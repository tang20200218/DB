-- 处理平台印制易自动写签发队列表的JOB
declare
  v_cnt int:=0;
begin
  select count(1) INTO v_cnt from dba_scheduler_jobs t where t.OWNER='EVS' AND t.JOB_NAME='PLATFORM_JOB';
  IF v_cnt = 0 THEN
    sys.dbms_scheduler.create_job(job_name        => 'EVS.PLATFORM_JOB',
                                  job_type        => 'PLSQL_BLOCK',
                                  job_action      => 'pkg_platform_job.p_auto();',
                                  start_date      => to_date('2023-01-01 22:00:00','yyyy-mm-dd hh24:mi:ss'),
                                  repeat_interval => 'Freq=Minutely;Interval=1',
                                  end_date        => null,
                                  job_class       => 'DEFAULT_JOB_CLASS',
                                  enabled         => true,
                                  auto_drop       => false,
                                  comments        => '');
  ELSE
    sys.dbms_scheduler.drop_job(job_name          => 'EVS.PLATFORM_JOB');
    sys.dbms_scheduler.create_job(job_name        => 'EVS.PLATFORM_JOB',
                                  job_type        => 'PLSQL_BLOCK',
                                  job_action      => 'pkg_platform_job.p_auto();',
                                  start_date      => to_date('2023-01-01 22:00:00','yyyy-mm-dd hh24:mi:ss'),
                                  repeat_interval => 'Freq=Minutely;Interval=1',
                                  end_date        => null,
                                  job_class       => 'DEFAULT_JOB_CLASS',
                                  enabled         => true,
                                  auto_drop       => false,
                                  comments        => '');
  END IF;
end;
/

-- 自动分发空白凭证的JOB
declare
  v_cnt int:=0;
begin
  select count(1) INTO v_cnt from dba_scheduler_jobs t where t.OWNER='EVS' AND t.JOB_NAME='YZ_SQ_REPLY_QUEUE1';
  IF v_cnt = 0 THEN
    sys.dbms_scheduler.create_job(job_name        => 'EVS.YZ_SQ_REPLY_QUEUE1',
                                  job_type        => 'PLSQL_BLOCK',
                                  job_action      => 'pkg_yz_sq_reply_queue1.p_auto();',
                                  start_date      => to_date('2023-01-01 22:00:00','yyyy-mm-dd hh24:mi:ss'),
                                  repeat_interval => 'Freq=Secondly;Interval=30',
                                  end_date        => null,
                                  job_class       => 'DEFAULT_JOB_CLASS',
                                  enabled         => true,
                                  auto_drop       => false,
                                  comments        => '');
  ELSE
    sys.dbms_scheduler.drop_job(job_name          => 'EVS.YZ_SQ_REPLY_QUEUE1');
    sys.dbms_scheduler.create_job(job_name        => 'EVS.YZ_SQ_REPLY_QUEUE1',
                                  job_type        => 'PLSQL_BLOCK',
                                  job_action      => 'pkg_yz_sq_reply_queue1.p_auto();',
                                  start_date      => to_date('2023-01-01 22:00:00','yyyy-mm-dd hh24:mi:ss'),
                                  repeat_interval => 'Freq=Secondly;Interval=30',
                                  end_date        => null,
                                  job_class       => 'DEFAULT_JOB_CLASS',
                                  enabled         => true,
                                  auto_drop       => false,
                                  comments        => '');
  END IF;
end;
/

