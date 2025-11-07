CREATE OR REPLACE PACKAGE myfile IS
  /***************************************************************************************************
  名称     : myfile
  功能描述 : 文件信息公共包
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-07-31  唐金鑫  创建  
  ***************************************************************************************************/

  -- 获取文件名后缀
  FUNCTION f_getfileformat(i_filename VARCHAR2) RETURN VARCHAR2;

  -- 获取不带后缀的文件名
  FUNCTION f_getfilenamenoformat(i_filename VARCHAR2) RETURN VARCHAR2;

  -- 从文件路径中获取文件名
  FUNCTION f_getfilenamefrompath(i_path VARCHAR2) RETURN VARCHAR2;

  -- 制作不带文件名的路径
  FUNCTION f_getfiledirfrompath(i_path VARCHAR2) RETURN VARCHAR2;

  -- 制作文件全路径
  FUNCTION f_filepathaddname
  (
    i_filedir  VARCHAR2, -- 文件目录
    i_filename VARCHAR2 -- 文件名
  ) RETURN VARCHAR2;

  -- 补齐路径首尾斜线
  FUNCTION f_diraddend(i_path VARCHAR2) RETURN VARCHAR2;

  -- 删除前缀(制作相对路径)
  FUNCTION f_path_del
  (
    i_path   VARCHAR2, -- 文件路径
    i_prefix VARCHAR2 -- 需要删除的部分
  ) RETURN VARCHAR2;

  -- 合并路径(制作绝对路径)
  FUNCTION f_path_concat
  (
    i_prefix VARCHAR2, -- 需要增加的部分
    i_path   VARCHAR2 -- 文件路径
  ) RETURN VARCHAR2;
