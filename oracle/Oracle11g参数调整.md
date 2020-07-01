# Oracle 11g安装后的设置

在 Oracle  11g 安装并建库后，需要进行一些调整，使数据库能够稳定、高效地运行。除了对数据库使用手工内存管理之外，还需要进行如下的调整。  

## 1. 针对RAC数据库的参数调整  

alter system set parallel_force_local=true sid='*' scope=spfile;
说明：这个参数是 11g 的新增参数，用于将并行的 slave 进程限制在发起并行 SQL 的会话所在的节点，即避免跨节点并行产生大量的节点间数据交换和引起性能问题。 这个参数用于取代 11g 之前 instance_groups和parallel_instance_group 参数设置。
alter system set "_gc_policy_time"=0 sid='*' scope=spfile;
alter system set "_gc_undo_affinity"=false scope=spfile;
说明：这两个参数用于关闭 RAC 的 DRM（dynamic remastering）特性，避免频繁的 DRM 使系统性能不稳定、严重的时候使数据库挂起。同时也关闭 Read-mostly Locking 新特性，这个特性目前会触发大量的 BUG，严重时使数据库实例宕掉。  
针对 11g RAC，需要注意的是如果节点的 CPU 数量不一样，这可能导致推导出来的 lms 进程数量不一样，根据多个案例的实践来看，lms 数量不一样在高负载时会产生严重的性能问题，在此种情况下，需要手工设置 gcs_server_processes 参数，使 RAC 数据库所有节点的 lms 进程数相同。

## 2.  RAC数据库和非RAC数据库都适用的参数调整  

alter system set "_optimizer_adaptive_cursor_sharing"=false sid='*' scope=spfile;
alter system set "_optimizer_extended_cursor_sharing"=none sid='*' scope=spfile;
alter system set "_optimizer_extended_cursor_sharing_rel"=none sid='*' scope=spfile;
alter system set "_optimizer_use_feedback"=false    sid ='*' scope=spfile;  
说明：这几个参数都是用于关闭 11g 的 adaptive cursor sharing、cardinality feedback 特性，避免出现SQL性能不稳定、SQL子游标过多的问题。  

alter system set deferred_segment_creation=false sid='*' scope=spfile;
说明：这个参数用于关闭 11g 的段延迟创建特性，避免出现这个新特性引起的 BUG，比如数据导入导出 BUG、表空间删除后对应的表对象还在数据字典里面等。  
alter  system set  event='28401  trace  name  context  forever,level  1','10949  trace  name  context forever,level 1' sid='*' scope=spfile;
说明：这个参数主要设置 2 个事件:
    1） 10949 事件用于关闭 11g 的自动 serial direct path read 特性，避免出现过多的直接路径读，消耗过多的 IO 资源。
    2） 28401 事件用于关闭 11g 数据库中用户持续输入错误密码时的延迟用户验证特性，避免用户持续输入错误密码时产生大量的 row cache lock 或 library cache lock 等待，严重时使数据库完全不能登录。

alter system set resource_limit=true sid='*' scope=spfile;
alter system set resource_manager_plan='force:' sid='*' scope=spfile;
说明：这两个参数用于将资源管理计划强制设置为“ 空 ”，避免 Oracle 自动打开维护窗口（每晚 22:00 到早上 6:00，周末全天）的资源计划（resource manager plan），使系统在维护窗口期间资源不足或触发相应的 BUG。  

alter system set "_undo_autotune"=false sid='*' scope=spfile;
说明：关闭 UNDO 表空间的自动调整功能，避免出现 UNDO 表空间利用率过高或者是 UNDO段争用的问题。  

alter system set "_optimizer_null_aware_antijoin"=false sid ='*' scope=spfile;
说明：关闭优化器的 null aware antijoin 特性，避免这个新特性带来的 BUG。  

alter system set "_px_use_large_pool"=true    sid ='*' scope=spfile;
说明：11g 数据库中，并行会话默认使用的是 shared pool 用于并行执行时的消息缓冲区，并行过多时容易造成 shared  pool 不足，使数据库报 ORA-4031 错误。将这个参数设置为 true，使并行会话改为使用 large pool。  

--考虑关闭审计（oracle 11g 默认打开审计）
alter system set audit_trail=none sid='*' scope=spfile;
说明：11g 默认打开数据库审计，为了避免审计带来的 SYSTEM 表空间的过多占用，可以关闭审计。  

alter system set "_partition_large_extents"=false sid='*' scope=spfile;
alter system set "_index_partition_large_extents"=false sid='*' scope=spfile;
说明：在 11g 里面，新建分区会给一个比较大的初始 extent 大小（8M）， 如果一次性建的分区很多，比如按天建的分区，则初始占用的空间会很大。  

alter system set "_use_adaptive_log_file_sync"=false sid='*' scope=spfile;
说明：11.2.0.3 版本里面，这个参数默认为 true，LGWR 会自动选择两种方法来通知其他进程 commit 已经写入：post/wait、polling。前者 LGWR 负担较重，后者等待时间会过长，特别是高负载的 OLTP 系统中。在 10g 及之前的版本中是 post/wait 方式，将这个参数设置为 false恢复到以前版本方式。  

