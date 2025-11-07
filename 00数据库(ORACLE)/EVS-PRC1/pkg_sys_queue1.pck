CREATE OR REPLACE PACKAGE pkg_sys_queue1 IS

  /***************************************************************************************************
  名称     : pkg_sys_queue1
  功能描述 : 注册单位/用户的队列
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-08  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询默认排序号
  PROCEDURE p_getinfo
  (
    o_status OUT VARCHAR2, -- 是否存在待处理数据(1:是 0:否)
    o_type   OUT VARCHAR2, -- 调用TDS的方法名(saveDept,saveUser)
    o_info   OUT VARCHAR2, -- 调用TDS的参数
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  );

  -- 保存注册成功后返回的信息
  PROCEDURE p_save
  (
    i_type IN VARCHAR2, -- 调用TDS的方法名(saveDept,saveUser)
    i_info IN CLOB, -- 注册成功后返回的信息
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_sys_queue1 IS

  /***************************************************************************************************
  名称     : pkg_sys_queue1.p_getinfo
  功能描述 : 查询待注册数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-08  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_getinfo
  (
    o_status OUT VARCHAR2, -- 是否存在待处理数据(1:是 0:否)
    o_type   OUT VARCHAR2, -- 调用TDS的方法名(saveDept,saveUser)
    o_info   OUT VARCHAR2, -- 调用TDS的参数
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id           VARCHAR2(64);
    v_errtimes     INT;
    v_modifieddate DATE;
    v_datatype     INT;
    v_datatype_now INT;
  
    v_sysdate DATE := SYSDATE;
    v_select  INT := 0;
  
    v_num INT := 0;
    v_max INT := 5;
  
    v_name VARCHAR2(200);
  BEGIN
    -- mydebug.wlog('start');
    o_status := '0';
  
    o_info := '<info>';
    o_info := mystring.f_concat(o_info, '<appuri>', pkg_basic.f_getconfig('cf02'), '</appuri>');
    o_info := mystring.f_concat(o_info, '<operuri>system</operuri>');
    o_info := mystring.f_concat(o_info, '<opername>system</opername>');
    o_info := mystring.f_concat(o_info, '<opertype>OT01</opertype>');
    o_info := mystring.f_concat(o_info, '<datas>');
  
    DECLARE
      CURSOR v_cursor IS
        SELECT id, errtimes, modifieddate, datatype FROM info_register_queue t ORDER BY t.modifieddate;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_errtimes, v_modifieddate, v_datatype;
        EXIT WHEN v_cursor%NOTFOUND;
      
        v_select := 1;
        IF v_errtimes > 0 THEN
          -- 错误数据，根据错误次数增加等待时间
          IF mydate.f_interval_second(v_sysdate, v_modifieddate) < v_errtimes * 60 THEN
            v_select := 0;
          END IF;
        END IF;
      
        IF v_select = 1 THEN
          IF v_num = 0 THEN
            v_datatype_now := v_datatype;
          ELSE
            IF v_datatype_now <> v_datatype THEN
              v_select := 0;
            END IF;
          END IF;
        END IF;
      
        IF v_select = 1 THEN
          UPDATE info_register_queue t SET t.modifieddate = v_sysdate WHERE t.id = v_id;
        
          v_name := '';
          BEGIN
            SELECT objname
              INTO v_name
              FROM info_register_obj
             WHERE objcode = v_id
               AND rownum <= 1;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
        END IF;
      
        IF v_select = 1 THEN
          IF v_datatype_now = 0 THEN
            o_type := 'saveUser';
            o_info := mystring.f_concat(o_info, '<data>');
            o_info := mystring.f_concat(o_info, '<name>', myxml.f_escape(v_name), '</name>');
            o_info := mystring.f_concat(o_info, '<idcard>', myxml.f_escape(v_id), '</idcard>');
            o_info := mystring.f_concat(o_info, '</data>');
          ELSE
            o_type := 'saveDept';
            o_info := mystring.f_concat(o_info, '<data>');
            o_info := mystring.f_concat(o_info, '<name>', myxml.f_escape(v_name), '</name>');
            o_info := mystring.f_concat(o_info, '<code>', myxml.f_escape(v_id), '</code>');
            o_info := mystring.f_concat(o_info, '</data>');
          END IF;
          v_num := v_num + 1;
          IF v_num = v_max THEN
            EXIT;
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
  
    o_info := mystring.f_concat(o_info, '</datas>');
    o_info := mystring.f_concat(o_info, '</info>');
  
    -- mydebug.wlog('o_status', o_status);
    IF v_num > 0 THEN
      o_status := '1';
      mydebug.wlog('o_type', o_type);
      mydebug.wlog('o_info', o_info);
    END IF;
  
    COMMIT;
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_sys_queue1.p_save
  功能描述 : 保存注册成功后返回的信息
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-08  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_save
  (
    i_type IN VARCHAR2, -- 调用TDS的方法名(saveDept,saveUser)
    i_info IN CLOB, -- 注册成功后返回的信息
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sysdate DATE := SYSDATE;
  
    v_xml   xmltype;
    v_i     INT := 0;
    v_xpath VARCHAR2(200);
  
    v_flag  VARCHAR2(64);
    v_msg   VARCHAR2(2000);
    v_code  VARCHAR2(64);
    v_id    VARCHAR2(64);
    v_route VARCHAR2(4000);
    v_name  VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_type', i_type);
    mydebug.wlog('i_info', i_info);
  
    -- 解析XML  
    v_xml := xmltype(i_info);
  
    v_i := 1;
    WHILE v_i <= 100 LOOP
      v_xpath := mystring.f_concat('/datas/data[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@flag')) INTO v_flag FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@msg')) INTO v_msg FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@code')) INTO v_code FROM dual;
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@id')) INTO v_id FROM dual;
      SELECT myxml.f_getnode_str(v_xml, mystring.f_concat(v_xpath, 'rs')) INTO v_route FROM dual;
    
      IF mystring.f_isnull(v_code) THEN
        v_i := 100;
      ELSE
        IF mystring.f_isnull(v_id) THEN
          UPDATE info_register_queue t SET t.errtimes = t.errtimes + 1, t.errcode = v_flag, t.errinfo = v_msg, t.modifieddate = v_sysdate WHERE t.id = v_code;
          UPDATE info_register_obj t SET t.status = 2, t.errmsg = v_msg, t.modifieddate = v_sysdate WHERE t.objcode = v_code;
        ELSE
          DELETE FROM info_register_queue WHERE id = v_code;
          UPDATE info_register_obj t SET t.objid = v_id, t.status = 1, t.modifieddate = v_sysdate WHERE t.objcode = v_code;
        
          v_name := NULL;
          BEGIN
            SELECT t.objname
              INTO v_name
              FROM info_register_obj t
             WHERE t.objcode = v_code
               AND rownum <= 1;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
        
          -- 修正签发数据
          UPDATE data_qf_book t
             SET t.douri = v_id
           WHERE t.docode = v_code
             AND t.douri IS NULL;
        
          -- 存储路由信息
          IF mystring.f_isnotnull(v_id) AND mystring.f_isnotnull(v_route) THEN
            pkg_exch_to_site.p_ins(v_id, v_name, 'QT10', v_route, o_code, o_msg);
            IF o_code <> 'EC00' THEN
              ROLLBACK;
              RETURN;
            END IF;
          END IF;
        END IF;
      END IF;
    
      v_i := v_i + 1;
    END LOOP;
  
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
