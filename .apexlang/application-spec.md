# 支払納品情報検索（XXSO_SO_610A_WI） APEXアプリケーション仕様書

## Summary

- Application purpose: 支払納品情報（購入・支給）を検索し、一覧表示およびCSV/Excelダウンロードを行う社内WEB照会画面（WebInq 610A）。
- Target users: 調達部／原価改善室のTMC社員、仕入先ユーザー、支給先ユーザー。
- Primary workflows: 検索条件入力 → 一覧照会 → 一括ダウンロード。
- Authoritative sources: `C7_MD_SO_AN100_610_支払納品情報_Issue1.2B.md`（機能仕様）, `db/01_tables.sql`〜`db/04_seed.sql`（AI生成スキーマ）。DDLはプロジェクト直下 `db/` に配置（APEXアプリ実行時アーティファクト許可リスト外のため、アプリルートには置かない）。ライブDBは wallet 接続（SQLcl 経由）で利用可能。
- Target app path: `applications/xxso-so-610a`
- Runtime mode: offline planning / live DB check later
- Destination APEX workspace: MAPS（解析スキーマ WKSP_MAPS）
- Known exclusions: 実績登録・更新系画面、締め処理、バッチ（本画面は参照専用）。EBS標準表（MTL_SECONDARY_INVENTORIES等）は不足時のみ生成。

## Requirement Coverage Matrix

| Requirement ID | Requirement Text / Cue | Planned Page / Region / Action | Frozen Plan Reference | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| FR-001 | 検索条件：Y品番 | P1 / search-conditions / P1_Y_ITEM_NO | FAP-1, FRP-1 | covered | 仕様 4.1 抽出条件 |
| FR-002 | 検索条件：仕入先コード（LOV） | P1 / search-conditions / P1_SUPPLIER_CODE | FAP-1, FRP-1 | covered | 仕様 4.1 |
| FR-003 | 検索条件：売買区分（購入/支給） | P1 / search-conditions / P1_BUYING_AND_SELLING_CLASS | FAP-1, FRP-1 | covered | 仕様 4.1 |
| FR-004 | 検索条件：納入年月日カラ（必須） | P1 / search-conditions / P1_DELIVERY_DATE_FROM | FAP-1, FRP-1 | covered | 仕様 4.1 必須○ |
| FR-005 | 検索条件：納入年月日マデ（必須） | P1 / search-conditions / P1_DELIVERY_DATE_TO | FAP-1, FRP-1 | covered | 仕様 4.1 必須○ |
| FR-006 | 検索条件：納入番号 | P1 / search-conditions / P1_DELIVERY_NUMBER | FAP-1, FRP-1 | covered | 仕様 4.1 |
| FR-007 | 検索条件：ステータス（必須） | P1 / search-conditions / P1_STATUS | FAP-1, FRP-1 | covered | 仕様 4.1 必須○ |
| FR-008 | 検索条件：調達係コード（LOV） | P1 / search-conditions / P1_PROCUREMENT_GROUP_CODE | FAP-1, FRP-1 | covered | 仕様 4.1 |
| FR-009 | 検索条件：調達担当コード（LOV） | P1 / search-conditions / P1_PROCUREMENT_PERSONNEL_CODE | FAP-1, FRP-1 | covered | 仕様 4.1 |
| FR-010 | 検索条件：複社発注区分（LOV） | P1 / search-conditions / P1_MULTIPLE_SUPPLIERS_CLASS | FAP-1, FRP-1 | covered | 仕様 4.1 |
| FR-011 | 検索条件：手配連番 | P1 / search-conditions / P1_ARRANGEMENT_SERIAL_NO | FAP-1, FRP-1 | covered | 仕様 4.1 |
| FR-012 | 検索条件：支給係コード（LOV） | P1 / search-conditions / P1_FURNISHING_GROUP | FAP-1, FRP-1 | covered | 仕様 4.1 |
| FR-013 | 検索条件：支給先コード（LOV） | P1 / search-conditions / P1_FURNISHED_PLACE_CODE | FAP-1, FRP-1 | covered | 仕様 4.1 |
| FR-014 | 検索条件：倉庫コード（LOV） | P1 / search-conditions / P1_WH_CODE | FAP-1, FRP-1 | covered | 仕様 4.1 |
| FR-015 | 検索条件：持込先コード（LOV） | P1 / search-conditions / P1_BROUGHT_IN_CODE | FAP-1, FRP-1 | covered | 仕様 4.1 |
| FR-016 | 検索実行 | P1 / button search | FAP-1, FRP-3 | covered | 仕様 4.2 検索 |
| FR-017 | 条件クリア | P1 / button clear | FAP-1, FRP-3 | covered | 仕様 4.2 クリア |
| FR-018 | 一括ダウンロード（CSV/Excel） | P1 / payment-delivery-report Actions > Download | FAP-1, FRP-2 | covered | 仕様 4.2 一括ダウンロード |
| FR-019 | 一覧項目1〜61の表示 | P1 / payment-delivery-report の列 | FAP-1, FRP-2 | covered | 仕様 4.1 一覧項目 |
| FR-020 | 金額項目は経理連携済のみ表示 | VIEW: xxso_so_webinq_610a_v の CASE | FRP-2 | covered | 仕様 4.1 備考 |
| FR-021 | 修理不可かつ0円の訂正前単価は非表示 | VIEW: last_*_disp の CASE | FRP-2 | covered | 仕様 4.1 備考 |
| FR-022 | 単価区分スポット判定 | VIEW: unit_price_class_mean の CASE | FRP-2 | covered | 仕様 4.1 備考 |
| FR-023 | 売買区分による持込先/支給先の入力可否 | P1 / dynamicAction toggle-supply-dest-fields | FRP-1 | covered | 仕様 4.1 備考 |
| FR-024 | 権限別データ参照制御（TMC/仕入先/支給先） | アプリ認可 + VIEW絞込関数 | FAP-1, FRP-2 | covered | 仕様 4.1 備考 |
| FR-025 | 検索条件必須チェック | P1 検証（納入年月日カラ/マデ、ステータス） | FRP-1 | covered | 仕様 4.1 必須○ |
| FR-026 | 画面項目以外の参照専用（更新なし） | 全ページ参照専用 | FAP-1 | covered | 仕様 1. 概要 |

