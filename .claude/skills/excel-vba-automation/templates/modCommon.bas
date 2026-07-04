Attribute VB_Name = "modCommon"
Option Explicit
'==============================================================
' modCommon: 共通処理モジュール
'--------------------------------------------------------------
' 各テンプレートから呼び出す共通関数をまとめたモジュールです。
' このモジュールを標準モジュールとして追加した上で、
' 各テンプレート（Template_*.bas）を使ってください。
'
' 収録している関数:
'   SelectFolder        : フォルダ選択ダイアログ
'   SelectFile          : ファイル選択ダイアログ（ひな型・対応表用）
'   CreateBackupFolder  : バックアップ用フォルダを作成
'   BackupFile          : ファイルをバックアップフォルダへコピー
'   WriteLog            : ログファイルに1行追記
'   UnprotectIfNeeded   : シート保護があれば解除（解除したかを返す）
'   ReprotectIfNeeded   : 解除していた場合のみ再保護
'   ShowResult          : 成功件数・失敗件数を表示
'==============================================================

'--------------------------------------------------------------
' フォルダ選択ダイアログを表示し、選んだフォルダのパスを返す
' キャンセルされた場合は空文字("")を返す
'--------------------------------------------------------------
Public Function SelectFolder(ByVal promptTitle As String) As String
    With Application.FileDialog(msoFileDialogFolderPicker)
        .Title = promptTitle
        .AllowMultiSelect = False
        If .Show = -1 Then                      ' -1 = ユーザーが「OK」を押した
            SelectFolder = .SelectedItems(1)
        Else
            SelectFolder = ""                   ' キャンセル
        End If
    End With
End Function

'--------------------------------------------------------------
' ファイル選択ダイアログを表示し、選んだファイルのパスを返す
' キャンセルされた場合は空文字("")を返す
' 例: SelectFile("ひな型を選択", "Excelファイル", "*.xlsx; *.xlsm")
'--------------------------------------------------------------
Public Function SelectFile(ByVal promptTitle As String, _
                           ByVal filterName As String, _
                           ByVal filterPattern As String) As String
    With Application.FileDialog(msoFileDialogFilePicker)
        .Title = promptTitle
        .AllowMultiSelect = False
        .Filters.Clear
        .Filters.Add filterName, filterPattern
        If .Show = -1 Then
            SelectFile = .SelectedItems(1)
        Else
            SelectFile = ""
        End If
    End With
End Function

'--------------------------------------------------------------
' 対象フォルダの中に「backup_日付_時刻」フォルダを作成してパスを返す
' 例: C:\data\backup_20260704_153000
'--------------------------------------------------------------
Public Function CreateBackupFolder(ByVal baseFolder As String) As String
    Dim backupPath As String
    backupPath = baseFolder & "\backup_" & Format(Now, "yyyymmdd_hhnnss")
    If Dir(backupPath, vbDirectory) = "" Then
        MkDir backupPath
    End If
    CreateBackupFolder = backupPath
End Function

'--------------------------------------------------------------
' ファイルをバックアップフォルダへコピーする（元ファイルはそのまま）
'--------------------------------------------------------------
Public Sub BackupFile(ByVal filePath As String, ByVal backupFolder As String)
    Dim fileName As String
    fileName = Mid(filePath, InStrRev(filePath, "\") + 1)   ' パスからファイル名だけ取り出す
    FileCopy filePath, backupFolder & "\" & fileName
End Sub

'--------------------------------------------------------------
' ログファイルに「日時 メッセージ」を1行追記する
' ログファイルが無ければ自動的に作成される
'--------------------------------------------------------------
Public Sub WriteLog(ByVal logPath As String, ByVal message As String)
    Dim fileNo As Integer
    fileNo = FreeFile
    Open logPath For Append As #fileNo
    Print #fileNo, Format(Now, "yyyy/mm/dd hh:nn:ss") & vbTab & message
    Close #fileNo
End Sub

'--------------------------------------------------------------
' シートが保護されていたら解除する
' 戻り値: True = 保護を解除した / False = もともと保護なし
' パスワード付き保護の場合は sheetPassword に指定する（無ければ ""）
'--------------------------------------------------------------
Public Function UnprotectIfNeeded(ByVal ws As Worksheet, _
                                  ByVal sheetPassword As String) As Boolean
    If ws.ProtectContents Then
        ws.Unprotect Password:=sheetPassword
        UnprotectIfNeeded = True
    Else
        UnprotectIfNeeded = False
    End If
End Function

'--------------------------------------------------------------
' UnprotectIfNeeded で解除していた場合のみ、同じパスワードで再保護する
' wasProtected には UnprotectIfNeeded の戻り値を渡す
'--------------------------------------------------------------
Public Sub ReprotectIfNeeded(ByVal ws As Worksheet, _
                             ByVal wasProtected As Boolean, _
                             ByVal sheetPassword As String)
    If wasProtected Then
        ws.Protect Password:=sheetPassword
    End If
End Sub

'--------------------------------------------------------------
' 処理結果（成功・失敗件数とログの場所）をメッセージ表示する
'--------------------------------------------------------------
Public Sub ShowResult(ByVal okCount As Long, _
                      ByVal ngCount As Long, _
                      ByVal logPath As String)
    Dim msg As String
    msg = "処理が完了しました。" & vbCrLf & vbCrLf & _
          "成功: " & okCount & " 件" & vbCrLf & _
          "失敗: " & ngCount & " 件"
    If ngCount > 0 Then
        msg = msg & vbCrLf & vbCrLf & "失敗の詳細はログを確認してください:" & vbCrLf & logPath
        MsgBox msg, vbExclamation, "処理結果"
    Else
        MsgBox msg, vbInformation, "処理結果"
    End If
End Sub
