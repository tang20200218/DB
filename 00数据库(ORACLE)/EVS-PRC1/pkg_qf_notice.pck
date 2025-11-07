CREATE OR REPLACE PACKAGE pkg_qf_notice IS

  /***************************************************************************************************
  名称     : pkg_qf_notice
  功能描述 : 业务办理-申领通知
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询办理状态集合
  PROCEDURE p_getstatus
  (
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询树
  PROCEDURE p_getkind
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
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

  -- 发送申领通知-单个处理
  PROCEDURE p_send2
  (
    i_dtype         IN VARCHAR2, -- 凭证类型
    i_templateform0 IN VARCHAR2, -- 
    i_filename      IN VARCHAR2, -- 申请模板文件名
    i_filepath      IN VARCHAR2, -- 申请模板文件路径
    i_png_filename  IN VARCHAR2, -- 封面文件名
    i_png_filepath  IN VARCHAR2, -- 封面文件路径
    i_totype        IN VARCHAR2, -- 接收者类型(1:单位 2:个人)
    i_toids         IN VARCHAR2, -- 接收者ID集合，使用逗号分割
    i_operuri       IN VARCHAR2, -- 操作人URI
    i_opername      IN VARCHAR2, -- 操作人姓名
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  );

  -- 发送申领通知
  PROCEDURE p_send
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询申领模板
  PROCEDURE p_gethfile
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
CREATE OR REPLACE PACKAGE BODY pkg_qf_notice IS

  /***************************************************************************************************
  名称     : pkg_qf_notice.p_getstatus
  功能描述 : 查询办理状态集合
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-10  唐金鑫  创建
      
  查询返回的结果(o_info)格式
  <rows>
    <row>
      <id>唯一标识(代码)</id>
      <title>标题(名称)</title>
    </row>
  </rows>
  ***************************************************************************************************/
  PROCEDURE p_getstatus
  (
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_num  INT := 0;
    v_code VARCHAR2(64);
    v_name VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 1.入参检查
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    o_info := '[';
    DECLARE
      CURSOR v_cursor IS
        SELECT t.code, t.name FROM sys_code_info t WHERE t.code LIKE 'ST7%' ORDER BY t.attrib2;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_code, v_name;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, '{');
        o_info := mystring.f_concat(o_info, ' "id":"', v_code, '"');
        o_info := mystring.f_concat(o_info, ',"title":"', v_name, '"');
        o_info := mystring.f_concat(o_info, '}');
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
    o_info := mystring.f_concat(o_info, ']');
  
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

  /***************************************************************************************************
  名称     : pkg_qf_notice.p_getkind
  功能描述 : 查询树
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-10  唐金鑫  创建
  
  返回信息(o_info)格式
  <kinds>
    <kind>
      <id>唯一标识</id>
      <name>名称</name>
    </kind>
  </kinds>
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getkind
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype  VARCHAR2(64);
    v_pid    VARCHAR2(64);
    v_exists INT := 0;
    v_idpath VARCHAR2(64);
  
    v_row_id       VARCHAR2(64);
    v_row_kindname VARCHAR2(64);
    v_row_isleaf   INT;
    v_root_name    VARCHAR2(128);
  
    v_otype INT;
    v_tree  VARCHAR2(32767);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD110', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_pid') INTO v_pid FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_pid', v_pid);
  
    DECLARE
      v_kindtype INT;
    BEGIN
      SELECT kindtype INTO v_kindtype FROM info_template t WHERE t.tempid = v_dtype;
      IF v_kindtype = 1 THEN
        o_code := 'EC00';
        o_msg  := '处理成功';
        mydebug.wlog(1, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    v_otype := pkg_info_template_pbl.f_getotype(v_dtype);
  
    IF v_pid = '0' THEN
      v_root_name := pkg_info_register_kind_pbl.f_getrootname(v_otype);
    
      v_tree := '<?xml version="1.0" encoding="UTF-8"?>';
      v_tree := mystring.f_concat(v_tree, '<tree id="0">');
      v_tree := mystring.f_concat(v_tree, '<item im0="folderClosed.gif"');
      v_tree := mystring.f_concat(v_tree, ' im1="folderOpen.gif"');
      v_tree := mystring.f_concat(v_tree, ' im2="folderClosed.gif"');
      v_tree := mystring.f_concat(v_tree, ' child="1"');
      v_tree := mystring.f_concat(v_tree, ' id="root"');
      v_tree := mystring.f_concat(v_tree, ' text="', myxml.f_escape(v_root_name), '">');
      v_tree := mystring.f_concat(v_tree, '<userdata name="kindid">root</userdata>');
      v_tree := mystring.f_concat(v_tree, '<userdata name="kindname">', myxml.f_escape(v_root_name), '</userdata>');
      v_tree := mystring.f_concat(v_tree, '<userdata name="kindcode">0</userdata>');
      v_tree := mystring.f_concat(v_tree, '<userdata name="num">0</userdata>');
      v_tree := mystring.f_concat(v_tree, '<userdata name="kindtype">1</userdata>');
      v_tree := mystring.f_concat(v_tree, '</item>');
      v_tree := mystring.f_concat(v_tree, '</tree>');
    
      dbms_lob.createtemporary(o_info, TRUE);
      dbms_lob.append(o_info, '{');
      dbms_lob.append(o_info, ' "code":"EC00"');
      dbms_lob.append(o_info, ',"msg":"处理成功"');
      dbms_lob.append(o_info, mystring.f_concat(',"tempContent":"', myjson.f_escape(v_tree), '"'));
      dbms_lob.append(o_info, '}');
    
      mydebug.wlog('o_info', o_info);
    
      -- 8.处理成功
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    v_tree := '<?xml version="1.0" encoding="UTF-8"?>';
    v_tree := mystring.f_concat(v_tree, '<tree id="', v_pid, '">');
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.id, t.name
          FROM info_register_kind t
         WHERE t.pid = v_pid
           AND t.datatype = v_otype
         ORDER BY t.sort, t.id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_row_id, v_row_kindname;
        EXIT WHEN v_cursor%NOTFOUND;
      
        IF v_row_id = 'root' THEN
          v_idpath := '/';
        ELSE
          v_idpath := v_row_id;
        END IF;
      
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM info_register_kind w1
                 INNER JOIN info_template_kind w2
                    ON (w2.tempid = v_dtype AND w2.kindid = w1.id)
                 WHERE instr(w1.idpath, v_idpath) > 0
                   AND w1.datatype = v_otype);
        IF v_exists = 1 THEN
          SELECT COUNT(1)
            INTO v_exists
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_register_kind w1
                   INNER JOIN info_admin_auth_kind w2
                      ON (w2.useruri = i_operuri AND w2.dtype = v_dtype AND w2.kindid = w1.id)
                   WHERE instr(w1.idpath, v_idpath) > 0
                     AND w1.datatype = v_otype);
        END IF;
      
        IF v_exists = 1 THEN
        
          v_row_isleaf := pkg_info_register_kind_pbl.f_isleaf(v_row_id);
        
          v_tree := mystring.f_concat(v_tree, '<item');
          v_tree := mystring.f_concat(v_tree, ' im0="folderClosed.gif"');
          v_tree := mystring.f_concat(v_tree, ' im1="folderOpen.gif"');
          v_tree := mystring.f_concat(v_tree, ' im2="folderClosed.gif"');
          IF v_row_isleaf = 1 THEN
            v_tree := mystring.f_concat(v_tree, ' child="0"');
          ELSE
            v_tree := mystring.f_concat(v_tree, ' child="1"');
          END IF;
          v_tree := mystring.f_concat(v_tree, ' id="', v_row_id, '"');
          v_tree := mystring.f_concat(v_tree, ' text="', myxml.f_escape(v_row_kindname), '">');
          v_tree := mystring.f_concat(v_tree, '<userdata name="kindid">', v_row_id, '</userdata>');
          v_tree := mystring.f_concat(v_tree, '<userdata name="kindname">', myxml.f_escape(v_row_kindname), '</userdata>');
          v_tree := mystring.f_concat(v_tree, '</item>');
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
    END;
  
    v_tree := mystring.f_concat(v_tree, '</tree>');
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, ' "code":"EC00"');
    dbms_lob.append(o_info, ',"msg":"处理成功"');
    dbms_lob.append(o_info, mystring.f_concat(',"tempContent":"', myjson.f_escape(v_tree), '"'));
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
    v_row_id           VARCHAR2(64);
    v_row_kindid       VARCHAR2(64);
    v_row_objid        VARCHAR2(64);
    v_row_name         VARCHAR2(128);
    v_row_kindname     VARCHAR2(128);
    v_row_sort         INT;
    v_row_status       VARCHAR2(16);
    v_row_status_code  VARCHAR2(8);
    v_row_sendnum      INT;
    v_row_sendunm      VARCHAR2(64);
    v_row_senddate_d   DATE;
    v_row_senddate     VARCHAR2(64);
    v_row_siteinfolist VARCHAR2(4000);
    v_row_statusimgstr VARCHAR2(4000);
    v_row_applystatus  INT;
    v_row_purpose      VARCHAR2(1024);
    v_row              VARCHAR2(8000);
  
    v_send_id     VARCHAR2(64);
    v_send_status VARCHAR2(8);
    v_send_sendid VARCHAR2(64);
    v_book_id     VARCHAR2(64);
    v_book_status VARCHAR2(8);
  
    v_otype      INT := 0;
    v_dtype      VARCHAR2(64);
    v_kindid     VARCHAR2(64);
    v_conditions VARCHAR2(4000);
    v_cs_name    VARCHAR2(200);
    v_cs_status  VARCHAR2(200);
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
        SELECT myxml.f_getvalue(v_xml, '/cs/name') INTO v_cs_name FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/cs/status') INTO v_cs_status FROM dual;
      END IF;
    END;
  
    v_otype := pkg_info_template_pbl.f_getotype(v_dtype);
  
    -- 制作sql
    v_sql := 'select id,objid,objname,kindid,sort from info_register_obj E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.status = 1');
    v_sql := mystring.f_concat(v_sql, ' AND E1.datatype = ', v_otype);
    v_sql := mystring.f_concat(v_sql, ' AND EXISTS(SELECT 1 FROM info_admin_auth_kind w1');
    v_sql := mystring.f_concat(v_sql, ' INNER JOIN info_template_kind w2 ON (w2.tempid = w1.dtype AND w2.kindid = w1.kindid)');
    v_sql := mystring.f_concat(v_sql, ' WHERE w1.useruri = ''', i_operuri, '''');
    v_sql := mystring.f_concat(v_sql, ' AND w1.dtype = ''', v_dtype, '''');
    v_sql := mystring.f_concat(v_sql, ' AND instr(E1.kindidpath, w1.kindid) > 0)');
    IF v_kindid <> 'root' THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.kindidpath, ''', v_kindid, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_name) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.objname, ''', v_cs_name, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_status) THEN
      IF v_cs_status = 'ST71' THEN
        -- ST71:待通知
        v_sql := mystring.f_concat(v_sql, ' AND not exists(select 1 from data_qf_notice_send w where w.dtype = ''', v_dtype, '''');
        v_sql := mystring.f_concat(v_sql, ' AND w.touri = E1.objid)');
        v_sql := mystring.f_concat(v_sql, ' AND not exists(select 1 from data_qf_book w where w.dtype = ''', v_dtype, '''');
        v_sql := mystring.f_concat(v_sql, ' AND w.douri = E1.objid)');
      ELSIF v_cs_status = 'ST72' THEN
        -- ST72:待申请
        v_sql := mystring.f_concat(v_sql, ' AND exists(select 1 from data_qf_notice_send w where w.dtype = ''', v_dtype, '''');
        v_sql := mystring.f_concat(v_sql, ' AND w.touri = E1.objid');
        v_sql := mystring.f_concat(v_sql, ' AND w.status = ''', v_cs_status, ''')');
        v_sql := mystring.f_concat(v_sql, ' AND not exists(select 1 from data_qf_book w where w.dtype = ''', v_dtype, '''');
        v_sql := mystring.f_concat(v_sql, ' AND w.douri = E1.objid)');
      ELSIF v_cs_status = 'ST75' THEN
        -- ST75:已首签
        v_sql := mystring.f_concat(v_sql, ' AND exists(select 1 from data_qf_book w where w.dtype = ''', v_dtype, '''');
        v_sql := mystring.f_concat(v_sql, ' AND w.douri = E1.objid');
        v_sql := mystring.f_concat(v_sql, ' AND w.status = ''GG03'')');
      ELSIF v_cs_status = 'ST76' THEN
        -- ST76:待签发
        v_sql := mystring.f_concat(v_sql, ' AND exists(select 1 from data_qf_book w where w.dtype = ''', v_dtype, '''');
        v_sql := mystring.f_concat(v_sql, ' AND w.douri = E1.objid');
        v_sql := mystring.f_concat(v_sql, ' AND w.status = ''GG01'')');
      ELSE
        v_sql := mystring.f_concat(v_sql, ' AND exists(select 1 from data_qf_notice_send w where w.dtype = ''', v_dtype, '''');
        v_sql := mystring.f_concat(v_sql, ' AND w.touri = E1.objid');
        v_sql := mystring.f_concat(v_sql, ' AND w.status = ''', v_cs_status, ''')');
      END IF;
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
          INTO v_row_id, v_row_objid, v_row_name, v_row_kindid, v_row_sort;
        EXIT WHEN v_cursor%NOTFOUND;
      
        v_row_kindname := pkg_info_register_kind_pbl.f_getname(v_row_kindid);
      
        v_send_id          := NULL;
        v_send_status      := NULL;
        v_row_sendnum      := 0;
        v_row_sendunm      := '';
        v_row_senddate_d   := NULL;
        v_row_senddate     := '';
        v_send_sendid      := '';
        v_row_siteinfolist := '';
        v_row_statusimgstr := '';
        v_row_applystatus  := 0;
        v_row_purpose      := '';
        BEGIN
          SELECT id, status, sendnum, sendunm, senddate, sendid, applystatus, applypurpose
            INTO v_send_id, v_send_status, v_row_sendnum, v_row_sendunm, v_row_senddate_d, v_send_sendid, v_row_applystatus, v_row_purpose
            FROM data_qf_notice_send t
           WHERE t.dtype = v_dtype
             AND t.touri = v_row_objid
             AND rownum <= 1;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        v_row_senddate     := to_char(v_row_senddate_d, 'yyyy-mm-dd hh24:mi');
        v_row_siteinfolist := pkg_exch_send.f_getsiteinfolist(v_send_sendid);
        v_row_statusimgstr := pkg_exch_send.f_getstatusimgstr(v_send_sendid, v_row_id);
      
        v_book_id     := NULL;
        v_book_status := NULL;
        BEGIN
          SELECT id, status
            INTO v_book_id, v_book_status
            FROM data_qf_book t
           WHERE t.dtype = v_dtype
             AND t.douri = v_row_objid
             AND rownum <= 1;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        IF mystring.f_isnull(v_book_id) THEN
          IF mystring.f_isnull(v_send_id) THEN
            v_row_status_code := 'ST71';
          ELSE
            v_row_status_code := v_send_status;
          END IF;
        ELSE
          IF v_book_status = 'GG03' THEN
            v_row_status_code := 'ST75';
          ELSE
            IF v_send_status = 'ST73' THEN
              v_row_status_code := 'ST73';
            ELSE
              v_row_status_code := 'ST76';
            END IF;
          END IF;
        END IF;
      
        v_row_status := pkg_basic.f_codevalue(v_row_status_code);
      
        v_num := v_num + 1;
        IF v_num = 1 THEN
          v_row := '{';
        ELSE
          v_row := ',{';
        END IF;
        v_row := mystring.f_concat(v_row, ' "rn":"', v_row_rn, '"');
        v_row := mystring.f_concat(v_row, ',"id":"', v_row_id, '"');
        v_row := mystring.f_concat(v_row, ',"objid":"', v_row_objid, '"');
        v_row := mystring.f_concat(v_row, ',"name":"', myxml.f_escape(v_row_name), '"');
        v_row := mystring.f_concat(v_row, ',"kindname":"', myxml.f_escape(v_row_kindname), '"');
        v_row := mystring.f_concat(v_row, ',"status":"', v_row_status, '"');
        v_row := mystring.f_concat(v_row, ',"status_code":"', v_row_status_code, '"');
        v_row := mystring.f_concat(v_row, ',"sendnum":"', v_row_sendnum, '"');
        v_row := mystring.f_concat(v_row, ',"sendunm":"', v_row_sendunm, '"');
        v_row := mystring.f_concat(v_row, ',"senddate":"', v_row_senddate, '"');
        v_row := mystring.f_concat(v_row, ',"siteInfoList":', v_row_siteinfolist);
        v_row := mystring.f_concat(v_row, ',"statusImgStr":"', myjson.f_escape(v_row_statusimgstr), '"');
        v_row := mystring.f_concat(v_row, ',"lastSitType":"NT01"');
        v_row := mystring.f_concat(v_row, ',"cancleSitId":""');
        v_row := mystring.f_concat(v_row, ',"applystatus":"', v_row_applystatus, '"');
        v_row := mystring.f_concat(v_row, ',"purpose":"', myxml.f_escape(v_row_purpose), '"');
        v_row := mystring.f_concat(v_row, '}');
        dbms_lob.append(o_info, v_row);
        v_row_rn := v_row_rn + 1;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
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
  名称     : pkg_qf_notice.p_send2
  功能描述 : 发送申领通知-单个处理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_send2
  (
    i_dtype         IN VARCHAR2, -- 凭证类型
    i_templateform0 IN VARCHAR2, -- 
    i_filename      IN VARCHAR2, -- 申请模板文件名
    i_filepath      IN VARCHAR2, -- 申请模板文件路径
    i_png_filename  IN VARCHAR2, -- 封面文件名
    i_png_filepath  IN VARCHAR2, -- 封面文件路径
    i_totype        IN VARCHAR2, -- 接收者类型(1:单位 2:个人)
    i_toids         IN VARCHAR2, -- 接收者ID集合，使用逗号分割
    i_operuri       IN VARCHAR2, -- 操作人URI
    i_opername      IN VARCHAR2, -- 操作人姓名
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_toids_count INT := 0;
    v_i           INT := 0;
    v_toid        VARCHAR2(64);
  
    v_sysdate   DATE := SYSDATE;
    v_form      VARCHAR2(8000);
    v_exchid    VARCHAR2(64);
    v_exchfiles VARCHAR2(4000);
    v_toobjuri  VARCHAR2(4000);
  
    v_send_id      VARCHAR2(64);
    v_send_sendnum INT;
    v_send_sendid  VARCHAR2(64);
  
    v_touri      VARCHAR2(64);
    v_toname     VARCHAR2(128);
    v_kindid     VARCHAR2(64);
    v_kindidpath VARCHAR2(512);
  BEGIN
    mydebug.wlog('i_totype', i_totype);
    mydebug.wlog('i_toids', i_toids);
  
    v_toids_count := myarray.f_getcount(i_toids, ',');
    v_i           := 1;
    WHILE v_i <= v_toids_count LOOP
      v_toid := myarray.f_getvalue(i_toids, ',', v_i);
    
      SELECT objid INTO v_touri FROM info_register_obj t WHERE t.id = v_toid;
    
      IF v_i = 1 THEN
        v_toobjuri := v_touri;
      ELSE
        v_toobjuri := mystring.f_concat(v_toobjuri, ',', v_touri);
      END IF;
    
      v_i := v_i + 1;
    END LOOP;
  
    IF mystring.f_isnull(v_toobjuri) THEN
      o_code := 'EC02';
      o_msg  := '选中对象数据错误,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_form := '<info>';
    v_form := mystring.f_concat(v_form, '<datatype>EVS_ES01</datatype>');
    v_form := mystring.f_concat(v_form, '<datatime>', to_char(v_sysdate, 'yyyy-mm-dd hh24:mi:ss'), '</datatime>');
    v_form := mystring.f_concat(v_form, '<dtype>', i_dtype, '</dtype>');
    v_form := mystring.f_concat(v_form, '<evtype>', i_dtype, '</evtype>');
    v_form := mystring.f_concat(v_form, '<noticetype>MS01</noticetype>');
    v_form := mystring.f_concat(v_form, '<totype>', i_totype, '</totype>');
    v_form := mystring.f_concat(v_form, '<fromuri>', pkg_basic.f_getcomid, '</fromuri>');
    v_form := mystring.f_concat(v_form, '<fromname>', pkg_basic.f_getcomname, '</fromname>');
    IF mystring.f_isnotnull(i_templateform0) THEN
      v_form := mystring.f_concat(v_form, '<templateform>');
      v_form := mystring.f_concat(v_form, mystring.f_clob2char(i_templateform0));
      v_form := mystring.f_concat(v_form, '</templateform>');
    END IF;
    v_form := mystring.f_concat(v_form, '<files>');
    v_form := mystring.f_concat(v_form, '<file type="1" name="', i_filename, '" />');
    IF mystring.f_isnotnull(i_png_filename) THEN
      v_form := mystring.f_concat(v_form, '<file type="2" name="', i_png_filename, '" />');
    END IF;
    v_form := mystring.f_concat(v_form, '</files>');
    v_form := mystring.f_concat(v_form, '</info>');
  
    v_exchfiles := '<manifest flag="0" deleteDir="" sendCount="1">';
    v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="0" filePath="">sendform.xml</file>');
    v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="7" filePath="', i_filepath, '">', myxml.f_escape(i_filename), '</file>');
    IF mystring.f_isnotnull(i_png_filename) THEN
      v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="7" filePath="', i_png_filepath, '">', myxml.f_escape(i_png_filename), '</file>');
    END IF;
    v_exchfiles := mystring.f_concat(v_exchfiles, '</manifest>');
  
    -- 发送
    DECLARE
      v_senddocid VARCHAR2(64);
    BEGIN
      v_senddocid := pkg_basic.f_newid('SE');
      pkg_exch_send.p_send2_massive_1(v_senddocid, 'EVS_ES01', '发送申领通知', v_form, v_exchfiles, v_toobjuri, v_exchid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END;
  
    v_i := 1;
    WHILE v_i <= v_toids_count LOOP
      v_toid := myarray.f_getvalue(i_toids, ',', v_i);
    
      SELECT objid, objname, kindid, kindidpath INTO v_touri, v_toname, v_kindid, v_kindidpath FROM info_register_obj t WHERE t.id = v_toid;
    
      v_send_id      := '';
      v_send_sendid  := '';
      v_send_sendnum := NULL;
      BEGIN
        SELECT id, sendid, sendnum
          INTO v_send_id, v_send_sendid, v_send_sendnum
          FROM data_qf_notice_send t
         WHERE t.dtype = i_dtype
           AND t.touri = v_touri
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    
      -- 删除交换队列数据
      IF mystring.f_isnotnull(v_send_sendid) THEN
        pkg_x_s.p_del(v_send_sendid, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          ROLLBACK;
          RETURN;
        END IF;
      END IF;
    
      v_send_sendid := mystring.f_concat(v_exchid, '-', v_i);
    
      IF mystring.f_isnull(v_send_id) THEN
        v_send_id := pkg_basic.f_newid('NE');
      
        IF v_send_sendnum IS NULL THEN
          v_send_sendnum := 1;
        ELSE
          v_send_sendnum := v_send_sendnum + 1;
        END IF;
      
        INSERT INTO data_qf_notice_send
          (id, dtype, noticetype, totype, touri, toname, kindid, kindidpath, status, sendstatus, sendid, senduid, sendunm, senddate, sendnum)
        VALUES
          (v_send_id, i_dtype, 'MS01', i_totype, v_touri, v_toname, v_kindid, v_kindidpath, 'ST72', 1, v_send_sendid, i_operuri, i_opername, v_sysdate, v_send_sendnum);
      ELSE
        UPDATE data_qf_notice_send t
           SET t.status = 'ST72', t.sendstatus = 1, t.sendid = v_send_sendid, t.senduid = i_operuri, t.sendunm = i_opername, t.senddate = v_sysdate, t.sendnum = t.sendnum + 1
         WHERE t.id = v_send_id;
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

  /***************************************************************************************************
  名称     : pkg_qf_notice.p_send
  功能描述 : 发送申领通知
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
  业务说明
  <info>
    <datatype>EVS_ES01</datatype>
    <datatime>发送时间</datatime>
    <dtype>凭证类型-大类</dtype>
    <evtype>凭证类型-小类</evtype>
    <totype>接收者类型(1:单位 2:个人)</totype>
    <fromuri>发送单位ID</fromuri>
    <fromname>发送单位名称</fromname>
    <templateform>首签参数xml</templateform>
    <files>
      <file type="文件类型(1:申领模板 2:封面)" name="文件名" />
    </files>
  </info>
  ***************************************************************************************************/
  PROCEDURE p_send
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype   VARCHAR2(64); -- 凭证类型
    v_objids  VARCHAR2(4000); -- 通知单位/用户ID，多个使用逗号分割
    v_hfileid VARCHAR2(64); -- 申请模板ID
    v_otype   INT := 0;
    v_totype  VARCHAR2(8);
    v_id      VARCHAR2(64);
    v_kindid  VARCHAR2(64);
    v_idtype  INT := 0; -- 是否节点(1:是 0:否)
    v_num     INT := 0;
  
    v_sql VARCHAR2(8000); -- 查询语句
  
    v_toids         VARCHAR2(4000);
    v_pzid          VARCHAR2(64);
    v_png_filename  VARCHAR2(128);
    v_png_filepath  VARCHAR2(256);
    v_templateform0 CLOB;
    v_fileid        VARCHAR2(64);
    v_filename      VARCHAR2(256);
    v_filepath      VARCHAR2(512);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD110', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_objids') INTO v_objids FROM dual;
    SELECT json_value(i_forminfo, '$.i_tmplid') INTO v_hfileid FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_objids', v_objids);
    mydebug.wlog('v_hfileid', v_hfileid);
  
    IF mystring.f_isnull(v_dtype) THEN
      o_code := 'EC02';
      o_msg  := '凭证类型为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT t.templateform0 INTO v_templateform0 FROM info_template_attr t WHERE t.tempid = v_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    -- 申请模板
    BEGIN
      SELECT t.fileid INTO v_fileid FROM info_template_hfile t WHERE t.id = v_hfileid;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF mystring.f_isnull(v_fileid) THEN
      BEGIN
        SELECT t.fileid INTO v_fileid FROM info_template_hfile0 t WHERE t.id = v_hfileid;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
    v_filename := pkg_file0.f_getfilename(v_fileid);
    v_filepath := pkg_file0.f_getfilepath(v_fileid);
  
    IF mystring.f_isnull(v_filename) THEN
      o_code := 'EC02';
      o_msg  := '没有申请模板,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 封面文件
    BEGIN
      SELECT q.id INTO v_pzid FROM (SELECT t.id FROM data_yz_pz_pub t WHERE t.dtype = v_dtype ORDER BY t.num_start) q WHERE rownum = 1;
      v_png_filename := pkg_file0.f_getfilename_docid(v_pzid, 0);
      v_png_filepath := pkg_file0.f_getfilepath_docid(v_pzid, 0);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_otype := pkg_info_template_pbl.f_getotype(v_dtype);
    IF v_otype = 0 THEN
      v_totype := '2';
    ELSE
      v_totype := '1';
    END IF;
  
    IF mystring.f_isnull(v_objids) THEN
      v_kindid := 'root';
      v_idtype := 1;
    ELSE
      IF v_objids = 'root' THEN
        v_kindid := 'root';
        v_idtype := 1;
      ELSE
        IF length(v_objids) < 128 THEN
          SELECT COUNT(1) INTO v_idtype FROM dual WHERE EXISTS (SELECT 1 FROM info_register_kind t WHERE t.id = v_objids);
          IF v_idtype = 1 THEN
            v_kindid := v_objids;
          END IF;
        END IF;
      END IF;
    END IF;
  
    IF v_idtype = 1 THEN
      -- 节点
      v_sql := 'SELECT id FROM info_register_obj t';
      v_sql := mystring.f_concat(v_sql, ' WHERE t.status = 1');
      v_sql := mystring.f_concat(v_sql, ' AND t.datatype = ', v_otype);
      IF v_kindid <> 'root' THEN
        v_sql := mystring.f_concat(v_sql, ' AND instr(t.kindidpath, ''', v_kindid, ''') > 0');
      END IF;
      v_sql := mystring.f_concat(v_sql, ' AND EXISTS (SELECT 1 FROM info_admin_auth_kind w1');
      v_sql := mystring.f_concat(v_sql, ' INNER JOIN info_template_kind w2 ON (w2.tempid = w1.dtype AND w2.kindid = w1.kindid)');
      v_sql := mystring.f_concat(v_sql, ' WHERE w1.useruri = ''', i_operuri, '''');
      v_sql := mystring.f_concat(v_sql, ' AND w1.dtype = ''', v_dtype, '''');
      v_sql := mystring.f_concat(v_sql, ' AND instr(t.kindidpath, w1.kindid) > 0)');
      v_sql := mystring.f_concat(v_sql, ' AND NOT EXISTS (SELECT 1 FROM data_qf_book w3');
      v_sql := mystring.f_concat(v_sql, ' WHERE w3.dtype = ''', v_dtype, '''');
      v_sql := mystring.f_concat(v_sql, ' AND w3.douri = t.objid)');
    
      o_code := 'EC00';
      DECLARE
        v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果
      BEGIN
        OPEN v_cursor FOR v_sql;
        LOOP
          FETCH v_cursor
            INTO v_id;
          EXIT WHEN v_cursor%NOTFOUND;
          v_num := v_num + 1;
          IF v_num = 1 THEN
            v_toids := v_id;
          ELSE
            v_toids := mystring.f_concat(v_toids, ',', v_id);
          END IF;
          IF v_num = 20 THEN
            pkg_qf_notice.p_send2(v_dtype, v_templateform0, v_filename, v_filepath, v_png_filename, v_png_filepath, v_totype, v_toids, i_operuri, i_opername, o_code, o_msg);
            IF o_code <> 'EC00' THEN
              EXIT;
            END IF;
            v_num := 0;
          END IF;
        END LOOP;
        CLOSE v_cursor;
      EXCEPTION
        -- 9.异常处理
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
    
      IF v_num > 0 THEN
        pkg_qf_notice.p_send2(v_dtype, v_templateform0, v_filename, v_filepath, v_png_filename, v_png_filepath, v_totype, v_toids, i_operuri, i_opername, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          ROLLBACK;
          RETURN;
        END IF;
      END IF;
    ELSE
      pkg_qf_notice.p_send2(v_dtype, v_templateform0, v_filename, v_filepath, v_png_filename, v_png_filepath, v_totype, v_objids, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
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
  名称     : pkg_qf_notice.p_gethfile
  功能描述 : 查询申领模板
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-20  唐金鑫  创建
  
  <files>
    <file>
      <id></id>
      <title></title>
      <filename></filename>
      <filepath></filepath>
    </file>
  </files>
  ***************************************************************************************************/
  PROCEDURE p_gethfile
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype      VARCHAR2(64);
    v_methodname VARCHAR2(64);
    v_exists     INT := 0;
    v_num        INT := 0;
    v_row_id     VARCHAR2(64);
    v_row_fileid VARCHAR2(64);
    v_row_sort   INT;
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD110', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.methodname') INTO v_methodname FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_methodname', v_methodname);
  
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_template_hfile t WHERE t.tempid = v_dtype);
  
    o_info := '{';
    IF v_methodname = 'queryNoteTmplList' THEN
      o_info := mystring.f_concat(o_info, '"tmplList":[');
    ELSE
      o_info := mystring.f_concat(o_info, '"fileList":[');
    END IF;
  
    IF v_exists = 0 THEN
      BEGIN
        SELECT t.id, t.fileid, t.sort
          INTO v_row_id, v_row_fileid, v_row_sort
          FROM info_template_hfile0 t
         WHERE t.dtype = v_dtype
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      IF mystring.f_isnotnull(v_row_id) THEN
        o_info := mystring.f_concat(o_info, '{');
        o_info := mystring.f_concat(o_info, ' "id":"', v_row_id, '"');
        o_info := mystring.f_concat(o_info, ',"title":"申请模板(默认)"');
        o_info := mystring.f_concat(o_info, ',"filename":"', pkg_file0.f_getfilename(v_row_fileid), '"');
        o_info := mystring.f_concat(o_info, ',"filepath":"', myjson.f_escape(pkg_file0.f_getfilepath(v_row_fileid)), '"');
        o_info := mystring.f_concat(o_info, '}');
      END IF;
    ELSE
      DECLARE
        CURSOR v_cursor IS
          SELECT t.id, t.fileid, t.sort FROM info_template_hfile t WHERE t.tempid = v_dtype ORDER BY t.sort;
      BEGIN
        OPEN v_cursor;
        LOOP
          FETCH v_cursor
            INTO v_row_id, v_row_fileid, v_row_sort;
          EXIT WHEN v_cursor%NOTFOUND;
          v_num := v_num + 1;
          IF v_num > 1 THEN
            o_info := mystring.f_concat(o_info, ',');
          END IF;
          o_info := mystring.f_concat(o_info, '{');
          o_info := mystring.f_concat(o_info, ' "id":"', v_row_id, '"');
          o_info := mystring.f_concat(o_info, ',"title":"申请模板(', v_row_sort, ')"');
          o_info := mystring.f_concat(o_info, ',"filename":"', pkg_file0.f_getfilename(v_row_fileid), '"');
          o_info := mystring.f_concat(o_info, ',"filepath":"', myjson.f_escape(pkg_file0.f_getfilepath(v_row_fileid)), '"');
          o_info := mystring.f_concat(o_info, '}');
        END LOOP;
        CLOSE v_cursor;
      EXCEPTION
        WHEN OTHERS THEN
          IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
          END IF;
          mydebug.err(7);
      END;
    END IF;
  
    o_info := mystring.f_concat(o_info, ']');
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

END;
/
