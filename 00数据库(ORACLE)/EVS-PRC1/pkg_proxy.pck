CREATE OR REPLACE PACKAGE pkg_proxy IS

  /***************************************************************************************************
  名称     : pkg_proxy
  功能描述 : 接收TDS推送过来的数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-10  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 通过交换接收代理
  PROCEDURE p_receive
  (
    i_info IN CLOB, -- 表单数据
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 获取业务代理列表
  PROCEDURE p_getproxy
  (
    o_info    OUT CLOB, -- 查询返回的结果
    o_dataidx OUT VARCHAR2, -- 返回版本号
    o_cfgidx  OUT VARCHAR2, -- 系统配置版本号
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_proxy IS

  -- 通过交换接收代理
  PROCEDURE p_receive
  (
    i_info IN CLOB, -- 表单数据
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml   xmltype;
    v_i     INT := 0;
    v_xpath VARCHAR2(200);
  
    v_ver_old INT := 0;
  
    v_siteid VARCHAR2(64);
    v_sitenm VARCHAR2(200);
    v_url    VARCHAR2(64);
    v_port   VARCHAR2(64);
    v_inlan  VARCHAR2(64);
    v_type   VARCHAR2(8); -- 代理地址类型(out:外网 in:内网)
  
    v_appuri VARCHAR2(64);
    v_ver    INT;
  
  BEGIN
    mydebug.wlog('i_info', i_info);
  
    -- 解析XML
    v_xml := xmltype(i_info);
    SELECT myxml.f_getvalue(v_xml, '/info/datas/@appuri') INTO v_appuri FROM dual;
    SELECT myxml.f_getint(v_xml, '/info/datas/@ver') INTO v_ver FROM dual;
  
    IF v_ver IS NULL THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT MAX(t.ver) INTO v_ver_old FROM info_proxy t;
    IF v_ver_old IS NULL THEN
      v_ver_old := 0;
    END IF;
    IF v_ver_old > v_ver THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    DELETE FROM info_proxy;
  
    v_i := 1;
    WHILE v_i <= 100 LOOP
      v_xpath := mystring.f_concat('/info/datas/data[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@siteid')) INTO v_siteid FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@sitenm')) INTO v_sitenm FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@url')) INTO v_url FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@port')) INTO v_port FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@inlan')) INTO v_inlan FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@type')) INTO v_type FROM dual;
    
      IF mystring.f_isnull(v_siteid) THEN
        v_i := 100;
      ELSE
        INSERT INTO info_proxy (siteid, sitenm, url, port, inlan, iptype, ver) VALUES (v_siteid, v_sitenm, v_url, v_port, v_inlan, v_type, v_ver);
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

  -- 获取业务代理列表
  PROCEDURE p_getproxy
  (
    o_info    OUT CLOB, -- 查询返回的结果
    o_dataidx OUT VARCHAR2, -- 返回版本号
    o_cfgidx  OUT VARCHAR2, -- 系统配置版本号
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_idx    INT := 0;
    v_url    VARCHAR2(128);
    v_port   VARCHAR2(128);
    v_inlan  VARCHAR2(128);
    v_iptype VARCHAR2(8);
    v_info   VARCHAR2(4000);
  BEGIN
    o_cfgidx := pkg_basic.f_getconfig2('cfgidx');
    IF mystring.f_isnull(o_cfgidx) THEN
      o_cfgidx := '0';
    END IF;
  
    SELECT MAX(t.ver) INTO o_dataidx FROM info_proxy t;
    IF mystring.f_isnull(o_dataidx) THEN
      o_dataidx := '0';
    END IF;
  
    v_info := '<param>';
    v_info := mystring.f_concat(v_info, '<proxy>');
    DECLARE
      CURSOR v_cursor IS
        SELECT t.iptype, t.inlan, t.url, t.port FROM info_proxy t;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_iptype, v_inlan, v_url, v_port;
        EXIT WHEN v_cursor%NOTFOUND;
        v_idx := v_idx + 1;
        IF v_iptype = 'in' THEN
          v_info := mystring.f_concat(v_info, '<item challenge="3">', v_inlan, '</item>');
        ELSE
          v_info := mystring.f_concat(v_info, '<item challenge="3">', v_url, ':', v_port, '</item>');
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
  
    v_info := mystring.f_concat(v_info, '</proxy>');
    v_info := mystring.f_concat(v_info, '</param>');
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, v_info);
    -- mydebug.wlog('o_info', o_info);
    -- mydebug.wlog('o_dataidx', o_dataidx);
    -- mydebug.wlog('o_cfgidx', o_cfgidx);
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
