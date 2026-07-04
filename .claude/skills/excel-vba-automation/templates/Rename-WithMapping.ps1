<#
==============================================================
 対応表CSVを使ったファイル名一括変換（PowerShell版）
--------------------------------------------------------------
 Excel/VBAが使えない環境向けの代替スクリプトです。
 対応表CSV（1列目=旧名、2列目=新名、拡張子なし、見出し行あり）を
 参照して、選択したフォルダ内のファイル名を一括変換します。

 対応表CSVの例（UTF-8またはShift-JISで保存）:
   旧名,新名
   請求書001,2026年6月_田中商事
   請求書002,2026年6月_佐藤工業

 実行方法:
   1. このファイルを右クリック →「PowerShellで実行」
   2. うまく動かない場合は PowerShell を開いて次を実行:
      Set-ExecutionPolicy -Scope Process RemoteSigned
      cd スクリプトのあるフォルダ
      .\Rename-WithMapping.ps1
==============================================================
#>

#▼▼▼ カスタマイズ箇所 ▼▼▼
$TargetExt  = "pdf"    # 変換対象の拡張子（"pdf" / "xlsx" など。ドット不要）
$MakeBackup = $true    # バックアップを作る場合は $true
#▲▲▲ カスタマイズ箇所ここまで ▲▲▲

# フォルダ選択・ファイル選択ダイアログを使うための準備
Add-Type -AssemblyName System.Windows.Forms

#--- 1. 対象フォルダを選択させる
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "名前を変更したいファイルがあるフォルダを選択してください"
if ($folderDialog.ShowDialog() -ne "OK") { exit }   # キャンセルなら終了
$folderPath = $folderDialog.SelectedPath

#--- 2. 対応表CSVを選択させる
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.Title  = "対応表のCSVファイルを選択してください"
$fileDialog.Filter = "CSVファイル (*.csv)|*.csv"
if ($fileDialog.ShowDialog() -ne "OK") { exit }
$mappingPath = $fileDialog.FileName

#--- 3. 対応表を読み込んで「旧名→新名」の辞書を作る
$mapping = @{}
Import-Csv -Path $mappingPath -Encoding Default |
    ForEach-Object {
        # 1列目・2列目を列名に関係なく取り出す
        $values  = $_.PSObject.Properties.Value
        $oldName = ("" + $values[0]).Trim()
        $newName = ("" + $values[1]).Trim()
        if ($oldName -ne "" -and $newName -ne "" -and -not $mapping.ContainsKey($oldName)) {
            $mapping[$oldName] = $newName
        }
    }
if ($mapping.Count -eq 0) {
    Write-Host "対応表にデータがありません。1列目=旧名、2列目=新名 で入力してください。" -ForegroundColor Red
    Read-Host "Enterキーで終了します"
    exit
}

#--- 4. バックアップフォルダとログの準備
$stamp   = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path $folderPath "リネームログ_$stamp.txt"
if ($MakeBackup) {
    $backupFolder = Join-Path $folderPath "backup_$stamp"
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
}

# ログに1行追記する小さな関数
function Write-Log([string]$message) {
    "{0}`t{1}" -f (Get-Date -Format "yyyy/MM/dd HH:mm:ss"), $message |
        Add-Content -Path $logPath -Encoding Default
}

#--- 5. フォルダ内の対象ファイルを1つずつ処理（エラーがあっても続行）
$okCount = 0
$ngCount = 0
Get-ChildItem -Path $folderPath -Filter "*.$TargetExt" -File | ForEach-Object {
    $baseName = $_.BaseName    # 拡張子を除いたファイル名
    try {
        if (-not $mapping.ContainsKey($baseName)) {
            Write-Log "$($_.Name)`t対応表に見つからないためスキップしました"
            $script:ngCount++
            return
        }
        $newFileName = $mapping[$baseName] + $_.Extension
        if (Test-Path (Join-Path $folderPath $newFileName)) {
            Write-Log "$($_.Name)`t変更先「$newFileName」が既に存在するためスキップしました"
            $script:ngCount++
            return
        }
        if ($MakeBackup) {
            Copy-Item -Path $_.FullName -Destination $backupFolder   # 先にバックアップ
        }
        Rename-Item -Path $_.FullName -NewName $newFileName -ErrorAction Stop
        $script:okCount++
    }
    catch {
        Write-Log "$($_.Name)`tエラー: $($PSItem.Exception.Message)"
        $script:ngCount++
    }
}

#--- 6. 結果表示
Write-Host ""
Write-Host "処理が完了しました。 成功: $okCount 件 / 失敗: $ngCount 件"
if ($ngCount -gt 0) {
    Write-Host "失敗の詳細はログを確認してください: $logPath" -ForegroundColor Yellow
}
Read-Host "Enterキーで終了します"
