---
name: retail-business-review
description: ラグジュアリーブランド日本リテールの売上レビューSkill。月次・四半期・半期（1-6月/1-12月等）の売上データから、店舗別レビュー、KPI分解（TR/UPT/ATV/AP/Quantity/Revenue）、顧客分析（New/Loyal/Lost/High/Top）、ハイスペンダー分析、外商示唆、店舗アクションプラン、店長会スライド骨子、HQ向け英語サマリーまでを一貫した構成で作成する。売上レビュー、店舗レビュー、ビジネスレビュー、月次報告、店長会資料、HQレポートの依頼時に使用する。
---

# Retail Business Review Skill

ラグジュアリーブランドの日本リテールビジネスにおける売上レビューを、一貫した構成・分析ルール・トーンで作成するためのSkill。店長会・社内報告・HQ共有にそのまま使えるアウトプットを目指す。

このファイル1つで完結する（フォルダ構成不要）。他のプロジェクト・環境で使う場合は、この`SKILL.md`をそのままコピーするだけでよい。

## 想定インプット

| データ | 形式 | 備考 |
|---|---|---|
| 売上データ | Excel / CSV | 店舗別・期間別。想定カラムは下記「入力データフォーマット」参照 |
| 店舗別KPI | Excel / CSV | TR / UPT / ATV / AP / Quantity / Revenue |
| 顧客ステータス別データ | Excel / CSV | New / Loyal / Lost / High / Top |
| 前年実績（LY） | Excel / CSV | 同一期間で比較できる粒度 |
| Budget | Excel / CSV | 店舗別・期間別 |
| 店舗コメント | テキスト | DSR・店長コメント等 |
| ミーティングメモ | テキスト | 任意 |

データ受領時は下記「KPI集計スクリプト」でKPI分解・前年比・Budget比を機械的に計算し、計算ミスを避ける。スクリプトが使えない環境では手計算でよいが、計算式は必ずKPI定義（下記）に従う。

## KPI定義（必ずこの式で分解する）

```
Revenue = TR × ATV
ATV     = UPT × AP
Quantity = TR × UPT
AP      = Revenue ÷ Quantity
```

- **TR**: トランザクション数（購買客数）
- **UPT**: Units per Transaction（1客あたり点数）
- **ATV**: Average Transaction Value（客単価）
- **AP**: Average Price（平均商品単価）

Revenueの増減は必ず「TR要因か、ATV要因か」→ ATVなら「UPT要因か、AP要因か」まで分解して説明する。

## 分析ルール（必須）

1. **Revenueだけで判断しない。** 必ずTR / ATV / UPT / AP / Quantityに分解し、増減のドライバーを特定する。
2. **前年差とBudget差を分けて見る。** 「LY比では成長だがBudget未達」「LY比マイナスだがBudget達成」は意味が異なる。混ぜない。
3. **顧客はNew / Loyal / Lostを必ず分けて見る。** Revenue成長がNew獲得によるものか、Loyalの深耕によるものかを区別する。Lostは人数と失った金額を明記する。
4. **ハイスペンダー（High / Top）は人数と金額の両方を見る。** 「人数減・単価増」と「人数増・単価減」は打ち手が異なる。
5. **結果で終わらせず、次のアクションに落とす。** 各ファインディングには対応するアクションを紐づける。
6. **アクションは店舗が実行できる行動にする。** 「顧客との関係強化」ではなく「Lost化リスクのある上位20名に対し、○月中に新作案内＋来店アポイントを設定する」のレベルまで具体化する。
7. **不明な点は推測しない。** データがない項目は「不足データ」セクションに明記し、次回までに揃えるべきデータとして提示する。
8. **外商・百貨店文脈を常に持つ。** 百貨店内店舗は外商経由売上の有無・比率に言及し、外商担当との連携アクションを検討する。

## アウトプット構成（この順で必ず作成）

1. **Executive Summary** — 全体結果を3〜5行。LY比・Budget比・最大のドライバー・最重要アクション。
2. **全体結果レビュー** — 全社KPIテーブル（Actual / LY / Budget / LY比 / Budget比）＋KPI分解による増減要因。
3. **店舗別の強み・課題** — 店舗ごとに強み・課題を各2〜3点。数値根拠を必ず添える。
4. **KPI分解** — TR / UPT / ATV / AP / Quantity の店舗別比較。異常値・特徴店舗を指摘。
5. **ハイスペンダー分析** — High / Top顧客の人数×金額マトリクス。前年比での人数増減と金額増減を分離。
6. **外商・百貨店連携の示唆** — 外商経由売上の状況、百貨店催事・外商顧客への打ち手。
7. **店舗別アクションプラン** — 店舗×アクション×期限×測定指標のテーブル。DSRの店舗コメントを反映。
8. **店長会向けスライド骨子** — 下記「店長会スライド骨子テンプレート」に従い、1スライド1メッセージで構成。
9. **HQ向け英語サマリー** — 下記「HQ向け英語サマリーテンプレート」に従い英語で作成。定量根拠を明示。

