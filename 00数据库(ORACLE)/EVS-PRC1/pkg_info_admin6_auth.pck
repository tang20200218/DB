CREATE OR REPLACE PACKAGE pkg_info_admin6_auth IS

  /***************************************************************************************************
  名称     : pkg_info_admin6_auth
  功能描述 : 操作员授权
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-30  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询列表上显示的签发对象分类(已授权)
  FUNCTION f_getkindname_auth
  (
    i_otype   INT, -- 1:单位 0:个人
    i_dtype   VARCHAR2,
    i_useruri VARCHAR2
  ) RETURN VARCHAR2;

  -- 查询列表上显示的签发对象分类(未授权)
  FUNCTION f_getkindname_noauth
  (
    i_otype INT, -- 1:单位 0:个人
    i_dtype VARCHAR2
  ) RETURN VARCHAR2;

  -- 查询已授权凭证列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询操作员集合
  PROCEDURE p_getusers
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 操作员的授权
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 增加授权
  PROCEDURE p_add2
  (
    i_datatype IN INT,
    i_useruri  IN VARCHAR2, -- 人员标识
    i_dtype    IN VARCHAR2, -- 凭证类型代码
    i_operuri  IN VARCHAR2, -- 操作人标识
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 增加授权
  PROCEDURE p_add
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_dtypes   IN VARCHAR2, -- 凭证类型代码，逗号分隔
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 取消授权
  PROCEDURE p_del
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_dtypes   IN VARCHAR2, -- 凭证类型代码，逗号分隔
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_admin6_auth IS

  -- 查询列表上显示的签发对象分类(已授权)
  FUNCTION f_getkindname_auth
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
      RETURN '待设置';
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
      RETURN '待设置';
  END;

  -- 查询列表上显示的签发对象分类(未授权)
  FUNCTION f_getkindname_noauth
  (
    i_otype INT, -- 1:单位 0:个人
    i_dtype VARCHAR2
  ) RETURN VARCHAR2 AS
    v_name VARCHAR2(128);
    v_cnt  INT := 0;
  BEGIN
    SELECT COUNT(1) INTO v_cnt FROM info_template_kind t WHERE t.tempid = i_dtype;
    IF v_cnt = 0 THEN
      RETURN '待设置';
    END IF;
  
    SELECT q.name
      INTO v_name
      FROM (SELECT w1.name
              FROM info_register_kind w1
             INNER JOIN info_template_kind w2
                ON (w2.tempid = i_dtype AND w2.kindid = w1.id)
             WHERE w1.datatype = i_otype
             ORDER BY w1.fullsort, w1.id) q
     WHERE rownum <= 1;
  
    IF v_cnt = 1 THEN
      RETURN v_name;
    END IF;
  
    RETURN mystring.f_concat(v_name, '...');
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '待设置';
  END;

  /***************************************************************************************************
  名称     : pkg_info_admin6_auth.p_getlist
  功能描述 : 查询已授权凭证列表
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-31  唐金鑫  创建
  
  业务说明
  <RESPONSE>
    <ROWS>
        <ROW row_id="1">
            <code>凭证类型代码</code>
            <name>凭证类型名称</name>
            <otype>(1:单位 0:个人)</otype>
            <usetype>签发类型(0:印签 1:签发 2:印制)</usetype>
            <kindtype>签发对象(1:不确定对象/2:相对固定对象)</kindtype>
            <kindname>签发对象显示内容</kindname>
        </ROW>
    </ROWS>
  </RESPONSE>
  ***************************************************************************************************/
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
  
    v_row_rn       INT;
    v_row_id       VARCHAR2(64);
    v_row_name     VARCHAR2(128);
    v_row_otype    INT;
    v_row_usetype  VARCHAR2(8); -- 签发类型(0:印签 1:签发 2:印制)
    v_row_kindtype INT; -- 签发对象(1:不确定对象(默认)/2:相对固定对象)
    v_row_kindname VARCHAR2(200); -- 签发对象分类显示内容
    v_row_flag     INT;
    v_row_sort     INT;
    v_row          VARCHAR2(4000);
  
    v_useruri    VARCHAR2(64);
    v_conditions VARCHAR2(4000);
    v_cs_name    VARCHAR2(200);
  BEGIN
    mydebug.wlog('开始');
    -- 验证用户权限
    pkg_qp_verify.p_check('MD913', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_useruri') INTO v_useruri FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件
    SELECT myxml.f_getvalue(v_conditions, '/condition/others/name') INTO v_cs_name FROM dual;
  
    -- 制作sql
    v_sql := 'select sort,tempid from info_template E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.bindstatus = 1');
    v_sql := mystring.f_concat(v_sql, ' AND E1.enable = ''1''');
  
    IF mystring.f_isnotnull(v_cs_name) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.tempname, ''', v_cs_name, ''') > 0');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY sort,tempid desc');
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
          INTO v_row_sort, v_row_id;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT t.tempname, t.otype, t.kindtype INTO v_row_name, v_row_otype, v_row_kindtype FROM info_template t WHERE t.tempid = v_row_id;
      
        -- 签发类型(0:印签 1:签发 2:印制)
        v_row_usetype := 0;
        BEGIN
          SELECT t.usetype INTO v_row_usetype FROM info_template_bind t WHERE t.id = v_row_id;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      
        SELECT COUNT(1)
          INTO v_row_flag
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM info_admin_auth w
                 WHERE w.useruri = v_useruri
                   AND w.dtype = v_row_id);
      
        IF v_row_usetype = 2 THEN
          v_row_kindname := '';
        ELSE
          IF v_row_kindtype = 2 THEN
            IF v_row_flag = 0 THEN
              v_row_kindname := pkg_info_admin6_auth.f_getkindname_noauth(v_row_otype, v_row_id);
            ELSE
              v_row_kindname := pkg_info_admin6_auth.f_getkindname_auth(v_row_otype, v_row_id, v_useruri);
            END IF;
          ELSE
            IF v_row_otype = 0 THEN
              v_row_kindname := '不确定用户';
            ELSE
              v_row_kindname := '不确定单位';
            END IF;
          END IF;
        END IF;
        v_row := '{';
        v_row := mystring.f_concat(v_row, ' "rn":"', v_row_rn, '"');
        v_row := mystring.f_concat(v_row, ',"code":"', v_row_id, '"');
        v_row := mystring.f_concat(v_row, ',"name":"', v_row_name, '"');
        v_row := mystring.f_concat(v_row, ',"otype":"', v_row_otype, '"');
        v_row := mystring.f_concat(v_row, ',"usetype":"', v_row_usetype, '"');
        v_row := mystring.f_concat(v_row, ',"kindtype":"', v_row_kindtype, '"');
        v_row := mystring.f_concat(v_row, ',"kindname":"', myjson.f_escape(v_row_kindname), '"');
        v_row := mystring.f_concat(v_row, ',"flag":"', v_row_flag, '"');
        v_row := mystring.f_concat(v_row, '}');
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, v_row);
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

  /***************************************************************************************************
  名称     : pkg_info_admin6_auth.p_getusers
  功能描述 : 查询操作员集合
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-18  唐金鑫  创建
  
  业务说明
  <rows>
    <row>
      <useruri>人员标识</useruri>
      <username>人员姓名</username>
    </row>
  </rows>
  ***************************************************************************************************/
  PROCEDURE p_getusers
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_rootname  VARCHAR2(128);
    v_cnt       INT := 0;
    v_tree      VARCHAR2(32767);
    v_adminuri  VARCHAR2(64);
    v_adminname VARCHAR2(128);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD913', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.rootname') INTO v_rootname FROM dual;
  
    SELECT COUNT(1) INTO v_cnt FROM info_admin t WHERE t.admintype = 'MT06';
  
    v_tree := '<?xml version="1.0" encoding="UTF-8"?>';
    v_tree := mystring.f_concat(v_tree, '<tree id="0">');
    v_tree := mystring.f_concat(v_tree, '<item id="root" text="', v_rootname, '"');
    v_tree := mystring.f_concat(v_tree, ' open="1" im0="folderClosed2.gif" im1="folderClosed2.gif" im2="folderClosed2.gif">');
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.adminuri, t.adminname FROM info_admin t WHERE t.admintype = 'MT06' ORDER BY t.sort, t.adminuri;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_adminuri, v_adminname;
        EXIT WHEN v_cursor%NOTFOUND;
        v_tree := mystring.f_concat(v_tree, '<item');
        v_tree := mystring.f_concat(v_tree, ' id="', myjson.f_escape(v_adminuri), '"');
        v_tree := mystring.f_concat(v_tree, ' text="', myjson.f_escape(v_adminuri), '（', myjson.f_escape(v_adminname), '）"');
        v_tree := mystring.f_concat(v_tree, ' im0="icon13.gif" im1="icon13.gif" im2="icon13.gif"/>');
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
  
    v_tree := mystring.f_concat(v_tree, '</item>');
    v_tree := mystring.f_concat(v_tree, '</tree>');
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, '"xmltree":"');
    dbms_lob.append(o_info, myjson.f_escape(v_tree));
    dbms_lob.append(o_info, '"');
    dbms_lob.append(o_info, ',"i_type":"T2"');
    dbms_lob.append(o_info, ',"rootname":"');
    dbms_lob.append(o_info, v_rootname);
    dbms_lob.append(o_info, '"');
    dbms_lob.append(o_info, ',"i_admintype":"MT06"');
    dbms_lob.append(o_info, ',"i_pagesize":"');
    dbms_lob.append(o_info, mystring.f_int2char(v_cnt));
    dbms_lob.append(o_info, '"');
    dbms_lob.append(o_info, ',"i_pagenum":"1"');
    dbms_lob.append(o_info, ',"o_info":""');
    dbms_lob.append(o_info, ',"code":"EC00"');
    dbms_lob.append(o_info, ',"msg":"处理成功"');
    dbms_lob.append(o_info, '}');
  
    mydebug.wlog('o_info', o_info);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      o_info := NULL;
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
  END;

  -- 操作员的授权
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_useruri VARCHAR2(64);
    v_dtypes  VARCHAR2(4000);
    v_dtypes2 VARCHAR2(4000);
  BEGIN
    mydebug.wlog('开始');
  
    SELECT json_value(i_forminfo, '$.i_useruri') INTO v_useruri FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtypes') INTO v_dtypes FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtypes2') INTO v_dtypes2 FROM dual;
  
    -- 增加的授权
    IF mystring.f_isnotnull(v_dtypes) THEN
      pkg_info_admin6_auth.p_add(v_useruri, v_dtypes, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    END IF;
  
    -- 取消的授权
    IF mystring.f_isnotnull(v_dtypes2) THEN
      pkg_info_admin6_auth.p_del(v_useruri, v_dtypes2, i_operuri, i_opername, o_code, o_msg);
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

  -- 增加授权
  PROCEDURE p_add2
  (
    i_datatype IN INT,
    i_useruri  IN VARCHAR2, -- 人员标识
    i_dtype    IN VARCHAR2, -- 凭证类型代码
    i_operuri  IN VARCHAR2, -- 操作人标识
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id     VARCHAR2(128);
    v_kindid VARCHAR2(64);
  BEGIN
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.id
          FROM info_register_kind t
         WHERE t.datatype = i_datatype
           AND EXISTS (SELECT 1
                  FROM info_template_kind w
                 WHERE w.tempid = i_dtype
                   AND w.kindid = t.id);
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_kindid;
        EXIT WHEN v_cursor%NOTFOUND;
        v_id := mystring.f_concat(i_useruri, i_dtype, v_kindid);
        DELETE FROM info_admin_auth_kind WHERE id = v_id;
        INSERT INTO info_admin_auth_kind (id, useruri, dtype, kindid, operuri, opername) VALUES (v_id, i_useruri, i_dtype, v_kindid, i_operuri, i_operuri);
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        o_code := 'EC03';
        o_msg  := '系统错误，请检查！';
        mydebug.err(7);
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        RETURN;
    END;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_info_admin6_auth.p_add
  功能描述 : 增加授权
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-31  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_add
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_dtypes   IN VARCHAR2, -- 凭证类型代码，逗号分隔
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists    INT := 0;
    v_ids_count INT := 0;
    v_i         INT := 0;
  
    v_otype INT := 0;
    v_dtype VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_useruri', i_useruri);
    mydebug.wlog('i_dtypes', i_dtypes);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD913', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_dtypes) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    v_ids_count := myarray.f_getcount(i_dtypes, ',');
    IF v_ids_count = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    v_i := 1;
    WHILE v_i <= v_ids_count LOOP
      v_dtype := myarray.f_getvalue(i_dtypes, ',', v_i);
    
      IF mystring.f_isnotnull(v_dtype) THEN
      
        v_otype := pkg_info_template_pbl.f_getotype(v_dtype);
      
        DELETE FROM info_admin_auth
         WHERE useruri = i_useruri
           AND dtype = v_dtype;
        INSERT INTO info_admin_auth (useruri, dtype, operuri, opername) VALUES (i_useruri, v_dtype, i_operuri, i_opername);
      
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM info_admin_auth_kind t
                 WHERE t.useruri = i_useruri
                   AND t.dtype = v_dtype);
        IF v_exists = 0 THEN
          pkg_info_admin6_auth.p_add2(v_otype, i_useruri, v_dtype, i_operuri, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
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

  /***************************************************************************************************
  名称     : pkg_info_admin6_auth.p_del
  功能描述 : 取消授权
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-31  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_del
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_dtypes   IN VARCHAR2, -- 凭证类型代码，逗号分隔
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_ids_count INT := 0;
    v_i         INT := 0;
    v_dtype     VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_useruri', i_useruri);
    mydebug.wlog('i_dtypes', i_dtypes);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD913', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_dtypes) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    v_ids_count := myarray.f_getcount(i_dtypes, ',');
    IF v_ids_count = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    v_i := 1;
    WHILE v_i <= v_ids_count LOOP
      v_dtype := myarray.f_getvalue(i_dtypes, ',', v_i);
      DELETE FROM info_admin_auth
       WHERE useruri = i_useruri
         AND dtype = v_dtype;
      DELETE FROM info_admin_auth_kind
       WHERE useruri = i_useruri
         AND dtype = v_dtype;
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
END;
/
