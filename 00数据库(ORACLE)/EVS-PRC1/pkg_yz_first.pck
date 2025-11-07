CREATE OR REPLACE PACKAGE pkg_yz_first IS

  /***************************************************************************************************
  名称     : pkg_yz_first
  功能描述 : 空白凭证印制-首页
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-01-07  唐金鑫  创建
  
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
CREATE OR REPLACE PACKAGE BODY pkg_yz_first IS
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
    v_tempauthtype INT := pkg_info_template_pbl.f_getauthtype;
    v_comid        VARCHAR2(64) := pkg_basic.f_getcomid;
    v_comname      VARCHAR2(128) := pkg_basic.f_getcomname; -- 签发单位名称
  
    v_sql      VARCHAR2(8000); -- 查询语句
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码  
    v_cnt      INT := 0;
    v_num      INT := 0;
  
    v_row_rn        INT;
    v_row_tempid    VARCHAR2(64);
    v_row_name      VARCHAR2(128);
    v_row_pcode     VARCHAR2(64);
    v_row_pname     VARCHAR2(128);
    v_row_otype     INT;
    v_row_ywtype    VARCHAR2(8);
    v_row_usetype   VARCHAR2(8); -- 签发类型(印签/印制)
    v_row_ycnum     INT;
    v_row_sjnum     INT;
    v_row_dbnum     INT; -- 申领量
    v_row_slnum     INT;
    v_row_qfflag    INT;
    v_row_yzflag1   INT; -- 是否可印制(1:是 0:否)
    v_row_yzflag2   INT;
    v_row_yztype    VARCHAR2(8); -- 申领分发方式(1:自动 0:手工)
    v_row_covertype VARCHAR2(16);
    v_row_sort      INT;
  
    v_otype      VARCHAR2(64);
    v_conditions VARCHAR2(4000);
    v_cs_name    VARCHAR2(200);
    v_cs_yztype  VARCHAR2(8);
    v_cs_dbnum   VARCHAR2(8);
  BEGIN
    mydebug.wlog('开始');
    -- 验证用户权限
    pkg_qp_verify.p_check('MD120', i_operuri, i_opername, o_code, o_msg);
    IF o_code <> 'EC00' THEN
      RETURN;
    END IF;
  
    SELECT json_value(i_forminfo, '$.perPageCount') INTO v_pagesize FROM dual;
    SELECT json_value(i_forminfo, '$.currPage') INTO v_pagenum FROM dual;
    SELECT json_value(i_forminfo, '$.i_fr') INTO v_otype FROM dual;
    SELECT json_value(i_forminfo, '$.i_conditions') INTO v_conditions FROM dual;
  
    -- 解析查询条件
    DECLARE
      v_xml xmltype;
    BEGIN
      IF mystring.f_isnotnull(v_conditions) THEN
        v_xml := xmltype(v_conditions);
        SELECT myxml.f_getvalue(v_xml, '/condition/others/name') INTO v_cs_name FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/yztype') INTO v_cs_yztype FROM dual;
        SELECT myxml.f_getvalue(v_xml, '/condition/others/dbnum') INTO v_cs_dbnum FROM dual;
      END IF;
    END;
  
    -- 制作sql
    v_sql := 'select sort,tempid from info_template E1';
    v_sql := mystring.f_concat(v_sql, ' WHERE E1.enable = ''1''');
    v_sql := mystring.f_concat(v_sql, ' AND E1.bindstatus = 1');
    v_sql := mystring.f_concat(v_sql, ' AND E1.yzflag = 1');
    v_sql := mystring.f_concat(v_sql, ' AND E1.otype = ''', v_otype, '''');
  
    IF v_tempauthtype = 1 THEN
      v_sql := mystring.f_concat(v_sql, ' AND exists (SELECT 1 FROM info_admin_auth w WHERE w.useruri =''', i_operuri, ''' AND w.dtype = E1.tempid) ');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_name) THEN
      v_sql := mystring.f_concat(v_sql, ' AND instr(E1.tempname, ''', v_cs_name, ''') > 0');
    END IF;
  
    IF mystring.f_isnotnull(v_cs_yztype) THEN
      v_sql := mystring.f_concat(v_sql, ' AND E1.yzfftype = ', v_cs_yztype);
    END IF;
  
    IF mystring.f_isnotnull(v_cs_dbnum) THEN
      IF v_cs_dbnum = '1' THEN
        v_sql := mystring.f_concat(v_sql, ' AND EXISTS (SELECT 1 FROM data_yz_sq_book w');
        v_sql := mystring.f_concat(v_sql, ' WHERE w.dtype = E1.tempid)');
      ELSE
        v_sql := mystring.f_concat(v_sql, ' AND NOT EXISTS (SELECT 1 FROM data_yz_sq_book w');
        v_sql := mystring.f_concat(v_sql, ' WHERE w.dtype = E1.tempid)');
      END IF;
    END IF;
  
    -- 计算总数
    myquery.p_getcountfromsql(v_sql, v_cnt);
  
    -- 处理分页SQL  
    v_sql := mystring.f_concat(v_sql, ' ORDER BY sort,tempid');
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
          INTO v_row_sort, v_row_tempid;
        EXIT WHEN v_cursor%NOTFOUND;
      
        SELECT tempname, pdtype, covertype, qfflag, yzflag1, yzflag2, yzfftype, yzautostock, otype
          INTO v_row_name, v_row_pcode, v_row_covertype, v_row_qfflag, v_row_yzflag1, v_row_yzflag2, v_row_yztype, v_row_ycnum, v_row_otype
          FROM info_template
         WHERE tempid = v_row_tempid;
      
        IF v_row_covertype = 'CoverType01' THEN
          v_row_ywtype := 0;
        ELSIF v_row_covertype = 'CoverType02' THEN
          v_row_ywtype := 1;
        ELSIF v_row_covertype = 'CoverType03' THEN
          v_row_ywtype := 2;
        ELSE
          v_row_ywtype := 0;
        END IF;
      
        -- 签发类型(印签/印制)
        IF v_row_qfflag = 1 THEN
          v_row_usetype := '印签';
        ELSE
          IF v_row_yzflag1 = 1 AND v_row_yzflag2 = 1 THEN
            v_row_usetype := '印制';
          ELSE
            v_row_usetype := '分发';
          END IF;
        END IF;
      
        -- 预存量
        IF v_row_ycnum IS NULL THEN
          v_row_ycnum := 0;
        END IF;
      
        -- 实存量
        SELECT COUNT(1) INTO v_row_sjnum FROM data_yz_pz_pub t WHERE t.dtype = v_row_tempid;
      
        -- 申领待分配量
        SELECT COUNT(1)
          INTO v_row_dbnum
          FROM data_yz_sq_book t2
         WHERE t2.dtype = v_row_tempid
           AND t2.status = 'VSB1';
      
        -- 申领量
        SELECT SUM(t2.booknum) INTO v_row_slnum FROM data_yz_sq_book t2 WHERE t2.dtype = v_row_tempid;
      
        v_row_pname := pkg_info_template_pbl.f_mktypename(v_row_pcode);
      
        v_num := v_num + 1;
        IF v_num > 1 THEN
          dbms_lob.append(o_info, ',');
        END IF;
        dbms_lob.append(o_info, '{');
        dbms_lob.append(o_info, mystring.f_concat(' "rn":"', v_row_rn, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"id":"', v_comid, '_', v_row_tempid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"code":"', v_row_tempid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"name":"', v_row_name, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"comid":"', v_comid, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"comname":"', v_comname, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"pcode":"', v_row_pcode, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"pname":"', v_row_pname, '"'));
        dbms_lob.append(o_info, ',"subnum":"1"');
        dbms_lob.append(o_info, mystring.f_concat(',"otype":"', v_row_otype, '"'));
        dbms_lob.append(o_info, ',"mflag":"0"');
        dbms_lob.append(o_info, mystring.f_concat(',"ywtype":"', v_row_ywtype, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"usetype":"', v_row_usetype, '"'));
        dbms_lob.append(o_info, ',"comtype":"0"');
        dbms_lob.append(o_info, ',"yztype":"0"');
        dbms_lob.append(o_info, mystring.f_concat(',"ycnum":"', v_row_ycnum, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"sjnum":"', v_row_sjnum, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"dbnum":"', v_row_dbnum, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"slnum":"', v_row_slnum, '"'));
        dbms_lob.append(o_info, ',"dwnum":"0"');
        dbms_lob.append(o_info, ',"appnum":"0"');
        dbms_lob.append(o_info, mystring.f_concat(',"yzflag1":"', v_row_yzflag1, '"'));
        dbms_lob.append(o_info, mystring.f_concat(',"yztype":"', v_row_yztype, '"'));
        dbms_lob.append(o_info, '}');
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

END;
/
