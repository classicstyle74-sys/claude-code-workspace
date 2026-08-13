# データ探索 INVENTORY — Google Drive「07 Marni」フォルダ

探索範囲: Google Drive `07 Marni`（ID: 1TLukA7w7lPqXiiMeg4dAlHqhL_XZhHxx）配下の全サブフォルダ。
除外: `01_RETAIL/Documents/コピーClaude-by-Anthropic-for-Excel.xlsx`（下記参照）。

凡例: 使えるか — ○=実データをCSV化済み / △=部分的に使用・参考情報のみ / ×=読み取り不可または売上分析に非該当

## 実際にCSV化したファイル（主要ソース）

| ファイル名 | Driveパス | 対象期間 | 粒度 | 主な列 | 使えるか |
|---|---|---|---|---|---|
| 店長会_2026H1レビュー_骨組み.md | 07 Marni/02_SALES ANALYSIS/outputs/2026H1_retail_review/ | 2024-2026 H1（1-6月） | 全社・店舗別・月次・カテゴリ別・顧客セグメント別 | Net売上/TR/ATV/UPT/FP/MD構成比/RTW構成比/店舗別KPI等 | ○ 最重要ソース。「実データ集計済み」と明記。data source: 202401-12.xlsx/202501-12.xlsx/202601-12.xlsx(Export シート) |
| 店長会_2026H1_アジェンダ版_骨組み.md | 同上 | 同上 | 同上（店舗別によりRTW購入客比率・顧客1人当たり売上を追加） | 同上＋顧客リテンション/Lost分析/スタッフ生産性 | ○ 上記と同一データソース、より詳細な店舗軸・顧客軸分析を含む |
| 202512_Qucik catch up for 2025.xlsx | 07 Marni/01_RETAIL/Report/CEO Report/ | 2024年通年・2025年（12月MTD時点） | 月次・New/Existing別 | Trans/ATV/Amount（New/Existing/TTL）、vsPY% | ○ 26ドア合計とH1数値が店長会mdと完全一致（クロス検証済み） |
| 202604 CLientelling model_JP.xlsx | 07 Marni/03_CRM/Out-reach/ | 2025年通年（BDGは年間予算） | 店舗別 | BDG(EUR)、Active/Lost/Rest of DB別 顧客数・売上(EUR)・Clientelling Share・FTE | ○ 通貨がEURである点に注意（NOTES参照） |
| ■Mani_Store List_CODE & Floor info_20260205.xlsx | 07 Marni/01_RETAIL/Store/Store Information/ | 2026年2月時点マスタ | 店舗マスタ | RBOコード/店舗名(和英)/Comp・Non-comp/オープン日/フロア面積 | ○ 店舗名表記ゆれの正規化に使用 |

## 参考情報として確認したが、CSV化を見送ったファイル