（明細項目No.1〜61の各列は FRP-2 の列定義で1対1にカバー）

## Source Evidence Matrix

| Fact Type | Object / Column / Relationship / Behavior | Evidence Source | Evidence Detail | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| table | XXSO_PAYMENT_DELIVERYS | schema_doc | db/01_tables.sql（AI生成） | covered | 明細の主表 |
| table | XXSO_PAYMENT_DELIVERYS_SUM | schema_doc | db/01_tables.sql | covered | 検索条件サマリ |
| table | XXSO_FURNISHED_PLACES | schema_doc | db/01_tables.sql | covered | 支給先 |
| table | XXPO_SUPPLIERS_INFO / XXPO_SUPPLIERS_RP | schema_doc | db/01_tables.sql | covered | 仕入先・担当者 |
| table | XXIN_SUPPLY_ITEM_MST | schema_doc | db/01_tables.sql | covered | 支給品マスタ |
| table | XXSO_BROUGHT_IN_LOOKUP | schema_doc | db/01_tables.sql | covered | 持込先参照 |
| table | MTL_SECONDARY_INVENTORIES | schema_doc | db/01_tables.sql（無い場合のみ生成） | covered | 倉庫名称 |
| table | FND_USER / FND_LOOKUP_VALUES | schema_doc | db/01_tables.sql（無い場合のみ生成） | covered | 更新者・コード名称 |
| package | XXSO_COMMON_OAF_TOOL_PKG.TRUNC_MONEY | schema_doc | db/02_packages.sql | covered | 通貨桁切捨て |
| package | XXSO_LOV_CARTRIDGE_PKG | schema_doc | db/02_packages.sql | covered | 名称/金額/更新者 |
| package | XXINVWI_DESC_PKG.GET_WEEK | schema_doc | db/02_packages.sql | covered | 週表示 |
| package | XXSO_SO_610A_AUTH_PKG | schema_doc | db/02_packages.sql | covered | 権限判定 |
| view | XXSO_SO_WEBINQ_610A_V | schema_doc | db/03_views.sql | covered | 一覧の単一ソース |
| view | XXSO_PER_ALL_PEOPLE_F_V / XXSO_SUPPLIER_ALL_V / XXSO_SUPPLY_DEST_ALL_V | schema_doc | db/03_views.sql | covered | 名称解決 |
| column | xxso_so_webinq_610a_v の全61項目 + payment_delivery_id | schema_doc | db/03_views.sql | covered | 一覧列 |
| role | TMC社員 / 仕入先ユーザー / 支給先ユーザー | user_asserted | 仕様 4.1 備考 | covered | 認可・絞込 |
| sql | IR の検索SQL（バインドP1_*） | schema_doc | p00001 の sqlQuery | covered | 15条件 |