END;
/
CREATE OR REPLACE PACKAGE BODY myfile IS

  -- 获取文件名后缀
  FUNCTION f_getfileformat(i_filename VARCHAR2) RETURN VARCHAR2 AS
    v_format  VARCHAR2(32);
    v_reverse VARCHAR2(4000);
    v_instr   INT;
  BEGIN
    IF i_filename IS NULL THEN
      RETURN '';
    END IF;
  
    IF length(i_filename) = 0 THEN
      RETURN '';
    END IF;
  
    SELECT REVERSE(i_filename) INTO v_reverse FROM dual;
  
    v_instr := instr(v_reverse, '.');
  
    IF v_instr = 0 THEN
      RETURN '';
    END IF;
  
    v_format := substr(v_reverse, 1, v_instr - 1);
  
    SELECT REVERSE(v_format) INTO v_format FROM dual;
  
    RETURN v_format;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END;

  -- 获取不带后缀的文件名
  FUNCTION f_getfilenamenoformat(i_filename VARCHAR2) RETURN VARCHAR2 AS
    v_filename VARCHAR2(512);
    v_instr    INT;
  BEGIN
    IF instr(i_filename, '.') = 0 THEN
      RETURN i_filename;
    END IF;
  
    SELECT REVERSE(i_filename) INTO v_filename FROM dual;
  
    v_instr    := instr(v_filename, '.');
    v_filename := substr(v_filename, v_instr + 1);
  
    SELECT REVERSE(v_filename) INTO v_filename FROM dual;
  
    RETURN v_filename;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_filename;
  END;

  -- 从文件路径中获取文件名
  FUNCTION f_getfilenamefrompath(i_path VARCHAR2) RETURN VARCHAR2 AS
    v_filename VARCHAR2(512) := i_path;
    v_reverse  VARCHAR2(4000);
    v_p1       INT := 0;
    v_p2       INT := 0;
    v_p        INT := 0;
  BEGIN
    IF instr(i_path, '\') = 0 AND instr(i_path, '/') = 0 THEN
      RETURN i_path;
    END IF;
  
    SELECT REVERSE(i_path) INTO v_reverse FROM dual;
  
    v_p1 := instr(v_reverse, '\');
    IF v_p1 IS NULL THEN
      v_p := 0;
    ELSE
      v_p := v_p1;
    END IF;
  
    v_p2 := instr(v_reverse, '/');
    IF v_p2 IS NOT NULL THEN
      IF v_p2 > v_p THEN
        v_p := v_p2;
      END IF;
    END IF;
  
    IF v_p = 0 THEN
      RETURN i_path;
    END IF;
  
    v_filename := substr(v_reverse, 1, v_p - 1);
  
    SELECT REVERSE(v_filename) INTO v_filename FROM dual;
  
    RETURN v_filename;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_path;
  END;

  -- 制作不带文件名的路径
  FUNCTION f_getfiledirfrompath(i_path VARCHAR2) RETURN VARCHAR2 IS
    v_result  VARCHAR2(4000); -- 返回文件路径
    v_reverse VARCHAR2(4000);
    v_instr   INT;
  BEGIN
    IF i_path IS NULL THEN
      RETURN '';
    END IF;
  
    IF length(i_path) = 0 THEN
      RETURN '';
    END IF;
  
    IF substr(i_path, -1, 1) IN ('/', '\') THEN
      RETURN i_path;
    END IF;
  
    SELECT REVERSE(i_path) INTO v_reverse FROM dual;
  
    v_instr := instr(v_reverse, '/');
    IF v_instr = 0 THEN
      v_instr := instr(v_reverse, '\');
    END IF;
  
    v_result := substr(v_reverse, v_instr);
  
    SELECT REVERSE(v_result) INTO v_result FROM dual;
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_path;
  END;

  -- 制作文件全路径
  FUNCTION f_filepathaddname
  (
    i_filedir  VARCHAR2, -- 文件目录
    i_filename VARCHAR2 -- 文件名
  ) RETURN VARCHAR2 IS
    v_result VARCHAR2(4000); -- 返回文件路径
  BEGIN
    IF i_filename IS NULL THEN
      RETURN '';
    END IF;
  
    IF length(i_filename) = 0 THEN
      RETURN '';
    END IF;
  
    IF i_filedir IS NULL THEN
      RETURN '';
    END IF;
  
    IF length(i_filedir) = 0 THEN
      RETURN '';
    END IF;
  
    IF instr(i_filedir, i_filename) > 0 THEN
      RETURN i_filedir;
    END IF;
  
    IF substr(i_filedir, -1, 1) IN ('/', '\') THEN
      v_result := i_filedir || i_filename;
    ELSE
      IF instr(i_filedir, '/') > 0 THEN
        v_result := i_filedir || '/' || i_filename;
      ELSE
        v_result := i_filedir || '/' || i_filename;
      END IF;
    END IF;
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_filedir;
  END;

  -- 补齐路径首尾斜线
  FUNCTION f_diraddend(i_path VARCHAR2) RETURN VARCHAR2 AS
    v_result VARCHAR2(200);
    v_first  VARCHAR2(2);
    v_last   VARCHAR2(2);
  BEGIN
    IF i_path IS NULL THEN
      RETURN '/';
    END IF;
  
    IF length(i_path) = 0 THEN
      RETURN '/';
    END IF;
  
    v_result := i_path;
  
    v_first := substr(v_result, 1, 1);
    IF v_first <> '/' AND v_first <> '\' THEN
      v_result := '/' || v_result;
    END IF;
  
    v_last := substr(v_result, -1, 1);
    IF v_last <> '/' AND v_last <> '\' THEN
      v_result := v_result || '/';
    END IF;
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '/';
  END;

  -- 删除前缀(制作相对路径)
  FUNCTION f_path_del
  (
    i_path   VARCHAR2, -- 文件路径
    i_prefix VARCHAR2 -- 需要删除的部分
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
    v_first  VARCHAR2(2);
  BEGIN
    IF i_prefix IS NULL THEN
      RETURN i_path;
    END IF;
  
    IF length(i_prefix) = 0 THEN
      RETURN i_path;
    END IF;
  
    v_first := substr(i_path, 1, 1);
    IF v_first = '/' OR v_first = '\' THEN
      v_result := i_path;
    ELSE
      v_result := '/' || i_path;
    END IF;
  
    IF instr(v_result, i_prefix) = 1 THEN
      RETURN substr(v_result, length(i_prefix) + 1);
    END IF;
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_path;
  END;

  -- 合并路径(制作绝对路径)
  FUNCTION f_path_concat
  (
    i_prefix VARCHAR2, -- 需要增加的部分
    i_path   VARCHAR2 -- 文件路径
  ) RETURN VARCHAR2 AS
    v_first VARCHAR2(2);
  BEGIN
    IF i_prefix IS NULL THEN
      RETURN i_path;
    END IF;
  
    IF length(i_prefix) = 0 THEN
      RETURN i_path;
    END IF;
  
    IF instr(i_path, i_prefix) = 1 THEN
      RETURN i_path;
    END IF;
  
    v_first := substr(i_path, 1, 1);
    IF v_first = '/' OR v_first = '\' THEN
      RETURN i_prefix || i_path;
    END IF;
  
    RETURN i_prefix || '/' || i_path;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_path;
  END;
END;
/
