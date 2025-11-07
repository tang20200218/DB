CREATE OR REPLACE PACKAGE pkg_info_register_kind_pbl IS

  /***************************************************************************************************
  名称     : pkg_info_register_kind_pbl
  功能描述 : 签发对象分类-公共包
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-07-25  唐金鑫  创建
  
  ***************************************************************************************************/

  -- 查询根节点名称
  FUNCTION f_getrootname(i_datatype INT) RETURN VARCHAR2;

  -- 查询节点名称
  FUNCTION f_getname(i_id VARCHAR2) RETURN VARCHAR2;

  -- 查询节点路径
  FUNCTION f_getidpath(i_id VARCHAR2) RETURN VARCHAR2;

  -- 查询完整排序
  FUNCTION f_getfullsort(i_id VARCHAR2) RETURN VARCHAR2;

  -- 是否叶子节点(1:是 0:否)
  FUNCTION f_isleaf(i_id VARCHAR2) RETURN INT;
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_register_kind_pbl IS

  -- 查询根节点名称
  FUNCTION f_getrootname(i_datatype INT) RETURN VARCHAR2 AS
    v_result VARCHAR2(200);
  BEGIN
    IF i_datatype = 0 THEN
      SELECT t.name INTO v_result FROM info_register_kind_root t WHERE t.id = 'root0';
    ELSE
      SELECT t.name INTO v_result FROM info_register_kind_root t WHERE t.id = 'root1';
    END IF;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询节点名称
  FUNCTION f_getname(i_id VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(200);
  BEGIN
    SELECT t.name INTO v_result FROM info_register_kind t WHERE t.id = i_id;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 查询节点路径
  FUNCTION f_getidpath(i_id VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(512);
  BEGIN
    SELECT t.idpath INTO v_result FROM info_register_kind t WHERE t.id = i_id;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '/';
  END;

  -- 查询完整排序
  FUNCTION f_getfullsort(i_id VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(512);
  BEGIN
    SELECT t.fullsort INTO v_result FROM info_register_kind t WHERE t.id = i_id;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '/';
  END;

  -- 是否叶子节点(1:是 0:否)
  FUNCTION f_isleaf(i_id VARCHAR2) RETURN INT AS
    v_exists INT := 0;
  BEGIN
    SELECT COUNT(1) INTO v_exists FROM dual WHERE EXISTS (SELECT 1 FROM info_register_kind t WHERE t.pid = i_id);
    IF v_exists = 0 THEN
      RETURN 1;
    END IF;
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;
END;
/
