Attribute VB_Name = "RenameFilesWithMapping"
Option Explicit

'==============================================================================
' 対応表を使ったファイル名変換テンプレート（VLOOKUP方式）
'------------------------------------------------------------------------------
' 概要   : 実行時に選択した「対応表Excel」（A列=現在のファイル名、
'          B列=新しいファイル名）をもとに、選択したフォルダ内のファイル名を
'          一括変換します。VLOOKUPで検索するのと同じ考え方です。
' 対応表 : 1行目は見出し（例: A1「旧ファイル名」B1「新ファイル名」）、
'          2行目からデータを入力してください。
'          ファイル名は拡張子付き（例: 見積書001.pdf）でも拡張子なしでも
'          構いません（拡張子なしの場合は元の拡張子を引き継ぎます）。
' 使い方 : VBE（Alt+F11）→ 挿入 → 標準モジュール に全文を貼り付けて、
'          RenameFilesUsingMapping を実行してください。
' 特徴   : 対応表選択 / フォルダ選択 / バックアップ / エラーログ /
'          成功・失敗件数の表示
'==============================================================================

'--- 設定（必要に応じて変更してください：カスタマイズ箇所） -------------------
Private Const TARGET_EXT As String = "*.pdf"    ' 対象ファイルの拡張子（Excelなら "*.xlsx"）
Private Const MAKE_BACKUP As Boolean = True     ' 変更前にバックアップを作成するか
Private Const MAP_SHEET_INDEX As Long = 1       ' 対応表のシート位置（通常は1枚目）
'------------------------------------------------------------------------------

