CREATE OR REPLACE PACKAGE pkg_yz_sq_config IS

  /***************************************************************************************************
  名称     : pkg_yz_sq_config
  功能描述 : 印制-凭证申领签发办理-策略定制
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-13  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询策略
  PROCEDURE p_get
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 保存策略
  PROCEDURE p_set
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_yz_sq_config IS

  -- 查询策略
  PROCEDURE p_get
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_dtype    VARCHAR2(64);
    v_yzfftype INT;
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
  
    BEGIN
      SELECT yzfftype INTO v_yzfftype FROM info_template t WHERE t.tempid = v_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    o_info := '{';
    o_info := mystring.f_concat(o_info, '"procyList":[');
    o_info := mystring.f_concat(o_info, '{');
    o_info := mystring.f_concat(o_info, ' "code":"', v_dtype, '"');
    o_info := mystring.f_concat(o_info, ',"value":"', v_yzfftype, '"');
    o_info := mystring.f_concat(o_info, ',"val2":""');
    o_info := mystring.f_concat(o_info, ',"val3":""');
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
      o_info := NULL;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 保存策略
  PROCEDURE p_set
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sysdate DATE := SYSDATE;
    v_exists  INT := 0;
    v_dtype   VARCHAR2(64);
    v_val     VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_val') INTO v_val FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_val', v_val);
  
    IF mystring.f_isnull(v_dtype) THEN
      o_code := 'EC02';
      o_msg  := '业务标识为空！';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(v_val) THEN
      o_code := 'EC02';
      o_msg  := '参数为空！';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM info_template t WHERE t.tempid = v_dtype;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询凭证信息出错！';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE info_template t SET t.yzfftype = v_val WHERE t.tempid = v_dtype;
  
    IF v_val = '1' THEN
      -- 自动分配
      o_code := 'EC00';
      DECLARE
        v_docid   VARCHAR2(64);
        v_fromuri VARCHAR2(64);
        CURSOR v_cursor IS
          SELECT t.docid, t.fromuri
            FROM data_yz_sq_book t
           WHERE t.dtype = v_dtype
             AND t.status = 'VSB1';
      BEGIN
        OPEN v_cursor;
        LOOP
          FETCH v_cursor
            INTO v_docid, v_fromuri;
          EXIT WHEN v_cursor%NOTFOUND;
          SELECT COUNT(1)
            INTO v_exists
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM data_yz_sq_com t
                   WHERE t.dtype = v_dtype
                     AND t.sqcomid = v_fromuri);
          IF v_exists > 0 THEN
            -- 设置在分配
            UPDATE data_yz_sq_book t
               SET t.respnum = t.booknum, t.status = 'VSB3', t.modifieddate = v_sysdate, t.operuri = i_operuri, t.opername = i_opername
             WHERE t.docid = v_docid;
          
            -- 增加自动分发队列
            pkg_yz_sq_reply_queue1.p_add(v_docid, o_code, o_msg);
            IF o_code <> 'EC00' THEN
              EXIT;
            END IF;
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
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
