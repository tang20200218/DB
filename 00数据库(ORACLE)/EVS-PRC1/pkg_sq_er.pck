CREATE OR REPLACE PACKAGE pkg_sq_er IS

  /***************************************************************************************************
  名称     : pkg_sq_er
  功能描述 : 空白凭证申领-通过交换接收空白凭证
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-08  唐金鑫  创建
  
  <info type="EVS">
      <datatype>SQ02</datatype>
      <datatime>2023-02-08 14:37:13</datatime>
      <docid>SQ20230208143546000649083</docid>
      <pdocid>SQ20230208143638003382496</pdocid>
      <dtype>DW004400002</dtype>
      <evtype>DW004400002</evtype>
      <pcode>DW004</pcode>
      <dispnum>1</dispnum>
      <sendtime>2023-02-08 14:37:13</sendtime>
      <operuri>P0159</operuri>
      <opername>唐金鑫</opername>
      <files>
          <file id="FS20230208093332000648960" num="1" nm="10000183" em="10000183" et="DW004400002" bc="22122101" bn="商用类用水数据资产证" bo="深圳市水务（集团）有限公司印制" fn="0025bbcbd8a94d9d9fabd9c50ebd219f.evf" fn2="b203763c407c4b838c1e8cc4010f5b22.png"/>
      </files>
  </info>
  
  业务说明
  ***************************************************************************************************/

  -- 接收空白凭证
  PROCEDURE p_disp
  (
    i_exchid   IN VARCHAR2, -- 交换标识
    i_forminfo IN CLOB, -- 表单数据
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 接收拒绝申领信息
  PROCEDURE p_refuse
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_sq_er IS

  -- 接收空白凭证
  PROCEDURE p_disp
  (
    i_exchid   IN VARCHAR2, -- 交换标识
    i_forminfo IN CLOB, -- 表单数据
    i_filepath IN VARCHAR2, -- 文件信息
    i_taskid   IN VARCHAR2, -- 接收任务ID
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml         xmltype;
    v_i           INT;
    v_xpath       VARCHAR2(200);
    v_files_count INT := 0;
  
    v_docid    VARCHAR2(128);
    v_dtype    VARCHAR2(64);
    v_dispnum  INTEGER;
    v_pngname  VARCHAR2(64);
    v_operuri  VARCHAR2(64);
    v_opername VARCHAR2(64);
  
    v_file_num VARCHAR2(128);
    v_file_nm  VARCHAR2(64);
    v_file_em  VARCHAR2(64);
    v_file_bc  VARCHAR2(128);
    v_file_bo  VARCHAR2(128);
    v_file_fn  VARCHAR2(128);
  
    v_pub_id VARCHAR2(128);
  
    v_sysdate DATE := SYSDATE;
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
    mydebug.wlog('i_forminfo', i_forminfo);
    mydebug.wlog('i_filepath', i_filepath);
    mydebug.wlog('i_taskid', i_taskid);
  
    -- 解析表单数据
    v_xml := xmltype(i_forminfo);
    SELECT myxml.f_getvalue(v_xml, '/info/pdocid') INTO v_docid FROM dual;
    SELECT myxml.f_getint(v_xml, '/info/dispnum') INTO v_dispnum FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/pngname') INTO v_pngname FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/operuri') INTO v_operuri FROM dual;
    SELECT myxml.f_getvalue(v_xml, '/info/opername') INTO v_opername FROM dual;
  
    DECLARE
      v_exists INT := 0;
    BEGIN
      SELECT COUNT(1) INTO v_exists FROM data_sq_book1 t WHERE t.docid = v_docid;
      IF v_exists = 0 THEN
        o_code := 'EC00';
        o_msg  := '处理成功';
        mydebug.wlog(1, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    SELECT dtype INTO v_dtype FROM data_sq_book1 t WHERE t.docid = v_docid;
  
    v_i           := 1;
    v_files_count := 0;
    WHILE v_i <= 1000 LOOP
      v_xpath := mystring.f_concat('/info/files/file[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@num')) INTO v_file_num FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@nm')) INTO v_file_nm FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@em')) INTO v_file_em FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@bc')) INTO v_file_bc FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@bo')) INTO v_file_bo FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@fn')) INTO v_file_fn FROM dual;
      IF mystring.f_isnull(v_file_fn) THEN
        v_i := 1000;
      ELSE
        v_pub_id := pkg_basic.f_newid('FS');
        INSERT INTO data_yz_pz_pub
          (id, taskid, dtype, num_start, num_end, num_count, billcode, billorg, islocal, operuri, opername)
        VALUES
          (v_pub_id, v_docid, v_dtype, v_file_nm, v_file_em, v_file_num, v_file_bc, v_file_bo, '0', v_operuri, v_opername);
      
        INSERT INTO data_sq_apply_pz
          (id, docid, dtype, num_start, num_end, num_count, billcode, billorg)
        VALUES
          (v_pub_id, v_docid, v_dtype, v_file_nm, v_file_em, v_file_num, v_file_bc, v_file_bo);
      
        pkg_file0.p_ins2(v_file_fn, i_filepath, 0, v_pub_id, 2, 'system', 'system', o_code, o_msg);
        IF o_code <> 'EC00' THEN
          RETURN;
        END IF;
      
        pkg_file0.p_ins2(v_pngname, i_filepath, 0, v_pub_id, 0, 'system', 'system', o_code, o_msg);
        IF o_code <> 'EC00' THEN
          RETURN;
        END IF;
      
        -- 删除交换接收表里面的文件
        pkg_x_file.p_del(i_taskid, v_file_fn, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          ROLLBACK;
          RETURN;
        END IF;
      
        v_files_count := v_files_count + 1;
      END IF;
    
      v_i := v_i + 1;
    END LOOP;
  
    -- 删除交换接收表里面的文件
    pkg_x_file.p_del(i_taskid, v_pngname, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    DECLARE
      v_receivenum INT;
    BEGIN
      SELECT receivenum INTO v_receivenum FROM data_sq_book1 t WHERE t.docid = v_docid;
      v_receivenum := v_receivenum + v_files_count;
      IF v_receivenum >= v_dispnum THEN
        UPDATE data_sq_book1 t SET t.status = 'ST03' WHERE t.docid = v_docid;
      ELSE
        UPDATE data_sq_book1 t SET t.status = 'ST05' WHERE t.docid = v_docid;
      END IF;
    
      UPDATE data_sq_book1 t
         SET t.recvtime   = v_sysdate,
             t.dispnum    = v_dispnum,
             t.receivenum = v_receivenum,
             t.operuri    = v_operuri,
             t.opername   = v_opername,
             t.opertime   = v_sysdate
       WHERE t.docid = v_docid;
    END;
  
    COMMIT;
  
    -- 6.处理成功
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

  -- 接收拒绝申领信息
  PROCEDURE p_refuse
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_pdocid   VARCHAR2(128);
    v_reason   VARCHAR2(4000);
    v_operuri  VARCHAR2(64);
    v_opername VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_forminfo', i_forminfo);
  
    -- 解析表单数据
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(i_forminfo);
      SELECT myxml.f_getvalue(v_xml, '/info/pdocid') INTO v_pdocid FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/reason') INTO v_reason FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/operuri') INTO v_operuri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/info/opername') INTO v_opername FROM dual;
    EXCEPTION
      WHEN OTHERS THEN
        mydebug.err(7);
    END;
  
    DECLARE
      v_exists INT := 0;
    BEGIN
      SELECT COUNT(1) INTO v_exists FROM data_sq_book1 t WHERE t.docid = v_pdocid;
      IF v_exists = 0 THEN
        o_code := 'EC00';
        o_msg  := '处理成功';
        mydebug.wlog(1, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    UPDATE data_sq_book1 t
       SET t.status = 'ST04', t.reason = v_reason, t.operuri = v_operuri, t.opername = v_opername, t.opertime = SYSDATE
     WHERE t.docid = v_pdocid;
  
    COMMIT;
  
    -- 6.处理成功
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
