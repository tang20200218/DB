CREATE OR REPLACE PACKAGE pkg_info_register_pbl IS

  /***************************************************************************************************
  名称     : pkg_info_register_pbl
  功能描述 : 开户注册管理-公共包
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-07-24  唐金鑫  创建
  
  ***************************************************************************************************/

  -- 查询证件号码/机构代码
  FUNCTION f_getobjcode(i_objid VARCHAR2) RETURN VARCHAR2;

  -- 自动开户
  PROCEDURE p_ins
  (
    i_datatype IN VARCHAR2, -- 数据类型(0:用户 1:单位)
    i_objname  IN VARCHAR2, -- 用户姓名/单位名称
    i_objcode  IN VARCHAR2, -- 证件号码/机构代码
    o_objid    OUT VARCHAR2, -- 空间号
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  );
END;
/
CREATE OR REPLACE PACKAGE BODY pkg_info_register_pbl IS

  -- 查询证件号码/机构代码
  FUNCTION f_getobjcode(i_objid VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(200);
  BEGIN
    SELECT t.objcode
      INTO v_result
      FROM info_register_obj t
     WHERE t.objid = i_objid
       AND rownum <= 1;
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 自动开户
  PROCEDURE p_ins
  (
    i_datatype IN VARCHAR2, -- 数据类型(0:用户 1:单位)
    i_objname  IN VARCHAR2, -- 用户姓名/单位名称
    i_objcode  IN VARCHAR2, -- 证件号码/机构代码
    o_objid    OUT VARCHAR2, -- 空间号
    o_code     OUT VARCHAR2, -- 操作结果:错误码
    o_msg      OUT VARCHAR2 -- 成功/错误原因
  ) AS
    v_exists INT := 0;
    v_sort   INT := 0;
    v_id     VARCHAR2(64);
  BEGIN
    mydebug.wlog('i_objname', i_objname);
    mydebug.wlog('i_objcode', i_objcode);
  
    SELECT COUNT(1)
      INTO v_exists
      FROM info_register_obj t
     WHERE t.objcode = i_objcode
       AND t.datatype = i_datatype;
  
    IF v_exists > 0 THEN
      SELECT t.objid
        INTO o_objid
        FROM info_register_obj t
       WHERE t.objcode = i_objcode
         AND t.datatype = i_datatype
         AND rownum <= 1;
    
      mydebug.wlog('o_objid', o_objid);
      o_code := 'EC00';
      o_msg  := '处理成功';
      mydebug.wlog(1, o_code, o_msg);
      RETURN;
    END IF;

    SELECT MAX(t.sort)
      INTO v_sort
      FROM info_register_obj t
     WHERE t.kindid = 'root'
       AND t.datatype = i_datatype;
    IF v_sort IS NULL THEN
      v_sort := 1;
    ELSE
      v_sort := v_sort + 1;
    END IF;
  
    v_id := pkg_basic.f_newid('OG');
  
    INSERT INTO info_register_obj
      (id, objname, objcode, datatype, sort, kindid, kindidpath, fromtype, status, operuri, opername)
    VALUES
      (v_id, i_objname, i_objcode, i_datatype, v_sort, 'root', '/', 2, 0, 'system', 'system');
  
    DELETE FROM info_register_queue WHERE id = i_objcode;
    INSERT INTO info_register_queue (id, datatype) VALUES (i_objcode, i_datatype);
  
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
