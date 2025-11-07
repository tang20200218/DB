CREATE OR REPLACE PACKAGE pkg_yz_sq_er IS

  /***************************************************************************************************
  名称     : pkg_yz_sq_er
  功能描述 : 印制-凭证申领签发办理-通过交换接收数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-30  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  -- 接收申请信息
  PROCEDURE p_add
  (
    i_exchid     IN VARCHAR2, -- 交换标识
    i_exchstatus IN CLOB, -- 交换路由
    i_forminfo   IN CLOB, -- 表单数据
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除申请信息
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_yz_sq_er IS

  -- 接收申请信息
  PROCEDURE p_add
  (
    i_exchid     IN VARCHAR2, -- 交换标识
    i_exchstatus IN CLOB, -- 交换路由
    i_forminfo   IN CLOB, -- 表单数据
    o_code       OUT VARCHAR2, -- 操作结果:错误码
    o_msg        OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT := 0;
  
    v_id       VARCHAR2(64);
    v_booktime DATE;
  
    v_datatype2 VARCHAR2(64);
    v_pdocid    VARCHAR2(64);
    v_dtype     VARCHAR2(64);
    v_dtypename VARCHAR2(128);
    v_reqnum    INTEGER;
    v_fromtype  INTEGER;
    v_fromuri   VARCHAR2(64);
    v_fromname  VARCHAR2(128);
    v_appuri    VARCHAR2(64);
    v_appname   VARCHAR2(128);
    v_qfsuri    VARCHAR2(64);
    v_qfsname   VARCHAR2(128);
    v_sendtime  VARCHAR2(64);
    v_linkusr   VARCHAR2(64);
    v_linktel   VARCHAR2(64);
    v_operuri   VARCHAR2(64);
    v_opername  VARCHAR2(64);
    v_items     VARCHAR2(4000);
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
    mydebug.wlog('i_forminfo', i_forminfo);
  
    -- 解析表单数据
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(i_forminfo);
      SELECT myxml.f_getvalue(v_xml, '/info/datatype2') INTO v_datatype2 FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/docid') INTO v_pdocid FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/dtype') INTO v_dtype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/dtypename') INTO v_dtypename FROM dual;
      SELECT myxml.f_getint(v_xml, '/info/reqnum') INTO v_reqnum FROM dual;
      SELECT myxml.f_getint(v_xml, '/info/fromtype') INTO v_fromtype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromuri') INTO v_fromuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromname') INTO v_fromname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/appuri') INTO v_appuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/appname') INTO v_appname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/qfsuri') INTO v_qfsuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/qfsname') INTO v_qfsname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/sendtime') INTO v_sendtime FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/linkusr') INTO v_linkusr FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/linktel') INTO v_linktel FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/operuri') INTO v_operuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/opername') INTO v_opername FROM dual;
      SELECT myxml.f_getnode_str(v_xml, '/info/items') INTO v_items FROM dual;
    END;
  
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_yz_sq_book t WHERE t.pdocid = v_pdocid);
    IF v_exists > 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    v_id := pkg_basic.f_newid('SQ');
  
    IF v_reqnum IS NULL THEN
      v_reqnum := 0;
    END IF;
    IF v_fromtype IS NULL THEN
      v_fromtype := 0;
    END IF;
  
    v_linktel  := mycrypt.f_encrypt(v_linktel);
    v_booktime := to_date(v_sendtime, 'yyyy-mm-dd hh24:mi:ss');
  
    INSERT INTO data_yz_sq_book
      (docid, dtype, status, booknum, fromuri, fromname, fromtype, datatype2, appuri, appname, linkusr, linktel, booktime, bookuri, bookname, pdocid, items, exchid)
    VALUES
      (v_id,
       v_dtype,
       'VSB1',
       v_reqnum,
       v_fromuri,
       v_fromname,
       v_fromtype,
       v_datatype2,
       v_appuri,
       v_appname,
       v_linkusr,
       v_linktel,
       v_booktime,
       v_operuri,
       v_opername,
       v_pdocid,
       v_items,
       i_exchid);
  
    -- 存储反向路由
    IF v_fromtype = 0 THEN
      pkg_exch_to_site.p_ins2(v_fromuri, v_fromname, 'QT10', i_exchstatus, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    ELSIF v_fromtype = 9 THEN
      pkg_exch_to_site.p_ins2(v_appuri, v_appname, 'QT13', i_exchstatus, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    ELSE
      pkg_exch_to_site.p_ins2(v_appuri, v_appname, 'QT12', i_exchstatus, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    -- 自动分发
    DECLARE
      v_yzfftype INT := 0;
    BEGIN
      BEGIN
        SELECT yzfftype INTO v_yzfftype FROM info_template t WHERE t.tempid = v_dtype;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      IF v_yzfftype = 1 THEN
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_yz_sq_com t
                 WHERE t.dtype = v_dtype
                   AND t.sqcomid = v_fromuri);
        IF v_exists > 0 THEN
          -- 设置在分配
          UPDATE data_yz_sq_book t SET t.respnum = t.booknum, t.status = 'VSB3', t.modifieddate = SYSDATE, t.operuri = 'system', t.opername = 'system' WHERE t.docid = v_id;
        
          -- 增加自动分发队列
          pkg_yz_sq_reply_queue1.p_add(v_id, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        END IF;
      END IF;
    END;
  
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

  -- 删除申请信息
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists   INT := 0;
    v_docid    VARCHAR2(64);
    v_pdocid   VARCHAR2(64);
    v_fromuri  VARCHAR2(64);
    v_fromname VARCHAR2(128);
    v_appuri   VARCHAR2(64);
    v_appname  VARCHAR2(128);
    v_operuri  VARCHAR2(64);
    v_opername VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_forminfo', i_forminfo);
  
    -- 解析表单数据
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(i_forminfo);
      SELECT myxml.f_getvalue(v_xml, '/info/docid') INTO v_pdocid FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromuri') INTO v_fromuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/fromname') INTO v_fromname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/appuri') INTO v_appuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/appname') INTO v_appname FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/operuri') INTO v_operuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/opername') INTO v_opername FROM dual;
    END;
  
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_yz_sq_book t WHERE t.pdocid = v_pdocid);
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT t.docid
        INTO v_docid
        FROM data_yz_sq_book t
       WHERE t.pdocid = v_pdocid
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    DELETE FROM data_yz_sq_book WHERE docid = v_docid;
    DELETE FROM data_yz_sq_reply_queue1 WHERE docid = v_docid;
  
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
