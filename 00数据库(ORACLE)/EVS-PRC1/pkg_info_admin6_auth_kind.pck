CREATE OR REPLACE PACKAGE pkg_info_admin6_auth_kind IS

  /***************************************************************************************************
  名称     : pkg_info_admin6_auth_kind
  功能描述 : 操作员授权-对象分类树
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-31  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询叶子节点ID集合
  FUNCTION f_getkindids_all
  (
    i_otype  INT, -- 1:单位 0:个人
    i_kindid VARCHAR2, -- 分类ID
    i_dtype  VARCHAR2
  ) RETURN VARCHAR2;

  -- 查询用户的叶子节点ID集合
  FUNCTION f_getkindids_user
  (
    i_otype   INT, -- 1:单位 0:个人
    i_kindid  VARCHAR2, -- 分类ID
    i_dtype   VARCHAR2,
    i_useruri VARCHAR2
  ) RETURN VARCHAR2;

  -- 签发公共参数-查询对象分类树根节点
  PROCEDURE p_getkind_first
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 签发公共参数-查询对象分类树
  PROCEDURE p_getkind
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 保存参数
  PROCEDURE p_save
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_admin6_auth_kind IS

  -- 查询叶子节点ID集合
  FUNCTION f_getkindids_all
  (
    i_otype  INT, -- 1:单位 0:个人
    i_kindid VARCHAR2, -- 分类ID
    i_dtype  VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
    v_num    INT := 0;
    v_id     VARCHAR2(64);
  BEGIN
    DECLARE
      CURSOR v_cursor IS
        SELECT id
          FROM info_register_kind t
         WHERE datatype = i_otype
           AND instr(idpath, i_kindid) > 0
           AND EXISTS (SELECT 1
                  FROM info_template_kind w
                 WHERE w.tempid = i_dtype
                   AND w.kindid = t.id)
         ORDER BY id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num = 1 THEN
          v_result := v_id;
        ELSE
          v_result := mystring.f_concat(v_result, ',', v_id);
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

  -- 查询用户的叶子节点ID集合
  FUNCTION f_getkindids_user
  (
    i_otype   INT, -- 1:单位 0:个人
    i_kindid  VARCHAR2, -- 分类ID
    i_dtype   VARCHAR2,
    i_useruri VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
    v_num    INT := 0;
    v_id     VARCHAR2(64);
  BEGIN
    DECLARE
      CURSOR v_cursor IS
        SELECT id
          FROM info_register_kind t
         WHERE datatype = i_otype
           AND instr(idpath, i_kindid) > 0
           AND EXISTS (SELECT 1
                  FROM info_template_kind w1
                 WHERE w1.tempid = i_dtype
                   AND w1.kindid = t.id)
           AND EXISTS (SELECT 1
                  FROM info_admin_auth_kind w2
                 WHERE w2.useruri = i_useruri
                   AND w2.dtype = i_dtype
                   AND w2.kindid = t.id)
         ORDER BY id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num = 1 THEN
          v_result := v_id;
        ELSE
          v_result := mystring.f_concat(v_result, ',', v_id);
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

  /***************************************************************************************************
  名称     : pkg_info_admin6_auth_kind.p_getkind_first
  功能描述 : 签发公共参数-查询对象分类树根节点
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-15  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getkind_first
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_useruri VARCHAR2(64);
    v_dtype   VARCHAR2(64);
  
    v_exists INT := 0;
    v_idpath VARCHAR2(64);
  
    v_row_id       VARCHAR2(64);
    v_row_kindname VARCHAR2(64);
    v_row_isleaf   INT;
    v_row_status   INT;
    v_row_ids      VARCHAR2(4000);
    v_root_name    VARCHAR2(128);
  
    v_ids_all VARCHAR2(4000);
  
    v_otype INT;
    v_tree  VARCHAR2(32767);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.i_useruri') INTO v_useruri FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    mydebug.wlog('v_useruri', v_useruri);
    mydebug.wlog('v_dtype', v_dtype);
  
    v_otype     := pkg_info_template_pbl.f_getotype(v_dtype);
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
    v_tree := mystring.f_concat(v_tree, '<userdata name="hand">0</userdata>');
  
    -- 执行sql
    DECLARE
      CURSOR v_cursor IS
        SELECT id, NAME
          FROM info_register_kind
         WHERE datatype = v_otype
           AND pid = 'root'
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
      
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM info_register_kind w1
                 INNER JOIN info_template_kind w2
                    ON (w2.tempid = v_dtype AND w2.kindid = w1.id)
                 WHERE w1.datatype = v_otype
                   AND instr(w1.idpath, v_idpath) > 0);
      
        IF v_exists = 1 THEN
          v_ids_all := pkg_info_admin6_auth_kind.f_getkindids_all(v_otype, v_row_id, v_dtype);
          IF mystring.f_isnotnull(v_ids_all) THEN
            v_row_ids    := pkg_info_admin6_auth_kind.f_getkindids_user(v_otype, v_row_id, v_dtype, v_useruri);
            v_row_status := 0;
            IF mystring.f_isnotnull(v_row_ids) THEN
              IF v_row_ids = v_ids_all THEN
                v_row_status := 1;
              ELSE
                v_row_status := 2;
              END IF;
            END IF;
          
            v_row_isleaf := pkg_info_register_kind_pbl.f_isleaf(v_row_id);
          
            v_tree := mystring.f_concat(v_tree, '<item im0="folderClosed.gif"');
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
            IF v_row_isleaf = 1 THEN
              v_tree := mystring.f_concat(v_tree, '<userdata name="kindtype">2</userdata>');
            ELSE
              v_tree := mystring.f_concat(v_tree, '<userdata name="kindtype">1</userdata>');
            END IF;
            v_tree := mystring.f_concat(v_tree, '<userdata name="kindstatus">', v_row_status, '</userdata>');
            v_tree := mystring.f_concat(v_tree, '<userdata name="ids">', v_row_ids, '</userdata>');
            v_tree := mystring.f_concat(v_tree, '<userdata name="hand">0</userdata>');
            v_tree := mystring.f_concat(v_tree, '</item>');
          END IF;
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
    dbms_lob.append(o_info, ' "code":"EC00"');
    dbms_lob.append(o_info, ',"msg":"');
    dbms_lob.append(o_info, myjson.f_escape(v_tree));
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
  名称     : pkg_info_admin6_auth_kind.p_getkind
  功能描述 : 签发公共参数-查询对象分类树
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-30  唐金鑫  创建
  
  返回信息(o_info)格式
  <rows>
    <row>
      <id>唯一标识</id>
      <name>名称</name>
      <type>节点类型(1:中间节点、2:叶子节点)</type>
      <status>是否存在选中的子节点(1:是 0:否 2:存在部分选中的子节点)</status>
      <ids>选中叶子节点ID，逗号分割</ids>
    </row>
  </rows>
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getkind
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 返回信息集合(前台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_useruri VARCHAR2(64);
    v_dtype   VARCHAR2(64);
    v_pid     VARCHAR2(64);
  
    v_exists INT := 0;
    v_idpath VARCHAR2(64);
  
    v_row_id       VARCHAR2(64);
    v_row_kindname VARCHAR2(64);
    v_row_isleaf   INT;
    v_row_status   INT;
    v_row_ids      VARCHAR2(4000);
    v_root_name    VARCHAR2(128);
  
    v_ids_all VARCHAR2(4000);
  
    v_otype INT;
    v_tree  VARCHAR2(32767);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.i_useruri') INTO v_useruri FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_pid') INTO v_pid FROM dual;
    mydebug.wlog('v_useruri', v_useruri);
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_pid', v_pid);
  
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
      v_tree := mystring.f_concat(v_tree, '<userdata name="hand">0</userdata>');
      v_tree := mystring.f_concat(v_tree, '</item>');
      v_tree := mystring.f_concat(v_tree, '</tree>');
    
      dbms_lob.createtemporary(o_info, TRUE);
      dbms_lob.append(o_info, '{');
      dbms_lob.append(o_info, ' "code":"EC00"');
      dbms_lob.append(o_info, ',"msg":"');
      dbms_lob.append(o_info, myjson.f_escape(v_tree));
      dbms_lob.append(o_info, '"');
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
        SELECT id, NAME
          FROM info_register_kind
         WHERE pid = v_pid
           AND datatype = v_otype
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
      
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM info_register_kind w1
                 INNER JOIN info_template_kind w2
                    ON (w2.tempid = v_dtype AND w2.kindid = w1.id)
                 WHERE w1.datatype = v_otype
                   AND instr(w1.idpath, v_idpath) > 0);
      
        IF v_exists = 1 THEN
          v_ids_all := pkg_info_admin6_auth_kind.f_getkindids_all(v_otype, v_row_id, v_dtype);
          IF mystring.f_isnotnull(v_ids_all) THEN
            v_row_ids    := pkg_info_admin6_auth_kind.f_getkindids_user(v_otype, v_row_id, v_dtype, v_useruri);
            v_row_status := 0;
            IF mystring.f_isnotnull(v_row_ids) THEN
              IF v_row_ids = v_ids_all THEN
                v_row_status := 1;
              ELSE
                v_row_status := 2;
              END IF;
            END IF;
          
            v_row_isleaf := pkg_info_register_kind_pbl.f_isleaf(v_row_id);
          
            v_tree := mystring.f_concat(v_tree, '<item im0="folderClosed.gif"');
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
            IF v_row_isleaf = 1 THEN
              v_tree := mystring.f_concat(v_tree, '<userdata name="kindtype">2</userdata>');
            ELSE
              v_tree := mystring.f_concat(v_tree, '<userdata name="kindtype">1</userdata>');
            END IF;
            v_tree := mystring.f_concat(v_tree, '<userdata name="kindstatus">', v_row_status, '</userdata>');
            v_tree := mystring.f_concat(v_tree, '<userdata name="ids">', v_row_ids, '</userdata>');
            v_tree := mystring.f_concat(v_tree, '<userdata name="hand">0</userdata>');
            v_tree := mystring.f_concat(v_tree, '</item>');
          END IF;
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
    mydebug.wlog('v_tree', v_tree);
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, ' "code":"EC00"');
    dbms_lob.append(o_info, ',"msg":"');
    dbms_lob.append(o_info, myjson.f_escape(v_tree));
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
  名称     : pkg_info_admin6_auth_kind.p_save
  功能描述 : 保存签发对象类型
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-31  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_save
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_useruri   VARCHAR2(64);
    v_dtype     VARCHAR2(64);
    v_kindids   VARCHAR2(4000);
    v_idpath    VARCHAR2(512);
    v_otype     INT;
    v_exists    INT := 0;
    v_ids_count INT := 0;
    v_i         INT := 0;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_useruri') INTO v_useruri FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_kindid') INTO v_kindids FROM dual;
    mydebug.wlog('v_useruri', v_useruri);
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_kindids', v_kindids);
  
    IF mystring.f_isnull(v_useruri) THEN
      o_code := 'EC02';
      o_msg  := '人员标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_dtype) THEN
      o_code := 'EC02';
      o_msg  := '凭证类型代码为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_kindids) THEN
      o_code := 'EC02';
      o_msg  := '对象分类ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_ids_count := myarray.f_getcount(v_kindids, ',');
    IF v_ids_count = 0 THEN
      o_code := 'EC02';
      o_msg  := '对象分类ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_otype := pkg_info_template_pbl.f_getotype(v_dtype);
  
    -- 未授权，直接退出
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_admin_auth t
             WHERE t.dtype = v_dtype
               AND t.useruri = v_useruri);
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
    END IF;
  
    DELETE FROM info_admin_auth_kind
     WHERE useruri = v_useruri
       AND dtype = v_dtype;
  
    IF instr(v_kindids, 'root') > 0 THEN
      INSERT INTO info_admin_auth_kind
        (id, useruri, dtype, kindid, operuri, opername)
        SELECT mystring.f_concat(v_useruri, v_dtype, t.id), v_useruri, v_dtype, t.id, i_operuri, i_opername
          FROM info_register_kind t
         WHERE t.datatype = v_otype
           AND EXISTS (SELECT 1
                  FROM info_template_kind w
                 WHERE w.tempid = v_dtype
                   AND w.kindid = t.id);
    ELSE
      v_i := 1;
      WHILE v_i <= v_ids_count LOOP
        v_idpath := myarray.f_getvalue(v_kindids, ',', v_i);
        IF mystring.f_isnotnull(v_idpath) THEN
          INSERT INTO info_admin_auth_kind
            (id, useruri, dtype, kindid, operuri, opername)
            SELECT mystring.f_concat(v_useruri, v_dtype, t.id), v_useruri, v_dtype, t.id, i_operuri, i_opername
              FROM info_register_kind t
             WHERE t.datatype = v_otype
               AND instr(t.idpath, v_idpath) > 0
               AND EXISTS (SELECT 1
                      FROM info_template_kind w1
                     WHERE w1.tempid = v_dtype
                       AND w1.kindid = t.id)
               AND NOT EXISTS (SELECT 1
                      FROM info_admin_auth_kind w2
                     WHERE w2.useruri = v_useruri
                       AND w2.dtype = v_dtype
                       AND w2.kindid = t.id);
        END IF;
        v_i := v_i + 1;
      END LOOP;
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
END;
/
