CREATE OR REPLACE PACKAGE pkg_yz_pz IS

  /***************************************************************************************************
  名称     : pkg_yz_pz
  功能描述 : 印制-空白凭证印制办理
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-30  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 查询印制需要的数据
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 增加
  PROCEDURE p_ins
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除
  PROCEDURE p_del
  (
    i_id    IN VARCHAR2, -- ID
    i_dtype IN VARCHAR2,
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  );

  -- 删除
  PROCEDURE p_del_ids
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 空白凭证的增加/删除/修改操作
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 保存凭证文件
  PROCEDURE p_file_add
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

  -- 凭证印制失败的操作
  PROCEDURE p_err
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_yz_pz IS

  -- 查询列表
  PROCEDURE p_getlist
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码  
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_row_rn        INT;
    v_row_id        VARCHAR2(64);
    v_row_dtype     VARCHAR2(64);
    v_row_role      VARCHAR2(64); -- 签发角色，调用凭证接口SetUserRole传入凭证
    v_row_evnum     VARCHAR2(64);
    v_row_booktime  DATE;
    v_row_filename  VARCHAR2(128);
    v_row_filepath  VARCHAR2(256);
    v_row_filename2 VARCHAR2(128);
  
    v_dtype        VARCHAR2(64);
    v_conditions   VARCHAR2(4000);
    v_cs_starttime VARCHAR2(200);
    v_cs_endtime   VARCHAR2(200);
  BEGIN
    mydebug.wlog('开始');
    -- 验证用户权限
    pkg_qp_verify.p_check('MD120', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      ROLLBACK;
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_dtype') INTO v_dtype FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/condition/others/starttime') INTO v_cs_starttime FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/endtime') INTO v_cs_endtime FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select createddate, id from data_yz_pz_pub E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.dtype = ''', v_dtype, '''');
  
    IF mystring.f_isnotnull(v_cs_starttime) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.createddate >= to_date(''', v_cs_starttime, ''', ''yyyy-mm-dd'')');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_endtime) THEN
      v_cs_endtime := mydate.f_addday_str(v_cs_endtime, 1);
    
      v_sql := mystring.f_concat(v_sql, ' AND E1.createddate < to_date(''', v_cs_endtime, ''', ''yyyy-mm-dd'')');
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY createddate desc,id desc');
    v_sql := myquery.f_getpagesql(v_sql, v_pagesize, v_pagenum);
    mydebug.wlog('v_sql', v_sql);
  
    -- 分页起始编号
    v_row_rn := myquery.f_getpagestartnum(v_pagesize, v_pagenum);
  
    -- 执行sql
    dbms_lob.createtemporary(o_info1, TRUE);
    dbms_lob.append(o_info1, '{');
    dbms_lob.append(o_info1, '"objContent":{');
    dbms_lob.append(o_info1, myquery.f_getpagenation(v_cnt, v_pagesize, v_pagenum));
    dbms_lob.append(o_info1, ',"dataList":[');
    DECLARE
      v_cursor SYS_REFCURSOR; -- 游标:查询返回的结果
    BEGIN
      OPEN v_cursor FOR v_sql;
      LOOP
        FETCH v_cursor
          INTO v_row_booktime, v_row_id;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT dtype, num_start INTO v_row_dtype, v_row_evnum FROM data_yz_pz_pub WHERE id = v_row_id;
      
        v_row_filename  := pkg_file0.f_getfilename_docid(v_row_id, 0);
        v_row_filepath  := pkg_file0.f_getfilepath_docid(v_row_id, 0);
        v_row_filename2 := pkg_file0.f_getfilename_docid(v_row_id, 2);
        v_row_role      := pkg_info_template_pbl.f_getrole(v_row_dtype);
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info1, ',');
        END IF;
        dbms_lob.append(o_info1, '{');
        dbms_lob.append(o_info1, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"id":"', v_row_id, '"'));
        dbms_lob.append(o_info1, ',"status":"VSA4"');
        dbms_lob.append(o_info1, mystring.f_concat(',"dtype":"', v_row_dtype, '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"role":"', v_row_role, '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"evnum":"', v_row_evnum, '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"booktime":"', to_char(v_row_booktime, 'yyyy-mm-dd hh24:mi:ss'), '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"filename":"', v_row_filename, '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"filepath":"', myjson.f_escape(v_row_filepath), '"'));
        dbms_lob.append(o_info1, mystring.f_concat(',"filename2":"', v_row_filename2, '"'));
        dbms_lob.append(o_info1, '}');
      
        IF mystring.f_isnull(o_info2) THEN
          IF mystring.f_isnotnull(v_row_filepath) AND mystring.f_isnotnull(v_row_filename) THEN
            o_info2 := '<info>';
            o_info2 := mystring.f_concat(o_info2, '<dlfiles>');
            o_info2 := mystring.f_concat(o_info2, '<file flag="iconimg_', v_row_dtype, '">', v_row_filepath, v_row_filename, '</file>');
            o_info2 := mystring.f_concat(o_info2, '</dlfiles>');
            o_info2 := mystring.f_concat(o_info2, '</info>');
          END IF;
        END IF;
      
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
    dbms_lob.append(o_info1, ']');
    dbms_lob.append(o_info1, '}');
    dbms_lob.append(o_info1, ',"code":"EC00"');
    dbms_lob.append(o_info1, ',"msg":"处理成功"');
    dbms_lob.append(o_info1, '}');
  
    mydebug.wlog('o_info1', o_info1);
    mydebug.wlog('o_info2', o_info2);
  
    -- 8.处理成功
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      o_info1 := NULL;
      o_info2 := NULL;
      o_code  := 'EC00';
      o_msg   := '处理成功';
      mydebug.err(7);
  END;

  -- 查询印制需要的数据
  PROCEDURE p_getinfo
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_id VARCHAR2(64);
  
    v_info           VARCHAR2(4000);
    v_info_dtype     VARCHAR2(64);
    v_info_dtypename VARCHAR2(128);
    v_info_role      VARCHAR2(64); -- 签发角色，调用凭证接口SetUserRole传入凭证
    v_info_evnum     VARCHAR2(64);
    v_info_mfname    VARCHAR2(200);
    v_info_mfname2   VARCHAR2(200);
    v_info_filename  VARCHAR2(200);
    v_info_filepath  VARCHAR2(512);
  
    v_data_master           VARCHAR2(128);
    v_data_issuemode        VARCHAR2(8);
    v_data_pickusage        VARCHAR2(512);
    v_data_customdata       VARCHAR2(4000);
    v_data_bases_code       VARCHAR2(64);
    v_data_bases_count      INT;
    v_data_bases_printedorg VARCHAR2(200);
  
    v_tempname  VARCHAR2(128);
    v_master    VARCHAR2(64);
    v_masternm  VARCHAR2(128);
    v_master1   VARCHAR2(64);
    v_masternm1 VARCHAR2(128);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.i_id') INTO v_id FROM dual;
    mydebug.wlog('v_id', v_id);
  
    SELECT dtype, num_start INTO v_info_dtype, v_info_evnum FROM data_yz_pz_pub t WHERE t.id = v_id;
  
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
    v_info_filename  := pkg_file0.f_getfilename_docid(v_id, 2);
    v_info_filepath  := pkg_file0.f_getfilepath_docid(v_id, 2);
    v_info_role      := pkg_info_template_pbl.f_getrole(v_info_dtype);
  
    v_info := '<info>';
    v_info := mystring.f_concat(v_info, '<id>', v_id, '</id>');
    v_info := mystring.f_concat(v_info, '<evtype>', v_info_dtype, '</evtype>');
    v_info := mystring.f_concat(v_info, '<evtypename>', v_info_dtypename, '</evtypename>');
    v_info := mystring.f_concat(v_info, '<role>', v_info_role, '</role>');
    v_info := mystring.f_concat(v_info, '<evnum>', v_info_evnum, '</evnum>');
    v_info := mystring.f_concat(v_info, '<mfname>', v_info_mfname, '</mfname>');
    v_info := mystring.f_concat(v_info, '<mfname2>', v_info_mfname2, '</mfname2>');
    v_info := mystring.f_concat(v_info, '<filename>', v_info_filename, '</filename>');
    v_info := mystring.f_concat(v_info, '<filepath>', v_info_filepath, '</filepath>');
    v_info := mystring.f_concat(v_info, '</info>');
  
    dbms_lob.createtemporary(o_info1, TRUE);
    dbms_lob.append(o_info1, '{');
    dbms_lob.append(o_info1, mystring.f_concat(' "id":"', v_id, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"i_id":"', v_id, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"uniqueId":"', v_id, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"evtype":"', v_info_dtype, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"evtypename":"', v_info_dtypename, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"role":"', v_info_role, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"evnum":"', v_info_evnum, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"mfname":"', v_info_mfname, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"mfname2":"', v_info_mfname2, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"filename":"', v_info_filename, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"filepath":"', myjson.f_escape(v_info_filepath), '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"o_info":"', myjson.f_escape(v_info), '"'));
    dbms_lob.append(o_info1, ',"o_data":"');
  
    -- 传入印制接口的参数
    SELECT tempname, master, masternm, master1, masternm1, mtype, billcode, billcount, billorg
      INTO v_tempname, v_master, v_masternm, v_master1, v_masternm1, v_data_issuemode, v_data_bases_code, v_data_bases_count, v_data_bases_printedorg
      FROM info_template t
     WHERE t.tempid = v_info_dtype;
  
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
  
    BEGIN
      SELECT pickusage, attr INTO v_data_pickusage, v_data_customdata FROM info_template_attr t WHERE t.tempid = v_info_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF mystring.f_isnotnull(v_data_pickusage) THEN
      v_data_pickusage := mybase64.f_str_decode(v_data_pickusage);
    END IF;
    IF mystring.f_isnotnull(v_data_customdata) THEN
      v_data_customdata := mybase64.f_str_encode(v_data_customdata);
    END IF;
  
    dbms_lob.append(o_info1, '<data>');
    dbms_lob.append(o_info1, '<infos>');
    dbms_lob.append(o_info1, mystring.f_concat('<info key=\"Type\">', v_info_dtype, ',', v_tempname, '</info>'));
    dbms_lob.append(o_info1, mystring.f_concat('<info key=\"Master\">', v_data_master, '</info>'));
    dbms_lob.append(o_info1, mystring.f_concat('<info key=\"IssueMode\">', v_data_issuemode, '</info>'));
    dbms_lob.append(o_info1, mystring.f_concat('<info key=\"PickUsage\">', myjson.f_escape(v_data_pickusage), '</info>'));
    dbms_lob.append(o_info1, mystring.f_concat('<info key=\"CustomData\">', myjson.f_escape(v_data_customdata), '</info>'));
    dbms_lob.append(o_info1, '</infos>');
    dbms_lob.append(o_info1, '<bases>');
    dbms_lob.append(o_info1, mystring.f_concat('<item tag=\"Code\"><value>', v_data_bases_code, '</value></item>'));
    dbms_lob.append(o_info1, mystring.f_concat('<item tag=\"Number\"><value>', v_info_evnum, '</value></item>'));
    dbms_lob.append(o_info1, mystring.f_concat('<item tag=\"Count\"><value>', v_data_bases_count, '</value></item>'));
    dbms_lob.append(o_info1, mystring.f_concat('<item tag=\"PrintedOrg\"><value>', v_data_bases_printedorg, '</value></item>'));
    dbms_lob.append(o_info1, '</bases>');
  
    DECLARE
      v_sectioncode VARCHAR2(64);
      v_items2      CLOB;
      v_files       CLOB;
      CURSOR v_cursor IS
        SELECT t.sectioncode, t.items2, t.files
          FROM info_template_prvdata t
         WHERE t.tempid = v_info_dtype
           AND t.datatype = '1';
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_sectioncode, v_items2, v_files;
        EXIT WHEN v_cursor%NOTFOUND;
        IF mystring.f_isnotnull(v_items2) OR mystring.f_isnotnull(v_files) THEN
          IF mystring.f_isnull(v_sectioncode) THEN
            dbms_lob.append(o_info1, '<section>');
          ELSE
            dbms_lob.append(o_info1, mystring.f_concat('<section code=\"', v_sectioncode, '\">'));
          END IF;
          IF mystring.f_isnotnull(v_items2) THEN
            dbms_lob.append(o_info1, myjson.f_escape(v_items2));
          END IF;
          IF mystring.f_isnotnull(v_files) THEN
            dbms_lob.append(o_info1, myjson.f_escape(v_files));
          END IF;
          dbms_lob.append(o_info1, '</section>');
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
  
    dbms_lob.append(o_info1, '<seals>');
  
    DECLARE
      v_code     VARCHAR2(64);
      v_name     VARCHAR2(128);
      v_sealpin  VARCHAR2(64);
      v_sealpack CLOB;
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
          INTO v_code, v_name, v_sealpin, v_sealpack;
        EXIT WHEN v_cursor%NOTFOUND;
        IF mystring.f_isnotnull(v_sealpack) THEN
          dbms_lob.append(o_info1, mystring.f_concat('<item label=\"', v_code, '\">'));
          dbms_lob.append(o_info1, mystring.f_concat('<seal name=\"', v_name, '\"'));
          dbms_lob.append(o_info1, ' pin=\"\">');
          dbms_lob.append(o_info1, '<pack>');
          dbms_lob.append(o_info1, v_sealpack);
          dbms_lob.append(o_info1, '</pack> ');
          dbms_lob.append(o_info1, '</seal>');
          dbms_lob.append(o_info1, '</item>');
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
  
    dbms_lob.append(o_info1, '</seals>');
    dbms_lob.append(o_info1, '</data>');
  
    dbms_lob.append(o_info1, '"');
    dbms_lob.append(o_info1, ',"code":"EC00"');
    dbms_lob.append(o_info1, ',"msg":"处理成功"');
    dbms_lob.append(o_info1, '}');
  
    o_info2 := '<info>';
    o_info2 := mystring.f_concat(o_info2, '<dlfiles>');
    o_info2 := mystring.f_concat(o_info2, '<file flag="datafile">', v_info_filepath, v_info_filename, '</file>');
    o_info2 := mystring.f_concat(o_info2, '</dlfiles>');
    o_info2 := mystring.f_concat(o_info2, '</info>');
  
    mydebug.wlog('o_info1', o_info1);
    mydebug.wlog('o_info2', o_info2);
  
    o_code := 'EC00';
    o_msg  := '处理成功';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      -- 异常处理
      o_info1 := NULL;
      o_info2 := NULL;
      o_code  := 'EC03';
      o_msg   := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 增加
  PROCEDURE p_ins
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists        INT := 0;
    v_dtype         VARCHAR2(64);
    v_taskid        VARCHAR2(64);
    v_temp_enable   VARCHAR2(8);
    v_temp_filepath VARCHAR2(512);
  
    v_id          VARCHAR2(128);
    v_num_start   INT;
    v_num_end     INT;
    v_num_count   INT;
    v_billcode    VARCHAR2(64);
    v_billorg     VARCHAR2(128);
    v_billlastnum INT;
  
    v_info_dtypename VARCHAR2(128);
    v_info_role      VARCHAR2(64);
    v_info_mfname    VARCHAR2(200);
    v_info_mfname2   VARCHAR2(200);
    v_info_tempfile  VARCHAR2(512);
    v_info_tempfile2 VARCHAR2(512);
  
    v_data_master           VARCHAR2(128);
    v_data_issuemode        VARCHAR2(8);
    v_data_pickusage        VARCHAR2(512);
    v_data_customdata       VARCHAR2(4000);
    v_data_bases_code       VARCHAR2(64);
    v_data_bases_count      INT;
    v_data_bases_printedorg VARCHAR2(200);
  
    v_tempname  VARCHAR2(128);
    v_master    VARCHAR2(64);
    v_masternm  VARCHAR2(128);
    v_master1   VARCHAR2(64);
    v_masternm1 VARCHAR2(128);
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
    SELECT json_value(i_forminfo, '$.i_taskid') INTO v_taskid FROM dual;
    mydebug.wlog('v_dtype', v_dtype);
    mydebug.wlog('v_taskid', v_taskid);
  
    SELECT COUNT(1) INTO v_exists FROM info_template WHERE tempid = v_dtype;
    IF v_exists = 0 THEN
      o_code := 'EC02';
      o_msg  := '查询数据出错,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT t.enable, t.billorg, t.billcode, t.billcount, t.billlastnum
      INTO v_temp_enable, v_billorg, v_billcode, v_num_count, v_billlastnum
      FROM info_template t
     WHERE t.tempid = v_dtype;
  
    IF v_temp_enable = '0' THEN
      o_code := 'EC02';
      o_msg  := '凭证未启用,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    IF v_billlastnum IS NULL THEN
      v_num_start := 1;
    ELSE
      v_num_start := v_billlastnum + 1;
    END IF;
  
    v_num_end := v_num_start + v_num_count - 1;
  
    v_id := pkg_basic.f_newid('FS');
  
    INSERT INTO data_yz_pz_tmp
      (id, taskid, dtype, num_start, num_end, num_count, billcode, billorg, operuri, opername)
    VALUES
      (v_id, v_taskid, v_dtype, v_num_start, v_num_end, v_num_count, v_billcode, v_billorg, i_operuri, i_opername);
  
    UPDATE info_template t SET t.billlastnum = v_num_end WHERE t.tempid = v_dtype;
  
    v_temp_filepath := pkg_info_template_pbl.f_getfilepath(v_dtype);
    DECLARE
      v_fileid1 VARCHAR2(64);
      v_fileid2 VARCHAR2(64);
    BEGIN
      SELECT fileid1, fileid2 INTO v_fileid1, v_fileid2 FROM info_template_file t WHERE t.code = v_dtype;
      v_info_mfname    := pkg_file0.f_getfilename(v_fileid1);
      v_info_mfname2   := pkg_file0.f_getfilename(v_fileid2);
      v_info_tempfile  := mystring.f_concat(v_temp_filepath, v_info_mfname);
      v_info_tempfile2 := mystring.f_concat(v_temp_filepath, v_info_mfname2);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_info_dtypename := pkg_info_template_pbl.f_gettempname(v_dtype);
    v_info_role      := pkg_info_template_pbl.f_getrole(v_dtype);
  
    dbms_lob.createtemporary(o_info1, TRUE);
    dbms_lob.append(o_info1, '{');
    dbms_lob.append(o_info1, mystring.f_concat(' "tempContent":"', v_id, '"'));
    dbms_lob.append(o_info1, ',"objContent":{');
    dbms_lob.append(o_info1, mystring.f_concat(' "id":"', v_id, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"evtype":"', v_dtype, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"evtypename":"', v_info_dtypename, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"role":"', v_info_role, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"evnum":"', v_num_start, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"mfname":"', v_info_mfname, '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"mfname2":"', v_info_mfname2, '"'));
    dbms_lob.append(o_info1, ',"filename":""');
    dbms_lob.append(o_info1, ',"filepath":""');
    dbms_lob.append(o_info1, mystring.f_concat(',"tempfile":"', myjson.f_escape(v_info_tempfile), '"'));
    dbms_lob.append(o_info1, mystring.f_concat(',"tempfile2":"', myjson.f_escape(v_info_tempfile2), '"'));
    dbms_lob.append(o_info1, ',"deptname":""');
    dbms_lob.append(o_info1, mystring.f_concat(',"printdate":"', to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'), '"'));
    dbms_lob.append(o_info1, ',"printdata":"');
  
    -- 传入印制接口的参数
    SELECT tempname, master, masternm, master1, masternm1, mtype, billcode, billcount, billorg
      INTO v_tempname, v_master, v_masternm, v_master1, v_masternm1, v_data_issuemode, v_data_bases_code, v_data_bases_count, v_data_bases_printedorg
      FROM info_template t
     WHERE t.tempid = v_dtype;
  
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
  
    BEGIN
      SELECT pickusage, attr INTO v_data_pickusage, v_data_customdata FROM info_template_attr t WHERE t.tempid = v_dtype;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    IF mystring.f_isnotnull(v_data_pickusage) THEN
      v_data_pickusage := mybase64.f_str_decode(v_data_pickusage);
    END IF;
    IF mystring.f_isnotnull(v_data_customdata) THEN
      v_data_customdata := mybase64.f_str_encode(v_data_customdata);
    END IF;
  
    dbms_lob.append(o_info1, '<data>');
    dbms_lob.append(o_info1, '<infos>');
    dbms_lob.append(o_info1, mystring.f_concat('<info key=\"Type\">', v_dtype, ',', v_tempname, '</info>'));
    dbms_lob.append(o_info1, mystring.f_concat('<info key=\"Master\">', v_data_master, '</info>'));
    dbms_lob.append(o_info1, mystring.f_concat('<info key=\"IssueMode\">', v_data_issuemode, '</info>'));
    dbms_lob.append(o_info1, mystring.f_concat('<info key=\"PickUsage\">', myjson.f_escape(v_data_pickusage), '</info>'));
    dbms_lob.append(o_info1, mystring.f_concat('<info key=\"CustomData\">', myjson.f_escape(v_data_customdata), '</info>'));
    dbms_lob.append(o_info1, '</infos>');
    dbms_lob.append(o_info1, '<bases>');
    dbms_lob.append(o_info1, mystring.f_concat('<item tag=\"Code\"><value>', v_data_bases_code, '</value></item>'));
    dbms_lob.append(o_info1, mystring.f_concat('<item tag=\"Number\"><value>', v_num_start, '</value></item>'));
    dbms_lob.append(o_info1, mystring.f_concat('<item tag=\"Count\"><value>', v_data_bases_count, '</value></item>'));
    dbms_lob.append(o_info1, mystring.f_concat('<item tag=\"PrintedOrg\"><value>', v_data_bases_printedorg, '</value></item>'));
    dbms_lob.append(o_info1, '</bases>');
  
    DECLARE
      v_sectioncode VARCHAR2(64);
      v_items2      CLOB;
      v_files       CLOB;
      CURSOR v_cursor IS
        SELECT t.sectioncode, t.items2, t.files
          FROM info_template_prvdata t
         WHERE t.tempid = v_dtype
           AND t.datatype = '1';
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_sectioncode, v_items2, v_files;
        EXIT WHEN v_cursor%NOTFOUND;
        IF mystring.f_isnotnull(v_items2) OR mystring.f_isnotnull(v_files) THEN
          IF mystring.f_isnull(v_sectioncode) THEN
            dbms_lob.append(o_info1, '<section>');
          ELSE
            dbms_lob.append(o_info1, mystring.f_concat('<section code=\"', v_sectioncode, '\">'));
          END IF;
          IF mystring.f_isnotnull(v_items2) THEN
            dbms_lob.append(o_info1, myjson.f_escape(v_items2));
          END IF;
          IF mystring.f_isnotnull(v_files) THEN
            dbms_lob.append(o_info1, myjson.f_escape(v_files));
          END IF;
          dbms_lob.append(o_info1, '</section>');
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
  
    dbms_lob.append(o_info1, '<seals>');
  
    DECLARE
      v_code     VARCHAR2(64);
      v_name     VARCHAR2(128);
      v_sealpin  VARCHAR2(64);
      v_sealpack CLOB;
      CURSOR v_cursor IS
        SELECT t.code, t.name, t.sealpin, t.sealpack
          FROM info_template_seal t
         WHERE t.tempid = v_dtype
           AND t.sealtype = 'print'
         ORDER BY t.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_code, v_name, v_sealpin, v_sealpack;
        EXIT WHEN v_cursor%NOTFOUND;
        IF mystring.f_isnotnull(v_sealpack) THEN
          dbms_lob.append(o_info1, mystring.f_concat('<item label=\"', v_code, '\">'));
          dbms_lob.append(o_info1, mystring.f_concat('<seal name=\"', v_name, '\"'));
          dbms_lob.append(o_info1, ' pin=\"\">');
          dbms_lob.append(o_info1, '<pack>');
          dbms_lob.append(o_info1, v_sealpack);
          dbms_lob.append(o_info1, '</pack> ');
          dbms_lob.append(o_info1, '</seal>');
          dbms_lob.append(o_info1, '</item>');
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
  
    dbms_lob.append(o_info1, '</seals>');
    dbms_lob.append(o_info1, '</data>');
  
    dbms_lob.append(o_info1, '"');
    dbms_lob.append(o_info1, '}');
    dbms_lob.append(o_info1, ',"code":"EC00"');
    dbms_lob.append(o_info1, mystring.f_concat(',"msg":"', v_id, '"'));
    dbms_lob.append(o_info1, '}');
  
    o_info2 := '<info>';
    o_info2 := mystring.f_concat(o_info2, '<dlfiles>');
    o_info2 := mystring.f_concat(o_info2, '<file flag="tmplfile">', v_info_tempfile, '</file>');
    o_info2 := mystring.f_concat(o_info2, '<file flag="iconfile">', v_info_tempfile2, '</file>');
    o_info2 := mystring.f_concat(o_info2, '</dlfiles>');
    o_info2 := mystring.f_concat(o_info2, '</info>');
  
    mydebug.wlog('o_info1', o_info1);
    mydebug.wlog('o_info2', o_info2);
  
    COMMIT;
  
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_info1 := NULL;
      o_info2 := NULL;
      o_code  := 'EC03';
      o_msg   := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 删除
  PROCEDURE p_del
  (
    i_id    IN VARCHAR2, -- ID
    i_dtype IN VARCHAR2,
    o_code  OUT VARCHAR2, -- 操作结果:错误码
    o_msg   OUT VARCHAR2 -- 成功/错误原因
  ) AS
  BEGIN
    -- 加锁
    UPDATE info_template_bind t SET t.modifieddate = SYSDATE WHERE t.id = i_dtype;
  
    mydebug.wlog('i_id', i_id);
  
    DELETE FROM data_yz_pz_tmp WHERE id = i_id;
    DELETE FROM data_yz_pz_pub WHERE id = i_id;
  
    -- 删除文件
    pkg_file0.p_del_docid(i_id, o_code, o_msg);
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

  -- 删除
  PROCEDURE p_del_ids
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_data  VARCHAR2(4000);
    v_id    VARCHAR2(64);
    v_xml   xmltype;
    v_i     INT := 0;
    v_dtype VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    -- 验证用户权限
    pkg_qp_verify.p_check('MD120', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.selectData') INTO v_data FROM dual;
    mydebug.wlog('v_data', v_data);
  
    IF mystring.f_isnull(v_data) THEN
      o_code := 'EC02';
      o_msg  := 'ID为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_xml := xmltype(v_data);
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat('/selectData/data[', v_i, ']/id')) INTO v_id FROM dual;
      IF mystring.f_isnull(v_id) THEN
        v_i := 100;
      ELSE
      
        v_dtype := '';
        BEGIN
          SELECT dtype INTO v_dtype FROM data_yz_pz_pub t WHERE t.id = v_id;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        pkg_yz_pz.p_del(v_id, v_dtype, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          RETURN;
        END IF;
      END IF;
      v_i := v_i + 1;
    END LOOP;
  
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  -- 空白凭证的增加/删除/修改操作
  PROCEDURE p_oper
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_info1    OUT CLOB, -- 返回信息集合(前台)
    o_info2    OUT VARCHAR2, -- 返回信息集合(后台)
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_type VARCHAR2(64);
  BEGIN
    SELECT json_value(i_forminfo, '$.i_type') INTO v_type FROM dual;
    mydebug.wlog('v_type', v_type);
  
    IF v_type = '1' THEN
      pkg_yz_pz.p_ins(i_forminfo, i_operuri, i_opername, o_info1, o_info2, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    ELSIF v_type = '0' THEN
      pkg_yz_pz.p_del_ids(i_forminfo, i_operuri, i_opername, o_code, o_msg);
      IF o_code <> 'EC00' THEN
        ROLLBACK;
        RETURN;
      END IF;
    END IF;
  
    o_code := 'EC00';
    o_msg  := '处理成功。';
    mydebug.wlog(1, o_code, o_msg);
  EXCEPTION
    WHEN OTHERS THEN
      o_code := 'EC03';
      o_msg  := '系统错误，请检查！';
      mydebug.err(7);
  END;

  /***************************************************************************************************
  名称     : pkg_yz_pz.p_file_add
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
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_files VARCHAR2(32767);
    v_xml   xmltype;
    v_i     INT := 0;
    v_xpath VARCHAR2(200);
  
    v_id        VARCHAR2(64);
    v_taskid    VARCHAR2(128);
    v_dtype     VARCHAR2(64);
    v_num_start INT;
    v_num_end   INT;
    v_num_count INT;
    v_billcode  VARCHAR2(64);
    v_billorg   VARCHAR2(128);
    v_operuri   VARCHAR2(64);
    v_opername  VARCHAR2(128);
  
    v_filename VARCHAR2(200); -- 文件名
    v_filepath VARCHAR2(2000); -- 文件路径  
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    IF mystring.f_isnull(i_operuri) OR mystring.f_isnull(i_opername) THEN
      o_code := 'EC02';
      o_msg  := '操作人为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.i_files' RETURNING VARCHAR2(32767)) INTO v_files FROM dual;
    mydebug.wlog('v_files', v_files);
  
    IF mystring.f_isnull(v_files) THEN
      o_code := 'EC02';
      o_msg  := '文件信息为空,请检查！';
      mydebug.wlog(3, o_code, o_msg);
      RETURN;
    END IF;
  
    v_xml := xmltype(v_files);
    v_i   := 1;
    WHILE v_i <= 100 LOOP
      v_xpath := mystring.f_concat('/files/data[', v_i, ']/');
      SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@uniqueId')) INTO v_id FROM dual;
      IF mystring.f_isnull(v_id) THEN
        v_i := 100;
      ELSE
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '/file[filetype="0"]/filename')) INTO v_filename FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '/file[filetype="0"]/filepath')) INTO v_filepath FROM dual;
        pkg_file0.p_ins2(v_filename, v_filepath, 0, v_id, 0, i_operuri, i_opername, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          RETURN;
        END IF;
      
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '/file[filetype="2"]/filename')) INTO v_filename FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '/file[filetype="2"]/filepath')) INTO v_filepath FROM dual;
        pkg_file0.p_ins2(v_filename, v_filepath, 0, v_id, 2, i_operuri, i_opername, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          RETURN;
        END IF;
      
        -- 写入发布表
        SELECT taskid, dtype, num_start, num_end, num_count, billcode, billorg, operuri, opername
          INTO v_taskid, v_dtype, v_num_start, v_num_end, v_num_count, v_billcode, v_billorg, v_operuri, v_opername
          FROM data_yz_pz_tmp
         WHERE id = v_id;
        INSERT INTO data_yz_pz_pub
          (id, taskid, dtype, num_start, num_end, num_count, billcode, billorg, operuri, opername)
        VALUES
          (v_id, v_taskid, v_dtype, v_num_start, v_num_end, v_num_count, v_billcode, v_billorg, v_operuri, v_opername);
      
        DELETE FROM data_yz_pz_tmp WHERE id = v_id;
      END IF;
      v_i := v_i + 1;
    END LOOP;
  
    UPDATE info_template t SET t.yzdate = SYSDATE WHERE t.tempid = v_dtype;
  
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

  -- 凭证印制失败的操作
  PROCEDURE p_err
  (
    i_forminfo IN CLOB, -- 表单信息(前台请求)
    i_operuri  IN VARCHAR2, -- 操作人URI
    i_opername IN VARCHAR2, -- 操作人姓名
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_taskid VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_operuri', i_operuri);
    mydebug.wlog('i_opername', i_opername);
  
    SELECT json_value(i_forminfo, '$.i_taskid') INTO v_taskid FROM dual;
    mydebug.wlog('v_taskid', v_taskid);
  
    o_code := 'EC00';
    DECLARE
      v_id VARCHAR2(64);
      CURSOR v_cursor IS
        SELECT t.id FROM data_yz_pz_tmp t WHERE t.taskid = v_taskid;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_id;
        EXIT WHEN v_cursor%NOTFOUND;
      
        DELETE FROM data_yz_pz_tmp WHERE id = v_id;
        DELETE FROM data_yz_pz_pub WHERE id = v_id;
        pkg_file0.p_del_docid(v_id, o_code, o_msg);
        IF o_code <> 'EC00' THEN
          EXIT;
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