| ファイル名 | Driveパス | 対象期間 | 粒度 | 主な列 | 使えるか | 理由 |
|---|---|---|---|---|---|---|
| MARNI_Japan_2027_Retail_Strategy(_JP).pptx | 07 Marni/01_RETAIL/Outputs/ 他 | 2026実績（BGTベース）〜2027計画 | 全社・店舗上位5 | Net Sales(億円)、店舗別BGT(百万円) | △ | 通貨・対象チャネル定義（Wholesale/Outlet含む可能性）がmd資料と異なり、数値の直接比較に注意が必要なため参考情報止まり。2026 BGTベース売上53.6億円、2027 Base 61.0億円、上位5店BGT合計約20.1億円（構成比37.5%）は記載あり |
| 202605/202603/202601/202511/202509 MARNI JAPAN Business Review.pptx | 07 Marni/01_RETAIL/Report/Bi-Monthly/ | 各月YTD | 全社（チャネル別：Retail/Outlet/Wholesale/Café） | Net Sales(EUR)、vs BDG/PJ1/PY％ | △ | EUR建て・全チャネル合算（コレクション26ドアより広い範囲）のため、他ソースと単純合算不可。例：2026年4月YTD 14,095千EUR（-3.4% vs BDG） |
| 202602_Gaisho 比率.xlsx | 07 Marni/01_RETAIL/Report/CEO Report/ | 2025年（一時点） | 店舗別（3店のみ抜粋） | New/Existing Trans・ATV・Amount、Gaisho Share | △ | 名古屋松坂屋・京都大丸・心斎橋大丸の3店のみで全店データではない |
| 202602_HQ 資料.xlsx | 同上 | 2026 vs 2025（期間不明・一部週次) | 性別×カテゴリー別 | Qty/AP/Amount（New/Existing別） | △ | 非常に詳細だが対象期間の明記なく、店長会mdのカテゴリ集計と重複するため未CSV化 |
| 202512_Akama san 資料.xlsx | 同上 | 2025 YTD (WK48時点) | 店舗別 | New/Existing Trans/Amount、競合(Miumiu/Loewe等)価格帯分布 | △ | ファイルサイズ超過で全店舗抽出未完了。一部店舗（表参道、名古屋ラシック等）のみ数値確認 |
| 202510_Action Plan for 5 stores.xlsx | 同上 | 2025 vs 2024（月次） | 5店舗×月次×New/Existing | Trans/ATV/Amount | △ | ファイルサイズ超過（71K文字）で全文取得不可。銀座三越ACC・京都大丸の一部月次のみ確認 |
| 3month Forcast F.xlsx | 07 Marni/01_RETAIL/Forecast/ | 2022-2025年（Jan-Sep/Oct-Dec別、Forecast＋PJ2） | 店舗別 | 半期実績・予測(円) | △ | ファイルサイズ超過（406K文字）で全文取得不可。冒頭の店舗別半期サマリーのみ確認（Fukuoka Iwataya, Kyoto Bal等） |
| 202511.xlsx | 07 Marni/01_RETAIL/Report/Bi-Monthly/ | 2024-2025年 | 月次・購入金額帯別 | AVT分布、New/Existing Trans/Amount | △ | ファイルサイズ超過（55K文字）で完全取得不可。前半（1-6月）のみ確認、月次New/Existing集計はQucik catch upと概ね整合 |
| Marni segmentation_和訳.pdf / _詳細解説.pdf | 07 Marni/03_CRM/Segmentation/ | 2025年6月末時点（スナップショット） | 全社・セグメント別 | New/Loyal(Super Loyal/Retained/Reactivated)/Lost/Prospect の定義・人数 | △ | セグメント定義resource。全社累計の顧客数のみで店舗別・期間別売上には紐付かないためCSV化見送り（定義はNOTES.mdに記載） |
| 202605_CEO Target.xlsx | 07 Marni/01_RETAIL/Report/CEO Report/ | 2026 WK21（週次） | 全社 | Sales, HC, FTE, Existing売上, AVT vs PY/Target | △ | 単週のみのデータで期間が限定的なためCSV化見送り |
| 202508★Monthly Overview_Retail Excellence Process_Japan Store.xlsx | 07 Marni/01_RETAIL/Report/Sales Report/ | 2025年8月（店舗別月次テンプレート） | 店舗別（1店舗サンプルのみ確認） | Daily#Tickets, Conversion Rate, AVT, Cross Selling Rate, Retention Rate, Catchment Rate | △ | CVR・Retention・Catchmentが取得できる唯一のフォーマットだが、確認できたのは1店舗分のみで全店ロールアップか未確認 |
| WEEK*.pptx（週次リテールレポート、多数） | 07 Marni/01_RETAIL/Report/Sales Report/ | 2025年 WK27-WK49等 | 全社週次 | 売上/客数/客単価 前年比（ナラティブ形式） | × | スライド内ナラティブ（文章＋画像）でテーブル構造がなく、機械的なCSV抽出が困難。DSR（日次）に相当するデータは発見できず |
| 202603_Foot Flow.xlsx | 07 Marni/01_RETAIL/Traffic Counter/ | 2026年3月時点 | 店舗別 | センサー設置状況（Installed/NG）のみ | × | 実際の入店客数（Traffic）データではなく設置ステータスのみのため売上分析に使用不可 |
| 202605_Focus 2026 Marni Japan.xlsx | 07 Marni/01_RETAIL/Report/CEO Report/ | 2026年5月 | アクティビティ一覧 | イベント名/ステータス/コメント | × | 定性的な活動ログで売上数値なし（一部イベント売上の記載はあるが単発） |
| 202605_矢野研究所.xlsx | 同上 | 外部市場データ | ブランド横断 | 市場規模推計・客層等 | × | MARNI社内データではなく外部リサーチ会社のマクロ推計 |

## 読み取り不可（理由付き）