最後に **不足データ** セクションを付ける（該当があれば）。

アウトプット全体は下記「レビュー出力テンプレート」を起点に使う。

## トーン・品質基準

- 日本語は簡潔・ビジネス向け・常体ベース（「〜である」「〜する」）。箇条書き中心。
- ラグジュアリーリテールの文脈を前提にする（顧客体験・CRM・外商・百貨店・路面店・限定品・ウェイティングリスト等の語彙を自然に使う）。
- 1スライド1メッセージ。スライド骨子ではタイトル＝メッセージにする（「売上結果」ではなく「TR減をATVで補ったが、New獲得が課題」）。
- 店長が翌日から動ける内容にする。抽象論・精神論は書かない。
- HQ向けは定量根拠（数値・%・件数）を必ず添える。形容詞だけの評価をしない。
- 数値の丸め：金額は千円単位または百万円単位で統一、%は小数1桁。表内で単位を明記。

## ワークフロー

1. 入力データを確認し、期間・店舗・比較軸（LY / Budget）が揃っているかチェックする。
2. 揃っていない場合は不足を明示した上で、あるデータの範囲で分析を進める。
3. 下記の`kpi_analysis.py`でKPI分解・LY比・Budget比・顧客セグメント集計を実行する。
4. 数値ファクトを固めてから、店舗コメント・ミーティングメモを突き合わせて解釈を作る。
5. アウトプット構成1〜9の順で作成する。
6. 分析ルール1〜8に照らしてセルフチェックし、抽象的なアクションを具体化し直す。

---

## 入力データフォーマット

実データのカラム名が異なる場合は、以下の定義にマッピングしてから分析する。
マッピングできないカラムがあれば推測せず、ユーザーに確認するか「不足データ」に記載する。

### 1. 店舗別KPIデータ（sales_by_store）

| カラム | 型 | 説明 |
|---|---|---|
| period | 文字列 | 例：2026-01、2026H1 |
| store | 文字列 | 店舗名 |
| channel | 文字列 | 百貨店 / 路面店 / アウトレット等（任意） |
| revenue | 数値 | 売上金額 |
| tr | 数値 | トランザクション数 |
| quantity | 数値 | 販売点数 |
| revenue_ly | 数値 | 前年同期間の売上 |
| tr_ly | 数値 | 前年同期間のTR |
| quantity_ly | 数値 | 前年同期間の点数 |
| budget | 数値 | 売上Budget |

※ ATV / UPT / AP はスクリプトで導出するため入力不要（あれば検算に使う）。

### 2. 顧客ステータス別データ（sales_by_segment）

| カラム | 型 | 説明 |
|---|---|---|
| period | 文字列 | 期間 |
| store | 文字列 | 店舗名（全社計の場合は ALL） |
| segment | 文字列 | New / Loyal / Lost / High / Top |
| clients | 数値 | 顧客人数 |
| revenue | 数値 | セグメント売上（Lostは前年に失った売上） |
| clients_ly | 数値 | 前年人数 |
| revenue_ly | 数値 | 前年売上 |

セグメント定義（ブランド側の定義があればそれを優先。なければ確認する）：
- **New**: 対象期間に初回購買した顧客
- **Loyal**: 定義された継続購買条件を満たす既存顧客
- **Lost**: 前年に購買があり対象期間に購買がない顧客
- **High / Top**: 年間購買金額の閾値で定義されるハイスペンダー層（Top ⊂ High が一般的。閾値は要確認）

### 3. 外商データ（gaisho_sales・任意）

| カラム | 型 | 説明 |
|---|---|---|
| period / store | | 上と同じ |
| gaisho_revenue | 数値 | 外商経由売上 |
| gaisho_tr | 数値 | 外商経由TR（任意） |

### 4. 店舗コメント／DSR・ミーティングメモ

