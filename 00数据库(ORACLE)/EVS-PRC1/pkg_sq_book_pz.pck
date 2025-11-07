CREATE OR REPLACE PACKAGE pkg_sq_book_pz IS

  /***************************************************************************************************
  名称     : pkg_sq_book_pz
  功能描述 : 空白凭证申领-申领办理-查看收到的凭证信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-28  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查看收到的凭证信息-列表(分页)
  PROCEDURE p_getlist
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
CREATE OR REPLACE PACKAGE BODY pkg_sq_book_pz IS

  -- 查看收到的凭证信息-列表(分页)
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码  
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_row_rn    INT;
    v_row_id    VARCHAR2(64);
    v_row_evnum VARCHAR2(64);
  
    v_docid VARCHAR2(64);
  BEGIN
    mydebug.wlog('开始');

    -- 验证用户权限
    pkg_qp_verify.p_check('MD130', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_docid') INTO v_docid FROM dual;
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
  
    -- 制作sql
    v_sql := 'select num_start, id from data_sq_apply_pz E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.docid = ''', v_docid, '''');
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY num_start');
    v_sql := myquery.f_getpagesql(v_sql, v_pagesize, v_pagenum);
    mydebug.wlog('v_sql', v_sql);
  
    -- 分页起始编号
    v_row_rn := myquery.f_getpagestartnum(v_pagesize, v_pagenum);
  
    -- 执行sql
    o_info := '{';
    o_info := mystring.f_concat(o_info, myquery.f_getpagenation(v_cnt, v_pagesize, v_pagenum));
    o_info := mystring.f_concat(o_info, ',"dataList":[');
    DECLARE
      v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果
    BEGIN
      OPEN v_cursor FOR v_sql;
      LOOP
        FETCH v_cursor
          INTO v_row_evnum, v_row_id;
        EXIT WHEN v_cursor%NOTFOUND;    
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          o_info := mystring.f_concat(o_info, ',');
        END IF;
        o_info   := mystring.f_concat(o_info, '{');
        o_info   := mystring.f_concat(o_info, ' "rn":"', v_row_rn, '"');
        o_info   := mystring.f_concat(o_info, ',"evnum":"', v_row_evnum, '"');
        o_info   := mystring.f_concat(o_info, '}');
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
END;
/
