Attribute VB_Name = "CopyFormatFromTemplate"
Option Explicit

'==============================================================================
' ひな型Excelから書式コピーテンプレート
'------------------------------------------------------------------------------
' 概要   : 実行時に選択した「ひな型Excel」の指定シート・指定範囲の書式
'          （罫線・色・フォント・表示形式など）を、フォルダ内の全Excel
'          ファイルの同じ位置へコピーします。値は変更しません。
' 使い方 : VBE（Alt+F11）→ 挿入 → 標準モジュール に全文を貼り付けて、
'          CopyFormatToAllFiles を実行してください。
' 特徴   : ひな型選択 / フォルダ選択 / バックアップ / シート保護対応 /
'          エラーログ / 成功・失敗件数の表示
'==============================================================================

'--- 設定（必要に応じて変更してください：カスタマイズ箇所） -------------------
Private Const TARGET_EXT As String = "*.xlsx"   ' 対象ファイルの拡張子
Private Const PROTECT_PASSWORD As String = ""   ' シート保護のパスワード（無い場合は空欄）
Private Const MAKE_BACKUP As Boolean = True     ' 処理前にバックアップを作成するか
'------------------------------------------------------------------------------

Public Sub CopyFormatToAllFiles()
    Dim templatePath As String      ' ひな型ファイルのパス
    Dim targetFolder As String      ' 処理対象フォルダ
    Dim backupFolder As String      ' バックアップ先フォルダ
    Dim sheetName As String         ' 対象シート名
    Dim rangeAddress As String      ' 対象範囲（例: A1:F20）
    Dim wbTemplate As Workbook      ' ひな型ブック
    Dim wb As Workbook              ' 処理対象ブック
    Dim fileName As String          ' 現在処理中のファイル名
    Dim successCount As Long        ' 成功件数
    Dim failCount As Long           ' 失敗件数
    Dim logText As String           ' ログの内容
    Dim logPath As String           ' ログファイルの保存先

    '--- 1) ひな型ファイルを実行時に選択させる ---
    templatePath = SelectExcelFile("ひな型のExcelファイルを選択してください")
    If templatePath = "" Then Exit Sub

    '--- 2) 対象フォルダを実行のたびに選択させる ---
    targetFolder = SelectFolder("書式を反映するExcelファイルがあるフォルダを選択してください")
    If targetFolder = "" Then Exit Sub

    '--- 3) 対象シート名・対象範囲をユーザーに確認する ---
    sheetName = InputBox("対象のシート名を入力してください", "シート名の確認", "Sheet1")
    If sheetName = "" Then Exit Sub
    rangeAddress = InputBox("書式をコピーする範囲を入力してください（例: A1:F20）", "範囲の確認", "A1:F20")
    If rangeAddress = "" Then Exit Sub

    '--- 4) 高速化設定（終了時に必ず元に戻します）---
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    On Error GoTo Cleanup

    '--- 5) ひな型を読み取り専用で開く ---
    Set wbTemplate = Workbooks.Open(templatePath, ReadOnly:=True)

    '--- 6) バックアップフォルダを作成する ---
    If MAKE_BACKUP Then
        backupFolder = targetFolder & "\backup_" & Format(Now, "yyyymmdd_hhnnss")
        MkDir backupFolder
    End If

    '--- 7) フォルダ内のファイルを順番に処理する ---
    fileName = Dir(targetFolder & "\" & TARGET_EXT)
    Do While fileName <> ""
        ' ひな型自身が同じフォルダにある場合はスキップする
        If targetFolder & "\" & fileName = templatePath Then
            logText = logText & "スキップ: " & fileName & " （ひな型ファイル）" & vbCrLf
        Else
            On Error Resume Next    ' 1ファイルのエラーで全体を止めない
            Err.Clear
            Set wb = Nothing

            If MAKE_BACKUP Then FileCopy targetFolder & "\" & fileName, backupFolder & "\" & fileName
            If Err.Number = 0 Then Set wb = Workbooks.Open(targetFolder & "\" & fileName)
            If Err.Number = 0 Then
                CopyFormatToWorkbook wbTemplate, wb, sheetName, rangeAddress
            End If

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
        End If
        fileName = Dir()    ' 次のファイルへ
    Loop

    '--- 8) ログファイルを出力する ---
    logPath = targetFolder & "\書式コピーログ_" & Format(Now, "yyyymmdd_hhnnss") & ".txt"
    WriteLog logPath, logText

Cleanup:
    '--- 9) ひな型を閉じ、設定を必ず元に戻す ---
    If Not wbTemplate Is Nothing Then wbTemplate.Close SaveChanges:=False
    Application.CutCopyMode = False
    Application.DisplayAlerts = True
    Application.ScreenUpdating = True

    If Err.Number <> 0 Then
        MsgBox "予期しないエラーで中断しました。" & vbCrLf & Err.Description, vbCritical
    Else
        MsgBox "書式コピーが完了しました。" & vbCrLf & _
               "成功: " & successCount & " 件" & vbCrLf & _
               "失敗: " & failCount & " 件" & vbCrLf & vbCrLf & _
               "ログ: " & logPath, vbInformation
    End If
End Sub

'------------------------------------------------------------------------------
' ひな型の書式を1ブックへコピーする（値は変更しない）
'------------------------------------------------------------------------------
Private Sub CopyFormatToWorkbook(ByVal wbTemplate As Workbook, ByVal wb As Workbook, _
                                 ByVal sheetName As String, ByVal rangeAddress As String)
    Dim wsFrom As Worksheet         ' ひな型側のシート
    Dim wsTo As Worksheet           ' コピー先のシート
    Dim wasProtected As Boolean     ' 元々シート保護されていたか

    Set wsFrom = wbTemplate.Worksheets(sheetName)
    Set wsTo = wb.Worksheets(sheetName)

    ' シート保護されている場合は解除してから処理する
    wasProtected = wsTo.ProtectContents
    If wasProtected Then wsTo.Unprotect Password:=PROTECT_PASSWORD

    ' 書式のみを貼り付ける（xlPasteFormats = 書式だけ）
    wsFrom.Range(rangeAddress).Copy
    wsTo.Range(rangeAddress).PasteSpecial Paste:=xlPasteFormats
    Application.CutCopyMode = False     ' コピー状態を解除する

    ' 列幅もひな型に合わせたい場合は、下の1行の先頭の「'」を外してください（カスタマイズ箇所）
    'wsTo.Range(rangeAddress).PasteSpecial Paste:=xlPasteColumnWidths

    ' 元々保護されていた場合は必ず再保護する
    If wasProtected Then wsTo.Protect Password:=PROTECT_PASSWORD
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
