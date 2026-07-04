#!/usr/bin/env python3
"""KPI分解・LY比・Budget比・顧客セグメント集計スクリプト。

売上レビューの数値ファクトを機械的に計算し、手計算ミスを防ぐ。
入力フォーマットは examples/input-data-format.md を参照。

使い方:
    python kpi_analysis.py sales_by_store.csv [--segment sales_by_segment.csv] [--out report.md]

Excel(.xlsx)も直接読める。シート名が複数ある場合は最初のシートを使う。
"""

import argparse
import sys
from pathlib import Path

import pandas as pd

STORE_REQUIRED = ["store", "revenue", "tr", "quantity"]
SEGMENT_REQUIRED = ["segment", "clients", "revenue"]


def read_table(path: str) -> pd.DataFrame:
    p = Path(path)
    if p.suffix.lower() in (".xlsx", ".xls"):
        df = pd.read_excel(p)
    else:
        df = pd.read_csv(p)
    df.columns = [str(c).strip().lower() for c in df.columns]
    return df


def check_columns(df: pd.DataFrame, required: list[str], name: str) -> list[str]:
    missing = [c for c in required if c not in df.columns]
    if missing:
        print(f"[不足データ] {name}: 必須カラムがありません: {missing}", file=sys.stderr)
    return missing


def pct(actual, base):
    """基準比を%で返す。基準が0/欠損ならNone（推測しない）。"""
    if base is None or pd.isna(base) or base == 0 or actual is None or pd.isna(actual):
        return None
    return (actual / base - 1) * 100


def fmt_pct(v, digits=1):
    return "N/A" if v is None else f"{v:+.{digits}f}%"


def derive_kpis(df: pd.DataFrame, suffix: str = "") -> pd.DataFrame:
    """Revenue/TR/QuantityからATV・UPT・APを導出する。suffixは '' か '_ly'。"""
    rev, tr, qty = f"revenue{suffix}", f"tr{suffix}", f"quantity{suffix}"
    out = df.copy()
    if rev in out and tr in out:
        out[f"atv{suffix}"] = out[rev] / out[tr].where(out[tr] != 0)
    if qty in out and tr in out:
        out[f"upt{suffix}"] = out[qty] / out[tr].where(out[tr] != 0)
    if rev in out and qty in out:
        out[f"ap{suffix}"] = out[rev] / out[qty].where(out[qty] != 0)
    return out


def store_report(df: pd.DataFrame) -> list[str]:
    lines = ["## 店舗別KPI分解", ""]
    df = derive_kpis(df)
    if "revenue_ly" in df.columns:
        df = derive_kpis(df, "_ly")

    # 全社計（合計から再計算。単純平均でATV等を出さない）
    total = df.select_dtypes("number").sum(numeric_only=True)
    rows = [("全社計", total)] + [(r["store"], r) for _, r in df.iterrows()]

    header = "| 店舗 | Revenue | vs LY | vs Budget | TR | TR vs LY | ATV | ATV vs LY | UPT | UPT vs LY | AP | AP vs LY |"
    lines += [header, "|" + "---|" * 12]

    for name, r in rows:
        rev, tr, qty = r.get("revenue"), r.get("tr"), r.get("quantity")
        atv = rev / tr if tr else None
        upt = qty / tr if tr else None
        ap = rev / qty if qty else None
        atv_ly = (r.get("revenue_ly") / r.get("tr_ly")) if r.get("tr_ly") else None
        upt_ly = (r.get("quantity_ly") / r.get("tr_ly")) if r.get("tr_ly") else None
        ap_ly = (r.get("revenue_ly") / r.get("quantity_ly")) if r.get("quantity_ly") else None
        lines.append(
            f"| {name} | {rev:,.0f} | {fmt_pct(pct(rev, r.get('revenue_ly')))} "
            f"| {fmt_pct(pct(rev, r.get('budget')))} "
            f"| {tr:,.0f} | {fmt_pct(pct(tr, r.get('tr_ly')))} "
            f"| {atv:,.0f} | {fmt_pct(pct(atv, atv_ly))} "
            f"| {upt:.2f} | {fmt_pct(pct(upt, upt_ly))} "
            f"| {ap:,.0f} | {fmt_pct(pct(ap, ap_ly))} |"
        )

    # Revenue増減のドライバー分解（全社）: ΔRev% ≈ ΔTR% + ΔATV% (+交差項)
    rev_g = pct(total.get("revenue"), total.get("revenue_ly"))
    tr_g = pct(total.get("tr"), total.get("tr_ly"))
    if rev_g is not None and tr_g is not None:
        atv_now = total["revenue"] / total["tr"]
        atv_ly = total["revenue_ly"] / total["tr_ly"]
        atv_g = pct(atv_now, atv_ly)
        lines += [
            "",
            "### 全社Revenue増減のドライバー",
            f"- Revenue {fmt_pct(rev_g)} ≒ TR要因 {fmt_pct(tr_g)} × ATV要因 {fmt_pct(atv_g)}",
        ]
        qty_g = pct(total.get("quantity"), total.get("quantity_ly"))
        if qty_g is not None:
            upt_g = pct(total["quantity"] / total["tr"], total["quantity_ly"] / total["tr_ly"])
            ap_g = pct(total["revenue"] / total["quantity"], total["revenue_ly"] / total["quantity_ly"])
            lines.append(f"- ATV {fmt_pct(atv_g)} ≒ UPT要因 {fmt_pct(upt_g)} × AP要因 {fmt_pct(ap_g)}")
    return lines


