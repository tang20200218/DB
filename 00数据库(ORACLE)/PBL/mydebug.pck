CREATE OR REPLACE PACKAGE mydebug IS

  /***************************************************************************************************
  调试专用包
  
  2012-09-29
  
  日志级别:
  1、debug;
  2、info;
  3、warning;
  4、client error(数据错误);
  5、server error(数据校验错误);
  6、communicate error;
  7、error(其他错误);
  
  当前日志级别 >= 系统日志级别 时 记录日志
  
  -- 系统错误日志表-mylog
  -- drop table MYLOG;
  create table MYLOG(
    msgdate     timestamp,
    call_stack  VARCHAR2(4000),
    ownername   varchar2(255),
    objname     varchar2(255),
    lineno      integer,
    msglevel    integer,
    msgcode     varchar2(100),
    msg         varchar2(2000),
    cdata       clob
  );
  comment on table  MYLOG            is '系统错误日志表';
  comment on column MYLOG.msgdate    is '日志时间';
  comment on column MYLOG.call_stack is '调用栈';
  comment on column MYLOG.ownername  is '调用对象所有者';
  comment on column MYLOG.objname    is '调用对象名称';
  comment on column MYLOG.lineno     is '程序行数';
  comment on column MYLOG.msglevel   is '日志级别:1、debug;2、info;3、warning;4、client error(数据错误);5、server error(数据校验错误);6、communicate error;7、other error(其他错误)';
  comment on column MYLOG.msgcode    is '日志代码';
  comment on column MYLOG.msg        is '日志信息，小于2000字符';
  comment on column MYLOG.cdata      is '相关数据';
  
  ***************************************************************************************************/
  -- 记录日志
  PROCEDURE wlog;

  -- 记录日志(clob数据)
  PROCEDURE wlog(i_cdata IN CLOB);

  -- 记录日志(xml数据)
  PROCEDURE wlog(i_xdata IN xmltype);

  -- 记录日志(数据名称、clob数据)
  PROCEDURE wlog
  (
    i_msgcode IN VARCHAR2, -- 数据名称
    i_msg     IN CLOB -- clob数据
  );

  -- 记录日志(数据名称、xml数据)
  PROCEDURE wlog
  (
    i_msgcode IN VARCHAR2, -- 数据名称
    i_msg     IN xmltype -- xml数据
  );

  -- 记录日志(日志级别、日志代码、日志消息)
  PROCEDURE wlog
  (
    i_msglevel IN INTEGER, -- 日志级别
    i_msgcode  IN VARCHAR2, -- 日志代码
    i_msg      IN VARCHAR2 -- 日志消息
  );

  -- 记录日志(内部)
  PROCEDURE p_wlog_base
  (
    i_msglevel IN INTEGER, -- 日志级别
    i_msgcode  IN VARCHAR2, -- 日志代码
    i_msg      IN CLOB -- 日志消息
  );

  -- 过程调用跟踪(内部)
  PROCEDURE p_call_trace
  (
    o_owner      OUT VARCHAR2, -- 对象所有者
    o_object     OUT VARCHAR2, -- 对象名
    o_lineno     OUT NUMBER, -- 行号
    o_call_stack OUT VARCHAR2 -- 调用栈
  );

  -- 记录错误日志
  PROCEDURE err(i_msglevel IN INTEGER DEFAULT NULL);

  -- 错误信息跟踪(内部)
  PROCEDURE p_error_trace
  (
    o_owner      OUT VARCHAR2, -- 对象所有者
    o_object     OUT VARCHAR2, -- 对象名
    o_lineno     OUT NUMBER, -- 行号
    o_errcode    OUT VARCHAR2, -- 错误代码
    o_errmsg     OUT VARCHAR2, -- 错误信息
    o_call_stack OUT VARCHAR2
  );

  PROCEDURE p_ins
  (
    i_call_stack IN VARCHAR2,
    i_ownername  IN VARCHAR2,
    i_objname    IN VARCHAR2,
    i_lineno     IN INTEGER,
    i_msglevel   IN INTEGER, -- 日志级别
    i_msgcode    IN VARCHAR2, -- 日志代码
    i_msg        IN CLOB -- 日志消息
  );

  -- 取系统日志级别(内部)
  FUNCTION f_getloglevel RETURN INTEGER;
