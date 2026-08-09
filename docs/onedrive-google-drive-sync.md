# セールスデータ連携手順（OneDrive → Google Drive）

## この文書の目的

個人用 OneDrive に置いているセールスデータを、Claude から継続的に読み込めるようにするための設定手順。

## なぜこの構成にするのか

個人用 Microsoft アカウントの OneDrive を Claude に直接つなぐ純正コネクタは、現時点では存在しない。

- Claude の「Microsoft 365」コネクタは**法人テナント（Entra ID）専用**。個人アカウントでサインインすると
  「ここに個人アカウントでサインインすることはできません。代わりに職場または学校アカウントをご利用ください。」
  と表示され、仕様上どうやっても通らない。
- 一方、Google Drive コネクタは接続済みで、実測で問題なく動作している
  （3MB の xlsx をダウンロードし、13,370行 × 42列を完全にパース）。

したがって **OneDrive を運用の場として維持したまま、Google Drive をミラー（読み取り用の窓口）として使う**構成をとる。
普段のファイルの置き場所・作業手順は変えなくてよい。

```
[OneDrive/セールスデータ]  ←  普段の作業はここ（変更なし）
          │
          │  自動ミラー
          ▼
[Google Drive/セールスデータ]  →  Claude が読む
```

---

## 方法A: Google ドライブ デスクトップ アプリでミラーする（推奨）

外部サービスを挟まず、無料で、反映も速い。PC を日常的に使っているなら第一候補。

### 前提

- Windows または Mac に **OneDrive デスクトップ アプリ**が入っていて、
  `C:\Users\<ユーザー名>\OneDrive\...`（Mac は `~/OneDrive/...`）にセールスデータのフォルダが同期されていること。

### 手順

1. **Google ドライブ デスクトップ アプリをインストール**
   <https://www.google.com/drive/download/> から入手し、Claude に接続しているのと**同じ Google アカウント**でログインする。

2. **OneDrive のフォルダをミラー対象に追加**
   1. タスクトレイ（Mac はメニューバー）の Google ドライブ アイコン → 歯車 → 「設定」
   2. 左メニュー「パソコンから」→「フォルダを追加」
   3. OneDrive 内のセールスデータのフォルダを選択
   4. 同期方法で **「Google ドライブと同期する」** を選ぶ

3. **【重要】ファイル オンデマンドを解除する**
   OneDrive の「ファイル オンデマンド」が有効だと、ファイルの実体がクラウド上にしかなく
   （アイコンが雲マーク）、Google ドライブ側がミラーできない。

   対象フォルダを右クリック → **「このデバイス上で常に保持する」** を選択。
   アイコンが緑のチェックに変われば実体がローカルにある状態。

4. **反映を確認**
   ブラウザで Google ドライブを開き、左メニューの「パソコン」→ 自分の PC 名 → 対象フォルダ
   の下にファイルが並んでいれば成功。

### 注意点

- **PC の電源が入っていてアプリが動いている間だけ同期される。** PC を閉じている間の変更は、次に起動したときにまとめて反映される。
- 反映先は「マイドライブ」ではなく **「パソコン」セクション**の配下になる。Claude から探すときはこの位置を伝えること。
- ミラーは双方向。Google ドライブ側でファイルを消すと、OneDrive 側（＝ローカル実体）からも消える。**Claude 側での削除操作は行わない**方針とする。

---

## 方法B: Zapier で自動コピーする

PC の起動状態に依存せず、クラウド間で完結させたい場合はこちら。

### 手順

1. Zapier で Zap を新規作成する。

2. **トリガー: OneDrive**
   - イベントは **「New File」ではなく「Updated File」（または New or Updated File）** を選ぶ。

     > **これが最重要ポイント。** `Sales FY26.xlsx` のように *既存ファイルを上書き更新* していく運用では、
     > 「New File」トリガーは初回作成時にしか発火せず、以降の月次更新をすべて取りこぼす。

   - 監視対象フォルダにセールスデータのフォルダを指定する。

3. **アクション: Google Drive → Upload File**
   - File 欄に、トリガーの出力ファイル（Zapier がファイル実体を引き渡す項目）を指定
   - 保存先に**専用のフォルダ**を指定する（既存フォルダと混ぜない）
   - 「Convert to Google Docs?」は **No**（xlsx のまま保持する）

4. Zap をオンにし、OneDrive 側のファイルを一度更新して発火をテストする。

### 注意点

- **既存ファイルはコピーされない。** トリガーは Zap をオンにした後の変更にしか反応しないため、
  現時点で OneDrive にあるファイルは初回に手動でコピーする必要がある（下記「初回移行」参照）。
