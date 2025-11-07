CREATE OR REPLACE PACKAGE pkg_file0 IS
  /***************************************************************************************************
  名称     : pkg_file0
  功能描述 : 文件信息维护公共包
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2017-09-04  唐金鑫  创建  
  ***************************************************************************************************/

  -- 查询文件名
  FUNCTION f_getfilename(i_fileid VARCHAR2) RETURN VARCHAR2;

  -- 查询文件路径
  FUNCTION f_getfilepath(i_fileid VARCHAR2) RETURN VARCHAR2;

  -- 查询文件路径(带文件名)
  FUNCTION f_getfilepath2(i_fileid VARCHAR2) RETURN VARCHAR2;

  -- 查询文件ID
  FUNCTION f_getfileid
  (
    i_docid VARCHAR2,
    i_isdoc INT
  ) RETURN VARCHAR2;

  -- 查询文件名
  FUNCTION f_getfilename_docid
  (
    i_docid VARCHAR2,
    i_isdoc INT
  ) RETURN VARCHAR2;

  -- 查询文件路径
  FUNCTION f_getfilepath_docid
  (
    i_docid VARCHAR2,
    i_isdoc INT
  ) RETURN VARCHAR2;

  -- 系统初始化配置的文件路径
  FUNCTION f_getconfig RETURN VARCHAR2;

  -- 绝对路径改成相对路径
  FUNCTION f_path2relative(i_filepath VARCHAR2) RETURN VARCHAR2;

  -- 相对路径改成绝对路径
  FUNCTION f_path2absolute(i_filepath VARCHAR2) RETURN VARCHAR2;

  -- 增加文件
  PROCEDURE p_ins0
  (
    i_filename IN VARCHAR2,
    i_filepath IN VARCHAR2,
    i_filesize IN NUMBER,
    i_docid    IN VARCHAR2,
    i_isdoc    IN INT,
    i_operuri  IN VARCHAR2, -- 操作人id
    i_opername IN VARCHAR2, -- 操作人姓名
    o_fileid   OUT VARCHAR2,
    o_code     OUT VARCHAR2, -- 出错代码
    o_msg      OUT VARCHAR2 -- 出错原因
  );
  PROCEDURE p_ins1
  (
    i_filename IN VARCHAR2,
    i_filepath IN VARCHAR2,
    i_filesize IN NUMBER,
    i_operuri  IN VARCHAR2, -- 操作人id
    i_opername IN VARCHAR2, -- 操作人姓名
    o_fileid   OUT VARCHAR2,
    o_code     OUT VARCHAR2, -- 出错代码
    o_msg      OUT VARCHAR2 -- 出错原因
  );
  PROCEDURE p_ins2
  (
    i_filename IN VARCHAR2,
    i_filepath IN VARCHAR2,
    i_filesize IN NUMBER,
    i_docid    IN VARCHAR2,
    i_isdoc    IN INT,
    i_operuri  IN VARCHAR2, -- 操作人id
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 出错代码
    o_msg      OUT VARCHAR2 -- 出错原因
  );
  PROCEDURE p_ins3
  (
    i_filename IN VARCHAR2,
    i_filepath IN VARCHAR2,
    i_filesize IN NUMBER,
    i_docid    IN VARCHAR2,
    i_isdoc    IN INT,
    i_operuri  IN VARCHAR2, -- 操作人id
    i_opername IN VARCHAR2, -- 操作人姓名
    o_fileid   OUT VARCHAR2,
    o_code     OUT VARCHAR2, -- 出错代码
    o_msg      OUT VARCHAR2 -- 出错原因
  );

  -- 重命名
  PROCEDURE p_rename
  (
    i_fileid   IN VARCHAR2, -- 文件ID
    i_filename IN VARCHAR2, -- 文件名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除文件
  PROCEDURE p_del
  (
    i_fileid IN VARCHAR2, -- 文件ID
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  );

  -- 按业务数据标识删除文件
  PROCEDURE p_del_docid
  (
    i_docid IN VARCHAR2, -- 业务数据标识
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_file0 IS

  -- 查询文件名
  FUNCTION f_getfilename(i_fileid VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(200);
  BEGIN
    SELECT mycrypt.f_decrypt(t1.filename) INTO v_result FROM data_doc_file t1 WHERE t1.fileid = i_fileid;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询文件路径
  FUNCTION f_getfilepath(i_fileid VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(1024);
  BEGIN
    SELECT mycrypt.f_decrypt(t1.filedir) INTO v_result FROM data_doc_file t1 WHERE t1.fileid = i_fileid;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询文件路径(带文件名)
  FUNCTION f_getfilepath2(i_fileid VARCHAR2) RETURN VARCHAR2 AS
    v_filename VARCHAR2(1024);
    v_filedir  VARCHAR2(1024);
  BEGIN
    SELECT mycrypt.f_decrypt(t1.filename) INTO v_filename FROM data_doc_file t1 WHERE t1.fileid = i_fileid;
    SELECT mycrypt.f_decrypt(t1.filedir) INTO v_filedir FROM data_doc_file t1 WHERE t1.fileid = i_fileid;
    RETURN myfile.f_filepathaddname(v_filedir, v_filename);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询文件ID
  FUNCTION f_getfileid
  (
    i_docid VARCHAR2,
    i_isdoc INT
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(200);
  BEGIN
    SELECT t1.fileid
      INTO v_result
      FROM data_doc_file t1
     WHERE t1.docid = i_docid
       AND t1.isdoc = i_isdoc
       AND rownum <= 1;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询文件名
  FUNCTION f_getfilename_docid
  (
    i_docid VARCHAR2,
    i_isdoc INT
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(200);
  BEGIN
    SELECT mycrypt.f_decrypt(t1.filename)
      INTO v_result
      FROM data_doc_file t1
     WHERE t1.docid = i_docid
       AND t1.isdoc = i_isdoc
       AND rownum <= 1;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询文件路径
  FUNCTION f_getfilepath_docid
  (
    i_docid VARCHAR2,
    i_isdoc INT
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(1024);
  BEGIN
    SELECT mycrypt.f_decrypt(t1.filedir)
      INTO v_result
      FROM data_doc_file t1
     WHERE t1.docid = i_docid
       AND t1.isdoc = i_isdoc
       AND rownum <= 1;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 系统初始化配置的文件路径
  FUNCTION f_getconfig RETURN VARCHAR2 AS
    v_config VARCHAR2(200);
  BEGIN
    v_config := pkg_basic.f_getconfig('cf07');
    RETURN myfile.f_diraddend(v_config);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '/';
  END;

  -- 绝对路径改成相对路径
  FUNCTION f_path2relative(i_filepath VARCHAR2) RETURN VARCHAR2 AS
    v_config VARCHAR2(200); -- 系统初始化配置的文件路径
  BEGIN
    v_config := pkg_file0.f_getconfig;
    RETURN myfile.f_path_del(i_filepath, v_config);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_filepath;
  END;

  -- 相对路径改成绝对路径
  FUNCTION f_path2absolute(i_filepath VARCHAR2) RETURN VARCHAR2 AS
    v_config VARCHAR2(200); -- 系统初始化配置的文件路径
  BEGIN
    v_config := pkg_file0.f_getconfig;
    RETURN myfile.f_path_concat(v_config, i_filepath);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_filepath;
  END;

  /***************************************************************************************************
  名称     : pkg_file0.p_ins0
  功能描述 : 增加文件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.1   2023-05-09  唐金鑫  创建
  
  业务说明：
  ***************************************************************************************************/
  PROCEDURE p_ins0
  (
    i_filename IN VARCHAR2,
    i_filepath IN VARCHAR2,
    i_filesize IN NUMBER,
    i_docid    IN VARCHAR2,
    i_isdoc    IN INT,
    i_operuri  IN VARCHAR2, -- 操作人id
    i_opername IN VARCHAR2, -- 操作人姓名
    o_fileid   OUT VARCHAR2,
    o_code     OUT VARCHAR2, -- 出错代码
    o_msg      OUT VARCHAR2 -- 出错原因
  ) AS
    v_fileid   VARCHAR2(64);
    v_docid    VARCHAR2(64);
    v_isdoc    INT := 0;
    v_filesize NUMBER(16) := 0;
    v_sort     INT := 0;
    v_filename VARCHAR2(256);
    v_filedir  VARCHAR2(512);
  BEGIN
    mydebug.wlog('i_filename', i_filename);
  
    IF mystring.f_isnull(i_filename) THEN
      o_code := 'EC02';
      o_msg  := '文件名为空,请检查';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_filepath) THEN
      o_code := 'EC02';
      o_msg  := '文件路径为空,请检查';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 2.业务处理
    v_fileid := pkg_basic.f_newid('FI');
    IF mystring.f_isnull(i_docid) THEN
      v_docid := v_fileid;
    ELSE
      v_docid := i_docid;
    END IF;
  
    SELECT MAX(t.sort) INTO v_sort FROM data_doc_file t WHERE t.docid = v_docid;
    IF v_sort IS NULL THEN
      v_sort := 1;
    ELSE
      v_sort := v_sort + 1;
    END IF;
  
    IF i_filesize IS NULL THEN
      v_filesize := 0;
    ELSE
      v_filesize := i_filesize;
    END IF;
  
    IF i_isdoc IS NULL THEN
      v_isdoc := 0;
    ELSE
      v_isdoc := i_isdoc;
    END IF;
  
    v_filename := mycrypt.f_encrypt(i_filename);
    v_filedir  := mycrypt.f_encrypt(i_filepath);
  
    INSERT INTO data_doc_file
      (docid, fileid, isdoc, filename, filedir, filesize, sort, operuri, opername)
    VALUES
      (v_docid, v_fileid, v_isdoc, v_filename, v_filedir, v_filesize, v_sort, i_operuri, i_opername);
  
    -- 返回文件ID
    o_fileid := v_fileid;
  
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
  名称     : pkg_file0.p_ins1
  功能描述 : 增加文件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.1   2023-05-09  唐金鑫  创建
  
  业务说明：
  ***************************************************************************************************/
  PROCEDURE p_ins1
  (
    i_filename IN VARCHAR2,
    i_filepath IN VARCHAR2,
    i_filesize IN NUMBER,
    i_operuri  IN VARCHAR2, -- 操作人id
    i_opername IN VARCHAR2, -- 操作人姓名
    o_fileid   OUT VARCHAR2,
    o_code     OUT VARCHAR2, -- 出错代码
    o_msg      OUT VARCHAR2 -- 出错原因
  ) AS
  BEGIN
    pkg_file0.p_ins0(i_filename, i_filepath, i_filesize, NULL, 0, i_operuri, i_opername, o_fileid, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_file0.p_ins2
  功能描述 : 增加文件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.1   2023-05-09  唐金鑫  创建
  
  业务说明：
  ***************************************************************************************************/
  PROCEDURE p_ins2
  (
    i_filename IN VARCHAR2,
    i_filepath IN VARCHAR2,
    i_filesize IN NUMBER,
    i_docid    IN VARCHAR2,
    i_isdoc    IN INT,
    i_operuri  IN VARCHAR2, -- 操作人id
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 出错代码
    o_msg      OUT VARCHAR2 -- 出错原因
  ) AS
    v_fileid VARCHAR2(64);
  BEGIN
    pkg_file0.p_ins0(i_filename, i_filepath, i_filesize, i_docid, i_isdoc, i_operuri, i_opername, v_fileid, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_file0.p_ins3
  功能描述 : 增加文件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.1   2023-05-09  唐金鑫  创建
  
  业务说明：
  ***************************************************************************************************/
  PROCEDURE p_ins3
  (
    i_filename IN VARCHAR2,
    i_filepath IN VARCHAR2,
    i_filesize IN NUMBER,
    i_docid    IN VARCHAR2,
    i_isdoc    IN INT,
    i_operuri  IN VARCHAR2, -- 操作人id
    i_opername IN VARCHAR2, -- 操作人姓名
    o_fileid   OUT VARCHAR2,
    o_code     OUT VARCHAR2, -- 出错代码
    o_msg      OUT VARCHAR2 -- 出错原因
  ) AS
  BEGIN
    pkg_file0.p_ins0(i_filename, i_filepath, i_filesize, i_docid, i_isdoc, i_operuri, i_opername, o_fileid, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_file0.p_rename
  功能描述 : 重命名
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-03-17  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_rename
  (
    i_fileid   IN VARCHAR2, -- 文件ID
    i_filename IN VARCHAR2, -- 文件名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT := 0;
  BEGIN
    mydebug.wlog('i_fileid', i_fileid);
  
    IF mystring.f_isnull(i_fileid) THEN
      o_code := 'EC02';
      o_msg  := '文件ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM data_doc_file t1 WHERE t1.fileid = i_fileid;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE data_doc_file t SET t.filename = mycrypt.f_encrypt(i_filename) WHERE t.fileid = i_fileid;
  
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
  名称     : pkg_file0.p_del
  功能描述 : 删除文件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2017-09-04  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_del
  (
    i_fileid IN VARCHAR2, -- 文件ID
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT := 0;
  BEGIN
    mydebug.wlog('i_fileid', i_fileid);
  
    IF mystring.f_isnull(i_fileid) THEN
      o_code := 'EC02';
      o_msg  := '文件ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM data_doc_file t1 WHERE t1.fileid = i_fileid;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 则将文件转入临时表
    DELETE FROM file_tmp1 WHERE fileid = i_fileid;
    INSERT INTO file_tmp1
      (fileid, filename, filepath)
      SELECT t1.fileid, t1.filename, t1.filedir FROM data_doc_file t1 WHERE t1.fileid = i_fileid;
  
    DELETE FROM data_doc_file WHERE fileid = i_fileid;
  
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
  名称     : pkg_file0.p_del_docid
  功能描述 : 按业务数据标识删除文件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-22  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_del_docid
  (
    i_docid IN VARCHAR2, -- 业务数据标识
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_docid', i_docid);
  
    INSERT INTO file_tmp1
      (fileid, filename, filepath)
      SELECT t.fileid, t.filename, t.filedir
        FROM data_doc_file t
       WHERE t.docid = i_docid
         AND NOT EXISTS (SELECT 1 FROM file_tmp1 w WHERE w.fileid = t.fileid);
  
    DELETE FROM data_doc_file WHERE docid = i_docid;
  
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
