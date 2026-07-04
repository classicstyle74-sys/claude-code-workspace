Attribute VB_Name = "Template_CopyFromTemplate"
Option Explicit
'==============================================================
' ひな型Excelから書式・関数（数式）コピーテンプレート
'--------------------------------------------------------------
' 実行時に選択した「ひな型Excel」の指定シート・指定範囲から、
' フォルダ内すべてのExcelファイルの同じシート・同じ範囲へ
' 「書式」または「数式」をコピーします。
'
' 標準仕様:
'   ・ひな型ファイルと対象フォルダは実行のたびに選択
'   ・シート名・対象範囲は実行時にInputBoxで確認
'   ・コピー内容（書式 / 数式 / 両方）は実行時に選択
'   ・処理前に backup_日付時刻 フォルダへ元ファイルをコピー
'   ・シート保護があれば解除→処理→再保護
'   ・エラーのファイルはスキップしてログに記録
'   ・最後に成功件数・失敗件数を表示
'
' ※ modCommon.bas を同じブックに追加してから使ってください
'==============================================================

'▼▼▼ カスタマイズ箇所 ▼▼▼
Private Const TARGET_EXT As String = "xlsx"     ' 対象拡張子（"xlsx" / "xlsm" など）
Private Const SHEET_PASSWORD As String = ""     ' シート保護のパスワード（無い場合は "" のまま）
Private Const MAKE_BACKUP As Boolean = True     ' バックアップを作る場合は True
'▲▲▲ カスタマイズ箇所ここまで ▲▲▲

' コピーする内容を表す値（CopyFromTemplate内で使用）
Private Enum CopyMode
    FormatsOnly = 1     ' 書式のみ
    FormulasOnly = 2    ' 数式のみ
    FormatsAndFormulas = 3 ' 書式と数式の両方
End Enum