END mydebug;
/
CREATE OR REPLACE PACKAGE BODY mydebug IS

  -- 记录日志
  PROCEDURE wlog IS
  BEGIN
    -- 如果日志级别小于日志打印级别，则直接退出
    IF f_getloglevel > 1 THEN
      RETURN;
    END IF;
  
    -- 记录日志
    p_wlog_base(1, NULL, NULL);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END wlog;

  -- 记录日志(clob数据)
  PROCEDURE wlog(i_cdata IN CLOB) IS
  BEGIN
    -- 如果日志级别小于日志打印级别，则直接退出
    IF f_getloglevel > 1 THEN
      RETURN;
    END IF;
  
    -- 记录日志
    p_wlog_base(1, NULL, i_cdata);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END wlog;

  -- 记录日志(xml数据)
  PROCEDURE wlog(i_xdata IN xmltype) IS
    v_cdata CLOB;
  BEGIN
    -- 如果日志级别小于日志打印级别，则直接退出
    IF f_getloglevel > 1 THEN
      RETURN;
    END IF;
  
    -- 将xml数据转为clob
    IF i_xdata IS NOT NULL THEN
      v_cdata := i_xdata.getclobval();
    END IF;
  
    -- 记录日志
    p_wlog_base(1, NULL, v_cdata);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END wlog;

  -- 记录日志(数据名称、clob数据)
  PROCEDURE wlog
  (
    i_msgcode IN VARCHAR2, -- 数据名称
    i_msg     IN CLOB -- clob数据
  ) AS
  BEGIN
    -- 如果日志级别小于日志打印级别，则直接退出
    IF f_getloglevel > 1 THEN
      RETURN;
    END IF;
  
    -- 记录日志
    p_wlog_base(1, i_msgcode, i_msg);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END wlog;

  -- 记录日志(数据名称、xml数据)
  PROCEDURE wlog
  (
    i_msgcode IN VARCHAR2, -- 数据名称
    i_msg     IN xmltype -- xml数据
  ) AS
    v_msg CLOB;
  BEGIN
    -- 如果日志级别小于日志打印级别，则直接退出
    IF f_getloglevel > 1 THEN
      RETURN;
    END IF;
  
    -- 将xml数据转为clob
    IF i_msg IS NOT NULL THEN
      v_msg := i_msg.getclobval();
    END IF;
  
    -- 记录日志
    p_wlog_base(1, i_msgcode, v_msg);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END wlog;

  -- 记录日志(日志代码、日志消息、clob数据)
  PROCEDURE wlog
  (
    i_msglevel IN INTEGER, -- 日志级别
    i_msgcode  IN VARCHAR2, -- 日志代码
    i_msg      IN VARCHAR2 -- 日志消息
  ) AS
  BEGIN
    -- 如果日志级别小于日志打印级别，则直接退出
    IF f_getloglevel > i_msglevel THEN
      RETURN;
    END IF;
  
    -- 记录日志
    p_wlog_base(i_msglevel, i_msgcode, i_msg);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END wlog;

  -- 记录日志(内部)
  PROCEDURE p_wlog_base
  (
    i_msglevel IN INTEGER, -- 日志级别
    i_msgcode  IN VARCHAR2, -- 日志代码
    i_msg      IN CLOB -- 日志消息
  ) AS
    v_ownername  VARCHAR2(255);
    v_objname    VARCHAR2(255);
    v_lineno     INTEGER;
    v_call_stack VARCHAR2(4000);
  BEGIN
    -- 过程调用信息
    p_call_trace(o_owner => v_ownername, o_object => v_objname, o_lineno => v_lineno, o_call_stack => v_call_stack);
    p_ins(i_call_stack => v_call_stack, i_ownername => v_ownername, i_objname => v_objname, i_lineno => v_lineno, i_msglevel => i_msglevel, i_msgcode => i_msgcode, i_msg => i_msg);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END p_wlog_base;

  /***************************************************************************************************
  过程调用跟踪(内部)
  本过程返回调用日志包的对象和行号
  
  使用dbms_utility.format_call_stack()来获取调用栈    
  调用栈示例:  
  - - - PL/SQL Call Stack - - -
    object      line  object
    handle    number  name
  0x99257a38       176  package body EXCH3.MYDEBUG
  0x99257a38       126  package body EXCH3.MYDEBUG
  0x99257a38        13  package body EXCH3.MYDEBUG
  0x709e7020         8  procedure EXCH3.T1
  0x7027af98         3  anonymous block
  
  栈里面存储了所有涉及到的过程名称、行号
  第4行为本过程调用dbms_utility.format_call_stack()的位置
  第5行为调用本过程的位置，即记录日志的过程
  第7行为打印日志的位置
  最后一行为开始的位置
  ***************************************************************************************************/
  PROCEDURE p_call_trace
  (
    o_owner      OUT VARCHAR2, -- 对象所有者
    o_object     OUT VARCHAR2, -- 对象名
    o_lineno     OUT NUMBER, -- 行号
    o_call_stack OUT VARCHAR2 -- 调用栈
  ) AS
    l_call_stack VARCHAR2(4000) DEFAULT dbms_utility.format_call_stack();
    l_line       VARCHAR2(4000);
  BEGIN
    -- skip three header lines and first levels in the stack
    FOR i IN 1 .. 6 LOOP
      l_call_stack := substr(l_call_stack, instr(l_call_stack, chr(10)) + 1);
    END LOOP;
  
    -- set l_line to the current line
    l_line := substr(l_call_stack, 1, instr(l_call_stack, chr(10)) - 1);
  
    -- strip object handle
    l_line := ltrim(substr(l_line, instr(l_line, ' ')));
  
    -- assign line number
    o_lineno := to_number(substr(l_line, 1, instr(l_line, ' ')));
    l_line   := ltrim(substr(l_line, instr(l_line, ' ')));
  
    -- strip out object type
    l_line := ltrim(substr(l_line, instr(l_line, ' ')));
  
    -- if 'package body' or 'anonymous block', strip out second piece
    IF l_line LIKE 'block%' OR l_line LIKE 'body%' THEN
      l_line := ltrim(substr(l_line, instr(l_line, ' ')));
    END IF;
  
    -- assign owner and object name
    o_owner  := ltrim(rtrim(substr(l_line, 1, instr(l_line, '.') - 1)));
    o_object := ltrim(rtrim(substr(l_line, instr(l_line, '.') + 1)));
  
    o_call_stack := l_call_stack;
  
    IF o_owner IS NULL THEN
      o_owner  := USER;
      o_object := 'ANONYMOUS BLOCK';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END p_call_trace;

  -- 记录错误日志
  PROCEDURE err(i_msglevel IN INTEGER DEFAULT NULL) AS
    v_msglevel   INTEGER;
    v_ownername  VARCHAR2(255);
    v_objname    VARCHAR2(255);
    v_lineno     INTEGER;
    v_msgcode    VARCHAR2(100);
    v_msg        VARCHAR2(4000);
    v_call_stack VARCHAR2(4000);
  BEGIN
    -- 如果日志级别小于日志打印级别，则直接退出
    IF i_msglevel IS NULL THEN
      v_msglevel := 1;
    ELSE
      v_msglevel := i_msglevel;
    END IF;
  
    IF f_getloglevel > v_msglevel THEN
      RETURN;
    END IF;
  
    -- 过程调用信息
    p_error_trace(o_owner => v_ownername, o_object => v_objname, o_lineno => v_lineno, o_errcode => v_msgcode, o_errmsg => v_msg, o_call_stack => v_call_stack);
    IF v_lineno IS NULL THEN
      v_lineno := 0;
    END IF;
  
    p_ins(i_call_stack => v_call_stack, i_ownername => v_ownername, i_objname => v_objname, i_lineno => v_lineno, i_msglevel => v_msglevel, i_msgcode => v_msgcode, i_msg => v_msg);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END err;

  /***************************************************************************************************
  确定打印日志的位置(内部)
  
  本过程返回错误信息以及错误信息产生的位置
  
  1.使用dbms_utility.format_error_stack()来获取错误信息
    例；
      ORA-01476: divisor is equal to zero
  
  2.使用dbms_utility.format_error_backtrace()来获取错误信息产生的位置
    例：
      匿名块
      ORA-06512: at line 4
      
      过程
      ORA-06512: at "EXCH3.T1", line 4
      
      过程嵌套
      ORA-06512: at "EXCH3.P0", line 4
      ORA-06512: at "EXCH3.P1", line 3
      ORA-06512: at "EXCH3.P2", line 3
      ORA-06512: at "EXCH3.P3", line 3
      ORA-06512: at "EXCH3.P4", line 2
      ORA-06512: at "EXCH3.P5", line 2
      ORA-06512: at "EXCH3.TOP_WITH_LOGGING", line 6
      
  ***************************************************************************************************/
  PROCEDURE p_error_trace
  (
    o_owner      OUT VARCHAR2, -- 对象所有者
    o_object     OUT VARCHAR2, -- 对象名
    o_lineno     OUT NUMBER, -- 行号
    o_errcode    OUT VARCHAR2, -- 错误代码
    o_errmsg     OUT VARCHAR2, -- 错误信息
    o_call_stack OUT VARCHAR2
  ) AS
    l_error      VARCHAR2(4000) DEFAULT dbms_utility.format_error_stack(); -- 错误信息
    l_call_stack VARCHAR2(4000) DEFAULT dbms_utility.format_error_backtrace(); -- 错误信息调用栈
    l_line       VARCHAR2(4000); -- 栈里面的1行
  BEGIN
    -- 1.没有取到错误信息直接退回
    IF l_error IS NULL THEN
      RETURN;
    END IF;
  
    -- 2.处理错误信息
    -- 截取错误信息第1行
    IF instr(l_error, chr(10)) > 0 THEN
      l_error := substr(l_error, 1, instr(l_error, chr(10)) - 1);
    ELSE
      l_error := l_error;
    END IF;
  
    -- 错误代码
    o_errcode := substr(l_error, 1, instr(l_error, ':') - 1);
  
    -- 错误信息
    o_errmsg := l_error;
  
    -- 3.处理错误信息调用栈
    -- 截取调用栈最后1行
    IF instr(l_call_stack, chr(10)) > 0 THEN
      l_line := substr(l_call_stack, instr(l_call_stack, chr(10), -2) + 1);
    ELSE
      l_line := l_call_stack;
    END IF;
  
    l_line := substr(l_line, instr(l_line, 'at') + 2);
  
    l_line := REPLACE(l_line, chr(10));
    l_line := REPLACE(l_line, chr(13));
  
    -- 行号
    o_lineno := to_number(TRIM(substr(l_line, instr(l_line, ' line ') + 6)));
  
    -- 获取对象名
    IF instr(l_line, '"') > 0 THEN
    
      -- 截取对象信息
      l_line := substr(l_line, instr(l_line, '"') + 1);
      l_line := substr(l_line, 1, instr(l_line, '"') - 1);
    
      -- 对象所有者
      o_owner := ltrim(rtrim(substr(l_line, 1, instr(l_line, '.') - 1)));
    
      -- 对象名
      o_object := ltrim(rtrim(substr(l_line, instr(l_line, '.') + 1)));
    END IF;
  
    o_call_stack := l_call_stack;
  
    -- 对象名为空，则当前对象为匿名块
    IF o_owner IS NULL THEN
      o_owner  := USER;
      o_object := 'ANONYMOUS BLOCK';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END p_error_trace;

  PROCEDURE p_ins
  (
    i_call_stack IN VARCHAR2,
    i_ownername  IN VARCHAR2,
    i_objname    IN VARCHAR2,
    i_lineno     IN INTEGER,
    i_msglevel   IN INTEGER, -- 日志级别
    i_msgcode    IN VARCHAR2, -- 日志代码
    i_msg        IN CLOB
  ) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO mylog
      (msgdate, call_stack, ownername, objname, lineno, msglevel, msgcode, msg)
    VALUES
      (systimestamp, i_call_stack, i_ownername, i_objname, i_lineno, i_msglevel, i_msgcode, i_msg);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
  END;

  -- 取系统日志级别(内部)
  FUNCTION f_getloglevel RETURN INTEGER IS
    loglevel INTEGER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT to_number(val) FROM sys_config2 t WHERE code = :code AND rownum = 1'
      INTO loglevel
      USING 'cf99';
    RETURN loglevel;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END f_getloglevel;
END mydebug;
/
