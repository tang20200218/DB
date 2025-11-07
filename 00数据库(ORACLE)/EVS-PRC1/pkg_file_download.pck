CREATE OR REPLACE PACKAGE pkg_file_download IS
  /***************************************************************************************************
  名称     : pkg_file_download
  功能描述 : 通用文件下载
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-21  唐金鑫  创建  
  ***************************************************************************************************/

  -- 检查权限
  PROCEDURE p_check
  (
    i_filename IN VARCHAR2, -- 文件名
    i_filedir  IN VARCHAR2, -- 文件路径
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 通用文件下载
  PROCEDURE p_main
  (
    i_forminfo IN CLOB,
    i_operuri  IN VARCHAR2,
    i_opername IN VARCHAR2,
    o_info1    OUT VARCHAR2,
    o_info2    OUT VARCHAR2,
    o_code     OUT VARCHAR2,
    o_msg      OUT VARCHAR2
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_file_download IS

  -- 检查权限
  PROCEDURE p_check
  (
    i_filename IN VARCHAR2, -- 文件名
    i_filedir  IN VARCHAR2, -- 文件路径
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_fileid   VARCHAR2(64);
    v_docid    VARCHAR2(64);
    v_filename VARCHAR2(256);
    v_filedir  VARCHAR2(512);
  
    v_exists INT := 0;
    v_dtype  VARCHAR2(64);
    v_utype5 INT := 0; -- 是否管理员(1:是 0:否)
    v_utype6 INT := 0; -- 是否操作员(1:是 0:否)
  BEGIN
    mydebug.wlog('i_filename', i_filename);
    mydebug.wlog('i_filedir', i_filedir);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_filename) THEN
      o_code := 'EC12';
      o_msg  := '文件名为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_filedir) THEN
      o_code := 'EC12';
      o_msg  := '文件路径为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_filename := mycrypt.f_encrypt(i_filename);
    v_filedir  := mycrypt.f_encrypt(i_filedir);
    BEGIN
      SELECT docid, fileid
        INTO v_docid, v_fileid
        FROM data_doc_file t
       WHERE t.filename = v_filename
         AND t.filedir = v_filedir
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_fileid) THEN
      o_code := 'EC12';
      o_msg  := '查询文件信息出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 客户端安装包，不验证权限
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_client t WHERE t.setupfileid = v_fileid);
    IF v_exists = 1 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC12';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1)
      INTO v_utype5
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_admin t
             WHERE t.adminuri = i_operuri
               AND t.admintype = 'MT05');
  
    SELECT COUNT(1)
      INTO v_utype6
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_admin t
             WHERE t.adminuri = i_operuri
               AND t.admintype = 'MT06');
    IF v_utype5 = 0 AND v_utype6 = 0 THEN
      o_code := 'EC12';
      o_msg  := '无权访问该文件！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_docid = v_fileid THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 凭证模板
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_template t WHERE t.tempid = v_docid);
    IF v_exists = 1 THEN
      IF v_utype5 = 0 THEN
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM info_admin_auth t
                 WHERE t.dtype = v_docid
                   AND t.useruri = i_operuri);
        IF v_exists = 0 THEN
          o_code := 'EC12';
          o_msg  := '无权访问该文件！';
          mydebug.wlog(3, o_code, o_msg);
          RETURN;
        END IF;
      END IF;
    
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 空白凭证
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_yz_pz_pub t WHERE t.id = v_docid);
    IF v_exists = 1 THEN
      BEGIN
        SELECT t.dtype INTO v_dtype FROM data_yz_pz_pub t WHERE t.id = v_docid;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      SELECT COUNT(1)
        INTO v_exists
        FROM dual
       WHERE EXISTS (SELECT 1
                FROM info_admin_auth t
               WHERE t.dtype = v_dtype
                 AND t.useruri = i_operuri);
      IF v_exists = 0 THEN
        o_code := 'EC12';
        o_msg  := '无权访问该文件！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 凭证签发办理-申请文件
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_qf_notice_applyinfo t WHERE t.id = v_docid);
    IF v_exists = 1 THEN
      pkg_qp_verify.p_check('MD110', i_operuri, i_opername, o_code, o_msg);
      RETURN;
    END IF;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC12';
      o_msg  := '请求验证失败！';
      mydebug.err(7);
  END;

  -- 通用文件下载
  PROCEDURE p_main
  (
    i_forminfo IN CLOB,
    i_operuri  IN VARCHAR2,
    i_opername IN VARCHAR2,
    o_info1    OUT VARCHAR2,
    o_info2    OUT VARCHAR2,
    o_code     OUT VARCHAR2,
    o_msg      OUT VARCHAR2
  ) AS
    v_filename VARCHAR2(256);
    v_filepath VARCHAR2(512);
  BEGIN
    mydebug.wlog('开始');
  
    -- 解析表单信息
    SELECT json_value(i_forminfo, '$.filename') INTO v_filename FROM dual;
    SELECT json_value(i_forminfo, '$.filepath') INTO v_filepath FROM dual;
  
    mydebug.wlog('v_filename', v_filename);
    mydebug.wlog('v_filepath', v_filepath);
  
    -- 检查权限
    pkg_file_download.p_check(v_filename, v_filepath, i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    o_info1 := '{"code":"EC00","msg":"处理成功！"}';
  
    -- 返回文件
    o_info2 := '<info>';
    o_info2 := mystring.f_concat(o_info2, '<dlfiles>');
    o_info2 := mystring.f_concat(o_info2, '<file flag="datafile">');
    o_info2 := mystring.f_concat(o_info2, myfile.f_filepathaddname(v_filepath, v_filename));
    o_info2 := mystring.f_concat(o_info2, '</file>');
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

END;
/