## Frozen Application Plan

| Page | Name | Group | Type / Native Pattern | Page Mode | Menu | Breadcrumb Entry | Requirement ID | Primary Source |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FAP-1 / 1 | 支払納品情報検索 | - | Interactive Report + filter form | normal | - | home（root） | FR-001〜FR-026 | view xxso_so_webinq_610a_v |

- 参照専用の単一画面。モーダル・フォーム・更新処理は持たない。
- テンプレート: Universal Theme `standard`。

## Frozen Region Plan

| Page | Order | Region Name | Native Component Family | Parent/Child | Source Shape | Source Object / Query Intent | Layout Recipe | Columns / Display Mappings | Links / Actions | Filters | Refresh / Context |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FRP-1 | 10 | 支払納品情報検索 (title-bar) | staticContent | parent | none/staticContent | タイトルバー + パンくず | breadcrumbBar | ページタイトル | - | - | - |
| FRP-2 | 20 | search-conditions | staticContent | parent | none/staticContent | 検索条件入力領域 | contentBody / 3列 | P1_* 15項目 | 検索・クリア | 15条件 | 検索時IR再取得 |
| FRP-3 | 30 | payment-delivery-report | interactiveReport | child | sql | `select * from xxso_so_webinq_610a_v where ... :P1_*` | contentBody | 61項目（表示58/非表示3） | Actions>Download | - | ページ送信で再検索 |

### 一覧列（項目No. / 列 / 表示形式）

