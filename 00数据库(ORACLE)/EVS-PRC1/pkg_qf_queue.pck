CREATE OR REPLACE PACKAGE pkg_qf_queue IS
  /***************************************************************************************************
  名称     : pkg_qf_queue
  功能描述 : 签发办理-后台签发
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-16  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 增加队列
  PROCEDURE p_add
  (
    i_id   IN VARCHAR2, -- 唯一标识
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 后台签发调用查询
  PROCEDURE p_getid
  (
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2, -- 成功/错误原因
    o_info OUT VARCHAR2 -- 返回结果
  );

  -- 签发信息查询
  PROCEDURE p_getinfo
  (
    i_qid  IN VARCHAR2, -- 队列标识
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2, -- 成功/错误原因
    o_info OUT CLOB, -- 查询返回的结果
    o_data OUT CLOB -- 传入ImportFlowDatas接口的数据
  );

  -- 成功
  PROCEDURE p_success
  (
    i_qid           IN VARCHAR2, -- 队列标识
    i_issuepart     IN VARCHAR2, -- 签发模式(0:发送整本凭证 1:发送增量数据)
    i_registerflag  IN VARCHAR2, -- 是否首签(1:是 0:否)
    i_file1_newname IN VARCHAR2, -- 存根文件名
    i_file2_name    IN VARCHAR2, -- 签出文件名称
    i_file2_path    IN VARCHAR2, -- 签出文件路径
    i_route         IN VARCHAR2, -- 路由信息（未有路由时为空）
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  );

  -- 队列调度失败后的处理
  PROCEDURE p_fail
  (
    i_qid     IN VARCHAR2, -- 队列标识
    i_errcode IN VARCHAR2, -- 错误代码（WEB）
    i_reason  IN VARCHAR2, -- 处理失败原因
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  );

  -- 签发文件的发送
  PROCEDURE p_set
  (
    i_qid           IN VARCHAR2, -- 队列标识
    i_flag          IN VARCHAR2, -- 处理状态 1：成功 0：失败
    i_errcode       IN VARCHAR2, -- 错误代码（WEB）
    i_reason        IN VARCHAR2, -- 处理失败原因
    i_issuepart     IN VARCHAR2, -- 签发模式(0:发送整本凭证 1:发送增量数据)
    i_registerflag  IN VARCHAR2, -- 是否首签(1:是 0:否)
    i_file1_newname IN VARCHAR2, -- 存根文件名
    i_file2_name    IN VARCHAR2, -- 签出文件名称
    i_file2_path    IN VARCHAR2, -- 签出文件路径
    i_route         IN VARCHAR2, -- 路由信息（未有路由时为空）
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf_queue IS

  -- 增加队列
  PROCEDURE p_add
  (
    i_id   IN VARCHAR2, -- 唯一标识
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT := 0;
  BEGIN
    mydebug.wlog('i_id', i_id);
  
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_qf_queue t WHERE t.id = i_id);
  
    IF v_exists = 0 THEN
      INSERT INTO data_qf_queue (id) VALUES (i_id);
    END IF;
  
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

  -- 后台签发调用查询
  PROCEDURE p_getid
  (
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2, -- 成功/错误原因
    o_info OUT VARCHAR2 -- 返回结果
  ) AS
    v_id           VARCHAR2(64);
    v_errtimes     INT;
    v_modifieddate TIMESTAMP;
    v_status       INT;
  
    v_sysdate DATE := SYSDATE;
    v_select  INT := 0;
  
    v_num INT := 0;
    v_max INT := 10;
  BEGIN
    -- o_code := 'EC00';
    -- o_msg  := '查询成功';
    -- RETURN;
  
    -- 查询队列
    v_num := 0;
    DECLARE
      CURSOR v_cursor IS
        SELECT t.id, errtimes, modifieddate, status FROM data_qf_queue t ORDER BY t.modifieddate;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_errtimes, v_modifieddate, v_status;
        EXIT WHEN v_cursor%NOTFOUND;
      
        v_select := 1;
        IF v_status > 0 THEN
          -- 已被扫描，超过2小时未处理，重新处理
          IF mydate.f_interval_second(v_sysdate, v_modifieddate) < 7200 THEN
            v_select := 0;
          END IF;
        END IF;
      
        IF v_select = 1 THEN
          IF v_errtimes > 0 THEN
            -- 错误数据，根据错误次数增加等待时间
            IF mydate.f_interval_second(v_sysdate, v_modifieddate) < v_errtimes * 60 THEN
              v_select := 0;
            END IF;
          END IF;
        END IF;
      
        -- v_select := 1;
        IF v_select = 1 THEN
          UPDATE data_qf_queue t SET t.modifieddate = systimestamp WHERE t.id = v_id;
          pkg_lock.p_lock(v_id, 'qf', 'system', '系统后台', o_code, o_msg);
          IF o_code = 'EC00' THEN
            v_num := v_num + 1;
            IF v_num = 1 THEN
              o_info := v_id;
            ELSE
              o_info := mystring.f_concat(o_info, ',', v_id);
            END IF;
            UPDATE data_qf_queue t SET t.status = 1 WHERE t.id = v_id;
            IF v_num = v_max THEN
              EXIT;
            END IF;
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
  
    IF v_num > 0 THEN
      mydebug.wlog('o_info', o_info);
    END IF;
    COMMIT;
  
    o_code := 'EC00';
    o_msg  := '查询成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_qf_queue.p_getinfo
  功能描述 : 签发信息查询
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-03-31  唐金鑫  创建
  
  业务说明
  <info>
      <qid>唯一标识</qid>
      <touri>接收者标识</touri>
      <douri>持有者标识</douri>
      <doname>持有者名称</doname>
      <routeflag>是否有路由(1:是 0:否)</routeflag>
      <webflag>是否WEB方式</webflag>
      <dtype>大类代码</dtype>
      <filename>凭证文件名</filename>
      <filepath>凭证文件路径</filepath>
      <role>签发角色，调用凭证接口SetUserRole传入凭证</role>
      <issuepart>签发模式(0:发送整本凭证 1:发送增量数据)，调用接口SetIssuePart传入凭证</issuepart>
      <issueragency>签发单位</issueragency>
      <issuername>签发人</issuername>
      <signseal>个人签名印章</signseal>
      <files>
        <file>
          <fromtype>文件来源类型(1:应用系统 2:数字空间 3:TDS 4:批量导入)</fromtype>
          <type>业务标识=flowdata里面的//flow/@type</type>
          <filename>文件名</filename>
          <filepath>文件路径</filepath>
        </file>
      </files>
      <seals>
        <!-- 印章集合-- >
        <seal>
          <label></label>
          <name></name>
          <pin></pin>
          <pack></pack>
        </seal>
      </seals>
      <forms>
        <!-- 签发数据的页面信息-- >
        <form>
          <formid>页面编号</formid>
          <formname>页面名称</formname>
          <tag>印章标签</tag>
          <label>印章标签</label>
          <type>印章类型</type>
          <desc>印章名称</desc>
        </form>
      </forms>
  </info>
  ***************************************************************************************************/
  PROCEDURE p_getinfo
  (
    i_qid  IN VARCHAR2, -- 队列标识
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2, -- 成功/错误原因
    o_info OUT CLOB, -- 查询返回的结果
    o_data OUT CLOB -- 传入ImportFlowDatas接口的数据
  ) AS
    v_task_id       VARCHAR2(64);
    v_task_pid      VARCHAR2(64);
    v_task_fromtype VARCHAR2(8);
    v_task_opertype VARCHAR2(64);
  
    v_exists INT := 0;
  
    v_info_douri      VARCHAR2(64); -- 持有者标识
    v_info_doname     VARCHAR2(128); -- 持有者名称
    v_info_routeflag  INT; -- 如果是交换则是否有路由
    v_info_dtype      VARCHAR2(64); -- 大类代码
    v_info_filename   VARCHAR2(64); -- 空白凭证文件名
    v_info_filepath   VARCHAR2(256); -- 空白凭证文件路径
    v_info_role       VARCHAR2(64); -- 签发角色，调用凭证接口SetUserRole传入凭证
    v_info_issuepart  VARCHAR2(8); -- 签发模式(0:发送整本凭证 1:发送增量数据)，调用接口SetIssuePart传入凭证
    v_info_issuername VARCHAR2(64); -- 签发人姓名
    v_info_signuri    VARCHAR2(64);
    v_info_signseal   CLOB; -- 个人签名印章
  
    v_bases_holdercode VARCHAR2(64); -- 持证者编码(个人身份证号/统一社会信用代码)
    v_bases_holdername VARCHAR2(128); -- 持证者名称(用户姓名/单位名称)
    v_bases_issuercode VARCHAR2(64); -- 签发者编码(统一社会信用代码)
    v_bases_issuername VARCHAR2(128); -- 签发者名称(单位名称)
    v_bases_xml        VARCHAR2(4000);
  BEGIN
    mydebug.wlog('i_qid', i_qid);
  
    IF mystring.f_isnull(i_qid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM data_qf_book t WHERE t.id = i_qid;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM data_qf_task t
             WHERE t.pid = i_qid
               AND t.sendstatus = 0);
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      -- mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_qf_send t WHERE t.pid = i_qid);
    IF v_exists = 0 THEN
      BEGIN
        SELECT q.id
          INTO v_task_id
          FROM (SELECT t.*
                  FROM data_qf_task t
                 WHERE t.pid = i_qid
                   AND t.sendstatus = 0
                   AND t.opertype = '1'
                 ORDER BY t.createddate, t.id) q
         WHERE rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      IF mystring.f_isnull(v_task_id) THEN
        o_code := 'EC02';
        o_msg  := '没有首签,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    ELSE
      BEGIN
        SELECT q.id
          INTO v_task_id
          FROM (SELECT t.*
                  FROM data_qf_task t
                 WHERE t.pid = i_qid
                   AND t.sendstatus = 0
                 ORDER BY t.createddate, t.id) q
         WHERE rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
    IF mystring.f_isnull(v_task_id) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      -- mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT dtype INTO v_info_dtype FROM data_qf_book t WHERE t.id = i_qid;
  
    -- 使用1张空白凭证
    pkg_qf_pbl.p_usepz(i_qid, v_info_dtype, o_code, o_msg, v_info_filename, v_info_filepath);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT pid, fromtype, opertype INTO v_task_pid, v_task_fromtype, v_task_opertype FROM data_qf_task t WHERE t.id = v_task_id;
    DELETE FROM data_qf_task_tmp WHERE pid = i_qid;
    INSERT INTO data_qf_task_tmp (id, pid) VALUES (v_task_id, v_task_pid);
  
    -- 首签基础参数
    SELECT docode, doname INTO v_bases_holdercode, v_bases_holdername FROM data_qf_book t WHERE t.id = i_qid;
    BEGIN
      SELECT sqdcode, sqdnm INTO v_bases_issuercode, v_bases_issuername FROM info_template_bind t WHERE t.id = v_info_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_bases_xml := '<bases>';
    v_bases_xml := mystring.f_concat(v_bases_xml, '<item tag="HolderCode"><value>', v_bases_holdercode, '</value></item>');
    v_bases_xml := mystring.f_concat(v_bases_xml, '<item tag="HolderName"><value>', v_bases_holdername, '</value></item>');
    v_bases_xml := mystring.f_concat(v_bases_xml, '<item tag="IssuerCode"><value>', v_bases_issuercode, '</value></item>');
    v_bases_xml := mystring.f_concat(v_bases_xml, '<item tag="IssuerName"><value>', v_bases_issuername, '</value></item>');
    v_bases_xml := mystring.f_concat(v_bases_xml, '</bases>');
  
    -- 签发模式(0:发送整本凭证 1:发送增量数据)，调用接口SetIssuePart传入凭证
    v_info_issuepart := pkg_qf_config.f_getissuepart(v_info_dtype);
  
    -- 签发人签名信息
    SELECT operuri, opername INTO v_info_signuri, v_info_issuername FROM data_qf_book t WHERE t.id = i_qid;
    IF mystring.f_isnull(v_info_signuri) OR v_info_signuri = 'system' THEN
      BEGIN
        SELECT q.adminuri, q.adminname
          INTO v_info_signuri, v_info_issuername
          FROM (SELECT t2.adminuri, t2.adminname
                  FROM info_admin_auth_kind t1
                 INNER JOIN info_admin t2
                    ON (t2.adminuri = t1.useruri AND t2.admintype = 'MT06')
                 WHERE t1.dtype = v_info_dtype
                 ORDER BY t2.sort, t2.adminuri) q
         WHERE rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
    v_info_signseal := pkg_info_admin6.f_getseal(v_info_signuri);
  
    SELECT douri, doname INTO v_info_douri, v_info_doname FROM data_qf_book t WHERE t.id = i_qid;
    v_info_routeflag := pkg_exch_to_site.f_check(v_info_douri);
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '<info>');
    dbms_lob.append(o_info, mystring.f_concat('<qid>', i_qid, '</qid>'));
    dbms_lob.append(o_info, mystring.f_concat('<touri>', v_info_douri, '</touri>'));
    dbms_lob.append(o_info, mystring.f_concat('<douri>', v_info_douri, '</douri>'));
    dbms_lob.append(o_info, mystring.f_concat('<doname>', v_info_doname, '</doname>'));
    dbms_lob.append(o_info, mystring.f_concat('<routeflag>', v_info_routeflag, '</routeflag>'));
    dbms_lob.append(o_info, '<webflag>0</webflag>');
    dbms_lob.append(o_info, mystring.f_concat('<dtype>', v_info_dtype, '</dtype>'));
    dbms_lob.append(o_info, mystring.f_concat('<filename>', v_info_filename, '</filename>'));
    dbms_lob.append(o_info, mystring.f_concat('<filepath>', v_info_filepath, '</filepath>'));
    dbms_lob.append(o_info, mystring.f_concat('<role>', v_info_role, '</role>'));
    dbms_lob.append(o_info, mystring.f_concat('<issuepart>', v_info_issuepart, '</issuepart>'));
    dbms_lob.append(o_info, mystring.f_concat('<issueragency>', v_bases_issuername, '</issueragency>'));
    dbms_lob.append(o_info, mystring.f_concat('<issuername>', v_info_issuername, '</issuername>'));
    dbms_lob.append(o_info, '<signseal>');
    IF mystring.f_isnotnull(v_info_signseal) THEN
      dbms_lob.append(o_info, v_info_signseal);
    END IF;
    dbms_lob.append(o_info, '</signseal>');
    dbms_lob.append(o_info, '<files>');
  
    DECLARE
      v_fileid VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t.fileid FROM data_qf_task_file t WHERE t.pid = v_task_id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_fileid;
        EXIT WHEN v_cursor%NOTFOUND;
        dbms_lob.append(o_info, '<file>');
        dbms_lob.append(o_info, mystring.f_concat('<fromtype>', v_task_fromtype, '</fromtype>'));
        dbms_lob.append(o_info, mystring.f_concat('<type>', v_task_opertype, '</type>'));
        dbms_lob.append(o_info, mystring.f_concat('<filename>', pkg_file0.f_getfilename(v_fileid), '</filename>'));
        dbms_lob.append(o_info, mystring.f_concat('<filepath>', pkg_file0.f_getfilepath(v_fileid), '</filepath>'));
        dbms_lob.append(o_info, '</file>');
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
  
    dbms_lob.append(o_info, '</files>');
    dbms_lob.append(o_info, '<seals>');
  
    DECLARE
      v_code     VARCHAR2(64);
      v_name     VARCHAR2(128);
      v_sealpin  VARCHAR2(64);
      v_sealpack CLOB;
      CURSOR v_cursor IS
        SELECT t.code, t.name, t.sealpin, t.sealpack
          FROM info_template_seal t
         WHERE t.tempid = v_info_dtype
           AND t.sealtype = 'issue';
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_code, v_name, v_sealpin, v_sealpack;
        EXIT WHEN v_cursor%NOTFOUND;
        dbms_lob.append(o_info, '<seal>');
        dbms_lob.append(o_info, mystring.f_concat('<label>', v_code, '</label>'));
        dbms_lob.append(o_info, mystring.f_concat('<name>', v_name, '</name>'));
        dbms_lob.append(o_info, mystring.f_concat('<pin>', v_sealpin, '</pin>'));
        dbms_lob.append(o_info, '<pack>');
        IF mystring.f_isnotnull(v_sealpack) THEN
          dbms_lob.append(o_info, v_sealpack);
        END IF;
        dbms_lob.append(o_info, '</pack>');
        dbms_lob.append(o_info, '</seal>');
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
  
    dbms_lob.append(o_info, '</seals>');
    dbms_lob.append(o_info, '<forms>');
  
    DECLARE
      v_name0    VARCHAR2(128);
      v_formid   VARCHAR2(64);
      v_sealtype VARCHAR2(8);
      v_tag      VARCHAR2(64);
      v_label    VARCHAR2(64);
      v_desc     VARCHAR2(128);
      CURSOR v_cursor IS
        SELECT t1.name0, t2.formid, t2.tag, t2.label, t2.sealtype, t2.desc_
          FROM info_template_qfoper t1
         INNER JOIN info_template_seal_rel t2
            ON (t2.tempid = v_info_dtype AND t2.formid = t1.form)
         WHERE t1.tempid = v_info_dtype
           AND (t1.code = v_task_opertype OR t1.pcode = v_task_opertype)
         ORDER BY t1.sort, t2.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_name0, v_formid, v_tag, v_label, v_sealtype, v_desc;
        EXIT WHEN v_cursor%NOTFOUND;
        dbms_lob.append(o_info, '<form>');
        dbms_lob.append(o_info, mystring.f_concat('<formid>', v_formid, '</formid>'));
        dbms_lob.append(o_info, mystring.f_concat('<formname>', v_name0, '</formname>'));
        dbms_lob.append(o_info, mystring.f_concat('<tag>', v_tag, '</tag>'));
        dbms_lob.append(o_info, mystring.f_concat('<label>', v_label, '</label>'));
        dbms_lob.append(o_info, mystring.f_concat('<type>', v_sealtype, '</type>'));
        dbms_lob.append(o_info, mystring.f_concat('<desc>', v_desc, '</desc>'));
        dbms_lob.append(o_info, '</form>');
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
  
    dbms_lob.append(o_info, '</forms>');
    dbms_lob.append(o_info, '</info>');
    mydebug.wlog('o_info', o_info);
  
    DECLARE
      v_items     CLOB;
      v_flow_name VARCHAR2(200);
      v_flow_v    VARCHAR2(32767);
    BEGIN
      BEGIN
        SELECT items INTO v_items FROM data_qf_task_data t WHERE t.id = v_task_id;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      v_flow_name := pkg_info_template_pbl.f_getqfopername(v_info_dtype, v_task_opertype);
      v_flow_v    := myxml.f_getnode_str(v_items, '/template/*');
    
      dbms_lob.createtemporary(o_data, TRUE);
      dbms_lob.append(o_data, '<datas>');
      IF mystring.f_isnotnull(v_task_id) THEN
        dbms_lob.append(o_data, '<flow');
        dbms_lob.append(o_data, mystring.f_concat(' type = "', v_task_opertype, '"'));
        dbms_lob.append(o_data, mystring.f_concat(' name = "', v_flow_name, '"'));
        IF v_task_opertype = '1' THEN
          dbms_lob.append(o_data, ' flag = "1"');
        END IF;
        dbms_lob.append(o_data, ' >');
        IF v_task_opertype = '1' THEN
          dbms_lob.append(o_data, v_bases_xml);
        END IF;
        IF mystring.f_isnotnull(v_flow_v) THEN
          dbms_lob.append(o_data, v_flow_v);
        END IF;
        dbms_lob.append(o_data, '</flow>');
      END IF;
      dbms_lob.append(o_data, '</datas>');
    END;
  
    mydebug.wlog('o_data', o_data);
  
    COMMIT;
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_info := NULL;
      o_data := NULL;
      o_code := 'EC08';
      o_msg  := '数据处理异常';
      mydebug.err(7);
  END;

  -- 成功
  PROCEDURE p_success
  (
    i_qid           IN VARCHAR2, -- 队列标识
    i_issuepart     IN VARCHAR2, -- 签发模式(0:发送整本凭证 1:发送增量数据)
    i_registerflag  IN VARCHAR2, -- 是否首签(1:是 0:否)
    i_file1_newname IN VARCHAR2, -- 存根文件名
    i_file2_name    IN VARCHAR2, -- 签出文件名称
    i_file2_path    IN VARCHAR2, -- 签出文件路径
    i_route         IN VARCHAR2, -- 路由信息（未有路由时为空）
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT := 0;
  BEGIN
    mydebug.wlog('i_qid', i_qid);
  
    IF mystring.f_isnull(i_qid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM data_qf_queue WHERE id = i_qid;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 发送
    pkg_qf_book_send.p_send_pbl(i_qid, i_issuepart, i_registerflag, i_file1_newname, i_file2_name, i_file2_path, '0', '', '', i_route, 'system', 'system', o_code, o_msg);
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM data_qf_task t
             WHERE t.pid = i_qid
               AND t.sendstatus = 0);
    IF v_exists = 0 THEN
      DELETE FROM data_qf_queue WHERE id = i_qid;
    ELSE
      UPDATE data_qf_queue t SET t.status = 0, t.errcode = '', t.errinfo = '', t.modifieddate = systimestamp WHERE t.id = i_qid;
      IF o_code = 'EC00' THEN
        UPDATE data_qf_queue t SET t.errtimes = 0 WHERE t.id = i_qid;
      ELSE
        UPDATE data_qf_queue t SET t.errtimes = t.errtimes + 1, t.errcode = o_code, t.errinfo = o_msg WHERE t.id = i_qid;
      END IF;
    END IF;
  
    COMMIT;
    IF mystring.f_isnull(o_code) THEN
      o_code := 'EC00';
      o_msg  := '处理成功。';
    END IF;
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 队列调度失败后的处理
  PROCEDURE p_fail
  (
    i_qid     IN VARCHAR2, -- 队列标识
    i_errcode IN VARCHAR2, -- 错误代码（WEB）
    i_reason  IN VARCHAR2, -- 处理失败原因
    o_code    OUT VARCHAR2, -- 操作结果:错误码
    o_msg     OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_qid', i_qid);
    mydebug.wlog('i_errcode', i_errcode);
    mydebug.wlog('i_reason', i_reason);
  
    IF mystring.f_isnull(i_qid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 设置失败
    UPDATE data_qf_queue t SET t.status = 0, t.errtimes = t.errtimes + 1, t.errcode = i_errcode, t.errinfo = i_reason, t.modifieddate = systimestamp WHERE t.id = i_qid;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 队列调度成功后的处理
  PROCEDURE p_set
  (
    i_qid           IN VARCHAR2, -- 队列标识
    i_flag          IN VARCHAR2, -- 处理状态 1：成功 0：失败
    i_errcode       IN VARCHAR2, -- 错误代码（WEB）
    i_reason        IN VARCHAR2, -- 处理失败原因
    i_issuepart     IN VARCHAR2, -- 签发模式(0:发送整本凭证 1:发送增量数据)
    i_registerflag  IN VARCHAR2, -- 是否首签(1:是 0:否)
    i_file1_newname IN VARCHAR2, -- 存根文件名
    i_file2_name    IN VARCHAR2, -- 签出文件名称
    i_file2_path    IN VARCHAR2, -- 签出文件路径
    i_route         IN VARCHAR2, -- 路由信息（未有路由时为空）
    o_code          OUT VARCHAR2, -- 操作结果:错误码
    o_msg           OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_qid', i_qid);
    mydebug.wlog('i_flag', i_flag);
  
    IF mystring.f_isnull(i_flag) THEN
      o_code := 'EC02';
      o_msg  := '处理状态为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_qid) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    -- 设置失败
    IF i_flag = '0' THEN
      pkg_qf_queue.p_fail(i_qid, i_errcode, i_reason, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    ELSE
      pkg_qf_queue.p_success(i_qid, i_issuepart, i_registerflag, i_file1_newname, i_file2_name, i_file2_path, i_route, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    DELETE FROM data_lock WHERE docid = i_qid;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
