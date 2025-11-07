CREATE OR REPLACE PACKAGE pkg_qf2_er IS

  /***************************************************************************************************
  名称     : pkg_qf2_er
  功能描述 : 入账凭证签发
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-06  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 接收入账凭证签发申请
  PROCEDURE p_add
  (
    i_exchid   IN VARCHAR2, -- 交换ID
    i_forminfo IN CLOB, -- 表单信息
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END pkg_qf2_er;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf2_er IS

  /***************************************************************************************************
  名称     : pkg_qf2_er.p_add
  功能描述 : 接收入账凭证签发申请
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-10  唐金鑫  创建
  
  ***************************************************************************************************/
  PROCEDURE p_add
  (
    i_exchid   IN VARCHAR2, -- 交换ID
    i_forminfo IN CLOB, -- 表单信息
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml       xmltype;
    v_exists    INT := 0;
    v_id        VARCHAR2(64);
    v_autoqf    INT;
    v_startflag INT := 0;
  
    v_info_datatime     VARCHAR2(64);
    v_info_datatime_d   DATE;
    v_info_fromtype     VARCHAR2(8);
    v_info_fromuri      VARCHAR2(64);
    v_info_fromname     VARCHAR2(128);
    v_info_certsn       VARCHAR2(128);
    v_info_id           VARCHAR2(64);
    v_info_title        VARCHAR2(200);
    v_info_dtype        VARCHAR2(64);
    v_info_pickusage    VARCHAR2(512);
    v_info_printedparam VARCHAR2(32767);
    v_info_operuri      VARCHAR2(64);
    v_info_opername     VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
  
    -- 解析表单数据
    BEGIN
      v_xml := xmltype(i_forminfo);
      SELECT myxml.f_getvalue(v_xml, '/info/datatime') INTO v_info_datatime FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromtype') INTO v_info_fromtype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromuri') INTO v_info_fromuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromname') INTO v_info_fromname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/certsn') INTO v_info_certsn FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/id') INTO v_info_id FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/title') INTO v_info_title FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/dtype') INTO v_info_dtype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/pickusage') INTO v_info_pickusage FROM dual;
      SELECT myxml.f_getnode_str(v_xml, '/info/printedparam/data/section') INTO v_info_printedparam FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/operuri') INTO v_info_operuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/opername') INTO v_info_opername FROM dual;
    END;
  
    SELECT COUNT(1) INTO v_exists FROM info_template t WHERE t.tempid = v_info_dtype;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM info_register_obj t WHERE t.objid = v_info_fromuri;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT autoqf INTO v_autoqf FROM info_register_obj t WHERE t.objid = v_info_fromuri;
    IF v_autoqf = 1 THEN
      v_startflag := 1;
    END IF;
  
    BEGIN
      v_info_datatime_d := to_date(v_info_datatime, 'yyyy-mm-dd hh24:mi:ss');
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_info_datatime_d IS NULL THEN
      v_info_datatime_d := SYSDATE;
    END IF;
  
    v_id := pkg_basic.f_newid('TK');
  
    INSERT INTO data_qf2_applyinfo
      (id, title, dtype, fromtype, fromuri, fromname, certsn, fromid, fromdate, pickusage, printedparam, operuri, opername, exchid)
    VALUES
      (v_id,
       v_info_title,
       v_info_dtype,
       v_info_fromtype,
       v_info_fromuri,
       v_info_fromname,
       v_info_certsn,
       v_info_id,
       v_info_datatime_d,
       v_info_pickusage,
       v_info_printedparam,
       v_info_operuri,
       v_info_opername,
       i_exchid);
  
    INSERT INTO data_qf2_task
      (id, dtype, title, otype, douri, doname, docode, fromdate, fromoperuri, fromopername, autoqf, startflag, booktype)
    VALUES
      (v_id, v_info_dtype, v_info_title, v_info_fromtype, v_info_fromuri, v_info_fromname, v_info_certsn, SYSDATE, v_info_operuri, v_info_opername, v_autoqf, v_startflag, '2');
  
    UPDATE info_register_obj t SET t.qfflag = 1 WHERE t.objid = v_info_fromuri;
  
    COMMIT;
    -- 5.返回结果
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(3);
  END;

END pkg_qf2_er;
/