| No | 列 | ヘッダ | 型 |
| --- | --- | --- | --- |
| 1 | Y_ITEM_NO | Y品番 | plainText |
| 2 | ITEM_NAME | 品名 | plainText |
| 3 | SUPPLIER_CODE | 仕入先コード | plainText |
| 4 | SUPPLIER_NAME | 仕入先名称 | plainText |
| 5 | BUYING_AND_SELLING_CLASS | 売買区分 | plainText |
| 6 | BUYING_AND_SELLING_CLASS_MEAN | 売買区分名称 | plainText |
| 7 | BROUGHT_IN_CODE | 持込先コード | plainText |
| 8 | BROUGHT_IN_NAME | 持込先名称 | plainText |
| 9 | BROUGHT_IN_FACTORY_CLASS | 持込先工場区分 | plainText |
| 10 | MAKER_CODE | メーカーコード | plainText |
| 11 | MAKER_NAME | メーカー名称 | plainText |
| 12 | DELIVERY_QUANTITY_DISP | 納入数量 | html |
| 13 | DELIVERY_DATE | 納入年月日 | plainText(date) |
| 14 | DELIVERY_NUMBER | 納入番号 | plainText |
| 15 | PROCESSING_DATE | 処理年月日 | plainText(date) |
| 16 | STATUS | ステータス | plainText |
| 17 | STATUS_MEANING | ステータス名称 | plainText |
| 18 | PERIOD_CLASS | 期間区分 | plainText |
| 19 | PROCUREMENT_GROUP_CODE | 調達係コード | plainText |
| 20 | PROCUREMENT_PERSONNEL_CODE | 調達担当コード | plainText |
| 21 | SUBCONTRACT_ACT_CLS | 下請法対象区分 | plainText |
| 22 | EXCLUSIVE_FLG_MEAN | 下請法対象区分名称 | plainText |
| 24 | SPEC | 仕様 | plainText |
| 25 | TOOL_NO | ツールNo | plainText |
| 26 | PURCHASE_FURNISHED_PRICE_DISP | 購入・支給単価 | html |
| 27 | PURCHASE_PAYMENT_MONEY_DISP | 購入・支給金額 | html |
| 28 | CONTROL_NUMBER | 管理番号 | plainText |
| 29 | ARRANGEMENT_SERIAL_NO | 手配連番 | plainText |
| 30 | RECORDED_YM | 計上年月 | plainText |
| 31 | EARLY_AND_LATE_CLASS | 前納後納区分 | plainText |
| 32 | EARLY_AND_LATE_CLASS_MEAN | 前納後納区分名称 | plainText |
| 33 | MULTIPLE_SUPPLIERS_CLASS | 複社発注区分 | plainText |
| 34 | MULTIPLE_SUPPLIERS_CLASS_MEAN | 複社発注区分名称 | plainText |
| 35 | UPDATE_FND_USER | 更新者 | plainText |
| 36 | UPDATE_DATE | 更新日付 | plainText(date) |
| 37 | REVATE_UNIT_PRICE_DISP | 還元金単価 | html |
| 38 | PAYMENT_FURNISHED_UNIT_PRICE_DISP | 支払・支給単価 | html |
| 39 | REVATE_AMOUNT_OF_MONEY_DISP | 還元金金額 | html |
| 40 | PAYMENT_FURNISHED_AMOUNT_DISP | 支払・支給金額 | html |
| 41 | CURRENCY_CODE | 通貨コード | plainText |
| 42 | FURNISHING_GROUP | 支給係コード | plainText |
| 43 | FURNISHED_PLACE_CODE | 支給先コード | plainText |
| 44 | FURNISHED_NAME | 支給先名称 | plainText |
| 45 | FURNISHED_INDUSTRIAL_TYPE | 支給先業態区分 | plainText |
| 46 | WH_CODE | 倉庫コード | plainText |
| 47 | WAREHOUSE_NAME | 倉庫名称 | plainText |
| 48 | WAREHOUSE_INDUSTRIAL_CLASS | 倉庫業態区分 | plainText |
| 49 | UNIT_PRICE_CLASS | 単価区分 | plainText |
| 50 | UNIT_PRICE_CLASS_MEAN | 単価区分名称 | plainText |
| 51 | REP_PATTERN | 修理パターン | plainText |
| 52 | REP_PATTERN_MEAN | 修理パターン名称 | plainText |
| 53 | REPAIRABLE_FLAG | 修理可否 | plainText |
| 54 | REPAIRABLE_FLAG_MEAN | 修理可否名称 | plainText |
| 55 | LAST_PURCHASE_FURNISH_PRICE_DISP | 訂正前購入・支給単価 | html |
| 56 | LAST_REVATE_UNIT_PRICE_DISP | 訂正前還元金単価 | html |
| 57 | LAST_PAYMENT_FURNISHED_PRICE_DISP | 訂正前支払・支給単価 | html |
| 58 | DATA_TYPE_MEAN | データ種別名称 | plainText |
| 59 | BACK_CORRECTION_FLAG_MEAN | 訂正後データ名称 | plainText |
| 60 | TOTAL_CLS_MEAN | 合計区分名称 | plainText |
| 61 | ORDER_DATE | 発注日 | plainText(date) |

## Application Composition Plan

- Application scope: 1画面（検索一覧）＋ログイン。
- Artifact scope: `applications/xxso-so-610a`（application.apx / pages / shared-components / db）。
- Page groups: なし（単一画面）。
- Shared LOVs: 11個（下記 LOVs）。
- Navigation menu: なし（単一画面・ホーム=ページ1）。
- Static files/icons: 既定アイコンのみ。
- Plan-to-artifact traceability: FAP-1→p00001、FRP-1→title-bar、FRP-2→search-conditions、FRP-3→payment-delivery-report。

### Management Or Launch Hub Entries

| Page | Label | Target Page | Icon | Description | Evidence |
| --- | --- | --- | --- | --- | --- |
| なし | - | - | - | 単一画面のためハブ不要 | 仕様 1. |

### Breadcrumb Hierarchy

