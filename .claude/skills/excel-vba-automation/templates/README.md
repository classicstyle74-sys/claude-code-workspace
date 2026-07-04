# 標準VBAテンプレート一覧

すべて **Option Explicit・変数宣言・エラー処理・バックアップ・エラーログ・成功/失敗件数表示** を組み込んだ、コピペで動く完成版です。
`.bas` ファイルは VBE（Alt+F11）の「ファイル → ファイルのインポート」で取り込むか、標準モジュールに全文を貼り付けて使います。

| ファイル | 実行するマクロ | 用途 |
|---|---|---|
| `BatchProcessExcel.bas` | `BatchProcessExcelFiles` | フォルダ内Excelファイルの一括処理（汎用の骨格） |
| `RenamePdfFiles.bas` | `RenamePdfFilesInFolder` | PDFファイル名の一括変更（前後付加・置換ルール） |
| `CopyFormatFromTemplate.bas` | `CopyFormatToAllFiles` | ひな型Excelから書式のみを全ファイルへコピー |
| `CopyFormulasFromTemplate.bas` | `CopyFormulasToAllFiles` | ひな型Excelから数式（関数）のみを全ファイルへコピー |
| `BulkUpdateCells.bas` | `BulkUpdateCellsInFolder` | 任意シート・任意セルへの値の一括書き込み |
| `ExportFileList.bas` | `ExportFileListToExcel` | フォルダ内ファイル一覧を新規ブックへ出力 |
| `RenameFilesWithMapping.bas` | `RenameFilesUsingMapping` | 対応表Excel（旧名→新名）によるファイル名一括変換 |
| `ExportFileList.ps1` | ―（PowerShell） | ファイル一覧のCSV出力（Excel不要） |
| `RenameFilesWithMapping.ps1` | ―（PowerShell） | 対応表CSVによるファイル名一括変換（Excel不要） |

## 共通の設定定数

各 `.bas` の先頭にある定数を必要に応じて書き換えてください。

- `TARGET_EXT` — 対象ファイルの拡張子（例: `*.xlsx`、`*.pdf`）
- `PROTECT_PASSWORD` — シート保護のパスワード（保護なし・パスワードなしなら空欄のまま）
- `MAKE_BACKUP` — 処理前にバックアップフォルダを作るか（原則 `True` のまま）

シート保護があるブックは、自動で「保護解除 → 処理 → 再保護」を行います。
