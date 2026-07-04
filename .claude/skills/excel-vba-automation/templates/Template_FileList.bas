Attribute VB_Name = "Template_FileList"
Option Explicit
'==============================================================
' ファイル一覧出力テンプレート
'--------------------------------------------------------------
' 実行時に選択したフォルダ内のファイル一覧を、新しいブックに
' 「ファイル名 / 拡張子 / サイズ / 更新日時 / フルパス」の形で
' 出力します。ファイル名変更の対応表を作る下準備にも使えます。
'
' 標準仕様:
'   ・フォルダは実行のたびにダイアログで選択
'   ・対象拡張子は実行時にInputBoxで指定（例: pdf。* で全ファイル）
'   ・読み取りのみの処理のためバックアップは不要
'   ・最後に出力件数を表示
'
' ※ modCommon.bas を同じブックに追加してから使ってください
'==============================================================

Public Sub ExportFileList()
    Dim folderPath As String        ' 一覧を取るフォルダ
    Dim ext As String               ' 対象拡張子
    Dim outWb As Workbook           ' 出力先の新しいブック
    Dim outWs As Worksheet          ' 出力先シート
    Dim fileName As String          ' 処理中のファイル名
    Dim filePath As String          ' フルパス
    Dim r As Long                   ' 書き込み行

    '--- 1. フォルダを選択させる（標準仕様1）
    folderPath = SelectFolder("一覧を出力したいフォルダを選択してください")
    If folderPath = "" Then Exit Sub

    '--- 2. 対象拡張子を確認する（標準仕様2）
    ext = InputBox("対象の拡張子を入力してください（例: pdf、xlsx）" & vbCrLf & _
                   "すべてのファイルを対象にする場合は * を入力", "拡張子の指定", "*")
    If ext = "" Then Exit Sub

    On Error GoTo Cleanup   ' 想定外エラーでも必ず後片付けを通す
    Application.ScreenUpdating = False

    '--- 3. 出力先の新しいブックを作り、見出しを書く
    Set outWb = Workbooks.Add
    Set outWs = outWb.Worksheets(1)
    outWs.Range("A1:E1").Value = Array("ファイル名", "拡張子", "サイズ(KB)", "更新日時", "フルパス")
    outWs.Range("A1:E1").Font.Bold = True

    '--- 4. フォルダ内のファイルを1つずつ書き出す
    r = 2                                           ' 2行目から書き込む
    fileName = Dir(folderPath & "\*." & ext)
    Do While fileName <> ""
        filePath = folderPath & "\" & fileName
        outWs.Cells(r, 1).Value = fileName
        If InStrRev(fileName, ".") > 0 Then
            outWs.Cells(r, 2).Value = Mid(fileName, InStrRev(fileName, ".") + 1)
        End If
        outWs.Cells(r, 3).Value = Round(FileLen(filePath) / 1024, 1)    ' KB単位
        outWs.Cells(r, 4).Value = FileDateTime(filePath)                ' 更新日時
        outWs.Cells(r, 5).Value = filePath
        r = r + 1
        fileName = Dir()
    Loop

    '--- 5. 見た目を整える
    outWs.Columns("A:E").AutoFit
    outWs.Range("D:D").NumberFormat = "yyyy/mm/dd hh:mm"

Cleanup:
    Application.ScreenUpdating = True
    If Err.Number <> 0 Then
        MsgBox "エラーが発生しました。" & vbCrLf & Err.Description, vbCritical
    Else
        '--- 6. 結果表示（出力したブックは開いたままにするので保存はユーザーが行う）
        MsgBox (r - 2) & " 件のファイルを一覧に出力しました。" & vbCrLf & _
               "必要に応じて名前を付けて保存してください。", vbInformation, "処理結果"
    End If
End Sub
