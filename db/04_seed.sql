-- =====================================================================
-- XXSO_SO_610A_WI  支払納品情報検索  初期データ（コード・マスタ・デモ）
-- 実行 : @04_seed.sql
-- =====================================================================
set define off
whenever sqlerror exit failure

-- ---------------------------------------------------------------------
-- コードマスタ
-- ---------------------------------------------------------------------
merge into fnd_lookup_values t
using (
  select 'XXSO_BUYING_AND_SELLING_CLS' lookup_type, 'K' lookup_code, '購入' meaning, '1' seq from dual union all
  select 'XXSO_BUYING_AND_SELLING_CLS', 'U', '支給', '2' from dual union all
  select 'XXSO_PAYMENT_DELIVERYS_STATUS', '1', '未処理', '1' from dual union all
  select 'XXSO_PAYMENT_DELIVERYS_STATUS', '2', '処理中', '2' from dual union all
  select 'XXSO_PAYMENT_DELIVERYS_STATUS', '3', '完了',   '3' from dual union all
  select 'XXSO_SUBCONTRACT_ACT_CLS', '1', '＊対象', '1' from dual union all
  select 'XXSO_SUBCONTRACT_ACT_CLS', '2', '対象外', '2' from dual union all
  select 'XXSO_EARLY_AND_LATE_CLS', '1', '前納', '1' from dual union all
  select 'XXSO_EARLY_AND_LATE_CLS', '2', '後納', '2' from dual union all
  select 'XXSO_EARLY_AND_LATE_CLS', '3', '定期', '3' from dual union all
  select 'XXPO_MULTIPLE_COM_ODR_CLS', '1', '複社発注', '1' from dual union all
  select 'XXPO_MULTIPLE_COM_ODR_CLS', '2', '単独発注', '2' from dual union all
  select 'XXSO_UNIT_PRICE_CLS', '1', '標準', '1' from dual union all
  select 'XXSO_UNIT_PRICE_CLS', '2', 'スポット', '2' from dual union all
  select 'XXIN_FIXED_AMOUNT_REPAIR_PTRN', '1', '定額', '1' from dual union all
  select 'XXIN_FIXED_AMOUNT_REPAIR_PTRN', '2', '実費', '2' from dual union all
  select 'XXIN_FIXED_AMOUNT_REPAIR_PTRN', '3', '修理不能', '3' from dual union all
  select 'XXPO_REPAIR_YN', '1', '可', '1' from dual union all
  select 'XXPO_REPAIR_YN', '2', '不可', '2' from dual union all
  select 'XXSO_MATERIALS_DATA_CLASS', '1', '新品', '1' from dual union all
  select 'XXSO_MATERIALS_DATA_CLASS', '2', '中古', '2' from dual union all
  select 'XXSO_MATERIALS_DATA_CLASS', '3', '再生品', '3' from dual union all
  select 'XXSO_BACK_CORRECTION_FLAG', '1', '訂正前', '1' from dual union all
  select 'XXSO_BACK_CORRECTION_FLAG', '2', '訂正後', '2' from dual union all
  select 'XXIN_TOTAL_CLS', '1', '明細', '1' from dual union all
  select 'XXIN_TOTAL_CLS', '2', '合計', '2' from dual
) s
on (t.lookup_type = s.lookup_type and t.lookup_code = s.lookup_code)
when matched then update set
  t.meaning = s.meaning,
  t.display_sequence = to_number(s.seq),
  t.enabled_flag = 'Y',
  t.last_update_date = sysdate
when not matched then insert
  (lookup_type, lookup_code, meaning, display_sequence, enabled_flag)
  values
  (s.lookup_type, s.lookup_code, s.meaning, to_number(s.seq), 'Y');

-- 倉庫・持込先名称（DETAIL名称変更用: ATTRIBUTE4 に旧名称）
merge into fnd_lookup_values t
using (
  select 'XXSO_MATERIALS_PARTNO' lookup_type, 'WH01' lookup_code, '第1倉庫' meaning, '1' seq from dual union all
  select 'XXSO_MATERIALS_PARTNO', 'WH02', '第2倉庫', '2' from dual union all
  select 'XXSO_MATERIALS_PARTNO', 'BI001', '本社持込先', '3' from dual union all
  select 'XXSO_MATERIALS_PARTNO', 'BI002', '田原持込先', '4' from dual
) s
on (t.lookup_type = s.lookup_type and t.lookup_code = s.lookup_code)
when matched then update set
  t.meaning = s.meaning,
  t.attribute4 = '旧' || s.meaning,
  t.enabled_flag = 'Y',
  t.last_update_date = sysdate
when not matched then insert
  (lookup_type, lookup_code, meaning, attribute4, display_sequence, enabled_flag)
  values
  (s.lookup_type, s.lookup_code, s.meaning, '旧' || s.meaning, to_number(s.seq), 'Y');