自由テキスト。店舗名と期間が分かる形で受領する。
数値と矛盾するコメントがあった場合は、矛盾として明示する（どちらかに寄せない）。

---

## レビュー出力テンプレート

対象期間・対象店舗・比較軸（LY / Budget）を冒頭に明記してから、以下の構成で作成する。

```markdown
# {ブランド名} 日本リテール ビジネスレビュー（{期間}）

- 対象期間：{例：2026年1月〜6月}
- 対象店舗：{店舗数・リスト}
- 比較軸：前年同期間（LY）／ Budget
- 金額単位：{千円 / 百万円}

## 1. Executive Summary

- 全体Revenue：{金額}（LY比 {±x.x}% ／ Budget比 {±x.x}%）
- 最大のドライバー：{例：TR減をATV増（AP上昇）で補完}
- 顧客構造：{例：New獲得はBudget未達、Loyal売上はLY比+x%}
- 最重要アクション：{1〜2点}

## 2. 全体結果レビュー

| KPI | Actual | LY | Budget | vs LY | vs Budget |
|---|---:|---:|---:|---:|---:|
| Revenue | | | | | |
| TR | | | | | |
| ATV | | | | | |
| UPT | | | | | |
| AP | | | | | |
| Quantity | | | | | |

**増減要因の分解**
- Revenue {±x.x}% = TR要因 {±x.x}pt ＋ ATV要因 {±x.x}pt
- ATV {±x.x}% = UPT要因 {±x.x}pt ＋ AP要因 {±x.x}pt
- 解釈：{何が構造的で、何が一時的か}

## 3. 店舗別の強み・課題

### {店舗名}（Revenue {金額}、vs LY {±x.x}%、vs Budget {±x.x}%）
- 強み：{数値根拠つきで2〜3点}
- 課題：{数値根拠つきで2〜3点}

（店舗数分繰り返す）

## 4. KPI分解（店舗別）

| 店舗 | Revenue vs LY | TR vs LY | ATV vs LY | UPT vs LY | AP vs LY | 特記事項 |
|---|---:|---:|---:|---:|---:|---|

- 異常値・特徴店舗の指摘：{例：A店はTR+だがAP−。エントリー価格帯偏重の可能性}

## 5. ハイスペンダー分析

| セグメント | 人数 | 人数 vs LY | 金額 | 金額 vs LY | 1人あたり金額 |
|---|---:|---:|---:|---:|---:|
| Top | | | | | |
| High | | | | | |
| Loyal | | | | | |
| New | | | | | |
| Lost | | | −{失った金額} | | |

- 人数×金額の解釈：{人数減・単価増 or 人数増・単価減 を明示}
- Lost顧客：{人数}名／逸失額 {金額}。上位Lostの傾向：{店舗・カテゴリ等}

## 6. 外商・百貨店連携の示唆

- 外商経由売上：{金額・比率。データがなければ「不足データ」へ}
- 百貨店店舗の状況：{催事・館全体トレンドとの関係}
- 打ち手：{外商担当との連携アクション。担当者・時期を具体化}

## 7. 店舗別アクションプラン

→ 下記「店舗別アクションプランテンプレート」の形式を使用

## 8. 店長会向けスライド骨子

→ 下記「店長会スライド骨子テンプレート」の形式を使用

## 9. HQ向け英語サマリー

→ 下記「HQ向け英語サマリーテンプレート」の形式を使用

## 不足データ

- {項目}：{何が分からないか、次回までに何を揃えるべきか}
```

---

## 店長会スライド骨子テンプレート

原則：**1スライド1メッセージ**。スライドタイトル＝そのスライドの結論。
「売上結果」のような名詞タイトルは禁止。「TR減をATVで補ったが、New獲得が未達」のようにメッセージで書く。

各スライドは以下の形式で骨子化する：

```
Slide {n}: {タイトル＝メッセージ}
- Body: {載せる図表・数値（表 or グラフの指定）}
- Talk: {口頭で補足するポイント1〜2点}
```

### 標準構成（10〜12枚）

1. **全体結果**：{期間}はLY比{±x}% / Budget比{±x}% — ドライバーは{TR/ATV}
2. **KPI分解**：Revenue増減の内訳（TR×ATVのウォーターフォール）
3. **店舗別結果**：達成店舗と未達店舗の分布（Budget達成率ランキング）
4. **好調店舗の要因**：{店舗名}に学ぶ — {具体要因}
5. **課題店舗の要因**：{店舗名}の課題は{TR/ATV/顧客構造}
6. **顧客構造**：New / Loyal / Lostの人数と金額 — {メッセージ}
7. **ハイスペンダー**：Top/High顧客の人数×金額 — {メッセージ}
8. **Lost顧客**：{人数}名・{金額}の逸失 — 防げるLostは誰か
9. **外商・百貨店**：{メッセージ}
10. **アクションプラン**：店舗×アクション×期限（全店共通＋店舗個別）
11. **次回までの宿題**：各店が持ち帰るTo-Doと測定指標

