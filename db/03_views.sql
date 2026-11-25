-- =====================================================================
-- XXSO_SO_610A_WI  支払納品情報検索  ビュー生成スクリプト
-- 実行 : @02_views.sql
-- =====================================================================
set define off
whenever sqlerror exit failure

-- ---------------------------------------------------------------------
-- 社員情報（更新者名称の解決用）
--   FND_USER.USER_NAME = 'XX' || EMPコード を社員番号とみなす
-- ---------------------------------------------------------------------
create or replace view xxso_per_all_people_f_v as
select u.user_id              as person_id,
       substr(u.user_name, 3) as employee_number,
       u.description          as full_name,
       u.email_address        as email_address,
       'TMC'                  as department_code
  from fnd_user u
 where u.user_name like 'XX%';

-- ---------------------------------------------------------------------
-- 仕入先（有効・無効を全て含む）
-- ---------------------------------------------------------------------
create or replace view xxso_supplier_all_v as
select si.supplier_id,
       si.supplier_code,
       nvl(si.kanji_supplier_name, si.supplier_name_mst) as supplier_name,
       case when si.web_use_cls = 'Y' and si.abolishment_cls is null then 'Y' else 'N' end as enabled_flag
  from xxpo_suppliers_info si;

-- ---------------------------------------------------------------------
-- 支給先（有効・無効を全て含む）
-- ---------------------------------------------------------------------
create or replace view xxso_supply_dest_all_v as
select fp.furnished_place_id   as supply_dest_id,
       fp.furnished_place_code as supply_dest_code,
       fp.furnished_name       as supply_dest_name,
       fp.industrial_type,
       fp.enabled_flag,
       fp.created_by
  from xxso_furnished_places fp;

