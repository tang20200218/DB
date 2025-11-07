CREATE OR REPLACE PACKAGE pkg_info_org2 IS

  /***************************************************************************************************
  名称     : pkg_info_org2
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

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_org2 IS

  /***************************************************************************************************
  名称     : pkg_info_org2.p_getlist
  功能描述 : 查询列表
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-12-05  唐金鑫  创建
  
  业务说明
  入参
  {
      "beanname": "mixtureServiceImpl",
      "methodname": "queryAuthDeptPageList",
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
            "sort": "排序号",
            "operdate": "接收时间"
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
  
    v_row_rn       INT;
    v_row_id       VARCHAR2(64);
    v_row_comid    VARCHAR2(64);
    v_row_comname  VARCHAR2(128);
    v_row_sort     INT;
    v_row_operdate DATE;
    v_row          VARCHAR2(4000);
  
    v_conditions VARCHAR2(4000);
  BEGIN
    mydebug.wlog('开始');
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD919', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 制作sql
    v_sql := 'select id from info_register_obj E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.datatype = 1');
  
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
      
        SELECT objid, objname, sort, createddate INTO v_row_comid, v_row_comname, v_row_sort, v_row_operdate FROM info_register_obj WHERE id = v_row_id;
      
        v_row := '{';
        v_row := mystring.f_concat(v_row, ' "rn":"', v_row_rn, '"');
        v_row := mystring.f_concat(v_row, ',"id":"', v_row_id, '"');
        v_row := mystring.f_concat(v_row, ',"comid":"', v_row_comid, '"');
        v_row := mystring.f_concat(v_row, ',"comname":"', myjson.f_escape(v_row_comname), '"');
        v_row := mystring.f_concat(v_row, ',"sort":"', v_row_sort, '"');
        v_row := mystring.f_concat(v_row, ',"operdate":"', to_char(v_row_operdate, 'yyyy-mm-dd hh24:mi'), '"');
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

END;
/
