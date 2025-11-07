CREATE OR REPLACE PACKAGE pkg_info_template IS

  /***************************************************************************************************
  名称     : pkg_info_template
  功能描述 : 凭证参数维护
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-19  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询叶子节点ID集合
  FUNCTION f_getkindids_all
  (
    i_otype  INT,
    i_kindid VARCHAR2
  ) RETURN VARCHAR2;

  -- 查询当前凭证的叶子节点ID集合
  FUNCTION f_getkindids_tempid
  (
    i_otype  INT,
    i_kindid VARCHAR2,
    i_tempid VARCHAR2
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

  -- 模板导出
  PROCEDURE p_downcard
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT CLOB, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 查询凭证参数-印制参数
  PROCEDURE p_getinfo1
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询凭证参数-签发业务
  FUNCTION f_getqfoper
  (
    i_tempid  VARCHAR2, -- 模板标识
    i_type    VARCHAR2,
    i_info    VARCHAR2,
    i_realnum VARCHAR2
  ) RETURN VARCHAR2;

  -- 查询凭证参数-签发参数
  PROCEDURE p_getinfo2
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询凭证参数
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 保存特有参数
  PROCEDURE p_prvdata_set
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询特有参数
  PROCEDURE p_prvdata_get
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 保存空白印制公共参数
  PROCEDURE p_save1
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_info     IN CLOB, -- 参数信息
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 保存签发业务类型
  PROCEDURE p_save2
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_info     IN CLOB, -- 参数信息
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 保存签发公共参数
  PROCEDURE p_save3
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_info     IN CLOB, -- 参数信息
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
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
CREATE OR REPLACE PACKAGE BODY pkg_info_template IS

  -- 查询叶子节点ID集合
  FUNCTION f_getkindids_all
  (
    i_otype  INT,
    i_kindid VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
    v_num    INT := 0;
    v_id     VARCHAR2(64);
    v_idpath VARCHAR2(512);
    v_select INT := 0;
  BEGIN
    DECLARE
      CURSOR v_cursor IS
        SELECT id, idpath FROM info_register_kind WHERE datatype = i_otype ORDER BY id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_idpath;
        EXIT WHEN v_cursor%NOTFOUND;
        v_select := 0;
        IF i_kindid = 'root' THEN
          v_select := 1;
        ELSE
          IF instr(v_idpath, i_kindid) > 0 THEN
            v_select := 1;
          END IF;
        END IF;
        IF v_select = 1 THEN
          v_num := v_num + 1;
          IF v_num = 1 THEN
            v_result := v_id;
          ELSE
            v_result := mystring.f_concat(v_result, ',', v_id);
          END IF;
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

  -- 查询当前凭证的叶子节点ID集合
  FUNCTION f_getkindids_tempid
  (
    i_otype  INT,
    i_kindid VARCHAR2,
    i_tempid VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
    v_num    INT := 0;
    v_id     VARCHAR2(64);
    v_idpath VARCHAR2(512);
    v_select INT := 0;
  BEGIN
    DECLARE
      CURSOR v_cursor IS
        SELECT id, idpath
          FROM info_register_kind t
         WHERE datatype = i_otype
           AND EXISTS (SELECT 1
                  FROM info_template_kind w
                 WHERE w.tempid = i_tempid
                   AND w.kindid = t.id)
         ORDER BY id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_idpath;
        EXIT WHEN v_cursor%NOTFOUND;
        v_select := 0;
        IF i_kindid = 'root' THEN
          v_select := 1;
        ELSE
          IF instr(v_idpath, i_kindid) > 0 THEN
            v_select := 1;
          END IF;
        END IF;
        IF v_select = 1 THEN
          v_num := v_num + 1;
          IF v_num = 1 THEN
            v_result := v_id;
          ELSE
            v_result := mystring.f_concat(v_result, ',', v_id);
          END IF;
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
  名称     : pkg_info_template.p_getkind_first
  功能描述 : 签发公共参数-查询对象分类树根节点
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-15  唐金鑫  创建
  
  业务说明
  <?xml version="1.0" encoding="UTF-8"?>
  <tree id="0">
      <item im0="folderClosed.gif" im1="folderOpen.gif" im2="folderClosed.gif" child="1:有子节点 0:没有子节点" id="唯一标识" text="名称">
          <userdata name="kindid">唯一标识</userdata>
          <userdata name="kindname">名称</userdata>
          <userdata name="kindtype">节点类型(1:中间节点、2:叶子节点)</userdata>
          <userdata name="hand">0</userdata>
          <item im0="folderClosed.gif" im1="folderOpen.gif" im2="folderClosed.gif" child="1:有子节点 0:没有子节点" id="唯一标识" text="名称">
              <userdata name="kindid">唯一标识</userdata>
              <userdata name="kindname">名称</userdata>
              <userdata name="kindtype">节点类型(1:中间节点、2:叶子节点)</userdata>
              <userdata name="kindstatus">勾选状态(0:未选 1:已选 2:灰勾)</userdata>
              <userdata name="ids">被选中的叶子节点ID，逗号分割</userdata>
              <userdata name="hand">0</userdata>
          </item>
      </item>
  </tree>
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
    v_tempid    VARCHAR2(64);
    v_setstatus INT := 0; -- 是否已设置(1:是 0:否)
  
    v_row_id       VARCHAR2(64);
    v_row_kindname VARCHAR2(64);
    v_row_isleaf   INT;
    v_row_status   INT;
    v_row_ids      VARCHAR2(4000);
    v_root_name    VARCHAR2(128);
  
    v_ids_all VARCHAR2(4000);
    v_otype   INT;
    v_tree    VARCHAR2(32767);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    mydebug.wlog('v_tempid', v_tempid);
  
    v_otype := pkg_info_template_pbl.f_getotype(v_tempid);
  
    SELECT COUNT(1) INTO v_setstatus FROM dual WHERE EXISTS (SELECT 1 FROM info_template_kind t WHERE t.tempid = v_tempid);
  
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
      
        v_ids_all := pkg_info_template.f_getkindids_all(v_otype, v_row_id);
        IF mystring.f_isnotnull(v_ids_all) THEN
          IF v_setstatus = 0 THEN
            v_row_status := 1;
            v_row_ids    := v_ids_all;
          ELSE
            v_row_ids    := pkg_info_template.f_getkindids_tempid(v_otype, v_row_id, v_tempid);
            v_row_status := 0;
            IF mystring.f_isnotnull(v_row_ids) THEN
              IF v_row_ids = v_ids_all THEN
                v_row_status := 1;
              ELSE
                v_row_status := 2;
              END IF;
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
  名称     : pkg_info_template.p_getkind
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
    v_tempid    VARCHAR2(64);
    v_pid       VARCHAR2(64);
    v_setstatus INT := 0; -- 是否已设置(1:是 0:否)
  
    v_row_id       VARCHAR2(64);
    v_row_kindname VARCHAR2(64);
    v_row_isleaf   INT;
    v_row_status   INT;
    v_row_ids      VARCHAR2(4000);
    v_root_name    VARCHAR2(128);
  
    v_ids_all VARCHAR2(4000);
    v_otype   INT;
    v_tree    VARCHAR2(32767);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    SELECT json_value(i_forminfo, '$.i_pid') INTO v_pid FROM dual;
    mydebug.wlog('v_tempid', v_tempid);
    mydebug.wlog('v_pid', v_pid);
  
    v_otype := pkg_info_template_pbl.f_getotype(v_tempid);
  
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
      dbms_lob.append(o_info, mystring.f_concat(',"msg":"', myjson.f_escape(v_tree), '"'));
      dbms_lob.append(o_info, '}');
    
      mydebug.wlog('o_info', o_info);
    
      -- 8.处理成功
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_setstatus FROM dual WHERE EXISTS (SELECT 1 FROM info_template_kind t WHERE t.tempid = v_tempid);
  
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
      
        v_ids_all := pkg_info_template.f_getkindids_all(v_otype, v_row_id);
        IF mystring.f_isnotnull(v_ids_all) THEN
          IF v_setstatus = 0 THEN
            v_row_status := 1;
            v_row_ids    := v_ids_all;
          ELSE
            v_row_ids    := pkg_info_template.f_getkindids_tempid(v_otype, v_row_id, v_tempid);
            v_row_status := 0;
            IF mystring.f_isnotnull(v_row_ids) THEN
              IF v_row_ids = v_ids_all THEN
                v_row_status := 1;
              ELSE
                v_row_status := 2;
              END IF;
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
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, ' "code":"EC00"');
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
  名称     : pkg_info_template.p_downcard
  功能描述 : 模板导出
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-10  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_downcard
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT CLOB, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_methodname VARCHAR2(64);
    v_dataxml    VARCHAR2(4000);
    v_dtype      VARCHAR2(64);
    v_filename   VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    -- 解析表单信息
    SELECT json_value(i_forminfo, '$.methodname') INTO v_methodname FROM dual;
    mydebug.wlog('v_methodname', v_methodname);
  
    -- 返回文件
    IF v_methodname = 'useTemplateOrNot_batload' THEN
      SELECT json_value(i_forminfo, '$.dataxml') INTO v_dataxml FROM dual;
      o_info1 := v_dataxml;
      o_info2 := '<info>';
      o_info2 := mystring.f_concat(o_info2, '<dlfiles>');
      DECLARE
        v_xml   xmltype;
        v_i     INT := 0;
        v_xpath VARCHAR2(200);
      BEGIN
        v_xml := xmltype(v_dataxml);
        v_i   := 1;
        WHILE v_i <= 100 LOOP
          v_xpath := mystring.f_concat('/rows/row[', v_i, ']/');
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'dtype')) INTO v_dtype FROM dual;
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'filename')) INTO v_filename FROM dual;
          IF mystring.f_isnull(v_dtype) THEN
            v_i := 100;
          ELSE
            o_info2 := mystring.f_concat(o_info2, '<file flag="datafile">');
            o_info2 := mystring.f_concat(o_info2, pkg_info_template_pbl.f_getfilepath(v_dtype), v_filename);
            o_info2 := mystring.f_concat(o_info2, '</file>');
          END IF;
          v_i := v_i + 1;
        END LOOP;
      END;
      o_info2 := mystring.f_concat(o_info2, '</dlfiles>');
      o_info2 := mystring.f_concat(o_info2, '</info>');
    ELSE
      SELECT json_value(i_forminfo, '$.dtype') INTO v_dtype FROM dual;
      SELECT json_value(i_forminfo, '$.filename') INTO v_filename FROM dual;
      o_info1 := '{"code":"EC00","msg":"处理成功"}';
      o_info2 := '<info>';
      o_info2 := mystring.f_concat(o_info2, '<dlfiles>');
      o_info2 := mystring.f_concat(o_info2, '<file flag="datafile">');
      o_info2 := mystring.f_concat(o_info2, pkg_info_template_pbl.f_getfilepath(v_dtype), v_filename);
      o_info2 := mystring.f_concat(o_info2, '</file>');
      o_info2 := mystring.f_concat(o_info2, '</dlfiles>');
      o_info2 := mystring.f_concat(o_info2, '</info>');
    END IF;
  
    mydebug.wlog('o_info1', o_info1);
    mydebug.wlog('o_info2', o_info2);
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_info1 := NULL;
      o_info2 := NULL;
      o_code  := 'EC03';
      o_msg   := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_info_template.p_getinfo1
  功能描述 : 查询凭证参数-印制参数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-19  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getinfo1
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_tempname      VARCHAR2(128);
    v_billorg       VARCHAR2(128); -- 印制机构
    v_billcode      VARCHAR2(64); -- 票据编码
    v_billcount     INT; -- 票据份数
    v_dtype         VARCHAR2(256); -- 凭证大类
    v_issplit       VARCHAR2(8); -- 是否支持分签(0:不支持 1:支持)
    v_merge         VARCHAR2(8); -- 合并方式(0:不支持 1:按凭证类型 2:按签发者+凭证类型 3:按签发者+凭证类型+特别参数)
    v_master_new    VARCHAR2(128); -- 合并目标凭证
    v_master        VARCHAR2(64);
    v_masternm      VARCHAR2(128);
    v_master1       VARCHAR2(64);
    v_masternm1     VARCHAR2(128);
    v_attr          VARCHAR2(4000); -- 自定义参数
    v_pickusage     VARCHAR2(512); -- 默认提取用途
    v_forwardreason VARCHAR2(512); -- 默认转发原因
    v_operunm       VARCHAR2(64);
    v_operdate      DATE;
  BEGIN
    mydebug.wlog('i_tempid', i_tempid);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    BEGIN
      SELECT tempname, billcode, billorg, billcount, issplit, mtype, masternm, master, masternm1, master1, operunm, operdate
        INTO v_tempname, v_billcode, v_billorg, v_billcount, v_issplit, v_merge, v_masternm, v_master, v_masternm1, v_master1, v_operunm, v_operdate
        FROM info_template t
       WHERE t.tempid = i_tempid;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    BEGIN
      SELECT attr, pickusage, forwardreason INTO v_attr, v_pickusage, v_forwardreason FROM info_template_attr t WHERE t.tempid = i_tempid;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_dtype := mystring.f_concat(v_tempname, '(', i_tempid, ')');
  
    IF mystring.f_isnotnull(v_masternm) THEN
      v_master_new := mystring.f_concat(v_masternm, '(', v_master, ')');
    END IF;
    IF mystring.f_isnotnull(v_masternm1) THEN
      IF mystring.f_isnull(v_master_new) THEN
        v_master_new := mystring.f_concat(v_masternm1, '(', v_master1, ')');
      ELSE
        v_master_new := mystring.f_concat(v_master_new, ',', v_masternm1, '(', v_master1, ')');
      END IF;
    END IF;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"objContent":{');
    o_info := mystring.f_concat(o_info, '"dataInfo":{');
    o_info := mystring.f_concat(o_info, ' "billorg":"', v_billorg, '"');
    IF mystring.f_isnotnull(v_billcode) THEN
      o_info := mystring.f_concat(o_info, ',"billcode":"', v_billcode, '"');
    END IF;
    o_info := mystring.f_concat(o_info, ',"billcount":"', v_billcount, '"');
    o_info := mystring.f_concat(o_info, ',"dtype":"', v_dtype, '"');
    o_info := mystring.f_concat(o_info, ',"temptype":"', i_tempid, '"');
    o_info := mystring.f_concat(o_info, ',"issplit":"', v_issplit, '"');
    IF mystring.f_isnotnull(v_merge) THEN
      o_info := mystring.f_concat(o_info, ',"merge":"', v_merge, '"');
    END IF;
    IF mystring.f_isnotnull(v_master_new) THEN
      o_info := mystring.f_concat(o_info, ',"master":"', v_master_new, '"');
    END IF;
    IF mystring.f_isnotnull(v_attr) THEN
      o_info := mystring.f_concat(o_info, ',"attr":"', myjson.f_escape(v_attr), '"');
    END IF;
    IF mystring.f_isnotnull(v_pickusage) THEN
      o_info := mystring.f_concat(o_info, ',"pickusage":"', myjson.f_escape(v_pickusage), '"');
    END IF;
    IF mystring.f_isnotnull(v_forwardreason) THEN
      o_info := mystring.f_concat(o_info, ',"forwardreason":"', myjson.f_escape(v_forwardreason), '"');
    END IF;
    IF mystring.f_isnotnull(v_operunm) THEN
      o_info := mystring.f_concat(o_info, ',"operunm":"', v_operunm, '"');
    END IF;
    IF v_operdate IS NOT NULL THEN
      o_info := mystring.f_concat(o_info, ',"operdate":"', to_char(v_operdate, 'yyyy-mm-dd hh24:mi'), '"');
    END IF;
    o_info := mystring.f_concat(o_info, '}');
    o_info := mystring.f_concat(o_info, '}');
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

  -- 查询凭证参数-签发业务
  FUNCTION f_getqfoper
  (
    i_tempid  VARCHAR2, -- 模板标识
    i_type    VARCHAR2,
    i_info    VARCHAR2,
    i_realnum VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
  
    v_xml   xmltype;
    v_i     INT := 0;
    v_xpath VARCHAR2(200);
    v_idx   INT := 0;
  
    v_pname VARCHAR2(128);
    v_name  VARCHAR2(128);
    v_ptype VARCHAR2(64);
    v_type  VARCHAR2(64);
    v_form  VARCHAR2(64);
    v_flag  INTEGER;
    v_num   INTEGER;
    v_value VARCHAR2(128);
  BEGIN
    v_xml := xmltype(i_info);
    v_num := myxml.f_getcount(v_xml, mystring.f_concat('/', i_type, 's/', i_type));
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      v_xpath := mystring.f_concat('/', i_type, 's/', i_type, '[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'pname')) INTO v_pname FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'name')) INTO v_name FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'ptype')) INTO v_ptype FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'type')) INTO v_type FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'form')) INTO v_form FROM dual;
      SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, 'flag')) INTO v_flag FROM dual;
      IF mystring.f_isnull(v_name) THEN
        v_i := 100;
      ELSE
        v_value := '';
        BEGIN
          SELECT t.name
            INTO v_value
            FROM info_template_qfoper t
           WHERE t.tempid = i_tempid
             AND t.pcode = v_ptype
             AND t.code = v_type;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        IF mystring.f_isnull(v_value) THEN
          IF i_type = 'MS01' THEN
            v_value := '首签';
          ELSE
            v_value := v_name;
          END IF;
        END IF;
      
        v_idx := v_idx + 1;
        IF v_idx = 1 THEN
          v_result := '{';
        ELSE
          v_result := mystring.f_concat(v_result, ',{');
        END IF;
        v_result := mystring.f_concat(v_result, ' "realnum":"', i_realnum, '"');
        v_result := mystring.f_concat(v_result, ',"pcode":"', i_type, '"');
        v_result := mystring.f_concat(v_result, ',"pname":"', v_pname, '"');
        v_result := mystring.f_concat(v_result, ',"num":"', v_num, '"');
        v_result := mystring.f_concat(v_result, ',"name":"', v_name, '"');
        v_result := mystring.f_concat(v_result, ',"ptype":"', v_ptype, '"');
        v_result := mystring.f_concat(v_result, ',"type":"', v_type, '"');
        v_result := mystring.f_concat(v_result, ',"form":"', v_form, '"');
        v_result := mystring.f_concat(v_result, ',"flag":"', v_flag, '"');
        v_result := mystring.f_concat(v_result, ',"value":"', v_value, '"');
        IF v_i = 1 THEN
          v_result := mystring.f_concat(v_result, ',"first":"1"');
        ELSE
          v_result := mystring.f_concat(v_result, ',"first":"0"');
        END IF;
        v_result := mystring.f_concat(v_result, '}');
      END IF;
      v_i := v_i + 1;
    END LOOP;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  /***************************************************************************************************
  名称     : pkg_info_template.p_getinfo2
  功能描述 : 查询凭证参数-签发参数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-19  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getinfo2
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_ms01info     VARCHAR2(4000);
    v_ms02info     VARCHAR2(4000);
    v_ms03info     VARCHAR2(4000);
    v_ms04info     VARCHAR2(4000);
    v_ms05info     VARCHAR2(4000);
    v_ms01info_out VARCHAR2(4000);
    v_ms02info_out VARCHAR2(4000);
    v_ms03info_out VARCHAR2(4000);
    v_ms04info_out VARCHAR2(4000);
    v_ms05info_out VARCHAR2(4000);
  
    v_idx     INT := 0;
    v_realnum INT := 0;
  
    v_issuername VARCHAR2(128); -- 签发单位名称
    v_issuercode VARCHAR2(64); -- 签发单位编码
    v_kindtype   INT; -- 签发对象(1:不确定对象(默认)/2:相对固定对象)
    v_operunm    VARCHAR2(64);
    v_operdate   DATE;
  BEGIN
    mydebug.wlog('i_tempid', i_tempid);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.MS01Info') INTO v_ms01info FROM dual;
    SELECT json_value(i_forminfo, '$.MS02Info') INTO v_ms02info FROM dual;
    SELECT json_value(i_forminfo, '$.MS03Info') INTO v_ms03info FROM dual;
    SELECT json_value(i_forminfo, '$.MS04Info') INTO v_ms04info FROM dual;
    SELECT json_value(i_forminfo, '$.MS05Info') INTO v_ms05info FROM dual;
  
    BEGIN
      SELECT kindtype, operunm, operdate INTO v_kindtype, v_operunm, v_operdate FROM info_template t WHERE t.tempid = i_tempid;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    BEGIN
      SELECT sqdcode, sqdnm INTO v_issuercode, v_issuername FROM info_template_bind t WHERE t.id = i_tempid;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"objContent":{');
    o_info := mystring.f_concat(o_info, '"dataInfo":{');
    o_info := mystring.f_concat(o_info, ' "issuername":"', v_issuername, '"');
    o_info := mystring.f_concat(o_info, ',"issuercode":"', v_issuercode, '"');
    o_info := mystring.f_concat(o_info, ',"kindtype":"', v_kindtype, '"');
    o_info := mystring.f_concat(o_info, ',"operunm":"', v_operunm, '"');
    o_info := mystring.f_concat(o_info, ',"operdate":"', to_char(v_operdate, 'yyyy-mm-dd hh24:mi'), '"');
    o_info := mystring.f_concat(o_info, '}');
    o_info := mystring.f_concat(o_info, ',"dataList":[');
  
    IF mystring.f_isnotnull(v_ms01info) THEN
      v_realnum      := v_realnum + 1;
      v_ms01info_out := pkg_info_template.f_getqfoper(i_tempid, 'MS01', v_ms01info, v_realnum);
      IF mystring.f_isnotnull(v_ms01info_out) THEN
        v_idx := v_idx + 1;
        IF v_idx > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, v_ms01info_out);
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_ms02info) THEN
      v_realnum      := v_realnum + 1;
      v_ms02info_out := pkg_info_template.f_getqfoper(i_tempid, 'MS02', v_ms02info, v_realnum);
      IF mystring.f_isnotnull(v_ms02info_out) THEN
        v_idx := v_idx + 1;
        IF v_idx > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, v_ms02info_out);
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_ms03info) THEN
      v_realnum      := v_realnum + 1;
      v_ms03info_out := pkg_info_template.f_getqfoper(i_tempid, 'MS03', v_ms03info, v_realnum);
      IF mystring.f_isnotnull(v_ms03info_out) THEN
        v_idx := v_idx + 1;
        IF v_idx > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, v_ms03info_out);
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_ms04info) THEN
      v_realnum      := v_realnum + 1;
      v_ms04info_out := pkg_info_template.f_getqfoper(i_tempid, 'MS04', v_ms04info, v_realnum);
      IF mystring.f_isnotnull(v_ms04info_out) THEN
        v_idx := v_idx + 1;
        IF v_idx > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, v_ms04info_out);
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_ms05info) THEN
      v_realnum      := v_realnum + 1;
      v_ms05info_out := pkg_info_template.f_getqfoper(i_tempid, 'MS05', v_ms05info, v_realnum);
      IF mystring.f_isnotnull(v_ms05info_out) THEN
        v_idx := v_idx + 1;
        IF v_idx > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, v_ms05info_out);
      END IF;
    END IF;
  
    o_info := mystring.f_concat(o_info, ']');
    o_info := mystring.f_concat(o_info, '}');
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

  /***************************************************************************************************
  名称     : pkg_info_template.p_getinfo
  功能描述 : 查询凭证参数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-19  唐金鑫  创建
  
  返回信息(o_info)格式
  印制参数
  <info>
    <rows>
      <row id="billorg">印制机构</row>
      <row id="billcode">票据编码</row>
      <row id="billcount">票据份数</row>
      <row id="dtype">凭证大类/凭证类型</row>
      <row id="temptype">凭证小类</row>
      <row id="issplit">是否支持分签(0:不支持 1:支持)</row>
      <row id="merge">合并方式(0:不支持 1:按凭证类型 2:按签发者+凭证类型 3:按签发者+凭证类型+特别参数)</row>
      <row id="master">合并目标凭证</row>
      <row id="attr">自定义参数(xml)</row>
      <row id="pickusage">默认提取用途</row>
      <row id="forwardreason">默认转发原因</row>
    <rows>
    <operunm>维护人</operunm>
    <operdate>维护时间</operdate>
  <info>
  
  签发参数
  <info>
    <rows>
      <row id="issuername">签发单位名称</row>
      <row id="issuercode">签发单位编码</row>
      <row id="kindtype">签发对象(1:不确定对象(默认)/2:相对固定对象)</row>
      <row id="qfoper">
        <c id="1" pcode="MS01" pname="首签">首签</c>
        <c id="2" pcode="MS02" pname="增签">增签</c>
        <c id="3" pcode="MS03" pname="变签">变签</c>
        <c id="4" pcode="MS04" pname="取消">取消</c>
        <c id="5" pcode="MS05" pname="注销">注销</c>
      </row>
    <rows>
    <operunm>维护人</operunm>
    <operdate>维护时间</operdate>
  <info>
  
  usetype签发类型
    0:印签  空白印制维护+签发印制维护
    1:签发  签发印制维护
    2:印制  空白印制维护
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_type   VARCHAR2(8);
    v_tempid VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    mydebug.wlog('v_type', v_type);
  
    IF v_type = '1' THEN
      -- 1:印制参数
      pkg_info_template.p_getinfo1(v_tempid, i_operuri, i_opername, o_info, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSE
      -- 2:签发参数
      pkg_info_template.p_getinfo2(v_tempid, i_forminfo, i_operuri, i_opername, o_info, o_code, o_msg);
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
  名称     : pkg_info_template.p_prvdata_set
  功能描述 : 保存特有参数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-19  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_prvdata_set
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id          VARCHAR2(128);
    v_tempid      VARCHAR2(64); -- 模板标识
    v_type        VARCHAR2(8); -- 参数类型(1:印制 2:签发)
    v_sectioncode VARCHAR2(64); -- 子类模板标识，没有子类传空值
    v_sectionname VARCHAR2(128); -- 子类模板名称，没有子类传空值
    v_items       VARCHAR2(32767); -- 特有参数(xml)
    v_imageitems  VARCHAR2(32767);
    v_attachinfo  VARCHAR2(32767);
    v_files       VARCHAR2(32767); -- 特有参数(文件)
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
    SELECT json_value(i_forminfo, '$.i_sectioncode') INTO v_sectioncode FROM dual;
    SELECT json_value(i_forminfo, '$.i_sectionname') INTO v_sectionname FROM dual;
    SELECT json_value(i_forminfo, '$.i_prvdata_items' RETURNING VARCHAR2(32767)) INTO v_items FROM dual;
    SELECT json_value(i_forminfo, '$.imageItems' RETURNING VARCHAR2(32767)) INTO v_imageitems FROM dual;
    SELECT json_value(i_forminfo, '$.attachInfo' RETURNING VARCHAR2(32767)) INTO v_attachinfo FROM dual;
    mydebug.wlog('v_tempid', v_tempid);
    mydebug.wlog('v_type', v_type);
    mydebug.wlog('v_sectioncode', v_sectioncode);
    mydebug.wlog('v_sectionname', v_sectionname);
    mydebug.wlog('v_items', v_items);
    mydebug.wlog('v_imageItems', v_imageitems);
    mydebug.wlog('v_attachInfo', v_attachinfo);
  
    IF mystring.f_isnull(v_tempid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_type) THEN
      o_code := 'EC02';
      o_msg  := '参数类型为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_files := '<files>';
    IF mystring.f_isnotnull(v_imageitems) THEN
      v_files := mystring.f_concat(v_files, v_imageitems);
    END IF;
    IF mystring.f_isnotnull(v_attachinfo) THEN
      v_files := mystring.f_concat(v_files, v_attachinfo);
    END IF;
    v_files := mystring.f_concat(v_files, '</files>');
  
    IF mystring.f_isnull(v_sectioncode) THEN
      v_id := mystring.f_concat(v_tempid, '_', v_type);
      DELETE FROM info_template_prvdata
       WHERE tempid = v_tempid
         AND datatype = v_type;
    ELSE
      v_id := mystring.f_concat(v_tempid, '_', v_type, '_', v_sectioncode);
      DELETE FROM info_template_prvdata
       WHERE tempid = v_tempid
         AND datatype = v_type
         AND sectioncode = v_sectioncode;
    END IF;
    DELETE FROM info_template_prvdata WHERE id = v_id;
  
    INSERT INTO info_template_prvdata
      (id, tempid, datatype, sectioncode, sectionname, items2, files, createduid, createdunm)
    VALUES
      (v_id, v_tempid, v_type, v_sectioncode, v_sectionname, v_items, v_files, i_operuri, i_opername);
  
    -- 修改维护人、维护时间
    UPDATE info_template t SET t.operuid = i_operuri, t.operunm = i_opername, t.operdate = SYSDATE WHERE t.tempid = v_tempid;
  
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
  名称     : pkg_info_template.p_prvdata_get
  功能描述 : 查询特有参数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-19  唐金鑫  创建
  
  o_info
  <info>
    <operunm>维护人</operunm>
    <operdate>维护时间</operdate>
  <info>
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_prvdata_get
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_files         CLOB; -- 特有参数(文件)
    v_tempid        VARCHAR2(64); -- 模板标识
    v_type          VARCHAR2(8); -- 参数类型(1:印制 2:签发)
    v_sectioncode   VARCHAR2(64); -- 子类模板标识，没有子类传空值
    v_prvdata_items VARCHAR2(32767);
    v_imageinfo     VARCHAR2(32767);
    v_attachinfo    VARCHAR2(32767);
    v_items         VARCHAR2(32767); -- 特有参数(xml)
    v_imagelist     VARCHAR2(32767);
    v_attachlist    VARCHAR2(32767);
    v_items_new     VARCHAR2(32767);
    v_operunm       VARCHAR2(64);
    v_operdate      DATE;
  
    v_xml   xmltype;
    v_i     INT := 0;
    v_xpath VARCHAR2(200);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
    SELECT json_value(i_forminfo, '$.i_sectioncode') INTO v_sectioncode FROM dual;
    SELECT json_value(i_forminfo, '$.prvdata_items' RETURNING VARCHAR2(32767)) INTO v_prvdata_items FROM dual;
    SELECT json_value(i_forminfo, '$.imageInfo' RETURNING VARCHAR2(32767)) INTO v_imageinfo FROM dual;
    SELECT json_value(i_forminfo, '$.attachInfo' RETURNING VARCHAR2(32767)) INTO v_attachinfo FROM dual;
    mydebug.wlog('v_tempid', v_tempid);
    mydebug.wlog('v_type', v_type);
    mydebug.wlog('v_sectioncode', v_sectioncode);
    mydebug.wlog('v_prvdata_items', v_prvdata_items);
    mydebug.wlog('v_imageinfo', v_imageinfo);
    mydebug.wlog('v_attachinfo', v_attachinfo);
  
    IF mystring.f_isnull(v_sectioncode) THEN
      BEGIN
        SELECT t.items2, t.files
          INTO v_items, v_files
          FROM info_template_prvdata t
         WHERE t.tempid = v_tempid
           AND t.datatype = v_type
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    ELSE
      BEGIN
        SELECT t.items2, t.files
          INTO v_items, v_files
          FROM info_template_prvdata t
         WHERE t.tempid = v_tempid
           AND t.datatype = v_type
           AND t.sectioncode = v_sectioncode
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
  
    BEGIN
      SELECT operunm, operdate INTO v_operunm, v_operdate FROM info_template t WHERE t.tempid = v_tempid;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    -- 特有参数-附件
    DECLARE
      v_image_tag   VARCHAR2(64);
      v_image_desc  VARCHAR2(128);
      v_image_type  VARCHAR2(64);
      v_image_value VARCHAR2(32767);
    BEGIN
      v_imagelist := '[';
      IF mystring.f_isnotnull(v_imageinfo) THEN
        v_xml := xmltype(v_imageinfo);
        v_i   := 1;
        WHILE v_i <= 100 LOOP
          v_xpath := mystring.f_concat('/images/image[', v_i, ']/');
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'tag')) INTO v_image_tag FROM dual;
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'desc')) INTO v_image_desc FROM dual;
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'type')) INTO v_image_type FROM dual;
          v_image_value := myxml.f_getlongvalue(v_files, mystring.f_concat('/files/item[@type="image" and @tag="', v_image_tag, '"]/value'));
        
          IF mystring.f_isnull(v_image_tag) THEN
            v_i := 100;
          ELSE
            IF v_i > 1 THEN
              v_imagelist := mystring.f_concat(v_imagelist, ',');
            END IF;
            v_imagelist := mystring.f_concat(v_imagelist, '{');
            v_imagelist := mystring.f_concat(v_imagelist, ' "tag":"', v_image_tag, '"');
            v_imagelist := mystring.f_concat(v_imagelist, ',"type":"', v_image_type, '"');
            v_imagelist := mystring.f_concat(v_imagelist, ',"value":"', v_image_value, '"');
            v_imagelist := mystring.f_concat(v_imagelist, ',"desc":"', v_image_desc, '"');
            v_imagelist := mystring.f_concat(v_imagelist, '}');
          END IF;
          v_i := v_i + 1;
        END LOOP;
      END IF;
      v_imagelist := mystring.f_concat(v_imagelist, ']');
    END;
  
    -- 特有参数-图片
    DECLARE
      v_attach_tag   VARCHAR2(64);
      v_attach_desc  VARCHAR2(128);
      v_attach_type  VARCHAR2(64);
      v_attach_value VARCHAR2(32767);
    BEGIN
      v_attachlist := '[';
      IF mystring.f_isnotnull(v_attachinfo) THEN
        v_xml := xmltype(v_attachinfo);
        v_i   := 1;
        WHILE v_i <= 100 LOOP
          v_xpath := mystring.f_concat('/attachs/attach[', v_i, ']/');
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'tag')) INTO v_attach_tag FROM dual;
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'desc')) INTO v_attach_desc FROM dual;
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'type')) INTO v_attach_type FROM dual;
          v_attach_value := myxml.f_getlongvalue(v_files, mystring.f_concat('/files/item[@type="attach" and @tag="', v_attach_tag, '"]/value'));
        
          IF mystring.f_isnull(v_attach_tag) THEN
            v_i := 100;
          ELSE
            IF v_i > 1 THEN
              v_attachlist := mystring.f_concat(v_attachlist, ',');
            END IF;
            v_attachlist := mystring.f_concat(v_attachlist, '{');
            v_attachlist := mystring.f_concat(v_attachlist, ' "tag":"', v_attach_tag, '"');
            v_attachlist := mystring.f_concat(v_attachlist, ',"type":"', v_attach_type, '"');
            v_attachlist := mystring.f_concat(v_attachlist, ',"value":"', v_attach_value, '"');
            v_attachlist := mystring.f_concat(v_attachlist, ',"desc":"', v_attach_desc, '"');
            v_attachlist := mystring.f_concat(v_attachlist, '}');
          END IF;
          v_i := v_i + 1;
        END LOOP;
      END IF;
      v_attachlist := mystring.f_concat(v_attachlist, ']');
    END;
  
    -- 特有参数-XML
    DECLARE
      v_item_tag   VARCHAR2(64);
      v_item_desc  VARCHAR2(128);
      v_item_type  VARCHAR2(64);
      v_item_value VARCHAR2(32767);
      v_items_xml  xmltype;
    BEGIN
      v_items_new := '<items>';
      IF mystring.f_isnotnull(v_prvdata_items) THEN
        v_xml := xmltype(v_prvdata_items);
        IF mystring.f_isnotnull(v_items) THEN
          v_items_xml := xmltype(v_items);
        END IF;
        v_i := 1;
        WHILE v_i <= 100 LOOP
          v_xpath := mystring.f_concat('/items/item[', v_i, ']/');
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@tag')) INTO v_item_tag FROM dual;
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@desc')) INTO v_item_desc FROM dual;
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@type')) INTO v_item_type FROM dual;
        
          IF mystring.f_isnotnull(v_items_xml) THEN
            SELECT myxml.f_getvalue(v_items_xml, mystring.f_concat('/items/item[@tag="', v_item_tag, '"]/value')) INTO v_item_value FROM dual;
          END IF;
        
          IF mystring.f_isnull(v_item_tag) THEN
            v_i := 100;
          ELSE
            v_items_new := mystring.f_concat(v_items_new, '<item');
            v_items_new := mystring.f_concat(v_items_new, ' tag="', v_item_tag, '"');
            v_items_new := mystring.f_concat(v_items_new, ' desc="', v_item_desc, '"');
            v_items_new := mystring.f_concat(v_items_new, ' type="', v_item_type, '"');
            v_items_new := mystring.f_concat(v_items_new, ' >');
            v_items_new := mystring.f_concat(v_items_new, '<value>', myxml.f_escape(v_item_value), '</value>');
            v_items_new := mystring.f_concat(v_items_new, '</item>');
          END IF;
          v_i := v_i + 1;
        END LOOP;
      END IF;
      v_items_new := mystring.f_concat(v_items_new, '</items>');
    END;
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, '"objContent":{');
    dbms_lob.append(o_info, '"dataInfo":{');
    dbms_lob.append(o_info, mystring.f_concat(' "operunm":"', v_operunm, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"operdate":"', to_char(v_operdate, 'yyyy-mm-dd hh24:mi'), '"'));
    dbms_lob.append(o_info, '}');
    dbms_lob.append(o_info, mystring.f_concat(',"imageList":', v_imagelist));
    dbms_lob.append(o_info, mystring.f_concat(',"attachList":', v_attachlist));
    dbms_lob.append(o_info, mystring.f_concat(',"prvdata_items":"', myjson.f_escape(v_items_new), '"'));
    dbms_lob.append(o_info, '}');
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

  -- 保存空白印制公共参数
  PROCEDURE p_save1
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_info     IN CLOB, -- 参数信息
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists        INT := 0;
    v_billorg       VARCHAR2(128); -- 印制机构
    v_billcode      VARCHAR2(64); -- 票据编码
    v_billcount     INT; -- 票据份数
    v_attr          VARCHAR2(4000); -- 自定义参数
    v_pickusage     VARCHAR2(512); -- 默认提取用途
    v_forwardreason VARCHAR2(512); -- 默认转发原因
  BEGIN
    mydebug.wlog('i_tempid', i_tempid);
    mydebug.wlog('i_info', i_info);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_tempid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_info) THEN
      o_code := 'EC02';
      o_msg  := '参数信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 解析XML
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(i_info);
      SELECT myxml.f_getvalue(v_xml, '/rows/row[@id="billorg"]') INTO v_billorg FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/rows/row[@id="billcode"]') INTO v_billcode FROM dual;
      SELECT myxml.f_getint(v_xml, '/rows/row[@id="billcount"]') INTO v_billcount FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/rows/row[@id="pickusage"]') INTO v_pickusage FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/rows/row[@id="forwardreason"]') INTO v_forwardreason FROM dual;
      SELECT myxml.f_getnode_str(v_xml, '/rows/row[@id="attr"]/*') INTO v_attr FROM dual;
    END;
  
    IF mystring.f_isnull(v_billorg) THEN
      o_code := 'EC02';
      o_msg  := '请填写印制机构！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_billcode) THEN
      o_code := 'EC02';
      o_msg  := '请填写票据编码！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_billcount IS NULL THEN
      o_code := 'EC02';
      o_msg  := '请填写票据份数！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_billcount > 999 THEN
      o_code := 'EC02';
      o_msg  := '票据份数不能大于999！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_pickusage) THEN
      o_code := 'EC02';
      o_msg  := '请填写默认提取用途！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE info_template t SET t.billcode = v_billcode, t.billorg = v_billorg, t.billcount = v_billcount WHERE t.tempid = i_tempid;
  
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_template_attr t WHERE t.tempid = i_tempid);
    IF v_exists = 0 THEN
      INSERT INTO info_template_attr (tempid, createduid, createdunm) VALUES (i_tempid, i_operuri, i_opername);
    END IF;
    UPDATE info_template_attr t SET t.attr = v_attr, t.pickusage = v_pickusage, t.forwardreason = v_forwardreason WHERE t.tempid = i_tempid;
  
    -- 修改维护人、维护时间
    UPDATE info_template t SET t.operuid = i_operuri, t.operunm = i_opername, t.operdate = SYSDATE WHERE t.tempid = i_tempid;
  
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

  -- 保存签发业务类型
  PROCEDURE p_save2
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_info     IN CLOB, -- 参数信息
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id    VARCHAR2(128);
    v_code  VARCHAR2(64);
    v_pcode VARCHAR2(64);
    v_name  VARCHAR2(64);
    v_form  VARCHAR2(64);
    v_flag  INT;
    v_val   VARCHAR2(512);
  BEGIN
    mydebug.wlog('i_tempid', i_tempid);
    mydebug.wlog('i_info', i_info);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_tempid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_info) THEN
      o_code := 'EC02';
      o_msg  := '参数信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DELETE FROM info_template_qfoper WHERE tempid = i_tempid;
  
    -- 解析XML
    DECLARE
      v_xml   xmltype;
      v_cnt   INT := 0;
      v_i     INT := 0;
      v_xpath VARCHAR2(200);
    BEGIN
      v_xml := xmltype(i_info);
    
      v_i := 1;
      WHILE v_i <= 100 LOOP
        v_xpath := mystring.f_concat('/rows/row[@id="qfoper"]/c[', v_i, ']');
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '/@id')) INTO v_code FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '/@pcode')) INTO v_pcode FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '/@form')) INTO v_form FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '/@name')) INTO v_name FROM dual;
        SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '/@flag')) INTO v_flag FROM dual;
        SELECT myxml.f_getvalue(v_xml, v_xpath) INTO v_val FROM dual;
        IF mystring.f_isnull(v_code) THEN
          v_i := 100;
        ELSE
          IF v_flag IS NULL THEN
            v_flag := 0;
          END IF;
        
          IF mystring.f_isnull(v_val) THEN
            IF v_pcode = '1' THEN
              v_val := '首签';
            ELSE
              v_val := v_name;
            END IF;
          END IF;
        
          v_id := mystring.f_concat(i_tempid, '_', v_code);
          INSERT INTO info_template_qfoper
            (id, tempid, pcode, code, NAME, name0, form, flag, sort, operuri, opername)
          VALUES
            (v_id, i_tempid, v_pcode, v_code, v_val, v_name, v_form, v_flag, v_i, i_operuri, i_opername);
          v_cnt := v_cnt + 1;
        END IF;
        v_i := v_i + 1;
      END LOOP;
    
      IF v_cnt = 0 THEN
        ROLLBACK;
        o_code := 'EC02';
        o_msg  := '未获取到签发业务！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    -- 修改维护人、维护时间
    UPDATE info_template t SET t.operuid = i_operuri, t.operunm = i_opername, t.operdate = SYSDATE WHERE t.tempid = i_tempid;
  
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

  -- 保存签发公共参数
  PROCEDURE p_save3
  (
    i_tempid   IN VARCHAR2, -- 模板标识
    i_info     IN CLOB, -- 参数信息
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_otype     INT;
    v_kindtype  INT;
    v_kindids   VARCHAR2(4000);
    v_idpath    VARCHAR2(64);
    v_ids_count INT := 0;
    v_i         INT := 0;
  BEGIN
    mydebug.wlog('i_tempid', i_tempid);
    mydebug.wlog('i_info', i_info);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_tempid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_info) THEN
      o_code := 'EC02';
      o_msg  := '参数信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_otype := pkg_info_template_pbl.f_getotype(i_tempid);
  
    -- 解析xml
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(i_info);
      SELECT myxml.f_getint(v_xml, '/rows/row[@id="kindtype"]') INTO v_kindtype FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/rows/row[@id="kindid"]') INTO v_kindids FROM dual;
    END;
  
    IF mystring.f_isnull(v_kindtype) THEN
      o_code := 'EC02';
      o_msg  := '对象分类选择为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_kindtype = 2 THEN
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
    END IF;
  
    UPDATE info_template t SET t.kindtype = v_kindtype WHERE t.tempid = i_tempid;
  
    DELETE FROM info_template_kind WHERE tempid = i_tempid;
  
    IF v_kindtype = 2 THEN
      IF instr(v_kindids, 'root') > 0 THEN
        INSERT INTO info_template_kind
          (id, tempid, kindid, operuri, opername)
          SELECT mystring.f_concat(i_tempid, '_', t.id), i_tempid, t.id, i_operuri, i_opername FROM info_register_kind t WHERE t.datatype = v_otype;
      ELSE
        v_i := 1;
        WHILE v_i <= v_ids_count LOOP
          v_idpath := myarray.f_getvalue(v_kindids, ',', v_i);
          IF mystring.f_isnotnull(v_idpath) THEN
            INSERT INTO info_template_kind
              (id, tempid, kindid, operuri, opername)
              SELECT mystring.f_concat(i_tempid, '_', t.id), i_tempid, t.id, i_operuri, i_opername
                FROM info_register_kind t
               WHERE t.datatype = v_otype
                 AND instr(t.idpath, v_idpath) > 0
                 AND NOT EXISTS (SELECT 1
                        FROM info_template_kind w
                       WHERE w.tempid = i_tempid
                         AND w.kindid = t.id);
          END IF;
          v_i := v_i + 1;
        END LOOP;
      END IF;
    END IF;
  
    -- 修改维护人、维护时间
    UPDATE info_template t SET t.operuid = i_operuri, t.operunm = i_opername, t.operdate = SYSDATE WHERE t.tempid = i_tempid;
  
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
  名称     : pkg_info_template.p_save
  功能描述 : 保存参数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-19  唐金鑫  创建
  
  <rows>
    <!-- 印制-- >
    <row id="billorg">印制机构</row>
    <row id="billcode">票据编码</row>
    <row id="billcount">票据份数</row>
    <row id="attr">自定义参数(xml)</row>
    <row id="pickusage">默认提取用途</row>
    <row id="forwardreason">默认转发原因</row>
    
    <!-- 签发公共参数-- >
    <row id="kindtype">对象分类选择(1:不确定对象(默认)/2:相对固定对象)</row>
    <row id="kindid">对象分类ID，使用逗号分割</row>
    
    <!-- 签发业务类型-- >
    <row id="qfoper">
      <c id="1" pcode="MS01" form="" name="" flag="0">首签</c>
      <c id="2" pcode="MS02" form="" name="" flag="0">增签</c>
      <c id="3" pcode="MS03" form="" name="" flag="0">变签</c>
      <c id="4" pcode="MS04" form="" name="" flag="0">取消</c>
      <c id="5" pcode="MS05" form="" name="" flag="0">注销</c>
    </row>
  <rows>
  
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
    v_tempid VARCHAR2(64); -- 模板标识
    v_type   VARCHAR2(8); -- 参数类型(1:空白印制公共参数 2:签发业务类型 3:签发公共参数)
    v_info   VARCHAR2(32767); -- 参数信息
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    SELECT json_value(i_forminfo, '$.i_info' RETURNING VARCHAR2(32767)) INTO v_info FROM dual;
    mydebug.wlog('v_type', v_type);
  
    IF v_type = '1' THEN
      -- 空白印制公共参数
      pkg_info_template.p_save1(v_tempid, v_info, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSIF v_type = '2' THEN
      -- 签发业务类型
      pkg_info_template.p_save2(v_tempid, v_info, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSIF v_type = '3' THEN
      -- 签发公共参数
      pkg_info_template.p_save3(v_tempid, v_info, i_operuri, i_opername, o_code, o_msg);
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
