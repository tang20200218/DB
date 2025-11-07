CREATE OR REPLACE PACKAGE pkg_info_register IS

  /***************************************************************************************************
  名称     : pkg_info_register
  功能描述 : 开户注册管理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-09  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  -- 检查节点是否有授权(1:是 0:否)
  FUNCTION f_kindauthstatus
  (
    i_kindid  VARCHAR2,
    i_useruri VARCHAR2
  ) RETURN INT;

  -- 查询分类树根节点
  PROCEDURE p_gettree_first
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询分类树
  PROCEDURE p_gettree
  (
    i_datatype IN INT,
    i_pid      IN VARCHAR2, -- 上级标识
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询批量导入下载示例文件
  PROCEDURE p_getexfile
  (
    i_forminfo IN CLOB,
    i_operuri  IN VARCHAR2,
    i_opername IN VARCHAR2,
    o_info1    OUT VARCHAR2,
    o_info2    OUT VARCHAR2,
    o_code     OUT VARCHAR2,
    o_msg      OUT VARCHAR2
  );

  -- 更改节点
  PROCEDURE p_move
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 查询默认排序号
  PROCEDURE p_getsort
  (
    i_kindid   IN VARCHAR2, -- 节点标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_sort     OUT VARCHAR2, -- 排序号
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_register IS
  -- 检查节点是否有授权(1:是 0:否)
  FUNCTION f_kindauthstatus
  (
    i_kindid  VARCHAR2,
    i_useruri VARCHAR2
  ) RETURN INT AS
    v_exists INT := 0;
  BEGIN
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_template t1
             INNER JOIN info_admin_auth t2
                ON (t2.useruri = i_useruri AND t2.dtype = t1.tempid)
             INNER JOIN info_register_kind t3
                ON (instr(t3.idpath, i_kindid) > 0 AND t3.datatype = t1.otype)
             INNER JOIN info_admin_auth_kind t4
                ON (t4.useruri = i_useruri AND t4.dtype = t1.tempid AND t4.kindid = t3.id)
             WHERE t1.enable = '1'
               AND t1.bindstatus = 1
               AND t1.kindtype = 2
               AND t1.qfflag = 1);  
    RETURN v_exists;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  /***************************************************************************************************
  名称     : pkg_info_register.p_gettree_first
  功能描述 : 查询分类树根节点
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_gettree_first
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_type     VARCHAR2(64);
    v_c1       INT := 0;
    v_exists   INT := 0;
    v_isleaf   INT := 0;
    v_datatype INT := 0;
  
    v_row_id    VARCHAR2(64);
    v_row_name  VARCHAR2(128);
    v_row_num   INTEGER;
    v_root_name VARCHAR2(128);
    v_tree      VARCHAR2(32767);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 请求表单解析
    SELECT json_value(i_forminfo, '$.type') INTO v_type FROM dual;
    mydebug.wlog('v_type', v_type);
  
    IF v_type = 'user' THEN
      -- 验证用户权限
      pkg_qp_verify.p_check('MD922', i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    
      v_datatype := 0;
    ELSE
      -- 验证用户权限
      pkg_qp_verify.p_check('MD921', i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    
      v_datatype := 1;
    END IF;
  
    v_root_name := pkg_info_register_kind_pbl.f_getrootname(v_datatype);
  
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
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.id, t.name, t.num
          FROM info_register_kind t
         WHERE t.pid = 'root'
           AND t.datatype = v_datatype
         ORDER BY t.sort, t.id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_row_id, v_row_name, v_row_num;
        EXIT WHEN v_cursor%NOTFOUND;
        v_exists := pkg_info_register.f_kindauthstatus(v_row_id, i_operuri);
        IF v_exists = 1 THEN
          SELECT COUNT(1) INTO v_c1 FROM info_register_obj t WHERE t.kindid = v_row_id;
          v_isleaf := pkg_info_register_kind_pbl.f_isleaf(v_row_id);
          v_tree   := mystring.f_concat(v_tree, '<item im0="folderClosed.gif"');
          v_tree   := mystring.f_concat(v_tree, ' im1="folderOpen.gif"');
          v_tree   := mystring.f_concat(v_tree, ' im2="folderClosed.gif"');
          IF v_isleaf = 1 THEN
            v_tree := mystring.f_concat(v_tree, ' child="0"');
          ELSE
            v_tree := mystring.f_concat(v_tree, ' child="1"');
          END IF;
          v_tree := mystring.f_concat(v_tree, ' id="', v_row_id, '"');
          v_tree := mystring.f_concat(v_tree, ' text="', myxml.f_escape(v_row_name), '">');
          v_tree := mystring.f_concat(v_tree, '<userdata name="kindid">', v_row_id, '</userdata>');
          v_tree := mystring.f_concat(v_tree, '<userdata name="kindname">', myxml.f_escape(v_row_name), '</userdata>');
          v_tree := mystring.f_concat(v_tree, '<userdata name="kindcode">', v_row_num, '</userdata>');
          v_tree := mystring.f_concat(v_tree, '<userdata name="num">', v_c1, '</userdata>');
          IF v_isleaf = 1 THEN
            v_tree := mystring.f_concat(v_tree, '<userdata name="kindtype">2</userdata>');
          ELSE
            v_tree := mystring.f_concat(v_tree, '<userdata name="kindtype">1</userdata>');
          END IF;
        
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
  
    v_tree := mystring.f_concat(v_tree, '</item>');
    v_tree := mystring.f_concat(v_tree, '</tree>');
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, mystring.f_concat('"code":"', o_code, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"msg":"', myjson.f_escape(v_tree), '"'));
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

  /***************************************************************************************************
  名称     : pkg_info_register.p_gettree
  功能描述 : 查询分类树
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-02  唐金鑫  创建
  
  返回信息(o_info)格式
  <kinds>
    <kinds>
      <id>唯一标识</id>
      <name>名称</name>
      <type>节点类型(1:中间节点、2:叶子节点)</type>
      <code>节点编号</code>
      <c1>单位数量</c1>
    </kinds>
  </kinds>
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_gettree
  (
    i_datatype IN INT,
    i_pid      IN VARCHAR2, -- 上级标识
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_c1     INT := 0;
    v_exists INT := 0;
    v_isleaf INT := 0;
  
    v_row_id   VARCHAR2(64);
    v_row_name VARCHAR2(128);
    v_row_num  INTEGER;
  
    v_root_name VARCHAR2(128);
    v_root_sort INTEGER;
  BEGIN
    mydebug.wlog('i_pid', i_pid);
  
    -- 验证用户权限
    IF i_datatype = 0 THEN
      pkg_qp_verify.p_check('MD922', i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSE
      pkg_qp_verify.p_check('MD921', i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    END IF;
  
    IF i_pid = '0' THEN
      IF i_datatype = 0 THEN
        SELECT t.name, t.sort INTO v_root_name, v_root_sort FROM info_register_kind_root t WHERE t.id = 'root0';
      ELSE
        SELECT t.name, t.sort INTO v_root_name, v_root_sort FROM info_register_kind_root t WHERE t.id = 'root1';
      END IF;
      o_info := '<?xml version="1.0" encoding="UTF-8"?>';
      o_info := mystring.f_concat(o_info, '<tree id="0">');
      o_info := mystring.f_concat(o_info, '<item im0="folderClosed.gif"');
      o_info := mystring.f_concat(o_info, ' im1="folderOpen.gif"');
      o_info := mystring.f_concat(o_info, ' im2="folderClosed.gif"');
      o_info := mystring.f_concat(o_info, ' child="1"');
      o_info := mystring.f_concat(o_info, ' id="root"');
      o_info := mystring.f_concat(o_info, ' text="', myxml.f_escape(v_root_name), '">');
      o_info := mystring.f_concat(o_info, '<userdata name="kindid">root</userdata>');
      o_info := mystring.f_concat(o_info, '<userdata name="kindcode">0</userdata>');
      o_info := mystring.f_concat(o_info, '<userdata name="num">0</userdata>');
      o_info := mystring.f_concat(o_info, '<userdata name="kindtype">1</userdata>');
      o_info := mystring.f_concat(o_info, '<userdata name="kindname">', myxml.f_escape(v_root_name), '</userdata>');
      o_info := mystring.f_concat(o_info, '<userdata name="sort">', v_root_sort, '</userdata>');
      o_info := mystring.f_concat(o_info, '</item>');
      o_info := mystring.f_concat(o_info, '</tree>');
    
      mydebug.wlog('o_info', o_info);
    
      -- 8.处理成功
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    o_info := '<?xml version="1.0" encoding="UTF-8"?>';
    o_info := mystring.f_concat(o_info, '<tree id="', i_pid, '">');
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.id, t.name, t.num
          FROM info_register_kind t
         WHERE t.pid = i_pid
           AND t.datatype = i_datatype
         ORDER BY t.sort, t.id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_row_id, v_row_name, v_row_num;
        EXIT WHEN v_cursor%NOTFOUND;
        v_exists := pkg_info_register.f_kindauthstatus(v_row_id, i_operuri);
        IF v_exists = 1 THEN
          SELECT COUNT(1) INTO v_c1 FROM info_register_obj t WHERE t.kindid = v_row_id;
          v_isleaf := pkg_info_register_kind_pbl.f_isleaf(v_row_id);
          o_info   := mystring.f_concat(o_info, '<item im0="folderClosed.gif"');
          o_info   := mystring.f_concat(o_info, ' im1="folderOpen.gif"');
          o_info   := mystring.f_concat(o_info, ' im2="folderClosed.gif"');
          IF v_isleaf = 1 THEN
            o_info := mystring.f_concat(o_info, ' child="0"');
          ELSE
            o_info := mystring.f_concat(o_info, ' child="1"');
          END IF;
          o_info := mystring.f_concat(o_info, ' id="', v_row_id, '"');
          o_info := mystring.f_concat(o_info, ' text="', myxml.f_escape(v_row_name), '">');
          o_info := mystring.f_concat(o_info, '<userdata name="kindid">', v_row_id, '</userdata>');
          o_info := mystring.f_concat(o_info, '<userdata name="kindname">', myxml.f_escape(v_row_name), '</userdata>');
          o_info := mystring.f_concat(o_info, '<userdata name="kindcode">', v_row_num, '</userdata>');
          o_info := mystring.f_concat(o_info, '<userdata name="num">', v_c1, '</userdata>');
          IF v_isleaf = 1 THEN
            o_info := mystring.f_concat(o_info, '<userdata name="kindtype">2</userdata>');
          ELSE
            o_info := mystring.f_concat(o_info, '<userdata name="kindtype">1</userdata>');
          END IF;
        
          o_info := mystring.f_concat(o_info, '</item>');
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
  
    o_info := mystring.f_concat(o_info, '</tree>');
  
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

  -- 查询批量导入下载示例文件
  PROCEDURE p_getexfile
  (
    i_forminfo IN CLOB,
    i_operuri  IN VARCHAR2,
    i_opername IN VARCHAR2,
    o_info1    OUT VARCHAR2,
    o_info2    OUT VARCHAR2,
    o_code     OUT VARCHAR2,
    o_msg      OUT VARCHAR2
  ) AS
    v_type     VARCHAR2(64);
    v_filetype VARCHAR2(64);
    v_filename VARCHAR2(64);
    v_filepath VARCHAR2(512);
  BEGIN
    mydebug.wlog('开始');
  
    -- 解析表单信息
    SELECT json_value(i_forminfo, '$.type') INTO v_type FROM dual;
    SELECT json_value(i_forminfo, '$.filetype') INTO v_filetype FROM dual;
  
    mydebug.wlog('v_type', v_type);
    mydebug.wlog('v_filetype', v_filetype);
  
    IF v_type = 'dept' THEN
      IF v_filetype = '1' THEN
        v_filename := 'dept_example.txt';
      ELSE
        v_filename := 'dept_example.xls';
      END IF;
    ELSE
      IF v_filetype = '1' THEN
        v_filename := 'user_example.txt';
      ELSE
        v_filename := 'user_example.xls';
      END IF;
    END IF;
  
    v_filepath := pkg_file0.f_getconfig;
    v_filepath := mystring.f_concat(v_filepath, 'examplefile/', v_filename);
  
    o_info1 := '{"code":"EC00","msg":"处理成功！"}';
  
    -- 返回文件
    o_info2 := '<info>';
    o_info2 := mystring.f_concat(o_info2, '<dlfiles>');
    o_info2 := mystring.f_concat(o_info2, '<file flag="datafile">', v_filepath, '</file>');
    o_info2 := mystring.f_concat(o_info2, '</dlfiles>');
    o_info2 := mystring.f_concat(o_info2, '</info>');
  
    -- 添加成功
    o_code := 'EC00';
    o_msg  := '处理成功！';
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

  -- 更改节点
  PROCEDURE p_move
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_type       VARCHAR2(64);
    v_kindid     VARCHAR2(64);
    v_ids        VARCHAR2(4000);
    v_ids_count  INT := 0;
    v_i          INT := 0;
    v_id         VARCHAR2(64);
    v_sort       INT := 0;
    v_sysdate    DATE := SYSDATE;
    v_kindidpath VARCHAR2(512);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 请求表单解析
    SELECT json_value(i_forminfo, '$.type') INTO v_type FROM dual;
    SELECT json_value(i_forminfo, '$.i_kindid') INTO v_kindid FROM dual;
    SELECT json_value(i_forminfo, '$.i_ids') INTO v_ids FROM dual;
  
    mydebug.wlog('v_type', v_type);
    mydebug.wlog('v_kindid', v_kindid);
    mydebug.wlog('v_ids', v_ids);
  
    -- 验证用户权限
    IF v_type = 'user' THEN
      pkg_qp_verify.p_check('MD922', i_operuri, i_opername, o_code, o_msg);
    ELSE
      pkg_qp_verify.p_check('MD921', i_operuri, i_opername, o_code, o_msg);
    END IF;
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
  
    IF mystring.f_isnull(v_kindid) THEN
      o_code := 'EC02';
      o_msg  := '节点标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_ids) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_ids_count := myarray.f_getcount(v_ids, ',');
    IF v_ids_count = 0 THEN
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
  
    SELECT MAX(t.sort) INTO v_sort FROM info_register_obj t WHERE t.kindid = v_kindid;
    IF v_sort IS NULL THEN
      v_sort := 0;
    END IF;
  
    v_i := 1;
    WHILE v_i <= v_ids_count LOOP
      v_id := myarray.f_getvalue(v_ids, ',', v_i);
      UPDATE info_register_obj t
         SET t.kindid = v_kindid, t.kindidpath = v_kindidpath, t.sort = t.sort + v_sort, t.operuri = i_operuri, t.opername = i_opername, t.modifieddate = v_sysdate
       WHERE t.id = v_id;
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
  名称     : pkg_info_register.p_getsort
  功能描述 : 查询默认排序号
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-05  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getsort
  (
    i_kindid   IN VARCHAR2, -- 节点标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_sort     OUT VARCHAR2, -- 排序号
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sort INT := 0;
  BEGIN
    mydebug.wlog('i_kindid', i_kindid);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT MAX(t.sort) INTO v_sort FROM info_register_obj t WHERE t.kindid = i_kindid;
    IF v_sort IS NULL THEN
      v_sort := 1;
    ELSE
      v_sort := v_sort + 1;
    END IF;
  
    o_sort := v_sort;
  
    mydebug.wlog('o_sort', o_sort);
  
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

END;
/
