# archive

廃止したスキルの退避場所。現役では使わないが、判断を後から検証できるように原文を残しておく。

## marni-pptx（廃止: 2026-08-15）

`marni-deck` に一本化したため廃止。

### 廃止理由

**1. 参照先のテンプレートを持っておらず、そもそも動作しない**

`SKILL.md` はテンプレートの場所を次のように指定していた。

```
/mnt/skills/user/marni-pptx/Marni_Template.pptx
```

しかし実際には、

- `marni-pptx` パッケージの中身は `SKILL.md` 1ファイルのみで、テンプレートを同梱していない
- `/mnt/skills/user/` というディレクトリは存在しない（`examples` と `public` のみ）
- `Marni_Template.pptx` はシステム上で `marni-deck/assets/` に1つあるだけ

つまり呼び出してもテンプレートが見つからず必ず失敗する状態だった。

**2. 手順が Claude Code の構成と噛み合っていない**

ワークフローが `/home/claude/...` および `/mnt/skills/public/pptx/scripts/...` 前提で書かれている。これは Claude アプリのサンドボックス向けのパス構成。

**3. `marni-deck` と役割が完全に重複していた**

description がどちらも「Marni テンプレートで PPTX を作る」であり、トリガーが競合して意図しない方が起動しうる状態だった。

### 移行先

`marni-deck` は自己完結している。

| | marni-pptx | marni-deck |
| --- | --- | --- |
| テンプレート本体 | ❌ 無し（外部パス参照） | ✅ `assets/Marni_Template.pptx` |
| 生成スクリプト | ❌ 手作業の XML 編集手順 | ✅ `scripts/build_deck.py` |
| レイアウト部品 | ❌ 無し | ✅ `scripts/marni_kit.py` |
| スライド仕様書 | テンプレート10枚の一覧 | ✅ `references/slide-types.md`（17タイプ） |

### 失われた情報

ブランドカラーは7色すべて `marni_kit.py` の定数と RGB 完全一致を確認済みで、固有情報の損失は無い。

唯一 `marni-pptx` にしか記載が無かったのが **PANTONE 番号**なので、以下に転記して保全する。

| 色名 | PANTONE | RGB | marni_kit.py 定数 |
| --- | --- | --- | --- |
| Red | 199 C | 218, 18, 18 | `RED` |
| Black | — | 0, 0, 0 | `BLACK` |
| Dark Brown | 4975 C | 64, 32, 35 | `DARK_BROWN` |
| Camel | 7586 C | 157, 83, 48 | `CAMEL` |
| Lilac | 2092 C | 183, 172, 214 | `LILAC` |
| Light Grey | — | 210, 210, 210 | `LIGHT_GREY` |
| Yellow | 0131 U | 251, 245, 155 | `YELLOW` |

### 復活させる場合

`archive/marni-pptx/SKILL.md` が原文（無改変）。ただし復活させるなら、テンプレート本体の同梱とパス構成の修正が必須。
