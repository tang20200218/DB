-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 交换动态SQL-DATA_EXCH_SQL
-- 第1个参数:i_ 业务类型
-- 第2个参数:i_ 数据类型(1:i_收件 2:i_接收送交换成功的状态)
-- 第3个参数:i_ 存储过程
   
-- 存储过程参数说明
-- 1:i_收件，6个入参，可以只接收部分参数
-- :i_exchid, :i_exchtempl, :i_exchstatus, :i_forminfo, :i_filepath, :i_taskid, :o_code, :o_msg
-- exchid     交换ID
-- exchtempl  交换模板
-- exchstatus 交换状态
-- forminfo   表单信息
-- filepath   文件绝对路径，不带文件名，每个接收任务中的所有文件都存放在相同目录
-- taskid     收件ID，按文件名查询、删除文件信息时使用
   
-- 2:i_接收送交换成功的状态，支持2种参数
-- :i_exchid, :o_code, :o_msg
-- :i_docid, :o_code, :o_msg
-- docid  = data_exch_status.docid
-- exchid = data_exch_status.exchid
   
-- 查询SQL
-- select * from DATA_EXCH_SQL;
   
-- 删除SQL
-- truncate table DATA_EXCH_SQL;
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


call proc_sql_register('proxy'      ,'1','call EVS.pkg_proxy.p_receive(:i_forminfo, :o_code, :o_msg)');
call proc_sql_register('site'       ,'1','call EVS.pkg_exch_mysite.p_receive(:i_forminfo, :o_code, :o_msg)');
call proc_sql_register('EVC_TURNS'  ,'1','call EVS.pkg_exch_to_site_er.p_receive(:i_forminfo, :o_code, :o_msg)');
call proc_sql_register('dept'       ,'1','call EVS.pkg_platform_er.p_dept(:i_forminfo, :o_code, :o_msg)');
call proc_sql_register('user'       ,'1','call EVS.pkg_platform_er.p_user(:i_forminfo, :o_code, :o_msg)');
call proc_sql_register('EVC_OBJDEL' ,'1','call EVS.pkg_platform_er.p_objdel(:i_forminfo, :o_code, :o_msg)');
call proc_sql_register('bind'       ,'1','call EVS.pkg_info_template_er_bind.p_receive(:i_forminfo, :o_code, :o_msg)');
call proc_sql_register('ywcode'     ,'1','call EVS.pkg_info_template_er_ywcode.p_receive(:i_forminfo, :o_code, :o_msg)');
call proc_sql_register('ywcodenew'  ,'1','call EVS.pkg_info_template_er_ywcode.p_receive(:i_forminfo, :o_code, :o_msg)');
call proc_sql_register('tfile'      ,'1','call EVS.pkg_info_template_er_tfile.p_receive(:i_exchid, :i_forminfo, :i_filepath, :i_taskid, :o_code, :o_msg)');
call proc_sql_register('SQ01'       ,'1','call EVS.pkg_yz_sq_er.p_add(:i_exchid, :i_exchstatus, :i_forminfo, :o_code, :o_msg)');
call proc_sql_register('EVS_SQ04'   ,'1','call EVS.pkg_yz_sq_er.p_del(:i_forminfo, :o_code, :o_msg)');
call proc_sql_register('SQ02'       ,'1','call EVS.pkg_sq_er.p_disp(:i_exchid, :i_forminfo, :i_filepath, :i_taskid, :o_code, :o_msg)');
call proc_sql_register('EVS_SQ03'   ,'1','call EVS.pkg_sq_er.p_refuse(:i_forminfo, :o_code, :o_msg)');
call proc_sql_register('EVC_ES01'   ,'1','call EVS.pkg_qf_apply_er.p_receive(:i_exchid, :i_forminfo, :i_filepath, :i_taskid, :o_code, :o_msg)');
call proc_sql_register('SQ05'       ,'1','call EVS.pkg_qf_apply_er.p_sq05(:i_exchid, :i_forminfo, :i_filepath, :i_taskid, :o_code, :o_msg)');
call proc_sql_register('QD01'       ,'1','call EVS.pkg_op_websrv.p_exchoper(:i_exchid, :i_forminfo, :i_filepath, :i_taskid, :o_code, :o_msg)');
call proc_sql_register('SQ02'       ,'2','call EVS.pkg_yz_sq_reply_queue1.p_sendfinish(:i_docid, :o_code, :o_msg)');
call proc_sql_register('GG11'       ,'2','call EVS.pkg_qf_book_er.p_sendfinish(:i_docid, :o_code, :o_msg)');
call proc_sql_register('whzwclient' ,'1','call EVS.pkg_client.p_receive(:i_exchid, :i_forminfo, :i_filepath, :i_taskid, :o_code, :o_msg)');
call proc_sql_register('EVS_ES03'   ,'1','call EVS.pkg_qf2_er.p_add(:i_exchid, :i_forminfo, :i_filepath, :i_taskid, :o_code, :o_msg)');

