CREATE OR REPLACE PACKAGE pkg_info_template_list IS

  /***************************************************************************************************
  名称     : pkg_info_template_list
  功能描述 : 凭证参数维护-列表页面
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-19  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 列表上显示的签发角色
  FUNCTION f_getroles_name(i_code VARCHAR2) RETURN VARCHAR2;

  -- 查询列表上显示的签发对象分类
  FUNCTION f_getkindname
  (
    i_otype INT, -- 1:单位 0:个人
    i_dtype VARCHAR2
  ) RETURN VARCHAR2;

  -- 查询归主凭证列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 修改排序号
  PROCEDURE p_sort
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_template_list IS
  -- 列表上显示的签发角色
  FUNCTION f_getroles_name(i_code VARCHAR2) RETURN VARCHAR2 AS
    v_result   VARCHAR2(2000);
    v_rolename VARCHAR2(200);
  BEGIN
    DECLARE
      CURSOR v_cursor IS
        SELECT t.rolename FROM info_template_role t WHERE t.tempcode = i_code ORDER BY t.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_rolename;
        EXIT WHEN v_cursor%NOTFOUND;
        IF mystring.f_isnull(v_result) THEN
          v_result := v_rolename;
        ELSE
          v_result := mystring.f_concat(v_result, ',', v_rolename);
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
    END;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询列表上显示的签发对象分类
  FUNCTION f_getkindname
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
  名称     : pkg_info_template_list.p_getlist
  功能描述 : 查询凭证列表
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  {
      "beanname": "mixtureServiceImpl",
      "methodname": "queryTmplPageList",
      "i_conditions": "",
      "currPage": "1",
      "perPageCount": "19"
  }
  
  {
    "pageNation": {
        "allCount": 22,
        "allPage": 2,
        "curPage": 1,
        "endPoint": 39,
        "perPage": 19,
        "startPoint": 1
    },
    "dataList": [
        {
            "rn": "1",
            "id": "",
        }
    ],
    "code": "EC00",
    "msg": "处理成功"
  }
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
  
    v_row_rn         INT;
    v_row_tempid     VARCHAR2(64);
    v_row_comid      VARCHAR2(64);
    v_row_tempname   VARCHAR2(128);
    v_row_pcode      VARCHAR2(64);
    v_row_pname      VARCHAR2(128);
    v_row_roles      VARCHAR2(128);
    v_row_roles_code VARCHAR2(128);
    v_row_billcode   VARCHAR2(128);
    v_row_billorg    VARCHAR2(128);
    v_row_otype      VARCHAR2(8);
    v_row_usetype    VARCHAR2(8); -- 签发类型(0:印签 1:签发 2:印制)
    v_row_kindtype   INT; -- 签发对象(1:不确定对象(默认)/2:相对固定对象)
    v_row_kindname   VARCHAR2(200); -- 签发对象分类显示内容
    v_row_enable     VARCHAR2(8);
    v_row_setval     INT;
    v_row_filename   VARCHAR2(200);
    v_row_filename2  VARCHAR2(200);
    v_row_sort       INT;
    v_row_operdate   DATE;
    v_row_operunm    VARCHAR2(64);
  
    v_fileid1 VARCHAR2(64);
    v_fileid2 VARCHAR2(64);
  
    v_conditions   VARCHAR2(4000);
    v_cs_billname  VARCHAR2(200);
    v_cs_enable    VARCHAR2(200);
    v_cs_operdate1 VARCHAR2(200);
    v_cs_operdate2 VARCHAR2(200);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/condition/others/billname') INTO v_cs_billname FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/enable') INTO v_cs_enable FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/operdate1') INTO v_cs_operdate1 FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/operdate2') INTO v_cs_operdate2 FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select sort,tempid from info_template E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.bindstatus = 1');
  
    IF pkg_basic.f_getsystype = '2' THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.vtype = 1');
    ELSE
      v_sql := mystring.f_concat(v_sql, ' AND E1.vtype = 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_billname) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.tempname, ''', v_cs_billname, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_enable) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.enable = ''', v_cs_enable, '''');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_operdate1) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.operdate >= to_date(''', v_cs_operdate1, ''', ''yyyy-mm-dd'')');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_operdate2) THEN
      v_cs_operdate2 := mydate.f_addday_str(v_cs_operdate2, 1);
    
      v_sql := mystring.f_concat(v_sql, ' AND E1.operdate < to_date(''', v_cs_operdate2, ''', ''yyyy-mm-dd'')');
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
          INTO v_row_sort, v_row_tempid;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT comid, tempname, pdtype, billcode, billorg, otype, kindtype, ENABLE, yzautostock, operdate, operunm
          INTO v_row_comid, v_row_tempname, v_row_pcode, v_row_billcode, v_row_billorg, v_row_otype, v_row_kindtype, v_row_enable, v_row_setval, v_row_operdate, v_row_operunm
          FROM info_template
         WHERE tempid = v_row_tempid;
      
        v_row_pname      := pkg_info_template_pbl.f_mktypename(v_row_pcode);
        v_row_roles      := pkg_info_template_list.f_getroles_name(v_row_tempid);
        v_row_roles_code := pkg_info_template_pbl.f_getrole(v_row_tempid);
      
        IF v_row_setval IS NULL THEN
          v_row_setval := 0;
        END IF;
      
        v_row_usetype := 0;
        BEGIN
          SELECT usetype INTO v_row_usetype FROM info_template_bind t WHERE t.id = v_row_tempid;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      
        IF v_row_usetype = 2 THEN
          v_row_kindname := '';
        ELSE
          IF v_row_kindtype = 2 THEN
            v_row_kindname := pkg_info_template_list.f_getkindname(v_row_otype, v_row_tempid);
          ELSE
            IF v_row_otype = 0 THEN
              v_row_kindname := '不确定用户';
            ELSE
              v_row_kindname := '不确定单位';
            END IF;
          END IF;
        END IF;
      
        v_fileid1 := NULL;
        v_fileid2 := NULL;
        BEGIN
          SELECT fileid1, fileid2 INTO v_fileid1, v_fileid2 FROM info_template_file t WHERE t.code = v_row_tempid;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        v_row_filename  := pkg_file0.f_getfilename(v_fileid1);
        v_row_filename2 := pkg_file0.f_getfilename(v_fileid2);
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"id":"', v_row_tempid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"tempid":"', v_row_tempid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"comid":"', v_row_comid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"temptype":"', v_row_tempid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"tempname":"', v_row_tempname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"dtype":"', v_row_tempid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"dtypename":"', v_row_tempname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"pcode":"', v_row_pcode, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"pname":"', v_row_pname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"roles":"', v_row_roles, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"roles_code":"', v_row_roles_code, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"billcode":"', v_row_billcode, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"billorg":"', v_row_billorg, '"'));
        dbms_lob.append(o_info, ',"mflag":"0"');
        dbms_lob.append(o_info, mystring.f_concat(',"otype":"', v_row_otype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"usetype":"', v_row_usetype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"kindtype":"', v_row_kindtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"kindname":"', myjson.f_escape(v_row_kindname), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"enable":"', v_row_enable, '"'));
        dbms_lob.append(o_info, ',"curval":"0"');
        dbms_lob.append(o_info, mystring.f_concat(',"setval":"', v_row_setval, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"filename":"', v_row_filename, '"'));
        IF mystring.f_isnull(v_row_filename) THEN
          dbms_lob.append(o_info, ',"fileIsExist":"0"');
        ELSE
          dbms_lob.append(o_info, ',"fileIsExist":"1"');
        END IF;
        dbms_lob.append(o_info, mystring.f_concat(',"filename2":"', v_row_filename2, '"'));
        IF mystring.f_isnull(v_row_filename2) THEN
          dbms_lob.append(o_info, ',"coverIsExist":"0"');
        ELSE
          dbms_lob.append(o_info, ',"coverIsExist":"1"');
        END IF;
        dbms_lob.append(o_info, mystring.f_concat(',"sort":"', v_row_sort, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"operdate":"', to_char(v_row_operdate, 'yyyy-mm-dd hh24:mi'), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"operunm":"', v_row_operunm, '"'));
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

  /***************************************************************************************************
  名称     : pkg_info_template_list.p_sort
  功能描述 : 凭证参数维护-修改排序号
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-03  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_sort
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_tempid VARCHAR2(64);
    v_sort   VARCHAR2(64);
    v_sort2  INT;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作者信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    SELECT json_value(i_forminfo, '$.i_sort') INTO v_sort FROM dual;
    mydebug.wlog('v_tempid', v_tempid);
    mydebug.wlog('v_sort', v_sort);
  
    IF mystring.f_isnull(v_sort) THEN
      SELECT MAX(sort) INTO v_sort2 FROM info_template t WHERE t.bindstatus = 1;
      IF v_sort2 IS NULL THEN
        v_sort2 := 1;
      ELSE
        v_sort2 := v_sort2 + 1;
      END IF;
    ELSE
      v_sort2 := v_sort;
    END IF;
  
    UPDATE info_template t SET t.sort = v_sort2, t.operuid = i_operuri, t.operunm = i_opername, t.operdate = SYSDATE WHERE t.tempid = v_tempid;
  
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