| Page | Entry | Root | Parent Entry | Parent Page | Evidence |
| --- | --- | --- | --- | --- | --- |
| 1 | home | true | - | - | 単一画面 |

## Behavior Coverage

### Modal Targets And Cross-Page Links

| Source Page | Source Region / Column / Action | Target Page | Target Items | Key Column | Presentation | Close Refresh Region | Requirement ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| なし | - | - | - | - | - | - | 参照専用 |

### Page-Level Actions

| Page | Label | Target Page | Item Mappings | Placement | Requirement ID |
| --- | --- | --- | --- | --- | --- |
| 1 | 検索 | 1 | - | search-conditions | FR-016 |
| 1 | クリア | 1 | - | search-conditions | FR-017 |
| 1 | CSVダウンロード | 1 | - | IR Actions（標準機能） | FR-018 |

### Parent-Child Context And Action Coverage

| Page | Parent Region | Context Item | Source Key Column | Child Regions | Action Coverage | Exclusions |
| --- | --- | --- | --- | --- | --- | --- |
| なし | - | - | - | - | - | 明細照会なし |

### Form Validations, Context, And Defaults

| Page | Item | Behavior Type | Message / Source | Required When / Trigger | Editable / Visible | Requirement ID |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | P1_DELIVERY_DATE_FROM | validation | 納入年月日（カラ）を入力してください。 | 常時 | editable | FR-004 / FR-025 |
| 1 | P1_DELIVERY_DATE_TO | validation | 納入年月日（マデ）を入力してください。 | 常時 | editable | FR-005 / FR-025 |
| 1 | P1_STATUS | validation | ステータスを選択してください。 | 常時 | editable | FR-007 / FR-025 |
| 1 | P1_SUPPLIER_CODE | default | XXSO_SO_610A_AUTH_PKG.MY_SUPPLIER_CODE（仕入先ユーザーのみ） | 認証時 | 仕入先ユーザーは読取専用 | FR-024 |
| 1 | P1_FURNISHED_PLACE_CODE | default | XXSO_SO_610A_AUTH_PKG.MY_SUPPLY_DEST_CODE（支給先ユーザーのみ） | 認証時 | 支給先ユーザーは読取専用 | FR-024 |
| 1 | P1_FURNISHING_GROUP / P1_FURNISHED_PLACE_CODE | validation(context) | 売買区分='U'時は入力不可 | P1_BUYING_AND_SELLING_CLASS変更 | 動的無効化 | FR-023 |
| 1 | P1_BROUGHT_IN_CODE | validation(context) | 売買区分='U'時のみ有効 | P1_BUYING_AND_SELLING_CLASS変更 | 動的無効化 | FR-023 |

### Form Processes And Delete Rules

| Page | Form Region | Process Intent | Create | Update | Delete | Delete Restrictions | Requirement ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| - | - | none | - | - | - | 参照専用 | FR-026 |

### Refresh Dependencies

| Event Source | Event | Affected Region / Item | Refresh / Set-Value Behavior | Requirement ID |
| --- | --- | --- | --- | --- |
| button search | click | payment-delivery-report | ページ送信によりIR再検索 | FR-016 |
| P1_BUYING_AND_SELLING_CLASS | change | P1_BROUGHT_IN_CODE / P1_FURNISHING_GROUP / P1_FURNISHED_PLACE_CODE | 入力可否の切替（disable/enable） | FR-023 |

### Security, Guidance, And Empty States

| Page / Region / Item | Coverage Type | Planned Behavior / Text | Evidence | Requirement ID |
| --- | --- | --- | --- | --- |
| App | authorization | `is-payment-delivery-user`（TMC社員 or 仕入先担当 or 支給先担当） | 仕様 4.1 備考 | FR-024 |
| payment-delivery-report | no-data | 該当する支払納品情報はありません。 | 仕様 4.2 | FR-019 |
| search-conditions | help | 納入年月日（カラ・マデ）とステータスは必須です。 | 仕様 4.1 | FR-025 |

### Map Marker Targets And Viewport

| Page | Source Region | Source Layer | Target Page | Key Column | Target Item Mappings | Initial Viewport Strategy | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| なし | - | - | - | - | - | - | 地図要件なし |

## Rich UI Pattern Plan

