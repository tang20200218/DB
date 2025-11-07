CREATE OR REPLACE PACKAGE pkg_qf2_com IS

  /***************************************************************************************************
  名称     : pkg_qf2_com
  功能描述 : 入账凭证授权单位
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

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

  --修改
  PROCEDURE p_upd
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_qf2_com IS

  /***************************************************************************************************
  名称     : pkg_qf2_com.p_getlist
  功能描述 : 查询单位列表
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  入参
  {
      "beanname": "CreditedService",
      "methodname": "queryPageList",
      "i_conditions": "单位名称",
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
            "comid": "单位空间号",
            "comname": "单位名称",
            "wcnum": "已签数量",
            "wcnum2": "待签数量",
            "autoqf": "签发策略(1:自动签发 0:手动签发)"
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
  
    v_row_rn      INT;
    v_row_id      VARCHAR2(64);
    v_row_comid   VARCHAR2(64);
    v_row_comname VARCHAR2(128);
    v_row_wcnum   INT;
    v_row_wcnum2  INT;
    v_row_autoqf  INT;
    v_row         VARCHAR2(4000);
  
    v_conditions VARCHAR2(4000);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD140', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 制作sql
    v_sql := 'select id from info_register_obj E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.datatype = 1');
    v_sql := mystring.f_concat(v_sql, ' AND E1.qfflag = 1');
  
    IF mystring.f_isnotnull(v_conditions) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.objname, ''', v_conditions, ''') > 0');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY sort,id desc');
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
      
        SELECT objid, objname, autoqf INTO v_row_comid, v_row_comname, v_row_autoqf FROM info_register_obj WHERE id = v_row_id;
      
        v_row_wcnum := 0;
        SELECT COUNT(1)
          INTO v_row_wcnum
          FROM data_qf2_task t
         WHERE t.douri = v_row_comid
           AND t.sendflag = 1;
      
        v_row_wcnum2 := 0;
        SELECT COUNT(1)
          INTO v_row_wcnum2
          FROM data_qf2_task t
         WHERE t.douri = v_row_comid
           AND t.sendflag = 0;
      
        v_row := '{';
        v_row := mystring.f_concat(v_row, ' "rn":"', v_row_rn, '"');
        v_row := mystring.f_concat(v_row, ',"id":"', v_row_comid, '"');
        v_row := mystring.f_concat(v_row, ',"comid":"', v_row_comid, '"');
        v_row := mystring.f_concat(v_row, ',"comname":"', myjson.f_escape(v_row_comname), '"');
        v_row := mystring.f_concat(v_row, ',"wcnum":"', v_row_wcnum, '"');
        v_row := mystring.f_concat(v_row, ',"wcnum2":"', v_row_wcnum2, '"');
        v_row := mystring.f_concat(v_row, ',"autoqf":"', v_row_autoqf, '"');
        v_row := mystring.f_concat(v_row, '}');
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, v_row);
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
  名称     : pkg_qf2_com.p_upd
  功能描述 : 设置签发策略
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  入参
  {
      "beanname": "CreditedService",
      "methodname": "setSignProlicy",
      "id": "唯一标识",
      "autoqf": "签发策略(1:自动签发 0:手动签发)"
  }
  ***************************************************************************************************/
  PROCEDURE p_upd
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
    o_msg      OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_id     VARCHAR2(64);
    v_autoqf VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_forminfo', i_forminfo);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD140', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.id') INTO v_id FROM dual;
    SELECT json_value(i_forminfo, '$.autoqf') INTO v_autoqf FROM dual;
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_id) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE info_register_obj t SET t.autoqf = v_autoqf WHERE t.objid = v_id;
  
    IF v_autoqf = 1 THEN
      UPDATE data_qf2_task t
         SET t.startflag = 1, t.autoqf = 1
       WHERE t.douri = v_id
         AND t.startflag = 0;
    ELSE
      UPDATE data_qf2_task t
         SET t.startflag = 0, t.autoqf = 0
       WHERE t.douri = v_id
         AND t.yzflag = 0;
    END IF;
  
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
