CREATE OR REPLACE PACKAGE myquery IS
  /***************************************************************************************************
  
  名称     : myquery
  功能描述 : 查询专用包
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-06  唐金鑫  创建
  
  ***************************************************************************************************/

  -- 前台页面使用的分页参数
  FUNCTION f_getpagenation
  (
    i_allcount INTEGER, -- 总数
    i_pagesize INTEGER, -- 页大小
    i_pagenum  INTEGER -- 页码
  ) RETURN VARCHAR2;

  -- 从sql语句里面提取查询字段
  FUNCTION f_getcolumnsfromsql(i_sql VARCHAR2) RETURN VARCHAR2;

  --制作分页SQL
  FUNCTION f_getpagesql
  (
    i_sql      VARCHAR2, -- 原始SQL
    i_pagesize INTEGER, -- 页大小
    i_pagenum  INTEGER -- 页码
  ) RETURN VARCHAR2;

  -- 计算分页起始编号
  FUNCTION f_getpagestartnum
  (
    i_pagesize INTEGER, -- 页大小
    i_pagenum  INTEGER -- 页码
  ) RETURN INTEGER;

  -- 计算sql总数
  PROCEDURE p_getcountfromsql
  (
    i_sql   IN VARCHAR2,
    o_count OUT INT
  );
