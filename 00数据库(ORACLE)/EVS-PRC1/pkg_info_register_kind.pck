CREATE OR REPLACE PACKAGE pkg_info_register_kind IS

  /***************************************************************************************************
  名称     : pkg_info_register_kind
  功能描述 : 开户注册管理-分类树
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-07-24  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询节点树根节点
  PROCEDURE p_gettree_first
  (
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 查询单位(用户)分类/树-公共
  PROCEDURE p_gettree_pbl
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 查询节点树
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

  -- 查询默认排序-公共
  PROCEDURE p_getsort_pbl
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 查询默认排序号
  PROCEDURE p_getsort
  (
    i_datatype IN INT,
    i_pid      IN VARCHAR2, -- 上级标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_sort     OUT VARCHAR2, -- 排序号
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 增加
  PROCEDURE p_ins
  (
    i_type     IN VARCHAR2, -- 类型
    i_name     IN VARCHAR2, -- 名称
    i_pid      IN VARCHAR2, -- 上级ID
    i_sort     IN VARCHAR2, -- 排序
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 修改
  PROCEDURE p_upd
  (
    i_type     IN VARCHAR2, -- 类型
    i_id       IN VARCHAR2, -- 标识
    i_name     IN VARCHAR2, -- 名称
    i_sort     IN VARCHAR2, -- 排序
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除
  PROCEDURE p_del
  (
    i_id       IN VARCHAR2, -- 标识
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
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_register_kind IS

  /***************************************************************************************************
  名称     : pkg_info_register_kind.p_gettree_first
  功能描述 : 查询节点树根节点
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-15  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_gettree_first
  (
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_isleaf       INT := 0;
    v_row_id       VARCHAR2(64);
    v_row_name     VARCHAR2(128);
    v_row_num      INTEGER;
    v_row_sort     INTEGER;
    v_row_datatype INTEGER;
    v_root0_name   VARCHAR2(128);
    v_root0_sort   INTEGER;
    v_root1_name   VARCHAR2(128);
    v_root1_sort   INTEGER;
    v_item         VARCHAR2(32767);
    v_objcontent   VARCHAR2(32767);
    v_objcontent2  VARCHAR2(32767);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD916', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT t.name, t.sort INTO v_root1_name, v_root1_sort FROM info_register_kind_root t WHERE t.id = 'root1';
    v_objcontent := '<?xml version="1.0" encoding="UTF-8"?>';
    v_objcontent := mystring.f_concat(v_objcontent, '<tree id="0">');
    v_objcontent := mystring.f_concat(v_objcontent, '<item im0="folderClosed.gif"');
    v_objcontent := mystring.f_concat(v_objcontent, ' im1="folderOpen.gif"');
    v_objcontent := mystring.f_concat(v_objcontent, ' im2="folderClosed.gif"');
    v_objcontent := mystring.f_concat(v_objcontent, ' child="1"');
    v_objcontent := mystring.f_concat(v_objcontent, ' id="root"');
    v_objcontent := mystring.f_concat(v_objcontent, ' text="', myxml.f_escape(v_root1_name), '">');
    v_objcontent := mystring.f_concat(v_objcontent, '<userdata name="kindid">root</userdata>');
    v_objcontent := mystring.f_concat(v_objcontent, '<userdata name="kindcode">0</userdata>');
    v_objcontent := mystring.f_concat(v_objcontent, '<userdata name="num">0</userdata>');
    v_objcontent := mystring.f_concat(v_objcontent, '<userdata name="kindtype">1</userdata>');
    v_objcontent := mystring.f_concat(v_objcontent, '<userdata name="kindname">', myxml.f_escape(v_root1_name), '</userdata>');
    v_objcontent := mystring.f_concat(v_objcontent, '<userdata name="sort">', v_root1_sort, '</userdata>');
  
    SELECT t.name, t.sort INTO v_root0_name, v_root0_sort FROM info_register_kind_root t WHERE t.id = 'root0';
    v_objcontent2 := '<?xml version="1.0" encoding="UTF-8"?>';
    v_objcontent2 := mystring.f_concat(v_objcontent2, '<tree id="0">');
    v_objcontent2 := mystring.f_concat(v_objcontent2, '<item im0="folderClosed.gif"');
    v_objcontent2 := mystring.f_concat(v_objcontent2, ' im1="folderOpen.gif"');
    v_objcontent2 := mystring.f_concat(v_objcontent2, ' im2="folderClosed.gif"');
    v_objcontent2 := mystring.f_concat(v_objcontent2, ' child="1"');
    v_objcontent2 := mystring.f_concat(v_objcontent2, ' id="root"');
    v_objcontent2 := mystring.f_concat(v_objcontent2, ' text="', myxml.f_escape(v_root0_name), '">');
    v_objcontent2 := mystring.f_concat(v_objcontent2, '<userdata name="kindid">root</userdata>');
    v_objcontent2 := mystring.f_concat(v_objcontent2, '<userdata name="kindcode">0</userdata>');
    v_objcontent2 := mystring.f_concat(v_objcontent2, '<userdata name="num">0</userdata>');
    v_objcontent2 := mystring.f_concat(v_objcontent2, '<userdata name="kindtype">1</userdata>');
    v_objcontent2 := mystring.f_concat(v_objcontent2, '<userdata name="kindname">', myxml.f_escape(v_root0_name), '</userdata>');
    v_objcontent2 := mystring.f_concat(v_objcontent2, '<userdata name="sort">', v_root0_sort, '</userdata>');
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.id, t.name, t.num, t.sort, datatype FROM info_register_kind t WHERE t.pid = 'root' ORDER BY t.datatype, t.sort, t.id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_row_id, v_row_name, v_row_num, v_row_sort, v_row_datatype;
        EXIT WHEN v_cursor%NOTFOUND;
        v_isleaf := pkg_info_register_kind_pbl.f_isleaf(v_row_id);
        v_item   := '<item im0="folderClosed.gif"';
        v_item   := mystring.f_concat(v_item, ' im1="folderOpen.gif"');
        v_item   := mystring.f_concat(v_item, ' im2="folderClosed.gif"');
        IF v_isleaf = 1 THEN
          v_item := mystring.f_concat(v_item, ' child="0"');
        ELSE
          v_item := mystring.f_concat(v_item, ' child="1"');
        END IF;
        v_item := mystring.f_concat(v_item, ' id="', v_row_id, '"');
        v_item := mystring.f_concat(v_item, ' text="', myxml.f_escape(v_row_name), '">');
        v_item := mystring.f_concat(v_item, '<userdata name="kindid">', v_row_id, '</userdata>');
        v_item := mystring.f_concat(v_item, '<userdata name="kindname">', myxml.f_escape(v_row_name), '</userdata>');
        v_item := mystring.f_concat(v_item, '<userdata name="kindcode">', v_row_num, '</userdata>');
        IF v_isleaf = 1 THEN
          v_item := mystring.f_concat(v_item, '<userdata name="kindtype">2</userdata>');
        ELSE
          v_item := mystring.f_concat(v_item, '<userdata name="kindtype">1</userdata>');
        END IF;
        v_item := mystring.f_concat(v_item, '<userdata name="sort">', v_row_sort, '</userdata>');
        v_item := mystring.f_concat(v_item, '</item>');
      
        IF v_row_datatype = 1 THEN
          v_objcontent := mystring.f_concat(v_objcontent, v_item);
        ELSE
          v_objcontent2 := mystring.f_concat(v_objcontent2, v_item);
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
  
    v_objcontent := mystring.f_concat(v_objcontent, '</item>');
    v_objcontent := mystring.f_concat(v_objcontent, '</tree>');
  
    v_objcontent2 := mystring.f_concat(v_objcontent2, '</item>');
    v_objcontent2 := mystring.f_concat(v_objcontent2, '</tree>');
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, mystring.f_concat(' "code":"', o_code, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"msg":"', o_msg, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"objContent":"', myjson.f_escape(v_objcontent), '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"objContent2":"', myjson.f_escape(v_objcontent2), '"'));
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

  -- 查询单位(用户)分类/树-公共
  PROCEDURE p_gettree_pbl
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_pid         VARCHAR2(64);
    v_menutype    VARCHAR2(64);
    v_dept        VARCHAR2(8);
    v_user        VARCHAR2(8);
    v_type        VARCHAR2(64);
    v_objcontent  VARCHAR2(32767);
    v_objcontent2 VARCHAR2(32767);
  BEGIN
    mydebug.wlog('开始');
  
    -- 请求表单解析
    SELECT json_value(i_forminfo, '$.i_pid') INTO v_pid FROM dual;
    SELECT json_value(i_forminfo, '$.menutype') INTO v_menutype FROM dual;
    SELECT json_value(i_forminfo, '$.dept') INTO v_dept FROM dual;
    SELECT json_value(i_forminfo, '$.user') INTO v_user FROM dual;
    SELECT json_value(i_forminfo, '$.type') INTO v_type FROM dual;
    mydebug.wlog('v_pid', v_pid);
    mydebug.wlog('v_menutype', v_menutype);
    mydebug.wlog('v_dept', v_dept);
    mydebug.wlog('v_user', v_user);
    mydebug.wlog('v_type', v_type);
  
    IF v_dept = '1' OR v_type = 'dept' THEN
      IF v_menutype = 'register' THEN
        pkg_info_register.p_gettree(1, v_pid, i_operuri, i_opername, v_objcontent, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          RETURN;
        END IF;
      ELSE
        pkg_info_register_kind.p_gettree(1, v_pid, i_operuri, i_opername, v_objcontent, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          RETURN;
        END IF;
      END IF;
    END IF;
  
    IF v_user = '1' OR v_type = 'user' THEN
      IF v_menutype = 'register' THEN
        pkg_info_register.p_gettree(0, v_pid, i_operuri, i_opername, v_objcontent2, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          RETURN;
        END IF;
      ELSE
        pkg_info_register_kind.p_gettree(0, v_pid, i_operuri, i_opername, v_objcontent2, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          RETURN;
        END IF;
      END IF;
    END IF;
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, ' "code":"EC00"');
    dbms_lob.append(o_info, ',"msg":"');
    v_objcontent := myjson.f_escape(v_objcontent);
    IF mystring.f_isnotnull(v_objcontent) THEN
      dbms_lob.append(o_info, v_objcontent);
    END IF;
    v_objcontent2 := myjson.f_escape(v_objcontent2);
    IF mystring.f_isnotnull(v_objcontent2) THEN
      dbms_lob.append(o_info, v_objcontent2);
    END IF;
    dbms_lob.append(o_info, '"');
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
  名称     : pkg_info_register_kind.p_gettree
  功能描述 : 查询节点树
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-05  唐金鑫  创建
  
  返回信息(o_info)格式
  <kinds>
    <kinds>
      <id>唯一标识</id>
      <name>名称</name>
      <type>节点类型(1:中间节点、2:叶子节点)</type>
      <code>节点编号</code>
      <sort>排序号</sort>
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
    v_isleaf INT := 0;
  
    v_row_id   VARCHAR2(64);
    v_row_name VARCHAR2(128);
    v_row_num  INTEGER;
    v_row_sort INTEGER;
  
    v_root_name VARCHAR2(128);
    v_root_sort INTEGER;
  BEGIN
    mydebug.wlog('i_pid', i_pid);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD916', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
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
        SELECT t.id, t.name, t.num, t.sort
          FROM info_register_kind t
         WHERE t.pid = i_pid
           AND t.datatype = i_datatype
         ORDER BY t.sort, t.id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_row_id, v_row_name, v_row_num, v_row_sort;
        EXIT WHEN v_cursor%NOTFOUND;
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
        IF v_isleaf = 1 THEN
          o_info := mystring.f_concat(o_info, '<userdata name="kindtype">2</userdata>');
        ELSE
          o_info := mystring.f_concat(o_info, '<userdata name="kindtype">1</userdata>');
        END IF;
        o_info := mystring.f_concat(o_info, '<userdata name="sort">', v_row_sort, '</userdata>');
        o_info := mystring.f_concat(o_info, '</item>');
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
      ROLLBACK;
      o_info := NULL;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 查询默认排序-公共
  PROCEDURE p_getsort_pbl
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_pid      VARCHAR2(64);
    v_datatype INT := 0;
    v_kindid   VARCHAR2(64);
    v_type     VARCHAR2(64);
    v_sort     VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    -- 请求表单解析
    SELECT json_value(i_forminfo, '$.type') INTO v_type FROM dual;
    mydebug.wlog('v_type', v_type);
  
    IF v_type = 'dept' THEN
      SELECT json_value(i_forminfo, '$.i_kindid') INTO v_kindid FROM dual;
      pkg_info_register.p_getsort(v_kindid, i_operuri, i_opername, v_sort, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSIF v_type = 'user' THEN
      SELECT json_value(i_forminfo, '$.i_kindid') INTO v_kindid FROM dual;
      pkg_info_register.p_getsort(v_kindid, i_operuri, i_opername, v_sort, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSE
      IF v_type = 'userkind' THEN
        v_datatype := 0;
      ELSE
        v_datatype := 1;
      END IF;
      SELECT json_value(i_forminfo, '$.i_pid') INTO v_pid FROM dual;
      pkg_info_register_kind.p_getsort(v_datatype, v_pid, i_operuri, i_opername, v_sort, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    END IF;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, ' "code":"', o_code, '"');
    o_info := mystring.f_concat(o_info, ',"msg":"', o_msg, '"');
    o_info := mystring.f_concat(o_info, ',"tempContent":"', v_sort, '"');
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

  /***************************************************************************************************
  名称     : pkg_info_register_kind.p_getsort
  功能描述 : 查询默认排序号
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-05  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getsort
  (
    i_datatype IN INT,
    i_pid      IN VARCHAR2, -- 上级标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_sort     OUT VARCHAR2, -- 排序号
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sort INT := 0;
  BEGIN
    mydebug.wlog('i_pid', i_pid);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT MAX(t.sort)
      INTO v_sort
      FROM info_register_kind t
     WHERE t.pid = i_pid
       AND t.datatype = i_datatype;
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

  -- 增加
  PROCEDURE p_ins
  (
    i_type     IN VARCHAR2, -- 类型
    i_name     IN VARCHAR2, -- 名称
    i_pid      IN VARCHAR2, -- 上级ID
    i_sort     IN VARCHAR2, -- 排序
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id         VARCHAR2(64);
    v_num        INT;
    v_idpath     VARCHAR2(512);
    v_idpath_p   VARCHAR2(512);
    v_fullsort   VARCHAR2(128);
    v_fullsort_p VARCHAR2(128);
    v_exists     INT := 0;
    v_datatype   INT;
  BEGIN
    mydebug.wlog('i_type', i_type);
    mydebug.wlog('i_name', i_name);
    mydebug.wlog('i_pid', i_pid);
    mydebug.wlog('i_sort', i_sort);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD916', i_operuri, i_opername, o_code, o_msg);
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
  
    IF mystring.f_isnull(i_name) THEN
      o_code := 'EC02';
      o_msg  := '名称为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_pid) THEN
      o_code := 'EC02';
      o_msg  := '上级ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_sort) THEN
      o_code := 'EC02';
      o_msg  := '排序号为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF i_type = 'user' THEN
      v_datatype := 0;
    ELSE
      v_datatype := 1;
    END IF;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_register_kind t
             WHERE t.pid = i_pid
               AND t.name = i_name
               AND t.datatype = v_datatype);
    IF v_exists = 1 THEN
      o_code := 'EC02';
      o_msg  := '该分类已存在,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT MAX(t.num) INTO v_num FROM info_register_kind t WHERE datatype = v_datatype;
    IF v_num IS NULL THEN
      v_num := 10001;
    ELSE
      IF v_num < 10001 THEN
        v_num := 10001;
      ELSE
        v_num := v_num + 1;
      END IF;
    END IF;
  
    v_id := pkg_basic.f_newid('KD');
  
    v_idpath_p := pkg_info_register_kind_pbl.f_getidpath(i_pid);
    IF mystring.f_isnull(v_idpath_p) THEN
      v_idpath := mystring.f_concat('/', v_id, '/');
    ELSE
      v_idpath := mystring.f_concat(v_idpath_p, v_id, '/');
    END IF;
  
    v_fullsort_p := pkg_info_register_kind_pbl.f_getfullsort(i_pid);
    v_fullsort   := lpad(i_sort, 8, '0');
    IF mystring.f_isnull(v_fullsort_p) THEN
      v_fullsort := mystring.f_concat('/', v_fullsort, '/');
    ELSE
      v_fullsort := mystring.f_concat(v_fullsort_p, v_fullsort, '/');
    END IF;
  
    INSERT INTO info_register_kind
      (id, NAME, num, datatype, pid, idpath, fullsort, sort, isdefault, operuri, opername)
    VALUES
      (v_id, i_name, v_num, v_datatype, i_pid, v_idpath, v_fullsort, i_sort, 0, i_operuri, i_opername);
  
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
    i_type     IN VARCHAR2, -- 类型
    i_id       IN VARCHAR2, -- 标识
    i_name     IN VARCHAR2, -- 名称
    i_sort     IN VARCHAR2, -- 排序
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists       INT := 0;
    v_pid          VARCHAR2(64);
    v_fullsort     VARCHAR2(128);
    v_fullsort_p   VARCHAR2(128);
    v_fullsort_len INT := 0;
    v_datatype     INT;
    v_idpath       VARCHAR2(512);
  
  BEGIN
    mydebug.wlog('i_type', i_type);
    mydebug.wlog('i_id', i_id);
    mydebug.wlog('i_name', i_name);
    mydebug.wlog('i_sort', i_sort);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD916', i_operuri, i_opername, o_code, o_msg);
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
  
    IF mystring.f_isnull(i_id) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_name) THEN
      o_code := 'EC02';
      o_msg  := '名称为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_sort) THEN
      o_code := 'EC02';
      o_msg  := '排序号为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF i_id = 'root' THEN
      IF i_type = 'user' THEN
        UPDATE info_register_kind_root t SET t.name = i_name, t.sort = i_sort, t.modifieddate = SYSDATE WHERE t.id = 'root0';
      ELSE
        UPDATE info_register_kind_root t SET t.name = i_name, t.sort = i_sort, t.modifieddate = SYSDATE WHERE t.id = 'root1';
      END IF;
    ELSE
      SELECT COUNT(1) INTO v_exists FROM info_register_kind t WHERE t.id = i_id;
      IF v_exists = 0 THEN
        o_code := 'EC02';
        o_msg  := '查询数据出错,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    
      SELECT t.pid, t.datatype, idpath INTO v_pid, v_datatype, v_idpath FROM info_register_kind t WHERE t.id = i_id;
    
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM info_register_kind t
               WHERE t.pid = v_pid
                 AND t.datatype = v_datatype
                 AND t.name = i_name
                 AND t.id <> i_id);
      IF v_exists = 1 THEN
        o_code := 'EC02';
        o_msg  := '该分类已存在,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    
      v_fullsort_p := pkg_info_register_kind_pbl.f_getfullsort(v_pid);
      v_fullsort   := lpad(i_sort, 8, '0');
      IF mystring.f_isnull(v_fullsort_p) THEN
        v_fullsort := mystring.f_concat('/', v_fullsort, '/');
      ELSE
        v_fullsort := mystring.f_concat(v_fullsort_p, v_fullsort, '/');
      END IF;
    
      UPDATE info_register_kind t SET t.name = i_name, t.sort = i_sort, t.fullsort = v_fullsort, t.modifieddate = SYSDATE WHERE t.id = i_id;
    
      -- 修正子节点的全排序
      v_fullsort_len := length(v_fullsort);
      v_fullsort_len := v_fullsort_len + 1;
      UPDATE info_register_kind t
         SET t.fullsort = mystring.f_concat(v_fullsort, substr(t.fullsort, v_fullsort_len))
       WHERE instr(t.idpath, v_idpath) > 0
         AND t.id <> i_id;
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

  -- 删除
  PROCEDURE p_del
  (
    i_id       IN VARCHAR2, -- 标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists   INT := 0;
    v_datatype INT;
  BEGIN
    mydebug.wlog('i_id', i_id);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD916', i_operuri, i_opername, o_code, o_msg);
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
  
    IF mystring.f_isnull(i_id) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT datatype INTO v_datatype FROM info_register_kind WHERE id = i_id;
  
    SELECT COUNT(1) INTO v_exists FROM info_register_obj t1 WHERE t1.kindid = i_id;
    IF v_exists > 0 THEN
      o_code := 'EC02';
      IF v_datatype = 0 THEN
        o_msg := '存在已注册用户信息,请检查！';
      ELSE
        o_msg := '存在已注册单位信息,请检查！';
      END IF;
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM info_register_kind t WHERE t.pid = i_id;
    IF v_exists > 0 THEN
      o_code := 'EC02';
      o_msg  := ' 请先删除子节点,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 删除
    DELETE FROM info_register_kind WHERE id = i_id;
  
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
  名称     : pkg_info_register_kind.p_oper
  功能描述 : 添加/删除/修改
  
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
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_type     VARCHAR2(64);
    v_opertype VARCHAR2(64);
    v_id       VARCHAR2(64);
    v_name     VARCHAR2(200);
    v_pid      VARCHAR2(64);
    v_sort     VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    -- 请求表单解析
    SELECT json_value(i_forminfo, '$.type') INTO v_type FROM dual;
    SELECT json_value(i_forminfo, '$.i_opertype') INTO v_opertype FROM dual;
    SELECT json_value(i_forminfo, '$.i_id') INTO v_id FROM dual;
    SELECT json_value(i_forminfo, '$.i_name') INTO v_name FROM dual;
    SELECT json_value(i_forminfo, '$.i_pid') INTO v_pid FROM dual;
    SELECT json_value(i_forminfo, '$.i_sort') INTO v_sort FROM dual;
  
    mydebug.wlog('v_opertype', v_opertype);
  
    IF mystring.f_isnull(v_opertype) OR v_opertype NOT IN ('1', '0', '2') THEN
      o_code := 'EC02';
      o_msg  := '操作类型错误,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_opertype = '1' THEN
      -- 增加
      pkg_info_register_kind.p_ins(v_type, v_name, v_pid, v_sort, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSIF v_opertype = '0' THEN
      -- 删除
      pkg_info_register_kind.p_del(v_id, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSIF v_opertype = '2' THEN
      -- 修改
      pkg_info_register_kind.p_upd(v_type, v_id, v_name, v_sort, i_operuri, i_opername, o_code, o_msg);
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
END;
/