| Pattern | Page / Region | Native APEX Component | Evidence | Generation Notes |
| --- | --- | --- | --- | --- |
| 検索一覧 | P1 / payment-delivery-report | Interactive Report | 仕様 4.1 | 列選択・ソート・ダウンロードはIR標準機能 |
| 条件入力 | P1 / search-conditions | Static Content + Page Items | 仕様 4.1 | 3列レイアウト |

## LOVs

### Static LOVs

| LOV | Values | Display / Return | Evidence | Consuming Items |
| --- | --- | --- | --- | --- |
| XXSO_BUYING_AND_SELLING_CLS | K=購入 / U=支給 | 名称 / コード | FND_LOOKUP_VALUES | P1_BUYING_AND_SELLING_CLASS |
| XXSO_PAYMENT_DELIVERYS_STATUS | 1=未処理 / 2=処理中 / 3=完了 | 名称 / コード | FND_LOOKUP_VALUES | P1_STATUS |
| XXPO_MULTIPLE_COM_ODR_CLS | 1=複社発注 / 2=単独発注 | 名称 / コード | FND_LOOKUP_VALUES | P1_MULTIPLE_SUPPLIERS_CLASS |

### Dynamic LOVs

| LOV | Display Column | Return Column | Source Object | Evidence | Consuming Items |
| --- | --- | --- | --- | --- | --- |
| XXSO_SUPPLIER_610A | SUPPLIER_NAME | SUPPLIER_CODE | XXSO_SUPPLIER_ALL_V | db/03_views.sql | P1_SUPPLIER_CODE |
| XXSO_BROUGHT_IN_610A | BROUGHT_IN_NAME | BROUGHT_IN_CODE | XXSO_BROUGHT_IN_LOOKUP | db/01_tables.sql | P1_BROUGHT_IN_CODE |
| XXSO_PROCUREMENT_GROUP_610A | 名称 | コード | XXSO_PAYMENT_DELIVERYS_SUM | db/01_tables.sql | P1_PROCUREMENT_GROUP_CODE |
| XXSO_PROCUREMENT_PERSON_610A | 名称 | コード | XXSO_PAYMENT_DELIVERYS_SUM | db/01_tables.sql | P1_PROCUREMENT_PERSONNEL_CODE |
| XXSO_FURNISHING_GROUP_610A | 名称 | コード | XXSO_PAYMENT_DELIVERYS_SUM | db/01_tables.sql | P1_FURNISHING_GROUP |
| XXSO_FURNISHED_PLACE_610A | SUPPLY_DEST_NAME | SUPPLY_DEST_CODE | XXSO_SUPPLY_DEST_ALL_V | db/03_views.sql | P1_FURNISHED_PLACE_CODE |
| XXSO_WAREHOUSE_610A | 名称 | コード | MTL_SECONDARY_INVENTORIES / FND_LOOKUP_VALUES | db/01_tables.sql | P1_WH_CODE |

## Data, Validation, And Behavior

- Required fields: P1_DELIVERY_DATE_FROM, P1_DELIVERY_DATE_TO, P1_STATUS
- Optional fields: 上記以外の12条件
- Conditional validations: 売買区分='U' のとき支給先・支給係は無効、'K' のとき持込先は無効
- Context-owned hidden/display-only items: 仕入先ユーザーのP1_SUPPLIER_CODE、支給先ユーザーのP1_FURNISHED_PLACE_CODE（読取専用）
- Defaulted items and override policy: 仕入先/支給先コードはログインユーザーから既定値設定、上書き不可
- Foreign keys: 仕入先=XXPO_SUPPLIERS_INFO、支給先=XXSO_FURNISHED_PLACES、倉庫=MTL_SECONDARY_INVENTORIES
- Check constraints: 売買区分 K/U、ステータス 1/2/3（FND_LOOKUP_VALUESで管理）
- Date/time handling: 納入年月日は DATE 型、表示は `YYYY/MM/DD`
- Derived metrics and totals: 金額表示は `XXSO_LOV_CARTRIDGE_PKG.GET_MONEY_FM` + `TRUNC_MONEY`
- Delete restrictions: なし（参照専用）
- Report-to-form behavior: なし
- Modal return behavior: なし
- Security and authorization assumptions: 認証は Oracle APEX Accounts、認可は `is-payment-delivery-user`、データ絞込は `XXSO_SO_610A_AUTH_PKG.SCOPE_OK`
- Help, accessibility, guidance text: 検索条件領域に必須項目のガイダンス
- No-data and empty-state behavior: 「該当する支払納品情報はありません。」