END;
/
CREATE OR REPLACE PACKAGE BODY myquery IS
  /***************************************************************************************************
  名称     : myquery.f_getpagenation
  功能描述 : 前台页面使用的分页参数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-06  唐金鑫  创建
  
  "pageNation": {
      "allCount":"总记录数",
      "allPage":"总页数",
      "curPage":"当前页码",
      "endPoint":"尾页开始位置",
      "perPage":"当前页结束位置",
      "startPoint":"首页"
  }  
  ***************************************************************************************************/
  FUNCTION f_getpagenation
  (
    i_allcount INTEGER, -- 总数
    i_pagesize INTEGER, -- 页大小
    i_pagenum  INTEGER -- 页码
  ) RETURN VARCHAR2 AS
    v_result   VARCHAR2(4000);
    v_pagesize INTEGER;
    v_curpage  INTEGER;
    v_allpage  INTEGER;
    v_endpoint INTEGER;
  BEGIN
    v_pagesize := i_pagesize;
    IF v_pagesize IS NULL THEN
      v_pagesize := 1;
    END IF;
    IF v_pagesize < 1 THEN
      v_pagesize := 1;
    END IF;
  
    v_curpage := i_pagenum;
    IF v_curpage IS NULL THEN
      v_curpage := 1;
    END IF;
    IF v_curpage < 1 THEN
      v_curpage := 1;
    END IF;
  
    -- 总页数
    IF i_allcount / v_pagesize > trunc(i_allcount / v_pagesize, 0) THEN
      v_allpage := trunc(i_allcount / v_pagesize, 0) + 1;
    ELSE
      v_allpage := trunc(i_allcount / v_pagesize, 0);
    END IF;
  
    -- 尾页开始位置
    v_endpoint := v_pagesize * v_allpage + 1;
  
    v_result := '"pageNation": {';
    v_result := mystring.f_concat(v_result, ' "allCount":', i_allcount);
    v_result := mystring.f_concat(v_result, ',"allPage":', v_allpage);
    v_result := mystring.f_concat(v_result, ',"curPage":', v_curpage);
    v_result := mystring.f_concat(v_result, ',"endPoint":', v_endpoint);
    v_result := mystring.f_concat(v_result, ',"perPage":', v_pagesize);
    v_result := mystring.f_concat(v_result, ',"startPoint":1');
    v_result := mystring.f_concat(v_result, '}');
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 从sql语句里面提取查询字段
  FUNCTION f_getcolumnsfromsql(i_sql VARCHAR2) RETURN VARCHAR2 AS
    v_result       VARCHAR2(2000);
    v_sql          VARCHAR2(4000);
    v_instr_from   INT := 0;
    v_instr_select INT := 0;
  BEGIN
    IF mystring.f_isnull(i_sql) THEN
      RETURN '';
    END IF;
  
    IF length(i_sql) = 0 THEN
      RETURN '';
    END IF;
  
    v_sql := lower(i_sql);
  
    v_instr_select := instr(v_sql, 'select ');
    IF v_instr_select = 0 THEN
      RETURN '';
    END IF;
  
    v_instr_from := instr(v_sql, ' from ');
    IF v_instr_from = 0 THEN
      RETURN '';
    END IF;
  
    IF v_instr_select > v_instr_from THEN
      RETURN '';
    END IF;
  
    v_result := substr(i_sql, v_instr_select + 7, v_instr_from - v_instr_select - 7);
    RETURN TRIM(v_result);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  /***************************************************************************************************
  名称     : myquery.f_getpagesql
  功能描述 : 制作分页SQL
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-06-06  唐金鑫  创建
  
  原始sql
  SELECT adminuri FROM info_admin e1 ORDER BY e1.sort, e1.adminuri DESC
  
  分页sql
  SELECT adminuri
    FROM (SELECT rownum rn, q1.*
            FROM (SELECT adminuri FROM info_admin e1 ORDER BY e1.sort, e1.adminuri DESC) q1
           WHERE rownum <= 20) q2
   WHERE q2.rn >= 1
  ***************************************************************************************************/
  FUNCTION f_getpagesql
  (
    i_sql      VARCHAR2, -- 原始SQL
    i_pagesize INTEGER, -- 页大小
    i_pagenum  INTEGER -- 页码
  ) RETURN VARCHAR2 AS
    v_result   VARCHAR2(4000);
    v_pagesize INT := 0; -- 页大小
    v_pagenum  INT := 0; -- 页码
    v_startnum INT := 0; -- 起始序号
    v_endnum   INT := 0; -- 终止序号
    v_columns  VARCHAR2(2000);
  BEGIN
    IF mystring.f_isnull(i_sql) THEN
      RETURN '';
    END IF;
  
    IF length(i_sql) = 0 THEN
      RETURN '';
    END IF;
  
    v_pagesize := i_pagesize;
    IF v_pagesize IS NULL THEN
      v_pagesize := 1;
    END IF;
    IF v_pagesize < 1 THEN
      v_pagesize := 1;
    END IF;
  
    v_pagenum := i_pagenum;
    IF v_pagenum IS NULL THEN
      v_pagenum := 1;
    END IF;
    IF v_pagenum < 1 THEN
      v_pagenum := 1;
    END IF;
  
    v_startnum := v_pagesize * v_pagenum - v_pagesize + 1;
    v_endnum   := v_pagesize * v_pagenum;
  
    v_columns := myquery.f_getcolumnsfromsql(i_sql);
  
    v_result := mystring.f_concat('select rownum rn, Q1.* from (', i_sql, ') Q1 where rownum <= ', v_endnum);
    v_result := mystring.f_concat('select ', v_columns, ' from (', v_result, ') Q2 where Q2.rn >= ', v_startnum);
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 计算分页起始编号
  FUNCTION f_getpagestartnum
  (
    i_pagesize INTEGER, -- 页大小
    i_pagenum  INTEGER -- 页码
  ) RETURN INTEGER AS
    v_pagesize INT := 0;
  BEGIN
    IF i_pagenum IS NULL THEN
      RETURN 1;
    END IF;
    IF i_pagenum < 1 THEN
      RETURN 1;
    END IF;
    IF i_pagenum = 1 THEN
      RETURN 1;
    END IF;
  
    v_pagesize := i_pagesize;
    IF v_pagesize IS NULL THEN
      v_pagesize := 1;
    END IF;
    IF v_pagesize < 1 THEN
      v_pagesize := 1;
    END IF;
  
    RETURN v_pagesize * i_pagenum - v_pagesize + 1;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 1;
  END;

  -- 计算sql总数
  PROCEDURE p_getcountfromsql
  (
    i_sql   IN VARCHAR2,
    o_count OUT INT
  ) AS
    v_sql        VARCHAR2(4000);
    v_instr_from INT := 0;
  BEGIN
    o_count := 0;
  
    IF mystring.f_isnull(i_sql) THEN
      RETURN;
    END IF;
  
    IF length(i_sql) = 0 THEN
      RETURN;
    END IF;
  
    v_sql        := lower(i_sql);
    v_instr_from := instr(v_sql, ' from ');
    IF v_instr_from = 0 THEN
      RETURN;
    END IF;
  
    v_sql := mystring.f_concat('select count(1) ', substr(i_sql, v_instr_from));
  
    EXECUTE IMMEDIATE v_sql
      INTO o_count;
  EXCEPTION
    WHEN OTHERS THEN
      o_count := 0;
  END;
END;
/
