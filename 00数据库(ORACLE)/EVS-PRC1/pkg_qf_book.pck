CREATE OR REPLACE PACKAGE pkg_qf_book IS
  /***************************************************************************************************
  名称     : pkg_qf_book
  功能描述 : 签发办理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-09  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询列表上显示的交换状态
  FUNCTION f_getsiteinfolist
  (
    i_id     VARCHAR2,
    i_objuri VARCHAR2
  ) RETURN VARCHAR2;

  -- 列表上显示的交换状态绿点
  FUNCTION f_getstatusimgstr
  (
    i_id     VARCHAR2,
    i_objuri VARCHAR2
  ) RETURN VARCHAR2;

  -- 查询列表上显示的自动签发业务
  FUNCTION f_getdealtype
  (
    i_id    VARCHAR2,
    i_dtype VARCHAR2
  ) RETURN VARCHAR2;

  -- 综合查询中获取状态列表
  PROCEDURE p_getstatuscode
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

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

  -- 增加-单个任务
  PROCEDURE p_ins2
  (
    i_dtype    IN VARCHAR2, -- 凭证单位标识
    i_otype    IN INT, -- (1:单位 0:个人)
    i_douri    IN VARCHAR2, -- 凭证单位标识
    i_doname   IN VARCHAR2, -- 凭证单位名称
    i_docode   IN VARCHAR2, -- 凭证单位机构代码/用户身份证号码
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 增加
  PROCEDURE p_ins
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
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

  -- 增加/删除/修改操作
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 修改接收对象
  PROCEDURE p_upd_backtype
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 打开时查询文件信息
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息
    o_info2    OUT VARCHAR2, -- 返回信息
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询签发印章信息
  PROCEDURE p_getsealinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 签发保存
  PROCEDURE p_save
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 检查单位、用户是否已签发
  PROCEDURE p_getselectobjids
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf_book IS

  -- 查询列表上显示的交换状态
  FUNCTION f_getsiteinfolist
  (
    i_id     VARCHAR2,
    i_objuri VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
    v_exists INT := 0;
    v_cnt    INT := 0;
  
    v_sitename        VARCHAR2(200);
    v_suri            VARCHAR2(64);
    v_sname           VARCHAR2(64);
    v_mysiteid        VARCHAR2(64);
    v_mysite_sitename VARCHAR2(128);
    v_mysite_suri     VARCHAR2(64);
    v_mysite_sname    VARCHAR2(128);
  
    v_exchid   VARCHAR2(64);
    v_sendtype VARCHAR2(8);
    v_toname   VARCHAR2(128);
    v_finished INT;
  BEGIN
    SELECT COUNT(1) INTO v_cnt FROM data_qf_task t WHERE t.pid = i_id;
    IF v_cnt <= 1 THEN
      BEGIN
        SELECT t.exchid
          INTO v_exchid
          FROM data_qf_send t
         WHERE t.pid = i_id
           AND t.sendtype = '1'
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      IF mystring.f_isnotnull(v_exchid) THEN
        RETURN pkg_exch_send.f_getsiteinfolist(v_exchid);
      END IF;
    END IF;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM data_qf_task t
             WHERE t.pid = i_id
               AND t.sendstatus = 0);
    IF v_exists = 0 THEN
      SELECT t.sendtype, t.exchid, t.toname, t.finished
        INTO v_sendtype, v_exchid, v_toname, v_finished
        FROM data_qf_send t
       WHERE t.pid = i_id
         AND t.isnew = 1
         AND rownum <= 1;
      IF v_sendtype = '1' THEN
        RETURN pkg_exch_send.f_getsiteinfolist(v_exchid);
      END IF;
    
      v_result := '[';
      v_result := mystring.f_concat(v_result, ' {"dealState":"已经处理","siteName":"', pkg_basic.f_getappname, '","status":"PS03"}');
      IF v_finished = 1 THEN
        v_result := mystring.f_concat(v_result, ',{"dealState":"已经处理","siteName":"', v_toname, '","status":"PS03"}');
      ELSE
        v_result := mystring.f_concat(v_result, ',{"dealState":"待处理","siteName":"', v_toname, '","status":"PS00"}');
      END IF;
      v_result := mystring.f_concat(v_result, ']');
      RETURN v_result;
    END IF;
  
    SELECT t.sitename, t.suri, t.sname, t.mysiteid
      INTO v_sitename, v_suri, v_sname, v_mysiteid
      FROM data_exch_to_info t
     WHERE t.objuri = i_objuri
       AND rownum <= 1;
  
    IF mystring.f_isnull(v_suri) THEN
      RETURN '[]';
    END IF;
  
    -- 本系统站点信息
    SELECT t.siteid, t.sitename INTO v_mysite_suri, v_mysite_sname FROM data_exch_mysite t WHERE t.siteid = v_mysiteid;
    IF mystring.f_isnull(v_mysite_suri) THEN
      RETURN '[]';
    END IF;
  
    v_mysite_sitename := pkg_basic.f_getconfig('cf01');
    IF mystring.f_isnull(v_mysite_sitename) THEN
      RETURN '[]';
    END IF;
  
    -- 返回信息
    v_result := '[';
    v_result := mystring.f_concat(v_result, ' {"dealState":"正在处理","siteName":"', v_mysite_sitename, '","status":"PS02"}');
    v_result := mystring.f_concat(v_result, ',{"dealState":"待处理","siteName":"', v_mysite_sname, '","status":"PS00"}');
    IF v_mysite_suri <> v_suri THEN
      v_result := mystring.f_concat(v_result, ',{"dealState":"待处理","siteName":"', v_sname, '","status":"PS00"}');
    END IF;
    v_result := mystring.f_concat(v_result, ',{"dealState":"待处理","siteName":"', v_sitename, '","status":"PS00"}');
    v_result := mystring.f_concat(v_result, ']');
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '[]';
  END;

  -- 列表上显示的交换状态绿点
  FUNCTION f_getstatusimgstr
  (
    i_id     VARCHAR2,
    i_objuri VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
    v_exists INT := 0;
    v_cnt    INT := 0;
  
    v_sitename        VARCHAR2(200);
    v_suri            VARCHAR2(64);
    v_sname           VARCHAR2(64);
    v_mysiteid        VARCHAR2(64);
    v_mysite_siteid   VARCHAR2(64);
    v_mysite_sitename VARCHAR2(128);
    v_mysite_suri     VARCHAR2(64);
    v_mysite_sname    VARCHAR2(128);
  
    v_exchid     VARCHAR2(64);
    v_sendtype   VARCHAR2(8);
    v_touri      VARCHAR2(64);
    v_toname     VARCHAR2(128);
    v_appid      VARCHAR2(64);
    v_appname    VARCHAR2(128);
    v_finished   INT;
    v_finishdate DATE;
    v_img        VARCHAR2(2000);
  BEGIN
    SELECT COUNT(1) INTO v_cnt FROM data_qf_task t WHERE t.pid = i_id;
    IF v_cnt <= 1 THEN
      BEGIN
        SELECT t.exchid
          INTO v_exchid
          FROM data_qf_send t
         WHERE t.pid = i_id
           AND t.sendtype = '1'
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      IF mystring.f_isnotnull(v_exchid) THEN
        RETURN pkg_exch_send.f_getstatusimgstr(v_exchid, i_id);
      END IF;
    END IF;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM data_qf_task t
             WHERE t.pid = i_id
               AND t.sendstatus = 0);
    IF v_exists = 0 THEN
      SELECT t.sendtype, t.exchid, t.touri, t.toname, t.finished, t.finishdate
        INTO v_sendtype, v_exchid, v_touri, v_toname, v_finished, v_finishdate
        FROM data_qf_send t
       WHERE t.pid = i_id
         AND t.isnew = 1
         AND rownum <= 1;
      IF v_sendtype = '1' THEN
        RETURN pkg_exch_send.f_getstatusimgstr(v_exchid, i_id);
      END IF;
    
      v_appid   := pkg_basic.f_getappid;
      v_appname := pkg_basic.f_getappname;
      v_result  := pkg_exch_send.f_getstatusimg(1, 'PS03', '已经处理', v_appid, v_appname, NULL, i_id);
      IF v_finished = 1 THEN
        v_img := pkg_exch_send.f_getstatusimg(2, 'PS03', '已经处理', v_touri, v_toname, v_finishdate, i_id);
      ELSE
        v_img := pkg_exch_send.f_getstatusimg(2, 'PS00', '待处理', v_touri, v_toname, NULL, i_id);
      END IF;
      v_result := mystring.f_concat(v_result, v_img);
      RETURN v_result;
    END IF;
  
    SELECT t.sitename, t.suri, t.sname, t.mysiteid
      INTO v_sitename, v_suri, v_sname, v_mysiteid
      FROM data_exch_to_info t
     WHERE t.objuri = i_objuri
       AND rownum <= 1;
  
    IF mystring.f_isnull(v_suri) THEN
      RETURN '';
    END IF;
  
    -- 本系统站点信息
    SELECT t.siteid, t.sitename INTO v_mysite_suri, v_mysite_sname FROM data_exch_mysite t WHERE t.siteid = v_mysiteid;
    IF mystring.f_isnull(v_mysite_suri) THEN
      RETURN '';
    END IF;
  
    v_mysite_siteid   := pkg_basic.f_getconfig('cf15');
    v_mysite_sitename := pkg_basic.f_getconfig('cf01');
    IF mystring.f_isnull(v_mysite_siteid) THEN
      RETURN '';
    END IF;
  
    v_result := pkg_exch_send.f_getstatusimg(1, 'PS02', '正在处理', v_mysite_siteid, v_mysite_sitename, NULL, i_id);
    v_img    := pkg_exch_send.f_getstatusimg(0, 'PS00', '待处理', v_mysite_suri, v_mysite_sname, NULL, i_id);
    v_result := mystring.f_concat(v_result, v_img);
    IF v_mysite_suri <> v_suri THEN
      v_img    := pkg_exch_send.f_getstatusimg(0, 'PS00', '待处理', v_suri, v_sname, NULL, i_id);
      v_result := mystring.f_concat(v_result, v_img);
    END IF;
    v_img    := pkg_exch_send.f_getstatusimg(2, 'PS00', '待处理', v_touri, v_toname, NULL, i_id);
    v_result := mystring.f_concat(v_result, v_img);
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询列表上显示的自动签发业务
  FUNCTION f_getdealtype
  (
    i_id    VARCHAR2,
    i_dtype VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(200);
    v_cnt    INT := 0;
    v_name   VARCHAR2(128);
  BEGIN
    SELECT COUNT(1) INTO v_cnt FROM data_qf_task t WHERE t.pid = i_id;
    IF v_cnt = 0 THEN
      RETURN '';
    END IF;
  
    DECLARE
      v_opertype VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t.opertype FROM data_qf_task t WHERE t.pid = i_id ORDER BY t.createddate, t.id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_opertype;
        EXIT WHEN v_cursor%NOTFOUND;
        v_name := NULL;
        IF v_opertype IN ('1', '2') THEN
          BEGIN
            SELECT t.name
              INTO v_name
              FROM info_template_qfoper t
             WHERE t.tempid = i_dtype
               AND t.pcode = v_opertype
               AND rownum <= 1;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
        ELSE
          BEGIN
            SELECT t.name
              INTO v_name
              FROM info_template_qfoper t
             WHERE t.tempid = i_dtype
               AND t.code = v_opertype
               AND rownum <= 1;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
        END IF;
      
        IF mystring.f_isnotnull(v_name) THEN
          IF mystring.f_isnull(v_result) THEN
            v_result := v_name;
          ELSE
            v_result := mystring.f_concat(v_result, ',', v_name);
          END IF;
        END IF;
        EXIT;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
    END;
  
    IF v_cnt > 1 THEN
      v_result := mystring.f_concat(v_result, '...等', v_cnt, '个业务');
    END IF;
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 综合查询中获取状态列表
  PROCEDURE p_getstatuscode
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_pcode   VARCHAR2(64);
    v_code    VARCHAR2(8);
    v_name    VARCHAR2(64);
    v_attrib1 VARCHAR2(256);
    v_num     INT := 0;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.i_code') INTO v_pcode FROM dual;
    mydebug.wlog('v_pcode', v_pcode);
  
    o_info := '[';
    DECLARE
      CURSOR v_cursor IS
        SELECT t.code, t.name, t.attrib1 FROM sys_code_info t WHERE instr(t.code, v_pcode) > 0 ORDER BY t.attrib2;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_code, v_name, v_attrib1;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, '{');
        o_info := mystring.f_concat(o_info, ' "code":"', v_code, '"');
        o_info := mystring.f_concat(o_info, ',"name":"', v_name, '"');
        o_info := mystring.f_concat(o_info, ',"attrib1":"', v_attrib1, '"');
        o_info := mystring.f_concat(o_info, '}');
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
    END;
  
    o_info := mystring.f_concat(o_info, ']');
  
    mydebug.wlog('o_info', o_info);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_info := NULL;
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
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
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_row_rn           INT;
    v_row_id           VARCHAR2(64); -- 办理标识
    v_row_status       VARCHAR2(8); -- 办理状态
    v_row_statusname   VARCHAR2(16); -- 办理状态
    v_row_dealtype     VARCHAR2(128); -- 自动签发业务
    v_row_douri        VARCHAR2(64);
    v_row_doname       VARCHAR2(128);
    v_row_pzflag       INT;
    v_row_booktype     INT; -- 是否存在申请信息(1:是 0:否)
    v_row_backtype     VARCHAR2(8);
    v_row_backname     VARCHAR2(128);
    v_row_applystatus  INT; -- 是否收到申请文件(1:是 0:否)
    v_row_filename     VARCHAR2(128);
    v_row_siteinfolist VARCHAR2(4000);
    v_row_statusimgstr VARCHAR2(4000);
    v_row_createddate  DATE;
    v_row_opername     VARCHAR2(64);
    v_row_ver          VARCHAR2(32);
  
    v_row_otype INT;
    v_pz_id     VARCHAR2(64);
  
    v_dtype            VARCHAR2(64);
    v_kindid           VARCHAR2(64);
    v_conditions       VARCHAR2(4000);
    v_cs_doname        VARCHAR2(200);
    v_cs_status        VARCHAR2(8);
    v_cs_modifieddate1 VARCHAR2(32);
    v_cs_modifieddate2 VARCHAR2(32);
  BEGIN
    mydebug.wlog('开始');
    -- 验证用户权限
    pkg_qp_verify.p_check('MD110', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_kindid') INTO v_kindid FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/condition/others/doname') INTO v_cs_doname FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/status') INTO v_cs_status FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/modifieddate1') INTO v_cs_modifieddate1 FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/modifieddate2') INTO v_cs_modifieddate2 FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select id,status,createddate FROM data_qf_book E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.dtype= ''', v_dtype, ''' ');
  
    IF mystring.f_isnotnull(v_kindid) THEN
      IF v_kindid <> 'otherRootE' THEN
        IF v_kindid = 'root' THEN
          v_sql := mystring.f_concat(v_sql, ' and exists(select 1 from info_register_obj w where w.objid = E1.douri)');
        ELSE
          v_sql := mystring.f_concat(v_sql, ' and exists(select 1 from info_register_obj w where instr(w.kindidpath,''', v_kindid, ''') > 0 and w.objid = E1.douri)');
        END IF;
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_cs_doname) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.doname, ''', v_cs_doname, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_status) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.status = ''', v_cs_status, '''');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_modifieddate1) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.createddate >= to_date(''', v_cs_modifieddate1, ''', ''yyyy-mm-dd'')');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_modifieddate2) THEN
      v_cs_modifieddate2 := mydate.f_addday_str(v_cs_modifieddate2, 1);
    
      v_sql := mystring.f_concat(v_sql, ' AND E1.createddate < to_date(''', v_cs_modifieddate2, ''', ''yyyy-mm-dd'')');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL
    v_sql := mystring.f_concat(v_sql, ' ORDER BY status,createddate DESC,id desc ');
    v_sql := myquery.f_getpagesql(v_sql, v_pagesize, v_pagenum);
    mydebug.wlog('v_sql', v_sql);
  
    -- 分页起始编号
    v_row_rn := myquery.f_getpagestartnum(v_pagesize, v_pagenum);
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, myquery.f_getpagenation(v_cnt, v_pagesize, v_pagenum));
    dbms_lob.append(o_info, ',"dataList":[');
  
    -- 执行sql
    DECLARE
      v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果
    BEGIN
      OPEN v_cursor FOR v_sql;
      LOOP
        FETCH v_cursor
          INTO v_row_id, v_row_status, v_row_createddate;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT otype, douri, doname, backtype, backappname, opername, ver
          INTO v_row_otype, v_row_douri, v_row_doname, v_row_backtype, v_row_backname, v_row_opername, v_row_ver
          FROM data_qf_book
         WHERE id = v_row_id;
      
        v_pz_id := NULL;
        BEGIN
          SELECT id
            INTO v_pz_id
            FROM data_qf_pz t
           WHERE t.pid = v_row_id
             AND rownum <= 1;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      
        v_row_statusname := pkg_basic.f_codevalue(v_row_status);
        v_row_dealtype   := pkg_qf_book.f_getdealtype(v_row_id, v_dtype);
      
        IF mystring.f_isnull(v_pz_id) THEN
          v_row_pzflag := 0;
        ELSE
          v_row_pzflag := 1;
        END IF;
      
        IF v_row_backtype = '0' THEN
          IF v_row_otype = 1 THEN
            v_row_backname := '单位空间';
          ELSIF v_row_otype = 0 THEN
            v_row_backname := '个人空间';
          ELSE
            v_row_backname := '数字空间';
          END IF;
        END IF;
      
        v_row_filename     := pkg_file0.f_getfilename_docid(v_pz_id, 2);
        v_row_siteinfolist := pkg_qf_book.f_getsiteinfolist(v_row_id, v_row_douri);
        v_row_statusimgstr := pkg_qf_book.f_getstatusimgstr(v_row_id, v_row_douri);
      
        -- 是否存在申请信息(1:是 0:否)
        SELECT COUNT(1)
          INTO v_row_booktype
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_qf_task t
                 WHERE t.pid = v_row_id
                   AND t.fromtype = '1'
                   AND t.sendstatus = 0);
        v_row_booktype := 0;
      
        -- 是否收到申请文件(1:是 0:否)
        SELECT COUNT(1)
          INTO v_row_applystatus
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_qf_notice_applyinfo t
                 WHERE t.dtype = v_dtype
                   AND t.fromuri = v_row_douri);
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"id":"', v_row_id, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"status":"', v_row_status, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"statusname":"', v_row_statusname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"dealtype":"', v_row_dealtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"douri":"', v_row_douri, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"doname":"', myjson.f_escape(v_row_doname), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"pzflag":"', v_row_pzflag, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"booktype":"', v_row_booktype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"backtype":"', v_row_backtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"backname":"', v_row_backname, '"'));
        dbms_lob.append(o_info, ',"mflag":"0"');
        dbms_lob.append(o_info, mystring.f_concat(',"dtype":"', v_dtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"evtype":"', v_dtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"applystatus":"', v_row_applystatus, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"filename":"', v_row_filename, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"siteInfoList":', v_row_siteinfolist));
        dbms_lob.append(o_info, mystring.f_concat(',"statusImgStr":"', myjson.f_escape(v_row_statusimgstr), '"'));
        dbms_lob.append(o_info, ',"lastSitType":"NT01"');
        dbms_lob.append(o_info, ',"cancleSitId":""');
        dbms_lob.append(o_info, ',"curstatus":"0"');
        dbms_lob.append(o_info, mystring.f_concat(',"modifieddate":"', to_char(v_row_createddate, 'yyyy-mm-dd hh24:mi'), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"opername":"', v_row_opername, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"ver":"', v_row_ver, '"'));
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
    dbms_lob.append(o_info, ',"menuList": [{"code": "MS000000","num": "0","name": "签发办理"}]');
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

  -- 增加-单个任务
  PROCEDURE p_ins2
  (
    i_dtype    IN VARCHAR2, -- 凭证单位标识
    i_otype    IN INT, -- (1:单位 0:个人)
    i_douri    IN VARCHAR2, -- 凭证单位标识
    i_doname   IN VARCHAR2, -- 凭证单位名称
    i_docode   IN VARCHAR2, -- 凭证单位机构代码/用户身份证号码
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id     VARCHAR2(64);
    v_docode VARCHAR2(128);
  
    v_pz_id        VARCHAR2(128); -- 唯一标识
    v_pz_num_start INT; -- 起始编号
    v_pz_num_end   INT; -- 终止编号
    v_pz_num_count INT; -- 票据份数
    v_pz_billcode  VARCHAR2(64); -- 票据编码
    v_pz_billorg   VARCHAR2(128); -- 印制机构
  BEGIN
  
    -- 加锁
    UPDATE info_template_bind t SET t.modifieddate = SYSDATE WHERE t.id = i_dtype;
  
    mydebug.wlog('i_douri', i_douri);
    mydebug.wlog('i_doname', i_doname);
    mydebug.wlog('i_docode', i_docode);
  
    IF mystring.f_isnull(i_doname) THEN
      o_code := 'EC02';
      o_msg  := '单位/个人名称为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 使用1张空白凭证
    pkg_yz_pz_pbl.p_use(i_dtype, v_pz_id, v_pz_num_start, v_pz_num_end, v_pz_num_count, v_pz_billcode, v_pz_billorg, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    IF mystring.f_isnotnull(i_docode) THEN
      v_docode := i_docode;
    ELSE
      v_docode := pkg_info_register_pbl.f_getobjcode(i_douri);
    END IF;
  
    v_id := pkg_basic.f_newid('GG');
    INSERT INTO data_qf_book
      (id, dtype, otype, douri, doname, docode, backtype, status, booktype, operuri, opername)
    VALUES
      (v_id, i_dtype, i_otype, i_douri, i_doname, v_docode, '0', 'GG01', '0', i_operuri, i_opername);
  
    INSERT INTO data_qf_pz
      (id, pid, dtype, num_start, num_end, num_count, billcode, billorg, operuri, opername)
    VALUES
      (v_pz_id, v_id, i_dtype, v_pz_num_start, v_pz_num_end, v_pz_num_count, v_pz_billcode, v_pz_billorg, i_operuri, i_opername);
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '处理失败，请检查！';
      mydebug.err(7);
  END;

  -- 增加
  PROCEDURE p_ins
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype VARCHAR2(64);
    v_data  VARCHAR2(4000);
    v_xml   xmltype;
    v_i     INT := 0;
    v_xpath VARCHAR2(200);
  
    v_douri  VARCHAR2(64); -- 凭证单位标识
    v_doname VARCHAR2(128); -- 凭证单位名称
    v_docode VARCHAR2(128); -- 凭证单位机构代码/用户身份证号码
  
    v_exists INT := 0;
  
    v_otype INT;
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD110', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.selectData') INTO v_data FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_data', v_data);
  
    v_otype := pkg_info_template_pbl.f_getotype(v_dtype);
  
    v_xml := xmltype(v_data);
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      v_xpath := mystring.f_concat('/datas/data[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'uri')) INTO v_douri FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'name')) INTO v_doname FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'code')) INTO v_docode FROM dual;
      IF mystring.f_isnull(v_douri) THEN
        v_i := 100;
      ELSE
        mydebug.wlog('v_douri', v_douri);
        mydebug.wlog('v_doname', v_doname);
        mydebug.wlog('v_docode', v_docode);
      
        SELECT COUNT(1)
          INTO v_exists
          FROM (SELECT 1
                  FROM data_qf_book t
                 WHERE t.dtype = v_dtype
                   AND t.douri = v_douri) q;
        IF v_exists = 0 THEN
          pkg_qf_book.p_ins2(v_dtype, v_otype, v_douri, v_doname, v_docode, i_operuri, i_opername, o_code, o_msg);
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
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '处理失败，请检查！';
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
    v_data VARCHAR2(4000);
    v_id   VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD110', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.selectData') INTO v_data FROM dual;
    mydebug.wlog('v_data', v_data);
  
    IF mystring.f_isnull(v_data) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT myxml.f_getvalue(v_data, '/datas/data[1]/uri') INTO v_id FROM dual;
    mydebug.wlog('v_id', v_id);
  
    IF mystring.f_isnull(v_id) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DECLARE
      v_exists INT := 0;
    BEGIN
      SELECT COUNT(1) INTO v_exists FROM data_qf_book t WHERE t.id = v_id;
      IF v_exists = 0 THEN
        o_code := 'EC02';
        o_msg  := '未找到签发件信息！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    -- 检查是否被锁定
    pkg_lock.p_check(v_id, i_operuri, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    /*IF r_data_qf_book.booktype = '1' THEN
      IF r_data_qf_book.status IN ('GG01', 'GG02', 'GG03') THEN
        o_code := 'EC02';
        o_msg  := '在办理的申领信息不能删除,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    ELSE
      IF r_data_qf_book.status IN ('GG02', 'GG03') THEN
        o_code := 'EC02';
        o_msg  := '该凭证已发送,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END IF;*/
  
    o_code := 'EC00';
  
    -- 删除凭证
    DECLARE
      v_pzid VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t.id FROM data_qf_pz t WHERE t.pid = v_id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_pzid;
        EXIT WHEN v_cursor%NOTFOUND;
        pkg_file0.p_del_docid(v_pzid, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          EXIT;
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        o_code := 'EC03';
        o_msg  := '处理失败，请检查！';
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
  
    DELETE FROM data_qf_pz WHERE pid = v_id;
  
    -- 删除发送记录
    DECLARE
      v_send_id     VARCHAR2(64);
      v_send_fileid VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t.id, t.fileid FROM data_qf_send t WHERE t.pid = v_id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_send_id, v_send_fileid;
        EXIT WHEN v_cursor%NOTFOUND;
        DELETE FROM data_qf_app_sendqueue WHERE id = v_send_id;
        DELETE FROM data_qf_app_sendinfo WHERE id = v_send_id;
        pkg_file0.p_del(v_send_fileid, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          EXIT;
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        o_code := 'EC03';
        o_msg  := '处理失败，请检查！';
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
  
    DELETE FROM data_qf_send WHERE pid = v_id;
  
    -- 删除签发任务
    o_code := 'EC00';
    DECLARE
      v_task_file_fileid VARCHAR2(64);
      v_task_file_id     VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t2.fileid, t2.id FROM data_qf_task t1 INNER JOIN data_qf_task_file t2 ON (t2.pid = t1.id) WHERE t1.pid = v_id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_task_file_fileid, v_task_file_id;
        EXIT WHEN v_cursor%NOTFOUND;
        pkg_file0.p_del(v_task_file_fileid, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          EXIT;
        END IF;
        DELETE FROM data_qf_task_file WHERE id = v_task_file_id;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        o_code := 'EC03';
        o_msg  := '处理失败，请检查！';
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
  
    DELETE FROM data_qf_task_data WHERE id IN (SELECT id FROM data_qf_task WHERE pid = v_id);
    DELETE FROM data_qf_task WHERE pid = v_id;
  
    -- 删除通知
    DECLARE
      v_dtype VARCHAR2(64);
      v_douri VARCHAR2(64);
    BEGIN
      SELECT dtype, douri INTO v_dtype, v_douri FROM data_qf_book WHERE id = v_id;
      DELETE FROM data_qf_notice_applyinfo
       WHERE dtype = v_dtype
         AND fromuri = v_douri;
      DELETE FROM data_qf_notice_send
       WHERE dtype = v_dtype
         AND touri = v_douri;
    END;
  
    DELETE FROM data_qf_app_recinfo WHERE pid = v_id;
  
    DELETE FROM data_qf_queue WHERE id = v_id;
  
    DELETE FROM data_qf_book WHERE id = v_id;
  
    -- 删除交换队列数据
    pkg_x_s.p_del_docid(v_id, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '处理失败，请检查！';
      mydebug.err(7);
  END;

  -- 增加/删除/修改操作
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_type VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
    SELECT json_value(i_forminfo, '$.i_opertype') INTO v_type FROM dual;
    mydebug.wlog('v_type', v_type);
  
    IF v_type = '1' THEN
      pkg_qf_book.p_ins(i_forminfo, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSIF v_type = '0' THEN
      pkg_qf_book.p_del(i_forminfo, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    END IF;
  
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '处理失败，请检查！';
      mydebug.err(7);
  END;

  -- 修改接收对象
  PROCEDURE p_upd_backtype
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_type    VARCHAR2(8); -- 操作类型 1：修改为应用系统 2：恢复默认空间
    v_id      VARCHAR2(64); -- 标识
    v_appuri  VARCHAR2(64); -- 系统标识
    v_appname VARCHAR2(128); -- 系统名称
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
    SELECT json_value(i_forminfo, '$.i_id') INTO v_id FROM dual;
    SELECT json_value(i_forminfo, '$.i_appuri') INTO v_appuri FROM dual;
    SELECT json_value(i_forminfo, '$.i_appname') INTO v_appname FROM dual;
    mydebug.wlog('v_type', v_type);
    mydebug.wlog('v_id', v_id);
    mydebug.wlog('v_appuri', v_appuri);
    mydebug.wlog('v_appname', v_appname);
  
    DECLARE
      v_exists INT := 0;
    BEGIN
      SELECT COUNT(1) INTO v_exists FROM data_qf_book t WHERE t.id = v_id;
      IF v_exists = 0 THEN
        o_code := 'EC02';
        o_msg  := '未找到签发件信息！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    DECLARE
      v_booktype VARCHAR2(8);
    BEGIN
      SELECT booktype INTO v_booktype FROM data_qf_book t WHERE t.id = v_id;
      IF v_booktype = '1' THEN
        o_code := 'EC02';
        o_msg  := '该签发件不能修改退回发送！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    IF v_type = '1' THEN
      UPDATE data_qf_book t SET t.backappuri = v_appuri, t.backappname = v_appname, t.backtype = '1' WHERE t.id = v_id;
    ELSIF v_type = '2' THEN
      UPDATE data_qf_book t SET t.backappuri = NULL, t.backappname = NULL, t.backtype = '0' WHERE t.id = v_id;
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_qf_book.p_getinfo
  功能描述 : 打开时查询文件信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-10  唐金鑫  创建
  
  业务说明
  <info>
      <id>唯一标识</id>
      <douri>持有者标识</douri>
      <doname>持有者名称</doname>
      <webflag>是否WEB方式</webflag>
      <weburl>WEB方式路径</weburl>
      <dtype>大类代码</dtype>
      <evtype>小类代码</evtype>
      <filename>凭证文件名</filename>
      <filepath>凭证文件路径</filepath>
      <role>签发角色，调用凭证接口SetUserRole传入凭证</role>
      <issuepart>签发模式(0:发送整本凭证 1:发送增量数据)，调用接口SetIssuePart传入凭证</issuepart>
      <issueragency>签发单位</issueragency>
      <signseal>个人签名印章</signseal>
      <bases>首签基础参数，通过接口 SetRegisterData()导入凭证</bases>
      <dstype>是否存在需要通过接口ImportFlowData处理的签发数据(1:是 0:否)</dstype>
      <flowdata>通过接口ImportFlowData传入的签发数据</flowdata>
      <ds>
        <d>
          <type>子节点标签</type>
          <v>首签使用的签发私有参数</v>
        </d>
      </ds>
      <files>
        <file>
          <fromtype>文件来源类型(1:应用系统 2:数字空间 3:TDS 4:批量导入)</fromtype>
          <type>业务标识=flowdata里面的//flow/@type</type>
          <filename>文件名</filename>
          <filepath>文件路径</filepath>
        </file>
      </files>
      <seals>
        <!-- 印章集合-- >
        <seal>
          <label></label>
          <name></name>
          <pin></pin>
          <pack></pack>
        </seal>
      </seals>
      <forms>
        <!-- 签发数据的页面信息-- >
        <form>
          <formid>页面编号</formid>
          <formname>页面名称</formname>
          <tag>印章标签</tag>
          <label>印章标签</label>
          <type>印章类型</type>
          <desc>印章名称</desc>
        </form>
      </forms>
      <ver>版本信息</ver>
  </info>
  ***************************************************************************************************/
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息
    o_info2    OUT VARCHAR2, -- 返回信息
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id          VARCHAR2(64);
    v_lstver      INT; -- 缓存文件版本
    v_cache_exist INT; -- 缓存文件是否已存在
    v_iscache     INT; -- 是否需要缓存文件
    v_file_status INT := 0;
    v_exists      INT := 0;
    v_num         INT := 0;
    v_appid       VARCHAR2(64);
  
    -- 首签基础参数
    v_bases_holdercode VARCHAR2(64); -- 持证者编码(个人身份证号/统一社会信用代码)
    v_bases_holdername VARCHAR2(128); -- 持证者名称(用户姓名/单位名称)
    v_bases_issuercode VARCHAR2(64); -- 签发者编码(统一社会信用代码)
    v_bases_issuername VARCHAR2(128); -- 签发者名称(单位名称)
  
    v_info_comid     VARCHAR2(64); -- 机构标识
    v_info_douri     VARCHAR2(64); -- 持有者标识
    v_info_doname    VARCHAR2(128); -- 持有者名称
    v_info_routeflag INT; -- 如果是交换则是否有路由(1:是 0:否)
    v_info_dtype     VARCHAR2(64); -- 大类代码
    v_info_bookid    VARCHAR2(64); -- 登记证标识
    v_info_filename  VARCHAR2(64); -- 空白凭证文件名
    v_info_filepath  VARCHAR2(256); -- 空白凭证文件路径
    v_info_role      VARCHAR2(64); -- 签发角色，调用凭证接口SetUserRole传入凭证
    v_info_issuepart VARCHAR2(8); -- 签发模式(0:发送整本凭证 1:发送增量数据)，调用接口SetIssuePart传入凭证
    v_info_signseal  CLOB; -- 个人签名印章
    v_info_bases     VARCHAR2(2000); -- 首签基础参数
    v_info_ver       INT; -- 版本信息
    v_lockcode       VARCHAR2(128);
    v_lockmsg        VARCHAR2(2000);
  
    v_info_dstype     INT := 0; -- 是否存在需要通过接口ImportFlowData处理的签发数据(1:是 0:否)
    v_info_forms      VARCHAR2(32767); -- 签发数据的页面信息
    v_flow_name       VARCHAR2(64);
    v_flow_v          VARCHAR2(32767);
    v_qf_opertype_all VARCHAR2(256) := '|';
    v_task_data_items CLOB;
    v_task_id         VARCHAR2(64);
    v_task_opertype   VARCHAR2(64);
    v_task_sendstatus INT;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD110', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.docId') INTO v_id FROM dual;
    SELECT json_value(i_forminfo, '$.lstver') INTO v_lstver FROM dual;
    SELECT json_value(i_forminfo, '$.iscache') INTO v_iscache FROM dual;
    SELECT json_value(i_forminfo, '$.cache_exist') INTO v_cache_exist FROM dual;
    mydebug.wlog('v_id', v_id);
    mydebug.wlog('v_lstver', mystring.f_concat('v_lstver=', v_lstver));
    mydebug.wlog('v_iscache', mystring.f_concat('v_iscache=', v_iscache));
    mydebug.wlog('v_cache_exist', mystring.f_concat('v_cache_exist=', v_cache_exist));
  
    IF mystring.f_isnull(v_id) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_lstver IS NULL THEN
      v_lstver := 0;
    END IF;
  
    pkg_lock.p_lock(v_id, '', i_operuri, i_opername, v_lockcode, v_lockmsg);
  
    SELECT COUNT(1) INTO v_exists FROM data_qf_book t WHERE t.id = v_id;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT douri, doname, dtype, ver INTO v_info_douri, v_info_doname, v_info_dtype, v_info_ver FROM data_qf_book t WHERE t.id = v_id;
    IF mystring.f_isnull(v_info_douri) THEN
      o_code := 'EC02';
      o_msg  := '正在注册空间号,请等待！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_appid := pkg_basic.f_getappid;
  
    -- 使用1张空白凭证
    pkg_qf_pbl.p_usepz(v_id, v_info_dtype, o_code, o_msg, v_info_filename, v_info_filepath);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    -- 检查路由
    v_info_routeflag := pkg_exch_to_site.f_check(v_info_douri);
  
    -- 当前登录人签名
    v_info_signseal := pkg_info_admin6.f_getseal(i_operuri);
  
    -- 首签基础参数
    SELECT docode, doname INTO v_bases_holdercode, v_bases_holdername FROM data_qf_book t WHERE t.id = v_id;
    BEGIN
      SELECT sqdcode, sqdnm INTO v_bases_issuercode, v_bases_issuername FROM info_template_bind t WHERE t.id = v_info_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_info_bases := '<bases>';
    v_info_bases := mystring.f_concat(v_info_bases, '<item tag="HolderCode"><value>', v_bases_holdercode, '</value></item>');
    v_info_bases := mystring.f_concat(v_info_bases, '<item tag="HolderName"><value>', v_bases_holdername, '</value></item>');
    v_info_bases := mystring.f_concat(v_info_bases, '<item tag="IssuerCode"><value>', v_bases_issuercode, '</value></item>');
    v_info_bases := mystring.f_concat(v_info_bases, '<item tag="IssuerName"><value>', v_bases_issuername, '</value></item>');
    v_info_bases := mystring.f_concat(v_info_bases, '</bases>');
  
    -- 签发角色，调用凭证接口SetUserRole传入凭证
    v_info_role := pkg_info_template_pbl.f_getrole(v_info_dtype);
  
    -- 签发模式(0:发送整本凭证 1:发送增量数据)，调用接口SetIssuePart传入凭证
    v_info_issuepart := pkg_qf_config.f_getissuepart(v_info_dtype);
  
    dbms_lob.createtemporary(o_info1, TRUE);
    dbms_lob.append(o_info1, '{');
    dbms_lob.append(o_info1, mystring.f_concat(' "id":"', v_id, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"comid":"', v_info_comid, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"douri":"', v_info_douri, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"doname":"', myjson.f_escape(v_info_doname), '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"routeflag":"', v_info_routeflag, '"'));
    dbms_lob.append(o_info1, ',"routeflagcz":"1"');
    dbms_lob.append(o_info1, ',"webflag":"0"');
    dbms_lob.append(o_info1, mystring.f_concat(',"dtype":"', v_info_dtype, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"evtype":"', v_info_dtype, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"bookid":"', v_info_bookid, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"ver":"', v_info_ver, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"filename":"', v_info_filename, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"filepath":"', myjson.f_escape(v_info_filepath), '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"role":"', v_info_role, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"issuepart":"', v_info_issuepart, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"issueragency":"', v_bases_issuername, '"'));
    dbms_lob.append(o_info1, ',"signseal":"');
    IF mystring.f_isnotnull(v_info_signseal) THEN
      dbms_lob.append(o_info1, v_info_signseal);
    END IF;
    dbms_lob.append(o_info1, '"');
    dbms_lob.append(o_info1, mystring.f_concat(',"bases":"', myjson.f_escape(v_info_bases), '"'));
  
    -- 首签使用的签发私有参数
    dbms_lob.append(o_info1, ',"signDataList":[');
    v_num := 0;
    DECLARE
      v_prvdata_sectioncode VARCHAR2(64);
      v_prvdata_sectionname VARCHAR2(64);
      v_prvdata_items2      CLOB;
      v_prvdata_files       CLOB;
      CURSOR v_cursor IS
        SELECT t.sectioncode, t.sectionname, t.items2, t.files
          FROM info_template_prvdata t
         WHERE t.tempid = v_info_dtype
           AND t.datatype = '2';
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_prvdata_sectioncode, v_prvdata_sectionname, v_prvdata_items2, v_prvdata_files;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info1, ',');
        END IF;
        dbms_lob.append(o_info1, '{');
        dbms_lob.append(o_info1, mystring.f_concat(' "type":"', v_prvdata_sectioncode, '"'));
        dbms_lob.append(o_info1, ',"data":"');
        dbms_lob.append(o_info1, '<v>');
        dbms_lob.append(o_info1, mystring.f_concat('<section code=\"', v_prvdata_sectioncode, '\" name=\"', v_prvdata_sectionname, '\" >'));
        IF mystring.f_isnotnull(v_prvdata_items2) THEN
          dbms_lob.append(o_info1, myjson.f_escape(v_prvdata_items2));
        END IF;
        IF mystring.f_isnotnull(v_prvdata_files) THEN
          dbms_lob.append(o_info1, myjson.f_escape(v_prvdata_files));
        END IF;
        dbms_lob.append(o_info1, '</section>');
        dbms_lob.append(o_info1, '</v>');
        dbms_lob.append(o_info1, '"');
        dbms_lob.append(o_info1, '}');
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
  
    dbms_lob.append(o_info1, ']');
  
    -- 是否存在需要通过接口ImportFlowData处理的签发数据(1:是 0:否)
    IF v_lockcode = 'EC00' THEN
      SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_qf_send t WHERE t.pid = v_id);
      IF v_exists = 0 THEN
        -- 未签发过，必须先首签
        SELECT COUNT(1)
          INTO v_info_dstype
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_qf_task t
                 WHERE t.pid = v_id
                   AND t.sendstatus = 0
                   AND t.opertype = '1');
      ELSE
        SELECT COUNT(1)
          INTO v_info_dstype
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_qf_task t
                 WHERE t.pid = v_id
                   AND t.sendstatus = 0);
      END IF;
    END IF;
  
    IF v_info_dstype > 0 THEN
      DELETE FROM data_qf_task_tmp WHERE pid = v_id;
    
      -- 通过接口ImportFlowData传入的签发数据
      dbms_lob.append(o_info1, ',"dstype":"1"');
      dbms_lob.append(o_info1, ',"flowdata":"');
      dbms_lob.append(o_info1, '<datas>');
    
      SELECT q.id, q.opertype, q.sendstatus
        INTO v_task_id, v_task_opertype, v_task_sendstatus
        FROM (SELECT t.*
                FROM data_qf_task t
               WHERE t.pid = v_id
                 AND t.opertype = '1'
               ORDER BY t.sendstatus, t.createddate, t.id) q
       WHERE rownum <= 1;
      IF v_task_sendstatus = 0 THEN
        INSERT INTO data_qf_task_tmp (id, pid) VALUES (v_task_id, v_id);
      
        BEGIN
          SELECT items INTO v_task_data_items FROM data_qf_task_data t WHERE t.id = v_task_id;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      
        v_flow_name := pkg_info_template_pbl.f_getqfopername(v_info_dtype, v_task_opertype);
        v_flow_v    := myxml.f_getnode_str(v_task_data_items, '/template/*');
      
        dbms_lob.append(o_info1, '<flow');
        dbms_lob.append(o_info1, mystring.f_concat(' type = \"', v_task_opertype, '\"'));
        dbms_lob.append(o_info1, mystring.f_concat(' name = \"', v_flow_name, '\"'));
        IF v_task_opertype = '1' THEN
          dbms_lob.append(o_info1, ' flag = \"1\"');
        END IF;
        dbms_lob.append(o_info1, ' >');
        IF v_task_opertype = '1' THEN
          dbms_lob.append(o_info1, myjson.f_escape(v_info_bases));
        END IF;
        IF mystring.f_isnotnull(v_flow_v) THEN
          dbms_lob.append(o_info1, myjson.f_escape(v_flow_v));
        END IF;
        dbms_lob.append(o_info1, '</flow>');
      END IF;
    
      DECLARE
        CURSOR v_cursor IS
          SELECT t.id, t.opertype
            FROM data_qf_task t
           WHERE t.pid = v_id
             AND t.sendstatus = 0
             AND t.id <> v_task_id
           ORDER BY createddate, id;
      BEGIN
        OPEN v_cursor;
        LOOP
          FETCH v_cursor
            INTO v_task_id, v_task_opertype;
          EXIT WHEN v_cursor%NOTFOUND;
          INSERT INTO data_qf_task_tmp (id, pid) VALUES (v_task_id, v_id);
        
          v_task_data_items := NULL;
          BEGIN
            SELECT items INTO v_task_data_items FROM data_qf_task_data t WHERE t.id = v_task_id;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
        
          v_flow_name := pkg_info_template_pbl.f_getqfopername(v_info_dtype, v_task_opertype);
          v_flow_v    := myxml.f_getnode_str(v_task_data_items, '/template/*');
        
          dbms_lob.append(o_info1, '<flow');
          dbms_lob.append(o_info1, mystring.f_concat(' type = \"', v_task_opertype, '\"'));
          dbms_lob.append(o_info1, mystring.f_concat(' name = \"', v_flow_name, '\"'));
          IF v_task_opertype = '1' THEN
            dbms_lob.append(o_info1, ' flag = \"1\"');
          END IF;
          dbms_lob.append(o_info1, ' >');
          IF v_task_opertype = '1' THEN
            dbms_lob.append(o_info1, myjson.f_escape(v_info_bases));
          END IF;
          IF mystring.f_isnotnull(v_flow_v) THEN
            dbms_lob.append(o_info1, myjson.f_escape(v_flow_v));
          END IF;
          dbms_lob.append(o_info1, '</flow>');
        
          IF mystring.f_instr(v_qf_opertype_all, mystring.f_concat('|', v_task_opertype, '|')) = 0 THEN
            v_qf_opertype_all := mystring.f_concat(v_qf_opertype_all, v_task_opertype, '|');
          END IF;
        END LOOP;
        CLOSE v_cursor;
      EXCEPTION
        WHEN OTHERS THEN
          IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
          END IF;
          mydebug.err(7);
          ROLLBACK;
          o_info1 := NULL;
          o_info2 := NULL;
          o_code  := 'EC00';
          o_msg   := '处理成功';
          mydebug.err(7);
          RETURN;
      END;
      dbms_lob.append(o_info1, '</datas>');
      dbms_lob.append(o_info1, '"');
    
      -- 附件
      dbms_lob.append(o_info1, ',"certFileList":[');
      v_num := 0;
      DECLARE
        v_certfilelist_fromtype VARCHAR2(64);
        v_certfilelist_opertype VARCHAR2(64);
        v_certfilelist_fileid   VARCHAR2(64);
        CURSOR v_cursor IS
          SELECT t1.fromtype, t1.opertype, t2.fileid
            FROM data_qf_task t1
           INNER JOIN data_qf_task_file t2
              ON (t2.pid = t1.id)
           WHERE t1.pid = v_id
             AND t1.sendstatus = 0;
      BEGIN
        OPEN v_cursor;
        LOOP
          FETCH v_cursor
            INTO v_certfilelist_fromtype, v_certfilelist_opertype, v_certfilelist_fileid;
          EXIT WHEN v_cursor%NOTFOUND;
          v_num := v_num + 1;
          IF v_num > 1 THEN
            dbms_lob.append(o_info1, ',');
          END IF;
          dbms_lob.append(o_info1, '{');
          dbms_lob.append(o_info1, mystring.f_concat(' "fromtype":"', v_certfilelist_fromtype, '"'));
          dbms_lob.append(o_info1, mystring.f_concat(',"type":"', v_certfilelist_opertype, '"'));
          dbms_lob.append(o_info1, mystring.f_concat(',"filename":"', pkg_file0.f_getfilename(v_certfilelist_fileid), '"'));
          dbms_lob.append(o_info1, mystring.f_concat(',"filepath":"', myjson.f_escape(pkg_file0.f_getfilepath(v_certfilelist_fileid)), '"'));
          dbms_lob.append(o_info1, '}');
        END LOOP;
        CLOSE v_cursor;
      EXCEPTION
        WHEN OTHERS THEN
          IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
          END IF;
          mydebug.err(7);
      END;
      dbms_lob.append(o_info1, ']');
    
      -- 签发数据的页面信息
      v_info_forms := ',"formList":[';
      v_num        := 0;
    
      DECLARE
        v_qfoper_name0   VARCHAR2(128);
        v_qfoper_code    VARCHAR2(128);
        v_qfoper_pcode   VARCHAR2(128);
        v_form_id        VARCHAR2(64);
        v_form_sealtype  VARCHAR2(8);
        v_form_sealtag   VARCHAR2(64);
        v_form_seallabel VARCHAR2(64);
        v_form_sealdesc  VARCHAR2(128);
        CURSOR v_cursor IS
          SELECT t1.name0, t1.code, t1.pcode, t2.formid, t2.tag, t2.label, t2.sealtype, t2.desc_
            FROM info_template_qfoper t1
           INNER JOIN info_template_seal_rel t2
              ON (t2.tempid = v_info_dtype AND t2.formid = t1.form)
           WHERE t1.tempid = v_info_dtype
           ORDER BY t1.sort, t2.sort;
      BEGIN
        OPEN v_cursor;
        LOOP
          FETCH v_cursor
            INTO v_qfoper_name0, v_qfoper_code, v_qfoper_pcode, v_form_id, v_form_sealtag, v_form_seallabel, v_form_sealtype, v_form_sealdesc;
          EXIT WHEN v_cursor%NOTFOUND;
          v_exists := 0;
          IF v_qfoper_pcode = '1' THEN
            v_qfoper_code := mystring.f_concat('|', v_qfoper_pcode, '|');
          ELSE
            v_qfoper_code := mystring.f_concat('|', v_qfoper_code, '|');
          END IF;
          IF instr(v_qf_opertype_all, v_qfoper_code) > 0 THEN
            v_exists := 1;
          END IF;
          IF v_exists > 0 THEN
            v_num := v_num + 1;
            IF v_num > 1 THEN
              v_info_forms := mystring.f_concat(v_info_forms, ',');
            END IF;
            v_info_forms := mystring.f_concat(v_info_forms, '{');
            v_info_forms := mystring.f_concat(v_info_forms, ' "formid":"', v_form_id, '"');
            v_info_forms := mystring.f_concat(v_info_forms, ',"formname":"', v_qfoper_name0, '"');
            v_info_forms := mystring.f_concat(v_info_forms, ',"tag":"', v_form_sealtag, '"');
            v_info_forms := mystring.f_concat(v_info_forms, ',"label":"', v_form_seallabel, '"');
            v_info_forms := mystring.f_concat(v_info_forms, ',"type":"', v_form_sealtype, '"');
            v_info_forms := mystring.f_concat(v_info_forms, ',"desc":"', v_form_sealdesc, '"');
            v_info_forms := mystring.f_concat(v_info_forms, '}');
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
    
      v_info_forms := mystring.f_concat(v_info_forms, ']');
      IF mystring.f_isnotnull(v_info_forms) THEN
        dbms_lob.append(o_info1, v_info_forms);
      END IF;
    
      dbms_lob.append(o_info1, ',"sealList":[');
      v_num := 0;
    
      DECLARE
        v_seal_code VARCHAR2(64);
        v_seal_name VARCHAR2(128);
        v_sealpin   VARCHAR2(64);
        v_sealpack  CLOB;
        CURSOR v_cursor IS
          SELECT t.code, t.name, t.sealpin, t.sealpack
            FROM info_template_seal t
           WHERE t.tempid = v_info_dtype
             AND t.sealtype = 'issue';
      BEGIN
        OPEN v_cursor;
        LOOP
          FETCH v_cursor
            INTO v_seal_code, v_seal_name, v_sealpin, v_sealpack;
          EXIT WHEN v_cursor%NOTFOUND;
          v_num := v_num + 1;
          IF v_num > 1 THEN
            dbms_lob.append(o_info1, ',');
          END IF;
          dbms_lob.append(o_info1, '{');
          dbms_lob.append(o_info1, mystring.f_concat(' "label":"', v_seal_code, '"'));
          dbms_lob.append(o_info1, mystring.f_concat(',"name":"', v_seal_name, '"'));
          dbms_lob.append(o_info1, mystring.f_concat(',"pin":"', v_sealpin, '"'));
          dbms_lob.append(o_info1, ',"pack":"');
          IF mystring.f_isnotnull(v_sealpack) THEN
            dbms_lob.append(o_info1, v_sealpack);
          END IF;
          dbms_lob.append(o_info1, '"');
          dbms_lob.append(o_info1, '}');
        END LOOP;
        CLOSE v_cursor;
      EXCEPTION
        WHEN OTHERS THEN
          IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
          END IF;
          mydebug.err(7);
      END;
    
      dbms_lob.append(o_info1, ']');
    ELSE
      dbms_lob.append(o_info1, ',"dstype":"0"');
    END IF;
  
    dbms_lob.append(o_info1, ',"signcont":""');
    dbms_lob.append(o_info1, mystring.f_concat(',"appid":"', v_appid, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"lockcode":"', v_lockcode, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"lockmsg":"', myjson.f_escape(v_lockmsg), '"'));
    dbms_lob.append(o_info1, ',"code":"EC00"');
    dbms_lob.append(o_info1, ',"msg":"处理成功"');
    dbms_lob.append(o_info1, '}');
    mydebug.wlog('o_info1', o_info1);
  
    v_file_status := 1;
    IF mystring.f_isnull(v_info_filepath) THEN
      v_file_status := 0;
    END IF;
    IF v_lstver = v_info_ver AND v_cache_exist = 1 THEN
      v_file_status := 0;
    END IF;
    IF v_file_status = 1 THEN
      o_info2 := '<info>';
      o_info2 := mystring.f_concat(o_info2, '<dlfiles>');
      o_info2 := mystring.f_concat(o_info2, '<file flag="datafile"');
      IF v_iscache = '1' THEN
        o_info2 := mystring.f_concat(o_info2, ' deal="256"');
      END IF;
      o_info2 := mystring.f_concat(o_info2, ' name="', v_info_ver, '_', v_info_filename, '">');
      o_info2 := mystring.f_concat(o_info2, myfile.f_filepathaddname(v_info_filepath, v_info_filename));
      o_info2 := mystring.f_concat(o_info2, '</file>');
      o_info2 := mystring.f_concat(o_info2, '</dlfiles>');
      o_info2 := mystring.f_concat(o_info2, '</info>');
      mydebug.wlog('o_info2', o_info2);
    END IF;
  
    COMMIT;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      ROLLBACK;
      o_info1 := NULL;
      o_info2 := NULL;
      o_code  := 'EC00';
      o_msg   := '处理成功';
      mydebug.err(7);
  END;

  -- 查询签发印章信息
  PROCEDURE p_getsealinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype     VARCHAR2(64);
    v_seallabel VARCHAR2(64);
    v_sealname  VARCHAR2(128);
    v_sealpack  CLOB;
  BEGIN
    mydebug.wlog('开始');
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_seallabel') INTO v_seallabel FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_seallabel', v_seallabel);
  
    BEGIN
      SELECT t.name, t.sealpack
        INTO v_sealname, v_sealpack
        FROM info_template_seal t
       WHERE t.tempid = v_dtype
         AND t.sealtype = 'issue'
         AND t.code = v_seallabel
         AND rownum = 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, mystring.f_concat(' "o_sealname":"', v_sealname, '"'));
    dbms_lob.append(o_info, ',"o_sealpack":"');
    IF mystring.f_isnotnull(v_sealpack) THEN
      dbms_lob.append(o_info, v_sealpack);
    END IF;
    dbms_lob.append(o_info, '"');
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
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 签发保存
  PROCEDURE p_save
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id      VARCHAR2(64);
    v_exists  INT := 0;
    v_operuri VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD110', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_id') INTO v_id FROM dual;
    mydebug.wlog('v_id', v_id);
  
    IF mystring.f_isnull(v_id) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM data_qf_book WHERE id = v_id;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '未找到签发信息,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE data_qf_book t SET t.ver = t.ver + 1, t.modifieddate = SYSDATE WHERE t.id = v_id;
  
    SELECT operuri INTO v_operuri FROM data_qf_book WHERE id = v_id;
    IF mystring.f_isnull(v_operuri) THEN
      UPDATE data_qf_book t SET t.operuri = i_operuri, t.opername = i_opername WHERE t.id = v_id;
    ELSE
      IF mystring.f_isnotnull(i_operuri) AND i_operuri <> 'system' THEN
        UPDATE data_qf_book t SET t.operuri = i_operuri, t.opername = i_opername WHERE t.id = v_id;
      END IF;
    END IF;
  
    UPDATE data_qf_pz t SET t.ver = t.ver + 1, t.modifieddate = SYSDATE, t.operuri = i_operuri, t.opername = i_opername WHERE t.pid = v_id;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 检查单位、用户是否已签发
  PROCEDURE p_getselectobjids
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype        VARCHAR2(64);
    v_objids       VARCHAR2(4000);
    v_docode       VARCHAR2(64);
    v_selectobjids VARCHAR2(4000);
    v_num          INT := 0;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.objids') INTO v_objids FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_objids', v_objids);
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.docode
          FROM data_qf_book t
         WHERE t.dtype = v_dtype
           AND instr(v_objids, t.docode) > 0;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_docode;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num = 1 THEN
          v_selectobjids := v_docode;
        ELSE
          v_selectobjids := mystring.f_concat(v_selectobjids, ',', v_docode);
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
    END;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"objids":"', v_selectobjids, '"');
    o_info := mystring.f_concat(o_info, ',"code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"处理成功"');
    o_info := mystring.f_concat(o_info, '}');
  
    mydebug.wlog('o_info', o_info);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_info := NULL;
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
  END;

END;
/
