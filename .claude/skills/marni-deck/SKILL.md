---
name: marni-deck
description: Marni ブランドテンプレートを使った PowerPoint (PPTX) 資料の作成。ユーザーが「Marni のテンプレートでプレゼンを作って」「この内容でスライドを作って」等、Marni デザインの資料作成・スライド生成を依頼したときに使用する。ブランドのデザイントークン(赤/黒/グレー基調、ロゴ、フォント、フッター)を厳守しつつ、内容に応じてチャート・図解・KPI タイルなどの最適なフォーマットを選び、見やすく単調にならない資料を組み立てる。
---

# Marni テンプレートデッキ生成

Marni ブランドテンプレート (`assets/Marni_Template.pptx`) をベースに PPTX を
生成する。

## 3 原則

1. **トークンは厳守、フレームは柔軟** — 色・フォント (Helvetica Neue)・ロゴ・
   フッター・「番号+見出し」のヘッダー様式は絶対に変えない。その枠内で、
   レイアウトは内容の見やすさを最優先に選ぶ。文章の詰め込みは禁止。
2. **図解優先** — 数値は `chart` か `stats`、手順は `flow`、対比は
   `comparison`、日程は `timeline`、明細は `table` で表現する。
   文章の羅列で済ませない。1 スライド 1 メッセージ。
3. **一貫性の中の変化** — セクション区切り (`section_red` / `section_black`
   を交互に)、`quote`、`full_image` を挟んでリズムを作る。同じタイプを
   3 枚以上連続させない。

## ワークフロー

1. **内容の受け取り** — ユーザーから資料の内容(テーマ、本文、データ、画像)を
   受け取る。不足があれば確認する。構成お任せの場合は内容から自然に組み立てる。

2. **フォーマット選択** — 各パートに最適なタイプを選ぶ:

   | 内容の性質 | 使うタイプ |
   |---|---|
   | 表紙 / 結び | `cover` / `closing` |
   | 目次(本編 3 枚以上なら入れる) | `toc` |
   | 章の区切り | `section_red` / `section_black`(交互に) |
   | 要点リスト・戦略の柱(画像なしの文章はこれ) | `bullets` |
   | 数値データ・推移・構成比 | `chart`(column/bar/line/pie/doughnut) |
   | 少数の重要数値 (KPI) | `stats` |
   | 手順・プロセス (3〜5 ステップ) | `flow` |
   | 2 案の対比・Before/After | `comparison` |
   | スケジュール・ロードマップ | `timeline` |
   | 明細・数値一覧 | `table` |
   | 説明文 + 画像 1 枚 | `text_image` |
   | 画像が主役 (2 枚並べ) | `two_images` |
   | 3 項目の並列比較 (画像付き) | `three_columns` |
   | 印象的な全面ビジュアル | `full_image` |
   | 引用・キーメッセージ | `quote` |

   構成の定石: `cover` → `toc` → (`section_*` → 本文 2〜4 枚) × 章数 →
   `closing`。`secnum` は「1.0」「2.1」形式で章・節に合わせて振る。

3. **スペック JSON の作成** — 各タイプのフィールド仕様は
   [references/slide-types.md](references/slide-types.md) を必ず読んで従う。
   文字数目安を超える内容はスライドを分割する。

4. **生成** — 依存: `pip install python-pptx`

   ```bash
   python3 scripts/build_deck.py spec.json -o output.pptx
   ```

   フッター左下の日付("July 26" 等、Month + 下 2 桁年)は実行時の日付を
   自動反映する。過去日基準で生成したい場合は `--date YYYY-MM-DD` を指定する。

   WARNING が出たら内容を調整して再生成する。

5. **検証(任意、LibreOffice が使える環境のみ)** — PDF 化して目視確認する
   (はみ出し・重なり・画像欠落)。無い環境では省略してよい:

   ```bash
   soffice --headless --convert-to pdf --outdir /tmp/check output.pptx
   pdftoppm -png -r 60 /tmp/check/output.pdf /tmp/check/s
   ```

   ※ "source file could not be loaded" が出る場合は `HOME` が書き込み可能か
   確認し、`-env:UserInstallation=file:///tmp/lo-profile` を付ける。

6. **納品** — 生成した .pptx をユーザーに渡す。

## 既存タイプで表現できない内容の場合

`scripts/marni_kit.py` を import した Python スクリプトを書いて独自レイアウトを
組んでよい。`kit.canvas()` でヘッダー付きキャンバス (grey/red/black) を作り、
`add_text` / `add_block` / `add_chart` / `add_cover_picture` 等の部品を配置する。
色は必ず `marni_kit` の定数 (RED, BLACK, CAMEL, LILAC, DARK_BROWN, YELLOW,
LIGHT_GREY, WHITE) を、フォントは `kit.FONT` を使い、コンテンツは
グリッド定数 (CONTENT_X/Y/W/H) の範囲に収める。

## 禁止事項

- ブランドカラー以外の色、Helvetica Neue 以外のフォント指定を使わない
- ロゴ・フッター・ヘッダー様式・スライドサイズ (10 × 5.63 in) を変えない
- グラデーション・影の追加・立体表現など、フラットでない装飾をしない
- `assets/Marni_Template.pptx` を上書きしない

## 画像の扱い

- 画像はユーザー提供が原則。画像プレースホルダーは空のままでも成立する
  (その領域は空白=背景色のまま表示される)。
- 画像は自動でパネル全面にクロップ配置される。縦横比の近い画像が最適。
