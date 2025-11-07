CREATE OR REPLACE PACKAGE pkg_qf2_task IS

  /***************************************************************************************************
  名称     : pkg_qf2_task
  功能描述 : 入账凭证签发办理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询凭证类型
  PROCEDURE p_gettype
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询文件信息
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除单个记录
  PROCEDURE p_del_single
  (
    i_id   IN VARCHAR2, -- 唯一标识
    o_code OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg  OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 删除
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 确认签发单个记录
  PROCEDURE p_confirm_single
  (
    i_id       IN VARCHAR2, -- 唯一标识
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 确认签发
  PROCEDURE p_confirm
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 拒绝签发单个记录
  PROCEDURE p_refuse_single
  (
    i_id       IN VARCHAR2, -- 唯一标识
    i_reason   IN VARCHAR2, -- 拒绝原因
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 拒绝签发
  PROCEDURE p_refuse
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf2_task IS

  /***************************************************************************************************
  名称     : pkg_qf2_task.p_gettype
  功能描述 : 查询凭证类型
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-11  唐金鑫  创建
  
  业务说明
  入参
  {
      "beanname": "CreditedService",
      "methodname": "loadTypeList",
      "comid": "单位标识"
  }
  
  出参  
  {
    "dataList": [
        {
            "id": "",
            "name": "",
            "c1": "待签数量"
        }
    ],
    "code": "EC00",
    "msg": "处理成功"
  }
  ***************************************************************************************************/
  PROCEDURE p_gettype
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_comid    VARCHAR2(64);
    v_num      INT := 0;
    v_tempid   VARCHAR2(64);
    v_tempname VARCHAR2(200);
    v_c1       INT := 0;
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD140', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.comid') INTO v_comid FROM dual;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"dataList":[');
    DECLARE
      CURSOR v_cursor IS
        SELECT t.tempid, t.tempname
          FROM info_template t
         WHERE t.bindstatus = 1
           AND t.enable = 1
         ORDER BY t.sort, t.tempid;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_tempid, v_tempname;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT COUNT(1)
          INTO v_c1
          FROM data_qf2_task t
         WHERE t.douri = v_comid
           AND t.dtype = v_tempid
           AND t.sendflag = 0;
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, '{');
        o_info := mystring.f_concat(o_info, ' "id":"', v_tempid, '"');
        o_info := mystring.f_concat(o_info, ',"name":"', v_tempname, '"');
        o_info := mystring.f_concat(o_info, ',"c1":"', v_c1, '"');
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

  /***************************************************************************************************
  名称     : pkg_qf2_task.p_getlist
  功能描述 : 查询列表
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  入参
  {
      "beanname": "CreditedService",
      "methodname": "queryProofPageList",
      "comid": "单位标识",
      "dtype": "凭证类型",
      "i_conditions": "<condition>
                         <others>
                           <title>标题</title>
                           <status>签发状态(0:待签发 1:已签发 2:在签发)</status>
                           <modifieddate1>起始时间</modifieddate1>
                           <modifieddate2>终止时间</modifieddate2>
                         </others>
                       </condition>",
      "currPage": "1",
      "perPageCount": "19"
  }
  
  出参  
  {
    "pageNation": {},
    "dataList": [
        {
            "rn": "1",
            "id": "",
            "title": "标题",
            "status": "签发状态(0:待签发 1:已签发 2:在签发)",
            "siteInfoList": "交换状态",
            "statusImgStr": "交换状态",
            "fromopername": "申请人",
            "fromdate": "申请时间",
            "filename2": "封面文件名",
            "filepath2": "封面文件路径",
            "opername": "签发人",
            "operdate": "签发时间",
        }
    ],
    "code": "EC00",
    "msg": "处理成功"
  }
  ***************************************************************************************************/
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码  
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_comid VARCHAR2(64);
    v_dtype VARCHAR2(64);
  
    v_row_rn           INT;
    v_row_id           VARCHAR2(64);
    v_row_title        VARCHAR2(200);
    v_row_status       INT;
    v_row_startflag    INT;
    v_row_sendflag     INT;
    v_row_sendid       VARCHAR2(64);
    v_row_siteinfolist VARCHAR2(4000);
    v_row_statusimgstr VARCHAR2(4000);
    v_row_fromopername VARCHAR2(128);
    v_row_fromdate     DATE;
    v_row_opername     VARCHAR2(128);
    v_row_operdate     DATE;
    v_row_filename2    VARCHAR2(128);
    v_row_filepath2    VARCHAR2(256);
  
    v_conditions       VARCHAR2(4000);
    v_cs_title         VARCHAR2(200);
    v_cs_status        VARCHAR2(8);
    v_cs_modifieddate1 VARCHAR2(32);
    v_cs_modifieddate2 VARCHAR2(32);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD140', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.comid') INTO v_comid FROM dual;
    SELECT json_value(i_forminfo, '$.dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/condition/others/title') INTO v_cs_title FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/status') INTO v_cs_status FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/modifieddate1') INTO v_cs_modifieddate1 FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/modifieddate2') INTO v_cs_modifieddate2 FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select id from data_qf2_task E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.douri = ''' || v_comid || '''');
    IF v_dtype IS NOT NULL THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.dtype = ''' || v_dtype || '''');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_title) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.title, ''', v_cs_title, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_status) THEN
      IF v_cs_status = '1' THEN
        v_sql := mystring.f_concat(v_sql, ' AND E1.sendflag = 1');
      ELSIF v_cs_status = '2' THEN
        v_sql := mystring.f_concat(v_sql, ' AND E1.startflag = 1 AND E1.sendflag = 0');
      ELSE
        v_sql := mystring.f_concat(v_sql, ' AND E1.startflag = 0');
      END IF;
    END IF;
  
    IF mystring.f_isnotnull(v_cs_modifieddate1) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.fromdate >= to_date(''', v_cs_modifieddate1, ''', ''yyyy-mm-dd'')');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_modifieddate2) THEN
      v_cs_modifieddate2 := mydate.f_addday_str(v_cs_modifieddate2, 1);
    
      v_sql := mystring.f_concat(v_sql, ' AND E1.fromdate < to_date(''', v_cs_modifieddate2, ''', ''yyyy-mm-dd'')');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY fromdate desc,id desc');
    v_sql := myquery.f_getpagesql(v_sql, v_pagesize, v_pagenum);
    mydebug.wlog('v_sql', v_sql);
  
    -- 分页起始编号
    v_row_rn := myquery.f_getpagestartnum(v_pagesize, v_pagenum);
  
    -- 执行sql
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, myquery.f_getpagenation(v_cnt, v_pagesize, v_pagenum));
    dbms_lob.append(o_info, ',"dataList":[');
  
    DECLARE
      v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果  
    BEGIN
      OPEN v_cursor FOR v_sql;
      LOOP
        FETCH v_cursor
          INTO v_row_id;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT title, startflag, sendflag, sendid, fromopername, fromdate, opername, senddate
          INTO v_row_title, v_row_startflag, v_row_sendflag, v_row_sendid, v_row_fromopername, v_row_fromdate, v_row_opername, v_row_operdate
          FROM data_qf2_task
         WHERE id = v_row_id;
      
        v_row_status := 0;
        IF v_row_startflag = 1 THEN
          v_row_status := 2;
        END IF;
        IF v_row_sendflag = 1 THEN
          v_row_status := 1;
        END IF;
      
        v_row_siteinfolist := pkg_exch_send.f_getsiteinfolist(v_row_sendid);
        v_row_statusimgstr := pkg_exch_send.f_getstatusimgstr(v_row_sendid, v_row_id);
      
        v_row_filename2 := pkg_file0.f_getfilename_docid(v_row_id, 0);
        v_row_filepath2 := pkg_file0.f_getfilepath_docid(v_row_id, 0);
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
      
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"id":"', v_row_id, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"title":"', myjson.f_escape(v_row_title), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"status":"', v_row_status, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"siteInfoList":', v_row_siteinfolist));
        dbms_lob.append(o_info, mystring.f_concat(',"statusImgStr":"', myjson.f_escape(v_row_statusimgstr), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"fromopername":"', v_row_fromopername, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"fromdate":"', to_char(v_row_fromdate, 'yyyy-mm-dd hh24:mi'), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"opername":"', v_row_opername, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"operdate":"', to_char(v_row_operdate, 'yyyy-mm-dd hh24:mi'), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"filename2":"', v_row_filename2, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"filepath2":"', v_row_filepath2, '"'));
        dbms_lob.append(o_info, '}');
        v_row_rn := v_row_rn + 1;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
    END;
    dbms_lob.append(o_info, ']');
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
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_qf2_task.p_getinfo
  功能描述 : 查询文件信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  入参
  {
      "beanname": "CreditedService",
      "methodname": "getProofOpenData",
      "id": "唯一标识"
  }
  
  出参  
  {  
    "title": "标题",
    "filename": "凭证文件名",
    "filepath": "凭证文件路径",
    "printedparam": "申请信息xml",
    "code": "EC00",
    "msg": "处理成功"
  }
  ***************************************************************************************************/
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists           INT := 0;
    v_id               VARCHAR2(64);
    v_title            VARCHAR2(200);
    v_filename         VARCHAR2(128);
    v_filepath         VARCHAR2(256);
    v_filename2        VARCHAR2(128);
    v_filepath2        VARCHAR2(256);
    v_printedparam     CLOB;
    v_printedparam_str VARCHAR2(32767);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD140', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.id') INTO v_id FROM dual;
  
    IF mystring.f_isnull(v_id) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM data_qf2_applyinfo t WHERE t.id = v_id;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT t.title, t.printedparam INTO v_title, v_printedparam FROM data_qf2_applyinfo t WHERE t.id = v_id;
  
    v_printedparam_str := mystring.f_clob2char(v_printedparam);
  
    v_filename  := pkg_file0.f_getfilename_docid(v_id, 2);
    v_filepath  := pkg_file0.f_getfilepath_docid(v_id, 2);
    v_filename2 := pkg_file0.f_getfilename_docid(v_id, 0);
    v_filepath2 := pkg_file0.f_getfilepath_docid(v_id, 0);
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, '{');
    dbms_lob.append(o_info, mystring.f_concat(' "title":"', myjson.f_escape(v_title), '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"filename":"', v_filename, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"filepath":"', v_filepath, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"filename2":"', v_filename2, '"'));
    dbms_lob.append(o_info, mystring.f_concat(',"filepath2":"', v_filepath2, '"'));
    dbms_lob.append(o_info, ',"printedparam":"');
    IF mystring.f_isnotnull(v_printedparam_str) THEN
      dbms_lob.append(o_info, myjson.f_escape(v_printedparam_str));
    END IF;
    dbms_lob.append(o_info, '"');
    dbms_lob.append(o_info, mystring.f_concat(',"code":"EC00"'));
    dbms_lob.append(o_info, mystring.f_concat(',"msg":"处理成功"'));
    dbms_lob.append(o_info, mystring.f_concat('}'));
  
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

  /***************************************************************************************************
  名称     : pkg_info_template_com2.p_del_single
  功能描述 : 删除单个记录
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_del_single
  (
    i_id   IN VARCHAR2, -- 唯一标识
    o_code OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg  OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_exists INT := 0;
  BEGIN
    mydebug.wlog('i_id', i_id);
  
    SELECT COUNT(1) INTO v_exists FROM data_qf2_task t WHERE t.id = i_id;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    pkg_file0.p_del_docid(i_id, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    DELETE FROM data_qf2_task WHERE id = i_id;
    DELETE FROM data_qf2_applyinfo WHERE id = i_id;
  
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
  名称     : pkg_qf2_task.p_del
  功能描述 : 删除
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  入参
  {
      "beanname": "CreditedService",
      "methodname": "deleteProof",
      "id": "唯一标识"
  }
  ***************************************************************************************************/
  PROCEDURE p_del
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_ids       VARCHAR2(4000);
    v_ids_count INT := 0;
    v_id        VARCHAR2(64);
    v_i         INT := 0;
    v_code      VARCHAR2(200);
    v_msg       VARCHAR2(2000);
    v_num       INT := 0;
  BEGIN
    mydebug.wlog('i_forminfo', i_forminfo);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD140', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.id') INTO v_ids FROM dual;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_ids) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_ids_count := myarray.f_getcount(v_ids, ',');
    IF v_ids_count = 0 THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    o_info := '{"code":"EC00","msg":"处理成功","errors":[';
  
    v_i := 1;
    WHILE v_i <= v_ids_count LOOP
      v_id := myarray.f_getvalue(v_ids, ',', v_i);
      pkg_qf2_task.p_del_single(v_id, v_code, v_msg);
      IF v_code <> 'EC00' THEN
        v_num := v_num + 1;
        IF v_num > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, '{');
        o_info := mystring.f_concat(o_info, ' "id":"', v_id, '"');
        o_info := mystring.f_concat(o_info, ',"msg":"', myjson.f_escape(v_msg), '"');
        o_info := mystring.f_concat(o_info, '}');
      END IF;
      v_i := v_i + 1;
    END LOOP;
    o_info := mystring.f_concat(o_info, ']}');
  
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
  名称     : pkg_info_template_com2.p_confirm_single
  功能描述 : 确认签发单个记录
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_confirm_single
  (
    i_id       IN VARCHAR2, -- 唯一标识
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_exists INT := 0;
  BEGIN
    mydebug.wlog('i_id', i_id);
  
    SELECT COUNT(1) INTO v_exists FROM data_qf2_task t WHERE t.id = i_id;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE data_qf2_task t SET t.startflag = 1, t.modifieddate = SYSDATE, t.operuri = i_operuri, t.opername = i_opername WHERE t.id = i_id;
  
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
  名称     : pkg_qf2_task.p_confirm
  功能描述 : 确认签发
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  入参
  {
      "beanname": "CreditedService",
      "methodname": "confirmSignProof",
      "id": "唯一标识"
  }
  ***************************************************************************************************/
  PROCEDURE p_confirm
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_ids       VARCHAR2(4000);
    v_ids_count INT := 0;
    v_id        VARCHAR2(64);
    v_i         INT := 0;
    v_code      VARCHAR2(200);
    v_msg       VARCHAR2(2000);
    v_num       INT := 0;
  BEGIN
    mydebug.wlog('i_forminfo', i_forminfo);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD140', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.id') INTO v_ids FROM dual;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_ids) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_ids_count := myarray.f_getcount(v_ids, ',');
    IF v_ids_count = 0 THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    o_info := '{"code":"EC00","msg":"处理成功","errors":[';
  
    v_i := 1;
    WHILE v_i <= v_ids_count LOOP
      v_id := myarray.f_getvalue(v_ids, ',', v_i);
      pkg_qf2_task.p_confirm_single(v_id, i_operuri, i_opername, v_code, v_msg);
      IF v_code <> 'EC00' THEN
        v_num := v_num + 1;
        IF v_num > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, '{');
        o_info := mystring.f_concat(o_info, ' "id":"', v_id, '"');
        o_info := mystring.f_concat(o_info, ',"msg":"', myjson.f_escape(v_msg), '"');
        o_info := mystring.f_concat(o_info, '}');
      END IF;
      v_i := v_i + 1;
    END LOOP;
    o_info := mystring.f_concat(o_info, ']}');
  
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
  名称     : pkg_info_template_com2.p_refuse_single
  功能描述 : 拒绝签发单个记录
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_refuse_single
  (
    i_id       IN VARCHAR2, -- 唯一标识
    i_reason   IN VARCHAR2, -- 拒绝原因
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_exists INT := 0;
  
    v_fromuri VARCHAR2(64);
    v_fromid  VARCHAR2(64);
    v_form    VARCHAR2(4000);
  BEGIN
    mydebug.wlog('i_id', i_id);
  
    SELECT COUNT(1) INTO v_exists FROM data_qf2_applyinfo t WHERE t.id = i_id;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      SELECT fromuri, fromid INTO v_fromuri, v_fromid FROM data_qf2_applyinfo t WHERE t.id = i_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    -- 组织表单数据
    v_form := '<info>';
    v_form := mystring.f_concat(v_form, '<datatype>GG12</datatype>');
    v_form := mystring.f_concat(v_form, '<datatime>', to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'), '</datatime>');
    v_form := mystring.f_concat(v_form, '<pdocid>', v_fromid, '</pdocid>');
    v_form := mystring.f_concat(v_form, '<reason>', i_reason, '</reason>');
    v_form := mystring.f_concat(v_form, '<operuri>', i_operuri, '</operuri>');
    v_form := mystring.f_concat(v_form, '<opername>', i_opername, '</opername>');
    v_form := mystring.f_concat(v_form, '</info>');
  
    -- 发送
    pkg_exch_send.p_send1_1('拒绝签发退回给数字空间', v_form, NULL, v_fromuri, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    pkg_file0.p_del_docid(i_id, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    DELETE FROM data_qf2_task WHERE id = i_id;
    DELETE FROM data_qf2_applyinfo WHERE id = i_id;
  
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
  名称     : pkg_qf2_task.p_refuse
  功能描述 : 拒绝签发
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  入参
  {
      "beanname": "CreditedService",
      "methodname": "refuseSignProof",
      "id": "唯一标识",
      "reason": "拒绝原因",
      
  }
  ***************************************************************************************************/
  PROCEDURE p_refuse
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_reason    VARCHAR2(2000);
    v_ids       VARCHAR2(4000);
    v_ids_count INT := 0;
    v_id        VARCHAR2(64);
    v_i         INT := 0;
    v_code      VARCHAR2(200);
    v_msg       VARCHAR2(2000);
    v_num       INT := 0;
  BEGIN
    mydebug.wlog('i_forminfo', i_forminfo);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD140', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.id') INTO v_ids FROM dual;
    SELECT json_value(i_forminfo, '$.reason') INTO v_reason FROM dual;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_ids) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_ids_count := myarray.f_getcount(v_ids, ',');
    IF v_ids_count = 0 THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    o_info := '{"code":"EC00","msg":"处理成功","errors":[';
  
    v_i := 1;
    WHILE v_i <= v_ids_count LOOP
      v_id := myarray.f_getvalue(v_ids, ',', v_i);
      pkg_qf2_task.p_refuse_single(v_id, v_reason, i_operuri, i_opername, v_code, v_msg);
      IF v_code <> 'EC00' THEN
        v_num := v_num + 1;
        IF v_num > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info := mystring.f_concat(o_info, '{');
        o_info := mystring.f_concat(o_info, ' "id":"', v_id, '"');
        o_info := mystring.f_concat(o_info, ',"msg":"', myjson.f_escape(v_msg), '"');
        o_info := mystring.f_concat(o_info, '}');
      END IF;
      v_i := v_i + 1;
    END LOOP;
    o_info := mystring.f_concat(o_info, ']}');
  
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
