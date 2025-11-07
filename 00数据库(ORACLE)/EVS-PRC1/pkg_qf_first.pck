CREATE OR REPLACE PACKAGE pkg_qf_first IS

  /***************************************************************************************************
  名称     : pkg_qf_first
  功能描述 : 凭证印签办理-签发首页
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询列表上显示的签发对象分类
  FUNCTION f_getkindname
  (
    i_otype   INT, -- 1:单位 0:个人
    i_dtype   VARCHAR2,
    i_useruri VARCHAR2
  ) RETURN VARCHAR2;

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
CREATE OR REPLACE PACKAGE BODY pkg_qf_first IS

  -- 查询列表上显示的签发对象分类
  FUNCTION f_getkindname
  (
    i_otype   INT, -- 1:单位 0:个人
    i_dtype   VARCHAR2,
    i_useruri VARCHAR2
  ) RETURN VARCHAR2 AS
    v_name VARCHAR2(128);
    v_cnt  INT := 0;
  BEGIN
    SELECT COUNT(1)
      INTO v_cnt
      FROM info_admin_auth_kind t
     WHERE t.useruri = i_useruri
       AND t.dtype = i_dtype;
    IF v_cnt = 0 THEN
      RETURN '';
    END IF;
  
    SELECT q.name
      INTO v_name
      FROM (SELECT w1.name
              FROM info_register_kind w1
             INNER JOIN info_template_kind w2
                ON (w2.tempid = i_dtype AND w2.kindid = w1.id)
             INNER JOIN info_admin_auth_kind w3
                ON (w3.useruri = i_useruri AND w3.dtype = i_dtype AND w3.kindid = w1.id)
             WHERE w1.datatype = i_otype
             ORDER BY w1.fullsort, w1.id) q
     WHERE rownum <= 1;
  
    IF v_cnt = 1 THEN
      RETURN v_name;
    END IF;
  
    RETURN mystring.f_concat(v_name, '...');
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

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
    v_comid        VARCHAR2(64) := pkg_basic.f_getcomid;
    v_comname      VARCHAR2(128) := pkg_basic.f_getcomname; -- 签发单位名称
  
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码  
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_row_rn          INT;
    v_row_tempid      VARCHAR2(64);
    v_row_name        VARCHAR2(128);
    v_row_pcode       VARCHAR2(64);
    v_row_pname       VARCHAR2(128);
    v_row_wcnum       INT;
    v_row_dbnum       INT;
    v_row_otype       INT;
    v_row_kindtype    INT; -- 签发对象(1:不确定对象(默认)/2:相对固定对象)
    v_row_kindname    VARCHAR2(200); -- 相对固定对象显示内容
    v_row_hfilestatus INT; -- 是否存在申请表(1:是 0:否)
    v_row_sort        INT;
  
    v_otype      VARCHAR2(64);
    v_conditions VARCHAR2(4000);
    v_cs_name    VARCHAR2(200);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD110', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_fr') INTO v_otype FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件
    SELECT myxml.f_getvalue(v_conditions, '/condition/others/name') INTO v_cs_name FROM dual;
  
    -- 制作sql
    v_sql := 'select sort,tempid from info_template E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.enable = ''1''');
    v_sql := mystring.f_concat(v_sql, ' AND E1.bindstatus = 1');
    v_sql := mystring.f_concat(v_sql, ' AND E1.qfflag = 1');
    v_sql := mystring.f_concat(v_sql, ' AND E1.otype = ''', v_otype, '''');
  
    IF v_tempauthtype = 1 THEN
      v_sql := mystring.f_concat(v_sql, ' AND exists (SELECT 1 FROM info_admin_auth w WHERE w.useruri =''', i_operuri, ''' AND w.dtype = E1.tempid) ');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_name) THEN
      v_sql := mystring.f_concat(v_sql, ' AND (instr(E1.tempname, ''', v_cs_name, ''') > 0');
      v_sql := mystring.f_concat(v_sql, ' OR instr(E1.tempid, ''', v_cs_name, ''') > 0)');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY sort,tempid');
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
          INTO v_row_sort, v_row_tempid;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT tempname, pdtype, otype, kindtype INTO v_row_name, v_row_pcode, v_row_otype, v_row_kindtype FROM info_template WHERE tempid = v_row_tempid;
      
        v_row_pname := pkg_info_template_pbl.f_mktypename(v_row_pcode);
      
        -- 查询已签发
        SELECT COUNT(1)
          INTO v_row_wcnum
          FROM data_qf_book t
         WHERE t.dtype = v_row_tempid
           AND t.status = 'GG03';
      
        SELECT COUNT(1)
          INTO v_row_dbnum
          FROM data_qf_book t6
         WHERE t6.dtype = v_row_tempid
           AND t6.status IN ('GG01', 'GG02');
      
        IF v_row_kindtype IS NULL THEN
          v_row_kindtype := 1;
        END IF;
        IF v_row_kindtype = 2 THEN
          v_row_kindname := pkg_qf_first.f_getkindname(v_row_otype, v_row_tempid, i_operuri);
        ELSE
          IF v_row_otype = 0 THEN
            v_row_kindname := '不确定用户';
          ELSE
            v_row_kindname := '不确定单位';
          END IF;
        END IF;
      
        -- 是否存在申请表(1:是 0:否)
        SELECT COUNT(1) INTO v_row_hfilestatus FROM dual WHERE EXISTS (SELECT 1 FROM info_template_hfile t WHERE t.tempid = v_row_tempid);
        IF v_row_hfilestatus = 0 THEN
          SELECT COUNT(1) INTO v_row_hfilestatus FROM dual WHERE EXISTS (SELECT 1 FROM info_template_hfile0 t WHERE t.dtype = v_row_tempid);
        END IF;
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"id":"', v_comid, '_', v_row_tempid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"code":"', v_row_tempid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"name":"', v_row_name, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"comid":"', v_comid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"comname":"', v_comname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"pcode":"', v_row_pcode, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"pname":"', v_row_pname, '"'));
        dbms_lob.append(o_info, ',"subnum":"1"');
        dbms_lob.append(o_info, mystring.f_concat(',"wcnum":"', v_row_wcnum, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"dbnum":"', v_row_dbnum, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"otype":"', v_row_otype, '"'));
        dbms_lob.append(o_info, ',"mflag":"0"');
        dbms_lob.append(o_info, mystring.f_concat(',"kindtype":"', v_row_kindtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"kindname":"', myjson.f_escape(v_row_kindname), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"hfilestatus":"', v_row_hfilestatus, '"'));
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
END;
/
