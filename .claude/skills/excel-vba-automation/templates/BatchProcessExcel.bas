Attribute VB_Name = "BatchProcessExcel"
Option Explicit

'==============================================================================
' Excelファイル一括処理テンプレート
'------------------------------------------------------------------------------
' 概要   : 選択したフォルダ内のExcelファイルを1つずつ開き、指定シートに
'          処理を行って保存する汎用テンプレートです。
' 使い方 : VBE（Alt+F11）→ 挿入 → 標準モジュール に全文を貼り付けて、
'          BatchProcessExcelFiles を実行してください。
' 特徴   : フォルダ選択 / バックアップ / シート保護対応 / エラーログ /
'          成功・失敗件数の表示
'==============================================================================

'--- 設定（必要に応じて変更してください：カスタマイズ箇所） -------------------
Private Const TARGET_EXT As String = "*.xlsx"   ' 対象ファイルの拡張子
Private Const PROTECT_PASSWORD As String = ""   ' シート保護のパスワード（無い場合は空欄のまま）
Private Const MAKE_BACKUP As Boolean = True     ' 処理前にバックアップを作成するか
'------------------------------------------------------------------------------

Public Sub BatchProcessExcelFiles()
    Dim targetFolder As String      ' 処理対象フォルダ
    Dim backupFolder As String      ' バックアップ先フォルダ
    Dim sheetName As String         ' 処理対象シート名
    Dim fileName As String          ' 現在処理中のファイル名
    Dim wb As Workbook              ' 開いたブック
    Dim successCount As Long        ' 成功件数
    Dim failCount As Long           ' 失敗件数
    Dim logText As String           ' ログの内容
    Dim logPath As String           ' ログファイルの保存先

    '--- 1) 対象フォルダを実行のたびに選択させる ---
    targetFolder = SelectFolder("処理対象のフォルダを選択してください")
    If targetFolder = "" Then Exit Sub  ' キャンセルされたら終了

    '--- 2) 対象シート名をユーザーに確認する ---
    sheetName = InputBox("処理対象のシート名を入力してください", "シート名の確認", "Sheet1")
    If sheetName = "" Then Exit Sub

    '--- 3) 高速化設定（終了時に必ず元に戻します）---
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    On Error GoTo Cleanup   ' 予期しないエラーでも設定を必ず戻すための保険

    '--- 4) バックアップフォルダを作成する ---
    If MAKE_BACKUP Then
        backupFolder = targetFolder & "\backup_" & Format(Now, "yyyymmdd_hhnnss")
        MkDir backupFolder
    End If

    '--- 5) フォルダ内のファイルを順番に処理する ---
    fileName = Dir(targetFolder & "\" & TARGET_EXT)
    Do While fileName <> ""
        On Error Resume Next    ' 1ファイルのエラーで全体を止めない
        Err.Clear
        Set wb = Nothing

        ' バックアップを作成してからファイルを開く
        If MAKE_BACKUP Then FileCopy targetFolder & "\" & fileName, backupFolder & "\" & fileName
        If Err.Number = 0 Then Set wb = Workbooks.Open(targetFolder & "\" & fileName)
        If Err.Number = 0 Then ProcessOneWorkbook wb, sheetName

        If Err.Number = 0 Then
            wb.Close SaveChanges:=True      ' 成功したら保存して閉じる
            successCount = successCount + 1
            logText = logText & "成功: " & fileName & vbCrLf
        Else
            ' 失敗した内容をログに残し、保存せずに閉じる
            failCount = failCount + 1
            logText = logText & "失敗: " & fileName & " （" & Err.Description & "）" & vbCrLf
            If Not wb Is Nothing Then wb.Close SaveChanges:=False
        End If

        Set wb = Nothing
        On Error GoTo Cleanup
        fileName = Dir()    ' 次のファイルへ
    Loop

    '--- 6) ログファイルを出力する ---
    logPath = targetFolder & "\処理ログ_" & Format(Now, "yyyymmdd_hhnnss") & ".txt"
    WriteLog logPath, logText

Cleanup:
    '--- 7) 設定を必ず元に戻す（戻し忘れ防止）---
    Application.DisplayAlerts = True
    Application.ScreenUpdating = True

    If Err.Number <> 0 Then
        MsgBox "予期しないエラーで中断しました。" & vbCrLf & Err.Description, vbCritical
    Else
        '--- 8) 成功・失敗件数を表示する ---
        MsgBox "処理が完了しました。" & vbCrLf & _
               "成功: " & successCount & " 件" & vbCrLf & _
               "失敗: " & failCount & " 件" & vbCrLf & vbCrLf & _
               "ログ: " & logPath, vbInformation
    End If
End Sub

'------------------------------------------------------------------------------
' 1ブックに対する処理（★ここを書き換えて使います：カスタマイズ箇所）
'------------------------------------------------------------------------------
Private Sub ProcessOneWorkbook(ByVal wb As Workbook, ByVal sheetName As String)
    Dim ws As Worksheet
    Dim wasProtected As Boolean     ' 元々シート保護されていたか

    Set ws = wb.Worksheets(sheetName)   ' シートが無ければここでエラー→ログに記録される

    ' シート保護されている場合は解除してから処理する
    wasProtected = ws.ProtectContents
    If wasProtected Then ws.Unprotect Password:=PROTECT_PASSWORD

    '=== ここに処理を書く（カスタマイズ箇所）==================================
    ' 例: A1セルに「処理済み」と入力する
    ws.Range("A1").Value = "処理済み"
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
