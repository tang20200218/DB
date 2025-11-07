CREATE OR REPLACE PACKAGE pkg_qf_book_send IS
  /***************************************************************************************************
  名称     : pkg_qf_book_send
  功能描述 : 签发办理-签发凭证的发送
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-14  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 公共凭证签发送给空间
  PROCEDURE p_send_gg11
  (
    i_id           IN VARCHAR2, -- 信息标识
    i_sendid       IN VARCHAR2, -- 发送任务ID
    i_issuepart    IN VARCHAR2, -- 签发模式(0:发送整本凭证 1:发送增量数据)
    i_registerflag IN VARCHAR2, -- 是否首签(1:是 0:否)
    i_touri        IN VARCHAR2, -- 接收对象标识
    i_filename     IN VARCHAR2, -- 文件名称(多个文件，分隔，第一个为正本)
    i_filepath     IN VARCHAR2, -- 文件路径
    i_operuri      IN VARCHAR2, -- 操作人URI
    i_opername     IN VARCHAR2, -- 操作人姓名
    o_code         OUT VARCHAR2, -- 操作结果:错误码
    o_msg          OUT VARCHAR2, -- 成功/错误原因
    o_exchid       OUT VARCHAR2 -- 返回交换ID
  );

  -- 公共凭证签发送应用系统
  PROCEDURE p_send_qd02
  (
    i_id       IN VARCHAR2, -- 信息标识
    i_sendid   IN VARCHAR2, -- 发送任务ID
    i_sendtype IN VARCHAR2, -- 发送方式(1:交换 2:WEBSERVICE URI/JSON)
    i_appuri   IN VARCHAR2, -- 应用标识
    i_touri    IN VARCHAR2, -- 接收对象标识
    i_filename IN VARCHAR2, -- 文件名称(多个文件，分隔，第一个为正本)
    i_filepath IN VARCHAR2, -- 文件路径
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2, -- 成功/错误原因
    o_exchid   OUT VARCHAR2 -- 返回交换ID
  );

  -- 返回签发成功状态给验证服务单位
  PROCEDURE p_send_sq06
  (
    i_id   IN VARCHAR2, -- 信息标识
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 签发凭证的发送
  PROCEDURE p_send_pbl
  (
    i_id            IN VARCHAR2, -- 唯一标识
    i_issuepart     IN VARCHAR2, -- 签发模式(0:发送整本凭证 1:发送增量数据)
    i_registerflag  IN VARCHAR2, -- 是否首签(1:是 0:否)
    i_file1_newname IN VARCHAR2, -- 原始文件的新文件名
    i_file2_name    IN VARCHAR2, -- 签出文件名称
    i_file2_path    IN VARCHAR2, -- 签出文件路径
    i_totype        IN VARCHAR2, -- 接收对象类型(0:未选接收者 1:用户 2:单位 3:微应用)
    i_touri         IN VARCHAR2, -- 接收对象标识
    i_toname        IN VARCHAR2, -- 接收对象名称
    i_route         IN VARCHAR2, -- 路由信息
    i_operuri       IN VARCHAR2, -- 操作人标识
    i_opername      IN VARCHAR2, -- 操作人姓名
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  );

  -- 签发凭证的发送
  PROCEDURE p_send
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询交换状态
  PROCEDURE p_getsendstatus
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
CREATE OR REPLACE PACKAGE BODY pkg_qf_book_send IS

  -- 公共凭证签发送给空间
  PROCEDURE p_send_gg11
  (
    i_id           IN VARCHAR2, -- 信息标识
    i_sendid       IN VARCHAR2, -- 发送任务ID
    i_issuepart    IN VARCHAR2, -- 签发模式(0:发送整本凭证 1:发送增量数据)
    i_registerflag IN VARCHAR2, -- 是否首签(1:是 0:否)
    i_touri        IN VARCHAR2, -- 接收对象标识
    i_filename     IN VARCHAR2, -- 文件名称(多个文件，分隔，第一个为正本)
    i_filepath     IN VARCHAR2, -- 文件路径
    i_operuri      IN VARCHAR2, -- 操作人URI
    i_opername     IN VARCHAR2, -- 操作人姓名
    o_code         OUT VARCHAR2, -- 操作结果:错误码
    o_msg          OUT VARCHAR2, -- 成功/错误原因
    o_exchid       OUT VARCHAR2 -- 返回交换ID
  ) AS
    v_dtype  VARCHAR2(64);
    v_otype  INT;
    v_vtype  INT;
    v_douri  VARCHAR2(64);
    v_doname VARCHAR2(128);
  
    v_info_pdocid       VARCHAR2(128);
    v_info_suri         VARCHAR2(64);
    v_info_sname        VARCHAR2(200);
    v_info_issuepart    INT; -- 签发模式(0:发送整本凭证 1:发送增量数据)
    v_info_issuepart2   INT; -- 配置的签发模式(0:发送整本凭证 1:发送增量数据)
    v_info_registerflag INT; -- 是否首签(1:是 0:否)
  
    v_pz_id        VARCHAR2(64);
    v_pz_num_start INT;
    v_pz_billcode  VARCHAR2(64);
    v_png_filename VARCHAR2(128);
    v_png_filepath VARCHAR2(256);
    v_form         VARCHAR2(4000);
    v_exchfiles    VARCHAR2(4000);
  
    v_exists INT := 0;
  BEGIN
    mydebug.wlog('i_id', i_id);
    mydebug.wlog('i_touri', i_touri);
  
    SELECT dtype, otype, douri, doname INTO v_dtype, v_otype, v_douri, v_doname FROM data_qf_book t WHERE t.id = i_id;
  
    SELECT t.vtype INTO v_vtype FROM info_template t WHERE t.tempid = v_dtype;
  
    SELECT id, num_start, billcode
      INTO v_pz_id, v_pz_num_start, v_pz_billcode
      FROM data_qf_pz t
     WHERE t.pid = i_id
       AND rownum <= 1;
  
    BEGIN
      IF v_vtype = 1 THEN
        SELECT fromid INTO v_info_pdocid FROM data_qf2_applyinfo t WHERE t.id = i_id;
      ELSE
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_qf_app_recinfo t
                 WHERE t.pid = i_id
                   AND t.fromtype = '5');
        IF v_exists > 0 THEN
          SELECT t.prvdata
            INTO v_info_pdocid
            FROM data_qf_app_recinfo t
           WHERE t.pid = i_id
             AND t.fromtype = '5'
             AND rownum <= 1;
        ELSE
          SELECT fromid
            INTO v_info_pdocid
            FROM data_qf_notice_applyinfo t
           WHERE t.dtype = v_dtype
             AND t.fromuri = v_douri
             AND rownum <= 1;
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_info_suri  := pkg_basic.f_getcomid;
    v_info_sname := pkg_basic.f_getcomname;
  
    -- 配置的签发模式(0:发送整本凭证 1:发送增量数据)    
    v_info_issuepart2 := pkg_qf_config.f_getissuepart(v_dtype);
  
    IF i_registerflag = '1' THEN
      v_info_registerflag := 1;
    ELSE
      v_info_registerflag := 0;
    END IF;
  
    IF mystring.f_isnull(i_issuepart) THEN
      v_info_issuepart := 0;
    ELSE
      v_info_issuepart := i_issuepart;
    END IF;
  
    -- 封面文件
    v_png_filename := pkg_file0.f_getfilename_docid(v_pz_id, 0);
    v_png_filepath := pkg_file0.f_getfilepath_docid(v_pz_id, 0);
  
    -- 组织表单数据
    v_form := '<info>';
    v_form := mystring.f_concat(v_form, '<datatype>GG11</datatype>');
    v_form := mystring.f_concat(v_form, '<datatime>', to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'), '</datatime>');
    v_form := mystring.f_concat(v_form, '<id>', i_id, '</id>');
    v_form := mystring.f_concat(v_form, '<pdocid>', v_info_pdocid, '</pdocid>');
    v_form := mystring.f_concat(v_form, '<pzid>', v_pz_id, '</pzid>');
    v_form := mystring.f_concat(v_form, '<evnum>', v_pz_num_start, '</evnum>');
    v_form := mystring.f_concat(v_form, '<billcode>', myxml.f_escape(v_pz_billcode), '</billcode>');
    v_form := mystring.f_concat(v_form, '<mktype>', v_dtype, '</mktype>');
    v_form := mystring.f_concat(v_form, '<dtype>', v_dtype, '</dtype>');
    v_form := mystring.f_concat(v_form, '<evtype>', v_dtype, '</evtype>');
    v_form := mystring.f_concat(v_form, '<otype>', v_otype, '</otype>');
    v_form := mystring.f_concat(v_form, '<issuepart>', v_info_issuepart, '</issuepart>');
    v_form := mystring.f_concat(v_form, '<issuepart2>', v_info_issuepart2, '</issuepart2>');
    v_form := mystring.f_concat(v_form, '<registerflag>', v_info_registerflag, '</registerflag>');
    v_form := mystring.f_concat(v_form, '<suri>', v_info_suri, '</suri>');
    v_form := mystring.f_concat(v_form, '<sname>', v_info_sname, '</sname>');
    v_form := mystring.f_concat(v_form, '<douri>', v_douri, '</douri>');
    v_form := mystring.f_concat(v_form, '<doname>', v_doname, '</doname>');
    v_form := mystring.f_concat(v_form, '<operuri>', i_operuri, '</operuri>');
    v_form := mystring.f_concat(v_form, '<opername>', i_opername, '</opername>');
    v_form := mystring.f_concat(v_form, '<filename>', i_filename, '</filename>');
    v_form := mystring.f_concat(v_form, '<filename2>', v_png_filename, '</filename2>');
    v_form := mystring.f_concat(v_form, '</info>');
  
    v_exchfiles := '<manifest flag="0" deleteDir="" sendCount="1">';
    v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="0" filePath="">sendform.xml</file>');
    v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="7" deal="1" filePath="', i_filepath, '">', myxml.f_escape(i_filename), '</file>');
    IF mystring.f_isnotnull(v_png_filename) AND mystring.f_isnotnull(v_png_filepath) THEN
      v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="7" filePath="', v_png_filepath, '">', myxml.f_escape(v_png_filename), '</file>');
    END IF;
    v_exchfiles := mystring.f_concat(v_exchfiles, '</manifest>');
  
    -- 发送
    pkg_exch_send.p_send2_1(i_sendid, 'GG11', '公共凭证签发发送', v_form, v_exchfiles, i_touri, o_exchid, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    IF v_vtype = 1 THEN
      UPDATE data_qf2_task t SET t.startflag = 1, t.qfflag = 1, t.sendflag = 1, t.sendid = o_exchid, t.senddate = SYSDATE, t.modifieddate = SYSDATE WHERE t.id = i_id;
      UPDATE data_qf2_task t
         SET t.operuri = 'system', t.opername = '自动签发'
       WHERE t.id = i_id
         AND t.autoqf = 1;
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '发送失败，请检查！';
      mydebug.err(7);
  END;

  -- 公共凭证签发送应用系统
  PROCEDURE p_send_qd02
  (
    i_id       IN VARCHAR2, -- 信息标识
    i_sendid   IN VARCHAR2, -- 发送任务ID
    i_sendtype IN VARCHAR2, -- 发送方式(1:交换 2:WEBSERVICE URI/JSON)
    i_appuri   IN VARCHAR2, -- 应用标识
    i_touri    IN VARCHAR2, -- 接收对象标识
    i_filename IN VARCHAR2, -- 文件名称(多个文件，分隔，第一个为正本)
    i_filepath IN VARCHAR2, -- 文件路径
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2, -- 成功/错误原因
    o_exchid   OUT VARCHAR2 -- 返回交换ID
  ) AS
    v_taskid       VARCHAR2(64);
    v_dtype        VARCHAR2(64);
    v_pz_id        VARCHAR2(64);
    v_pz_num_start INT;
    v_pz_billcode  VARCHAR2(64);
    v_prvdata      VARCHAR2(1024);
    v_png_filename VARCHAR2(128);
    v_png_filepath VARCHAR2(256);
    v_form         VARCHAR2(32767);
    v_exchfiles    VARCHAR2(4000);
  BEGIN
    mydebug.wlog('i_id', i_id);
  
    SELECT dtype INTO v_dtype FROM data_qf_book t WHERE t.id = i_id;
  
    SELECT id, num_start, billcode
      INTO v_pz_id, v_pz_num_start, v_pz_billcode
      FROM data_qf_pz t
     WHERE t.pid = i_id
       AND rownum <= 1;
  
    BEGIN
      SELECT t.id
        INTO v_taskid
        FROM data_qf_task_tmp t
       WHERE t.pid = i_id
         AND rownum <= 1;
      SELECT prvdata INTO v_prvdata FROM data_qf_app_recinfo t WHERE t.id = v_taskid;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    -- 封面文件
    v_png_filename := pkg_file0.f_getfilename_docid(v_pz_id, 0);
    v_png_filepath := pkg_file0.f_getfilepath_docid(v_pz_id, 0);
  
    -- 组织表单数据
    v_form := '<info>';
    v_form := mystring.f_concat(v_form, '<datatype>QD02</datatype>');
    v_form := mystring.f_concat(v_form, '<datatime>', to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'), '</datatime>');
    v_form := mystring.f_concat(v_form, '<result>0</result>');
    v_form := mystring.f_concat(v_form, '<msg>成功</msg>');
    v_form := mystring.f_concat(v_form, '<prvdata>', v_prvdata, '</prvdata>');
    v_form := mystring.f_concat(v_form, '<bookid>', i_id, '</bookid>');
    v_form := mystring.f_concat(v_form, '<cardcode>', v_dtype, '</cardcode>');
    v_form := mystring.f_concat(v_form, '<filenum>', v_pz_num_start, '</filenum>');
    v_form := mystring.f_concat(v_form, '<billcode>', myxml.f_escape(v_pz_billcode), '</billcode>');
    v_form := mystring.f_concat(v_form, '<files>');
    v_form := mystring.f_concat(v_form, '<file type="0" >', i_filename, '</file>');
    v_form := mystring.f_concat(v_form, '<file type="3" >', v_png_filename, '</file>');
    v_form := mystring.f_concat(v_form, '</files>');
    v_form := mystring.f_concat(v_form, '</info>');
  
    IF i_sendtype = '1' THEN
      -- 通过交换发送
      v_exchfiles := '<manifest flag="0" deleteDir="" sendCount="1">';
      v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="0" filePath="">sendform.xml</file>');
      v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="7" filePath="', i_filepath, '">', myxml.f_escape(i_filename), '</file>');
      IF mystring.f_isnotnull(v_png_filename) AND mystring.f_isnotnull(v_png_filepath) THEN
        v_exchfiles := mystring.f_concat(v_exchfiles, '<file flag="7" filePath="', v_png_filepath, '">', myxml.f_escape(v_png_filename), '</file>');
      END IF;
      v_exchfiles := mystring.f_concat(v_exchfiles, '</manifest>');
    
      -- 送交换
      pkg_exch_send.p_send2_1(i_sendid, 'QD02', '签发凭证发送给应用', v_form, v_exchfiles, i_touri, o_exchid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    ELSE
      -- 通过WEBSERVICE URI/JSON发送    
      v_exchfiles := '<files>';
      v_exchfiles := mystring.f_concat(v_exchfiles, '<file type="0" path="', i_filepath, '">', i_filename, '</file>');
      IF mystring.f_isnotnull(v_png_filename) AND mystring.f_isnotnull(v_png_filepath) THEN
        v_exchfiles := mystring.f_concat(v_exchfiles, '<file type="3" path="', v_png_filepath, '">', v_png_filename, '</file>');
      END IF;
      v_exchfiles := mystring.f_concat(v_exchfiles, '</files>');
    
      INSERT INTO data_qf_app_sendqueue (id) VALUES (i_sendid);
      INSERT INTO data_qf_app_sendinfo (id, fromid, datatype, appuri, forminfo, files) VALUES (i_sendid, i_id, '0', i_appuri, v_form, v_exchfiles);
      o_exchid := i_sendid;
    END IF;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '发送失败，请检查！';
      mydebug.err(7);
  END;

  -- 返回签发成功状态给验证服务单位
  PROCEDURE p_send_sq06
  (
    i_id   IN VARCHAR2, -- 信息标识
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_suri  VARCHAR2(64);
    v_sname VARCHAR2(128);
  
    v_form VARCHAR2(4000);
  
    v_sendid   VARCHAR2(64);
    v_exchid   VARCHAR2(64);
    v_fromid   VARCHAR2(64);
    v_fromtype VARCHAR2(8);
  BEGIN
    mydebug.wlog('i_id', i_id);
  
    BEGIN
      SELECT docid, fromuri, fromname, fromtype
        INTO v_fromid, v_suri, v_sname, v_fromtype
        FROM (SELECT * FROM data_qf_app_recinfo t WHERE t.pid = i_id ORDER BY t.createddate DESC) q
       WHERE rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_fromtype) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_fromtype <> '5' THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 组织表单数据
    v_form := '<info>';
    v_form := mystring.f_concat(v_form, '<datatype>CNS202</datatype>');
    v_form := mystring.f_concat(v_form, '<datatype2>SQ06</datatype2>');
    v_form := mystring.f_concat(v_form, '<datatime>', to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'), '</datatime>');
    v_form := mystring.f_concat(v_form, '<suri>', v_suri, '</suri>');
    v_form := mystring.f_concat(v_form, '<sname>', v_sname, '</sname>');
    v_form := mystring.f_concat(v_form, '<id>', v_fromid, '</id>');
    v_form := mystring.f_concat(v_form, '</info>');
  
    -- 发送
    pkg_exch_send.p_send2_1(v_sendid, 'SQ06', '签发成功状态', v_form, NULL, v_suri, v_exchid, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    UPDATE data_qf_app_recinfo t SET t.replystatus = 1, t.replyid = v_exchid WHERE t.pid = i_id;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '发送失败，请检查！';
      mydebug.err(7);
  END;

  -- 签发凭证的发送
  PROCEDURE p_send_pbl
  (
    i_id            IN VARCHAR2, -- 唯一标识
    i_issuepart     IN VARCHAR2, -- 签发模式(0:发送整本凭证 1:发送增量数据)
    i_registerflag  IN VARCHAR2, -- 是否首签(1:是 0:否)
    i_file1_newname IN VARCHAR2, -- 原始文件的新文件名
    i_file2_name    IN VARCHAR2, -- 签出文件名称
    i_file2_path    IN VARCHAR2, -- 签出文件路径
    i_totype        IN VARCHAR2, -- 接收对象类型(0:未选接收者 1:用户 2:单位 3:微应用)
    i_touri         IN VARCHAR2, -- 接收对象标识
    i_toname        IN VARCHAR2, -- 接收对象名称
    i_route         IN VARCHAR2, -- 路由信息
    i_operuri       IN VARCHAR2, -- 操作人标识
    i_opername      IN VARCHAR2, -- 操作人姓名
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_send_id       VARCHAR2(64);
    v_send_sort     INT;
    v_send_sendtype VARCHAR2(8);
    v_send_totype   VARCHAR2(8);
    v_send_touri    VARCHAR2(64);
    v_send_toname   VARCHAR2(128);
    v_exchid        VARCHAR2(64);
  
    v_backtype   VARCHAR2(8);
    v_backappuri VARCHAR2(64);
  
    v_otype   INT;
    v_douri   VARCHAR2(64);
    v_doname  VARCHAR2(128);
    v_pz_id   VARCHAR2(64);
    v_fileid  VARCHAR2(64);
    v_sysdate DATE := SYSDATE;
    v_exists  INT := 0;
  BEGIN
    mydebug.wlog('i_id', i_id);
    mydebug.wlog('i_issuepart', i_issuepart);
    mydebug.wlog('i_registerflag', i_registerflag);
    mydebug.wlog('i_file1_newname', i_file1_newname);
    mydebug.wlog('i_file2_name', i_file2_name);
    mydebug.wlog('i_file2_path', i_file2_path);
    mydebug.wlog('i_totype', i_totype);
    mydebug.wlog('i_touri', i_touri);
    mydebug.wlog('i_toname', i_toname);
    mydebug.wlog('i_route', i_route);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_id) THEN
      o_code := 'EC02';
      o_msg  := '签发标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_file2_name) OR mystring.f_isnull(i_file2_path) THEN
      o_code := 'EC02';
      o_msg  := '未获取签发凭证文件信息！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_issuepart) THEN
      o_code := 'EC07';
      o_msg  := '签发模式为空！';
      mydebug.wlog(3, o_code, o_msg);
    END IF;
  
    IF mystring.f_isnull(i_registerflag) THEN
      o_code := 'EC07';
      o_msg  := '是否首签为空！';
      mydebug.wlog(3, o_code, o_msg);
    END IF;
  
    BEGIN
      SELECT id
        INTO v_pz_id
        FROM data_qf_pz t
       WHERE t.pid = i_id
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    v_fileid := pkg_file0.f_getfileid(v_pz_id, 2);
    -- 防止出错后，原始文件无法复原，原始文件重命名
    IF mystring.f_isnotnull(v_fileid) AND mystring.f_isnotnull(i_file1_newname) THEN
      pkg_file0.p_rename(v_fileid, i_file1_newname, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    SELECT otype, douri, doname, backtype, backappuri INTO v_otype, v_douri, v_doname, v_backtype, v_backappuri FROM data_qf_book t WHERE t.id = i_id;
    mydebug.wlog('v_douri', v_douri);
  
    IF mystring.f_isnotnull(i_route) THEN
      pkg_exch_to_site.p_ins(v_douri, v_doname, 'QT10', i_route, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    -- 存储发送信息
    UPDATE data_qf_send t SET t.isnew = 0 WHERE t.pid = i_id;
  
    SELECT MAX(t.sort) INTO v_send_sort FROM data_qf_send t WHERE t.pid = i_id;
    IF v_send_sort IS NULL THEN
      v_send_sort := 1;
    ELSE
      v_send_sort := v_send_sort + 1;
    END IF;
  
    v_send_id := pkg_basic.f_newid('SE');
  
    pkg_file0.p_ins3(i_file2_name, i_file2_path, 0, v_send_id, 0, i_operuri, i_opername, v_fileid, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    INSERT INTO data_qf_send
      (id, pid, isnew, fileid, issuepart, registerflag, sort, operuri, opername)
    VALUES
      (v_send_id, i_id, 1, v_fileid, i_issuepart, i_registerflag, v_send_sort, i_operuri, i_opername);
  
    IF i_totype = '0' THEN
      -- 未选接收者
      IF v_backtype = '0' THEN
        -- 送数字空间
        v_send_sendtype := '1';
        IF v_otype = 0 THEN
          v_send_totype := '1';
        ELSE
          v_send_totype := '2';
        END IF;
        v_send_touri  := v_douri;
        v_send_toname := v_doname;
      END IF;
    ELSIF i_totype = '3' THEN
      v_backtype   := '1';
      v_backappuri := i_touri;
    ELSE
      v_backtype      := '0';
      v_send_sendtype := '1';
      v_send_totype   := i_totype;
      v_send_touri    := i_touri;
      v_send_toname   := i_toname;
    END IF;
  
    IF v_backtype = '1' THEN
      -- 送应用系统
      DECLARE
        v_apptype  VARCHAR2(8);
        v_reptype  VARCHAR2(8);
        v_backkind VARCHAR2(8);
      BEGIN
        SELECT COUNT(1) INTO v_exists FROM info_apps_book1 t WHERE t.appuri = v_backappuri;
        IF v_exists = 0 THEN
          o_code := 'EC02';
          o_msg  := '查询应用信息出错,请检查！';
          mydebug.wlog(3, o_code, o_msg);
          RETURN;
        END IF;
      
        SELECT apptype INTO v_apptype FROM info_apps_book1 t WHERE t.appuri = v_backappuri;
      
        IF v_apptype = '0' THEN
          -- 仅收凭证
          SELECT reptype INTO v_reptype FROM info_apps_book1 t WHERE t.appuri = v_backappuri;
          IF v_reptype = '1' THEN
            -- 交换
            v_send_sendtype := '1';
          ELSE
            -- WEBSERVICE  URI/JSON 接收
            v_send_sendtype := '2';
          END IF;
          v_send_totype := '3';
          v_send_touri  := v_backappuri;
          SELECT appname INTO v_send_toname FROM info_apps_book1 t WHERE t.appuri = v_backappuri;
        ELSE
          -- 提供数据
          SELECT backkind INTO v_backkind FROM info_apps_book1 t WHERE t.appuri = v_backappuri;
          IF v_backkind = '1' THEN
            -- 返回本应用
            SELECT backtype INTO v_backtype FROM info_apps_book1 t WHERE t.appuri = v_backappuri;
            IF v_backtype = '1' THEN
              -- 交换接收
              v_send_sendtype := '1';
            ELSE
              -- WEBSERVICE  URI/JSON 接收
              v_send_sendtype := '2';
            END IF;
            v_send_totype := '3';
            v_send_touri  := v_backappuri;
            SELECT appname INTO v_send_toname FROM info_apps_book1 t WHERE t.appuri = v_backappuri;
          ELSIF v_backkind = '2' THEN
            -- 返回其他应用
            SELECT backtype INTO v_backtype FROM info_apps_book1 t WHERE t.appuri = v_backappuri;
            IF v_backtype = '1' THEN
              -- 交换接收  
              v_send_sendtype := '1';
            ELSE
              -- WEBSERVICE  URI/JSON 接收
              v_send_sendtype := '2';
            END IF;
            v_send_totype := '3';
            SELECT backapp, backappname INTO v_send_touri, v_send_toname FROM info_apps_book1 t WHERE t.appuri = v_backappuri;
          ELSE
            -- 返回数字空间
            v_send_sendtype := '1';
            v_send_totype   := v_otype;
            v_send_touri    := v_douri;
            v_send_toname   := v_doname;
          END IF;
        END IF;
      END;
    END IF;
  
    IF v_send_totype = '3' THEN
      -- 送应用系统
      pkg_qf_book_send.p_send_qd02(i_id, v_send_id, v_send_sendtype, v_backappuri, v_send_touri, i_file2_name, i_file2_path, o_code, o_msg, v_exchid);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    ELSE
      -- 送数字空间
      pkg_qf_book_send.p_send_gg11(i_id, v_send_id, i_issuepart, i_registerflag, v_send_touri, i_file2_name, i_file2_path, i_operuri, i_opername, o_code, o_msg, v_exchid);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    UPDATE data_qf_send t SET t.sendtype = v_send_sendtype, t.totype = v_send_totype, t.touri = v_send_touri, t.toname = v_send_toname, t.exchid = v_exchid WHERE t.id = v_send_id;
  
    o_code := 'EC00';
    DECLARE
      v_task_file_fileid VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t2.fileid FROM data_qf_task_tmp t1 INNER JOIN data_qf_task_file t2 ON (t2.pid = t1.id AND t2.fileid IS NOT NULL) WHERE t1.pid = i_id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_task_file_fileid;
        EXIT WHEN v_cursor%NOTFOUND;
        pkg_file0.p_del(v_task_file_fileid, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          EXIT;
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
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
  
    DECLARE
      v_tmp_id VARCHAR2(64);
      v_rel_id VARCHAR2(128);
      CURSOR v_cursor IS
        SELECT t.id FROM data_qf_task_tmp t WHERE t.pid = i_id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_tmp_id;
        EXIT WHEN v_cursor%NOTFOUND;
        UPDATE data_qf_task t SET t.sendstatus = 1, t.senddate = v_sysdate WHERE t.id = v_tmp_id;
        DELETE FROM data_qf_task_file WHERE pid = v_tmp_id;
      
        v_rel_id := mystring.f_concat(v_send_id, v_tmp_id);
        INSERT INTO data_qf_send_rel (id, pid, sendid, taskid) VALUES (v_rel_id, i_id, v_send_id, v_tmp_id);
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
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
  
    DELETE FROM data_qf_task_tmp WHERE pid = i_id;
  
    DECLARE
      v_dtype VARCHAR2(64);
    BEGIN
      SELECT dtype INTO v_dtype FROM data_qf_book t WHERE t.id = i_id;
      UPDATE data_qf_notice_send t
         SET t.status = 'ST75'
       WHERE t.dtype = v_dtype
         AND t.touri = v_douri;
    END;
  
    -- 设置已发送
    UPDATE data_qf_book t SET t.status = 'GG02', t.ver = t.ver + 1, t.modifieddate = v_sysdate WHERE t.id = i_id;
    DECLARE
      v_operuri VARCHAR2(64);
    BEGIN
      SELECT operuri INTO v_operuri FROM data_qf_book WHERE id = i_id;
      IF mystring.f_isnull(v_operuri) THEN
        UPDATE data_qf_book t SET t.operuri = i_operuri, t.opername = i_opername WHERE t.id = i_id;
      ELSE
        IF mystring.f_isnotnull(i_operuri) AND i_operuri <> 'system' THEN
          UPDATE data_qf_book t SET t.operuri = i_operuri, t.opername = i_opername WHERE t.id = i_id;
        END IF;
      END IF;
    END;
  
    -- 返回签发成功状态给验证服务单位
    pkg_qf_book_send.p_send_sq06(i_id, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_qf_book_send.p_send
  功能描述 : 签发凭证的发送
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-24  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_send
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id            VARCHAR2(64); -- 票本标识
    v_issuepart     VARCHAR2(8); -- 签发模式(0:发送整本凭证 1:发送增量数据)
    v_registerflag  VARCHAR2(8); -- 是否首签(1:是 0:否)
    v_file1_newname VARCHAR2(256); -- 原始文件的新文件名
    v_file2_name    VARCHAR2(256); -- 签出文件名称
    v_file2_path    VARCHAR2(512); -- 签出文件路径
    v_totype        VARCHAR2(8); -- 接收对象类型(0:未选接收者 1:用户 2:单位 3:微应用)
    v_touri         VARCHAR2(64); -- 接收对象标识
    v_toname        VARCHAR2(128); -- 接收对象名称
    v_route         VARCHAR2(4000); -- 路由信息
    v_exists        INT := 0;
  BEGIN
    SELECT json_value(i_forminfo, '$.i_id') INTO v_id FROM dual;
    SELECT json_value(i_forminfo, '$.i_issuepart') INTO v_issuepart FROM dual;
    SELECT json_value(i_forminfo, '$.i_registerflag') INTO v_registerflag FROM dual;
    SELECT json_value(i_forminfo, '$.i_newname') INTO v_file1_newname FROM dual;
    SELECT json_value(i_forminfo, '$.i_filename') INTO v_file2_name FROM dual;
    SELECT json_value(i_forminfo, '$.i_filepath') INTO v_file2_path FROM dual;
    SELECT json_value(i_forminfo, '$.i_totype') INTO v_totype FROM dual;
    SELECT json_value(i_forminfo, '$.i_touri') INTO v_touri FROM dual;
    SELECT json_value(i_forminfo, '$.i_toname') INTO v_toname FROM dual;
    SELECT json_value(i_forminfo, '$.i_route') INTO v_route FROM dual;
  
    mydebug.wlog('v_id', v_id);
  
    IF mystring.f_isnull(v_id) THEN
      o_code := 'EC02';
      o_msg  := '签发标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM data_qf_book t WHERE t.id = v_id;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_totype) THEN
      v_totype := '0';
    END IF;
  
    pkg_qf_book_send.p_send_pbl(v_id,
                                v_issuepart,
                                v_registerflag,
                                v_file1_newname,
                                v_file2_name,
                                v_file2_path,
                                v_totype,
                                v_touri,
                                v_toname,
                                v_route,
                                i_operuri,
                                i_opername,
                                o_code,
                                o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM data_qf_task t
             WHERE t.pid = v_id
               AND t.sendstatus = 0);
    IF v_exists = 0 THEN
      DELETE FROM data_qf_queue WHERE id = v_id;
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 查询交换状态
  PROCEDURE p_getsendstatus
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id           VARCHAR2(64);
    v_douri        VARCHAR2(64);
    v_doname       VARCHAR2(128);
    v_siteinfolist VARCHAR2(4000);
    v_statusimg    VARCHAR2(4000);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.i_id') INTO v_id FROM dual;
    mydebug.wlog('v_id', v_id);
  
    BEGIN
      SELECT douri, doname INTO v_douri, v_doname FROM data_qf_book WHERE id = v_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_siteinfolist := pkg_qf_book.f_getsiteinfolist(v_id, v_douri);
    v_statusimg    := pkg_qf_book.f_getstatusimgstr(v_id, v_douri);
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"objContent":[');
    o_info := mystring.f_concat(o_info, '{');
    o_info := mystring.f_concat(o_info, ' "name":"', myjson.f_escape(v_doname), '"');
    o_info := mystring.f_concat(o_info, ',"siteInfoList":', v_siteinfolist, '');
    o_info := mystring.f_concat(o_info, ',"statusImg":"', myjson.f_escape(v_statusimg), '"');
    o_info := mystring.f_concat(o_info, ',"lastSitType":"NT01"');
    o_info := mystring.f_concat(o_info, ',"cancleSitId":""');
    o_info := mystring.f_concat(o_info, '}');
    o_info := mystring.f_concat(o_info, ']');
    o_info := mystring.f_concat(o_info, ',"code":"EC00"');
    o_info := mystring.f_concat(o_info, ',"msg":"处理成功"');
    o_info := mystring.f_concat(o_info, '}');
  
    mydebug.wlog('o_info', o_info);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      o_info := NULL;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
