CREATE OR REPLACE PACKAGE pkg_info_template_er_ywcode IS

  /***************************************************************************************************
  名称     : pkg_info_template_er_ywcode
  功能描述 : 凭证参数维护-通过交换接收数据
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2022-12-29  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询凭证分类排序
  FUNCTION f_getmktypesort(i_code VARCHAR2) RETURN INT;

  -- 查询凭证类型是否可用(1:是 0:否)
  FUNCTION f_getbindstatus(i_code VARCHAR2) RETURN INT;

  -- 查询凭证类型是否支持印制(1:是 0:否)
  FUNCTION f_getyzflag(i_code VARCHAR2) RETURN INT;

  -- 查询凭证类型是否支持签发(1:是 0:否)
  FUNCTION f_getqfflag(i_code VARCHAR2) RETURN INT;

  -- 接收凭证类型
  PROCEDURE p_receive
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );

END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_template_er_ywcode IS

  -- 查询凭证分类排序
  FUNCTION f_getmktypesort(i_code VARCHAR2) RETURN INT AS
    v_result INT;
  BEGIN
    SELECT t.sort INTO v_result FROM info_mktype t WHERE t.code = i_code;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 查询凭证类型是否可用(1:是 0:否)
  FUNCTION f_getbindstatus(i_code VARCHAR2) RETURN INT AS
    v_exists INT := 0;
  BEGIN
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_template_bind t WHERE t.id = i_code);
    IF v_exists > 0 THEN
      RETURN 1;
    END IF;
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 查询凭证类型是否支持印制(1:是 0:否)
  FUNCTION f_getyzflag(i_code VARCHAR2) RETURN INT AS
    v_exists INT := 0;
  BEGIN
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_template_bind t
             WHERE t.id = i_code
               AND t.usetype IN ('0', '2'));
    IF v_exists > 0 THEN
      RETURN 1;
    END IF;
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 查询凭证类型是否支持签发(1:是 0:否)
  FUNCTION f_getqfflag(i_code VARCHAR2) RETURN INT AS
    v_exists INT := 0;
  BEGIN
    SELECT COUNT(1)
      INTO v_exists
      FROM dual
     WHERE EXISTS (SELECT 1
              FROM info_template_bind t
             WHERE t.id = i_code
               AND t.usetype IN ('0', '1'));
    IF v_exists > 0 THEN
      RETURN 1;
    END IF;
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 接收凭证类型
  PROCEDURE p_receive
  (
    i_forminfo IN CLOB, -- 表单数据
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_xml   xmltype;
    v_i     INT;
    v_xpath VARCHAR2(200);
  
    v_exists  INT := 0;
    v_sysdate DATE := SYSDATE;
    v_idx     INT := 0;
    v_oper    INT := 0;
    v_comid   VARCHAR2(64) := pkg_basic.f_getcomid;
  
    v_ver      INT;
    v_datatype VARCHAR2(64);
  BEGIN
    -- 加锁
    UPDATE data_lock2 SET opertime = systimestamp WHERE lockid = 'alltemplate';
  
    mydebug.wlog('i_forminfo', i_forminfo);
  
    -- 解析表单数据
    v_xml := xmltype(i_forminfo);
    SELECT myxml.f_getvalue(v_xml, '/info/datatype') INTO v_datatype FROM dual;
    SELECT myxml.f_getint(v_xml, '/info/ver') INTO v_ver FROM dual;
  
    DECLARE
      v_dataidx INT;
    BEGIN
      IF v_datatype = 'ywcode' THEN
        IF v_ver IS NULL THEN
          o_code := 'EC00';
          o_msg  := '未知版本号，不能更新！';
          mydebug.wlog(3, o_code, o_msg);
          RETURN;
        END IF;
      
        v_dataidx := mystring.f_toint(pkg_basic.f_getconfig2('codeidx'));
        IF v_ver < v_dataidx THEN
          o_code := 'EC00';
          o_msg  := '低版本号信息，不能更新！';
          mydebug.wlog(3, o_code, o_msg);
          RETURN;
        END IF;
      END IF;
    END;
  
    -- 凭证分类-info_mktype
    DECLARE
      v_mktype_ptype    INT;
      v_mktype_pcode    VARCHAR2(64);
      v_mktype_dataidx2 INT;
    
      v_parameter_ver       INT;
      v_parameter_isdefault VARCHAR2(64);
      v_parameter_code      VARCHAR2(64);
      v_parameter_name      VARCHAR2(128);
      v_parameter_issub     VARCHAR2(8); -- 是否有分类
      v_parameter_pcode     VARCHAR2(64); -- 上级代码
      v_parameter_otype     VARCHAR2(8); -- 1：单位 0：个人
      v_parameter_ptype     VARCHAR2(8); -- 1-普通 0-特殊
      v_parameter_htype     VARCHAR2(8);
      v_parameter_vtype     VARCHAR2(8); -- 0-个人 1-归主凭证 2-入账凭证
      v_parameter_showtype  VARCHAR2(64);
      v_parameter_showname  VARCHAR2(128); -- 
      v_parameter_showcode  VARCHAR2(128); -- 
      v_parameter_ico       VARCHAR2(128); -- 
      v_parameter_sort      INT;
    BEGIN
      v_i := 1;
      WHILE v_i <= 1000 LOOP
        v_xpath := mystring.f_concat('/info/parameter[', v_i, ']/');
        SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@ver')) INTO v_parameter_ver FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@isdefault')) INTO v_parameter_isdefault FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@code')) INTO v_parameter_code FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@name')) INTO v_parameter_name FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@issub')) INTO v_parameter_issub FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@pcode')) INTO v_parameter_pcode FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@otype')) INTO v_parameter_otype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@ptype')) INTO v_parameter_ptype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@htype')) INTO v_parameter_htype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@vtype')) INTO v_parameter_vtype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@showtype')) INTO v_parameter_showtype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@showname')) INTO v_parameter_showname FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@showcode')) INTO v_parameter_showcode FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@ico')) INTO v_parameter_ico FROM dual;
        SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@sort')) INTO v_parameter_sort FROM dual;
        IF mystring.f_isnull(v_parameter_code) THEN
          v_i := 1000;
        ELSE
        
          v_oper := 0;
          SELECT COUNT(1) INTO v_exists FROM info_mktype t WHERE t.code = v_parameter_code;
          IF v_exists = 0 THEN
            v_oper := 1;
          ELSE
            SELECT dataidx2 INTO v_mktype_dataidx2 FROM info_mktype t WHERE t.code = v_parameter_code;
            IF v_mktype_dataidx2 <= v_parameter_ver THEN
              v_oper := 1;
            END IF;
          END IF;
          IF v_oper = 1 THEN
            IF v_parameter_pcode = 'mk0x' THEN
              v_mktype_pcode := NULL;
              v_mktype_ptype := 1;
            ELSE
              v_mktype_pcode := v_parameter_pcode;
              v_mktype_ptype := 0;
            END IF;
          
            DELETE FROM info_mktype WHERE code = v_parameter_code;
            INSERT INTO info_mktype
              (code, NAME, ptype, pcode, dflag, issub, dataidx, dataidx2, utype, vtype, showkind, showcode1, showname1, showtype, sort)
            VALUES
              (v_parameter_code,
               v_parameter_name,
               v_mktype_ptype,
               v_mktype_pcode,
               v_parameter_isdefault,
               v_parameter_issub,
               v_ver,
               v_parameter_ver,
               v_parameter_otype,
               v_parameter_vtype,
               v_parameter_ptype,
               v_parameter_showcode,
               v_parameter_showname,
               v_parameter_showtype,
               v_parameter_sort);
          END IF;
        END IF;
      
        v_i := v_i + 1;
      END LOOP;
    END;
  
    -- 凭证类型-INFO_DTYPES
    DECLARE
      v_yzflag INT := 0;
      v_qfflag INT := 0;
    
      v_template_sort       INT;
      v_template_ver        INT;
      v_template_pdtypesort INT;
      v_template_yzflag     INT;
      v_template_yzflag1    INT;
      v_template_yzflag2    INT;
      v_template_qfflag     INT;
      v_template_sqflag     INT;
      v_template_bindstatus INT;
    
      v_mk_ver       INT; -- 版本号
      v_mk_id        VARCHAR2(64); -- 代码
      v_mk_name      VARCHAR2(128); -- 名称
      v_mk_issub     VARCHAR2(8); -- 凭证业务小类(1:存在 0:不存在)
      v_mk_issplit   INT; -- 凭证支持拆分(1-支持 0-不支持)
      v_mk_ismerge   INT; -- 凭证支持合并(1-支持合并 0-不支持合并)
      v_mk_master    VARCHAR2(64); -- 凭证合并对象代码-单位
      v_mk_masternm  VARCHAR2(128); -- 凭证合并对象名称-单位
      v_mk_master1   VARCHAR2(64); -- 凭证合并对象代码-个人
      v_mk_masternm1 VARCHAR2(128); -- 凭证合并对象名称-个人
      v_mk_mtype     VARCHAR2(8); -- 凭证合并方式(0:不支持 1:按凭证类型 2:按签发者+凭证类型 3:按签发者+凭证类型+特别参数)
      v_mk_isch      VARCHAR2(8); -- 凭证支持变动(1:支持持有者变动 0:不支持持有者变动)
      v_mk_sendtype  VARCHAR2(16); -- 开具类型(SendType01:分发 SendType02:签发)
      v_mk_zhsflag   VARCHAR2(4); -- 支持国产终端(1:是 0:否)
      v_mk_covertype VARCHAR2(64); -- 模板类型（标准/宽型）
      v_mk_ocxid     VARCHAR2(64); -- 控件标识
      v_mk_pluginid  VARCHAR2(64); -- 插件标识
      v_mk_subtype   VARCHAR2(8); -- 从凭证模板文件中读取的是否存在子类(1:是 0:否)
      v_mk_otype     VARCHAR2(8); -- 1：单位 0：个人
      v_mk_type      VARCHAR2(64); -- 所属大类
      v_mk_rtype     VARCHAR2(64); -- 
      v_mk_sort      INT; -- 排序号
      v_mk_islegal   INT;
    BEGIN
      SELECT MAX(t.sort) INTO v_template_sort FROM info_template t;
      IF v_template_sort IS NULL THEN
        v_template_sort := 0;
      END IF;
    
      v_i := 1;
      WHILE v_i <= 10000 LOOP
        v_xpath := mystring.f_concat('/info/mk[', v_i, ']/');
        SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@ver')) INTO v_mk_ver FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@id')) INTO v_mk_id FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@name')) INTO v_mk_name FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@issub')) INTO v_mk_issub FROM dual;
        SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@issplit')) INTO v_mk_issplit FROM dual;
        SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@ismerge')) INTO v_mk_ismerge FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@master')) INTO v_mk_master FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@masternm')) INTO v_mk_masternm FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@master1')) INTO v_mk_master1 FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@masternm1')) INTO v_mk_masternm1 FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@mtype')) INTO v_mk_mtype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@isch')) INTO v_mk_isch FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@sendtype')) INTO v_mk_sendtype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@zhsflag')) INTO v_mk_zhsflag FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@covertype')) INTO v_mk_covertype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@ocxid')) INTO v_mk_ocxid FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@pluginid')) INTO v_mk_pluginid FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@subtype')) INTO v_mk_subtype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@otype')) INTO v_mk_otype FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@type')) INTO v_mk_type FROM dual;
        SELECT myxml.f_getvalue(v_xml, mystring.f_concat(v_xpath, '@rtype')) INTO v_mk_rtype FROM dual;
        SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@sort')) INTO v_mk_sort FROM dual;
        SELECT myxml.f_getint(v_xml, mystring.f_concat(v_xpath, '@islegal')) INTO v_mk_islegal FROM dual;
        IF mystring.f_isnull(v_mk_type) OR mystring.f_isnull(v_mk_id) THEN
          v_i := 10000;
        ELSE
          v_oper := 0;
          v_idx  := v_idx + 1;
        
          SELECT COUNT(1) INTO v_exists FROM info_template WHERE tempid = v_mk_id;
          IF v_exists = 0 THEN
            v_oper          := 1;
            v_template_sort := v_template_sort + 1;
            INSERT INTO info_template (tempid, tempname, temptype, comid, sort, operdate) VALUES (v_mk_id, v_mk_name, v_mk_id, v_comid, v_template_sort, v_sysdate);
          ELSE
            SELECT ver INTO v_template_ver FROM info_template t WHERE t.tempid = v_mk_id;
            IF v_template_ver IS NULL THEN
              v_template_ver := 0;
            END IF;
            IF v_template_ver <= v_mk_ver THEN
              v_oper := 1;
            END IF;
          END IF;
          IF v_oper = 1 THEN
            v_template_pdtypesort := pkg_info_template_er_ywcode.f_getmktypesort(v_mk_type);
            v_template_bindstatus := pkg_info_template_er_ywcode.f_getbindstatus(v_mk_id);
          
            v_yzflag           := pkg_info_template_er_ywcode.f_getyzflag(v_mk_id);
            v_qfflag           := pkg_info_template_er_ywcode.f_getqfflag(v_mk_id);
            v_template_yzflag  := 0;
            v_template_yzflag1 := 0;
            v_template_yzflag2 := 0;
            v_template_qfflag  := 0;
            v_template_sqflag  := 0;
            IF v_mk_sendtype = 'SendType01' THEN
              -- SendType01:分发，不能做签发操作
              IF v_yzflag = 1 AND v_qfflag = 0 THEN
                v_template_yzflag  := 1;
                v_template_yzflag1 := 1;
                v_template_yzflag2 := 1;
                v_template_sqflag  := 0;
              ELSE
                v_template_yzflag  := 1;
                v_template_yzflag1 := 0;
                v_template_yzflag2 := 1;
                v_template_sqflag  := 1;
              END IF;
            ELSE
              IF v_yzflag = 1 THEN
                v_template_yzflag  := 1;
                v_template_yzflag1 := 1;
                v_template_yzflag2 := 1;
              END IF;
              v_template_qfflag := v_qfflag;
              v_template_sqflag := 0;
              -- 可以签发，不能印制，则可以申请
              IF v_template_qfflag = 1 AND v_template_yzflag = 0 THEN
                v_template_sqflag := 1;
              END IF;
            END IF;
          END IF;
        
          UPDATE info_template
             SET tempname   = v_mk_name,
                 dtypesort  = v_mk_sort,
                 pdtype     = v_mk_type,
                 pdtypesort = v_template_pdtypesort,
                 otype      = v_mk_otype,
                 mtype      = v_mk_mtype,
                 master     = v_mk_master,
                 masternm   = v_mk_masternm,
                 master1    = v_mk_master1,
                 masternm1  = v_mk_masternm1,
                 sendtype   = v_mk_sendtype,
                 covertype  = v_mk_covertype,
                 ocxid      = v_mk_ocxid,
                 pluginid   = v_mk_pluginid,
                 ver        = v_mk_ver,
                 islegal    = v_mk_islegal,
                 yzflag     = v_template_yzflag,
                 yzflag1    = v_template_yzflag1,
                 yzflag2    = v_template_yzflag2,
                 qfflag     = v_template_qfflag,
                 sqflag     = v_template_sqflag,
                 bindstatus = v_template_bindstatus
           WHERE tempid = v_mk_id;
        END IF;
      
        v_i := v_i + 1;
      END LOOP;
    
    END;
  
    UPDATE info_template SET vtype = 0;
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_mktype WHERE vtype = '2');
    IF v_exists > 0 THEN
      UPDATE info_template SET vtype = 1 WHERE pdtype IN (SELECT code FROM info_mktype WHERE vtype = '2');
    END IF;
  
    -- 设置版本号
    IF v_idx > 0 THEN
      UPDATE sys_config2 t SET t.val = v_ver WHERE t.code = 'codeidx';
    END IF;
  
    -- 6.处理成功
    COMMIT;
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
