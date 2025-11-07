CREATE OR REPLACE PACKAGE pkg_info_template_pbl IS
  /***************************************************************************************************
  名称     : pkg_info_template_pbl
  功能描述 : 凭证参数维护公共包
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-02-08  唐金鑫  创建
  
  业务说明
  ***************************************************************************************************/

  -- 查询签发角色
  FUNCTION f_getrole(i_code VARCHAR2) RETURN VARCHAR2;

  -- 凭证文件存放路径
  FUNCTION f_getfilepath(i_code VARCHAR2) RETURN VARCHAR2;

  -- 获取签发业务名称
  FUNCTION f_getqfopername
  (
    i_tempid VARCHAR2,
    i_code   VARCHAR2
  ) RETURN VARCHAR2;

  -- 是否存在子凭证(1:是 0否)
  FUNCTION f_getcollectstatus(i_tempid VARCHAR2) RETURN INT;

  -- 查询凭证名称
  FUNCTION f_gettempname(i_id VARCHAR2) RETURN VARCHAR2;

  -- 查询凭证类型(1:单位 0:个人)
  FUNCTION f_getotype(i_tempid VARCHAR2) RETURN INT;

  -- 查询凭证是否需要授权(1:是 0:否)
  FUNCTION f_getauthtype RETURN INT;

  -- 凭证分类名称
  FUNCTION f_mktypename(i_code VARCHAR2) RETURN VARCHAR2;
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_template_pbl IS

  -- 调用凭证接口(SetUserRole)传入的角色信息
  -- 查询签发角色
  FUNCTION f_getrole(i_code VARCHAR2) RETURN VARCHAR2 AS
    v_result   VARCHAR2(200);
    v_rolecode VARCHAR2(64);
  BEGIN
    DECLARE
      CURSOR v_cursor IS
        SELECT t.rolecode FROM info_template_role t WHERE t.tempcode = i_code ORDER BY t.sort;
    BEGIN
      OPEN v_cursor;
      LOOP
        FETCH v_cursor
          INTO v_rolecode;
        EXIT WHEN v_cursor%NOTFOUND;
        IF mystring.f_isnull(v_result) THEN
          v_result := v_rolecode;
        ELSE
          v_result := mystring.f_concat(v_result, ';', v_rolecode);
        END IF;
      END LOOP;
      CLOSE v_cursor;
    EXCEPTION
      WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
          CLOSE v_cursor;
        END IF;
    END;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 凭证文件存放路径
  -- /usr/local/pzysys/template/DW0020202020/
  FUNCTION f_getfilepath(i_code VARCHAR2) RETURN VARCHAR2 AS
    v_filepath VARCHAR2(200);
  BEGIN
    v_filepath := pkg_file0.f_getconfig;
    RETURN mystring.f_concat(v_filepath, 'template/', i_code, '/');
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '/';
  END;

  -- 获取签发业务名称
  FUNCTION f_getqfopername
  (
    i_tempid VARCHAR2,
    i_code   VARCHAR2
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(2000);
  BEGIN
    IF i_code IN ('1', '2') THEN
      SELECT t.name
        INTO v_result
        FROM info_template_qfoper t
       WHERE t.tempid = i_tempid
         AND t.pcode = i_code
         AND rownum <= 1;
    ELSE
      SELECT t.name
        INTO v_result
        FROM info_template_qfoper t
       WHERE t.tempid = i_tempid
         AND t.code = i_code
         AND rownum <= 1;
    END IF;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 是否存在子凭证(1:是 0否)
  FUNCTION f_getcollectstatus(i_tempid VARCHAR2) RETURN INT AS
  BEGIN
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 查询凭证名称
  FUNCTION f_gettempname(i_id VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(200);
  BEGIN
    SELECT tempname INTO v_result FROM info_template WHERE tempid = i_id;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询凭证类型(1:单位 0:个人)
  FUNCTION f_getotype(i_tempid VARCHAR2) RETURN INT AS
    v_result INT;
  BEGIN
    SELECT otype INTO v_result FROM info_template WHERE tempid = i_tempid;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 查询凭证是否需要授权(1:是 0:否)
  FUNCTION f_getauthtype RETURN INT AS
    v_cnt INT;
  BEGIN
    SELECT COUNT(1) INTO v_cnt FROM info_template t WHERE t.enable = '1';
    IF v_cnt > 1 THEN
      RETURN 1;
    END IF;
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 凭证分类名称
  FUNCTION f_mktypename(i_code VARCHAR2) RETURN VARCHAR2 AS
    v_name VARCHAR2(64);
  BEGIN
    SELECT NAME INTO v_name FROM info_mktype WHERE code = i_code;
    RETURN v_name;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_code;
  END;

END;
/
