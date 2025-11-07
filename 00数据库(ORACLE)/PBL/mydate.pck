CREATE OR REPLACE PACKAGE mydate IS

  /***************************************************************************************************
  名称     : mydate
  功能描述 : 常用日期函数
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-07-18  唐金鑫  创建
  
  ***************************************************************************************************/

  -- 间隔秒数
  FUNCTION f_interval_second
  (
    i_end   DATE,
    i_start DATE
  ) RETURN INT;

  -- 增加秒
  FUNCTION f_addsecond
  (
    i_date     DATE,
    i_interval INT
  ) RETURN DATE;

  -- 增加天
  FUNCTION f_addday
  (
    i_date     DATE,
    i_interval INT
  ) RETURN DATE;

  -- 增加天(字符串格式)
  FUNCTION f_addday_str
  (
    i_date     VARCHAR2,
    i_interval INT
  ) RETURN VARCHAR2;
END mydate;
/
CREATE OR REPLACE PACKAGE BODY mydate IS

  -- 间隔秒数
  FUNCTION f_interval_second
  (
    i_end   DATE,
    i_start DATE
  ) RETURN INT AS
    v_result INT;
  BEGIN
    IF i_start IS NULL THEN
      RETURN 0;
    END IF;
  
    IF i_end IS NULL THEN
      RETURN 0;
    END IF;
  
    IF i_start > i_end THEN
      RETURN 0;
    END IF;
  
    v_result := (i_end - i_start) * 24 * 60 * 60;
  
    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 增加秒
  FUNCTION f_addsecond
  (
    i_date     DATE,
    i_interval INT
  ) RETURN DATE AS
  BEGIN
    IF i_date IS NULL THEN
      RETURN NULL;
    END IF;
  
    IF i_interval IS NULL THEN
      RETURN i_date;
    END IF;
  
    IF i_interval = 0 THEN
      RETURN i_date;
    END IF;
  
    RETURN i_date + i_interval / 24 / 60 / 60;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_date;
  END;

  -- 增加天
  FUNCTION f_addday
  (
    i_date     DATE,
    i_interval INT
  ) RETURN DATE AS
  BEGIN
    IF i_date IS NULL THEN
      RETURN NULL;
    END IF;
  
    IF i_interval IS NULL THEN
      RETURN i_date;
    END IF;
  
    IF i_interval = 0 THEN
      RETURN i_date;
    END IF;
  
    RETURN i_date + i_interval;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_date;
  END;

  -- 增加天(字符串格式)
  FUNCTION f_addday_str
  (
    i_date     VARCHAR2,
    i_interval INT
  ) RETURN VARCHAR2 AS
    v_date DATE;
  BEGIN
    IF i_date IS NULL THEN
      RETURN '';
    END IF;
  
    IF i_interval IS NULL THEN
      RETURN i_date;
    END IF;
  
    IF i_interval = 0 THEN
      RETURN i_date;
    END IF;
  
    v_date := to_date(i_date, 'yyyy-mm-dd');
    v_date := v_date + i_interval;
  
    RETURN to_char(v_date, 'yyyy-mm-dd');
  EXCEPTION
    WHEN OTHERS THEN
      RETURN i_date;
  END;
END mydate;
/
