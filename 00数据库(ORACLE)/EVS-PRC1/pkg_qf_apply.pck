CREATE OR REPLACE PACKAGE pkg_qf_apply IS

  /***************************************************************************************************
  名称     : pkg_qf_apply
  功能描述 : 签发-申请
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-14  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getfiles
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT CLOB, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );
END pkg_qf_apply;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf_apply IS

  /***************************************************************************************************
  名称     : pkg_qf_apply.p_getfiles
  功能描述 : 查询申请文件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-14  唐金鑫  创建
  
  <files>
    <file>
      <filename></filename>
      <filepath></filepath>
    </file>
  </files>
  ***************************************************************************************************/
  PROCEDURE p_getfiles
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT CLOB, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_id       VARCHAR2(64);
    v_dtype    VARCHAR2(64);
    v_douri    VARCHAR2(64);
    v_fileid   VARCHAR2(64);
    v_filename VARCHAR2(200);
    v_filepath VARCHAR2(512);
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
  
    SELECT json_value(i_forminfo, '$.i_docid') INTO v_id FROM dual;
    mydebug.wlog('v_id', v_id);
  
    BEGIN
      SELECT dtype, douri INTO v_dtype, v_douri FROM data_qf_book t WHERE t.id = v_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    BEGIN
      SELECT fileid
        INTO v_fileid
        FROM (SELECT fileid
                FROM data_qf_notice_applyinfo t
               WHERE t.dtype = v_dtype
                 AND t.fromuri = v_douri
               ORDER BY t.createddate DESC) q
       WHERE rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_filename := pkg_file0.f_getfilename(v_fileid);
    v_filepath := pkg_file0.f_getfilepath(v_fileid);
  
    o_info1 := '{';
    o_info1 := mystring.f_concat(o_info1, '"fileList":[{');
    o_info1 := mystring.f_concat(o_info1, ' "filename":"', v_filename, '"');
    o_info1 := mystring.f_concat(o_info1, ',"filepath":"', myjson.f_escape(v_filepath), '"');
    o_info1 := mystring.f_concat(o_info1, '}]');
    o_info1 := mystring.f_concat(o_info1, ',"code":"EC00"');
    o_info1 := mystring.f_concat(o_info1, ',"msg":"处理成功"');
    o_info1 := mystring.f_concat(o_info1, '}');
  
    o_info2 := '<info>';
    o_info2 := mystring.f_concat(o_info2, '<dlfiles>');
    o_info2 := mystring.f_concat(o_info2, '<file flag="tempfile">');
    o_info2 := mystring.f_concat(o_info2, v_filepath, v_filename);
    o_info2 := mystring.f_concat(o_info2, '</file>');
    o_info2 := mystring.f_concat(o_info2, '</dlfiles>');
    o_info2 := mystring.f_concat(o_info2, '</info>');
  
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

END pkg_qf_apply;
/