## Plan Consistency Gate

- 全FR（26件）は covered。未解決なし。
- DBオブジェクト／列は `db/*.sql` に定義済み（ライブDB未接続）。
- 全ページ・領域・LOV・パンくずは凍結済み。

## Generation Readiness

- Required canonical templates or construction packs: `standard` ページテンプレート、`@/standard` リージョンテンプレート、`@/text` ボタンテンプレート
- Required compiler-truth queries: `apexlang compiler-truth audit`
- Required local validation: `apexlang format --strict-structure` / `apexlang validate`
- Required live validation, if any: `runtime validate` / `runtime roundtrip`（DB接続は復旧済み）
- Import eligibility blockers: なし（DDL 01〜04 実行済み、ビュー/パッケージ VALID を確認）

## Test Plan

| Scenario | Requirement / Acceptance Criteria | Pages / Regions | Expected Result | Validation Method |
| --- | --- | --- | --- | --- |
| 初期表示 | FR-001〜FR-019 | P1 | 条件領域と一覧が表示される | ローカル検証 + 将来のruntime verify-ui |
| 必須チェック | FR-025 | P1 | 未入力時にエラーメッセージ | ページ検証定義の確認 |
| 検索 | FR-016 | P1 / payment-delivery-report | 条件に合致する行のみ表示 | IR SQLの確認 |
| クリア | FR-017 | P1 | 条件が初期化される | ボタン定義の確認 |
| ダウンロード | FR-018 | P1 / payment-delivery-report | CSV/Excelが取得できる | IR標準機能 |
| 売買区分切替 | FR-023 | P1 | 持込先／支給先の入力可否が切り替わる | 動的アクション定義の確認 |
| 権限絞込 | FR-024 | P1 | 仕入先/支給先ユーザーは自社データのみ | 認可・SQL確認 |
| 金額非表示 | FR-020 | P1 | 未連携データは金額が空 | ビュー定義の確認 |
| 訂正前単価 | FR-021 | P1 | 修理不可かつ0は空 | ビュー定義の確認 |
| スポット判定 | FR-022 | P1 | 条件一致時に「スポット」 | ビュー定義の確認 |

## Assumptions

- `XXSO_SO_WEBINQ_610A_V` は一覧の唯一のソースとし、表示用の名称・金額文字列もビューで解決する。
- 通貨が JPY の場合は小数第1位切捨て、外貨は小数第3位切捨てとする（`TRUNC_MONEY`）。
- 単価区分「スポット」判定の運用開始日は `2020/01/01` を既定値とする。
- 仕様書の項目No.23は欠番のため、そのまま欠番として扱う（AIによる仕様修正メモ）。
- 下請法対象区分（項目22）は「'1':対象 の場合のみ『* 対象』を表示、以外はブランク」と解釈してビューで整形する（AIによる仕様修正メモ）。
- 持込先コード（項目7）／持込先工場区分（項目9）は売買区分='U'（支給）の場合に非表示（NULL）とする（AIによる仕様修正メモ）。
- 仕様書記載の `XXINVWI_DESC_PKG` はパッケージ名の綴りを正として実装（初版のタイポ `XXINWVI_DESC_PKG` を修正済み）。
- 一覧のCSV/ExcelダウンロードはAPEX対話式レポート標準のダウンロード機能（Actionsメニュー）で提供し、帳票SQL追加の週表示列は対象外とする（AIによる仕様修正メモ）。

## Missing Inputs / Blockers

- Planning blockers: なし
- Generation blockers: なし（AI生成スキーマで代替）
- Live validation/import: Oracle ADB（wallet 接続 / SQLcl 経由・thin モードは不可）に接続済み。`db/01_tables.sql`〜`04_seed.sql` 実行済み、パッケージ・ビュー VALID、デモデータ3件。