alter system set "_memory_imm_mode_without_autosga"=false sid='*' scope=spfile;
说明：11.2.0.3 版本里面，即使是手工管理内存方式下，如果某个 POOL 内存吃紧，Oracle仍然可能会自动调整内存，用这个参数来关闭这种行为。  

alter system set enable_ddl_logging=true sid='*'    scope=spfile;
说明：在 11g 里面，打开这个参数可以将 ddl 语句记录在 alert 日志中。以便于某些故障的排查。建议在 OLTP 类系统中使用。  

alter system set parallel_max_servers=64 sid='*'    scope=spfile;
说明：这个参数默认值与 CPU 相关，OLTP 系统中将这个参数设置小一些，可以避免过多的并行对系统造成冲击。

alter system set sec_case_sensitive_logon=false sid='*'    scope=spfile;
说明：从 11g 开始，用户密码区分大小写，而此前的版本则是不区分大小写，在升级时，如果这个参数保持默认值 TRUE，可能会使一些应用由于密码不正确而连接不上。  

alter system set “_b_tree_bitmap_plans”=false sid=’*’ scope=spfile;
说明：对于 OLTP 系统，Oracle 可能会将两个索引上的 ACCESS PATH 得到的 rowid 进行 bitmap操作再回表，这种操作有时逻辑读很高，对于此类 SQL 使用复合索引才能从根本上解决问题.

## 3. 其他调整  

alter profile "DEFAULT" limit PASSWORD_GRACE_TIME UNLIMITED;
alter profile "DEFAULT" limit PASSWORD_LIFE_TIME UNLIMITED;
alter profile "DEFAULT" limit PASSWORD_LOCK_TIME UNLIMITED;
alter profile "DEFAULT" limit FAILED_LOGIN_ATTEMPTS UNLIMITED;
说明：11g 默认会将 DEFAULT 的 PROFILE 设置登录失败尝试次数（10 次）。这样在无意或恶意的连续使用错误密码连接时，导致数据库用户被锁住，影响业务。因此需要将登录失败尝试次数设为不限制。  

exec dbms_scheduler.disable( 'ORACLE_OCM.MGMT_CONFIG_JOB' );
exec dbms_scheduler.disable( 'ORACLE_OCM.MGMT_STATS_CONFIG_JOB' );
说明：关闭一些不需要的维护任务，这两个属于 ORACLE_OCM 的任务不关闭，可能会在 alert日志中报错。  

考虑是否要关闭自动统计信息收集 BEGIN DBMS_AUTO_TASK_ADMIN.DISABLE( client_name => 'auto optimizer stats collection', operation => NULL, window_name => NULL); END; /
说明：如果是需要采用手工收集统计信息策略，则关闭统计信息自动收集任务。  考虑是否要关闭自动收集直方图
exec DBMS_STATS.SET_GLOBAL_PREFS( 'method_opt','FOR ALL COLUMNS SIZE 1' );
或者
exec DBMS_STATS.SET_PARAM( 'method_opt','FOR ALL COLUMNS SIZE 1' );
说明：为减少统计信息收集时间，同时为避免直方图引起的 SQL 执行计划不稳定，可以在数据库全局级关闭自方图的 收集，对于部分需要收集直方图的表列，可以使用DBMS_STATS.SET_TABLE_PREFS 过程来设置。  

关闭auto space advisor
BEGIN
    DBMS_AUTO_TASK_ADMIN.DISABLE(
        client_name => 'auto space advisor',
        peration => NULL,
        window_name => NULL
        );
    END;
    /
说明：关闭数据库的空间 Advisor，避免消耗过多的 IO，还 有 避 免 出现这个任务引起的 library cache lock。  

关闭auto sql tuning
BEGIN
    DBMS_AUTO_TASK_ADMIN.DISABLE(
        client_name => 'sql tuning advisor',
        operation => NULL,
        window_name => NULL);
    END;
    /
说明：关闭数据库的 SQL 自动调整 Advisor，避免消耗过多的资源。  

调整时间窗口:
EXECUTE DBMS_SCHEDULER.SET_ATTRIBUTE('SATURDAY_WINDOW','repeat_interval','freq=daily;byday=SAT;byhour=22;byminute=0;bysecond=0');
EXECUTE DBMS_SCHEDULER.SET_ATTRIBUTE('SUNDAY_WINDOW','repeat_interval','freq=daily;byday=SUN;byhour=22;byminute=0;bysecond=0');
EXEC DBMS_SCHEDULER.SET_ATTRIBUTE('SATURDAY_WINDOW', 'duration', '+000 08:00:00');
EXEC DBMS_SCHEDULER.SET_ATTRIBUTE('SUNDAY_WINDOW', 'duration', '+000 08:00:00');  
exec dbms_scheduler.disable('WEEKNIGHT_WINDOW', TRUE);
exec dbms_scheduler.disable('WEEKEND_WINDOW', TRUE);  
说明：一些业务系统即使在周末，也同样处于正常的业务工作状态，比如面向公众的业务系统，在月底（虽然是周末）有批处理操作的系统，以及节假日调整的周末等，建议调整周六和周日窗口的起止时间和窗口时间长度，避免有时候周六或周日影响业务性能.