Public Sub CopyFromTemplate()
    Dim templatePath As String      ' ひな型ファイルのパス
    Dim folderPath As String        ' 対象フォルダ
    Dim backupFolder As String      ' バックアップフォルダ
    Dim logPath As String           ' ログファイルのパス
    Dim sheetName As String         ' 対象シート名
    Dim rangeAddress As String      ' 対象範囲（例: A1:C10）
    Dim modeAnswer As String        ' コピー内容の選択結果
    Dim mode As CopyMode            ' コピーする内容
    Dim tmplWb As Workbook          ' ひな型ブック
    Dim tmplWs As Worksheet         ' ひな型シート
    Dim fileName As String          ' 処理中のファイル名
    Dim okCount As Long             ' 成功件数
    Dim ngCount As Long             ' 失敗件数

    '--- 1. ひな型ファイルを選択させる（標準仕様3）
    templatePath = SelectFile("ひな型のExcelファイルを選択してください", _
                              "Excelファイル", "*.xlsx; *.xlsm; *.xls")
    If templatePath = "" Then Exit Sub

    '--- 2. 対象フォルダを選択させる（標準仕様1）
    folderPath = SelectFolder("コピー先のExcelファイルがあるフォルダを選択してください")
    If folderPath = "" Then Exit Sub

    '--- 3. シート名・対象範囲・コピー内容を確認する（標準仕様4・5）
    sheetName = InputBox("対象のシート名を入力してください（ひな型・コピー先とも同じ名前）", "シート名の確認")
    If sheetName = "" Then Exit Sub

    rangeAddress = InputBox("コピーする範囲を入力してください（例: A1:C10）", "範囲の確認")
    If rangeAddress = "" Then Exit Sub

    modeAnswer = InputBox("コピーする内容を番号で入力してください" & vbCrLf & _
                          "1 = 書式のみ" & vbCrLf & _
                          "2 = 数式のみ" & vbCrLf & _
                          "3 = 書式と数式の両方", "コピー内容の選択", "1")
    Select Case modeAnswer
        Case "1": mode = FormatsOnly
        Case "2": mode = FormulasOnly
        Case "3": mode = FormatsAndFormulas
        Case Else: Exit Sub                     ' キャンセルまたは不正な入力
    End Select

    '--- 4. バックアップフォルダとログの準備（標準仕様7・8）
    logPath = folderPath & "\エラーログ_" & Format(Now, "yyyymmdd_hhnnss") & ".txt"
    If MAKE_BACKUP Then
        backupFolder = CreateBackupFolder(folderPath)
    End If

    '--- 5. 画面更新と警告を一時停止
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False

    On Error GoTo Cleanup   ' 想定外エラーでも必ず後片付けを通す

    '--- 6. ひな型を読み取り専用で開く
    Set tmplWb = Workbooks.Open(fileName:=templatePath, UpdateLinks:=0, ReadOnly:=True)
    Set tmplWs = tmplWb.Worksheets(sheetName)

    '--- 7. フォルダ内の対象ファイルを1つずつ処理
    fileName = Dir(folderPath & "\*." & TARGET_EXT)
    Do While fileName <> ""
        ' ひな型自身が対象フォルダに入っている場合はスキップ
        If StrComp(folderPath & "\" & fileName, templatePath, vbTextCompare) <> 0 Then
            If CopyToOneFile(tmplWs, folderPath & "\" & fileName, sheetName, _
                             rangeAddress, mode, backupFolder, logPath) Then
                okCount = okCount + 1
            Else
                ngCount = ngCount + 1
            End If
        End If
        fileName = Dir()
    Loop

Cleanup:
    '--- 8. 後片付け（エラー時もここを必ず通る）
    If Err.Number <> 0 Then
        WriteLog logPath, "処理全体のエラー" & vbTab & "エラー番号:" & Err.Number & vbTab & Err.Description
        ngCount = ngCount + 1
    End If
    On Error Resume Next
    If Not tmplWb Is Nothing Then tmplWb.Close SaveChanges:=False   ' 開いたら必ず閉じる
    Application.CutCopyMode = False                                 ' コピー状態を解除
    Application.ScreenUpdating = True
    Application.DisplayAlerts = True
    On Error GoTo 0

    '--- 9. 結果表示（標準仕様9）
    ShowResult okCount, ngCount, logPath
End Sub

'--------------------------------------------------------------
' ひな型シートから1ファイルへコピーする。成功なら True。
' エラーはログに記録して False を返す（ループは止まらない）。
'--------------------------------------------------------------
Private Function CopyToOneFile(ByVal tmplWs As Worksheet, _
                               ByVal filePath As String, _
                               ByVal sheetName As String, _
                               ByVal rangeAddress As String, _
                               ByVal mode As CopyMode, _
                               ByVal backupFolder As String, _
                               ByVal logPath As String) As Boolean
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim wasProtected As Boolean

    On Error GoTo ErrHandler

    '--- バックアップを取ってから処理する
    If MAKE_BACKUP Then
        BackupFile filePath, backupFolder
    End If

    '--- コピー先を開く
    Set wb = Workbooks.Open(fileName:=filePath, UpdateLinks:=0, ReadOnly:=False)
    Set ws = wb.Worksheets(sheetName)

    '--- シート保護があれば解除（標準仕様6）
    wasProtected = UnprotectIfNeeded(ws, SHEET_PASSWORD)

    '--- ひな型の範囲をコピーして、選んだ内容だけ貼り付ける
    tmplWs.Range(rangeAddress).Copy
    If mode = FormatsOnly Or mode = FormatsAndFormulas Then
        ws.Range(rangeAddress).PasteSpecial Paste:=xlPasteFormats       ' 書式
    End If
    If mode = FormulasOnly Or mode = FormatsAndFormulas Then
        ws.Range(rangeAddress).PasteSpecial Paste:=xlPasteFormulas      ' 数式
    End If
    Application.CutCopyMode = False     ' コピー状態（点線枠）を解除

    '--- 再保護して保存・クローズ
    ReprotectIfNeeded ws, wasProtected, SHEET_PASSWORD
    wb.Close SaveChanges:=True
    Set wb = Nothing

    CopyToOneFile = True
    Exit Function

ErrHandler:
    WriteLog logPath, filePath & vbTab & "エラー番号:" & Err.Number & vbTab & Err.Description
    If Not wb Is Nothing Then
        wb.Close SaveChanges:=False
        Set wb = Nothing
    End If
    CopyToOneFile = False
End Function
