Attribute VB_Name = "Template_ExcelBatch"
Option Explicit
'==============================================================
' Excelファイル一括処理テンプレート
'--------------------------------------------------------------
' 指定フォルダ内のExcelファイルを1つずつ開き、
' 指定シートの指定セル（範囲）を一括変更して保存します。
'
' 標準仕様:
'   ・フォルダは実行のたびにダイアログで選択
'   ・シート名・セル範囲・書き込む値は実行時にInputBoxで確認
'   ・処理前に backup_日付時刻 フォルダへ元ファイルをコピー
'   ・シート保護があれば解除→処理→再保護
'   ・エラーのファイルはスキップしてログに記録
'   ・最後に成功件数・失敗件数を表示
'
' ※ modCommon.bas を同じブックに追加してから使ってください
'==============================================================

'▼▼▼ カスタマイズ箇所 ▼▼▼
Private Const TARGET_EXT As String = "xlsx"     ' 対象拡張子（"xlsx" / "xlsm" / "xls" など）
Private Const SHEET_PASSWORD As String = ""     ' シート保護のパスワード（無い場合は "" のまま）
Private Const MAKE_BACKUP As Boolean = True     ' バックアップを作る場合は True
'▲▲▲ カスタマイズ箇所ここまで ▲▲▲

Public Sub BatchProcessExcelFiles()
    Dim folderPath As String        ' 処理対象フォルダ
    Dim backupFolder As String      ' バックアップフォルダ
    Dim logPath As String           ' エラーログのパス
    Dim sheetName As String         ' 対象シート名
    Dim rangeAddress As String      ' 対象セル範囲（例: B2 や A1:C10）
    Dim newValue As String          ' 書き込む値
    Dim fileName As String          ' Dir関数で取得するファイル名
    Dim okCount As Long             ' 成功件数
    Dim ngCount As Long             ' 失敗件数

    '--- 1. フォルダを選択させる（標準仕様1）
    folderPath = SelectFolder("処理対象のフォルダを選択してください")
    If folderPath = "" Then Exit Sub            ' キャンセルされたら何もせず終了

    '--- 2. シート名・セル範囲・値をユーザーに確認する（標準仕様4・5）
    sheetName = InputBox("対象のシート名を入力してください（例: Sheet1）", "シート名の確認")
    If sheetName = "" Then Exit Sub

    rangeAddress = InputBox("対象のセルまたは範囲を入力してください（例: B2 または A1:C10）", "セル範囲の確認")
    If rangeAddress = "" Then Exit Sub

    newValue = InputBox("書き込む値を入力してください", "値の入力")
    ' ※ 空文字を書き込みたい場合はこの If を削除してください
    If newValue = "" Then Exit Sub

    '--- 3. バックアップフォルダとログの準備（標準仕様7・8）
    logPath = folderPath & "\エラーログ_" & Format(Now, "yyyymmdd_hhnnss") & ".txt"
    If MAKE_BACKUP Then
        backupFolder = CreateBackupFolder(folderPath)
    End If

    '--- 4. 画面更新と警告表示を一時的に止めて高速化
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False

    '--- 5. フォルダ内の対象ファイルを1つずつ処理
    fileName = Dir(folderPath & "\*." & TARGET_EXT)   ' 拡張子を限定（標準仕様2）
    Do While fileName <> ""
        If ProcessOneFile(folderPath & "\" & fileName, sheetName, rangeAddress, _
                          newValue, backupFolder, logPath) Then
            okCount = okCount + 1
        Else
            ngCount = ngCount + 1
        End If
        fileName = Dir()                              ' 次のファイルへ
    Loop

    '--- 6. 後片付け（DisplayAlerts / ScreenUpdating の戻し忘れ防止）
    Application.ScreenUpdating = True
    Application.DisplayAlerts = True

    '--- 7. 結果表示（標準仕様9）
    ShowResult okCount, ngCount, logPath
End Sub

'--------------------------------------------------------------
' 1ファイル分の処理。成功なら True、失敗なら False を返す。
' エラーが起きてもここで握りつぶしてログに記録するので、
' 呼び出し元のループは止まらない（標準仕様8）。
'--------------------------------------------------------------
Private Function ProcessOneFile(ByVal filePath As String, _
                                ByVal sheetName As String, _
                                ByVal rangeAddress As String, _
                                ByVal newValue As String, _
                                ByVal backupFolder As String, _
                                ByVal logPath As String) As Boolean
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim wasProtected As Boolean

    On Error GoTo ErrHandler

    '--- バックアップを取ってから処理する（標準仕様7）
    If MAKE_BACKUP Then
        BackupFile filePath, backupFolder
    End If

    '--- ファイルを開く
    Set wb = Workbooks.Open(fileName:=filePath, UpdateLinks:=0, ReadOnly:=False)
    Set ws = wb.Worksheets(sheetName)   ' シートが無ければここでエラー→ログへ

    '--- シート保護があれば解除（標準仕様6）
    wasProtected = UnprotectIfNeeded(ws, SHEET_PASSWORD)

    '▼▼▼ カスタマイズ箇所: ここが実際の処理内容 ▼▼▼
    ' 例1: 指定範囲に同じ値を書き込む（初期状態）
    ws.Range(rangeAddress).Value = newValue

    ' 例2: 指定セルの値を置換したい場合（例1を消して使う）
    '   ws.Range(rangeAddress).Replace What:="旧文字", Replacement:="新文字", LookAt:=xlPart

    ' 例3: 数式を入れたい場合（例1を消して使う）
    '   ws.Range(rangeAddress).Formula = "=SUM(A1:A10)"
    '▲▲▲ カスタマイズ箇所ここまで ▲▲▲

    '--- 保護を解除していた場合は再保護（標準仕様6）
    ReprotectIfNeeded ws, wasProtected, SHEET_PASSWORD

    '--- 保存して閉じる（ファイルを開いたら必ず閉じる）
    wb.Close SaveChanges:=True
    Set wb = Nothing

    ProcessOneFile = True
    Exit Function

ErrHandler:
    '--- エラー内容をログに記録し、開いていたブックは保存せずに閉じる
    WriteLog logPath, filePath & vbTab & "エラー番号:" & Err.Number & vbTab & Err.Description
    If Not wb Is Nothing Then
        wb.Close SaveChanges:=False
        Set wb = Nothing
    End If
    ProcessOneFile = False
End Function
