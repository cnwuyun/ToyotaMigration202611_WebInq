-- =====================================================================
-- XXSO_SO_610A_WI  支払納品情報検索  共通パッケージ
-- 実行 : @02_packages.sql  （ビュー生成前に実行すること）
-- =====================================================================
set define off
whenever sqlerror exit failure

-- ---------------------------------------------------------------------
-- XXSO_COMMON_OAF_TOOL_PKG
-- ---------------------------------------------------------------------
create or replace package xxso_common_oaf_tool_pkg as
  -- 対象通貨の小数点以下一桁目を切り捨てる
  --   JPY      : 小数第1位を切り捨て（整数化）
  --   外貨     : 小数第3位を切り捨て（2桁保持）
  function trunc_money(p_amount in number, p_currency in varchar2) return number;
end xxso_common_oaf_tool_pkg;
/

create or replace package body xxso_common_oaf_tool_pkg as

  function trunc_money(p_amount in number, p_currency in varchar2) return number is
    l_scale pls_integer := 0;
  begin
    if p_amount is null then
      return null;
    end if;
    if p_currency is not null and p_currency <> 'JPY' then
      l_scale := 2;
    end if;
    return trunc(p_amount, l_scale);
  end trunc_money;

end xxso_common_oaf_tool_pkg;
/

-- ---------------------------------------------------------------------
-- XXSO_LOV_CARTRIDGE_PKG
-- ---------------------------------------------------------------------
create or replace package xxso_lov_cartridge_pkg as

  -- 単価区分「スポット」判定に使用する運用開始日
  c_operation_start_date constant date := to_date('20200101', 'YYYYMMDD');

  -- コード名称（MEANING）取得
  function get_lookup_meaning(p_lookup_type in varchar2,
                              p_lookup_code in varchar2) return varchar2;

  -- コード補足名称（DESCRIPTION）取得
  function get_lookup_description(p_lookup_type in varchar2,
                                  p_lookup_code in varchar2) return varchar2;

  -- 更新者名称取得（社員 / 仕入先担当者 / 支給先担当者）
  function get_updater_info(p_user_id in number) return varchar2;

  -- 金額表示文字列生成
  function get_money_fm(p_format   in varchar2 default 'HTML',
                        p_currency in varchar2 default 'JPY',
                        p_amount   in number   default null,
                        p_scale    in number   default 2) return varchar2;

  -- 倉庫名称・持込先名称の編集名称取得
  function get_materials_wh_name(p_supplier_code    in varchar2,
                                 p_y_item_no        in varchar2,
                                 p_place_code       in varchar2,
                                 p_supply_dest_code in varchar2,
                                 p_business_class   in varchar2) return varchar2;

end xxso_lov_cartridge_pkg;
/