Public Sub RenameFilesUsingMapping()
    Dim mappingPath As String       ' 対応表Excelのパス
    Dim targetFolder As String      ' 処理対象フォルダ
    Dim backupFolder As String      ' バックアップ先フォルダ
    Dim wbMap As Workbook           ' 対応表ブック
    Dim wsMap As Worksheet          ' 対応表シート
    Dim mapDict As Object           ' 対応表を入れる辞書（旧名→新名）
    Dim lastRow As Long             ' 対応表の最終行
    Dim i As Long                   ' ループ用
    Dim oldKey As String            ' 対応表の旧ファイル名
    Dim newName As String           ' 変換後のファイル名
    Dim fileName As String          ' 現在のファイル名
    Dim baseName As String          ' 拡張子を除いたファイル名
    Dim extName As String           ' 拡張子（ドット付き）
    Dim dotPos As Long              ' ドットの位置
    Dim successCount As Long        ' 成功件数
    Dim failCount As Long           ' 失敗件数
    Dim logText As String           ' ログの内容
    Dim logPath As String           ' ログファイルの保存先

    '--- 1) 対応表Excelを実行時に選択させる ---
    mappingPath = SelectExcelFile("対応表のExcelファイルを選択してください（A列=旧名、B列=新名）")
    If mappingPath = "" Then Exit Sub

    '--- 2) 対象フォルダを実行のたびに選択させる ---
    targetFolder = SelectFolder("名前を変更するファイルがあるフォルダを選択してください")
    If targetFolder = "" Then Exit Sub

    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    On Error GoTo Cleanup

    '--- 3) 対応表を読み込み、辞書（Dictionary）に入れる ---
    ' 辞書を使うとVLOOKUPと同じように「旧名で検索→新名を取得」ができます
    Set mapDict = CreateObject("Scripting.Dictionary")
    mapDict.CompareMode = 1     ' 大文字・小文字を区別しない

    Set wbMap = Workbooks.Open(mappingPath, ReadOnly:=True)
    Set wsMap = wbMap.Worksheets(MAP_SHEET_INDEX)
    lastRow = wsMap.Cells(wsMap.Rows.Count, 1).End(xlUp).Row

    For i = 2 To lastRow    ' 1行目は見出しなので2行目から読む
        oldKey = Trim(CStr(wsMap.Cells(i, 1).Value))
        newName = Trim(CStr(wsMap.Cells(i, 2).Value))
        If oldKey <> "" And newName <> "" Then
            If Not mapDict.Exists(oldKey) Then mapDict.Add oldKey, newName
        End If
    Next i

    wbMap.Close SaveChanges:=False  ' 対応表は読むだけなので保存せずに閉じる
    Set wbMap = Nothing

    If mapDict.Count = 0 Then
        MsgBox "対応表にデータがありません。A列に旧名、B列に新名を入力してください。", vbExclamation
        GoTo Cleanup
    End If

    '--- 4) バックアップフォルダを作成する ---
    If MAKE_BACKUP Then
        backupFolder = targetFolder & "\backup_" & Format(Now, "yyyymmdd_hhnnss")
        MkDir backupFolder
    End If

    '--- 5) フォルダ内のファイルを順番に変換する ---
    fileName = Dir(targetFolder & "\" & TARGET_EXT)
    Do While fileName <> ""
        On Error Resume Next    ' 1ファイルのエラーで全体を止めない
        Err.Clear

        ' ファイル名を「本体」と「拡張子」に分ける
        dotPos = InStrRev(fileName, ".")
        baseName = Left(fileName, dotPos - 1)
        extName = Mid(fileName, dotPos)

        ' 対応表を検索する（拡張子付き優先、なければ拡張子なしで検索）
        newName = ""
        If mapDict.Exists(fileName) Then
            newName = mapDict(fileName)
        ElseIf mapDict.Exists(baseName) Then
            newName = mapDict(baseName)
        End If

        If newName = "" Then
            ' 対応表に無いファイルはスキップ（ログにだけ残す）
            logText = logText & "スキップ: " & fileName & " （対応表に無し）" & vbCrLf
        Else
            ' 新名に拡張子が無ければ元の拡張子を付ける
            If InStrRev(newName, ".") = 0 Then newName = newName & extName

            If Dir(targetFolder & "\" & newName) <> "" Then
                failCount = failCount + 1
                logText = logText & "失敗: " & fileName & " （変更先 " & newName & " が既に存在）" & vbCrLf
            Else
                ' バックアップしてからリネームする
                If MAKE_BACKUP Then FileCopy targetFolder & "\" & fileName, backupFolder & "\" & fileName
                If Err.Number = 0 Then Name targetFolder & "\" & fileName As targetFolder & "\" & newName

                If Err.Number = 0 Then
                    successCount = successCount + 1
                    logText = logText & "成功: " & fileName & " → " & newName & vbCrLf
                Else
                    failCount = failCount + 1
                    logText = logText & "失敗: " & fileName & " （" & Err.Description & "）" & vbCrLf
                End If
            End If
        End If

        On Error GoTo Cleanup
        fileName = Dir()    ' 次のファイルへ
    Loop

    '--- 6) ログファイルを出力する ---
    logPath = targetFolder & "\名前変換ログ_" & Format(Now, "yyyymmdd_hhnnss") & ".txt"
    WriteLog logPath, logText

Cleanup:
    '--- 7) 対応表を閉じ忘れていたら閉じ、設定を必ず元に戻す ---
    If Not wbMap Is Nothing Then wbMap.Close SaveChanges:=False
    Application.DisplayAlerts = True
    Application.ScreenUpdating = True

    If Err.Number <> 0 Then
        MsgBox "予期しないエラーで中断しました。" & vbCrLf & Err.Description, vbCritical
    Else
        MsgBox "名前変換が完了しました。" & vbCrLf & _
               "成功: " & successCount & " 件" & vbCrLf & _
               "失敗: " & failCount & " 件" & vbCrLf & vbCrLf & _
               "ログ: " & logPath, vbInformation
    End If
End Sub

'------------------------------------------------------------------------------
' フォルダ選択ダイアログを表示する（キャンセル時は空文字を返す）
'------------------------------------------------------------------------------
Private Function SelectFolder(ByVal promptText As String) As String
    With Application.FileDialog(msoFileDialogFolderPicker)
        .Title = promptText
        .AllowMultiSelect = False
        If .Show = -1 Then
            SelectFolder = .SelectedItems(1)
        Else
            SelectFolder = ""
        End If
    End With
End Function

'------------------------------------------------------------------------------
' Excelファイル選択ダイアログを表示する（キャンセル時は空文字を返す）
'------------------------------------------------------------------------------
Private Function SelectExcelFile(ByVal promptText As String) As String
    With Application.FileDialog(msoFileDialogFilePicker)
        .Title = promptText
        .AllowMultiSelect = False
        .Filters.Clear
        .Filters.Add "Excelファイル", "*.xlsx; *.xlsm; *.xls"
        If .Show = -1 Then
            SelectExcelFile = .SelectedItems(1)
        Else
            SelectExcelFile = ""
        End If
    End With
End Function

'------------------------------------------------------------------------------
' ログをテキストファイルに書き出す
'------------------------------------------------------------------------------
Private Sub WriteLog(ByVal logPath As String, ByVal logText As String)
    Dim fileNo As Integer
    fileNo = FreeFile
    Open logPath For Output As #fileNo
    Print #fileNo, "処理日時: " & Format(Now, "yyyy/mm/dd hh:nn:ss")
    Print #fileNo, "--------------------------------------"
    Print #fileNo, logText
    Close #fileNo
End Sub