-- ---------------------------------------------------------------------
-- 倉庫マスタ
-- ---------------------------------------------------------------------
merge into mtl_secondary_inventories t
using (
  select 'WH01' code, '第1倉庫' name from dual union all
  select 'WH02', '第2倉庫' from dual
) s
on (t.secondary_inventory_name = s.code and t.organization_id = 1)
when not matched then insert
  (organization_id, secondary_inventory_name, description)
  values (1, s.code, s.name);

-- ---------------------------------------------------------------------
-- 支給先マスタ
-- ---------------------------------------------------------------------
merge into xxso_furnished_places t
using (
  select 'FP001' code, '支給先A工場' name, '1' ind_type from dual union all
  select 'FP002', '支給先B工場', '2' from dual
) s
on (t.furnished_place_code = s.code)
when not matched then insert
  (furnished_place_code, furnished_name, industrial_type, enabled_flag)
  values (s.code, s.name, s.ind_type, 'Y');

-- ---------------------------------------------------------------------
-- 仕入先情報
-- ---------------------------------------------------------------------
-- 仕入先情報は既存マスタ(ADMIN.XXPO_SUPPLIERS_INFO)を参照するためシード対象外

-- ---------------------------------------------------------------------
-- 持込先参照
-- ---------------------------------------------------------------------
merge into xxso_brought_in_lookup t
using (
  select 'BI001' code, '本社持込先' name, '1' factory_class from dual union all
  select 'BI002', '田原持込先', '2' from dual
) s
on (t.brought_in_code = s.code)
when not matched then insert
  (brought_in_code, brought_in_name, factory_class, enabled_flag)
  values (s.code, s.name, s.factory_class, 'Y');

-- ---------------------------------------------------------------------
-- ユーザー（更新者表示・権限判定用）
-- ---------------------------------------------------------------------
merge into fnd_user t
using (
  select 'XX10001' user_name, '山田　太郎' description from dual union all
  select 'XX10002', '佐藤　花子' from dual union all
  select 'SUP001_RP', '東海電装株式会社 担当' from dual union all
  select 'FP001_RP', '支給先A工場 担当' from dual
) s
on (t.user_name = s.user_name)
when not matched then insert (user_name, description)
  values (s.user_name, s.description);

-- 仕入先担当者 / 支給先担当者の紐付け
insert into xxpo_suppliers_rp (user_id, supplier_id, enabled_flag)
select u.user_id, si.supplier_id, 'Y'
  from fnd_user u, xxpo_suppliers_info si
 where u.user_name = 'SUP001_RP'
   and si.supplier_code = '1001'
   and not exists (select 1 from xxpo_suppliers_rp rp where rp.user_id = u.user_id and rp.supplier_id = si.supplier_id);

update xxso_furnished_places fp
   set fp.created_by = (select u.user_id from fnd_user u where u.user_name = 'FP001_RP')
 where fp.furnished_place_code = 'FP001'
   and fp.created_by is null;

-- ---------------------------------------------------------------------
-- 検索条件サマリ（LOV用）
-- ---------------------------------------------------------------------
delete from xxso_payment_deliverys_sum;

insert into xxso_payment_deliverys_sum
  (supplier_code, supplier_name, brought_in_code, brought_in_name,
   procurement_group_code, procurement_personnel_code, group_class,
   furnishing_group, supply_dest_code, supply_dest_name,
   wh_code, warehouse_name, multiple_suppliers_class, buying_and_selling_class, status, delivery_date)
values
  ('1001', '東海電装株式会社', 'BI001', '本社持込先', 'G01', 'P001', 'SG', 'F01', 'FP001', '支給先A工場', 'WH01', '第1倉庫', '1', 'K', '3', date '2026-11-10');

insert into xxso_payment_deliverys_sum
  (supplier_code, supplier_name, brought_in_code, brought_in_name,
   procurement_group_code, procurement_personnel_code, group_class,
   furnishing_group, supply_dest_code, supply_dest_name,
   wh_code, warehouse_name, multiple_suppliers_class, buying_and_selling_class, status, delivery_date)
values
  ('1002', '三河精工株式会社', 'BI002', '田原持込先', 'G02', 'P002', 'PR', 'F02', 'FP002', '支給先B工場', 'WH02', '第2倉庫', '2', 'U', '2', date '2026-11-12');

-- ---------------------------------------------------------------------
-- デモ明細（control_number = 'DEMO%' を入れ替え）
-- ---------------------------------------------------------------------
delete from xxso_payment_deliverys where control_number like 'DEMO%';

insert into xxso_payment_deliverys
  (y_item_no, item_name, supplier_code, supplier_name, buying_and_selling_class,
   brought_in_code, brought_in_name, brought_in_factory_class, maker_code, maker_name,
   delivery_quantity, delivery_date, delivery_number, processing_date, status,
   period_class, procurement_group_code, procurement_personnel_code, subcontract_act_cls,
   spec, tool_no, purchase_furnished_price, purchase_payment_money,
   control_number, arrangement_serial_no, recorded_ym, early_and_late_class,
   multiple_suppliers_class, update_user_id, update_date,
   revate_unit_price, payment_furnished_unit_price, revate_amount_of_money, payment_furnished_amount,
   currency_code, furnishing_group, furnished_place_code, furnished_name, furnished_industrial_type,
   wh_code, warehouse_name, warehouse_industrial_class, unit_price_class, rep_pattern, repairable_flag,
   last_purchase_furnish_price, last_revate_unit_price, last_payment_furnished_price,
   data_type_class, back_correction_flag, total_cls, order_date, accounting_linked_flg, creation_date)
