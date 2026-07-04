# =============================================================================
# 対応表を使ったファイル名変換テンプレート（PowerShell版）
# -----------------------------------------------------------------------------
# 概要   : 対応表CSV（1列目=旧ファイル名、2列目=新ファイル名、1行目は見出し）
#          をもとに、選択したフォルダ内のファイル名を一括変換します。
#          Excelがなくても実行できます。VLOOKUPで検索するのと同じ考え方です。
# 対応表 : 例）mapping.csv
#            旧ファイル名,新ファイル名
#            見積書001.pdf,2026年度_見積書_A社.pdf
#            見積書002.pdf,2026年度_見積書_B社.pdf
# 実行方法:
#   1) このファイルを RenameFilesWithMapping.ps1 という名前で保存する
#   2) スタートメニューから「PowerShell」を起動して、以下を実行する
#      powershell -ExecutionPolicy Bypass -File .\RenameFilesWithMapping.ps1
# =============================================================================

# --- 設定（必要に応じて変更してください：カスタマイズ箇所） ------------------
$targetExt  = "*.pdf"   # 対象ファイルの拡張子（Excelなら "*.xlsx"）
$makeBackup = $true     # 変更前にバックアップを作成するか
# -----------------------------------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms

# --- 1) 対応表CSVを実行時に選択させる ---
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.Title = "対応表のCSVファイルを選択してください（1列目=旧名、2列目=新名）"
$fileDialog.Filter = "CSVファイル (*.csv)|*.csv"
if ($fileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "キャンセルされました。"
    exit
}
$mappingPath = $fileDialog.FileName

# --- 2) 対象フォルダを実行のたびに選択させる ---
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "名前を変更するファイルがあるフォルダを選択してください"
if ($folderDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "キャンセルされました。"
    exit
}
$targetFolder = $folderDialog.SelectedPath

# --- 3) 対応表を読み込み、辞書（ハッシュテーブル）に入れる ---
# 辞書を使うとVLOOKUPと同じように「旧名で検索→新名を取得」ができます
$mapping = @{}
try {
    $csv = Import-Csv -Path $mappingPath -Encoding UTF8
    $columns = $csv[0].PSObject.Properties.Name   # 1列目・2列目の見出し名を取得する
    foreach ($row in $csv) {
        $oldName = ($row.($columns[0])).Trim()
        $newName = ($row.($columns[1])).Trim()
        if ($oldName -ne "" -and $newName -ne "" -and -not $mapping.ContainsKey($oldName)) {
            $mapping[$oldName] = $newName
        }
    }
}
catch {
    Write-Host ("対応表の読み込みに失敗しました: " + $_.Exception.Message)
    Read-Host "Enterキーを押すと終了します"
    exit
}

if ($mapping.Count -eq 0) {
    Write-Host "対応表にデータがありません。1列目に旧名、2列目に新名を入力してください。"
    Read-Host "Enterキーを押すと終了します"
    exit
}

# --- 4) バックアップフォルダを作成する ---
if ($makeBackup) {
    $backupFolder = Join-Path $targetFolder ("backup_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
    New-Item -Path $backupFolder -ItemType Directory | Out-Null
}

# --- 5) フォルダ内のファイルを順番に変換する ---
$successCount = 0
$failCount    = 0
$logLines     = @()

foreach ($file in Get-ChildItem -Path $targetFolder -Filter $targetExt -File) {
    # 対応表を検索する（拡張子付き優先、なければ拡張子なしで検索）
    $newName = $null
    if ($mapping.ContainsKey($file.Name)) {
        $newName = $mapping[$file.Name]
    }
    elseif ($mapping.ContainsKey($file.BaseName)) {
        $newName = $mapping[$file.BaseName]
    }

    if (-not $newName) {
        # 対応表に無いファイルはスキップ（ログにだけ残す）
        $logLines += ("スキップ: " + $file.Name + " （対応表に無し）")
        continue
    }

    # 新名に拡張子が無ければ元の拡張子を付ける
    if (-not [System.IO.Path]::HasExtension($newName)) {
        $newName = $newName + $file.Extension
    }

    try {
        $newPath = Join-Path $targetFolder $newName
        if (Test-Path $newPath) {
            # 同名ファイルが既にある場合は失敗として記録する（エラー処理で全体は止めない）
            throw ("変更先 " + $newName + " が既に存在")
        }

        # バックアップしてからリネームする
        if ($makeBackup) {
            Copy-Item -Path $file.FullName -Destination (Join-Path $backupFolder $file.Name)
        }
        Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop

        $successCount++
        $logLines += ("成功: " + $file.Name + " → " + $newName)
    }
    catch {
        $failCount++
        $logLines += ("失敗: " + $file.Name + " （" + $_.Exception.Message + "）")
    }
}

# --- 6) ログファイルを出力する ---
$logPath = Join-Path $targetFolder ("名前変換ログ_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")
$header = @(
    ("処理日時: " + (Get-Date -Format "yyyy/MM/dd HH:mm:ss")),
    "--------------------------------------"
)
($header + $logLines) | Out-File -FilePath $logPath -Encoding UTF8

# --- 7) 成功・失敗件数を表示する ---
Write-Host "名前変換が完了しました。"
Write-Host ("成功: " + $successCount + " 件")
Write-Host ("失敗: " + $failCount + " 件")
Write-Host ("ログ: " + $logPath)
Read-Host "Enterキーを押すと終了します"