※ 期間・議題により枚数は増減してよいが、1スライド1メッセージは崩さない。
※ 店長がその場で「自店は何をするか」を言えるレベルまでアクションを具体化して載せる。

---

## HQ向け英語サマリーテンプレート

- 英語・ビジネストーン。1ページ以内。
- すべての主張に定量根拠（数値・%・件数）を付ける。形容詞のみの評価は書かない。
- 日本市場特有の概念は簡潔に説明を添える（e.g., Gaisho = department stores' external VIP sales channel）。

```markdown
# Japan Retail Business Review — {Period}

## Headline

{One sentence: Revenue result vs LY and vs Budget, with the main driver.}
e.g., "Japan retail closed H1 at ¥X.XB, +X.X% vs LY but -X.X% vs Budget, driven by ATV growth (+X.X%) offsetting a TR decline (-X.X%)."

## Performance Summary

| KPI | Actual | vs LY | vs Budget |
|---|---:|---:|---:|
| Revenue | | | |
| Transactions (TR) | | | |
| ATV | | | |
| UPT | | | |
| Average Price (AP) | | | |

## Key Drivers

- {Driver 1 with numbers}
- {Driver 2 with numbers}
- {Driver 3 with numbers}

## Customer Structure

- New: {n} clients, ¥{amount} ({vs LY})
- Loyal: {n} clients, ¥{amount} ({vs LY})
- High / Top spenders: {n} clients, ¥{amount} — {headcount vs spend dynamics}
- Lost: {n} clients, ¥{amount} revenue at risk

## Store Highlights

- Best performer: {store} — {reason with numbers}
- Key concern: {store} — {reason with numbers}

## Actions for Next Period

1. {Action, owner, deadline, KPI to measure}
2. {Action, owner, deadline, KPI to measure}
3. {Action, owner, deadline, KPI to measure}

## Data Gaps (if any)

- {Missing data and plan to obtain it}
```

---

## 店舗別アクションプランテンプレート

原則：
- アクションは店舗が翌日から実行できる粒度にする（対象顧客数・時期・手段を明記）。
- 各アクションに測定指標（何がどれだけ変われば成功か）を必ず付ける。
- DSR・店舗コメントで挙がった事実をアクションの根拠に使う。
- 全店共通アクションと店舗個別アクションを分ける。

```markdown
## 全店共通アクション

| # | アクション | 根拠（データ／DSR） | 期限 | 測定指標 |
|---|---|---|---|---|
| 1 | | | | |

## 店舗個別アクション

### {店舗名}

| # | アクション | 根拠（データ／DSR） | 担当 | 期限 | 測定指標 |
|---|---|---|---|---|---|
| 1 | 例：Lost化リスクのある上位20名へ7月中に新作案内＋来店アポ設定 | Lost顧客のx%が最終購買12ヶ月超 | 店長＋CA | 7/31 | アポ獲得率50%、来店x件 |
| 2 | | | | | |

（店舗数分繰り返す）
```

### 悪い例 → 良い例（書き換え基準）

| 悪い例（書かない） | 良い例（このレベルまで具体化） |
|---|---|
| 顧客との関係を強化する | 上位顧客30名にバースデー月前月に電話＋来店特典案内、月末までに全員接触 |
| New顧客を増やす | 平日夕方の入店客に対しウェルカムドリンク＋レザーケア体験を提案、New登録率を月x%→y%へ |
| 外商との連携を深める | 外商担当と月1回の顧客リスト突合ミーティングを設定、外商経由の催事送客をx件作る |

---

## 出力例（抜粋・数値はダミー）

トーン・粒度・分解の深さの見本。実際の分析はこのレベルを下回らないこと。

### 1. Executive Summary

- H1全体Revenueは2,340百万円。LY比+3.2%、Budget比−4.1%で未達。
- 成長ドライバーはATV+8.5%（AP+6.2%が主因）。一方TRは−4.9%で、客数減をレザーグッズの価格改定効果で補った構造。
- New顧客は人数−12.3%と大幅減。Loyal売上は+9.8%と堅調で、成長が既存顧客依存に偏っている。
- 最重要アクション：①New獲得の立て直し（入店→登録転換の店頭オペ改善）、②Lost上位顧客180名への7月中の個別アプローチ。