-- ---------------------------------------------------------------------
-- 支払納品情報検索 メインビュー（項目No.1～61 に対応）
--   金額項目は「経理連携済(ACCOUNTING_LINKED_FLG='Y')」の場合のみ表示する。
-- ---------------------------------------------------------------------
create or replace view xxso_so_webinq_610a_v as
select pd.payment_delivery_id,
       -- 1  Y品番
       pd.y_item_no,
       -- 2  品名
       nvl(pd.item_name,
           (select im.item_name
              from xxin_supply_item_mst im
             where im.y_item_no = pd.y_item_no))                 as item_name,
       -- 3  仕入先コード
       pd.supplier_code,
       -- 4  仕入先名称
       nvl(pd.supplier_name, si.supplier_name)                   as supplier_name,
       -- 5  売買区分
       pd.buying_and_selling_class,
       -- 6  売買区分名称
       xxso_lov_cartridge_pkg.get_lookup_meaning(
           'XXSO_BUYING_AND_SELLING_CLS', pd.buying_and_selling_class)
                                                                 as buying_and_selling_class_mean,
       -- 7  持込先コード（売買区分='U' の場合は非表示）
       case when pd.buying_and_selling_class = 'U' then null
            else pd.brought_in_code
       end                                                       as brought_in_code,
       -- 8  持込先名称（売買区分='U' の場合は非表示）
       case when pd.buying_and_selling_class = 'U' then null
            else nvl(pd.brought_in_name,
                     nvl(xxso_lov_cartridge_pkg.get_lookup_description(
                             'XXSO_MATERIALS_PARTNO', pd.brought_in_code),
                         xxso_lov_cartridge_pkg.get_materials_wh_name(
                             pd.supplier_code, pd.y_item_no, pd.brought_in_code,
                             pd.furnished_place_code, pd.buying_and_selling_class)))
       end                                                       as brought_in_name,
       -- 9  持込先工場区分（売買区分='U' の場合は非表示）
       case when pd.buying_and_selling_class = 'U' then null
            else pd.brought_in_factory_class
       end                                                       as brought_in_factory_class,
       -- 10 メーカーコード
       pd.maker_code,
       -- 11 メーカー名称
       pd.maker_name,
       -- 12 納入数量（小数点3桁）
       to_char(pd.delivery_quantity, 'FM999,999,990.000')        as delivery_quantity_disp,
       -- 13 納入年月日
       pd.delivery_date,
       -- 14 納入番号
       pd.delivery_number,
       -- 15 処理年月日
       pd.processing_date,
       -- 16 ステータス
       pd.status,
       -- 17 ステータス名称
       xxso_lov_cartridge_pkg.get_lookup_meaning(
           'XXSO_PAYMENT_DELIVERYS_STATUS', pd.status)            as status_meaning,
       -- 18 期間区分
       pd.period_class,
       -- 19 調達係コード
       pd.procurement_group_code,
       -- 20 調達担当コード
       pd.procurement_personnel_code,
       -- 21 下請法対象区分（'1':対象 の場合のみ「* 対象」を表示）
       case when pd.subcontract_act_cls = '1' then '* 対象'
            else null
       end                                                       as subcontract_act_cls,
       -- 22 下請法対象区分名称（＊対象）
       xxso_lov_cartridge_pkg.get_lookup_meaning(
           'XXSO_SUBCONTRACT_ACT_CLS', pd.subcontract_act_cls)    as exclusive_flg_mean,
       -- 24 仕様
       pd.spec,
       -- 25 ツールNo
       pd.tool_no,
       -- 26 購入・支給単価（小数点1桁）
       case when pd.accounting_linked_flg = 'Y'
            then xxso_lov_cartridge_pkg.get_money_fm(
                     'HTML', pd.currency_code,
                     xxso_common_oaf_tool_pkg.trunc_money(pd.purchase_furnished_price, pd.currency_code), 1)
       end                                                       as purchase_furnished_price_disp,
       -- 27 購入・支給金額（小数点2桁）
       case when pd.accounting_linked_flg = 'Y'
            then xxso_lov_cartridge_pkg.get_money_fm(
                     'HTML', pd.currency_code,
                     xxso_common_oaf_tool_pkg.trunc_money(pd.purchase_payment_money, pd.currency_code), 2)
       end                                                       as purchase_payment_money_disp,
       -- 28 管理番号
       pd.control_number,
       -- 29 手配連番
       pd.arrangement_serial_no,
       -- 30 計上年月
       pd.recorded_ym,
       -- 31 前納後納区分
       pd.early_and_late_class,
       -- 32 前納後納区分名称
       xxso_lov_cartridge_pkg.get_lookup_meaning(
           'XXSO_EARLY_AND_LATE_CLS', pd.early_and_late_class)    as early_and_late_class_mean,
       -- 33 複社発注区分
       pd.multiple_suppliers_class,
       -- 34 複社発注区分名称
       xxso_lov_cartridge_pkg.get_lookup_meaning(
           'XXPO_MULTIPLE_COM_ODR_CLS', pd.multiple_suppliers_class) as multiple_suppliers_class_mean,
       -- 35 更新者
       xxso_lov_cartridge_pkg.get_updater_info(pd.update_user_id) as update_fnd_user,
       -- 36 更新日付
       pd.update_date,
       -- 37 還元金単価（小数点1桁）
       case when pd.accounting_linked_flg = 'Y'
            then xxso_lov_cartridge_pkg.get_money_fm(
                     'HTML', pd.currency_code,
                     xxso_common_oaf_tool_pkg.trunc_money(pd.revate_unit_price, pd.currency_code), 1)
       end                                                       as revate_unit_price_disp,
       -- 38 支払・支給単価（小数点1桁）
       case when pd.accounting_linked_flg = 'Y'
            then xxso_lov_cartridge_pkg.get_money_fm(
                     'HTML', pd.currency_code,
                     xxso_common_oaf_tool_pkg.trunc_money(pd.payment_furnished_unit_price, pd.currency_code), 1)
       end                                                       as payment_furnished_unit_price_disp,
       -- 39 還元金金額（小数点2桁）
       case when pd.accounting_linked_flg = 'Y'
            then xxso_lov_cartridge_pkg.get_money_fm(
                     'HTML', pd.currency_code,
                     xxso_common_oaf_tool_pkg.trunc_money(pd.revate_amount_of_money, pd.currency_code), 2)
       end                                                       as revate_amount_of_money_disp,
       -- 40 支払・支給金額（小数点2桁）
       case when pd.accounting_linked_flg = 'Y'
            then xxso_lov_cartridge_pkg.get_money_fm(
                     'HTML', pd.currency_code,
                     xxso_common_oaf_tool_pkg.trunc_money(pd.payment_furnished_amount, pd.currency_code), 2)
       end                                                       as payment_furnished_amount_disp,
       -- 41 通貨コード
       pd.currency_code,
       -- 42 支給係コード
       pd.furnishing_group,
       -- 43 支給先コード
       pd.furnished_place_code,
       -- 44 支給先名称
       nvl(pd.furnished_name, fp.furnished_name)                 as furnished_name,
       -- 45 支給先業態区分
       nvl(pd.furnished_industrial_type, fp.industrial_type)     as furnished_industrial_type,
       -- 46 倉庫コード
       pd.wh_code,
       -- 47 倉庫名称
       coalesce(pd.warehouse_name,
                m.wh_name,
                xxso_lov_cartridge_pkg.get_lookup_description(
                    'XXSO_MATERIALS_PARTNO', pd.wh_code))        as warehouse_name,
       -- 48 倉庫業態区分
       nvl(pd.warehouse_industrial_class,
           xxso_lov_cartridge_pkg.get_lookup_meaning(
               'XXSO_MATERIALS_PARTNO', pd.wh_code))             as warehouse_industrial_class,
       -- 49 単価区分
       pd.unit_price_class,
       -- 50 単価区分名称（スポット判定を含む）
       case when pd.creation_date < to_date('20200101', 'YYYYMMDD')
                 and substr(pd.y_item_no, 1, 2) in ('Y1', 'Y2', 'Y3')
                 and pd.unit_price_class = '1'
                 and pd.buying_and_selling_class = 'K'
                 and pd.maker_code is null
            then 'スポット'
            else xxso_lov_cartridge_pkg.get_lookup_meaning(
                     'XXSO_UNIT_PRICE_CLS', pd.unit_price_class)
       end                                                       as unit_price_class_mean,
       -- 51 修理パターン
       pd.rep_pattern,
       -- 52 修理パターン名称
       xxso_lov_cartridge_pkg.get_lookup_meaning(
           'XXIN_FIXED_AMOUNT_REPAIR_PTRN', pd.rep_pattern)       as rep_pattern_mean,
       -- 53 修理可否
       pd.repairable_flag,
       -- 54 修理可否名称
       xxso_lov_cartridge_pkg.get_lookup_meaning(
           'XXPO_REPAIR_YN', pd.repairable_flag)                 as repairable_flag_mean,
       -- 55 訂正前購入・支給単価（修理不可かつ0はNULL）
       case when pd.accounting_linked_flg = 'Y'
                 and not (pd.repairable_flag = '2' and nvl(pd.last_purchase_furnish_price, 0) = 0)
            then xxso_lov_cartridge_pkg.get_money_fm(
                     'HTML', pd.currency_code,
                     xxso_common_oaf_tool_pkg.trunc_money(pd.last_purchase_furnish_price, pd.currency_code), 1)
       end                                                       as last_purchase_furnish_price_disp,
       -- 56 訂正前還元金単価
       case when pd.accounting_linked_flg = 'Y'
                 and not (pd.repairable_flag = '2' and nvl(pd.last_revate_unit_price, 0) = 0)
            then xxso_lov_cartridge_pkg.get_money_fm(
                     'HTML', pd.currency_code,
                     xxso_common_oaf_tool_pkg.trunc_money(pd.last_revate_unit_price, pd.currency_code), 1)
       end                                                       as last_revate_unit_price_disp,
       -- 57 訂正前支払・支給単価
       case when pd.accounting_linked_flg = 'Y'
                 and not (pd.repairable_flag = '2' and nvl(pd.last_payment_furnished_price, 0) = 0)
            then xxso_lov_cartridge_pkg.get_money_fm(
                     'HTML', pd.currency_code,
                     xxso_common_oaf_tool_pkg.trunc_money(pd.last_payment_furnished_price, pd.currency_code), 1)
       end                                                       as last_payment_furnished_price_disp,
       -- 58 データ種別名称
       xxso_lov_cartridge_pkg.get_lookup_meaning(
           'XXSO_MATERIALS_DATA_CLASS', pd.data_type_class)      as data_type_mean,
       -- 59 訂正後データ名称
       xxso_lov_cartridge_pkg.get_lookup_meaning(
           'XXSO_BACK_CORRECTION_FLAG', pd.back_correction_flag) as back_correction_flag_mean,
       -- 60 合計区分名称
       xxso_lov_cartridge_pkg.get_lookup_meaning(
           'XXIN_TOTAL_CLS', pd.total_cls)                       as total_cls_mean,
       -- 61 発注日
       pd.order_date                                             as order_date
  from xxso_payment_deliverys pd
  left join xxso_supplier_all_v si
         on si.supplier_code = pd.supplier_code
  left join xxso_furnished_places fp
         on fp.furnished_place_code = pd.furnished_place_code
  left join (select secondary_inventory_name,
                    max(nvl(description, attribute4)) as wh_name
               from mtl_secondary_inventories
              group by secondary_inventory_name) m
         on m.secondary_inventory_name = pd.wh_code;

comment on table xxso_payment_deliverys is '支払納品情報（明細）';
comment on table xxso_payment_deliverys_sum is '支払納品情報（検索条件サマリ）';
comment on table xxso_furnished_places is '支給先マスタ';
comment on table xxso_brought_in_lookup is '持込先コード参照';

prompt 02_views.sql completed.
