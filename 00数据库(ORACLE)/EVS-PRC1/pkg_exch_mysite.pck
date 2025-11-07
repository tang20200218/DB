CREATE OR REPLACE PACKAGE pkg_exch_mysite IS

  /***************************************************************************************************
  名称     : pkg_exch_mysite
  功能描述 : 本系统集成交换连接的上级站点
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-07  唐金鑫  创建
  
  <datas appuri="系统标识" ver="当前最大版本号">
    <data
      siteid="站点ID"
      sitenm="站点名称"
      url="站点地址"
      port="端口"
      inlan="内网地址"
      area="站点机房代码"
      type="0-设备与设备间交换 4-平台与设备间交换"/>
  </datas>
  
  <info>
      <operuid>P0159</operuid>
      <operunm>唐金鑫</operunm>
      <datatype>site</datatype>
      <datatime>2023-02-07 17:04:47</datatime>
      <datas appuri="MI202105151544021494562167@ggy.zg" ver="1">
          <data siteid="RK21060104035300000511" sitenm="目录业务数据共享枢纽B111" url="103.44.239.63" port="9000" inlan="192.168.105.63:9000" area="SZ" type="4"/>
          <data siteid="RK21060104025000000510" sitenm="目录业务数据共享枢纽B110" url="103.44.239.60" port="9000" inlan="192.168.105.60:9000" area="SZ" type="4"/>
          <data siteid="BK20171000000000000060" sitenm="枢纽站H002" url="103.44.239.44" port="9000" inlan="192.168.105.23:9000" area="SZ" type="0"/>
          <data siteid="BK20171000000000000059" sitenm="枢纽站H001" url="103.44.239.55" port="9000" inlan="192.168.105.12:9000" area="SZ" type="0"/>
      </datas>
  </info>
  ***************************************************************************************************/

  -- 随机获取一个上级站点ID
  FUNCTION f_getid RETURN VARCHAR2;

  -- 系统注册时存储站点信息
  PROCEDURE p_config
  (
    i_info IN VARCHAR2, -- 表单数据
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 通过交换接收站点信息
  PROCEDURE p_receive
  (
    i_info IN CLOB, -- 表单数据
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询本系统集成交换连接的上级站点
  PROCEDURE p_get
  (
    o_info OUT VARCHAR2, -- 返回信息
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询本系统站点信息
  PROCEDURE p_getsite
  (
    i_siteid   IN VARCHAR2,
    o_siteid   OUT VARCHAR2,
    o_sitename OUT VARCHAR2,
    o_suri     OUT VARCHAR2,
    o_sname    OUT VARCHAR2,
    o_shost    OUT VARCHAR2,
    o_lan      OUT VARCHAR2,
    o_area     OUT VARCHAR2
  );

  -- 查询本系统站点信息
  PROCEDURE p_getsite2
  (
    i_siteid IN VARCHAR2,
    o_suri   OUT VARCHAR2,
    o_sname  OUT VARCHAR2,
    o_shost  OUT VARCHAR2,
    o_lan    OUT VARCHAR2,
    o_area   OUT VARCHAR2
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_exch_mysite IS

  -- 随机获取一个上级站点ID
  FUNCTION f_getid RETURN VARCHAR2 AS
    v_count  INT := 0;
    v_result VARCHAR2(64);
  BEGIN
    SELECT COUNT(1) INTO v_count FROM data_exch_mysite t WHERE t.sitetype = '0';
    IF v_count = 1 THEN
      SELECT t.siteid
        INTO v_result
        FROM data_exch_mysite t
       WHERE t.sitetype = '0'
         AND rownum <= 1;
      RETURN v_result;
    END IF;
  
    IF v_count > 0 THEN
      SELECT siteid INTO v_result FROM (SELECT t.siteid FROM data_exch_mysite t WHERE t.sitetype = '0' ORDER BY dbms_random.value()) q WHERE rownum <= 1;
      RETURN v_result;
    END IF;
  
    SELECT COUNT(1) INTO v_count FROM data_exch_mysite t;
    IF v_count = 0 THEN
      RETURN '';
    END IF;
  
    SELECT t.siteid INTO v_result FROM data_exch_mysite t WHERE rownum <= 1;
    IF v_count = 1 THEN
      RETURN v_result;
    END IF;
  
    SELECT siteid INTO v_result FROM (SELECT t.siteid FROM data_exch_mysite t ORDER BY dbms_random.value()) q WHERE rownum <= 1;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 系统注册时存储站点信息
  PROCEDURE p_config
  (
    i_info IN VARCHAR2, -- 表单数据
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml   xmltype;
    v_i     INT := 0;
    v_xpath VARCHAR2(200);
  
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(200);
    v_url      VARCHAR2(64);
    v_port     VARCHAR2(32);
    v_inlan    VARCHAR2(128);
    v_area     VARCHAR2(128);
    v_sitetype VARCHAR2(64);
    v_ver      INT := 0;
    v_ver_old  INT := 0;
  BEGIN
    mydebug.wlog('i_info', i_info);
  
    BEGIN
      SELECT MAX(t.ver) INTO v_ver_old FROM data_exch_mysite t;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_ver_old IS NULL THEN
      v_ver_old := 0;
    END IF;
  
    v_xml := xmltype(i_info);
    SELECT myxml.f_getint(v_xml, '/datas/@ver') INTO v_ver FROM dual;
  
    IF v_ver_old > v_ver THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    DELETE FROM data_exch_mysite;
  
    v_i := 1;
    WHILE v_i <= 100 LOOP
      v_xpath := mystring.f_concat('/datas/data[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@siteid')) INTO v_siteid FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@sitenm')) INTO v_sitename FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@url')) INTO v_url FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@port')) INTO v_port FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@inlan')) INTO v_inlan FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@area')) INTO v_area FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@type')) INTO v_sitetype FROM dual;
      IF mystring.f_isnull(v_siteid) THEN
        v_i := 100;
      ELSE
        INSERT INTO data_exch_mysite (siteid, sitename, url, port, inlan, area, sitetype, ver) VALUES (v_siteid, v_sitename, v_url, v_port, v_inlan, v_area, v_sitetype, v_ver);
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

  -- 通过交换接收站点信息
  PROCEDURE p_receive
  (
    i_info IN CLOB, -- 表单数据
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml   xmltype;
    v_i     INT := 0;
    v_xpath VARCHAR2(200);
  
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(200);
    v_url      VARCHAR2(64);
    v_port     VARCHAR2(32);
    v_inlan    VARCHAR2(128);
    v_area     VARCHAR2(128);
    v_sitetype VARCHAR2(64);
    v_ver      INT := 0;
    v_ver_old  INT := 0;
  BEGIN
    mydebug.wlog('i_info', i_info);
  
    BEGIN
      SELECT MAX(t.ver) INTO v_ver_old FROM data_exch_mysite t;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_ver_old IS NULL THEN
      v_ver_old := 0;
    END IF;
  
    v_xml := xmltype(i_info);
    SELECT myxml.f_getint(v_xml, '/info/datas/@ver') INTO v_ver FROM dual;
  
    IF v_ver_old > v_ver THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    DELETE FROM data_exch_mysite;
  
    v_i := 1;
    WHILE v_i <= 100 LOOP
      v_xpath := mystring.f_concat('/info/datas/data[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@siteid')) INTO v_siteid FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@sitenm')) INTO v_sitename FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@url')) INTO v_url FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@port')) INTO v_port FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@inlan')) INTO v_inlan FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@area')) INTO v_area FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@type')) INTO v_sitetype FROM dual;
      IF mystring.f_isnull(v_siteid) THEN
        v_i := 100;
      ELSE
        INSERT INTO data_exch_mysite (siteid, sitename, url, port, inlan, area, sitetype, ver) VALUES (v_siteid, v_sitename, v_url, v_port, v_inlan, v_area, v_sitetype, v_ver);
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
  名称     : pkg_exch_mysite.p_get
  功能描述 : 查询本系统集成交换连接的上级站点
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-07  唐金鑫  创建
  
  <rows>
    <row 
      siteid="站点ID"
      sitenm="站点名称"
      url="站点地址"
      port="端口"
      inlan="内网地址"
      area="站点机房代码"
      type="0-设备与设备间交换 4-平台与设备间交换"
    />
  </rows>
  ***************************************************************************************************/
  PROCEDURE p_get
  (
    o_info OUT VARCHAR2, -- 返回信息
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(200);
    v_url      VARCHAR2(64);
    v_port     VARCHAR2(32);
    v_inlan    VARCHAR2(128);
    v_area     VARCHAR2(128);
    v_sitetype VARCHAR2(64);
  BEGIN
    o_info := '<rows>';
    DECLARE
      CURSOR v_cursor IS
        SELECT t.siteid, t.sitename, t.url, t.port, t.inlan, t.area, t.sitetype FROM data_exch_mysite t ORDER BY t.siteid;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_siteid, v_sitename, v_url, v_port, v_inlan, v_area, v_sitetype;
        EXIT WHEN v_cursor%NOTFOUND;
        o_info := mystring.f_concat(o_info, '<row');
        o_info := mystring.f_concat(o_info, ' siteid="', v_siteid, '"');
        o_info := mystring.f_concat(o_info, ' sitenm="', v_sitename, '"');
        o_info := mystring.f_concat(o_info, ' url="', v_url, '"');
        o_info := mystring.f_concat(o_info, ' port="', v_port, '"');
        o_info := mystring.f_concat(o_info, ' inlan="', v_inlan, '"');
        o_info := mystring.f_concat(o_info, ' area="', v_area, '"');
        o_info := mystring.f_concat(o_info, ' type="', v_sitetype, '"');
        o_info := mystring.f_concat(o_info, ' />');
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
    o_info := mystring.f_concat(o_info, '</rows>');
  
    -- mydebug.wlog('o_info', o_info);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 查询本系统站点信息
  PROCEDURE p_getsite
  (
    i_siteid   IN VARCHAR2,
    o_siteid   OUT VARCHAR2,
    o_sitename OUT VARCHAR2,
    o_suri     OUT VARCHAR2,
    o_sname    OUT VARCHAR2,
    o_shost    OUT VARCHAR2,
    o_lan      OUT VARCHAR2,
    o_area     OUT VARCHAR2
  ) AS
    v_url  VARCHAR2(64);
    v_port VARCHAR2(32);
  BEGIN
    SELECT t.siteid, t.sitename, t.url, t.port, t.inlan, t.area INTO o_suri, o_sname, v_url, v_port, o_lan, o_area FROM data_exch_mysite t WHERE t.siteid = i_siteid;
    o_shost    := mystring.f_concat(v_url, ':', v_port);
    o_siteid   := pkg_basic.f_getconfig('cf15');
    o_sitename := pkg_basic.f_getconfig('cf01');
  EXCEPTION
    WHEN OTHERS THEN
      mydebug.err(7);
  END;

  -- 查询本系统站点信息
  PROCEDURE p_getsite2
  (
    i_siteid IN VARCHAR2,
    o_suri   OUT VARCHAR2,
    o_sname  OUT VARCHAR2,
    o_shost  OUT VARCHAR2,
    o_lan    OUT VARCHAR2,
    o_area   OUT VARCHAR2
  ) AS
    v_url  VARCHAR2(64);
    v_port VARCHAR2(32);
  BEGIN
    SELECT t.siteid, t.sitename, t.url, t.port, t.inlan, t.area INTO o_suri, o_sname, v_url, v_port, o_lan, o_area FROM data_exch_mysite t WHERE t.siteid = i_siteid;
    o_shost := mystring.f_concat(v_url, ':', v_port);
  EXCEPTION
    WHEN OTHERS THEN
      mydebug.err(7);
  END;
END;
/
