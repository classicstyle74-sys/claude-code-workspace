Attribute VB_Name = "ExportFileList"
Option Explicit

'==============================================================================
' ファイル一覧出力テンプレート
'------------------------------------------------------------------------------
' 概要   : 選択したフォルダ内のファイル一覧（名前・拡張子・サイズ・更新日時）
'          を新しいExcelブックに書き出します。元ファイルは一切変更しません。
' 使い方 : VBE（Alt+F11）→ 挿入 → 標準モジュール に全文を貼り付けて、
'          ExportFileListToExcel を実行してください。
' 特徴   : フォルダ選択 / 拡張子の絞り込み / 件数表示
'==============================================================================

'--- 設定（必要に応じて変更してください：カスタマイズ箇所） -------------------
Private Const TARGET_EXT As String = "*.*"      ' 対象ファイルの拡張子（例: "*.xlsx"、"*.pdf"、全部なら "*.*"）
'------------------------------------------------------------------------------

Public Sub ExportFileListToExcel()
    Dim targetFolder As String      ' 一覧を取るフォルダ
    Dim fileName As String          ' 現在のファイル名
    Dim filePath As String          ' フルパス
    Dim wbOut As Workbook           ' 出力用の新規ブック
    Dim wsOut As Worksheet          ' 出力用シート
    Dim rowIndex As Long            ' 書き込み行
    Dim fileCount As Long           ' 件数
    Dim dotPos As Long              ' ドットの位置

    '--- 1) 対象フォルダを実行のたびに選択させる ---
    targetFolder = SelectFolder("一覧を出力するフォルダを選択してください")
    If targetFolder = "" Then Exit Sub

    '--- 2) 高速化設定（終了時に必ず元に戻します）---
    Application.ScreenUpdating = False
    On Error GoTo Cleanup

    '--- 3) 出力用の新規ブックを作り、見出しを書く ---
    Set wbOut = Workbooks.Add
    Set wsOut = wbOut.Worksheets(1)
    wsOut.Name = "ファイル一覧"
    wsOut.Range("A1").Value = "No"
    wsOut.Range("B1").Value = "ファイル名"
    wsOut.Range("C1").Value = "拡張子"
    wsOut.Range("D1").Value = "サイズ(KB)"
    wsOut.Range("E1").Value = "更新日時"
    wsOut.Range("F1").Value = "フルパス"
    wsOut.Range("A1:F1").Font.Bold = True

    '--- 4) フォルダ内のファイルを順番に書き出す ---
    rowIndex = 2
    fileName = Dir(targetFolder & "\" & TARGET_EXT)
    Do While fileName <> ""
        filePath = targetFolder & "\" & fileName
        dotPos = InStrRev(fileName, ".")

        wsOut.Cells(rowIndex, 1).Value = rowIndex - 1                           ' No
        wsOut.Cells(rowIndex, 2).Value = fileName                               ' ファイル名
        If dotPos > 0 Then wsOut.Cells(rowIndex, 3).Value = Mid(fileName, dotPos + 1)   ' 拡張子
        wsOut.Cells(rowIndex, 4).Value = Round(FileLen(filePath) / 1024, 1)     ' サイズ(KB)
        wsOut.Cells(rowIndex, 5).Value = FileDateTime(filePath)                 ' 更新日時
        wsOut.Cells(rowIndex, 6).Value = filePath                               ' フルパス

        rowIndex = rowIndex + 1
        fileCount = fileCount + 1
        fileName = Dir()    ' 次のファイルへ
    Loop

    '--- 5) 見た目を整える ---
    wsOut.Cells(1, 5).EntireColumn.NumberFormat = "yyyy/mm/dd hh:mm"
    wsOut.Columns("A:F").AutoFit

Cleanup:
    '--- 6) 設定を必ず元に戻す ---
    Application.ScreenUpdating = True

    If Err.Number <> 0 Then
        MsgBox "予期しないエラーで中断しました。" & vbCrLf & Err.Description, vbCritical
    Else
        '--- 7) 件数を表示する（出力ブックは開いたままなので、確認して保存してください）---
        MsgBox "ファイル一覧を出力しました。" & vbCrLf & _
               "件数: " & fileCount & " 件" & vbCrLf & vbCrLf & _
               "内容を確認して、必要なら名前を付けて保存してください。", vbInformation
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
