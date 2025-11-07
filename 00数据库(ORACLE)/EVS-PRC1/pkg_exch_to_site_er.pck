CREATE OR REPLACE PACKAGE pkg_exch_to_site_er IS

  /***************************************************************************************************
  名称     : pkg_exch_to_site_er
  功能描述 : 接收空间推送过来的新路由
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-16  唐金鑫  创建
  
  业务说明
  单位、个人更换空间后，新空间会将单位、个人的新路由推送给凭证印制易
  <info>
      <datatype>EVC_TURNS</datatype>
      <datatime>2023-02-25 16:03:19</datatime>
      <uri>P0158</uri>
      <name>杨志成</name>
      <utype>0</utype>
      <exchid>F5C477A6997ECBFDE050007F010055A6</exchid>
      <datatype2>GG11</datatype2>
      <sys id="UI202105281443193164775196@ggy.zg" nm="专用数字空间1" ver="4">
          <proxy id="ggy.zg_15292771" ip="103.39.220.252" port="9005"/>
          <proxy id="ggy.zg_88191684" ip="103.39.220.251" port="9005"/>
          <site id="UI202105281443193164775196@ggy.zg" name="专用数字空间1" siteid="XU20211000000000132870" sitename="专用数字空间1" pid="BK20181000000000030830" pnm="枢纽站H005" host="103.44.239.47:9000" lan="192.168.105.4:9000" area="SZ"/>
      </sys>
  </info>
  
  ***************************************************************************************************/

  -- 接收新路由
  PROCEDURE p_receive
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_exch_to_site_er IS

  -- 接收新路由
  PROCEDURE p_receive
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_datatime_txt VARCHAR2(64);
    v_datatime     DATE;
    v_objuri       VARCHAR2(64);
    v_objname      VARCHAR2(128);
    v_siteid       VARCHAR2(64);
    v_sitename     VARCHAR2(200);
    v_suri         VARCHAR2(64);
    v_sname        VARCHAR2(64);
    v_shost        VARCHAR2(128);
    v_lan          VARCHAR2(128);
    v_area         VARCHAR2(128);
    v_mysiteid     VARCHAR2(64);
    v_createddate  DATE;
  BEGIN
    mydebug.wlog('i_forminfo', i_forminfo);
  
    -- 解析xml
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(i_forminfo);
      SELECT myxml.f_getvalue(v_xml, '/info/datatime') INTO v_datatime_txt FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/uri') INTO v_objuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/name') INTO v_objname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/sys/site/@siteid') INTO v_siteid FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/sys/site/@sitename') INTO v_sitename FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/sys/site/@pid') INTO v_suri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/sys/site/@pnm') INTO v_sname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/sys/site/@host') INTO v_shost FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/sys/site/@lan') INTO v_lan FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/sys/site/@area') INTO v_area FROM dual;
    END;
  
    IF mystring.f_isnull(v_datatime_txt) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      v_datatime := to_date(v_datatime_txt, 'yyyy-mm-dd hh24:mi:ss');
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF v_datatime IS NULL THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_objuri) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
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
  
    IF mystring.f_isnull(v_shost) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT t.createddate
        INTO v_createddate
        FROM data_exch_to_info t
       WHERE t.objuri = v_objuri
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_createddate IS NOT NULL THEN
      IF v_createddate > v_datatime THEN
        o_code := 'EC00';
        o_msg  := '处理成功';
        mydebug.wlog(1, o_code, o_msg);
        RETURN;
      END IF;
    END IF;
  
    v_mysiteid := pkg_exch_mysite.f_getid;
  
    DELETE FROM data_exch_to_info WHERE objuri = v_objuri;
    INSERT INTO data_exch_to_info
      (objuri, objname, objtype, siteid, sitename, suri, sname, shost, lan, area, mysiteid, fromtype, createddate)
    VALUES
      (v_objuri, v_objname, 'QT10', v_siteid, v_sitename, v_suri, v_sname, v_shost, v_lan, v_area, v_mysiteid, '1', v_datatime);
  
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
