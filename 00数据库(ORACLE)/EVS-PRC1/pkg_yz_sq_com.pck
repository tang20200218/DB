CREATE OR REPLACE PACKAGE pkg_yz_sq_com IS

  /***************************************************************************************************
  名称     : pkg_yz_sq_com
  功能描述 : 印制-凭证申领分发单位
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-13  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询制作单位已加的申请单位集合
  PROCEDURE p_getcoms
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 添加
  PROCEDURE p_ins
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 申请单位的添加/删除
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_yz_sq_com IS
  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码  
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_row_rn           INT;
    v_row_comid        VARCHAR2(64);
    v_row_comname      VARCHAR2(128);
    v_row_sort         INT;
    v_row_modifieddate DATE;
    v_row_opername     VARCHAR2(64);
  
    v_dtype VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');

    -- 验证用户权限
    pkg_qp_verify.p_check('MD120', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
  
    -- 制作sql
    v_sql := 'select sqcomid,sqcomname,sort,opername,modifieddate FROM data_yz_sq_com E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.dtype = ''', v_dtype, '''');
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY sort desc,sqcomid DESC ');
    v_sql := myquery.f_getpagesql(v_sql, v_pagesize, v_pagenum);
    mydebug.wlog('v_sql', v_sql);
  
    -- 分页起始编号
    v_row_rn := myquery.f_getpagestartnum(v_pagesize, v_pagenum);
  
    -- 执行sql
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, myquery.f_getpagenation(v_cnt, v_pagesize, v_pagenum));
    dbms_lob.append(o_info, ',"dataList":[');
    DECLARE
      v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果
    BEGIN
      OPEN v_cursor FOR v_sql;
      LOOP
        FETCH v_cursor
          INTO v_row_comid, v_row_comname, v_row_sort, v_row_opername, v_row_modifieddate;
        EXIT WHEN v_cursor%NOTFOUND;
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"comid":"', v_row_comid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"comname":"', v_row_comname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"sort":"', v_row_sort, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"opername":"', v_row_opername, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"modifieddate":"', to_char(v_row_modifieddate, 'yyyy-mm-dd hh24:mi'), '"'));
        dbms_lob.append(o_info, '}');
        v_row_rn := v_row_rn + 1;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        mydebug.err(7);
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
    END;
    dbms_lob.append(o_info, ']');
    dbms_lob.append(o_info, ',"code":"EC00"');
    dbms_lob.append(o_info, ',"msg":"处理成功"');
    dbms_lob.append(o_info, '}');
  
    mydebug.wlog('o_info', o_info);
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_info := NULL;
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
  END;

  -- 查询制作单位已加的申请单位集合
  PROCEDURE p_getcoms
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_num   INT := 0;
    v_dtype VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"o_coms":"');
    DECLARE
      v_sqcomid VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t.sqcomid FROM data_yz_sq_com t WHERE t.dtype = v_dtype;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_sqcomid;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num = 1 THEN
          o_info := mystring.f_concat(o_info, v_sqcomid);
        ELSE
          o_info := mystring.f_concat(o_info, ',', v_sqcomid);
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
    o_info := mystring.f_concat(o_info, '"');
    o_info := mystring.f_concat(o_info, ',"code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"处理成功"');
    o_info := mystring.f_concat(o_info, '}');
  
    mydebug.wlog('o_info', o_info);
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_info := NULL;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 添加
  PROCEDURE p_ins
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id       VARCHAR2(128);
    v_data     VARCHAR2(32767);
    v_sort     INT;
    v_sysdate  DATE := SYSDATE;
    v_dtype    VARCHAR2(64);
    v_xml      xmltype;
    v_i        INT := 0;
    v_xpath    VARCHAR2(200);
    v_comuri   VARCHAR2(128);
    v_comname  VARCHAR2(128);
    v_exists   INT := 0;
    v_yzfftype INT;
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD120', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.selectData' RETURNING VARCHAR2(32767)) INTO v_data FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_data', v_data);
  
    IF mystring.f_isnull(v_dtype) THEN
      o_code := 'EC02';
      o_msg  := '凭证类型为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT yzfftype INTO v_yzfftype FROM info_template t WHERE t.tempid = v_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_xml := xmltype(v_data);
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      v_xpath := mystring.f_concat('/datas/data[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'comuri')) INTO v_comuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'comname')) INTO v_comname FROM dual;
      IF mystring.f_isnull(v_comuri) THEN
        v_i := 100;
      ELSE
      
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_yz_sq_com t
                 WHERE t.dtype = v_dtype
                   AND t.sqcomid = v_comuri);
      
        IF v_exists = 0 THEN
          SELECT MAX(t.sort) INTO v_sort FROM data_yz_sq_com t WHERE t.dtype = v_dtype;
          IF v_sort IS NULL THEN
            v_sort := 1;
          ELSE
            v_sort := v_sort + 1;
          END IF;
          v_id := mystring.f_concat(v_dtype, v_comuri);
          INSERT INTO data_yz_sq_com (id, dtype, sqcomid, sqcomname, sort, operuri, opername) VALUES (v_id, v_dtype, v_comuri, v_comname, v_sort, i_operuri, i_opername);
        
          IF v_yzfftype = 1 THEN
            -- 自动分配
            o_code := 'EC00';
            DECLARE
              v_docid VARCHAR2(64);
              CURSOR v_cursor IS
                SELECT t.docid
                  FROM data_yz_sq_book t
                 WHERE t.dtype = v_dtype
                   AND t.fromuri = v_comuri
                   AND t.status = 'VSB1';
            BEGIN
              OPEN v_cursor;
              LOOP
                FETCH v_cursor
                  INTO v_docid;
                EXIT WHEN v_cursor%NOTFOUND;
                -- 设置在分配
                UPDATE data_yz_sq_book t
                   SET t.respnum = t.booknum, t.status = 'VSB3', t.modifieddate = v_sysdate, t.operuri = i_operuri, t.opername = i_opername
                 WHERE t.docid = v_docid;
              
                -- 增加自动分发队列
                pkg_yz_sq_reply_queue1.p_add(v_docid, o_code, o_msg);
                IF o_code <> 'EC00' THEN
                  EXIT;
                END IF;
              END LOOP;
              CLOSE v_cursor;
            EXCEPTION
              WHEN OTHERS THEN
                ROLLBACK;
                o_code := 'EC03';
                o_msg  := '系统错误，请检查！';
                mydebug.err(7);
                IF v_cursor%ISOPEN THEN
                  CLOSE v_cursor;
                END IF;
                RETURN;
            END;
            IF o_code <> 'EC00' THEN
              ROLLBACK;
              RETURN;
            END IF;
          
          END IF;
        END IF;
      END IF;
      v_i := v_i + 1;
    END LOOP;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 删除
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype   VARCHAR2(64);
    v_sqcomid VARCHAR2(64);
    v_data    VARCHAR2(4000);
    v_xml     xmltype;
    v_i       INT := 0;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD120', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.selectData') INTO v_data FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_data', v_data);
  
    IF mystring.f_isnull(v_dtype) THEN
      o_code := 'EC02';
      o_msg  := '凭证类型为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_data) THEN
      o_code := 'EC02';
      o_msg  := '单位标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_xml := xmltype(v_data);
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/datas/data[', v_i, ']/comuri')) INTO v_sqcomid FROM dual;
      IF mystring.f_isnull(v_sqcomid) THEN
        v_i := 100;
      ELSE
        DELETE FROM data_yz_sq_com
         WHERE dtype = v_dtype
           AND sqcomid = v_sqcomid;
      END IF;
      v_i := v_i + 1;
    END LOOP;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 申请单位的添加/删除
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_type VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
    mydebug.wlog('v_type', v_type);
  
    IF mystring.f_isnull(v_type) OR v_type NOT IN ('1', '0', '2', '3') THEN
      o_code := 'EC02';
      o_msg  := '操作类型不正确,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_type = '1' THEN
      pkg_yz_sq_com.p_ins(i_forminfo, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSIF v_type = '0' THEN
      pkg_yz_sq_com.p_del(i_forminfo, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    END IF;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

END;
/