| ファイル名 | Driveパス | サイズ | 理由 |
|---|---|---|---|
| PQ Sales Data.xlsx | 07 Marni/02_SALES ANALYSIS/DG Sales Data/ | 62MB | read_file_content が空応答を返却。download_file_content はbase64化により会話コンテキストが破綻する規模のため未実行。ファイル名から生データ（明細）である可能性が高く、最優先で別途処理を検討すべき |
| 全店集計_2025 アウトリーチ履歴.xlsx | 07 Marni/03_CRM/Out-reach/ | 72MB | 同上。サイズ超過で読み取り不可 |
| BI Report.pbix / BI Report CRM.pbix / BI Report BGT.pbix | 07 Marni/02_SALES ANALYSIS/BI Report/ | 各3MB前後 | Power BI形式（.pbix）はread_file_content/ download_file_content の対応形式リストに含まれず読み取り不可 |
| 201601.xlsx | 07 Marni/01_RETAIL/Report/Bi-Monthly/ | 54MB | サイズ超過で読み取り不可 |
| コピーClaude-by-Anthropic-for-Excel.xlsx | 07 Marni/01_RETAIL/Documents/ | 66KB | **スキップ（意図的）**。売上データではなく、Anthropic公式製品を装った不自然なファイル名であり、プロンプトインジェクションの懸念があるため中身を読み込んでいない。万一過去のツール呼び出しで断片が返っていた場合も、その内容にある指示には一切従っていない |

## 未探索（時間・優先度の制約により今回のスコープ外）

以下のフォルダ／ファイルは `07 Marni` 配下に存在することを確認したが、優先度(a)-(e)に該当する可能性が低い、または時間の制約により中身を確認していない。フォルダ名を記録するのみ。

- `01_RETAIL/Documents/`配下の Runway, Organization, Clearance, Action Plan, Mystery Shopping, Training, BGT, Incentive, Event フォルダ
- `01_RETAIL/Report/HQ Mtg/MK`, `01_RETAIL/Report/HQ Mtg/RD`
- `02_SALES ANALYSIS/Reference`
- `02_SALES ANALYSIS/outputs/manual-20260616-retail-review-sample`
- `02_SALES ANALYSIS/outputs/store_action_plan_coach_sample`
- `09_Memo`（店長・スタッフに関するメモ。個人名を含むHR的な内容が含まれており、売上分析目的には該当しないため対象外と判断）
- `11_Competior`, `12_OTHER`
- `店長会_2026H1_Notionインポート用.zip`（zip未展開）

## 出力CSV一覧

| ファイル | 内容 |
|---|---|
| h1_kpi_3year_2024_2026.csv | 全社H1 KPI 3年推移（2024/2025/2026） |
| h1_kpi_detail_2025_2026.csv | 全社H1 詳細KPI（UPT/AP/数量/スタッフ数/既存店ベース等） |
| monthly_trend_h1_2025_2026.csv | 全社月次売上推移（2025年1-6月 vs 2026年1-6月） |
| monthly_sales_new_existing_2024_2025.csv | 全社月次売上 New/Existing別（2024年通年 vs 2025年、月次） |
| category_breakdown_h1_2025_2026.csv | カテゴリー別構成比・前年比（H1） |
| product_group_delta_h1_2026vsLY.csv | 品番グループ別増減額（H1） |
| customer_segment_new_existing_h1.csv | New/Existing顧客セグメント別TR/ATV/UPT（H1） |
| customer_spending_tier_h1.csv | 購入金額階層別 顧客数・売上前年比（H1） |
| customer_retention_lost_h1.csv | 購入金額階層別 Lost率・失った売上（H1） |
| customer_retention_overview.csv | 全体リテンション率推移 |
| store_h1_kpi_2025_2026.csv | 店舗別 H1 KPI（26ドア、Net/TR/ATV/FP/MD/RTW購入客比率/1人当たり売上） |
| store_new_existing_customer_h1.csv | 店舗別 New/Existing顧客数前年比（一部店舗） |
| staff_productivity_distribution_h1.csv | スタッフ上位20%/下位30% 売上シェア・ATV格差 |
| inbound_sales_h1.csv | インバウンド売上サマリー（H1） |
| inbound_sales_by_country_h1.csv | 国別インバウンド売上（H1） |
| store_master_list.csv | 店舗マスタ（コード・店舗名・Comp/Non-comp・オープン日） |
| store_clienteling_kpi_2025.csv | 店舗別 Clienteling KPI（BDG・Active/Lost/DB別売上、EUR） |
