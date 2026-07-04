Attribute VB_Name = "RenamePdfFiles"
Option Explicit

'==============================================================================
' PDFファイル名一括変更テンプレート
'------------------------------------------------------------------------------
' 概要   : 選択したフォルダ内のPDFファイル名を、ルール（前に付ける文字・
'          後ろに付ける文字・置換）に従って一括変更します。
' 使い方 : VBE（Alt+F11）→ 挿入 → 標準モジュール に全文を貼り付けて、
'          RenamePdfFilesInFolder を実行してください。
' 特徴   : フォルダ選択 / バックアップ / エラーログ / 成功・失敗件数の表示
' 補足   : 対応表（旧名→新名）を使ったリネームは
'          RenameFilesWithMapping.bas を使ってください。
'==============================================================================

'--- 設定（必要に応じて変更してください：カスタマイズ箇所） -------------------
Private Const TARGET_EXT As String = "*.pdf"    ' 対象ファイルの拡張子
Private Const MAKE_BACKUP As Boolean = True     ' 変更前にバックアップを作成するか

' リネームのルール（使わない項目は空欄のままにしてください）
Private Const ADD_PREFIX As String = ""         ' ファイル名の前に付ける文字（例: "2026_"）
Private Const ADD_SUFFIX As String = ""         ' ファイル名の後ろに付ける文字（例: "_確認済"）
Private Const REPLACE_FROM As String = ""       ' 置換したい文字（例: "見積書"）
Private Const REPLACE_TO As String = ""         ' 置換後の文字（例: "御見積書"）
'------------------------------------------------------------------------------

Public Sub RenamePdfFilesInFolder()
    Dim targetFolder As String      ' 処理対象フォルダ
    Dim backupFolder As String      ' バックアップ先フォルダ
    Dim fileName As String          ' 現在のファイル名（拡張子付き）
    Dim baseName As String          ' 拡張子を除いたファイル名
    Dim extName As String           ' 拡張子（ドット付き）
    Dim newName As String           ' 変更後のファイル名
    Dim successCount As Long        ' 成功件数
    Dim failCount As Long           ' 失敗件数
    Dim logText As String           ' ログの内容
    Dim logPath As String           ' ログファイルの保存先
    Dim dotPos As Long              ' ドットの位置

    '--- 1) 対象フォルダを実行のたびに選択させる ---
    targetFolder = SelectFolder("PDFファイルがあるフォルダを選択してください")
    If targetFolder = "" Then Exit Sub

    On Error GoTo Cleanup   ' 予期しないエラー用の保険

    '--- 2) バックアップフォルダを作成する ---
    If MAKE_BACKUP Then
        backupFolder = targetFolder & "\backup_" & Format(Now, "yyyymmdd_hhnnss")
        MkDir backupFolder
    End If

    '--- 3) フォルダ内のPDFを順番にリネームする ---
    fileName = Dir(targetFolder & "\" & TARGET_EXT)
    Do While fileName <> ""
        On Error Resume Next    ' 1ファイルのエラーで全体を止めない
        Err.Clear

        ' ファイル名を「本体」と「拡張子」に分ける
        dotPos = InStrRev(fileName, ".")
        baseName = Left(fileName, dotPos - 1)
        extName = Mid(fileName, dotPos)

        ' ルールに従って新しいファイル名を作る
        newName = baseName
        If REPLACE_FROM <> "" Then newName = Replace(newName, REPLACE_FROM, REPLACE_TO)
        newName = ADD_PREFIX & newName & ADD_SUFFIX & extName

        If newName = fileName Then
            ' 名前が変わらない場合はスキップ（ログにだけ残す）
            logText = logText & "スキップ: " & fileName & " （変更なし）" & vbCrLf
        ElseIf Dir(targetFolder & "\" & newName) <> "" Then
            ' 同名ファイルが既にある場合は失敗として記録する
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

        On Error GoTo Cleanup
        fileName = Dir()    ' 次のファイルへ
    Loop

    '--- 4) ログファイルを出力する ---
    logPath = targetFolder & "\リネームログ_" & Format(Now, "yyyymmdd_hhnnss") & ".txt"
    WriteLog logPath, logText

Cleanup:
    If Err.Number <> 0 Then
        MsgBox "予期しないエラーで中断しました。" & vbCrLf & Err.Description, vbCritical
    Else
        '--- 5) 成功・失敗件数を表示する ---
        MsgBox "リネームが完了しました。" & vbCrLf & _
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
