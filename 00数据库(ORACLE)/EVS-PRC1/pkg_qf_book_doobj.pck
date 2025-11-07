CREATE OR REPLACE PACKAGE pkg_qf_book_doobj IS

  /***************************************************************************************************
  名称     : pkg_qf_book_doobj
  功能描述 : 签发办理-查询本系统注册单位树/用户树
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

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
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf_book_doobj IS

  /***************************************************************************************************
  名称     : pkg_qf_book_doobj.p_getkind
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
    v_dtype   VARCHAR2(64);
    v_pid     VARCHAR2(64);
    v_noother VARCHAR2(64);
  
    v_exists INT := 0;
    v_idpath VARCHAR2(64);
  
    v_row_id       VARCHAR2(64);
    v_row_kindname VARCHAR2(64);
    v_row_isleaf   INT;
    v_root_name    VARCHAR2(128);
  
    v_otype    INT;
    v_kindtype INT;
    v_tree     VARCHAR2(32767);
    v_info     VARCHAR2(32767);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_pid') INTO v_pid FROM dual;
    SELECT json_value(i_forminfo, '$.noother') INTO v_noother FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_pid', v_pid);
    mydebug.wlog('v_noother', v_noother);
  
    BEGIN
      SELECT otype, kindtype INTO v_otype, v_kindtype FROM info_template t WHERE t.tempid = v_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF v_kindtype = 1 THEN
      -- 不确定签发对象,进入签发办理页面没有左边树
      v_tree := '<?xml version="1.0" encoding="UTF-8"?>';
      v_tree := mystring.f_concat(v_tree, '<item id="0">');
      IF v_otype = 0 THEN
        -- 个人
        v_tree := mystring.f_concat(v_tree, '<item id="otherRootE" child="0" text="其他用户" im0="icon10.gif" im1="icon10.gif" im2="icon10.gif">');
      ELSE
        -- 单位
        v_tree := mystring.f_concat(v_tree, '<item id="otherRootE" child="0" text="其他单位" im0="icon12.gif" im1="icon12.gif" im2="icon12.gif">');
      END IF;
      v_tree := mystring.f_concat(v_tree, '<userdata name="isleaf">1</userdata>');
      v_tree := mystring.f_concat(v_tree, '</item>');
      v_tree := mystring.f_concat(v_tree, '</item>');
    
      v_info := '{';
      v_info := mystring.f_concat(v_info, '"tempContent":"', myjson.f_escape(v_tree), '"');
      v_info := mystring.f_concat(v_info, ',"code":"EC00"');
      v_info := mystring.f_concat(v_info, ',"msg":"处理成功"');
      v_info := mystring.f_concat(v_info, '}');
    
      dbms_lob.createtemporary(o_info, TRUE);
      dbms_lob.append(o_info, v_info);
      mydebug.wlog('o_info', o_info);
    
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
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
    
      IF mystring.f_isnull(v_noother) OR v_noother <> '1' THEN
        IF v_otype = 0 THEN
          -- 个人
          v_tree := mystring.f_concat(v_tree, '<item im0="groups.gif" im1="groups.gif" im2="groups.gif" child="0" id="otherRootE" text="其它用户">');
          v_tree := mystring.f_concat(v_tree, '<userdata name="kindname">其它用户</userdata>');
        ELSE
          -- 单位
          v_tree := mystring.f_concat(v_tree, '<item im0="folderClosed.gif" im1="folderOpen.gif" im2="folderClosed.gif" child="0" id="otherRootE" text="其它单位">');
          v_tree := mystring.f_concat(v_tree, '<userdata name="kindname">其它单位</userdata>');
        END IF;
        v_tree := mystring.f_concat(v_tree, '<userdata name="kindid">otherRootE</userdata>');
        v_tree := mystring.f_concat(v_tree, '</item>');
      END IF;
    
      v_tree := mystring.f_concat(v_tree, '</tree>');
    
      v_info := '{';
      v_info := mystring.f_concat(v_info, '"tempContent":"', myjson.f_escape(v_tree), '"');
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
      RETURN;
    END IF;
  
    v_tree := '<?xml version="1.0" encoding="UTF-8"?>';
    v_tree := mystring.f_concat(v_tree, '<tree id="', v_pid, '">');
    DECLARE
      CURSOR v_cursor IS
        SELECT id, NAME
          FROM info_register_kind
         WHERE datatype = v_otype
           AND pid = v_pid
         ORDER BY sort, id;
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
      
        v_exists := 0;
      
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
          IF v_otype = 0 THEN
            v_tree := mystring.f_concat(v_tree, ' im0="groups.gif"');
            v_tree := mystring.f_concat(v_tree, ' im1="groups.gif"');
            v_tree := mystring.f_concat(v_tree, ' im2="groups.gif"');
          ELSE
            v_tree := mystring.f_concat(v_tree, ' im0="folderClosed.gif"');
            v_tree := mystring.f_concat(v_tree, ' im1="folderOpen.gif"');
            v_tree := mystring.f_concat(v_tree, ' im2="folderClosed.gif"');
          END IF;
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
        mydebug.err(7);
    END;
  
    v_tree := mystring.f_concat(v_tree, '</tree>');
  
    v_info := '{';
    v_info := mystring.f_concat(v_info, '"tempContent":"', myjson.f_escape(v_tree), '"');
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
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_qf_book_doobj.p_getlist
  功能描述 : 查询列表
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
  返回信息(o_info)格式
  <RESPONSE>
    <ROWS>
      <ROW row_id="序号">
        <uri>港号</uri>
        <name>名称</name>
        <code>证件号码</code>
        <kindname>节点名称</kindname>
      </ROW>
    </ROWS>
  </RESPONSE>
  
  <RESPONSE><CNT>0</CNT></RESPONSE>
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
    v_otype  INT := 0;
    v_dtype  VARCHAR2(64);
    v_kindid VARCHAR2(64);
    v_name   VARCHAR2(200);
  
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码  
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_row_rn       INT;
    v_row_id       VARCHAR2(64);
    v_row_kindid   VARCHAR2(64);
    v_row_sort     INT;
    v_row_uri      VARCHAR2(64);
    v_row_name     VARCHAR2(128);
    v_row_code     VARCHAR2(128);
    v_row_kindname VARCHAR2(128);
    v_row_status   INT;
  
    v_info VARCHAR2(32767);
  BEGIN
    mydebug.wlog('开始');
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_kindid') INTO v_kindid FROM dual;
    SELECT json_value(i_forminfo, '$.i_name') INTO v_name FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_kindid', v_kindid);
    mydebug.wlog('v_name', v_name);
  
    v_otype := pkg_info_template_pbl.f_getotype(v_dtype);
  
    -- 制作sql
    v_sql := 'select kindid,sort,id from info_register_obj E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.datatype = ', v_otype);
    v_sql := mystring.f_concat(v_sql, ' AND EXISTS(SELECT 1 FROM info_admin_auth_kind w1');
    v_sql := mystring.f_concat(v_sql, ' INNER JOIN info_template_kind w2 ON (w2.tempid = w1.dtype AND w2.kindid = w1.kindid)');
    v_sql := mystring.f_concat(v_sql, ' WHERE w1.useruri = ''', i_operuri, '''');
    v_sql := mystring.f_concat(v_sql, ' AND w1.dtype = ''', v_dtype, '''');
    v_sql := mystring.f_concat(v_sql, ' AND instr(E1.kindidpath, w1.kindid) > 0)');
    IF v_kindid <> 'root' THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.kindidpath, ''', v_kindid, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_name) THEN
      v_sql := mystring.f_concat(v_sql, ' AND (instr(E1.objname, ''', v_name, ''') > 0 OR instr(E1.objid, ''', v_name, ''') > 0)');
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
    v_info := '{';
    v_info := mystring.f_concat(v_info, myquery.f_getpagenation(v_cnt, v_pagesize, v_pagenum));
    v_info := mystring.f_concat(v_info, ',"dataList":[');
    DECLARE
      v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果
    BEGIN
      OPEN v_cursor FOR v_sql;
      LOOP
        FETCH v_cursor
          INTO v_row_kindid, v_row_sort, v_row_id;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT objid, objname, objcode INTO v_row_uri, v_row_name, v_row_code FROM info_register_obj WHERE id = v_row_id;
      
        v_row_kindname := pkg_info_register_kind_pbl.f_getname(v_row_kindid);
      
        SELECT COUNT(1)
          INTO v_row_status
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_qf_book t
                 WHERE t.dtype = v_dtype
                   AND t.docode = v_row_code);
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          v_info := mystring.f_concat(v_info, ',');
        END IF;
        v_info   := mystring.f_concat(v_info, '{');
        v_info   := mystring.f_concat(v_info, ' "rn":"', v_row_rn, '"');
        v_info   := mystring.f_concat(v_info, ',"uri":"', v_row_uri, '"');
        v_info   := mystring.f_concat(v_info, ',"name":"', myjson.f_escape(v_row_name), '"');
        v_info   := mystring.f_concat(v_info, ',"code":"', myjson.f_escape(v_row_code), '"');
        v_info   := mystring.f_concat(v_info, ',"kindname":"', myjson.f_escape(v_row_kindname), '"');
        v_info   := mystring.f_concat(v_info, ',"status":"', v_row_status, '"');
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