### 3. 店舗別の強み・課題（1店舗分の例）

#### 銀座本店（Revenue 512百万円、vs LY +6.8%、vs Budget +1.2%）
- 強み
  - Top顧客売上+18.2%。人数横ばい（42→43名）で1人あたり金額が+15.9%と深耕型の成長。
  - UPT 1.42（全店平均1.18）。クロスセル提案が機能しており、シューズ＋SLGの併売率が高い。
- 課題
  - New TRが−21.4%。インバウンド比率の高い店舗だが、免税TRは+8%であり、減少は国内New。
  - 平日16時以降のTRがLY比−30%。DSRでも「平日夕方の入店減」のコメントと整合。

### 5. ハイスペンダー分析（形式の例）

| セグメント | 人数 | 人数 vs LY | 金額(百万円) | 金額 vs LY | 1人あたり(千円) |
|---|---:|---:|---:|---:|---:|
| Top | 128 | −5.9% | 486 | +7.1% | 3,797 |
| High | 542 | +2.1% | 703 | +1.8% | 1,297 |

- Topは**人数減・単価増**。上位顧客への依存度が上がっており、Top1名のLostインパクトが拡大している。
- 解釈：Top候補となるHigh上位層（年間200万円以上）からの引き上げが12ヶ月で9名にとどまる。引き上げパイプラインが細い。

### 7. 店舗別アクションプラン（1行の例）

| # | アクション | 根拠 | 担当 | 期限 | 測定指標 |
|---|---|---|---|---|---|
| 1 | Lost化リスク顧客（最終購買10ヶ月超のHigh 24名）に新作トランクショー招待を電話案内、8月第1週までに全員接触 | High顧客のLost転換の68%が最終購買12ヶ月超で発生 | 店長＋CA2名 | 8/8 | 接触率100%、来店12件、購買6件 |

### 不足データ（例）

- 外商経由売上の店舗別内訳：現状は百貨店合算のみ。外商施策の効果測定のため、次回から外商フラグ付きで受領したい。
- High/Topの閾値定義：本レビューではLY定義を踏襲したと仮定。HQ定義変更の有無を要確認。

---

## KPI集計スクリプト（kpi_analysis.py）

KPI分解・LY比・Budget比・顧客セグメント集計を機械的に計算し、手計算ミスを防ぐ。CSV/Excel対応（要`pandas`、Excel読み込みには`openpyxl`）。

使い方を他環境に持ち込む場合は、以下のコードを`kpi_analysis.py`として保存して使う：

```python
#!/usr/bin/env python3
"""KPI分解・LY比・Budget比・顧客セグメント集計スクリプト。

売上レビューの数値ファクトを機械的に計算し、手計算ミスを防ぐ。
入力フォーマットはSKILL.mdの「入力データフォーマット」を参照。

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


def safe_div(a, b):
    """a/bを返す。どちらかが欠損またはbが0ならNone（推測しない）。"""
    if a is None or b is None or pd.isna(a) or pd.isna(b) or b == 0:
        return None
    return a / b


def fmt_num(v, spec=",.0f"):
    return "N/A" if v is None or pd.isna(v) else format(v, spec)


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
        atv = safe_div(rev, tr)
        upt = safe_div(qty, tr)
        ap = safe_div(rev, qty)
        atv_ly = safe_div(r.get("revenue_ly"), r.get("tr_ly"))
        upt_ly = safe_div(r.get("quantity_ly"), r.get("tr_ly"))
        ap_ly = safe_div(r.get("revenue_ly"), r.get("quantity_ly"))
        lines.append(
            f"| {name} | {fmt_num(rev)} | {fmt_pct(pct(rev, r.get('revenue_ly')))} "
            f"| {fmt_pct(pct(rev, r.get('budget')))} "
            f"| {fmt_num(tr)} | {fmt_pct(pct(tr, r.get('tr_ly')))} "
            f"| {fmt_num(atv)} | {fmt_pct(pct(atv, atv_ly))} "
            f"| {fmt_num(upt, '.2f')} | {fmt_pct(pct(upt, upt_ly))} "
            f"| {fmt_num(ap)} | {fmt_pct(pct(ap, ap_ly))} |"
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
```
