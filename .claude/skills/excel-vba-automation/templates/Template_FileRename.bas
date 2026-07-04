Attribute VB_Name = "Template_FileRename"
Option Explicit
'==============================================================
' 対応表を使ったファイル名一括変換テンプレート（PDF等）
'--------------------------------------------------------------
' VLOOKUPのように「対応表Excel」を参照して、フォルダ内の
' ファイル名を一括変換します。
'
' 対応表Excelの形式（1シート目を使用）:
'   ・A列 = 現在のファイル名（拡張子なし。例: 請求書001）
'   ・B列 = 新しいファイル名（拡張子なし。例: 2026年6月_田中商事）
'   ・1行目は見出し行として読み飛ばします
'
' 標準仕様:
'   ・対象フォルダと対応表ファイルは実行のたびに選択
'   ・対象拡張子は定数で明確に指定（初期値: pdf）
'   ・変更前に backup_日付時刻 フォルダへ元ファイルをコピー
'   ・対応表に無いファイル、変更失敗はログに記録して続行
'   ・最後に成功件数・失敗件数を表示
'
' ※ modCommon.bas を同じブックに追加してから使ってください
'==============================================================

'▼▼▼ カスタマイズ箇所 ▼▼▼
Private Const TARGET_EXT As String = "pdf"      ' 変換対象の拡張子（"pdf" / "xlsx" など）
Private Const MAKE_BACKUP As Boolean = True     ' バックアップを作る場合は True
Private Const HEADER_ROWS As Long = 1           ' 対応表の見出し行数（見出しが無い場合は 0）
'▲▲▲ カスタマイズ箇所ここまで ▲▲▲

Public Sub RenameFilesWithMapping()
    Dim folderPath As String        ' 対象ファイルのあるフォルダ
    Dim mappingPath As String       ' 対応表Excelのパス
    Dim backupFolder As String      ' バックアップフォルダ
    Dim logPath As String           ' ログファイルのパス
    Dim mapping As Object           ' 対応表を入れる辞書（旧名→新名）
    Dim fileName As String          ' 処理中のファイル名
    Dim baseName As String          ' 拡張子を除いたファイル名
    Dim newName As String           ' 変更後のファイル名
    Dim okCount As Long             ' 成功件数
    Dim ngCount As Long             ' 失敗件数

    '--- 1. 対象フォルダを選択させる
    folderPath = SelectFolder("名前を変更したいファイルがあるフォルダを選択してください")
    If folderPath = "" Then Exit Sub

    '--- 2. 対応表Excelを選択させる（標準仕様3）
    mappingPath = SelectFile("対応表のExcelファイルを選択してください", _
                             "Excelファイル", "*.xlsx; *.xlsm; *.xls")
    If mappingPath = "" Then Exit Sub

    '--- 3. 対応表を辞書に読み込む（失敗したらここで終了）
    Set mapping = LoadMapping(mappingPath)
    If mapping Is Nothing Then Exit Sub
    If mapping.Count = 0 Then
        MsgBox "対応表にデータがありません。A列=旧名、B列=新名 で入力してください。", vbExclamation
        Exit Sub
    End If

    '--- 4. バックアップフォルダとログの準備
    logPath = folderPath & "\リネームログ_" & Format(Now, "yyyymmdd_hhnnss") & ".txt"
    If MAKE_BACKUP Then
        backupFolder = CreateBackupFolder(folderPath)
    End If

    '--- 5. フォルダ内の対象ファイルを1つずつ処理
    fileName = Dir(folderPath & "\*." & TARGET_EXT)
    Do While fileName <> ""
        ' 拡張子を除いた部分で対応表を検索する
        baseName = Left(fileName, InStrRev(fileName, ".") - 1)

        If mapping.Exists(baseName) Then
            newName = mapping(baseName) & "." & TARGET_EXT
            If RenameOneFile(folderPath, fileName, newName, backupFolder, logPath) Then
                okCount = okCount + 1
            Else
                ngCount = ngCount + 1
            End If
        Else
            ' 対応表に無いファイルは変更せず、ログにだけ残す
            WriteLog logPath, fileName & vbTab & "対応表に見つからないためスキップしました"
            ngCount = ngCount + 1
        End If

        fileName = Dir()
    Loop

    '--- 6. 結果表示
    ShowResult okCount, ngCount, logPath
End Sub

'--------------------------------------------------------------
' 対応表Excelを開いて「旧名→新名」の辞書を作って返す
' 読み込みに失敗した場合は Nothing を返す
'--------------------------------------------------------------
Private Function LoadMapping(ByVal mappingPath As String) As Object
    Dim wb As Workbook
    Dim ws As Worksheet
    Dim dict As Object
    Dim lastRow As Long
    Dim r As Long
    Dim oldName As String
    Dim newName As String

    On Error GoTo ErrHandler

    Set dict = CreateObject("Scripting.Dictionary")   ' 参照設定なしで使える辞書
    dict.CompareMode = 1                              ' 大文字・小文字を区別しない

    Set wb = Workbooks.Open(fileName:=mappingPath, UpdateLinks:=0, ReadOnly:=True)
    Set ws = wb.Worksheets(1)                         ' 1シート目を対応表とみなす

    lastRow = ws.Cells(ws.Rows.Count, "A").End(xlUp).Row
    For r = HEADER_ROWS + 1 To lastRow
        oldName = Trim(CStr(ws.Cells(r, "A").Value))  ' A列 = 旧ファイル名
        newName = Trim(CStr(ws.Cells(r, "B").Value))  ' B列 = 新ファイル名
        If oldName <> "" And newName <> "" Then
            If Not dict.Exists(oldName) Then
                dict.Add oldName, newName
            End If
        End If
    Next r

    wb.Close SaveChanges:=False                       ' 開いたら必ず閉じる
    Set LoadMapping = dict
    Exit Function

ErrHandler:
    If Not wb Is Nothing Then wb.Close SaveChanges:=False
    MsgBox "対応表の読み込みに失敗しました。" & vbCrLf & Err.Description, vbCritical
    Set LoadMapping = Nothing
End Function

'--------------------------------------------------------------
' 1ファイルの名前を変更する。成功なら True、失敗なら False。
' 変更先に同名ファイルがある場合は失敗としてログに残す。
'--------------------------------------------------------------
Private Function RenameOneFile(ByVal folderPath As String, _
                               ByVal oldFileName As String, _
                               ByVal newFileName As String, _
                               ByVal backupFolder As String, _
                               ByVal logPath As String) As Boolean
    On Error GoTo ErrHandler

    '--- 変更先に同じ名前のファイルが既にあれば上書きせずスキップ
    If Dir(folderPath & "\" & newFileName) <> "" Then
        WriteLog logPath, oldFileName & vbTab & "変更先「" & newFileName & "」が既に存在するためスキップしました"
        RenameOneFile = False
        Exit Function
    End If

    '--- バックアップしてから名前を変更
    If MAKE_BACKUP Then
        BackupFile folderPath & "\" & oldFileName, backupFolder
    End If
    Name folderPath & "\" & oldFileName As folderPath & "\" & newFileName

    RenameOneFile = True
    Exit Function

ErrHandler:
    WriteLog logPath, oldFileName & vbTab & "エラー番号:" & Err.Number & vbTab & Err.Description
    RenameOneFile = False
End Function