create or replace package body xxso_lov_cartridge_pkg as

  function get_lookup_meaning(p_lookup_type in varchar2,
                              p_lookup_code in varchar2) return varchar2 is
    l_meaning varchar2(240);
  begin
    if p_lookup_code is null then
      return null;
    end if;
    select lv.meaning
      into l_meaning
      from fnd_lookup_values lv
     where lv.lookup_type = p_lookup_type
       and lv.lookup_code = p_lookup_code
       and lv.enabled_flag = 'Y'
       and trunc(sysdate) between trunc(nvl(lv.start_date_active, sysdate))
                               and trunc(nvl(lv.end_date_active, sysdate));
    return l_meaning;
  exception
    when no_data_found then
      return null;
    when too_many_rows then
      return l_meaning;
  end get_lookup_meaning;

  function get_lookup_description(p_lookup_type in varchar2,
                                  p_lookup_code in varchar2) return varchar2 is
    l_desc varchar2(400);
  begin
    if p_lookup_code is null then
      return null;
    end if;
    select lv.description
      into l_desc
      from fnd_lookup_values lv
     where lv.lookup_type = p_lookup_type
       and lv.lookup_code = p_lookup_code
       and lv.enabled_flag = 'Y'
       and trunc(sysdate) between trunc(nvl(lv.start_date_active, sysdate))
                               and trunc(nvl(lv.end_date_active, sysdate));
    return l_desc;
  exception
    when no_data_found then
      return null;
    when too_many_rows then
      return l_desc;
  end get_lookup_description;

  function get_updater_info(p_user_id in number) return varchar2 is
    l_user_name  varchar2(100);
    l_person     varchar2(400);
    l_supplier   varchar2(400);
    l_dest       varchar2(400);
  begin
    if p_user_id is null then
      return null;
    end if;

    begin
      select u.user_name into l_user_name
        from fnd_user u
       where u.user_id = p_user_id;
    exception
      when no_data_found then
        return null;
    end;

    -- 1) 社員（XX + EMPコード）
    if l_user_name like 'XX%' then
      begin
        select p.employee_number || '　' || p.full_name
          into l_person
          from xxso_per_all_people_f_v p
         where p.employee_number = trim(substr(l_user_name, 3));
        if l_person is not null then
          return l_person;
        end if;
      exception
        when no_data_found then
          null;
      end;
      return l_user_name;
    end if;

    -- 2) 仕入先担当者
    begin
      select nvl(si.kanji_supplier_name, si.supplier_name_mst)
        into l_supplier
        from xxpo_suppliers_rp rp,
             xxpo_suppliers_info si
       where rp.supplier_id = si.supplier_id
         and rp.user_id = p_user_id
         and rp.enabled_flag = 'Y'
         and si.web_use_cls = 'Y'
         and si.abolishment_cls is null
         and rownum = 1;
      if l_supplier is not null then
        return l_supplier;
      end if;
    exception
      when no_data_found then
        null;
    end;

    -- 3) 支給先担当者（作成ユーザーで紐付け）
    begin
      select sd.supply_dest_name
        into l_dest
        from xxso_supply_dest_all_v sd
       where sd.created_by = p_user_id
         and sd.enabled_flag = 'Y'
         and rownum = 1;
      if l_dest is not null then
        return l_dest;
      end if;
    exception
      when no_data_found then
        null;
    end;

    return l_user_name;
  end get_updater_info;

  function get_money_fm(p_format   in varchar2 default 'HTML',
                        p_currency in varchar2 default 'JPY',
                        p_amount   in number   default null,
                        p_scale    in number   default 2) return varchar2 is
    l_txt    varchar2(200);
    l_symbol varchar2(10);
    l_fmt    varchar2(80);
    l_neg    boolean := (nvl(p_amount, 0) < 0);
  begin
    if p_amount is null then
      return null;
    end if;

    l_fmt := 'FM9999999999999990'
             || case when nvl(p_scale, 0) > 0
                     then '0.' || rpad('0', p_scale, '0')
                     else '' end;

    l_txt := to_char(abs(p_amount), l_fmt, 'NLS_NUMERIC_CHARACTERS=''.,''');

    l_symbol := case p_currency
                  when 'JPY' then '¥'
                  when 'USD' then '$'
                  when 'EUR' then '€'
                  else p_currency || ' '
                end;

    if p_format = 'HTML' then
      if l_neg then
        return '<span class="money money-negative">(' || l_symbol || l_txt || ')</span>';
      end if;
      return '<span class="money">' || l_symbol || l_txt || '</span>';
    else
      if l_neg then
        return '(' || l_symbol || l_txt || ')';
      end if;
      return l_symbol || l_txt;
    end if;
  end get_money_fm;

  function get_materials_wh_name(p_supplier_code    in varchar2,
                                 p_y_item_no        in varchar2,
                                 p_place_code       in varchar2,
                                 p_supply_dest_code in varchar2,
                                 p_business_class   in varchar2) return varchar2 is
    l_name varchar2(300);
  begin
    -- 名称チェックできない場合は 仕入先名称＋支給先名称 を編集して返す
    begin
      select nvl(si.kanji_supplier_name, si.supplier_name_mst) || '　' || fp.furnished_name
        into l_name
        from xxpo_suppliers_info si, xxso_furnished_places fp
       where si.supplier_code = p_supplier_code
         and fp.furnished_place_code = p_supply_dest_code
         and rownum = 1;
    exception
      when no_data_found then
        l_name := null;
    end;
    return l_name;
  end get_materials_wh_name;

end xxso_lov_cartridge_pkg;
/

-- ---------------------------------------------------------------------
-- XXINVWI_DESC_PKG
-- ---------------------------------------------------------------------
create or replace package xxinvwi_desc_pkg as
  -- 指定日の週（月曜～日曜）を 'YYYY/MM/DD～MM/DD' 形式で返す
  function get_week(p_date in date) return varchar2;
end xxinvwi_desc_pkg;
/

create or replace package body xxinvwi_desc_pkg as

  function get_week(p_date in date) return varchar2 is
    l_start date;
  begin
    if p_date is null then
      return null;
    end if;
    l_start := trunc(p_date, 'IW');
    return to_char(l_start, 'YYYY/MM/DD') || '～' || to_char(l_start + 6, 'MM/DD');
  end get_week;

end xxinvwi_desc_pkg;
/

