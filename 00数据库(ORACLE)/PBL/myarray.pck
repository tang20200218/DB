CREATE OR REPLACE PACKAGE myarray IS

  /***************************************************************************************************
  名称     : myarray
  功能描述 : 字符串集合
  
  修订记录：
  版本号  编辑时间    编辑人  修改描述
  1.0.0   2023-07-04  唐金鑫  创建此包
  
  ***************************************************************************************************/

  -- 计算字符串数组元素数量
  FUNCTION f_getcount
  (
    i_string    VARCHAR2, -- 字符串数组
    i_separator VARCHAR2 -- 分隔符(只能是一个字符)，默认为逗号
  ) RETURN INT;

  -- 获取字符串数组元素值
  FUNCTION f_getvalue
  (
    i_string    VARCHAR2, -- 字符串数组
    i_separator VARCHAR2, -- 分隔符(只能是一个字符)，默认为逗号
    i_num       INT -- 元素编号，从1开始
  ) RETURN VARCHAR2;

END myarray;
/
CREATE OR REPLACE PACKAGE BODY myarray IS

  -- 计算字符串数组元素数量
  FUNCTION f_getcount
  (
    i_string    VARCHAR2, -- 字符串数组
    i_separator VARCHAR2 -- 分隔符(只能是一个字符)，默认为逗号
  ) RETURN INT AS
    v_count INT;
  BEGIN
    IF i_string IS NULL THEN
      RETURN 0;
    END IF;
  
    v_count := nvl(length(i_string), 0) - nvl(length(REPLACE(i_string, i_separator)), 0) + 1;
    RETURN v_count;
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      RETURN 0;
  END;

  -- 获取字符串数组元素值
  FUNCTION f_getvalue
  (
    i_string    VARCHAR2, -- 字符串数组
    i_separator VARCHAR2, -- 分隔符(只能是一个字符)，默认为逗号
    i_num       INT -- 元素编号，从1开始
  ) RETURN VARCHAR2 AS
    v_result VARCHAR2(4000);
  
    v_separator_place_left  INT; -- 元素左边分隔符位置
    v_separator_place_right INT; -- 元素右边分隔符位置
  BEGIN
  
    -- 获取元素左边分隔符位置
    IF i_num = 1 THEN
      v_separator_place_left := 0;
    ELSE
      v_separator_place_left := instr(i_string, i_separator, 1, i_num - 1);
    END IF;
  
    -- 获取元素右边分隔符位置
    v_separator_place_right := instr(i_string, i_separator, 1, i_num);
  
    -- 取出元素
    IF v_separator_place_right = 0 THEN
      v_result := substr(i_string, v_separator_place_left + 1);
    ELSE
      v_result := substr(i_string, v_separator_place_left + 1, v_separator_place_right - v_separator_place_left - 1);
    END IF;
  
    RETURN v_result;
  EXCEPTION
    -- 9.异常处理
    WHEN OTHERS THEN
      RETURN '';
  END;

END myarray;
/
