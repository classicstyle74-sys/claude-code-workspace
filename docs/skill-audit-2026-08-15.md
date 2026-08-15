# スキル全件監査レポート（2026-08-15）

`marni-pptx` の廃止をきっかけに、同種の破損（存在しないパスの参照、アセット欠落）が他のスキルにも無いか、有効な全23スキルを機械的に検査した。

## 結論

**致命的な破損は `marni-pptx` の1件のみ**で、廃止済み。残る22スキルは動作に支障なし。軽微な指摘が3件ある。

## 検査項目と結果

| 検査 | 結果 |
| --- | --- |
| `/mnt/skills/user/...`（存在しないマウント）の参照 | `marni-pptx` のみ該当 → 廃止済み |
| `/mnt/skills/public/...` の参照先実在 | ✅ 全て実在 |
| スキル内の相対参照（`scripts/` `references/` `assets/`）の実在 | ✅ 実在しない参照は無し（下記の誤検知3件を除く） |
| 作業ディレクトリ（`/home/claude` 等）の実在 | ⚠️ 1件のみ不在（下記 A-2） |

## 検出した軽微な指摘（3件）

いずれも実行時に自己解決可能な範囲で、緊急の対応は不要。

### A-1. `pdf-to-pptx-layers`: プレースホルダーパスが未解決

`SKILL.md` L97 が以下のようにテンプレート文字列のまま。

```bash
python /path/to/pptx/scripts/thumbnail.py output.pptx
```

実体は `/mnt/skills/public/pptx/scripts/thumbnail.py` に存在するため、実行時に解決はできる。ただし `/path/to/` のまま実行しようとして一度失敗する可能性がある。

**推奨:** `/mnt/skills/public/pptx/scripts/thumbnail.py` に書き換え。

### A-2. `pptx-translate`: 出力先ディレクトリが存在しない

`SKILL.md` L201 が `/mnt/user-data/outputs/` へコピーする手順になっているが、このディレクトリは Claude Code 環境に存在しない（`/mnt/user-data` までは存在する）。

なお `/home/claude` は存在するため、作業ディレクトリ自体は問題ない。

**推奨:** 出力先をカレントディレクトリにするか、`mkdir -p` を前置する。

### A-3. `marni-deck`: description の守備範囲が広すぎる

description に「この内容でスライドを作って」という汎用フレーズが含まれており、Marni と無関係な資料作成でも起動しうる。`marni-pptx` を外したことで直接の競合は解消したが、`pptx` や `qa-pptx-generator` との境界は依然として曖昧。

**推奨:** トリガーを Marni 関連に限定する文言へ調整。

## 誤検知だったもの（対応不要）

初回スキャンで引っかかったが、精査の結果いずれも問題なし。

| 検出 | 実態 |
| --- | --- |
| `pdf → scripts/superscripts.` | 本文中の「subscripts/superscripts.」という散文をパスとして誤検出したもの |
| `pptx-translate → scripts/clean.py` | 絶対パス `/mnt/skills/public/pptx/scripts/clean.py` の末尾を拾ったもの。実在する |
| `pptx-translate → scripts/office` | 同上。実在する |

## PPTX系スキルの棲み分け（marni-pptx 廃止後）

重複の懸念があった PPTX 系5スキルの守備範囲を確認した。現状は明確に分かれている。

| スキル | 守備範囲 |
| --- | --- |
| `pptx` | 汎用。あらゆる .pptx/.potx の読み書き |
| `marni-deck` | Marni ブランドテンプレート専用のデッキ生成 |
| `qa-pptx-generator` | 4択問題＋解説スライドの一括生成 |
| `pptx-translate` | 既存 PPTX のテキストのみ翻訳（デザイン保持） |
| `pdf-to-pptx-layers` | PDF/画像スライド → 編集可能レイヤー付き PPTX |

## 検査方法

`~/.claude/skills/synced/` 配下の全 `SKILL.md` に対し、

1. `grep` で絶対パス参照（`/mnt/...`, `/home/...`）を抽出し、各パスの実在を確認
2. 相対参照（`scripts/` `references/` `assets/` `templates/` 配下）を正規表現で抽出し、スキルディレクトリ内での実在を確認
3. ヒットした各件を `SKILL.md` の該当行まで遡って精査し、真の破損と誤検知を分離
