CREATE OR REPLACE PACKAGE pkg_sq_pz IS

  /***************************************************************************************************
  名称     : pkg_sq_pz
  功能描述 : 空白凭证申领-已申领的空白凭证
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询库存凭证信息
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT VARCHAR2, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_sq_pz IS

  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码  
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_row_rn        INT;
    v_row_id        VARCHAR2(64);
    v_row_dtype     VARCHAR2(64);
    v_row_role      VARCHAR2(64); -- 签发角色，调用凭证接口SetUserRole传入凭证
    v_row_evnum     VARCHAR2(64);
    v_row_booktime  DATE;
    v_row_filename  VARCHAR2(128);
    v_row_filepath  VARCHAR2(256);
    v_row_filename2 VARCHAR2(128);
  
    v_dtype        VARCHAR2(64);
    v_conditions   VARCHAR2(4000);
    v_cs_starttime VARCHAR2(200);
    v_cs_endtime   VARCHAR2(200);
  BEGIN
    mydebug.wlog('开始');

    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/condition/others/starttime') INTO v_cs_starttime FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/endtime') INTO v_cs_endtime FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select createddate,id from data_yz_pz_pub E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.dtype = ''', v_dtype, '''');
  
    IF mystring.f_isnotnull(v_cs_starttime) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.createddate >= to_date(''', v_cs_starttime, ''', ''yyyy-mm-dd'')');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_endtime) THEN
      v_cs_endtime := mydate.f_addday_str(v_cs_endtime, 1);

      v_sql := mystring.f_concat(v_sql, ' AND E1.createddate < to_date(''', v_cs_endtime, ''', ''yyyy-mm-dd'')');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY createddate desc,id desc');
    v_sql := myquery.f_getpagesql(v_sql, v_pagesize, v_pagenum);
    mydebug.wlog('v_sql', v_sql);
  
    -- 分页起始编号
    v_row_rn := myquery.f_getpagestartnum(v_pagesize, v_pagenum);
  
    -- 执行sql
    dbms_lob.createtemporary(o_info1, TRUE);
    dbms_lob.append(o_info1, '{');
    dbms_lob.append(o_info1, '"objContent":{');
    dbms_lob.append(o_info1, myquery.f_getpagenation(v_cnt, v_pagesize, v_pagenum));
    dbms_lob.append(o_info1, ',"dataList":[');
    DECLARE
      v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果
    BEGIN
      OPEN v_cursor FOR v_sql;
      LOOP
        FETCH v_cursor
          INTO v_row_booktime, v_row_id;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT dtype, num_start INTO v_row_dtype, v_row_evnum FROM data_yz_pz_pub WHERE id = v_row_id;
      
        v_row_filename  := pkg_file0.f_getfilename_docid(v_row_id, 0);
        v_row_filepath  := pkg_file0.f_getfilepath_docid(v_row_id, 0);
        v_row_filename2 := pkg_file0.f_getfilename_docid(v_row_id, 2);
        v_row_role      := pkg_info_template_pbl.f_getrole(v_row_dtype);
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info1, ',');
        END IF;
        dbms_lob.append(o_info1, '{');
        dbms_lob.append(o_info1, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"id":"', v_row_id, '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"dtype":"', v_row_dtype, '"'));
        dbms_lob.append(o_info1, ',"status":"VSA4"');
        dbms_lob.append(o_info1, mystring.f_concat(',"role":"', v_row_role, '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"evnum":"', v_row_evnum, '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"booktime":"', to_char(v_row_booktime, 'yyyy-mm-dd hh24:mi:ss'), '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"filename":"', v_row_filename, '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"filepath":"', myjson.f_escape(v_row_filepath), '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"filename2":"', v_row_filename2, '"'));
        dbms_lob.append(o_info1, '}');
      
        IF mystring.f_isnull(o_info2) THEN
          IF mystring.f_isnotnull(v_row_filepath) AND mystring.f_isnotnull(v_row_filename) THEN
            o_info2 := '<info>';
            o_info2 := mystring.f_concat(o_info2, '<dlfiles>');
            o_info2 := mystring.f_concat(o_info2, '<file flag="iconimg_', v_row_dtype, '">', v_row_filepath, v_row_filename, '</file>');
            o_info2 := mystring.f_concat(o_info2, '</dlfiles>');
            o_info2 := mystring.f_concat(o_info2, '</info>');
          END IF;
        END IF;
      
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
    dbms_lob.append(o_info1, ']');
    dbms_lob.append(o_info1, '}');
    dbms_lob.append(o_info1, ',"code":"EC00"');
    dbms_lob.append(o_info1, ',"msg":"处理成功"');
    dbms_lob.append(o_info1, '}');
  
    mydebug.wlog('o_info1', o_info1);
    mydebug.wlog('o_info2', o_info2);
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_info1 := NULL;
      o_info2 := NULL;
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
  END;

  -- 删除
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id   VARCHAR2(64);
    v_data VARCHAR2(4000);
    v_xml  xmltype;
    v_i    INT := 0;
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.selectData') INTO v_data FROM dual;
    mydebug.wlog('v_data', v_data);
  
    v_xml := xmltype(v_data);
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/selectData/data[', v_i, ']/id')) INTO v_id FROM dual;
      IF mystring.f_isnull(v_id) THEN
        v_i := 100;
      ELSE
        mydebug.wlog('v_id', v_id);
      
        DECLARE
          v_exists INT := 0;
        BEGIN
          SELECT COUNT(1) INTO v_exists FROM data_yz_pz_pub t WHERE t.id = v_id;
          IF v_exists = 0 THEN
            o_code := 'EC00';
            o_msg  := '未找到该凭证,请检查！';
            mydebug.wlog(3, o_code, o_msg);
            RETURN;
          END IF;
        END;
      
        -- 删除文件
        pkg_file0.p_del_docid(v_id, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          ROLLBACK;
          RETURN;
        END IF;
      
        DELETE FROM data_yz_pz_pub WHERE id = v_id;
      
      END IF;
      v_i := v_i + 1;
    END LOOP;
  
    COMMIT;
  
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

  -- 查询库存凭证信息
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT VARCHAR2, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id        VARCHAR2(64);
    v_dtype     VARCHAR2(64);
    v_role      VARCHAR2(128);
    v_num_start INT;
    v_filename  VARCHAR2(128);
    v_filepath  VARCHAR2(512);
    v_exists    INT := 0;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_id') INTO v_id FROM dual;
    mydebug.wlog('v_id', v_id);
  
    IF mystring.f_isnull(v_id) THEN
      o_code := 'EC00';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;

    SELECT COUNT(1) INTO v_exists FROM data_yz_pz_pub t WHERE t.id = v_id;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '未找到该凭证,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT dtype, num_start INTO v_dtype, v_num_start FROM data_yz_pz_pub t WHERE t.id = v_id;
  
    v_role     := pkg_info_template_pbl.f_getrole(v_dtype);
    v_filename := pkg_file0.f_getfilename_docid(v_id, 2);
    v_filepath := pkg_file0.f_getfilepath_docid(v_id, 2);
  
    o_info1 := '{';
    o_info1 := mystring.f_concat(o_info1, ' "i_id":"', v_id, '"');
    o_info1 := mystring.f_concat(o_info1, ',"id":"', v_id, '"');
    o_info1 := mystring.f_concat(o_info1, ',"uniqueId":"', v_id, '"');
    o_info1 := mystring.f_concat(o_info1, ',"role":"', v_role, '"');
    o_info1 := mystring.f_concat(o_info1, ',"evnum":"', v_num_start, '"');
    o_info1 := mystring.f_concat(o_info1, ',"filename":"', v_filename, '"');
    o_info1 := mystring.f_concat(o_info1, ',"filepath":"', myjson.f_escape(v_filepath), '"');
    o_info1 := mystring.f_concat(o_info1, ',"o_info":"');
    o_info1 := mystring.f_concat(o_info1, '<info>');
    o_info1 := mystring.f_concat(o_info1, '<id>', v_id, '</id>');
    o_info1 := mystring.f_concat(o_info1, '<role>', v_role, '</role>');
    o_info1 := mystring.f_concat(o_info1, '<evnum>', v_num_start, '</evnum>');
    o_info1 := mystring.f_concat(o_info1, '<filename>', v_filename, '</filename>');
    o_info1 := mystring.f_concat(o_info1, '<filepath>', v_filepath, '</filepath>');
    o_info1 := mystring.f_concat(o_info1, '</info>');
    o_info1 := mystring.f_concat(o_info1, '"');
    o_info1 := mystring.f_concat(o_info1, ',"code":"EC00"');
    o_info1 := mystring.f_concat(o_info1, ',"msg":"处理成功"');
    o_info1 := mystring.f_concat(o_info1, '}');
  
    o_info2 := '<info>';
    o_info2 := mystring.f_concat(o_info2, '<dlfiles>');
    o_info2 := mystring.f_concat(o_info2, '<file flag="datafile">', v_filepath, v_filename, '</file>');
    o_info2 := mystring.f_concat(o_info2, '</dlfiles>');
    o_info2 := mystring.f_concat(o_info2, '</info>');
  
    mydebug.wlog('o_info1', o_info1);
    mydebug.wlog('o_info2', o_info2);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      o_info1 := NULL;
      o_info2 := NULL;
      o_code  := 'EC03';
      o_msg   := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
