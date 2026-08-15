---
name: marni-pptx
description: "MARNIブランドの公式テンプレートを使用してプレゼンテーションを作成するスキル。ユーザーがMARNI関連のプレゼン、デッキ、スライドを作成したい場合に使用する。テンプレートにはタイトル、目次、セクションヘッダー（赤/黒）、テキスト、画像、テーブル、引用、Thank Youの各レイアウトが含まれる。"
---

# MARNI Presentation Skill

MARNIブランド公式テンプレート（`Marni_Template.pptx`）を使用してプレゼンテーションを作成するスキルです。

## テンプレートの場所

```
/mnt/skills/user/marni-pptx/Marni_Template.pptx
```

## 必ず先に読むこと

このスキルを使用する前に、必ず以下のPPTXスキルのドキュメントを読んでください：

```
/mnt/skills/public/pptx/SKILL.md
/mnt/skills/public/pptx/editing.md
```

テンプレート編集のワークフロー（unpack → edit → clean → pack）やXML編集のルール、QA手順はすべてそちらに記載されています。

## テンプレート構成（全10スライド）

| スライド | ファイル | レイアウト | 用途 | 背景色 |
|---------|----------|-----------|------|--------|
| 1 | slide1.xml | TITLE (Layout1) | **タイトルスライド** - MARNIロゴ + サブタイトル | 赤 |
| 2 | slide2.xml | SECTION_HEADER_1 (Layout3) | **目次** - 番号付きセクションリスト + ページ番号 | 白 |
| 3 | slide3.xml | SECTION_HEADER (Layout2) | **セクションヘッダー1** - 赤背景、タイトルのみ | 赤 |
| 4 | slide4.xml | TITLE_AND_BODY (Layout12) | **セクションヘッダー2** - 黒背景、タイトルのみ | 黒 |
| 5 | slide5.xml | SECTION_HEADER_1_2 (Layout4) | **テキストページ** - タイトル + 本文テキスト | 白 |
| 6 | slide6.xml | SECTION_HEADER_1_2_2_1_1_1 (Layout10) | **画像ページ** - タイトル + 画像プレースホルダー + サブタイトル | 白 |
| 7 | slide7.xml | SECTION_HEADER_1_1 (Layout11) | **テーブルページ** - タイトル + 3列テーブル | 白 |
| 8 | slide8.xml | TITLE_AND_BODY_1 (Layout13) | **引用ページ** - 大きな引用テキスト | 黒 |
| 9 | slide9.xml | SECTION_HEADER_1 (Layout3) | **カラーパレット** - ブランドカラー参照 | 白 |
| 10 | slide10.xml | TITLE (Layout1) | **Thank You** - MARNIロゴ | 赤 |

## MARNIブランドカラー

| カラー名 | RGB | 用途 |
|---------|-----|------|
| Red (PANTONE 199 C) | 218, 18, 18 | メインブランドカラー、タイトルスライド背景 |
| Black | 0, 0, 0 | テキスト、セクションヘッダー背景 |
| Dark Brown (PANTONE 4975 C) | 64, 32, 35 | アクセント |
| Camel (PANTONE 7586 C) | 157, 83, 48 | アクセント |
| Lilac (PANTONE 2092 C) | 183, 172, 214 | アクセント |
| Light Grey | 210, 210, 210 | 背景、区切り |
| Yellow (PANTONE 0131 U) | 251, 245, 155 | アクセント |

## プレゼン作成手順

### 1. コンテンツの計画

ユーザーのリクエストに基づいて、以下を決定する：
- プレゼンのタイトル
- セクション構成（何スライド必要か）
- 各スライドにどのテンプレートスライドを使うか

### 2. スライドの選択ガイド

