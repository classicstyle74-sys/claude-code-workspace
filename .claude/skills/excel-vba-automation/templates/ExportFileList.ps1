# =============================================================================
# ファイル一覧出力テンプレート（PowerShell版）
# -----------------------------------------------------------------------------
# 概要   : 選択したフォルダ内のファイル一覧（名前・拡張子・サイズ・更新日時）
#          をCSVファイルに書き出します。Excelがなくても実行できます。
# 実行方法:
#   1) このファイルを ExportFileList.ps1 という名前で保存する
#   2) スタートメニューから「PowerShell」を起動して、以下を実行する
#      powershell -ExecutionPolicy Bypass -File .\ExportFileList.ps1
# =============================================================================

# --- 設定（必要に応じて変更してください：カスタマイズ箇所） ------------------
$targetExt = "*.*"    # 対象ファイルの拡張子（例: "*.xlsx"、"*.pdf"、全部なら "*.*"）
# -----------------------------------------------------------------------------

# --- 1) フォルダ選択ダイアログを表示する ---
Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
$dialog.Description = "一覧を出力するフォルダを選択してください"
if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "キャンセルされました。"
    exit
}
$targetFolder = $dialog.SelectedPath

# --- 2) ファイル一覧を取得してCSVに出力する ---
try {
    $files = Get-ChildItem -Path $targetFolder -Filter $targetExt -File

    # 出力する項目を整える（日本語の列名にする）
    $list = $files | Select-Object `
        @{Name = "ファイル名"; Expression = { $_.Name } }, `
        @{Name = "拡張子";     Expression = { $_.Extension.TrimStart(".") } }, `
        @{Name = "サイズ(KB)"; Expression = { [math]::Round($_.Length / 1KB, 1) } }, `
        @{Name = "更新日時";   Expression = { $_.LastWriteTime.ToString("yyyy/MM/dd HH:mm") } }, `
        @{Name = "フルパス";   Expression = { $_.FullName } }

    # CSVはExcelで開けるようにShift-JIS系（Default）ではなくBOM付きUTF-8で保存する
    $csvPath = Join-Path $targetFolder ("ファイル一覧_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".csv")
    $list | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

    # --- 3) 件数を表示する ---
    Write-Host "ファイル一覧を出力しました。"
    Write-Host ("件数  : " + $files.Count + " 件")
    Write-Host ("出力先: " + $csvPath)
}
catch {
    # エラーが起きた場合は内容を表示して終了する
    Write-Host ("エラーが発生しました: " + $_.Exception.Message)
}

Read-Host "Enterキーを押すと終了します"
