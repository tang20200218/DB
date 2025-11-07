CREATE OR REPLACE PROCEDURE pc_data_deal
(
  i_reqid    IN VARCHAR2, -- 请求标识
  i_forminfo IN CLOB, -- 表单信息(前台请求)
  i_operuri  IN VARCHAR2, -- 操作人URI
  i_opername IN VARCHAR2, -- 操作人姓名
  i_usertype IN VARCHAR2, -- 用户类型
  o_info1    OUT CLOB, -- 返回信息集合(前台)
  o_info2    OUT CLOB, -- 返回信息集合(后台)
  o_code     OUT VARCHAR2, -- 操作结果：错误码(ECXX)
  o_msg      OUT VARCHAR2 -- 添加成功/错误原因
) AS
  /***************************************************************************************************
  功能描述 : 前台请求总入口
    
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-01  唐金鑫  创建
    
  业务说明
  ***************************************************************************************************/
  v_forminfo   CLOB;
  v_beanname   VARCHAR2(64);
  v_methodname VARCHAR2(64);
  v_stype      VARCHAR2(8);
  v_stmt_sql   VARCHAR2(4000);
BEGIN
  mydebug.wlog('i_reqid', i_reqid);
  mydebug.wlog('i_forminfo', i_forminfo);
  mydebug.wlog('i_operuri', i_operuri);
  mydebug.wlog('i_opername', i_opername);
  mydebug.wlog('i_usertype', i_usertype);

  IF mystring.f_isnull(i_forminfo) THEN
    o_code  := 'EC02';
    o_msg   := '请求表单信息为空，请检查！';
    o_info1 := mystring.f_concat('{"code":"', o_code, '","msg":"', o_msg, '"}');
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  v_forminfo := mybase64.f_clob_decode(i_forminfo);
  mydebug.wlog('v_forminfo', v_forminfo);
  IF mystring.f_isnull(v_forminfo) THEN
    o_code  := 'EC02';
    o_msg   := '请求表单信息解码失败，请检查！';
    o_info1 := mystring.f_concat('{"code":"', o_code, '","msg":"', o_msg, '"}');
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  -- 请求表单解析
  SELECT json_value(v_forminfo, '$.beanname') INTO v_beanname FROM dual;
  SELECT json_value(v_forminfo, '$.methodname') INTO v_methodname FROM dual;
  mydebug.wlog('beanname', v_beanname);
  mydebug.wlog('methodname', v_methodname);

  -- 请求映射
  BEGIN
    SELECT t.stype, t.stmt
      INTO v_stype, v_stmt_sql
      FROM info_deal t
     WHERE t.beanname = v_beanname
       AND t.methodname = v_methodname;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
  mydebug.wlog('v_stmt_sql', v_stmt_sql);
  IF mystring.f_isnull(v_stmt_sql) THEN
    o_code  := 'EC02';
    o_msg   := '代理请求业务类型未定义，请检查！';
    o_info1 := mystring.f_concat('{"code":"', o_code, '","msg":"', o_msg, '"}');
    mydebug.wlog(3, o_code, o_msg);
    RETURN;
  END IF;

  IF v_stmt_sql LIKE '%:%:%:%:%:%:%:%' THEN
    EXECUTE IMMEDIATE v_stmt_sql
      USING IN v_forminfo, IN i_operuri, IN i_opername, OUT o_info1, OUT o_info2, OUT o_code, OUT o_msg;
  ELSIF v_stmt_sql LIKE '%:%:%:%:%:%:%' THEN
    EXECUTE IMMEDIATE v_stmt_sql
      USING IN v_forminfo, IN i_operuri, IN i_opername, OUT o_info1, OUT o_code, OUT o_msg;
  ELSE
    IF v_stmt_sql LIKE '%operuri%opername%info%code%_msg%' THEN
      EXECUTE IMMEDIATE v_stmt_sql
        USING IN i_operuri, IN i_opername, OUT o_info1, OUT o_code, OUT o_msg;
    ELSIF v_stmt_sql LIKE '%forminfo%operuri%opername%code%_msg%' THEN
      EXECUTE IMMEDIATE v_stmt_sql
        USING IN v_forminfo, IN i_operuri, IN i_opername, OUT o_code, OUT o_msg;
    ELSIF v_stmt_sql LIKE '%forminfo%info%code%_msg%' THEN
      EXECUTE IMMEDIATE v_stmt_sql
        USING IN v_forminfo, OUT o_info1, OUT o_code, OUT o_msg;
    END IF;
  END IF;

  IF mystring.f_isnull(o_code) THEN
    o_info1 := '{"code":"EC00","msg":"处理成功"}';
  ELSE
    IF o_code = 'EC00' THEN
      IF mystring.f_isnull(o_info1) THEN
        o_info1 := mystring.f_concat('{"code":"', o_code, '","msg":"', o_msg, '"}');
      END IF;
    ELSE
      o_info1 := mystring.f_concat('{"code":"', o_code, '","msg":"', o_msg, '"}');
    END IF;
  END IF;

  -- 记录日志
  mydebug.wlog('o_info1', o_info1);
  mydebug.wlog('o_info2', o_info2);

  COMMIT;

  -- 8.处理成功
  o_code := 'EC00';
  o_msg  := '处理成功';
  mydebug.wlog(1, o_code, o_msg);
EXCEPTION
  -- 9.异常处理
  WHEN OTHERS THEN
    ROLLBACK;
    o_code  := 'EC03';
    o_msg   := '系统错误，请检查！';
    o_info1 := '{"code":"EC03","msg":"系统错误，请检查！"}';
    mydebug.err(7);
END;
/