| コンテンツタイプ | 使用するテンプレートスライド |
|----------------|--------------------------|
| 表紙 | slide1（赤背景タイトル） |
| 目次 | slide2（番号付きリスト） |
| セクション区切り（重要） | slide3（赤背景ヘッダー） |
| セクション区切り（通常） | slide4（黒背景ヘッダー） |
| テキスト説明・本文 | slide5（テキストページ） |
| 画像を含むページ | slide6（画像ページ） |
| 比較・データ表示 | slide7（3列テーブル） |
| 重要な引用・メッセージ | slide8（引用ページ） |
| 最終ページ | slide10（Thank You） |

### 3. 技術的なワークフロー

```bash
# 0. テンプレートをコピー
cp /mnt/skills/user/marni-pptx/Marni_Template.pptx /home/claude/template.pptx

# 1. 依存関係インストール
pip install "markitdown[pptx]" Pillow --break-system-packages -q

# 2. テンプレートをアンパック
python /mnt/skills/public/pptx/scripts/office/unpack.py /home/claude/template.pptx /home/claude/unpacked/

# 3. 必要なスライドを複製（add_slide.pyを使用）
# 例: テキストページを追加
python /mnt/skills/public/pptx/scripts/add_slide.py /home/claude/unpacked/ slide5.xml

# 4. presentation.xml の <p:sldIdLst> でスライド順序を調整
#    - 不要なスライドの<p:sldId>を削除（slide9カラーパレットは通常削除）
#    - 追加したスライドの<p:sldId>を正しい位置に配置

# 5. 各スライドのXMLを編集（str_replaceツールを使用）
#    - プレースホルダーテキストを実際のコンテンツに置換

# 6. クリーンアップ
python /mnt/skills/public/pptx/scripts/clean.py /home/claude/unpacked/

# 7. パック
python /mnt/skills/public/pptx/scripts/office/pack.py /home/claude/unpacked/ /home/claude/output.pptx --original /home/claude/template.pptx

# 8. QA - テキスト確認
python -m markitdown /home/claude/output.pptx

# 9. QA - ビジュアル確認
python /mnt/skills/public/pptx/scripts/office/soffice.py --headless --convert-to pdf /home/claude/output.pptx
pdftoppm -jpeg -r 150 /home/claude/output.pdf slide

# 10. 最終出力
cp /home/claude/output.pptx /mnt/user-data/outputs/
```

### 4. テキスト編集のルール

- **str_replaceツールを使用する**（sedやPythonスクリプトではなく）
- **ヘッダーとラベルは太字に**: `b="1"` を `<a:rPr>` に設定
- **Unicode弾丸は使わない**: `•` の代わりに `<a:buChar>` を使用
- **スマートクォート**: XML エンティティを使用（`&#x201C;` `&#x201D;`）
- **複数項目は別々の`<a:p>`要素に**: 1つの段落に全部入れない
- **日本語テキスト**: `lang="ja-JP"` を `<a:rPr>` に設定

### 5. 重要な注意事項

- slide1のMARNIロゴは画像ではなくテキスト（スペース付きの「M  A  R  N  I」）
- slide10も同様にMARNIロゴテキスト + 「Thank You!」テキスト
- slide1とslide10はほぼそのまま使用し、サブタイトルのみ変更する
- slide9（カラーパレット）は参照用。通常のプレゼンでは削除する
- フッターにはページ番号とコピーライト情報が自動的に入る

### 6. よくあるスライド構成例

**基本プレゼン（5-7スライド）:**
1. slide1 → タイトル
2. slide2 → 目次
3. slide3 → セクション1ヘッダー
4. slide5 → セクション1内容
5. slide3（複製） → セクション2ヘッダー
6. slide5（複製） → セクション2内容
7. slide10 → Thank You

**詳細プレゼン（10-15スライド）:**
1. slide1 → タイトル
2. slide2 → 目次
3. slide3 → セクション1ヘッダー
4. slide5 → テキスト説明
5. slide7 → データ/比較
6. slide4 → セクション2ヘッダー
7. slide5（複製） → テキスト説明
8. slide6 → 画像付き説明
9. slide3（複製） → セクション3ヘッダー
10. slide5（複製） → テキスト説明
11. slide8 → 重要メッセージ/引用
12. slide10 → Thank You