-- ---------------------------------------------------------------------
-- XXSO_SO_610A_AUTH_PKG  （画面のユーザー区分判定）
-- ---------------------------------------------------------------------
create or replace package xxso_so_610a_auth_pkg as

  -- ログインユーザー名
  function login_user_name return varchar2;

  -- 調達部／原価改善室（TMC社員）判定 : 'Y' / 'N'
  function is_tmc_user return varchar2;

  -- 仕入先ユーザー判定 : 'Y' / 'N'
  function is_supplier_user return varchar2;

  -- 支給先ユーザー判定 : 'Y' / 'N'
  function is_supply_dest_user return varchar2;

  -- ログインユーザーの仕入先コード
  function my_supplier_code return varchar2;

  -- ログインユーザーの支給先コード
  function my_supply_dest_code return varchar2;

  -- 検索対象の参照可否判定 : 'Y' / 'N'
  function scope_ok(p_supplier_code in varchar2,
                    p_supply_dest_code in varchar2) return varchar2;

  -- 支給先関連項目の入力可否（持込先のみ許可）判定 : 'Y' / 'N'
  function can_edit_supply_dest(p_buying_and_selling_class in varchar2) return varchar2;

  -- 本画面の利用権限（TMC社員 / 仕入先担当 / 支給先担当）判定 : 'Y' / 'N'
  function is_payment_delivery_user return varchar2;

end xxso_so_610a_auth_pkg;
/

create or replace package body xxso_so_610a_auth_pkg as

  function login_user_name return varchar2 is
    l_user varchar2(100) := sys_context('APEX$SESSION', 'APP_USER');
  begin
    -- APEX 実行時は APEXユーザー、それ以外（SQL*Plus等）はDBユーザー
    return nvl(l_user, sys_context('USERENV', 'SESSION_USER'));
  end login_user_name;

  function is_tmc_user return varchar2 is
    l_cnt pls_integer := 0;
  begin
    select count(*)
      into l_cnt
      from fnd_user u
     where u.user_name = login_user_name
       and u.user_name like 'XX%'
       and nvl(u.end_date, trunc(sysdate) + 1) > trunc(sysdate);
    return case when l_cnt > 0 then 'Y' else 'N' end;
  end is_tmc_user;

  function is_supplier_user return varchar2 is
  begin
    return case when my_supplier_code is not null then 'Y' else 'N' end;
  end is_supplier_user;

  function is_supply_dest_user return varchar2 is
  begin
    return case when my_supply_dest_code is not null then 'Y' else 'N' end;
  end is_supply_dest_user;

  function my_supplier_code return varchar2 is
    l_code varchar2(30);
  begin
    select si.supplier_code
      into l_code
      from fnd_user u,
           xxpo_suppliers_rp rp,
           xxpo_suppliers_info si
     where u.user_name = login_user_name
       and rp.user_id = u.user_id
       and rp.enabled_flag = 'Y'
       and si.supplier_id = rp.supplier_id
       and si.web_use_cls = 'Y'
       and si.abolishment_cls is null
       and rownum = 1;
    return l_code;
  exception
    when no_data_found then
      return null;
  end my_supplier_code;

  function my_supply_dest_code return varchar2 is
    l_code varchar2(30);
  begin
    select sd.supply_dest_code
      into l_code
      from fnd_user u,
           xxso_supply_dest_all_v sd
     where u.user_name = login_user_name
       and sd.created_by = u.user_id
       and sd.enabled_flag = 'Y'
       and rownum = 1;
    return l_code;
  exception
    when no_data_found then
      return null;
  end my_supply_dest_code;

  function scope_ok(p_supplier_code in varchar2,
                    p_supply_dest_code in varchar2) return varchar2 is
  begin
    -- APEX セッション外（バッチ・SQL検証）は全件参照可
    if sys_context('APEX$SESSION', 'APP_USER') is null then
      return 'Y';
    end if;
    if is_tmc_user = 'Y' then
      return 'Y';
    end if;
    if is_supplier_user = 'Y' and p_supplier_code = my_supplier_code then
      return 'Y';
    end if;
    if is_supply_dest_user = 'Y' and p_supply_dest_code = my_supply_dest_code then
      return 'Y';
    end if;
    return 'N';
  end scope_ok;

  function can_edit_supply_dest(p_buying_and_selling_class in varchar2) return varchar2 is
  begin
    -- 売買区分 = 'U'（支給）の場合、支給先・支給係の入力は不可
    return case when p_buying_and_selling_class = 'U' then 'N' else 'Y' end;
  end can_edit_supply_dest;

  function is_payment_delivery_user return varchar2 is
  begin
    return case when is_tmc_user = 'Y'
                 or is_supplier_user = 'Y'
                 or is_supply_dest_user = 'Y'
                then 'Y'
                else 'N'
           end;
  end is_payment_delivery_user;

end xxso_so_610a_auth_pkg;
/

prompt 02_packages.sql completed.
