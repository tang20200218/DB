CREATE OR REPLACE PACKAGE pkg_yz_pz_queue IS

  /***************************************************************************************************
  名称     : pkg_yz_pz_queue
  功能描述 : 印制-空白凭证印制办理-自动印制
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-09  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询实际库存数量
  FUNCTION f_getstock(i_code VARCHAR2) RETURN INT;

  -- 查询需要自动印制的凭证集合
  PROCEDURE p_getinfo
  (
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2, -- 成功/错误原因
    o_info OUT VARCHAR2 -- 返回结果
  );

  -- 查询印制需要的数据
  PROCEDURE p_getdata
  (
    i_id       IN VARCHAR2, -- 标识
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2, -- 成功/错误原因
    o_info     OUT CLOB, -- 查询返回的结果
    o_data     OUT CLOB -- 传入印制接口的参数
  );

  -- 增加
  PROCEDURE p_ins
  (
    i_dtype  IN VARCHAR2, -- 单证类型
    i_taskid IN VARCHAR2, -- 事务标识
    o_id     OUT VARCHAR2, -- 标识
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  );

  -- 增加入账凭证签发队列
  PROCEDURE p_add_qf_queue
  (
    i_id   IN VARCHAR2, -- 业务类型
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  );

  -- 印制-保存凭证文件
  PROCEDURE p_file_add
  (
    i_id    IN VARCHAR2, -- 票本标识
    i_files IN CLOB, -- 文件信息
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  );

  -- 出错后的处理
  PROCEDURE p_err
  (
    i_taskid IN VARCHAR2, -- 事务标识
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_yz_pz_queue IS

  -- 空白模板的生成调度

  -- 查询实际库存数量
  FUNCTION f_getstock(i_code VARCHAR2) RETURN INT AS
    v_result INT;
  BEGIN
    SELECT COUNT(1) INTO v_result FROM data_yz_pz_pub t WHERE t.dtype = i_code;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 查询需要自动印制的凭证集合
  PROCEDURE p_getinfo
  (
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2, -- 成功/错误原因
    o_info OUT VARCHAR2 -- 返回结果
  ) AS
    v_id          VARCHAR2(64);
    v_tempid      VARCHAR2(64);
    v_tempname    VARCHAR2(128);
    v_yzautostock INT := 0;
    v_yzdate      DATE;
    v_errtimes    INT;
  
    v_sysdate DATE := SYSDATE;
    v_select  INT := 0;
  
    v_i     INT := 0;
    v_num   INT := 0;
    v_max   INT := 20; -- 最大返回数量
    v_stock INT := 0; -- 实际库存
    v_count INT := 0; -- 需要印制本数  
    v_comid VARCHAR2(64) := pkg_basic.f_getcomid;
  BEGIN
    o_info := '<info>';
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.tempid, t.tempname, t.yzautostock, t.yzdate
          FROM info_template t
         WHERE t.yzflag1 = 1
           AND t.bindstatus = 1
           AND t.enable = '1'
           AND t.yzautostock > 0
           AND t.vtype = 0
         ORDER BY t.yzdate;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_tempid, v_tempname, v_yzautostock, v_yzdate;
        EXIT WHEN v_cursor%NOTFOUND;
      
        v_select := 1;
      
        v_errtimes := 0;
        BEGIN
          SELECT errtimes INTO v_errtimes FROM info_template_yz t WHERE tempid = v_tempid;
        EXCEPTION
          WHEN OTHERS THEN
            v_errtimes := 0;
        END;
        IF v_errtimes > 0 THEN
          -- 错误数据，根据错误次数增加等待时间
          IF mydate.f_interval_second(v_sysdate, v_yzdate) < v_errtimes * 60 THEN
            v_select := 0;
          END IF;
        END IF;
      
        IF v_select = 1 THEN
          UPDATE info_template t SET t.yzdate = SYSDATE WHERE t.tempid = v_tempid;
          UPDATE info_template_yz t SET t.modifieddate = SYSDATE WHERE t.tempid = v_tempid;
        
          v_count := 0;
        
          -- 实际库存
          v_stock := pkg_yz_pz_queue.f_getstock(v_tempid);
        
          IF v_stock < v_yzautostock THEN
            v_count := v_yzautostock - v_stock;
            v_i     := 1;
            WHILE v_i <= v_count LOOP
              o_info := mystring.f_concat(o_info, '<com>');
              o_info := mystring.f_concat(o_info, '<did>', v_comid, '</did>');
              o_info := mystring.f_concat(o_info, '<dtype>', v_tempid, '</dtype>');
              o_info := mystring.f_concat(o_info, '<evtype>', v_tempid, '</evtype>');
              o_info := mystring.f_concat(o_info, '<evtypename>', myxml.f_escape(v_tempname), '</evtypename>');
              o_info := mystring.f_concat(o_info, '</com>');
            
              v_num := v_num + 1;
              IF v_num >= v_max THEN
                EXIT;
              END IF;
            
              v_i := v_i + 1;
            END LOOP;
          END IF;
          IF v_num >= v_max THEN
            EXIT;
          END IF;
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        mydebug.err(7);
        o_info := '';
        RETURN;
    END;
  
    IF v_num = 0 THEN
      DECLARE
        CURSOR v_cursor IS
          SELECT t.id, t.douri, t.dtype, t.errtimes, t.modifieddate
            FROM data_qf2_task t
           WHERE t.startflag = 1
             AND t.yzflag = 0
           ORDER BY t.modifieddate;
      BEGIN
        OPEN v_cursor;
        LOOP
          FETCH v_cursor
            INTO v_id, v_comid, v_tempid, v_errtimes, v_yzdate;
          EXIT WHEN v_cursor%NOTFOUND;
        
          v_select := 1;
          SELECT COUNT(1)
            INTO v_select
            FROM dual
           WHERE EXISTS (SELECT 1
                    FROM info_template t
                   WHERE t.tempid = v_tempid
                     AND t.enable = 1
                     AND t.bindstatus = 1);
        
          IF v_select = 1 AND v_errtimes > 0 THEN
            -- 错误数据，根据错误次数增加等待时间
            IF mydate.f_interval_second(v_sysdate, v_yzdate) < v_errtimes * 60 THEN
              v_select := 0;
            END IF;
          END IF;
        
          IF v_select = 1 THEN
            UPDATE data_qf2_task t SET t.startflag = 1, t.yzflag = 1, t.modifieddate = SYSDATE WHERE t.id = v_id;
            DELETE FROM data_qf2_yz_tmp WHERE id = v_id;
            INSERT INTO data_qf2_yz_tmp (id, dtype) VALUES (v_id, v_tempid);
          
            v_tempname := pkg_info_template_pbl.f_gettempname(v_tempid);
          
            o_info := mystring.f_concat(o_info, '<com>');
            o_info := mystring.f_concat(o_info, '<did>', v_comid, '</did>');
            o_info := mystring.f_concat(o_info, '<dtype>', v_tempid, '</dtype>');
            o_info := mystring.f_concat(o_info, '<evtype>', v_tempid, '</evtype>');
            o_info := mystring.f_concat(o_info, '<evtypename>', myxml.f_escape(v_tempname), '</evtypename>');
            o_info := mystring.f_concat(o_info, '</com>');
            EXIT;
          END IF;
        END LOOP;
        CLOSE v_cursor;
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
          END IF;
          mydebug.err(7);
          o_info := '';
          RETURN;
      END;
    END IF;
  
    o_info := mystring.f_concat(o_info, '</info>');
  
    IF v_num > 0 THEN
      mydebug.wlog('o_info', o_info);
    END IF;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '查询成功';
    -- mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 查询印制需要的数据
  PROCEDURE p_getdata
  (
    i_id       IN VARCHAR2, -- 标识
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2, -- 成功/错误原因
    o_info     OUT CLOB, -- 查询返回的结果
    o_data     OUT CLOB -- 传入印制接口的参数
  ) AS
    v_info_dtype     VARCHAR2(64);
    v_info_dtypename VARCHAR2(128);
    v_info_role      VARCHAR2(64); -- 签发角色，调用凭证接口SetUserRole传入凭证
    v_info_evnum     VARCHAR2(64);
    v_info_mfname    VARCHAR2(200);
    v_info_mfname2   VARCHAR2(200);
    v_info_filename  VARCHAR2(200);
    v_info_filepath  VARCHAR2(512);
    v_info           VARCHAR2(4000);
  
    v_data_master           VARCHAR2(128);
    v_data_issuemode        VARCHAR2(8);
    v_data_pickusage        VARCHAR2(512);
    v_data_customdata       VARCHAR2(4000);
    v_data_bases_code       VARCHAR2(64);
    v_data_bases_count      INT;
    v_data_bases_printedorg VARCHAR2(200);
    v_infos                 VARCHAR2(4000);
    v_bases                 VARCHAR2(4000);
  
    v_tempname  VARCHAR2(128);
    v_master    VARCHAR2(64);
    v_masternm  VARCHAR2(128);
    v_master1   VARCHAR2(64);
    v_masternm1 VARCHAR2(128);
    v_vtype     INT;
  
    v_fromid       VARCHAR2(64);
    v_printedparam CLOB;
  BEGIN
    -- mydebug.wlog('i_id', i_id);
    -- mydebug.wlog('i_operuri', i_operuri);
    -- mydebug.wlog('i_opername', i_opername);
  
    SELECT dtype, num_start, fromid INTO v_info_dtype, v_info_evnum, v_fromid FROM data_yz_pz_tmp t WHERE t.id = i_id;
  
    SELECT tempname, master, masternm, master1, masternm1, mtype, billcode, billcount, billorg, vtype
      INTO v_tempname, v_master, v_masternm, v_master1, v_masternm1, v_data_issuemode, v_data_bases_code, v_data_bases_count, v_data_bases_printedorg, v_vtype
      FROM info_template t
     WHERE t.tempid = v_info_dtype;
  
    DECLARE
      v_fileid1 VARCHAR2(64);
      v_fileid2 VARCHAR2(64);
    BEGIN
      SELECT fileid1, fileid2 INTO v_fileid1, v_fileid2 FROM info_template_file t WHERE t.code = v_info_dtype;
      v_info_mfname  := pkg_file0.f_getfilename(v_fileid1);
      v_info_mfname2 := pkg_file0.f_getfilename(v_fileid2);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_info_dtypename := pkg_info_template_pbl.f_gettempname(v_info_dtype);
    v_info_filename  := pkg_file0.f_getfilename_docid(i_id, 2);
    v_info_filepath  := pkg_file0.f_getfilepath_docid(i_id, 2);
    v_info_role      := pkg_info_template_pbl.f_getrole(v_info_dtype);
  
    v_info := '<info>';
    v_info := mystring.f_concat(v_info, '<id>', i_id, '</id>');
    v_info := mystring.f_concat(v_info, '<evtype>', v_info_dtype, '</evtype>');
    v_info := mystring.f_concat(v_info, '<evtypename>', v_info_dtypename, '</evtypename>');
    v_info := mystring.f_concat(v_info, '<role>', v_info_role, '</role>');
    v_info := mystring.f_concat(v_info, '<evnum>', v_info_evnum, '</evnum>');
    v_info := mystring.f_concat(v_info, '<mfname>', v_info_mfname, '</mfname>');
    v_info := mystring.f_concat(v_info, '<mfname2>', v_info_mfname2, '</mfname2>');
    v_info := mystring.f_concat(v_info, '<filename>', v_info_filename, '</filename>');
    v_info := mystring.f_concat(v_info, '<filepath>', v_info_filepath, '</filepath>');
    v_info := mystring.f_concat(v_info, '</info>');
  
    dbms_lob.createtemporary(o_info, TRUE);
    dbms_lob.append(o_info, v_info);
    mydebug.wlog('o_info', o_info);
  
    -- 传入印制接口的参数  
    IF mystring.f_isnotnull(v_master) THEN
      v_data_master := mystring.f_concat(v_master, ',', v_masternm);
    END IF;
    IF mystring.f_isnotnull(v_master1) THEN
      IF mystring.f_isnull(v_data_master) THEN
        v_data_master := mystring.f_concat(v_master1, ',', v_masternm1);
      ELSE
        v_data_master := mystring.f_concat(v_data_master, ';', v_master1, ',', v_masternm1);
      END IF;
    END IF;
  
    IF v_vtype = 1 THEN
      BEGIN
        SELECT pickusage, printedparam INTO v_data_pickusage, v_printedparam FROM data_qf2_applyinfo t WHERE t.id = v_fromid;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
    IF mystring.f_isnull(v_data_pickusage) THEN
      BEGIN
        SELECT pickusage, attr INTO v_data_pickusage, v_data_customdata FROM info_template_attr t WHERE t.tempid = v_info_dtype;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
    IF mystring.f_isnotnull(v_data_pickusage) THEN
      v_data_pickusage := mybase64.f_str_decode(v_data_pickusage);
    END IF;
    IF mystring.f_isnotnull(v_data_customdata) THEN
      v_data_customdata := mybase64.f_str_encode(v_data_customdata);
    END IF;
  
    v_infos := '<infos>';
    v_infos := mystring.f_concat(v_infos, '<info key="Type">', v_info_dtype, ',', v_tempname, '</info>');
    v_infos := mystring.f_concat(v_infos, '<info key="Master">', v_data_master, '</info>');
    v_infos := mystring.f_concat(v_infos, '<info key="IssueMode">', v_data_issuemode, '</info>');
    v_infos := mystring.f_concat(v_infos, '<info key="PickUsage">', v_data_pickusage, '</info>');
    v_infos := mystring.f_concat(v_infos, '<info key="CustomData">', v_data_customdata, '</info>');
    v_infos := mystring.f_concat(v_infos, '</infos>');
    v_bases := '<bases>';
    v_bases := mystring.f_concat(v_bases, '<item tag="Code"><value>', v_data_bases_code, '</value></item>');
    v_bases := mystring.f_concat(v_bases, '<item tag="Number"><value>', v_info_evnum, '</value></item>');
    v_bases := mystring.f_concat(v_bases, '<item tag="Count"><value>', v_data_bases_count, '</value></item>');
    v_bases := mystring.f_concat(v_bases, '<item tag="PrintedOrg"><value>', v_data_bases_printedorg, '</value></item>');
    v_bases := mystring.f_concat(v_bases, '</bases>');
  
    dbms_lob.createtemporary(o_data, TRUE);
    dbms_lob.append(o_data, '<data>');
    dbms_lob.append(o_data, v_infos);
    dbms_lob.append(o_data, v_bases);
  
    IF v_vtype = 1 THEN
      IF mystring.f_isnotnull(v_printedparam) THEN
        dbms_lob.append(o_data, v_printedparam);
      END IF;
    ELSE
      DECLARE
        v_prvdata_sectioncode VARCHAR2(64);
        v_prvdata_items2      CLOB;
        v_prvdata_files       CLOB;
      
        CURSOR v_cursor IS
          SELECT t.sectioncode, t.items2, t.files
            FROM info_template_prvdata t
           WHERE t.tempid = v_info_dtype
             AND t.datatype = '1';
      BEGIN
        OPEN v_cursor;
        LOOP
          FETCH v_cursor
            INTO v_prvdata_sectioncode, v_prvdata_items2, v_prvdata_files;
          EXIT WHEN v_cursor%NOTFOUND;
        
          IF mystring.f_isnotnull(v_prvdata_items2) OR mystring.f_isnotnull(v_prvdata_files) THEN
            IF mystring.f_isnull(v_prvdata_sectioncode) THEN
              dbms_lob.append(o_data, '<section>');
            ELSE
              dbms_lob.append(o_data, mystring.f_concat('<section code="', v_prvdata_sectioncode, '">'));
            END IF;
            IF mystring.f_isnotnull(v_prvdata_items2) THEN
              dbms_lob.append(o_data, v_prvdata_items2);
            END IF;
            IF mystring.f_isnotnull(v_prvdata_files) THEN
              dbms_lob.append(o_data, v_prvdata_files);
            END IF;
            dbms_lob.append(o_data, '</section>');
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
    END IF;
  
    dbms_lob.append(o_data, '<seals>');
    DECLARE
      v_seal_code     VARCHAR2(64);
      v_seal_name     VARCHAR2(128);
      v_seal_sealpin  VARCHAR2(64);
      v_seal_sealpack CLOB;
    
      CURSOR v_cursor IS
        SELECT t.code, t.name, t.sealpin, t.sealpack
          FROM info_template_seal t
         WHERE t.tempid = v_info_dtype
           AND t.sealtype = 'print'
         ORDER BY t.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_seal_code, v_seal_name, v_seal_sealpin, v_seal_sealpack;
        EXIT WHEN v_cursor%NOTFOUND;
      
        IF mystring.f_isnotnull(v_seal_sealpack) THEN
          dbms_lob.append(o_data, mystring.f_concat('<item label="', v_seal_code, '">'));
          dbms_lob.append(o_data, mystring.f_concat('<seal name="', v_seal_name, '"'));
          IF mystring.f_isnull(v_seal_sealpin) THEN
            dbms_lob.append(o_data, ' pin="123456">');
          ELSE
            dbms_lob.append(o_data, mystring.f_concat(' pin="', v_seal_sealpin, '">'));
          END IF;
          dbms_lob.append(o_data, '<pack>');
          dbms_lob.append(o_data, v_seal_sealpack);
          dbms_lob.append(o_data, '</pack> ');
          dbms_lob.append(o_data, '</seal>');
          dbms_lob.append(o_data, '</item>');
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
  
    dbms_lob.append(o_data, '</seals>');
    dbms_lob.append(o_data, '</data>');
    mydebug.wlog('o_data', o_data);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 增加
  PROCEDURE p_ins
  (
    i_dtype  IN VARCHAR2, -- 单证类型
    i_taskid IN VARCHAR2, -- 事务标识
    o_id     OUT VARCHAR2, -- 标识
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists      INT := 0;
    v_enable      VARCHAR2(8);
    v_id          VARCHAR2(128);
    v_num_start   INT;
    v_num_end     INT;
    v_num_count   INT;
    v_billcode    VARCHAR2(64);
    v_billorg     VARCHAR2(128);
    v_billlastnum INT;
    v_fromid      VARCHAR2(64);
    v_vtype       INT;
  BEGIN
    -- 加锁
    UPDATE info_template_bind t SET t.modifieddate = SYSDATE WHERE t.id = i_dtype;
  
    mydebug.wlog('i_dtype', i_dtype);
    mydebug.wlog('i_taskid', i_taskid);
  
    SELECT COUNT(1) INTO v_exists FROM info_template WHERE tempid = i_dtype;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT t.enable, t.billorg, t.billcode, t.billcount, t.billlastnum, t.vtype
      INTO v_enable, v_billorg, v_billcode, v_num_count, v_billlastnum, v_vtype
      FROM info_template t
     WHERE t.tempid = i_dtype;
  
    IF v_vtype = 1 THEN
      BEGIN
        SELECT t.id
          INTO v_fromid
          FROM data_qf2_yz_tmp t
         WHERE t.dtype = i_dtype
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
  
    IF v_billlastnum IS NULL THEN
      v_num_start := 1;
    ELSE
      v_num_start := v_billlastnum + 1;
    END IF;
  
    v_num_end := v_num_start + v_num_count - 1;
  
    v_id := pkg_basic.f_newid('FS');
  
    INSERT INTO data_yz_pz_tmp
      (id, taskid, dtype, fromid, num_start, num_end, num_count, billcode, billorg, operuri, opername)
    VALUES
      (v_id, i_taskid, i_dtype, v_fromid, v_num_start, v_num_end, v_num_count, v_billcode, v_billorg, 'system', 'system');
  
    UPDATE info_template t SET t.billlastnum = v_num_end WHERE t.tempid = i_dtype;
  
    o_id := v_id;
    mydebug.wlog('o_id', o_id);
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 增加入账凭证签发队列
  PROCEDURE p_add_qf_queue
  (
    i_id   IN VARCHAR2, -- 业务类型
    o_code OUT VARCHAR2, -- 操作结果:错误码
    o_msg  OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_otype    INT;
    v_douri    VARCHAR2(64);
    v_doname   VARCHAR2(128);
    v_docode   VARCHAR2(128);
    v_tempname VARCHAR2(200);
  
    v_yznum INT;
    v_dtype VARCHAR2(64);
  
    v_pz_billcode VARCHAR2(64); -- 票据编码
    v_pz_billorg  VARCHAR2(128); -- 印制机构
  
    v_task_id VARCHAR2(64);
  
    v_items         VARCHAR2(4000);
    v_templateform0 CLOB;
  BEGIN
    mydebug.wlog('i_id', i_id);
  
    SELECT t.dtype, otype, douri, doname, docode, t.yznum INTO v_dtype, v_otype, v_douri, v_doname, v_docode, v_yznum FROM data_qf2_task t WHERE t.id = i_id;
  
    SELECT tempname, billcode, billorg INTO v_tempname, v_pz_billcode, v_pz_billorg FROM info_template t WHERE t.tempid = v_dtype;
  
    INSERT INTO data_qf_book
      (id, dtype, otype, douri, doname, docode, backtype, status, booktype, operuri, opername)
    VALUES
      (i_id, v_dtype, v_otype, v_douri, v_doname, v_docode, '0', 'GG02', '3', 'system', 'system');
  
    INSERT INTO data_qf_pz
      (id, pid, dtype, num_start, num_end, num_count, billcode, billorg, operuri, opername)
    VALUES
      (i_id, i_id, v_dtype, v_yznum, v_yznum, 1, v_pz_billcode, v_pz_billorg, 'system', 'system');
  
    v_task_id := pkg_basic.f_newid('TK');
    INSERT INTO data_qf_task (id, pid, fromtype, opertype) VALUES (v_task_id, i_id, '3', '1');
  
    BEGIN
      SELECT t.templateform0 INTO v_templateform0 FROM info_template_attr t WHERE t.tempid = v_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_items := mystring.f_concat('<template name="', v_tempname, '" version="1.1">');
    v_items := mystring.f_concat(v_items, '<section>');
  
    DECLARE
      v_formid VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t.formid
          FROM info_template_form t
         WHERE t.tempid = v_dtype
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
        v_items := mystring.f_concat(v_items, '<item tag="CertNumber" type="text">');
        v_items := mystring.f_concat(v_items, '<value>', v_douri, '</value>');
        v_items := mystring.f_concat(v_items, '</item>');
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
  
    -- 增加自动签发队列
    pkg_qf_queue.p_add(i_id, o_code, o_msg);
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

  /***************************************************************************************************
  名称     : pkg_yz_pz_queue.p_file_add
  功能描述 : 印制-保存凭证文件
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-30  唐金鑫  创建
  
    <files>
         <file>
              <filetype></filetype>  <!-- 0：封面文件 2：凭证文件 -- >
              <filename></filename>
              <filepath></filepath>
         </file>
    </files>
  
  业务说明
  ***************************************************************************************************/
  PROCEDURE p_file_add
  (
    i_id    IN VARCHAR2, -- 票本标识
    i_files IN CLOB, -- 文件信息
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_taskid VARCHAR2(128);
    v_dtype  VARCHAR2(64);
    v_fromid VARCHAR2(64);
    v_vtype  INT;
  
    v_num_start INT;
    v_num_end   INT;
    v_num_count INT;
    v_billcode  VARCHAR2(64);
    v_billorg   VARCHAR2(128);
    v_operuri   VARCHAR2(64);
    v_opername  VARCHAR2(128);
  
    v_docid    VARCHAR2(64);
    v_fileid   VARCHAR2(64);
    v_filetype INT; -- 文件类型(0：封面文件 2：凭证文件)
    v_filename VARCHAR2(200); -- 文件名
    v_filepath VARCHAR2(2000); -- 文件路径
  
  BEGIN
    mydebug.wlog('i_id', i_id);
    mydebug.wlog('i_files', i_files);
  
    IF mystring.f_isnull(i_id) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF mystring.f_isnull(i_files) THEN
      o_code := 'EC02';
      o_msg  := '文件信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT taskid, dtype, fromid, num_start, num_end, num_count, billcode, billorg, operuri, opername
      INTO v_taskid, v_dtype, v_fromid, v_num_start, v_num_end, v_num_count, v_billcode, v_billorg, v_operuri, v_opername
      FROM data_yz_pz_tmp
     WHERE id = i_id;
  
    SELECT t.vtype INTO v_vtype FROM info_template t WHERE t.tempid = v_dtype;
  
    DECLARE
      v_xml   xmltype;
      v_i     INT := 0;
      v_xpath VARCHAR2(200);
    BEGIN
      v_xml := xmltype(i_files);
    
      v_i := 1;
      WHILE v_i <= 100 LOOP
        v_xpath := mystring.f_concat('/files/file[', v_i, ']/');
        SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, 'filetype')) INTO v_filetype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'filename')) INTO v_filename FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, 'filepath')) INTO v_filepath FROM dual;
        IF mystring.f_isnull(v_filename) THEN
          v_i := 100;
        ELSE
          IF v_vtype = 1 THEN
            v_docid := v_fromid;
          ELSE
            v_docid := i_id;
          END IF;
          pkg_file0.p_ins3(v_filename, v_filepath, 0, v_docid, v_filetype, 'system', 'system', v_fileid, o_code, o_msg);
          IF o_code <> 'EC00' THEN
            ROLLBACK;
            RETURN;
          END IF;
        END IF;
        v_i := v_i + 1;
      END LOOP;
    END;
  
    IF v_vtype = 1 THEN
      UPDATE data_qf2_task t SET t.startflag = 1, t.yzflag = 1, t.yzdate = SYSDATE, t.yznum = v_num_start WHERE t.id = v_fromid;
      DELETE FROM data_qf2_yz_tmp WHERE id = v_fromid;
    
      -- 增加签发队列
      pkg_yz_pz_queue.p_add_qf_queue(v_fromid, o_code, o_msg);
    ELSE
      -- 写入发布表    
      INSERT INTO data_yz_pz_pub
        (id, taskid, dtype, num_start, num_end, num_count, billcode, billorg, operuri, opername)
      VALUES
        (i_id, v_taskid, v_dtype, v_num_start, v_num_end, v_num_count, v_billcode, v_billorg, v_operuri, v_opername);
    
    END IF;
  
    DELETE FROM data_yz_pz_tmp WHERE id = i_id;
  
    UPDATE info_template_yz t SET t.num = t.num + 1, t.errtimes = 0, t.modifieddate = SYSDATE WHERE t.tempid = v_dtype;
  
    COMMIT;
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 出错后的处理
  PROCEDURE p_err
  (
    i_taskid IN VARCHAR2, -- 事务标识
    o_code   OUT VARCHAR2, -- 操作结果:错误码
    o_msg    OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id     VARCHAR2(64);
    v_dtype  VARCHAR2(64);
    v_fromid VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_taskid', i_taskid);
  
    o_code := 'EC00';
  
    DECLARE
      CURSOR v_cursor IS
        SELECT t.id, t.dtype, t.fromid FROM data_yz_pz_tmp t WHERE t.taskid = i_taskid;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id, v_dtype, v_fromid;
        EXIT WHEN v_cursor%NOTFOUND;
      
        UPDATE info_template_yz t SET t.errtimes = t.errtimes + 1, t.modifieddate = SYSDATE WHERE t.tempid = v_dtype;
      
        IF mystring.f_isnotnull(v_fromid) THEN
          UPDATE data_qf2_task t SET t.errtimes = t.errtimes + 1, t.modifieddate = SYSDATE WHERE t.id = v_fromid;
        END IF;
      
        DELETE FROM data_yz_pz_tmp WHERE id = v_id;
      
        -- 删除文件
        pkg_file0.p_del_docid(v_id, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          EXIT;
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
        ROLLBACK;
        o_code := 'EC03';
        o_msg  := '系统错误，请检查！';
        mydebug.err(7);
        RETURN;
    END;
  
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
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;
END;
/
