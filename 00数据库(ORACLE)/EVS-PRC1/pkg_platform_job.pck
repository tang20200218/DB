CREATE OR REPLACE PACKAGE pkg_platform_job IS

  /***************************************************************************************************
  名称     : pkg_platform_job
  功能描述 : 平台印制易-自动调度
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-10  唐金鑫  创建
  
  扫描所有用户、单位、凭证
  将待签发的数据写入签发队列表
  ***************************************************************************************************/

  -- 增加
  PROCEDURE p_add
  (
    i_dtype     IN VARCHAR2, -- 业务类型
    i_douri     IN VARCHAR2, -- 凭证单位标识
    i_doname    IN VARCHAR2, -- 凭证单位名称
    i_docode    IN VARCHAR2, -- 凭证单位机构代码/用户身份证号码
    i_digitalid IN VARCHAR2, -- 数字身份ID
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  );

  -- 自动调度单位/个人
  PROCEDURE p_obj
  (
    i_tempid   IN VARCHAR2,
    i_datatype IN INT
  );

  -- 自动调度单位/个人(区分法人单位/非法人单位)
  PROCEDURE p_obj2
  (
    i_tempid   IN VARCHAR2,
    i_datatype IN INT,
    i_islegal  IN INT
  );

  -- 自动调度
  PROCEDURE p_auto;
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_platform_job IS

  -- 增加
  PROCEDURE p_add
  (
    i_dtype     IN VARCHAR2, -- 业务类型
    i_douri     IN VARCHAR2, -- 凭证单位标识
    i_doname    IN VARCHAR2, -- 凭证单位名称
    i_docode    IN VARCHAR2, -- 凭证单位机构代码/用户身份证号码
    i_digitalid IN VARCHAR2, -- 数字身份ID
    o_code      OUT VARCHAR2, -- 操作结果:错误码
    o_msg       OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_otype    INT;
    v_tempname VARCHAR2(200);
  
    v_pz_id        VARCHAR2(128); -- 唯一标识
    v_pz_num_start INT; -- 起始编号
    v_pz_num_end   INT; -- 终止编号
    v_pz_num_count INT; -- 票据份数
    v_pz_billcode  VARCHAR2(64); -- 票据编码
    v_pz_billorg   VARCHAR2(128); -- 印制机构
  
    v_book_id VARCHAR2(64);
    v_task_id VARCHAR2(64);
  
    v_items         VARCHAR2(4000);
    v_templateform0 CLOB;
  BEGIN
    -- 加锁
    UPDATE info_template_bind t SET t.modifieddate = SYSDATE WHERE t.id = i_dtype;
  
    mydebug.wlog('i_dtype', i_dtype);
    mydebug.wlog('i_douri', i_douri);
  
    v_otype := pkg_info_template_pbl.f_getotype(i_dtype);
  
    -- 使用1张空白凭证
    pkg_yz_pz_pbl.p_use(i_dtype, v_pz_id, v_pz_num_start, v_pz_num_end, v_pz_num_count, v_pz_billcode, v_pz_billorg, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    v_book_id := pkg_basic.f_newid('GG');
    INSERT INTO data_qf_book
      (id, dtype, otype, douri, doname, docode, backtype, status, booktype, operuri, opername)
    VALUES
      (v_book_id, i_dtype, v_otype, i_douri, i_doname, i_docode, '0', 'GG02', '3', 'system', 'system');
  
    INSERT INTO data_qf_pz
      (id, pid, dtype, num_start, num_end, num_count, billcode, billorg, operuri, opername)
    VALUES
      (v_pz_id, v_book_id, i_dtype, v_pz_num_start, v_pz_num_end, v_pz_num_count, v_pz_billcode, v_pz_billorg, 'system', 'system');
  
    v_task_id := pkg_basic.f_newid('TK');
    INSERT INTO data_qf_task (id, pid, fromtype, opertype) VALUES (v_task_id, v_book_id, '3', '1');
  
    BEGIN
      SELECT t.templateform0 INTO v_templateform0 FROM info_template_attr t WHERE t.tempid = i_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    IF mystring.f_isnotnull(v_templateform0) THEN
      IF mystring.f_instr(v_templateform0, 'CertNumber') > 0 OR mystring.f_instr(v_templateform0, 'DigitalId') > 0 THEN
        v_tempname := pkg_info_template_pbl.f_gettempname(i_dtype);
      
        v_items := mystring.f_concat('<template name="', v_tempname, '" version="1.1">');
        v_items := mystring.f_concat(v_items, '<section>');
      
        DECLARE
          v_formid VARCHAR2(64);
          CURSOR v_cursor IS
            SELECT t.formid
              FROM info_template_form t
             WHERE t.tempid = i_dtype
               AND t.formtype = 1
             ORDER BY t.sort;
        BEGIN
          OPEN v_cursor;
          LOOP
            FETCH v_cursor
              INTO v_formid;
            EXIT WHEN v_cursor%NOTFOUND;
            v_items := mystring.f_concat(v_items, '<data form="', v_formid, '">');
            v_items := mystring.f_concat(v_items, '<items>');
            IF mystring.f_instr(v_templateform0, 'CertNumber') > 0 THEN
              v_items := mystring.f_concat(v_items, '<item tag="CertNumber" type="text">');
              v_items := mystring.f_concat(v_items, '<value>', i_douri, '</value>');
              v_items := mystring.f_concat(v_items, '</item>');
            END IF;
            IF mystring.f_instr(v_templateform0, 'DigitalId') > 0 THEN
              v_items := mystring.f_concat(v_items, '<item tag="DigitalId" type="text">');
              v_items := mystring.f_concat(v_items, '<value>', i_digitalid, '</value>');
              v_items := mystring.f_concat(v_items, '</item>');
            END IF;
            v_items := mystring.f_concat(v_items, '</items>');
            v_items := mystring.f_concat(v_items, '</data>');
          END LOOP;
          CLOSE v_cursor;
        EXCEPTION
          WHEN OTHERS THEN
            IF v_cursor%ISOPEN THEN
              CLOSE v_cursor;
            END IF;
            mydebug.err(7);
        END;
      
        v_items := mystring.f_concat(v_items, '</section>');
        v_items := mystring.f_concat(v_items, '</template>');
        INSERT INTO data_qf_task_data (id, items) VALUES (v_task_id, v_items);
      END IF;
    END IF;
  
    -- 增加自动签发队列
    pkg_qf_queue.p_add(v_book_id, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '处理失败，请检查！';
      mydebug.err(7);
  END;

  -- 自动调度单位/个人
  PROCEDURE p_obj
  (
    i_tempid   IN VARCHAR2,
    i_datatype IN INT
  ) IS
    v_objid     VARCHAR2(64);
    v_objname   VARCHAR2(128);
    v_objcode   VARCHAR2(128);
    v_digitalid VARCHAR2(64);
    v_num       INT := 0;
    v_exists    INT := 0;
    v_code      VARCHAR2(64);
    v_msg       VARCHAR2(2000);
  BEGIN
    -- mydebug.wlog('i_tempid', i_tempid);
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.objid, t.objname, t.objcode, t.digitalid
          FROM info_register_obj t
         WHERE t.datatype = i_datatype
           AND t.objid IS NOT NULL
         ORDER BY t.id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_objid, v_objname, v_objcode, v_digitalid;
        EXIT WHEN v_cursor%NOTFOUND;
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_qf_book t
                 WHERE t.dtype = i_tempid
                   AND t.douri = v_objid);
        IF v_exists = 0 THEN
          SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_yz_pz_pub t WHERE t.dtype = i_tempid);
          IF v_exists = 1 THEN
            pkg_platform_job.p_add(i_tempid, v_objid, v_objname, v_objcode, v_digitalid, v_code, v_msg);
            IF v_code = 'EC00' THEN
              v_num := v_num + 1;
              IF v_num = 100 THEN
                EXIT;
              END IF;
            END IF;
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
  
    -- 6.处理成功
    -- mydebug.wlog('end');
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      mydebug.err(7);
  END;

  -- 自动调度单位/个人(区分法人单位/非法人单位)
  PROCEDURE p_obj2
  (
    i_tempid   IN VARCHAR2,
    i_datatype IN INT,
    i_islegal  IN INT
  ) IS
    v_objid     VARCHAR2(64);
    v_objname   VARCHAR2(128);
    v_objcode   VARCHAR2(128);
    v_digitalid VARCHAR2(64);
    v_num       INT := 0;
    v_exists    INT := 0;
    v_code      VARCHAR2(64);
    v_msg       VARCHAR2(2000);
  BEGIN
    -- mydebug.wlog('i_tempid', i_tempid);
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.objid, t.objname, t.objcode, t.digitalid
          FROM info_register_obj t
         WHERE t.datatype = i_datatype
           AND t.islegal = i_islegal
           AND t.objid IS NOT NULL
         ORDER BY t.id;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_objid, v_objname, v_objcode, v_digitalid;
        EXIT WHEN v_cursor%NOTFOUND;
        SELECT COUNT(1)
          INTO v_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM data_qf_book t
                 WHERE t.dtype = i_tempid
                   AND t.douri = v_objid);
        IF v_exists = 0 THEN
          SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM data_yz_pz_pub t WHERE t.dtype = i_tempid);
          IF v_exists = 1 THEN
            pkg_platform_job.p_add(i_tempid, v_objid, v_objname, v_objcode, v_digitalid, v_code, v_msg);
            IF v_code = 'EC00' THEN
              v_num := v_num + 1;
              IF v_num = 100 THEN
                EXIT;
              END IF;
            END IF;
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
  
    -- 6.处理成功
    -- mydebug.wlog('end');
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      mydebug.err(7);
  END;

  -- 自动调度
  PROCEDURE p_auto IS
    v_tempid  VARCHAR2(64);
    v_otype   INT;
    v_islegal INT;
    v_num     INT := 0;
    v_systype VARCHAR2(16) := pkg_basic.f_getsystype;
  BEGIN
    -- mydebug.wlog('start');
  
    -- 仅平台印制易才处理
    IF v_systype <> '1' THEN
      RETURN;
    END IF;
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.tempid, t.otype, t.islegal
          FROM info_template t
         WHERE t.bindstatus = 1
           AND t.enable = '1'
           AND t.yzflag = 1
           AND t.qfflag = 1
         ORDER BY t.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_tempid, v_otype, v_islegal;
        EXIT WHEN v_cursor%NOTFOUND;
      
        IF v_otype = 1 AND v_islegal IS NOT NULL THEN
          pkg_platform_job.p_obj2(v_tempid, v_otype, v_islegal);
        ELSE
          pkg_platform_job.p_obj(v_tempid, v_otype);
        END IF;
      
        v_num := v_num + 1;
        IF v_num = 100 THEN
          EXIT;
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
  
    -- 6.处理成功
    -- mydebug.wlog('end');
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      mydebug.err(7);
  END;

END;
/
