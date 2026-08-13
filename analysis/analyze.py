"""
Marni リテール H1(上期)売上分析。

data/ 配下の実データ（店長会資料由来、コレクション26ドア基準）を読み込み、
FRAMEWORK.md の分解式・分析軸に沿った集計を行い、analysis/output/ にCSV/テキストで保存する。

重要な制約（NOTES.md参照）:
- Traffic（入店客数）・CVRのデータは存在しない。使えるのは Net売上 = TR(客数) × ATV のみ。
- 予算（Budget）データは存在しない。比較軸は対前年（vsLY）のみ。
- 対象範囲は「コレクション26ドア」（Retail Store + Retail Concession）。
  MARNI MARKET系・Café・POP UP・Outlet・Online・卸は含まない。
- store_clienteling_kpi_2025.csv のみ EUR建て・29拠点+Outlet3と対象範囲が異なるため、
  他のCSVとは合算しない（本スクリプトでは扱わない）。
- 数値はすべて data/ 配下のCSVから読み込んだ実測値。捏造・推測値は用いない。
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
OUTPUT_DIR = Path(__file__).resolve().parent / "output"


def pct_to_float(s: str) -> float:
    """'+0.3%' や '-10.8%' のような文字列を float(0.003 / -0.108) に変換する。"""
    s = str(s).strip()
    if s in ("", "横ばい", "nan"):
        return 0.0
    s = s.replace("+", "").replace("%", "")
    return float(s) / 100.0


def yen_man_to_yen(man: float) -> float:
    """百万円 -> 円"""
    return man * 1_000_000


# ---------------------------------------------------------------------------
# 1. H1累計 TR×ATV 要因分解（円ベース）+ ATVのUPT要因/AP要因分解
# ---------------------------------------------------------------------------
def analyze_tr_atv_decomposition() -> pd.DataFrame:
    df = pd.read_csv(DATA_DIR / "h1_kpi_detail_2025_2026.csv")
    row = {r["KPI"]: r for _, r in df.iterrows()}

    tr_2025 = float(row["TR(客数)"]["2025_H1"])
    tr_2026 = float(row["TR(客数)"]["2026_H1"])
    atv_2025 = float(row["ATV"]["2025_H1"])
    atv_2026 = float(row["ATV"]["2026_H1"])
    upt_2025 = float(row["UPT"]["2025_H1"])
    upt_2026 = float(row["UPT"]["2026_H1"])
    ap_2025 = float(row["AP(1点単価)"]["2025_H1"])
    ap_2026 = float(row["AP(1点単価)"]["2026_H1"])

    revenue_2025 = tr_2025 * atv_2025
    revenue_2026 = tr_2026 * atv_2026
    gap = revenue_2026 - revenue_2025

    # 順次代入法: TR要因を先に評価（前年ATV固定）、残差をATV要因とする
    tr_effect = (tr_2026 - tr_2025) * atv_2025
    atv_effect = tr_2026 * (atv_2026 - atv_2025)

    # ATV = UPT × AP の要因分解（同じく順次代入法、TR_2026を掛けて円換算）
    upt_effect_on_atv = (upt_2026 - upt_2025) * ap_2025
    ap_effect_on_atv = upt_2026 * (ap_2026 - ap_2025)
    upt_effect_yen = tr_2026 * upt_effect_on_atv
    ap_effect_yen = tr_2026 * ap_effect_on_atv

    result = pd.DataFrame(
        [
            {"項目": "Net売上_2025_H1_円", "値": revenue_2025},
            {"項目": "Net売上_2026_H1_円", "値": revenue_2026},
            {"項目": "Net売上_前年差_円", "値": gap},
            {"項目": "TR要因_円", "値": tr_effect},
            {"項目": "ATV要因_円", "値": atv_effect},
            {"項目": "  内訳_UPT要因_円", "値": upt_effect_yen},
            {"項目": "  内訳_AP要因_円", "値": ap_effect_yen},
            {"項目": "TR_2025", "値": tr_2025},
            {"項目": "TR_2026", "値": tr_2026},
            {"項目": "ATV_2025_円", "値": atv_2025},
            {"項目": "ATV_2026_円", "値": atv_2026},
        ]
    )
    return result


# ---------------------------------------------------------------------------
# 2. 既存店ベース評価（h1_kpi_detail_2025_2026.csv の既存店ベース行をそのまま採用）
# ---------------------------------------------------------------------------
def analyze_existing_store_base() -> pd.DataFrame:
    df = pd.read_csv(DATA_DIR / "h1_kpi_detail_2025_2026.csv")
    df = df[df["KPI"].str.contains("既存店ベース", na=False)]
    return df[["KPI", "vsLY"]]


# ---------------------------------------------------------------------------
# 3. 店舗別の4象限分類 + 予算/Traffic/CVRを使わない要注意店舗スコア
# ---------------------------------------------------------------------------
def analyze_store_quadrant_and_risk() -> tuple[pd.DataFrame, pd.DataFrame]:
    df = pd.read_csv(DATA_DIR / "store_h1_kpi_2025_2026.csv")
    df = df[df["店舗"] != "渋谷パルコ1F"].copy()  # 新規オープン店は前年同期比較の対象外

    for col in ["Net_vsLY", "TR_vsLY", "ATV_vsLY", "FP売上_vsLY"]:
        df[col + "_f"] = df[col].apply(pct_to_float)
    df["MD構成比_delta_pt"] = df["MD構成比_2026"].str.rstrip("%").astype(float) - df[
        "MD構成比_2025"
    ].str.rstrip("%").astype(float)

    def quadrant(row: pd.Series) -> str:
        tr_up = row["TR_vsLY_f"] >= 0
        atv_up = row["ATV_vsLY_f"] >= 0
        if tr_up and atv_up:
            return "TR増/ATV増"
        if (not tr_up) and atv_up:
            return "TR減/ATV増（単価依存）"
        if tr_up and (not atv_up):
            return "TR増/ATV減"
        return "TR減/ATV減（二重苦）"

    df["象限"] = df.apply(quadrant, axis=1)

    quadrant_summary = (
        df.groupby("象限")["店舗"]
        .apply(lambda s: "、".join(s))
        .reset_index()
        .rename(columns={"店舗": "店舗一覧"})
    )
    quadrant_summary["店舗数"] = df.groupby("象限")["店舗"].count().values

    # 要注意店舗スコア: Traffic/CVR/予算を使わず、Net_vsLY・TR_vsLY・FP売上_vsLY・MD構成比悪化ptの加重
    w_net, w_tr, w_fp, w_md = 0.35, 0.25, 0.25, 0.15

    def neg_part(x):
        return (-x).clip(lower=0) if isinstance(x, pd.Series) else max(0.0, -x)

    df["risk_score"] = (
        w_net * neg_part(df["Net_vsLY_f"])
        + w_tr * neg_part(df["TR_vsLY_f"])
        + w_fp * neg_part(df["FP売上_vsLY_f"])
        + w_md * neg_part(-df["MD構成比_delta_pt"] / 100.0)  # MD構成比"上昇"はFP劣化のシグナルなので符号反転
    )
    risk_ranking = df.sort_values("risk_score", ascending=False)[
        ["店舗", "Net_vsLY", "TR_vsLY", "ATV_vsLY", "FP売上_vsLY", "MD構成比_delta_pt", "象限", "risk_score", "備考"]
    ]
    return quadrant_summary, risk_ranking


# ---------------------------------------------------------------------------
# 4. 収益の質（FP/MD）
# ---------------------------------------------------------------------------
def analyze_fp_md_quality() -> pd.DataFrame:
    df = pd.read_csv(DATA_DIR / "h1_kpi_detail_2025_2026.csv")
    row = {r["KPI"]: r for _, r in df.iterrows()}
    fp_2025 = yen_man_to_yen(float(row["FP(プロパー)売上"]["2025_H1"]))
    fp_2026 = yen_man_to_yen(float(row["FP(プロパー)売上"]["2026_H1"]))
    md_2025 = yen_man_to_yen(float(row["MD(セール)売上"]["2025_H1"]))
    md_2026 = yen_man_to_yen(float(row["MD(セール)売上"]["2026_H1"]))
    return pd.DataFrame(
        [
            {"項目": "FP売上_差額_円", "値": fp_2026 - fp_2025},
            {"項目": "MD売上_差額_円", "値": md_2026 - md_2025},
            {"項目": "FP+MD合計差額_円", "値": (fp_2026 - fp_2025) + (md_2026 - md_2025)},
        ]
    )


# ---------------------------------------------------------------------------
# 5. 顧客基盤（Lost/新規既存/購入額階層）
# ---------------------------------------------------------------------------
def analyze_customer_base() -> dict[str, pd.DataFrame]:
    lost = pd.read_csv(DATA_DIR / "customer_retention_lost_h1.csv")
    lost_total_yen = lost["失った2025年売上_円"].sum()

    seg = pd.read_csv(DATA_DIR / "customer_segment_new_existing_h1.csv")
    seg_row = {r["指標"]: r for _, r in seg.iterrows()}
    tr_delta_new = float(seg_row["Δ"]["新規顧客"])
    tr_delta_existing = float(seg_row["Δ"]["既存顧客"])
    atv_new_2026 = float(seg_row["ATV_2026_円"]["新規顧客"])
    atv_existing_2026 = float(seg_row["ATV_2026_円"]["既存顧客"])
    # TR差分に2026年ATVを掛けた「客数要因」だけの金額影響（ATV変動は含まない粗い推計）
    new_customer_tr_impact_yen = tr_delta_new * atv_new_2026
    existing_customer_tr_impact_yen = tr_delta_existing * atv_existing_2026

    tier = pd.read_csv(DATA_DIR / "customer_spending_tier_h1.csv")

    overview = pd.read_csv(DATA_DIR / "customer_retention_overview.csv")

    summary = pd.DataFrame(
        [
            {"項目": "Lost顧客が失った2025年売上合計_円", "値": lost_total_yen},
            {"項目": "新規顧客TR差分×2026ATV_概算金額影響_円", "値": new_customer_tr_impact_yen},
            {"項目": "既存顧客TR差分×2026ATV_概算金額影響_円", "値": existing_customer_tr_impact_yen},
        ]
    )
    return {"summary": summary, "lost_detail": lost, "segment_detail": seg, "tier_detail": tier, "retention_overview": overview}


# ---------------------------------------------------------------------------
# 6. カテゴリ構造（RTW/Bags）
# ---------------------------------------------------------------------------
def analyze_category_structure() -> pd.DataFrame:
    cat = pd.read_csv(DATA_DIR / "category_breakdown_h1_2025_2026.csv")
    product = pd.read_csv(DATA_DIR / "product_group_delta_h1_2026vsLY.csv")
    return cat, product


# ---------------------------------------------------------------------------
# 7. 月次の裏付け
# ---------------------------------------------------------------------------
def analyze_monthly_trend() -> pd.DataFrame:
    return pd.read_csv(DATA_DIR / "monthly_trend_h1_2025_2026.csv")


# ---------------------------------------------------------------------------
# 8. インバウンド
# ---------------------------------------------------------------------------
def analyze_inbound() -> pd.DataFrame:
    df = pd.read_csv(DATA_DIR / "inbound_sales_by_country_h1.csv")
    df["vsLY_計算値"] = (df["2026_H1_百万円"] / df["2025_H1_百万円"] - 1).round(4)
    return df


def run_all() -> None:
    OUTPUT_DIR.mkdir(exist_ok=True)

    tr_atv = analyze_tr_atv_decomposition()
    tr_atv.to_csv(OUTPUT_DIR / "1_tr_atv_decomposition.csv", index=False)

    existing_base = analyze_existing_store_base()
    existing_base.to_csv(OUTPUT_DIR / "2_existing_store_base.csv", index=False)

    quadrant_summary, risk_ranking = analyze_store_quadrant_and_risk()
    quadrant_summary.to_csv(OUTPUT_DIR / "3_store_quadrant_summary.csv", index=False)
    risk_ranking.to_csv(OUTPUT_DIR / "3_store_risk_ranking.csv", index=False)

    fp_md = analyze_fp_md_quality()
    fp_md.to_csv(OUTPUT_DIR / "4_fp_md_quality.csv", index=False)

    customer = analyze_customer_base()
    customer["summary"].to_csv(OUTPUT_DIR / "5_customer_summary.csv", index=False)

    cat, product = analyze_category_structure()
    cat.to_csv(OUTPUT_DIR / "6_category_breakdown.csv", index=False)
    product.to_csv(OUTPUT_DIR / "6_product_group_delta.csv", index=False)

    monthly = analyze_monthly_trend()
    monthly.to_csv(OUTPUT_DIR / "7_monthly_trend.csv", index=False)

    inbound = analyze_inbound()
    inbound.to_csv(OUTPUT_DIR / "8_inbound_by_country.csv", index=False)

    print("=== 1. TR×ATV要因分解 ===")
    print(tr_atv.to_string(index=False))
    print("\n=== 2. 既存店ベース ===")
    print(existing_base.to_string(index=False))
    print("\n=== 3. 店舗4象限サマリー ===")
    print(quadrant_summary.to_string(index=False))
    print("\n=== 3. 要注意店舗ランキング(上位10) ===")
    print(risk_ranking.head(10).to_string(index=False))
    print("\n=== 4. FP/MD収益の質 ===")
    print(fp_md.to_string(index=False))
    print("\n=== 5. 顧客基盤サマリー ===")
    print(customer["summary"].to_string(index=False))
    print("\n=== 8. インバウンド国別 ===")
    print(inbound.to_string(index=False))


if __name__ == "__main__":
    run_all()
