CREATE OR REPLACE PACKAGE pkg_info_template_hfile IS

  /***************************************************************************************************
  名称     : pkg_info_template_hfile
  功能描述 : 凭证参数维护-申领模板
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 增加模板
  PROCEDURE p_add
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除模板
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询办理类型集合
  PROCEDURE p_getlist
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
CREATE OR REPLACE PACKAGE BODY pkg_info_template_hfile IS

  /***************************************************************************************************
  名称     : pkg_info_template_hfile.p_add
  功能描述 : 增加模板
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_add
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_tempid   VARCHAR2(64); -- 模板标识
    v_filename VARCHAR2(256); -- 文件名
    v_filepath VARCHAR2(512); -- 文件路径
  
    v_id     VARCHAR2(64);
    v_fileid VARCHAR2(64);
    v_sort   INT := 0;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_tempid FROM dual;
    SELECT json_value(i_forminfo, '$.i_filename') INTO v_filename FROM dual;
    SELECT json_value(i_forminfo, '$.i_filepath') INTO v_filepath FROM dual;
    mydebug.wlog('v_tempid', v_tempid);
    mydebug.wlog('v_filename', v_filename);
    mydebug.wlog('v_filepath', v_filepath);
  
    IF mystring.f_isnull(v_tempid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_filename) THEN
      o_code := 'EC02';
      o_msg  := '文件名为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_filepath) THEN
      o_code := 'EC02';
      o_msg  := '文件路径为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    pkg_file0.p_ins3(v_filename, v_filepath, 0, v_tempid, 3, i_operuri, i_opername, v_fileid, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT MAX(t.sort) INTO v_sort FROM info_template_hfile t WHERE t.tempid = v_tempid;
    IF v_sort IS NULL THEN
      v_sort := 1;
    ELSE
      v_sort := v_sort + 1;
    END IF;
  
    v_id := v_fileid;
    INSERT INTO info_template_hfile (id, tempid, code, fileid, sort, operuri, opername) VALUES (v_id, v_tempid, 'MS01', v_fileid, v_sort, i_operuri, i_opername);
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, ' "tempContent":"', v_id, '"');
    o_info := mystring.f_concat(o_info, ',"code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"处理成功"');
    o_info := mystring.f_concat(o_info, '}');
    mydebug.wlog('o_info', o_info);
  
    COMMIT;
  
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

  /***************************************************************************************************
  名称     : pkg_info_template_hfile.p_del
  功能描述 : 删除模板
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id     VARCHAR2(64);
    v_fileid VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD914', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_tempid') INTO v_id FROM dual;
  
    mydebug.wlog('v_id', v_id);
  
    IF mystring.f_isnull(v_id) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT t.fileid
        INTO v_fileid
        FROM info_template_hfile t
       WHERE t.id = v_id
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnotnull(v_fileid) THEN
      pkg_file0.p_del(v_fileid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    DELETE FROM info_template_hfile WHERE id = v_id;
  
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
  名称     : pkg_info_template_hfile.p_getlist
  功能描述 : 查询办理类型集合
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-05  唐金鑫  创建
  
  返回信息(o_info)格式
  <rows>
    <row>
      <id>唯一标识</id>
      <code>代码</code>
      <title>显示名称</title>
      <filename>文件名</filename>
      <filepath>文件路径</filepath>
      <filetype>是否默认模板(1:是 0:否)</filetype>
    </row>
  </rows>
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_tempid VARCHAR2(64); -- 模板标识
    v_num    INT := 0;
    v_id     VARCHAR2(64);
    v_fileid VARCHAR2(64);
    v_sort   INT;
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
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"dataList":[');
    DECLARE
      CURSOR v_cursor IS
        SELECT t.id, t.fileid FROM info_template_hfile0 t WHERE t.dtype = v_tempid;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_fileid;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, '{');
        o_info := mystring.f_concat(o_info, ' "id":"', v_id, '"');
        o_info := mystring.f_concat(o_info, ',"code":"MS01"');
        o_info := mystring.f_concat(o_info, ',"title":"申请模板(默认)"');
        o_info := mystring.f_concat(o_info, ',"filetype":"1"');
        o_info := mystring.f_concat(o_info, ',"filename":"', pkg_file0.f_getfilename(v_fileid), '"');
        o_info := mystring.f_concat(o_info, ',"filepath":"', myjson.f_escape(pkg_file0.f_getfilepath(v_fileid)), '"');
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
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.id, t.fileid, t.sort FROM info_template_hfile t WHERE t.tempid = v_tempid ORDER BY t.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_fileid, v_sort;
        EXIT WHEN v_cursor%NOTFOUND;
        v_num := v_num + 1;
        IF v_num > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, '{');
        o_info := mystring.f_concat(o_info, ' "id":"', v_id, '"');
        o_info := mystring.f_concat(o_info, ',"code":"MS01"');
        o_info := mystring.f_concat(o_info, ',"title":"申请模板(', v_sort, ')"');
        o_info := mystring.f_concat(o_info, ',"filetype":"0"');
        o_info := mystring.f_concat(o_info, ',"filename":"', pkg_file0.f_getfilename(v_fileid), '"');
        o_info := mystring.f_concat(o_info, ',"filepath":"', myjson.f_escape(pkg_file0.f_getfilepath(v_fileid)), '"');
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
    o_info := mystring.f_concat(o_info, ',"savefir":"', myjson.f_escape(pkg_file0.f_getconfig), '"');
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
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
  END;
END;
/