- 同名ファイルを繰り返しアップロードすると、Google Drive 側で**重複ファイルが増える**ことがある。
  定期的に確認するか、Zap に「Find File → 既存なら置換」のステップを足す。
- 無料プランは Zap が 2 ステップまで、実行回数は月 100 タスクまで、ポーリング間隔は 15 分間隔。
  月次更新の用途なら無料枠で足りる想定。
- **OneDrive が Zapier の有料アプリ区分に該当するかは、設定画面で要確認。** 該当する場合は有料プランが必要になる。
- ファイル サイズに上限があるため、数十 MB 級のファイルを扱う場合は転送が通るか事前にテストすること。

---

## 初回移行（方法A・B 共通、最初に一度だけ）

自動同期は「設定後の変更」にしか反応しない。現時点のファイル一式は手動で移す。

1. OneDrive のセールスデータ フォルダを丸ごとダウンロード（またはローカル同期フォルダからコピー）
2. Google Drive に `セールスデータ` フォルダを作り、その中にアップロード
3. アップロード完了後、ファイル数と各ファイルの更新日時が OneDrive 側と一致することを確認

---

## 既存の Google Drive データの扱い

Google Drive には既に `Sales data folder` が存在するが、**内容が古い**。

| 項目 | 内容 |
|---|---|
| 場所 | マイドライブ → Excel → Sales data folder |
| 中身 | Sales FY17〜FY26、BU25.xlsx、Ref.xlsx、サブフォルダ `Sales Map` / `Power Query` |
| Sales FY26.xlsx の最終更新 | 2025/06/30 |
| Sales FY26.xlsx の収録期間 | 2025/03/31〜2025/06/29（Apr–Jun、Week 1–13）のみ |

OneDrive 側が最新であるため、このフォルダは**参照元として使わない**。取り違えを防ぐため、以下のいずれかを推奨する。

- `Sales data folder` を `_archive_Sales data folder（〜FY26 Q1・旧）` にリネームする
- または `_archive` フォルダを作ってその配下に移動する

加えて、`Sales Map` / `Power Query` サブフォルダには**ルートと同名だがサイズの異なる** `Sales FY24.xlsx` `Sales FY25.xlsx` 等が存在する。
どれを正とするかが不明瞭なため、新しい `セールスデータ` フォルダでは同名ファイルの重複を作らない運用とする。

---

## データの取り扱い上の注意

セールスデータの明細には以下の個人情報が含まれる。

- 顧客氏名（`Client` 列）
- 生年月日（`Birth Date` 列）、年齢
- 顧客性別、居住国
- 販売員氏名（`CA` 列）
- 購買履歴の全明細

このため、以下は行わないこと。

- **「リンクを知っている全員」の共有リンクを作らない。** 社外流出のリスクがある。
  共有は特定アカウントを指定した権限付与に限る。
- **Git リポジトリにコミットしない。** GitHub 上に個人情報が残る。
  このリポジトリの `.gitignore` に除外設定を追加済み。

---

## 参考: データ構造（Sales FY26.xlsx より）

単一シート `Sheet1`、1行 = 1明細（SKU 単位）の 42 列。

| 分類 | 列 |
|---|---|
| 期間軸 | FY, Month, Year Week Number (4-5-4), Weekday, Date |
| 店舗軸 | Channel Code (R/O), Store Group (FSS/SIS/SIS Oth/Outlet), Store Code, Store Desc. |
| 商品軸 | Gender, Line, Cate, Gender Desc., Line Desc., Commercial Class, SubCommercial Class, Brand Code, Born Season Code, Article Group, Theme, Article Code, Color Code, Size Desc. |
| 金額 | Unit, Value, Operation Type Desc., Discount Desc., Gaisho, Sale |
| 人・顧客軸 | Ticket Prefix+Number, Sales Assistant Code, CA, Specialist, Client, Customer Gender Code, Birth Date, Age, Residence Country Code, Inbound, First Purchase Date Total, Creation Date, New/Loyal |

補助マスタ `Ref.xlsx` は月名→月番号の対応表（Apr=1 … Mar=12）。4-5-4 会計年度で 4 月始まり。

この粒度により、Revenue / TR / ATV / UPT の算出、New・Loyal 分析、外商・インバウンド分析、
販売員別パフォーマンス分析が単一ファイルで完結する。

`Operation Type Desc.` に `ITEM RETURN` および `GAISHO/OUTSIDE RETURN-JP ONLY`（いずれもマイナス値）が
含まれるため、`Value` の単純合計は**返品相殺後の純額**になる点に注意。
