CREATE OR REPLACE PACKAGE pkg_info_user IS

  /***************************************************************************************************
  名称     : pkg_info_user
  功能描述 : 用户开户管理-用户
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-05  唐金鑫  创建
  
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

  -- 查询列表(打印、导出时查询)
  PROCEDURE p_getlist2
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 增加检查
  PROCEDURE p_ins_check
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 添加
  PROCEDURE p_ins
  (
    i_kindid   IN VARCHAR2, -- 节点标识
    i_username IN VARCHAR2, -- 姓名
    i_userid   IN VARCHAR2, -- 港号
    i_idcard   IN VARCHAR2, -- 证件号码
    i_sort     IN VARCHAR2, -- 人员排序
    i_rs       IN VARCHAR2, -- 向空间发送数据的路由
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_id       OUT VARCHAR2, -- 唯一标识
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 修改
  PROCEDURE p_upd
  (
    i_id       IN VARCHAR2, -- 唯一标识
    i_sort     IN VARCHAR2, -- 人员排序
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除
  PROCEDURE p_del
  (
    i_id       IN VARCHAR2, -- 唯一标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 添加/删除/修改
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 批量导入
  PROCEDURE p_ins_batch
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_user IS

  /***************************************************************************************************
  名称     : pkg_info_user.p_getlist
  功能描述 : 查询列表
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-05  唐金鑫  创建
  
  返回信息(o_info)格式
  <RESPONSE>
    <ROWS>
      <ROW row_id="序号">
        <id>唯一标识</id>
        <username>姓名</username>
        <userid>港号</userid>
        <idcard>证件号码</idcard>
        <sort>排序号</sort>
        <fromtype>开户方式(1:手工开户 2:自动开户)</fromtype>
        <status>注册状态(0:待注册 1:已注册 2:注册失败)</status>
        <errmsg>注册失败原因</errmsg>
        <kindname>节点名称</kindname>
        <opername>注册人</opername>
        <createddate>注册时间</createddate>
      </ROW>
    </ROWS>
  </RESPONSE>
  
  <RESPONSE><CNT>0</CNT></RESPONSE>
  
  查询条件
  <cs>
    <fromtype></fromtype>
    <status></status>
    <username></username>
    <starttime></starttime>
    <endtime></endtime>
  </cs>
  
  业务说明
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
  
    v_row_rn          INT;
    v_row_id          VARCHAR2(64);
    v_row_kindid      VARCHAR2(64);
    v_row_userid      VARCHAR2(64);
    v_row_username    VARCHAR2(128);
    v_row_idcard      VARCHAR2(128);
    v_row_sort        INT;
    v_row_fromtype    INT;
    v_row_status      INT;
    v_row_errmsg      VARCHAR2(2000);
    v_row_kindname    VARCHAR2(128);
    v_row_opername    VARCHAR2(128);
    v_row_createddate DATE;
    v_row             VARCHAR2(4000);
  
    v_kindid       VARCHAR2(64);
    v_conditions   VARCHAR2(4000);
    v_cs_fromtype  VARCHAR2(200);
    v_cs_status    VARCHAR2(200);
    v_cs_username  VARCHAR2(200);
    v_cs_starttime VARCHAR2(200);
    v_cs_endtime   VARCHAR2(200);
  BEGIN
    mydebug.wlog('开始');
    -- 验证用户权限
    pkg_qp_verify.p_check('MD922', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_kindid') INTO v_kindid FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/cs/fromtype') INTO v_cs_fromtype FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/cs/status') INTO v_cs_status FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/cs/username') INTO v_cs_username FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/cs/starttime') INTO v_cs_starttime FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/cs/endtime') INTO v_cs_endtime FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select kindid,sort,id from info_register_obj E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.datatype = 0');
    v_sql := mystring.f_concat(v_sql, ' AND EXISTS(SELECT 1 FROM info_admin_auth_kind w1');
    v_sql := mystring.f_concat(v_sql, ' INNER JOIN info_template_kind w2 ON (w2.tempid = w1.dtype AND w2.kindid = w1.kindid)');
    v_sql := mystring.f_concat(v_sql, ' WHERE w1.useruri = ''', i_operuri, '''');
    v_sql := mystring.f_concat(v_sql, ' AND instr(E1.kindidpath, w1.kindid) > 0)');
    IF v_kindid <> 'root' THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.kindidpath, ''', v_kindid, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_fromtype) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.fromtype = ''', v_cs_fromtype, '''');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_status) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.status = ''', v_cs_status, '''');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_username) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.objname, ''', v_cs_username, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_starttime) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.modifieddate >= to_date(''', v_cs_starttime, ''', ''yyyy-mm-dd'')');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_endtime) THEN
      v_cs_endtime := mydate.f_addday_str(v_cs_endtime, 1);
    
      v_sql := mystring.f_concat(v_sql, ' AND E1.modifieddate < to_date(''', v_cs_endtime, ''', ''yyyy-mm-dd'')');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL
    v_sql := mystring.f_concat(v_sql, ' ORDER BY kindid,sort,id desc');
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
          INTO v_row_kindid, v_row_sort, v_row_id;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT objid, objname, objcode, fromtype, status, errmsg, opername, modifieddate
          INTO v_row_userid, v_row_username, v_row_idcard, v_row_fromtype, v_row_status, v_row_errmsg, v_row_opername, v_row_createddate
          FROM info_register_obj
         WHERE id = v_row_id;
      
        v_row_kindname := pkg_info_register_kind_pbl.f_getname(v_row_kindid);
      
        v_num := v_num + 1;
        v_row := '{';
        v_row := mystring.f_concat(v_row, ' "rn":"', v_row_rn, '"');
        v_row := mystring.f_concat(v_row, ',"id":"', v_row_id, '"');
        v_row := mystring.f_concat(v_row, ',"userid":"', v_row_userid, '"');
        v_row := mystring.f_concat(v_row, ',"username":"', myjson.f_escape(v_row_username), '"');
        v_row := mystring.f_concat(v_row, ',"idcard":"', v_row_idcard, '"');
        v_row := mystring.f_concat(v_row, ',"sort":"', v_row_sort, '"');
        v_row := mystring.f_concat(v_row, ',"fromtype":"', v_row_fromtype, '"');
        v_row := mystring.f_concat(v_row, ',"status":"', v_row_status, '"');
        v_row := mystring.f_concat(v_row, ',"errmsg":"', myjson.f_escape(v_row_errmsg), '"');
        v_row := mystring.f_concat(v_row, ',"kindname":"', myjson.f_escape(v_row_kindname), '"');
        v_row := mystring.f_concat(v_row, ',"opername":"', v_row_opername, '"');
        v_row := mystring.f_concat(v_row, ',"createddate":"', to_char(v_row_createddate, 'yyyy-mm-dd hh24:mi'), '"');
        v_row := mystring.f_concat(v_row, '}');
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, v_row);
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
  名称     : pkg_info_user.p_getlist2
  功能描述 : 查询列表(打印、导出时查询)
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-05  唐金鑫  创建
  
  返回信息(o_info)格式
  <RESPONSE>
    <ROWS>
      <ROW row_id="序号">
        <id>唯一标识</id>
        <username>姓名</username>
        <userid>港号</userid>
        <idcard>证件号码</idcard>
        <sort>排序号</sort>
        <fromtype>开户方式(1:手工开户 2:自动开户)</fromtype>
        <status>注册状态(0:待注册 1:已注册 2:注册失败)</status>
        <errmsg>注册失败原因</errmsg>
        <kindname>节点名称</kindname>
        <opername>注册人</opername>
        <createddate>注册时间</createddate>
      </ROW>
    </ROWS>
  </RESPONSE>
  
  <RESPONSE><CNT>0</CNT></RESPONSE>
  
  查询条件
  <cs>
    <fromtype></fromtype>
    <status></status>
    <username></username>
    <starttime></starttime>
    <endtime></endtime>
  </cs>
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getlist2
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
  
    v_row_rn          INT;
    v_row_id          VARCHAR2(64);
    v_row_kindid      VARCHAR2(64);
    v_row_userid      VARCHAR2(64);
    v_row_username    VARCHAR2(128);
    v_row_idcard      VARCHAR2(128);
    v_row_sort        INT;
    v_row_fromtype    INT;
    v_row_status      INT;
    v_row_errmsg      VARCHAR2(2000);
    v_row_kindname    VARCHAR2(128);
    v_row_opername    VARCHAR2(128);
    v_row_createddate DATE;
    v_row             VARCHAR2(4000);
  
    v_kindid       VARCHAR2(64);
    v_conditions   VARCHAR2(4000);
    v_cs_fromtype  VARCHAR2(200);
    v_cs_status    VARCHAR2(200);
    v_cs_username  VARCHAR2(200);
    v_cs_starttime VARCHAR2(200);
    v_cs_endtime   VARCHAR2(200);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD922', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    IF v_pagesize IS NULL THEN
      SELECT json_value(i_forminfo, '$.allCounts') INTO v_pagesize FROM dual;
      SELECT json_value(i_forminfo, '$.currentPage') INTO v_pagenum FROM dual;
    END IF;
    SELECT json_value(i_forminfo, '$.i_kindid') INTO v_kindid FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/cs/fromtype') INTO v_cs_fromtype FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/cs/status') INTO v_cs_status FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/cs/username') INTO v_cs_username FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/cs/starttime') INTO v_cs_starttime FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/cs/endtime') INTO v_cs_endtime FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select kindid,sort,id from info_register_obj E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.datatype = 0');
    v_sql := mystring.f_concat(v_sql, ' AND EXISTS(SELECT 1 FROM info_admin_auth_kind w1');
    v_sql := mystring.f_concat(v_sql, ' INNER JOIN info_template_kind w2 ON (w2.tempid = w1.dtype AND w2.kindid = w1.kindid)');
    v_sql := mystring.f_concat(v_sql, ' WHERE w1.useruri = ''', i_operuri, '''');
    v_sql := mystring.f_concat(v_sql, ' AND instr(E1.kindidpath, w1.kindid) > 0)');
    IF v_kindid <> 'root' THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.kindidpath, ''', v_kindid, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_fromtype) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.fromtype = ''', v_cs_fromtype, '''');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_status) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.status = ''', v_cs_status, '''');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_username) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.objname, ''', v_cs_username, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_starttime) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.modifieddate >= to_date(''', v_cs_starttime, ''', ''yyyy-mm-dd'')');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_endtime) THEN
      v_cs_endtime := mydate.f_addday_str(v_cs_endtime, 1);
    
      v_sql := mystring.f_concat(v_sql, ' AND E1.modifieddate < to_date(''', v_cs_endtime, ''', ''yyyy-mm-dd'')');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL
    v_sql := mystring.f_concat(v_sql, ' ORDER BY kindid,sort,id desc');
    v_sql := myquery.f_getpagesql(v_sql, v_pagesize, v_pagenum);
    mydebug.wlog('v_sql', v_sql);
  
    -- 分页起始编号
    v_row_rn := myquery.f_getpagestartnum(v_pagesize, v_pagenum);
  
    -- 执行sql
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{"info":"<RESPONSE>');
    dbms_lob.append(o_info, '<CNT>');
    dbms_lob.append(o_info, mystring.f_int2char(v_cnt));
    dbms_lob.append(o_info, '</CNT>');
    dbms_lob.append(o_info, '<ROWS>');
    DECLARE
      v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果
    BEGIN
      OPEN v_cursor FOR v_sql;
      LOOP
        FETCH v_cursor
          INTO v_row_kindid, v_row_sort, v_row_id;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT objid, objname, objcode, fromtype, status, errmsg, opername, modifieddate
          INTO v_row_userid, v_row_username, v_row_idcard, v_row_fromtype, v_row_status, v_row_errmsg, v_row_opername, v_row_createddate
          FROM info_register_obj
         WHERE id = v_row_id;
      
        v_row_kindname := pkg_info_register_kind_pbl.f_getname(v_row_kindid);
      
        v_row := mystring.f_concat('<ROW row_id=\"', v_row_rn, '\">');
        v_row := mystring.f_concat(v_row, '<id>', v_row_id, '</id>');
        v_row := mystring.f_concat(v_row, '<userid>', v_row_userid, '</userid>');
        v_row := mystring.f_concat(v_row, '<username>', myxml.f_escape(v_row_username), '</username>');
        v_row := mystring.f_concat(v_row, '<idcard>', v_row_idcard, '</idcard>');
        v_row := mystring.f_concat(v_row, '<sort>', v_row_sort, '</sort>');
        v_row := mystring.f_concat(v_row, '<fromtype>', v_row_fromtype, '</fromtype>');
        v_row := mystring.f_concat(v_row, '<status>', v_row_status, '</status>');
        v_row := mystring.f_concat(v_row, '<errmsg>', myxml.f_escape(v_row_errmsg), '</errmsg>');
        v_row := mystring.f_concat(v_row, '<kindname>', myxml.f_escape(v_row_kindname), '</kindname>');
        v_row := mystring.f_concat(v_row, '<opername>', v_row_opername, '</opername>');
        v_row := mystring.f_concat(v_row, '<createddate>', to_char(v_row_createddate, 'yyyy-mm-dd hh24:mi'), '</createddate>');
        v_row := mystring.f_concat(v_row, '</ROW>');
        dbms_lob.append(o_info, v_row);
      
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
    dbms_lob.append(o_info, '</ROWS>');
    dbms_lob.append(o_info, '</RESPONSE>"');
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
  名称     : pkg_info_user.p_ins_check
  功能描述 : 增加检查
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-05  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_ins_check
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_idcard VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_idcard') INTO v_idcard FROM dual;
    mydebug.wlog('v_idcard', v_idcard);
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 添加
  PROCEDURE p_ins
  (
    i_kindid   IN VARCHAR2, -- 节点标识
    i_username IN VARCHAR2, -- 姓名
    i_userid   IN VARCHAR2, -- 港号
    i_idcard   IN VARCHAR2, -- 证件号码
    i_sort     IN VARCHAR2, -- 人员排序
    i_rs       IN VARCHAR2, -- 向空间发送数据的路由
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_id       OUT VARCHAR2, -- 唯一标识
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id         VARCHAR2(64);
    v_kindidpath VARCHAR2(512);
    v_status     INT;
    v_datatype   INT;
    v_sort       INT;
  BEGIN
    mydebug.wlog('i_kindid', i_kindid);
    mydebug.wlog('i_username', i_username);
    mydebug.wlog('i_userid', i_userid);
    mydebug.wlog('i_idcard', i_idcard);
    mydebug.wlog('i_sort', i_sort);
    mydebug.wlog('i_rs', i_rs);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_kindid) THEN
      o_code := 'EC02';
      o_msg  := '节点标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_username) THEN
      o_code := 'EC02';
      o_msg  := '姓名为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_idcard) THEN
      o_code := 'EC02';
      o_msg  := '证件号码为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_kindidpath := pkg_info_register_kind_pbl.f_getidpath(i_kindid);
  
    BEGIN
      SELECT t.id, t.datatype
        INTO v_id, v_datatype
        FROM info_register_obj t
       WHERE t.objcode = i_idcard
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_datatype = 1 THEN
      o_code := 'EC02';
      o_msg  := '与单位机构代码重复,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_sort) THEN
      SELECT MAX(t.sort) INTO v_sort FROM info_register_obj t WHERE t.kindid = i_kindid;
      IF v_sort IS NULL THEN
        v_sort := 1;
      ELSE
        v_sort := v_sort + 1;
      END IF;
    ELSE
      v_sort := i_sort;
    END IF;
  
    IF mystring.f_isnull(v_id) THEN
      IF mystring.f_isnull(i_userid) THEN
        v_status := 0;
      ELSE
        v_status := 1;
      END IF;
    
      v_id := pkg_basic.f_newid('US');
    
      INSERT INTO info_register_obj
        (id, objid, objname, objcode, datatype, sort, kindid, kindidpath, fromtype, status, operuri, opername)
      VALUES
        (v_id, i_userid, i_username, i_idcard, 0, v_sort, i_kindid, v_kindidpath, 1, v_status, i_operuri, i_opername);
    ELSE
      UPDATE info_register_obj t
         SET t.objname      = i_username,
             t.kindid       = i_kindid,
             t.kindidpath   = v_kindidpath,
             t.fromtype     = 1,
             t.sort         = v_sort,
             t.operuri      = i_operuri,
             t.opername     = i_opername,
             t.modifieddate = SYSDATE
       WHERE id = v_id;
    END IF;
  
    -- 存储路由信息
    IF mystring.f_isnotnull(i_userid) AND mystring.f_isnotnull(i_rs) THEN
      pkg_exch_to_site.p_ins(i_userid, i_username, 'QT10', i_rs, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    o_id := v_id;
    mydebug.wlog('o_id', o_id);
  
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

  -- 修改
  PROCEDURE p_upd
  (
    i_id       IN VARCHAR2, -- 唯一标识
    i_sort     IN VARCHAR2, -- 人员排序
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sort   INT;
    v_kindid VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_id', i_id);
    mydebug.wlog('i_sort', i_sort);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_id) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT t.kindid INTO v_kindid FROM info_register_obj t WHERE t.id = i_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(i_sort) THEN
      SELECT MAX(t.sort) INTO v_sort FROM info_register_obj t WHERE t.kindid = v_kindid;
      IF v_sort IS NULL THEN
        v_sort := 1;
      ELSE
        v_sort := v_sort + 1;
      END IF;
    ELSE
      v_sort := i_sort;
    END IF;
  
    UPDATE info_register_obj t SET t.sort = v_sort, t.operuri = i_operuri, t.opername = i_opername, t.modifieddate = SYSDATE WHERE t.id = i_id;
  
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

  -- 删除
  PROCEDURE p_del
  (
    i_id       IN VARCHAR2, -- 唯一标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_objcode VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_id', i_id);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_id) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT objcode INTO v_objcode FROM info_register_obj WHERE id = i_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    DELETE FROM info_register_queue WHERE id = v_objcode;
    DELETE FROM info_register_obj WHERE id = i_id;
  
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

  /***************************************************************************************************
  名称     : pkg_info_user.p_oper
  功能描述 : 用户的添加/删除/修改
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-05  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_type     VARCHAR2(64);
    v_id       VARCHAR2(64);
    v_kindid   VARCHAR2(64);
    v_userid   VARCHAR2(64);
    v_username VARCHAR2(128);
    v_idcard   VARCHAR2(128);
    v_sort     VARCHAR2(64);
    v_rs       VARCHAR2(4000);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD922', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    -- 请求表单解析
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
  
    IF mystring.f_isnull(v_type) OR v_type NOT IN ('1', '0', '2') THEN
      o_code := 'EC02';
      o_msg  := '操作类型错误,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_type = '1' THEN
      -- 增加
      SELECT json_value(i_forminfo, '$.i_id') INTO v_id FROM dual;
      SELECT json_value(i_forminfo, '$.i_kindid') INTO v_kindid FROM dual;
      SELECT json_value(i_forminfo, '$.i_sort') INTO v_sort FROM dual;
      SELECT json_value(i_forminfo, '$.i_rs') INTO v_rs FROM dual;
      SELECT json_value(i_forminfo, '$.i_userid') INTO v_userid FROM dual;
      SELECT json_value(i_forminfo, '$.i_username') INTO v_username FROM dual;
      SELECT json_value(i_forminfo, '$.i_idcard') INTO v_idcard FROM dual;
      pkg_info_user.p_ins(v_kindid, v_username, v_userid, v_idcard, v_sort, v_rs, i_operuri, i_opername, v_id, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
      o_info := mystring.f_concat('{"code":"EC00","msg":"处理成功","tempContent":"', v_id, '"}');
    ELSIF v_type = '0' THEN
      -- 删除
      DECLARE
        v_data VARCHAR2(32767);
        v_xml  xmltype;
        v_i    INT := 0;
        v_code VARCHAR2(200);
        v_msg  VARCHAR2(2000);
        v_num  INT := 0;
      BEGIN
        SELECT json_value(i_forminfo, '$.data' RETURNING VARCHAR2(32767)) INTO v_data FROM dual;
        v_xml  := xmltype(v_data);
        v_i    := 1;
        o_info := '{"code":"EC00","msg":"处理成功","errors":[';
        WHILE v_i <= 100 LOOP
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/datas/data[', v_i, ']/uri')) INTO v_id FROM dual;
          IF mystring.f_isnull(v_id) THEN
            v_i := 100;
          ELSE
            pkg_info_user.p_del(v_id, i_operuri, i_opername, o_code, o_msg);
            IF v_code <> 'EC00' THEN
              v_num := v_num + 1;
              IF v_num > 1 THEN
                o_info := mystring.f_concat(o_info, ',');
              END IF;
              o_info := mystring.f_concat(o_info, '{');
              o_info := mystring.f_concat(o_info, ' "id":"', v_id, '"');
              o_info := mystring.f_concat(o_info, ',"msg":"', myjson.f_escape(v_msg), '"');
              o_info := mystring.f_concat(o_info, '}');
            END IF;
          END IF;
          v_i := v_i + 1;
        END LOOP;
        o_info := mystring.f_concat(o_info, ']}');
      END;
    ELSIF v_type = '2' THEN
      -- 修改
      SELECT json_value(i_forminfo, '$.i_id') INTO v_id FROM dual;
      SELECT json_value(i_forminfo, '$.i_sort') INTO v_sort FROM dual;
      pkg_info_user.p_upd(v_id, v_sort, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    END IF;
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_info_user.p_ins_batch
  功能描述 : 批量导入
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
  业务说明
  <rows>
      <row>
          <name>姓名</name>
          <code>证件号码</code>
      </row>
  </rows>
  ***************************************************************************************************/
  PROCEDURE p_ins_batch
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_kindid     VARCHAR2(64);
    v_info       VARCHAR2(32767);
    v_sort       INT := 0;
    v_id         VARCHAR2(64);
    v_name       VARCHAR2(128);
    v_code       VARCHAR2(128);
    v_kindidpath VARCHAR2(512);
  BEGIN
    -- 验证用户权限
    pkg_qp_verify.p_check('MD922', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 请求表单解析
    SELECT json_value(i_forminfo, '$.i_kindid') INTO v_kindid FROM dual;
    SELECT json_value(i_forminfo, '$.i_info' RETURNING VARCHAR2(32767)) INTO v_info FROM dual;
    mydebug.wlog('v_kindid', v_kindid);
    mydebug.wlog('v_info', v_info);
  
    IF mystring.f_isnull(v_kindid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_kindidpath := pkg_info_register_kind_pbl.f_getidpath(v_kindid);
  
    IF mystring.f_isnull(v_kindidpath) THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT MAX(t.sort) INTO v_sort FROM info_register_obj t WHERE kindid = v_kindid;
    IF v_sort IS NULL THEN
      v_sort := 0;
    END IF;
  
    -- 解析XML
    DECLARE
      v_xml xmltype;
      v_i   INT := 0;
    BEGIN
      v_xml := xmltype(v_info);
      v_i   := 1;
      WHILE v_i <= 9999 LOOP
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/rows/row[', v_i, ']/name')) INTO v_name FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/rows/row[', v_i, ']/code')) INTO v_code FROM dual;
      
        IF mystring.f_isnull(v_name) OR mystring.f_isnull(v_code) THEN
          v_i := 9999;
        ELSE
          v_id := NULL;
          BEGIN
            SELECT t.id
              INTO v_id
              FROM info_register_obj t
             WHERE t.objcode = v_code
               AND t.datatype = 0
               AND rownum <= 1;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
          IF mystring.f_isnull(v_id) THEN
            v_id   := pkg_basic.f_newid('US');
            v_sort := v_sort + v_i;
          
            INSERT INTO info_register_obj
              (id, objname, objcode, datatype, sort, kindid, kindidpath, fromtype, errmsg, operuri, opername)
            VALUES
              (v_id, v_name, v_code, 0, v_sort, v_kindid, v_kindidpath, 2, 0, i_operuri, i_opername);
          
            DELETE FROM info_register_queue WHERE id = v_code;
            INSERT INTO info_register_queue (id, datatype) VALUES (v_code, 0);
          ELSE
            UPDATE info_register_obj t
               SET t.objname      = v_name,
                   t.kindid       = v_kindid,
                   t.kindidpath   = v_kindidpath,
                   t.fromtype     = 1,
                   t.sort         = v_sort,
                   t.operuri      = i_operuri,
                   t.opername     = i_opername,
                   t.modifieddate = SYSDATE
             WHERE t.id = v_id;
          END IF;
        END IF;
      
        v_i := v_i + 1;
      END LOOP;
    END;
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
END;
/
