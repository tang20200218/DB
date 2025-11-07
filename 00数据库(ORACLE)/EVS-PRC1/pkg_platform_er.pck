CREATE OR REPLACE PACKAGE pkg_platform_er IS

  /***************************************************************************************************
  名称     : pkg_platform_er
  功能描述 : 平台印制易-通过交换接收绑定单位/用户
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-10  唐金鑫  创建
  ***************************************************************************************************/

  -- 绑定单位
  PROCEDURE p_dept
  (
    i_info IN CLOB, -- 表单数据
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 绑定用户
  PROCEDURE p_user
  (
    i_info IN CLOB, -- 表单数据
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除单位、用户
  PROCEDURE p_objdel
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_platform_er IS

  -- 绑定单位
  PROCEDURE p_dept
  (
    i_info IN CLOB, -- 表单数据
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml   xmltype;
    v_i     INT := 0;
    v_xpath VARCHAR2(200);
  
    v_sort INT := 0;
    v_id   VARCHAR2(64);
  
    v_datatime   VARCHAR2(64);
    v_datatime_d DATE;
    v_fromdate   DATE;
  
    v_dept_id     VARCHAR2(64); -- 港号
    v_dept_nm     VARCHAR2(200); -- 名称
    v_dept_code   VARCHAR2(64); -- 机构代码
    v_dept_ver    INT; -- 版本号
    v_dept_enable INT; -- 1-在用 0-停用/删除
    v_dept_rs     VARCHAR2(4000); -- 路由信息
    v_islegal     INT;
    v_digitalid   VARCHAR2(64);
  
    v_autoqf INT := 0;
    v_qfflag INT := 0;
  BEGIN
    mydebug.wlog('i_info', i_info);
  
    SELECT MAX(t.sort) INTO v_sort FROM info_register_obj t WHERE t.datatype = 1;
    IF v_sort IS NULL THEN
      v_sort := 0;
    END IF;
  
    -- 解析XML
    v_xml := xmltype(i_info);
  
    SELECT myxml.f_getvalue(v_xml, '/info/datatime') INTO v_datatime FROM dual;
  
    BEGIN
      v_datatime_d := to_date(v_datatime, 'yyyy-mm-dd hh24:mi:ss');
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_datatime_d IS NULL THEN
      v_datatime_d := SYSDATE;
    END IF;
  
    v_i := 1;
    WHILE v_i <= 9999 LOOP
      v_xpath := mystring.f_concat('/info/datas/dept[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@id')) INTO v_dept_id FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@nm')) INTO v_dept_nm FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@code')) INTO v_dept_code FROM dual;
      SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@ver')) INTO v_dept_ver FROM dual;
      SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@enable')) INTO v_dept_enable FROM dual;
      SELECT myxml.f_getnode_str(v_xml, mystring.f_concat(v_xpath, 'rs')) INTO v_dept_rs FROM dual;
      SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@islegal')) INTO v_islegal FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@digitalid')) INTO v_digitalid FROM dual;
    
      IF v_islegal IS NULL THEN
        v_islegal := 1;
      END IF;
    
      IF mystring.f_isnull(v_dept_id) THEN
        v_i := 9999;
      ELSE
        v_id       := '';
        v_fromdate := NULL;
      
        IF v_dept_enable = 1 THEN
          v_autoqf := 1;
          v_qfflag := 0;
          BEGIN
            SELECT t.autoqf, t.qfflag
              INTO v_autoqf, v_qfflag
              FROM info_register_obj t
             WHERE objid = v_dept_id
               AND rownum <= 1;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
          IF v_autoqf IS NULL THEN
            v_autoqf := 1;
          END IF;
          IF v_qfflag IS NULL THEN
            v_qfflag := 0;
          END IF;
          DELETE FROM info_register_obj WHERE objid = v_dept_id;
          v_id   := pkg_basic.f_newid('OG');
          v_sort := v_sort + v_i;
          INSERT INTO info_register_obj
            (id, objid, objname, objcode, islegal, digitalid, datatype, sort, kindid, kindidpath, fromtype, fromdate, status, autoqf, qfflag, operuri, opername)
          VALUES
            (v_id, v_dept_id, v_dept_nm, v_dept_code, v_islegal, v_digitalid, 1, v_sort, 'root', '/', 2, v_datatime_d, 1, v_autoqf, v_qfflag, 'system', 'system');
        
          IF mystring.f_isnotnull(v_dept_rs) THEN
            pkg_exch_to_site.p_ins(v_dept_id, v_dept_nm, 'QT10', v_dept_rs, o_code, o_msg);
            IF o_code <> 'EC00' THEN
              ROLLBACK;
              RETURN;
            END IF;
          END IF;
        ELSE
          v_fromdate := NULL;
          BEGIN
            SELECT t.fromdate
              INTO v_fromdate
              FROM info_register_obj t
             WHERE objid = v_dept_id
               AND rownum <= 1;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
          IF v_fromdate < v_datatime_d THEN
            DELETE FROM info_register_obj WHERE objid = v_dept_id;
          END IF;
        END IF;
      END IF;
    
      v_i := v_i + 1;
    END LOOP;
  
    -- 6.处理成功
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 绑定用户
  PROCEDURE p_user
  (
    i_info IN CLOB, -- 表单数据
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml   xmltype;
    v_i     INT := 0;
    v_xpath VARCHAR2(200);
  
    v_sort INT := 0;
    v_id   VARCHAR2(64);
  
    v_datatime   VARCHAR2(64);
    v_datatime_d DATE;
    v_fromdate   DATE;
  
    v_user_id     VARCHAR2(64); -- 港号
    v_user_nm     VARCHAR2(200); -- 名称
    v_user_code   VARCHAR2(64); -- 机构代码
    v_user_ver    INT; -- 版本号
    v_user_enable INT; -- 1-在用 0-停用/删除
    v_user_rs     VARCHAR2(4000); -- 路由信息
    v_islegal     INT;
    v_digitalid   VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_info', i_info);
  
    SELECT MAX(t.sort) INTO v_sort FROM info_register_obj t WHERE t.datatype = 0;
    IF v_sort IS NULL THEN
      v_sort := 0;
    END IF;
  
    -- 解析XML
    v_xml := xmltype(i_info);
  
    SELECT myxml.f_getvalue(v_xml, '/info/datatime') INTO v_datatime FROM dual;
  
    BEGIN
      v_datatime_d := to_date(v_datatime, 'yyyy-mm-dd hh24:mi:ss');
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_datatime_d IS NULL THEN
      v_datatime_d := SYSDATE;
    END IF;
  
    v_i := 1;
    WHILE v_i <= 9999 LOOP
      v_xpath := mystring.f_concat('/info/datas/user[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@id')) INTO v_user_id FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@nm')) INTO v_user_nm FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@code')) INTO v_user_code FROM dual;
      SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@ver')) INTO v_user_ver FROM dual;
      SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@enable')) INTO v_user_enable FROM dual;
      SELECT myxml.f_getnode_str(v_xml, mystring.f_concat(v_xpath, 'rs')) INTO v_user_rs FROM dual;
      SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@islegal')) INTO v_islegal FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@digitalid')) INTO v_digitalid FROM dual;
    
      IF v_islegal IS NULL THEN
        v_islegal := 1;
      END IF;
    
      IF mystring.f_isnull(v_user_id) THEN
        v_i := 9999;
      ELSE
        v_id := '';
        BEGIN
          SELECT t.id
            INTO v_id
            FROM info_register_obj t
           WHERE objid = v_user_id
             AND rownum <= 1;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      
        IF v_user_enable = 1 THEN
          DELETE FROM info_register_obj WHERE objid = v_user_id;
          v_id   := pkg_basic.f_newid('US');
          v_sort := v_sort + v_i;
          INSERT INTO info_register_obj
            (id, objid, objname, objcode, islegal, digitalid, sort, kindid, kindidpath, fromtype, fromdate, status, operuri, opername)
          VALUES
            (v_id, v_user_id, v_user_nm, v_user_code, v_islegal, v_digitalid, v_sort, 'root', '/', 2, v_datatime_d, 1, 'system', 'system');
        
          IF mystring.f_isnotnull(v_user_rs) THEN
            pkg_exch_to_site.p_ins(v_user_id, v_user_nm, 'QT10', v_user_rs, o_code, o_msg);
            IF o_code <> 'EC00' THEN
              ROLLBACK;
              RETURN;
            END IF;
          END IF;
        ELSE
          IF v_fromdate < v_datatime_d THEN
            DELETE FROM info_register_obj WHERE objid = v_user_id;
          END IF;
        END IF;
      END IF;
    
      v_i := v_i + 1;
    END LOOP;
  
    -- 6.处理成功
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_platform_er.p_objdel
  功能描述 : 删除单位、用户
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-07-27  唐金鑫  创建
  
   <info>
      <datatype>EVC_OBJDEL</datatype>
      <datatime>2023-01-14 12:58:02</datatime>
      <uri>E1025：对象标识</uri>
      <name>鄂尔多斯市泰坤科技有限公司</name>
      <utype>1单位、0个人</utype>      
      <exchid>原交换标识</exchid>
      <datatype2>原业务类型</datatype2>
    </info>
  ***************************************************************************************************/
  PROCEDURE p_objdel
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_datatime   VARCHAR2(64);
    v_datatime_d DATE;
    v_fromdate   DATE;
    v_uri        VARCHAR2(64);
    v_name       VARCHAR2(128);
    v_utype      VARCHAR2(8);
  BEGIN
    mydebug.wlog('i_forminfo', i_forminfo);
  
    -- 解析xml
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(i_forminfo);
      SELECT myxml.f_getvalue(v_xml, '/info/datatime') INTO v_datatime FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/uri') INTO v_uri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/name') INTO v_name FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/utype') INTO v_utype FROM dual;
    END;
  
    IF mystring.f_isnull(v_uri) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      v_datatime_d := to_date(v_datatime, 'yyyy-mm-dd hh24:mi:ss');
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_datatime_d IS NULL THEN
      v_datatime_d := SYSDATE;
    END IF;
  
    BEGIN
      SELECT t.fromdate
        INTO v_fromdate
        FROM info_register_obj t
       WHERE objid = v_uri
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF v_fromdate < v_datatime_d THEN
      DELETE FROM info_register_obj WHERE objid = v_uri;
    END IF;
  
    COMMIT;
  
    -- 6.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
