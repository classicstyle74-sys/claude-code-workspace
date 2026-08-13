"""
Marni リテール売上分析 雛形スクリプト。

data/*.csv を読み込み、FRAMEWORK.md で定義した分解式・分析軸に沿った集計を行う。
実データの列名は未確定のため、COLUMN_MAP で吸収する（データ到着後にここを合わせる）。
"""

from __future__ import annotations

import glob
from dataclasses import dataclass, field
from pathlib import Path

import pandas as pd

DATA_DIR = Path(__file__).resolve().parent.parent / "data"

# 実データの列名 -> 内部で使う標準列名 のマッピング。
# データ到着後、実際のCSVのヘッダーに合わせてここだけ書き換える想定。
COLUMN_MAP = {
    "date": "date",  # 売上発生日
    "store_name": "store",  # 店舗名
    "store_type": "channel",  # 百貨店 / 路面 などのチャネル区分
    "category": "category",  # 商品カテゴリ
    "customer_segment": "customer_segment",  # New / Loyal / Lost
    "revenue": "revenue",  # 売上金額
    "traffic": "traffic",  # 来店客数
    "transactions": "transactions",  # 購買件数
    "units": "units",  # 販売点数
    "plan_revenue": "plan_revenue",  # 計画（予算）売上
}

# risk_score 算出時の重み（初期値、実データで調整する）
RISK_WEIGHTS = {
    "yoy_revenue": 0.30,
    "vs_plan_revenue": 0.30,
    "yoy_traffic": 0.15,
    "yoy_cvr": 0.10,
    "yoy_atv": 0.10,
    "lost_ratio_increase": 0.05,
}


@dataclass
class AnalysisResult:
    trend: pd.DataFrame = field(default_factory=pd.DataFrame)
    by_store: pd.DataFrame = field(default_factory=pd.DataFrame)
    by_channel: pd.DataFrame = field(default_factory=pd.DataFrame)
    by_category: pd.DataFrame = field(default_factory=pd.DataFrame)
    by_customer_segment: pd.DataFrame = field(default_factory=pd.DataFrame)
    at_risk_stores: pd.DataFrame = field(default_factory=pd.DataFrame)


def load_data(data_dir: Path = DATA_DIR) -> pd.DataFrame:
    """data/*.csv を読み込み、COLUMN_MAP で正規化して結合する。"""
    files = sorted(glob.glob(str(data_dir / "*.csv")))
    if not files:
        raise FileNotFoundError(f"No CSV files found in {data_dir}")

    frames = [pd.read_csv(f) for f in files]
    df = pd.concat(frames, ignore_index=True)
    df = df.rename(columns=COLUMN_MAP)
    df["date"] = pd.to_datetime(df["date"])
    return df


def add_kpi_columns(df: pd.DataFrame) -> pd.DataFrame:
    """CVR / ATV / UPT / AUR を算出して列として追加する。"""
    df = df.copy()
    df["cvr"] = df["transactions"] / df["traffic"]
    df["atv"] = df["revenue"] / df["transactions"]
    df["upt"] = df["units"] / df["transactions"]
    df["aur"] = df["revenue"] / df["units"]
    return df


def build_trend(df: pd.DataFrame, freq: str = "W") -> pd.DataFrame:
    """期間推移（週次/月次）の集計。"""
    grouped = (
        df.set_index("date")
        .resample(freq)
        .agg(
            revenue=("revenue", "sum"),
            traffic=("traffic", "sum"),
            transactions=("transactions", "sum"),
            units=("units", "sum"),
        )
    )
    grouped["cvr"] = grouped["transactions"] / grouped["traffic"]
    grouped["atv"] = grouped["revenue"] / grouped["transactions"]
    return grouped.reset_index()


def build_by_dimension(df: pd.DataFrame, dimension: str) -> pd.DataFrame:
    """店舗別 / チャネル別 / カテゴリ別 / 顧客区分別の共通集計。"""
    grouped = df.groupby(dimension).agg(
        revenue=("revenue", "sum"),
        plan_revenue=("plan_revenue", "sum"),
        traffic=("traffic", "sum"),
        transactions=("transactions", "sum"),
        units=("units", "sum"),
    )
    grouped["cvr"] = grouped["transactions"] / grouped["traffic"]
    grouped["atv"] = grouped["revenue"] / grouped["transactions"]
    grouped["vs_plan_pct"] = grouped["revenue"] / grouped["plan_revenue"] - 1
    return grouped.reset_index()


def compute_yoy(current: pd.DataFrame, prior: pd.DataFrame, on: str, value_cols: list[str]) -> pd.DataFrame:
    """当年 vs 前年の比較列（YoY %）を付与する。current/prior は同じ dimension で集計済みのDataFrame。"""
    merged = current.merge(prior, on=on, suffixes=("", "_py"))
    for col in value_cols:
        merged[f"yoy_{col}_pct"] = merged[col] / merged[f"{col}_py"] - 1
    return merged


def compute_risk_score(store_kpi_yoy: pd.DataFrame) -> pd.DataFrame:
    """FRAMEWORK.md の要注意店舗抽出ルールに沿って risk_score を算出する。

    store_kpi_yoy には以下の列が必要:
      yoy_revenue_pct, vs_plan_pct, yoy_traffic_pct, yoy_cvr_pt, yoy_atv_pct, lost_ratio_delta_pt
    """
    df = store_kpi_yoy.copy()

    def neg_part(series: pd.Series) -> pd.Series:
        return (-series).clip(lower=0)

    df["risk_score"] = (
        RISK_WEIGHTS["yoy_revenue"] * neg_part(df["yoy_revenue_pct"])
        + RISK_WEIGHTS["vs_plan_revenue"] * neg_part(df["vs_plan_pct"])
        + RISK_WEIGHTS["yoy_traffic"] * neg_part(df["yoy_traffic_pct"])
        + RISK_WEIGHTS["yoy_cvr"] * neg_part(df["yoy_cvr_pt"])
        + RISK_WEIGHTS["yoy_atv"] * neg_part(df["yoy_atv_pct"])
        + RISK_WEIGHTS["lost_ratio_increase"] * neg_part(-df["lost_ratio_delta_pt"])
    )
    return df.sort_values("risk_score", ascending=False)


def run_analysis(data_dir: Path = DATA_DIR) -> AnalysisResult:
    """エントリーポイント。実データ到着後、列名をCOLUMN_MAPで合わせてから実行する。"""
    df = load_data(data_dir)
    df = add_kpi_columns(df)

    result = AnalysisResult(
        trend=build_trend(df),
        by_store=build_by_dimension(df, "store"),
        by_channel=build_by_dimension(df, "channel"),
        by_category=build_by_dimension(df, "category"),
        by_customer_segment=build_by_dimension(df, "customer_segment"),
    )
    # at_risk_stores は前年データが揃った時点で compute_yoy + compute_risk_score を
    # 組み合わせて算出する（前年データの結合方法はデータ到着後に確定）。
    return result


if __name__ == "__main__":
    analysis = run_analysis()
    print(analysis.trend.tail())
    print(analysis.by_store.sort_values("revenue", ascending=False).head(10))