values
  ('Y10001', 'フロントバンパ', '1001', '東海電装株式会社', 'K',
   'BI001', '本社持込先', '1', 'M001', 'メーカーA',
   1200, date '2026-11-10', 'DN-0001', date '2026-11-11', '3',
   '01', 'G01', 'P001', '1',
   '板厚2.0mm', 'TL-001', 1500.25, 1800300,
   'DEMO-0001', '01', '202610', '1',
   '1', (select user_id from fnd_user where user_name = 'XX10001'), to_date('2026-11-11 10:00', 'YYYY-MM-DD HH24:MI'),
   100.5, 1200.4, 120600, 1440480,
   'JPY', 'F01', 'FP001', '支給先A工場', '1',
   'WH01', null, '1', '1', '1', '1',
   1400.9, 95.1, 1150.3,
   '1', '2', '1', date '2026-10-01', 'Y', date '2025-12-01');

insert into xxso_payment_deliverys
  (y_item_no, item_name, supplier_code, supplier_name, buying_and_selling_class,
   brought_in_code, brought_in_name, brought_in_factory_class, maker_code, maker_name,
   delivery_quantity, delivery_date, delivery_number, processing_date, status,
   period_class, procurement_group_code, procurement_personnel_code, subcontract_act_cls,
   spec, tool_no, purchase_furnished_price, purchase_payment_money,
   control_number, arrangement_serial_no, recorded_ym, early_and_late_class,
   multiple_suppliers_class, update_user_id, update_date,
   revate_unit_price, payment_furnished_unit_price, revate_amount_of_money, payment_furnished_amount,
   currency_code, furnishing_group, furnished_place_code, furnished_name, furnished_industrial_type,
   wh_code, warehouse_name, warehouse_industrial_class, unit_price_class, rep_pattern, repairable_flag,
   last_purchase_furnish_price, last_revate_unit_price, last_payment_furnished_price,
   data_type_class, back_correction_flag, total_cls, order_date, accounting_linked_flg, creation_date)
values
  ('Y20002', 'リアドア', '1002', '三河精工株式会社', 'U',
   'BI002', '田原持込先', '2', null, null,
   500, date '2026-11-12', 'DN-0002', date '2026-11-13', '2',
   '02', 'G02', 'P002', '2',
   '塗装済', 'TL-002', 800, 400000,
   'DEMO-0002', '02', '202611', '2',
   '2', (select user_id from fnd_user where user_name = 'XX10002'), to_date('2026-11-13 09:30', 'YYYY-MM-DD HH24:MI'),
   null, 900, null, 450000,
   'JPY', null, null, null, null,
   'WH02', null, '2', '2', '3', '2',
   0, 0, 0,
   '2', '1', '2', date '2026-10-05', 'Y', date '2025-11-20');

insert into xxso_payment_deliverys
  (y_item_no, item_name, supplier_code, supplier_name, buying_and_selling_class,
   brought_in_code, brought_in_name, brought_in_factory_class, maker_code, maker_name,
   delivery_quantity, delivery_date, delivery_number, processing_date, status,
   period_class, procurement_group_code, procurement_personnel_code, subcontract_act_cls,
   spec, tool_no, purchase_furnished_price, purchase_payment_money,
   control_number, arrangement_serial_no, recorded_ym, early_and_late_class,
   multiple_suppliers_class, update_user_id, update_date,
   revate_unit_price, payment_furnished_unit_price, revate_amount_of_money, payment_furnished_amount,
   currency_code, furnishing_group, furnished_place_code, furnished_name, furnished_industrial_type,
   wh_code, warehouse_name, warehouse_industrial_class, unit_price_class, rep_pattern, repairable_flag,
   last_purchase_furnish_price, last_revate_unit_price, last_payment_furnished_price,
   data_type_class, back_correction_flag, total_cls, order_date, accounting_linked_flg, creation_date)
values
  ('Y10003', 'サイドメンバ', '1001', '東海電装株式会社', 'K',
   null, null, null, null, null,
   30, date '2026-11-20', 'DN-0003', null, '1',
   '03', 'G01', 'P001', '2',
   null, null, 5000, 150000,
   'DEMO-0003', '03', '202611', '3',
   '2', (select user_id from fnd_user where user_name = 'SUP001_RP'), to_date('2026-11-21 14:00', 'YYYY-MM-DD HH24:MI'),
   null, null, null, null,
   'JPY', 'F01', 'FP001', '支給先A工場', '1',
   'WH01', null, '1', '1', null, null,
   null, null, null,
   null, null, null, null, 'N', date '2019-12-01');

commit;

prompt 04_seed.sql completed.
