#!/usr/bin/env python3
"""Store-level KPI breakdown for retail business review.

Input CSV columns (required):
  store, period, revenue, tr, quantity, revenue_ly, tr_ly, revenue_budget, tr_budget

period    : e.g. "2026-H1"
revenue   : current period revenue
tr        : current period transaction count
quantity  : current period unit quantity
*_ly      : same-period prior year values
*_budget  : budget targets

Computes UPT, ATV, AP for current/LY/budget and YoY%/Budget% deltas.
Rows with missing optional LY/Budget columns are still processed;
missing values are left blank rather than guessed.
"""
import argparse
import csv


def safe_div(a, b):
    try:
        a = float(a)
        b = float(b)
        if b == 0:
            return None
        return a / b
    except (TypeError, ValueError):
        return None


def pct_change(current, prior):
    if current is None or prior in (None, 0, ""):
        return None
    try:
        return (float(current) - float(prior)) / float(prior) * 100
    except (TypeError, ValueError):
        return None


def fmt(v, decimals=1):
    return "" if v is None else f"{v:.{decimals}f}"


def process_row(row):
    revenue = row.get("revenue")
    tr = row.get("tr")
    quantity = row.get("quantity")
    revenue_ly = row.get("revenue_ly")
    tr_ly = row.get("tr_ly")
    revenue_budget = row.get("revenue_budget")
    tr_budget = row.get("tr_budget")

    upt = safe_div(quantity, tr)
    atv = safe_div(revenue, tr)
    ap = safe_div(revenue, quantity)

    out = dict(row)
    out["upt"] = fmt(upt, 2)
    out["atv"] = fmt(atv, 0)
    out["ap"] = fmt(ap, 0)
    out["revenue_yoy_pct"] = fmt(pct_change(revenue, revenue_ly))
    out["revenue_budget_pct"] = fmt(pct_change(revenue, revenue_budget))
    out["tr_yoy_pct"] = fmt(pct_change(tr, tr_ly))
    out["tr_budget_pct"] = fmt(pct_change(tr, tr_budget))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Input CSV path")
    parser.add_argument("--output", required=True, help="Output CSV path")
    args = parser.parse_args()

    with open(args.input, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        rows = [process_row(row) for row in reader]

    if not rows:
        print("No rows found in input.")
        return

    fieldnames = list(rows[0].keys())
    with open(args.output, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} rows to {args.output}")


if __name__ == "__main__":
    main()
