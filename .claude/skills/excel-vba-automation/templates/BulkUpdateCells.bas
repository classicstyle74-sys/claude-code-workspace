Attribute VB_Name = "BulkUpdateCells"
Option Explicit

'==============================================================================
' 任意セル・任意シート一括変更テンプレート
'------------------------------------------------------------------------------
' 概要   : 選択したフォルダ内の全Excelファイルについて、実行時に指定した
'          シートのセル（または範囲）へ、指定した値を一括で書き込みます。
' 使い方 : VBE（Alt+F11）→ 挿入 → 標準モジュール に全文を貼り付けて、
'          BulkUpdateCellsInFolder を実行してください。
' 特徴   : フォルダ選択 / シート名・セル・値を実行時に確認 / バックアップ /
'          シート保護対応 / エラーログ / 成功・失敗件数の表示
'==============================================================================

'--- 設定（必要に応じて変更してください：カスタマイズ箇所） -------------------
Private Const TARGET_EXT As String = "*.xlsx"   ' 対象ファイルの拡張子
Private Const PROTECT_PASSWORD As String = ""   ' シート保護のパスワード（無い場合は空欄）
Private Const MAKE_BACKUP As Boolean = True     ' 処理前にバックアップを作成するか
'------------------------------------------------------------------------------

Public Sub BulkUpdateCellsInFolder()
    Dim targetFolder As String      ' 処理対象フォルダ
    Dim backupFolder As String      ' バックアップ先フォルダ
    Dim sheetName As String         ' 対象シート名
    Dim rangeAddress As String      ' 対象セルまたは範囲（例: B2 や B2:D5）
    Dim newValue As String          ' 書き込む値
    Dim fileName As String          ' 現在処理中のファイル名
    Dim wb As Workbook              ' 開いたブック
    Dim successCount As Long        ' 成功件数
    Dim failCount As Long           ' 失敗件数
    Dim logText As String           ' ログの内容
    Dim logPath As String           ' ログファイルの保存先

    '--- 1) 対象フォルダを実行のたびに選択させる ---
    targetFolder = SelectFolder("処理対象のフォルダを選択してください")
    If targetFolder = "" Then Exit Sub

    '--- 2) シート名・セル・値をユーザーに確認する ---
    sheetName = InputBox("対象のシート名を入力してください", "シート名の確認", "Sheet1")
    If sheetName = "" Then Exit Sub
    rangeAddress = InputBox("変更するセルまたは範囲を入力してください（例: B2 や B2:D5）", "セルの確認", "B2")
    If rangeAddress = "" Then Exit Sub
    newValue = InputBox("書き込む値を入力してください", "値の確認")
    ' ※空欄で「セルを空にする」使い方もできるため、newValue の空チェックはしません

    '--- 3) 実行前の最終確認（誤操作防止）---
    If MsgBox("フォルダ: " & targetFolder & vbCrLf & _
              "シート  : " & sheetName & vbCrLf & _
              "セル    : " & rangeAddress & vbCrLf & _
              "値      : " & newValue & vbCrLf & vbCrLf & _
              "この内容で全ファイルを変更します。よろしいですか？", _
              vbYesNo + vbQuestion, "実行確認") = vbNo Then Exit Sub

    '--- 4) 高速化設定（終了時に必ず元に戻します）---
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    On Error GoTo Cleanup

    '--- 5) バックアップフォルダを作成する ---
    If MAKE_BACKUP Then
        backupFolder = targetFolder & "\backup_" & Format(Now, "yyyymmdd_hhnnss")
        MkDir backupFolder
    End If

    '--- 6) フォルダ内のファイルを順番に処理する ---
    fileName = Dir(targetFolder & "\" & TARGET_EXT)
    Do While fileName <> ""
        On Error Resume Next    ' 1ファイルのエラーで全体を止めない
        Err.Clear
        Set wb = Nothing

        If MAKE_BACKUP Then FileCopy targetFolder & "\" & fileName, backupFolder & "\" & fileName
        If Err.Number = 0 Then Set wb = Workbooks.Open(targetFolder & "\" & fileName)
        If Err.Number = 0 Then UpdateOneWorkbook wb, sheetName, rangeAddress, newValue

        If Err.Number = 0 Then
            wb.Close SaveChanges:=True
            successCount = successCount + 1
            logText = logText & "成功: " & fileName & vbCrLf
        Else
            failCount = failCount + 1
            logText = logText & "失敗: " & fileName & " （" & Err.Description & "）" & vbCrLf
            If Not wb Is Nothing Then wb.Close SaveChanges:=False
        End If

        Set wb = Nothing
        On Error GoTo Cleanup
        fileName = Dir()    ' 次のファイルへ
    Loop

    '--- 7) ログファイルを出力する ---
    logPath = targetFolder & "\一括変更ログ_" & Format(Now, "yyyymmdd_hhnnss") & ".txt"
    WriteLog logPath, logText

Cleanup:
    '--- 8) 設定を必ず元に戻す（戻し忘れ防止）---
    Application.DisplayAlerts = True
    Application.ScreenUpdating = True

    If Err.Number <> 0 Then
        MsgBox "予期しないエラーで中断しました。" & vbCrLf & Err.Description, vbCritical
    Else
        MsgBox "一括変更が完了しました。" & vbCrLf & _
               "成功: " & successCount & " 件" & vbCrLf & _
               "失敗: " & failCount & " 件" & vbCrLf & vbCrLf & _
               "ログ: " & logPath, vbInformation
    End If
End Sub

'------------------------------------------------------------------------------
' 1ブックの指定セルへ値を書き込む（シート保護に対応）
'------------------------------------------------------------------------------
Private Sub UpdateOneWorkbook(ByVal wb As Workbook, ByVal sheetName As String, _
                              ByVal rangeAddress As String, ByVal newValue As String)
    Dim ws As Worksheet
    Dim wasProtected As Boolean     ' 元々シート保護されていたか

    Set ws = wb.Worksheets(sheetName)

    ' シート保護されている場合は解除してから処理する
    wasProtected = ws.ProtectContents
    If wasProtected Then ws.Unprotect Password:=PROTECT_PASSWORD

    '=== 値の書き込み（カスタマイズ箇所）======================================
    ' 数式を入れたい場合は .Value を .Formula に変更してください
    ' （例: newValue に "=SUM(A1:A10)" を入力して .Formula で書き込む）
    ws.Range(rangeAddress).Value = newValue
    '==========================================================================

    ' 元々保護されていた場合は必ず再保護する
    If wasProtected Then ws.Protect Password:=PROTECT_PASSWORD
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