def segment_report(df: pd.DataFrame) -> list[str]:
    lines = ["", "## 顧客セグメント別（人数×金額）", ""]
    grp = df.groupby("segment", as_index=False).sum(numeric_only=True)
    lines += [
        "| セグメント | 人数 | 人数 vs LY | 金額 | 金額 vs LY | 1人あたり金額 |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    order = ["New", "Loyal", "High", "Top", "Lost"]
    grp["_o"] = grp["segment"].apply(lambda s: order.index(s) if s in order else 99)
    for _, r in grp.sort_values("_o").iterrows():
        per_client = r["revenue"] / r["clients"] if r["clients"] else None
        per_str = f"{per_client:,.0f}" if per_client is not None else "N/A"
        lines.append(
            f"| {r['segment']} | {r['clients']:,.0f} | {fmt_pct(pct(r['clients'], r.get('clients_ly')))} "
            f"| {r['revenue']:,.0f} | {fmt_pct(pct(r['revenue'], r.get('revenue_ly')))} | {per_str} |"
        )
    lines += [
        "",
        "※ ハイスペンダーは人数増減と金額増減を分けて解釈すること（人数減・単価増 / 人数増・単価減で打ち手が異なる）。",
    ]
    return lines


def main():
    ap = argparse.ArgumentParser(description="Retail Business Review KPI集計")
    ap.add_argument("store_file", help="店舗別KPIデータ (CSV/Excel)")
    ap.add_argument("--segment", help="顧客セグメント別データ (CSV/Excel)")
    ap.add_argument("--out", help="Markdown出力先（省略時は標準出力）")
    args = ap.parse_args()

    lines = ["# KPI集計結果（機械計算）", ""]

    store = read_table(args.store_file)
    missing = check_columns(store, STORE_REQUIRED, "店舗別KPI")
    if missing:
        sys.exit(1)
    if "budget" not in store.columns:
        lines.append("> [不足データ] budgetカラムなし。Budget比は N/A で出力する。")
    if "revenue_ly" not in store.columns:
        lines.append("> [不足データ] LYカラムなし。前年比は N/A で出力する。")
    lines += store_report(store)

    if args.segment:
        seg = read_table(args.segment)
        if not check_columns(seg, SEGMENT_REQUIRED, "顧客セグメント"):
            lines += segment_report(seg)

    text = "\n".join(lines) + "\n"
    if args.out:
        Path(args.out).write_text(text, encoding="utf-8")
        print(f"出力: {args.out}")
    else:
        print(text)


if __name__ == "__main__":
    main()
