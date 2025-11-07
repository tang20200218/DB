CREATE OR REPLACE PACKAGE pkg_x_status_r IS

  /***************************************************************************************************
  名称     : pkg_x_status_r
  功能描述 : 处理收到的交换状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2020-12-08  唐金鑫  创建
  
  业务说明  
  ***************************************************************************************************/

  -- 获取到最后成功交换状态的业务处理
  PROCEDURE p_finish
  (
    i_exchid IN VARCHAR2, -- 交换标识
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  );

  PROCEDURE p_upd1
  (
    i_exchid       IN VARCHAR2, -- 交换标识
    i_site_uri     IN VARCHAR2, -- 发送者ID
    i_site_status  IN VARCHAR2, -- 处理状态代码(PS03)
    i_site_stadesc IN VARCHAR2, -- 处理状态(已经处理)
    i_site_modify  IN VARCHAR2, -- 处理时间(2019-12-24 15:26:34)
    i_site_errcode IN VARCHAR2, -- 错误代码(0:成功)
    o_code         OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
    o_msg          OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 将所有交换节点的状态设置为已经处理(PS03)
  PROCEDURE p_upd2
  (
    i_exchid IN VARCHAR2, -- 发送ID
    o_code   OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
    o_msg    OUT VARCHAR2 -- 添加成功/错误原因
  );

  -- 更新交换状态
  PROCEDURE p_upd
  (
    i_exchid     IN VARCHAR2, -- 交换标识
    i_exchstatus IN VARCHAR2, -- 交换状态
    o_code       OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
    o_msg        OUT VARCHAR2 -- 添加成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_x_status_r IS

  -- 获取到最后成功交换状态的业务处理
  PROCEDURE p_finish
  (
    i_exchid IN VARCHAR2, -- 交换标识
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_docid VARCHAR2(128);
    v_dtype VARCHAR2(8);
    v_sql   VARCHAR2(200);
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
  
    SELECT docid, dtype INTO v_docid, v_dtype FROM data_exch_status t WHERE t.exchid = i_exchid;
  
    BEGIN
      SELECT sqltxt
        INTO v_sql
        FROM data_exch_sql t
       WHERE t.dtype = v_dtype
         AND t.sqltype = '2'
         AND rownum <= 1;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnull(v_sql) THEN
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_sql LIKE '%exchid%' THEN
      EXECUTE IMMEDIATE v_sql
        USING IN i_exchid, OUT o_code, OUT o_msg;
    ELSE
      EXECUTE IMMEDIATE v_sql
        USING IN v_docid, OUT o_code, OUT o_msg;
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
      mydebug.err(3);
  END;

  /***************************************************************************************************
  名称     : pkg_x_status_r.p_upd1
  功能描述 : 更新交换状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2020-12-08  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_upd1
  (
    i_exchid       IN VARCHAR2, -- 交换标识
    i_site_uri     IN VARCHAR2, -- 发送者ID
    i_site_status  IN VARCHAR2, -- 处理状态代码(PS03)
    i_site_stadesc IN VARCHAR2, -- 处理状态(已经处理)
    i_site_modify  IN VARCHAR2, -- 处理时间(2019-12-24 15:26:34)
    i_site_errcode IN VARCHAR2, -- 错误代码(0:成功)
    o_code         OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
    o_msg          OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_exists          INT := 0;
    v_sysdate         DATE := SYSDATE;
    v_id              VARCHAR2(128);
    v_sort            INT;
    v_final           INT;
    v_site_modify     DATE;
    v_site_old_modify DATE;
    v_site_old_status VARCHAR2(16);
    v_site_stadesc    VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
  
    IF mystring.f_isnull(i_exchid) THEN
      o_code := 'EC00';
      o_msg  := '交换标识为空!';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_site_uri) THEN
      o_code := 'EC00';
      o_msg  := '处理失败,请确认发送状态信息格式是否正确!';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_site_status) THEN
      o_code := 'EC00';
      o_msg  := '处理失败,请确认发送状态信息格式是否正确!';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM data_exch_status t WHERE t.exchid = i_exchid;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理失败,未查到该发件信息!';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE data_exch_status t SET t.modifieddate = v_sysdate WHERE t.exchid = i_exchid;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM data_exch_status t
     WHERE t.exchid = i_exchid
       AND t.final = '1';
    IF v_exists > 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功！';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM data_exch_status_site t
             WHERE t.exchid = i_exchid
               AND t.siteuri = i_site_uri);
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '处理失败,未查到该节点信息!';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT t.id, t.final, t.sort
      INTO v_id, v_final, v_sort
      FROM data_exch_status_site t
     WHERE t.exchid = i_exchid
       AND t.siteuri = i_site_uri
       AND rownum <= 1;
  
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM data_exch_status_site t
             WHERE t.exchid = i_exchid
               AND t.sort > v_sort
               AND t.status <> 'PS00');
    IF v_exists = 1 THEN
      o_code := 'EC00';
      o_msg  := '处理成功！';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    BEGIN
      v_site_modify := to_date(i_site_modify, 'yyyy-mm-dd hh24:mi:ss');
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF v_site_modify IS NULL THEN
      v_site_modify := v_sysdate;
    END IF;
  
    -- 1.判断当前节点是否为处理失败,如果是且来的状态不为成功则忽略
    -- 2.比较错误码日期
    SELECT t.status INTO v_site_old_status FROM data_exch_status_site t WHERE t.id = v_id;
    IF v_site_old_status IN ('PS01', 'PS04', 'PS05', 'PS06', 'PS07') THEN
      IF i_site_status NOT IN ('PS03') THEN
        -- 老日期则返回
        SELECT t.modifieddate INTO v_site_old_modify FROM data_exch_status_site t WHERE t.id = v_id;
        IF v_site_old_modify > v_site_modify THEN
          o_code := 'EC00';
          o_msg  := '处理失败,当前状态为处理错误!';
          mydebug.wlog(3, o_code, o_msg);
          RETURN;
        END IF;
      END IF;
    END IF;
  
    -- 改前面节点改为PS03
    UPDATE data_exch_status_site t
       SET t.modifieddate = v_site_modify
     WHERE t.exchid = i_exchid
       AND t.siteuri = i_site_uri
       AND t.sort < v_sort
       AND t.status <> 'PS03';
    UPDATE data_exch_status_site t
       SET t.status = 'PS03', t.stadesc = '已经处理', t.errcode = '0'
     WHERE t.exchid = i_exchid
       AND t.sort < v_sort;
  
    -- 改当前节点的状态
    IF i_site_status = 'PS00' THEN
      v_site_stadesc := '等待处理';
    ELSIF i_site_status = 'PS01' THEN
      v_site_stadesc := '接收方未开机';
    ELSIF i_site_status = 'PS02' THEN
      v_site_stadesc := '正在处理';
    ELSIF i_site_status = 'PS03' THEN
      v_site_stadesc := '已经处理';
    ELSIF i_site_status = 'PS04' THEN
      v_site_stadesc := '处理失败';
    ELSIF i_site_status = 'PS05' THEN
      v_site_stadesc := '接收错误';
    ELSIF i_site_status = 'PS06' THEN
      v_site_stadesc := '发送错误';
    ELSIF i_site_status = 'PS07' THEN
      v_site_stadesc := '忽略处理';
    ELSE
      v_site_stadesc := i_site_stadesc;
    END IF;
  
    UPDATE data_exch_status_site t SET t.status = i_site_status, t.stadesc = v_site_stadesc, t.errcode = i_site_errcode, t.modifieddate = v_site_modify WHERE t.id = v_id;
  
    -- 更新下一个节点为PS02
    IF v_final = 0 THEN
      IF i_site_status = 'PS03' THEN
        v_sort := v_sort + 1;
        UPDATE data_exch_status_site t
           SET t.status = 'PS02', t.stadesc = '正在处理', t.errcode = '0'
         WHERE t.exchid = i_exchid
           AND t.sort = v_sort;
      END IF;
    END IF;
  
    -- 更新状态数据
    UPDATE data_exch_status t
       SET t.settimes = t.settimes + 1, t.modifieddate = v_sysdate
     WHERE t.exchid = i_exchid
       AND t.final = '0';
  
    IF v_final = 1 AND i_site_status = 'PS03' THEN
      -- 最后节点
      UPDATE data_exch_status t SET t.status = 'SS02', t.recvtime = v_site_modify, t.final = '1' WHERE t.exchid = i_exchid;
    
      -- 判断是否有业务需要办理
      pkg_x_status_r.p_finish(i_exchid, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    ELSE
      IF i_site_status IN ('PS01', 'PS04', 'PS05', 'PS06', 'PS07') THEN
        -- 发送失败
        UPDATE data_exch_status t SET t.status = 'SS03' WHERE t.exchid = i_exchid;
      ELSE
        -- 正在发送
        UPDATE data_exch_status t SET t.status = 'SS04' WHERE t.exchid = i_exchid;
      END IF;
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功！';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_x_status_r.p_upd2
  功能描述 : 将所有交换节点的状态设置为已经处理(PS03)
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2020-12-08  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_upd2
  (
    i_exchid IN VARCHAR2, -- 发送ID
    o_code   OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
    o_msg    OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_exists  INT := 0;
    v_sysdate DATE := SYSDATE;
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
  
    IF mystring.f_isnull(i_exchid) THEN
      o_code := 'EC00';
      o_msg  := '处理成功！';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT COUNT(1) INTO v_exists FROM data_exch_status t WHERE t.exchid = i_exchid;
    IF v_exists = 0 THEN
      o_code := 'EC00';
      o_msg  := '处理成功！';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;
  
    UPDATE data_exch_status_site t SET t.status = 'PS03', t.stadesc = '已经处理', t.errcode = '0', t.modifieddate = v_sysdate WHERE t.exchid = i_exchid;
  
    UPDATE data_exch_status t SET t.status = 'SS02', t.recvtime = v_sysdate, t.modifieddate = v_sysdate WHERE t.exchid = i_exchid;
  
    o_code := 'EC00';
    o_msg  := '处理成功！';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_x_status_r.p_upd
  功能描述 : 更新交换状态
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2020-12-08  唐金鑫  创建
  ***************************************************************************************************/
  PROCEDURE p_upd
  (
    i_exchid     IN VARCHAR2, -- 交换标识
    i_exchstatus IN VARCHAR2, -- 交换状态
    o_code       OUT VARCHAR2, -- 操作结果：错误码(ECXX)，参见系统代码表
    o_msg        OUT VARCHAR2 -- 添加成功/错误原因
  ) AS
    v_exchid    VARCHAR2(128);
    v_ids_count INT := 0;
    v_i         INT := 0;
  
    v_type   VARCHAR2(8);
    v_subids VARCHAR2(4000);
  
    v_site_uri     VARCHAR2(64); -- 发送者ID
    v_site_status  VARCHAR2(16); -- 处理状态代码(PS03)
    v_site_stadesc VARCHAR2(64); -- 处理状态(已经处理)
    v_site_modify  VARCHAR2(64); -- 处理时间(2019-12-24 15:26:34)
    v_site_errcode VARCHAR2(64); -- 错误代码(0:成功)
  BEGIN
    mydebug.wlog('i_exchid', i_exchid);
    mydebug.wlog('i_exchstatus', i_exchstatus);
  
    IF mystring.f_isnull(i_exchstatus) THEN
      o_code := 'EC00';
      o_msg  := '交换状态为空!';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    DECLARE
      v_xml xmltype;
    BEGIN
      v_xml := xmltype(i_exchstatus);
      SELECT myxml.f_getvalue(v_xml, '/status/@type') INTO v_type FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/@subids') INTO v_subids FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/site[1]/@uri') INTO v_site_uri FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/site[1]/@status') INTO v_site_status FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/site[1]/@stadesc') INTO v_site_stadesc FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/site[1]/@modify') INTO v_site_modify FROM dual;
      SELECT myxml.f_getvalue(v_xml, '/status/site[1]/@errcode') INTO v_site_errcode FROM dual;
    END;
  
    v_site_modify := TRIM(v_site_modify);
  
    IF v_type = 'massive' THEN
      v_ids_count := myarray.f_getcount(v_subids, '#');
      IF v_ids_count > 0 THEN
        v_i := 1;
        WHILE v_i <= v_ids_count LOOP
          v_exchid := myarray.f_getvalue(v_subids, '#', v_i);
          pkg_x_status_r.p_upd1(v_exchid, v_site_uri, v_site_status, v_site_stadesc, v_site_modify, v_site_errcode, o_code, o_msg);
          v_i := v_i + 1;
        END LOOP;
      END IF;
    ELSE
      pkg_x_status_r.p_upd1(i_exchid, v_site_uri, v_site_status, v_site_stadesc, v_site_modify, v_site_errcode, o_code, o_msg);
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功！';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

END;
/
