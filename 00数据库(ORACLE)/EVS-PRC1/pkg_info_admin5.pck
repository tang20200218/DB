CREATE OR REPLACE PACKAGE pkg_info_admin5 IS

  /***************************************************************************************************
  名称     : pkg_info_admin5
  功能描述 : 管理员管理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-04  唐金鑫  创建
  
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

  -- 添加
  PROCEDURE p_ins
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_username IN VARCHAR2, -- 人员名称
    i_passwd   IN VARCHAR2, -- 人员密码
    i_linktel  IN VARCHAR2, -- 联系电话
    i_sort     IN VARCHAR2, -- 人员排序
    i_sign     IN VARCHAR2, -- 个人签名印章
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除
  PROCEDURE p_del
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 修改
  PROCEDURE p_upd
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_username IN VARCHAR2, -- 人员名称
    i_linktel  IN VARCHAR2, -- 联系电话
    i_sort     IN VARCHAR2, -- 人员排序
    i_sign     IN VARCHAR2, -- 个人签名印章
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 修改密码
  PROCEDURE p_upd_passwd
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_passwd   IN VARCHAR2, -- 新密码
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 添加/删除/修改
  PROCEDURE p_oper
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
CREATE OR REPLACE PACKAGE BODY pkg_info_admin5 IS

  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT CLOB, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sql VARCHAR2(8000); -- 查询语句
  
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码
  
    v_cnt INT := 0;
    v_num INT := 0;
  
    v_row_rn          INT;
    v_row_adminuri    VARCHAR2(64);
    v_row_adminname   VARCHAR2(128);
    v_row_linktel     VARCHAR2(128);
    v_row_sort        INT;
    v_row_operunm     VARCHAR2(64);
    v_row_createddate DATE;
    v_row             VARCHAR2(4000);
  BEGIN
    mydebug.wlog('开始');
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD911', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    -- 制作sql
    v_sql := 'select sort,adminuri from info_admin E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.admintype= ''MT05''');
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY sort,adminuri desc');
    v_sql := myquery.f_getpagesql(v_sql, v_pagesize, v_pagenum);
    mydebug.wlog('v_sql', v_sql);
  
    -- 分页起始编号
    v_row_rn := myquery.f_getpagestartnum(v_pagesize, v_pagenum);
  
    -- 查询列表  
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
          INTO v_row_sort, v_row_adminuri;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT t.adminname, t.linktel, t.modifieddate, t.operunm
          INTO v_row_adminname, v_row_linktel, v_row_createddate, v_row_operunm
          FROM info_admin t
         WHERE t.adminuri = v_row_adminuri
           AND t.admintype = 'MT05';
      
        v_row := '{';
        v_row := mystring.f_concat(v_row, ' "rn":"', v_row_rn, '"');
        v_row := mystring.f_concat(v_row, ',"adminuri":"', v_row_adminuri, '"');
        v_row := mystring.f_concat(v_row, ',"adminname":"', myjson.f_escape(v_row_adminname), '"');
        v_row := mystring.f_concat(v_row, ',"linktel":"', myjson.f_escape(v_row_linktel), '"');
        v_row := mystring.f_concat(v_row, ',"sort":"', v_row_sort, '"');
        v_row := mystring.f_concat(v_row, ',"operunm":"', v_row_operunm, '"');
        v_row := mystring.f_concat(v_row, ',"createddate":"', to_char(v_row_createddate, 'yyyy-mm-dd hh24:mi'), '"');
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

  -- 添加
  PROCEDURE p_ins
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_username IN VARCHAR2, -- 人员名称
    i_passwd   IN VARCHAR2, -- 人员密码
    i_linktel  IN VARCHAR2, -- 联系电话
    i_sort     IN VARCHAR2, -- 人员排序
    i_sign     IN VARCHAR2, -- 个人签名印章
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT;
    v_passwd VARCHAR2(256);
  BEGIN
    mydebug.wlog('i_useruri', i_useruri);
    mydebug.wlog('i_username', i_username);
    mydebug.wlog('i_passwd', i_passwd);
    mydebug.wlog('i_linktel', i_linktel);
    mydebug.wlog('i_sort', i_sort);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_useruri) THEN
      o_code := 'EC02';
      o_msg  := '用户账号为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_username) THEN
      o_code := 'EC02';
      o_msg  := '用户姓名为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF i_useruri IN ('sys', 'system', 'admin') THEN
      o_code := 'EC02';
      o_msg  := '用户账号不能使用系统保留字符,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DECLARE
      v_check_useruri VARCHAR2(256);
    BEGIN
      v_check_useruri := lower(i_useruri);
      SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_admin_ban t WHERE t.id = v_check_useruri);
      IF v_exists > 0 THEN
        o_code := 'EC02';
        o_msg  := mystring.f_concat(i_useruri, '不能作为系统操作员账号！');
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_admin t
             WHERE t.adminuri = i_useruri
               AND t.admintype = 'MT05');
    IF v_exists > 0 THEN
      o_code := 'EC02';
      o_msg  := '已是管理员,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    INSERT INTO info_admin (adminuri, adminname, admintype, sort, operuid, operunm, linktel) VALUES (i_useruri, i_username, 'MT05', i_sort, i_operuri, i_opername, i_linktel);
  
    UPDATE info_admin t SET t.adminname = i_username, t.linktel = i_linktel WHERE t.adminuri = i_useruri;
  
    DELETE FROM info_admin_sign WHERE adminuri = i_useruri;
    INSERT INTO info_admin_sign (adminuri, adminname, signseal, operuid, operunm) VALUES (i_useruri, i_username, i_sign, i_operuri, i_opername);
  
    IF mystring.f_isnull(i_passwd) THEN
      v_passwd := '123456';
    ELSE
      v_passwd := i_passwd;
    END IF;
    UPDATE info_admin t SET t.password = v_passwd WHERE t.adminuri = i_useruri;
  
    UPDATE sys_config2 t SET t.val = '0' WHERE t.code = 'admin';
  
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

  -- 删除
  PROCEDURE p_del
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_cnt1 INT;
  BEGIN
    mydebug.wlog('i_useruri', i_useruri);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_useruri) THEN
      o_code := 'EC02';
      o_msg  := '用户标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF i_operuri <> 'admin' THEN
      SELECT COUNT(1) INTO v_cnt1 FROM info_admin t WHERE t.admintype = 'MT05';
      IF v_cnt1 = 1 THEN
        o_code := 'EC02';
        o_msg  := '最后的管理员不能注销,请检查！';
        mydebug.wlog(3, o_code, o_msg);
        RETURN;
      END IF;
    END IF;
  
    DELETE FROM info_admin
     WHERE adminuri = i_useruri
       AND admintype = 'MT05';
  
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

  -- 修改
  PROCEDURE p_upd
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_username IN VARCHAR2, -- 人员名称
    i_linktel  IN VARCHAR2, -- 联系电话
    i_sort     IN VARCHAR2, -- 人员排序
    i_sign     IN VARCHAR2, -- 个人签名印章
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_useruri', i_useruri);
    mydebug.wlog('i_username', i_username);
    mydebug.wlog('i_linktel', i_linktel);
    mydebug.wlog('i_sort', i_sort);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_useruri) THEN
      o_code := 'EC02';
      o_msg  := '用户标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE info_admin t
       SET t.adminname = i_username, t.sort = i_sort, t.operuid = i_operuri, t.operunm = i_opername, t.modifieddate = SYSDATE
     WHERE t.adminuri = i_useruri
       AND t.admintype = 'MT05';
  
    UPDATE info_admin t SET t.adminname = i_username, t.linktel = i_linktel WHERE t.adminuri = i_useruri;
  
    DELETE FROM info_admin_sign WHERE adminuri = i_useruri;
    INSERT INTO info_admin_sign (adminuri, adminname, signseal, operuid, operunm) VALUES (i_useruri, i_username, i_sign, i_operuri, i_opername);
  
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

  -- 修改密码
  PROCEDURE p_upd_passwd
  (
    i_useruri  IN VARCHAR2, -- 人员标识
    i_passwd   IN VARCHAR2, -- 新密码
    i_operuri  IN VARCHAR2, -- 操作人标识
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    mydebug.wlog('i_useruri', i_useruri);
    mydebug.wlog('i_passwd', i_passwd);
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_useruri) THEN
      o_code := 'EC02';
      o_msg  := '人员标识为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_passwd) THEN
      o_code := 'EC02';
      o_msg  := '密码为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE info_admin t SET t.password = i_passwd, t.operuid = i_operuri, t.operunm = i_opername, t.modifieddate = SYSDATE WHERE t.adminuri = i_useruri;
  
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

  /***************************************************************************************************
  名称     : pkg_info_admin5.p_oper
  功能描述 : 添加/删除/修改
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-17  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info     OUT VARCHAR2, -- 查询返回的结果
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_type     VARCHAR2(8);
    v_useruri  VARCHAR2(64);
    v_username VARCHAR2(128);
    v_password VARCHAR2(64);
    v_linktel  VARCHAR2(64);
    v_sort     VARCHAR2(8);
    v_sign     VARCHAR2(8000);
  BEGIN
    mydebug.wlog('开始');
    -- 验证用户权限
    pkg_qp_verify.p_check('MD911', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
    mydebug.wlog('v_type', v_type);
  
    IF mystring.f_isnull(v_type) OR v_type NOT IN ('1', '0', '2', '4') THEN
      o_code := 'EC02';
      o_msg  := '处理失败,操作类型不正确,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_type = '1' THEN
      SELECT json_value(i_forminfo, '$.i_useruri') INTO v_useruri FROM dual;
      SELECT json_value(i_forminfo, '$.i_username') INTO v_username FROM dual;
      SELECT json_value(i_forminfo, '$.i_password') INTO v_password FROM dual;
      SELECT json_value(i_forminfo, '$.i_linktel') INTO v_linktel FROM dual;
      SELECT json_value(i_forminfo, '$.i_sort') INTO v_sort FROM dual;
      SELECT json_value(i_forminfo, '$.i_sign') INTO v_sign FROM dual;
      pkg_info_admin5.p_ins(v_useruri, v_username, v_password, v_linktel, v_sort, v_sign, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSIF v_type = '0' THEN
      DECLARE
        v_data VARCHAR2(4000);
        v_xml  xmltype;
        v_i    INT := 0;
        v_code VARCHAR2(200);
        v_msg  VARCHAR2(2000);
        v_num  INT := 0;
      BEGIN
        SELECT json_value(i_forminfo, '$.data') INTO v_data FROM dual;
        v_xml  := xmltype(v_data);
        v_i    := 1;
        o_info := '{"code":"EC00","msg":"处理成功","errors":[';
        WHILE v_i <= 100 LOOP
          SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/datas/data[', v_i, ']/uri')) INTO v_useruri FROM dual;
          IF mystring.f_isnull(v_useruri) THEN
            v_i := 100;
          ELSE
            pkg_info_admin5.p_del(v_useruri, i_operuri, i_opername, v_code, v_msg);
            IF v_code <> 'EC00' THEN
              v_num := v_num + 1;
              IF v_num > 1 THEN
                o_info := mystring.f_concat(o_info, ',');
              END IF;
              o_info := mystring.f_concat(o_info, '{');
              o_info := mystring.f_concat(o_info, ' "id":"', v_useruri, '"');
              o_info := mystring.f_concat(o_info, ',"msg":"', myjson.f_escape(v_msg), '"');
              o_info := mystring.f_concat(o_info, '}');
            END IF;
          END IF;
          v_i := v_i + 1;
        END LOOP;
        o_info := mystring.f_concat(o_info, ']}');
      END;
    ELSIF v_type = '2' THEN
      SELECT json_value(i_forminfo, '$.i_useruri') INTO v_useruri FROM dual;
      SELECT json_value(i_forminfo, '$.i_username') INTO v_username FROM dual;
      SELECT json_value(i_forminfo, '$.i_linktel') INTO v_linktel FROM dual;
      SELECT json_value(i_forminfo, '$.i_sort') INTO v_sort FROM dual;
      SELECT json_value(i_forminfo, '$.i_sign') INTO v_sign FROM dual;
      pkg_info_admin5.p_upd(v_useruri, v_username, v_linktel, v_sort, v_sign, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    ELSIF v_type = '4' THEN
      SELECT json_value(i_forminfo, '$.i_useruri') INTO v_useruri FROM dual;
      SELECT json_value(i_forminfo, '$.i_password') INTO v_password FROM dual;
      pkg_info_admin5.p_upd_passwd(v_useruri, v_password, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        RETURN;
      END IF;
    END IF;
  
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
END;
/
