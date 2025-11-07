CREATE OR REPLACE PACKAGE pkg_sq_first IS

  /***************************************************************************************************
  名称     : pkg_sq_first
  功能描述 : 空白凭证申领-首页
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-06  唐金鑫  创建
  
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

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_sq_first IS

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
    v_tempauthtype INT := pkg_info_template_pbl.f_getauthtype;
  
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码  
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_row_rn        INT;
    v_row_tempid    VARCHAR2(64);
    v_row_sort      INT;
    v_row_name      VARCHAR2(128);
    v_row_ywtype    VARCHAR2(8);
    v_row_dzcomid   VARCHAR2(64);
    v_row_dzcomname VARCHAR2(128);
    v_row_dzappname VARCHAR2(128);
    v_row_kcnum     INT; -- 库存数量
    v_row_sqnum     INT; -- 申领总量
    v_row_usnum     INT; -- 使用量
    v_row_covertype VARCHAR2(16);
  
    v_info VARCHAR2(32767);
  
    v_otype        VARCHAR2(64);
    v_conditions   VARCHAR2(4000);
    v_cs_name      VARCHAR2(200);
    v_cs_kcnum     VARCHAR2(200);
    v_cs_dzcomname VARCHAR2(200);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_otype') INTO v_otype FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/condition/others/name') INTO v_cs_name FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/kcnum') INTO v_cs_kcnum FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/dzcomname') INTO v_cs_dzcomname FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select sort, tempid from info_template E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.enable = ''1''');
    v_sql := mystring.f_concat(v_sql, ' AND E1.bindstatus = 1');
    v_sql := mystring.f_concat(v_sql, ' AND E1.sqflag = 1');
    v_sql := mystring.f_concat(v_sql, ' AND E1.otype = ''', v_otype, '''');
  
    IF v_tempauthtype = 1 THEN
      v_sql := mystring.f_concat(v_sql, ' AND exists (SELECT 1 FROM info_admin_auth w WHERE w.dtype = E1.tempid');
      v_sql := mystring.f_concat(v_sql, ' AND w.useruri =''', i_operuri, ''')');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_name) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.tempname, ''', v_cs_name, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_kcnum) THEN
      IF v_cs_kcnum = '1' THEN
        v_sql := mystring.f_concat(v_sql, ' AND exists (SELECT 1 FROM data_sq_apply_pz w WHERE w.dtype = E1.tempid)');
      ELSE
        v_sql := mystring.f_concat(v_sql, ' AND not exists (SELECT 1 FROM data_sq_apply_pz w WHERE w.dtype = E1.tempid)');
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_cs_dzcomname) THEN
      v_sql := mystring.f_concat(v_sql, ' AND exists (SELECT 1 FROM data_sq_dzcom w WHERE w.dtype = E1.tempid');
      v_sql := mystring.f_concat(v_sql, ' AND (instr(w.comname, ''', v_cs_dzcomname, ''') > 0');
      v_sql := mystring.f_concat(v_sql, ' OR instr(w.appname, ''', v_cs_dzcomname, ''') > 0))');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY sort, tempid');
    v_sql := myquery.f_getpagesql(v_sql, v_pagesize, v_pagenum);
    mydebug.wlog('v_sql', v_sql);
  
    -- 分页起始编号
    v_row_rn := myquery.f_getpagestartnum(v_pagesize, v_pagenum);
  
    -- 执行sql
    v_info := '{';
    v_info := mystring.f_concat(v_info, myquery.f_getpagenation(v_cnt, v_pagesize, v_pagenum));
    v_info := mystring.f_concat(v_info, ',"dataList":[');
    DECLARE
      v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果  
    BEGIN
      OPEN v_cursor FOR v_sql;
      LOOP
        FETCH v_cursor
          INTO v_row_sort, v_row_tempid;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT tempname, covertype INTO v_row_name, v_row_covertype FROM info_template WHERE tempid = v_row_tempid;
      
        v_row_dzcomid   := '';
        v_row_dzcomname := '';
        v_row_dzappname := '';
        BEGIN
          SELECT comid, comname, appname
            INTO v_row_dzcomid, v_row_dzcomname, v_row_dzappname
            FROM data_sq_dzcom t
           WHERE t.dtype = v_row_tempid
             AND rownum = 1;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        v_row_dzcomname := myjson.f_escape(v_row_dzcomname);
        v_row_dzappname := myjson.f_escape(v_row_dzappname);
      
        IF v_row_covertype = 'CoverType01' THEN
          v_row_ywtype := 0;
        ELSIF v_row_covertype = 'CoverType02' THEN
          v_row_ywtype := 1;
        ELSIF v_row_covertype = 'CoverType03' THEN
          v_row_ywtype := 2;
        ELSE
          v_row_ywtype := 0;
        END IF;
      
        -- 可用库存数量
        SELECT COUNT(1) INTO v_row_kcnum FROM data_yz_pz_pub t WHERE t.dtype = v_row_tempid;
      
        -- 申领量
        SELECT COUNT(1) INTO v_row_sqnum FROM data_sq_apply_pz t WHERE t.dtype = v_row_tempid;
      
        -- 使用量          
        SELECT COUNT(1) INTO v_row_usnum FROM data_qf_pz t WHERE t.dtype = v_row_tempid;
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          v_info := mystring.f_concat(v_info, ',');
        END IF;
        v_info   := mystring.f_concat(v_info, '{');
        v_info   := mystring.f_concat(v_info, ' "rn":"', v_row_rn, '"');
        v_info   := mystring.f_concat(v_info, ',"code":"', v_row_tempid, '"');
        v_info   := mystring.f_concat(v_info, ',"name":"', v_row_name, '"');
        v_info   := mystring.f_concat(v_info, ',"mksub":"1"');
        v_info   := mystring.f_concat(v_info, ',"evtype":"', v_row_tempid, '"');
        v_info   := mystring.f_concat(v_info, ',"evtypename":"', v_row_name, '"');
        v_info   := mystring.f_concat(v_info, ',"ywtype":"', v_row_ywtype, '"');
        v_info   := mystring.f_concat(v_info, ',"dzcomid":"', v_row_dzcomid, '"');
        v_info   := mystring.f_concat(v_info, ',"dzcomname":"', v_row_dzcomname, '"');
        v_info   := mystring.f_concat(v_info, ',"dzappname":"', v_row_dzappname, '"');
        v_info   := mystring.f_concat(v_info, ',"kcnum":"', v_row_kcnum, '"');
        v_info   := mystring.f_concat(v_info, ',"sqnum":"', v_row_sqnum, '"');
        v_info   := mystring.f_concat(v_info, ',"usnum":"', v_row_usnum, '"');
        v_info   := mystring.f_concat(v_info, '}');
        v_row_rn := v_row_rn + 1;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
    v_info := mystring.f_concat(v_info, ']');
    v_info := mystring.f_concat(v_info, ',"code":"EC00"');
    v_info := mystring.f_concat(v_info, ',"msg":"处理成功"');
    v_info := mystring.f_concat(v_info, '}');
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, v_info);
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

END;
/
