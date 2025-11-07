CREATE OR REPLACE PACKAGE pkg_qf_book_task IS
  /***************************************************************************************************
  名称     : pkg_qf_book_task
  功能描述 : 签发办理-签发任务
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-04-07  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询列表上显示的交换状态
  FUNCTION f_getsiteinfolist(i_id VARCHAR2) RETURN VARCHAR2;

  -- 查询列表上显示的交换状态绿点
  FUNCTION f_getstatusimgstr(i_id VARCHAR2) RETURN VARCHAR2;

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

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf_book_task IS

  -- 查询列表上显示的交换状态
  FUNCTION f_getsiteinfolist(i_id VARCHAR2) RETURN VARCHAR2 AS
    v_result   VARCHAR2(4000);
    v_sendid   VARCHAR2(64);
    v_sendtype VARCHAR2(8);
    v_exchid   VARCHAR2(64);
    v_toname   VARCHAR2(128);
    v_finished INT;
  BEGIN
    SELECT sendid
      INTO v_sendid
      FROM data_qf_send_rel t
     WHERE t.taskid = i_id
       AND rownum <= 1;
  
    SELECT sendtype, exchid, toname, finished INTO v_sendtype, v_exchid, v_toname, v_finished FROM data_qf_send t WHERE t.id = v_sendid;
  
    IF v_sendtype = '1' THEN
      RETURN pkg_exch_send.f_getsiteinfolist(v_exchid);
    END IF;
  
    v_result := '[';
    v_result := mystring.f_concat(v_result, ' {"dealState":"已经处理","siteName":"', pkg_basic.f_getappname, '","status":"PS03"}');
    IF v_finished = 1 THEN
      v_result := mystring.f_concat(v_result, ',{"dealState":"已经处理","siteName":"', v_toname, '","status":"PS03"}');
    ELSE
      v_result := mystring.f_concat(v_result, ',{"dealState":"待处理","siteName":"', v_toname, '","status":"PS00"}');
    END IF;
    v_result := mystring.f_concat(v_result, ']');
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '[]';
  END;

  -- 查询列表上显示的交换状态绿点
  FUNCTION f_getstatusimgstr(i_id VARCHAR2) RETURN VARCHAR2 AS
    v_result     VARCHAR2(4000);
    v_sendid     VARCHAR2(64);
    v_sendtype   VARCHAR2(8);
    v_exchid     VARCHAR2(64);
    v_touri      VARCHAR2(64);
    v_toname     VARCHAR2(128);
    v_appid      VARCHAR2(64);
    v_appname    VARCHAR2(128);
    v_finished   INT;
    v_finishdate DATE;
    v_img        VARCHAR2(2000);
  BEGIN
    SELECT sendid
      INTO v_sendid
      FROM data_qf_send_rel t
     WHERE t.taskid = i_id
       AND rownum <= 1;
  
    SELECT sendtype, exchid, touri, toname, finished, finishdate INTO v_sendtype, v_exchid, v_touri, v_toname, v_finished, v_finishdate FROM data_qf_send t WHERE t.id = v_sendid;
  
    IF v_sendtype = '1' THEN
      RETURN pkg_exch_send.f_getstatusimgstr(v_exchid, i_id);
    END IF;
  
    v_appid   := pkg_basic.f_getappid;
    v_appname := pkg_basic.f_getappname;
    v_result  := pkg_exch_send.f_getstatusimg(1, 'PS03', '已经处理', v_appid, v_appname, NULL, i_id);
    IF v_finished = 1 THEN
      v_img := pkg_exch_send.f_getstatusimg(2, 'PS03', '已经处理', v_touri, v_toname, v_finishdate, i_id);
    ELSE
      v_img := pkg_exch_send.f_getstatusimg(2, 'PS00', '待处理', v_touri, v_toname, NULL, i_id);
    END IF;
    v_result := mystring.f_concat(v_result, v_img);
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  /***************************************************************************************************
  名称     : pkg_qf_book_task.p_getlist
  功能描述 : 查询列表-分页
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-04-07  唐金鑫  创建
  
  业务说明
  <RESPONSE>
    <ROWS>
        <ROW row_id="排序号">
            <code>业务代码</code>
            <name>业务名称</name>
            <status>是否已签发(1:是 0:否)</status>
            <qfdate>签发时间</qfdate>
            <createddate>接收时间</createddate>
        </ROW>
    </ROWS>
  </RESPONSE>
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
  
    v_row_rn           INT;
    v_row_id           VARCHAR2(64);
    v_row_code         VARCHAR2(64);
    v_row_name         VARCHAR2(128);
    v_row_status       VARCHAR2(8);
    v_row_qfdate       DATE;
    v_row_createddate  DATE;
    v_row_siteinfolist VARCHAR2(4000);
    v_row_statusimgstr VARCHAR2(4000);
  
    v_id    VARCHAR2(64);
    v_dtype VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_id') INTO v_id FROM dual;
    mydebug.wlog('v_id', v_id);
  
    BEGIN
      SELECT dtype INTO v_dtype FROM data_qf_book t WHERE t.id = v_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    -- 制作sql
    v_sql := mystring.f_concat('select createddate, id FROM data_qf_task E1 WHERE E1.pid = ''', v_id, '''');
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY createddate, id');
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
          INTO v_row_createddate, v_row_id;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT opertype, sendstatus, senddate INTO v_row_code, v_row_status, v_row_qfdate FROM data_qf_task WHERE id = v_row_id;
      
        v_row_name := NULL;
        IF v_row_code IN ('1', '2') THEN
          BEGIN
            SELECT t.name
              INTO v_row_name
              FROM info_template_qfoper t
             WHERE t.tempid = v_dtype
               AND t.pcode = v_row_code
               AND rownum <= 1;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
        ELSE
          BEGIN
            SELECT t.name
              INTO v_row_name
              FROM info_template_qfoper t
             WHERE t.tempid = v_dtype
               AND t.code = v_row_code
               AND rownum <= 1;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
        END IF;
        IF mystring.f_isnull(v_row_name) THEN
          v_row_name := v_row_code;
        END IF;
      
        v_row_siteinfolist := pkg_qf_book_task.f_getsiteinfolist(v_row_id);
        v_row_statusimgstr := pkg_qf_book_task.f_getstatusimgstr(v_row_id);
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"id":"', v_row_id, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"code":"', v_row_code, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"name":"', v_row_name, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"status":"', v_row_status, '"'));
        IF v_row_status = 1 THEN
          dbms_lob.append(o_info, ',"statusname":"已签发"');
        ELSE
          dbms_lob.append(o_info, ',"statusname":"<font color=''red''>未签发</font>"');
        END IF;
        dbms_lob.append(o_info, mystring.f_concat(',"qfdate":"', to_char(v_row_qfdate, 'yyyy-mm-dd hh24:mi:ss'), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"createddate":"', to_char(v_row_createddate, 'yyyy-mm-dd hh24:mi:ss'), '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"siteInfoList":', v_row_siteinfolist));
        dbms_lob.append(o_info, mystring.f_concat(',"statusImgStr":"', myjson.f_escape(v_row_statusimgstr), '"'));
        dbms_lob.append(o_info, ',"lastSitType":"NT01"');
        dbms_lob.append(o_info, ',"cancleSitId":""');
        dbms_lob.append(o_info, '}');
        v_row_rn := v_row_rn + 1;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        mydebug.err(7);
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
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

END;
/
