CREATE OR REPLACE PACKAGE pkg_exch_to_site IS

  /***************************************************************************************************
  名称     : pkg_exch_to_site
  功能描述 : 交换-接收者交换箱信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2021-04-14  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 检查接收者路由信息是否存在(1:是 0:否)
  FUNCTION f_check(i_objuri VARCHAR2) RETURN INT;

  -- 查询站点ID
  FUNCTION f_getsiteid(i_objuri VARCHAR2) RETURN VARCHAR2;

  -- 查询本系统上级站点ID
  FUNCTION f_getmysiteid(i_objuri VARCHAR2) RETURN VARCHAR2;

  -- 查询站点地址
  FUNCTION f_getshost(i_objuri VARCHAR2) RETURN VARCHAR2;

  -- 存储接收者信息
  PROCEDURE p_ins
  (
    i_objuri  IN VARCHAR2, -- 对象标识
    i_objname IN VARCHAR2, -- 对象名称
    i_objtype IN VARCHAR2, -- 对象类型
    i_route   IN VARCHAR2, -- 接收者路由信息
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  );

  -- 存储接收者信息(反向路由)
  PROCEDURE p_ins2
  (
    i_objuri     IN VARCHAR2, -- 对象标识
    i_objname    IN VARCHAR2, -- 对象名称
    i_objtype    IN VARCHAR2, -- 对象类型
    i_exchstatus IN CLOB, -- 交换状态
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_exch_to_site IS

  -- 检查接收者路由信息是否存在(1:是 0:否)
  FUNCTION f_check(i_objuri VARCHAR2) RETURN INT AS
    v_exists INT := 0;
  BEGIN
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_exch_to_info t WHERE t.objuri = i_objuri);
    RETURN v_exists;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 查询站点ID
  FUNCTION f_getsiteid(i_objuri VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(64);
  BEGIN
    SELECT t.siteid INTO v_result FROM data_exch_to_info t WHERE t.objuri = i_objuri;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询本系统上级站点ID
  FUNCTION f_getmysiteid(i_objuri VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(64);
  BEGIN
    SELECT t.mysiteid INTO v_result FROM data_exch_to_info t WHERE t.objuri = i_objuri;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询站点地址
  FUNCTION f_getshost(i_objuri VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(200);
  BEGIN
    SELECT t.shost INTO v_result FROM data_exch_to_info t WHERE t.objuri = i_objuri;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  /***************************************************************************************************
  名称     : pkg_exch_to_site.p_ins
  功能描述 : 存储接收者信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2021-04-14  唐金鑫  创建
  <rs>
    <r id="接收方ID fail="1-失败" msg="失败原因" >
      <n id="发起系统港号"  nm="发起系统名称" hs="地址" />
      <n id="交换节点标识"  nm="交换节点名称" hs="地址" area="机房标识" lan="内网地址"/>
      <n id="目的系统港号"  nm="目的系统名称" hs="地址" />
    </r>
  </rs>  
  ***************************************************************************************************/
  PROCEDURE p_ins
  (
    i_objuri  IN VARCHAR2, -- 对象标识
    i_objname IN VARCHAR2, -- 对象名称
    i_objtype IN VARCHAR2, -- 对象类型
    i_route   IN VARCHAR2, -- 接收者路由信息
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(200);
    v_suri     VARCHAR2(64);
    v_sname    VARCHAR2(64);
    v_shost    VARCHAR2(128);
    v_lan      VARCHAR2(128);
    v_area     VARCHAR2(128);
    v_mysiteid VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_route', i_route);
  
    IF mystring.f_isnull(i_objuri) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_route) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 解析xml
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(i_route);
      SELECT myxml.f_getvalue(v_xml, '/rs/r/n[4]/@id') INTO v_siteid FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/rs/r/n[4]/@nm') INTO v_sitename FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/rs/r/n[2]/@id') INTO v_mysiteid FROM dual;
      IF mystring.f_isnull(v_siteid) THEN
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[3]/@id') INTO v_siteid FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[3]/@nm') INTO v_sitename FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[2]/@id') INTO v_suri FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[2]/@nm') INTO v_sname FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[2]/@hs') INTO v_shost FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[2]/@lan') INTO v_lan FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[2]/@area') INTO v_area FROM dual;
      ELSE
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[3]/@id') INTO v_suri FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[3]/@nm') INTO v_sname FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[3]/@hs') INTO v_shost FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[3]/@lan') INTO v_lan FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/rs/r/n[3]/@area') INTO v_area FROM dual;
      END IF;
    END;
  
    IF mystring.f_isnull(v_siteid) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_suri) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_mysiteid) THEN
      v_mysiteid := pkg_exch_mysite.f_getid;
      pkg_exch_mysite.p_getsite2(v_mysiteid, v_suri, v_sname, v_shost, v_lan, v_area);
    END IF;
  
    DELETE FROM data_exch_to_info WHERE objuri = i_objuri;
    INSERT INTO data_exch_to_info
      (objuri, objname, objtype, siteid, sitename, suri, sname, shost, lan, area, mysiteid, fromtype)
    VALUES
      (i_objuri, i_objname, i_objtype, v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area, v_mysiteid, '1');
  
    -- 8.处理成功
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
  名称     : pkg_exch_to_site.p_ins2
  功能描述 : 存储接收者信息(反向路由)
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2021-04-14  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_ins2
  (
    i_objuri     IN VARCHAR2, -- 对象标识
    i_objname    IN VARCHAR2, -- 对象名称
    i_objtype    IN VARCHAR2, -- 对象类型
    i_exchstatus IN CLOB, -- 交换状态
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists   INT := 0;
    v_siteid   VARCHAR2(64);
    v_sitename VARCHAR2(200);
    v_suri     VARCHAR2(64);
    v_sname    VARCHAR2(64);
    v_shost    VARCHAR2(128);
    v_lan      VARCHAR2(128);
    v_area     VARCHAR2(128);
    v_mysiteid VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_objuri', i_objuri);
    mydebug.wlog('i_objtype', i_objtype);
    mydebug.wlog('i_exchstatus', i_exchstatus);
  
    IF mystring.f_isnull(i_objuri) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_exchstatus) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT COUNT(1)
        INTO v_exists
        FROM data_exch_to_info t
       WHERE t.objuri = i_objuri
         AND t.fromtype = '1'
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_exists = 1 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 解析xml
    DECLARE
      v_xml      xmltype;
      v_uri_last VARCHAR2(64);
    BEGIN
      v_xml := xmltype(i_exchstatus);
    
      SELECT myxml.f_getvalue(v_xml, '/status/site[1]/@uri') INTO v_siteid FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/site[1]/@name') INTO v_sitename FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/site[2]/@uri') INTO v_suri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/site[2]/@name') INTO v_sname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/site[2]/@host') INTO v_shost FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/site[2]/@lan') INTO v_lan FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/site[2]/@area') INTO v_area FROM dual;
    
      SELECT myxml.f_getvalue(v_xml, '/status/site[4]/@uri') INTO v_uri_last FROM dual;
      IF mystring.f_isnull(v_uri_last) THEN
        v_mysiteid := v_suri;
      ELSE
        SELECT myxml.f_getvalue(v_xml, '/status/site[3]/@uri') INTO v_mysiteid FROM dual;
      END IF;
    END;
  
    IF mystring.f_isnull(v_siteid) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_suri) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_mysiteid) THEN
      v_mysiteid := pkg_exch_mysite.f_getid;
      pkg_exch_mysite.p_getsite2(v_mysiteid, v_suri, v_sname, v_shost, v_lan, v_area);
    END IF;
  
    DELETE FROM data_exch_to_info WHERE objuri = i_objuri;
    INSERT INTO data_exch_to_info
      (objuri, objname, objtype, siteid, sitename, suri, sname, shost, lan, area, mysiteid, fromtype)
    VALUES
      (i_objuri, i_objname, i_objtype, v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area, v_mysiteid, '2');
  
    -- 8.处理成功
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
