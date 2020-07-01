# Oracle 12c最佳参数实践

## 一、显示参数设置

Num|参数名称|建议值|设置命令|重启|说明
-|-|-|-|-|-
1|control_files|设置3个副本|alter system set control_files='path1','path2','path2' scope=spfile;|是|设置3个
2|recyclebin|on|alter system set recyclebin=on scope=spfile;|否|默认为on，推荐开启回收站，并且建议定期清理回收站
3|undo_retention|5400|alter system set undo_retention=5400 scope=spfile;|否|undo默认保留期为900秒，建议设置为5400秒或更大(在_undo_autotune=false的情况下)
4|processes|2000|alter system set processes=2000 scope=spfile;|是|默认为150，建议根据实际情况修改
5|db_files|2000|alter system set db_files=2000 scope=spfile;|是|默认为200，建议调大
6|audit_trail|none|alter system set audit_trail=none scope=spfile;|是|默认为DB，建议设置为none，关闭审计
7|memory_max_target|0|alter system set memory_max_target=0 scope=spfile;|是|设置为0，禁用AMM
8|memory_target|0|alter system set memory_target=0 scope=spfile;|是|-
9|sga_max_size|memort*70%|alter system set sga_max_size=N scope=spfile;|是|使用自动共享内存管理(ASMM)
10|sga_target|memort*70%|alter system set sga_target=N scope=spfile;|是|使用自动共享内存管理(ASMM)
11|pga_aggregate_target|memort*20%|alter system set pga_aggregate_target=N scope=spfile;|否|设置pga大小
12|max_dump_file_size|104857600|alter system set max_dump_file_size=104857600 scope=spfile;|否|设置dump文件的大小，默认值为不限制，建议设置为104857600(100M)
13|parallel_force_local|TRUE|alter system set parallel_force_local=true scope=spfile;|否|RAC环境，禁用跨节点并行
14|control_file_record_keep_time|31|alter system set control_ﬁle_record_keep_time=31 scope=spﬁle;|否|默认7天，建议控制文件中的元数据保存时间设置为31天
15|parallel_max_servers|96|alter system set parallel_max_servers=96 scope=spﬁle;|否|设置数据库的最大并发度，新核心系统数据库服务器的逻辑cpu数是96,OLTP系统建议要设置太大。
16|parallel_min_servers|0|alter system set parallel_min_servers=0 scope=spﬁle;|否|设置数据库实例启动时默认启动的最小并发进程，新核心系统数据库服务的逻辑cpu数是96
17|open_cursors|1000|alter system set open_cursors=1000 scope=spﬁle;|否|当前值为300，open_cursors参数用于指定一个会话能同时打开游标的最大数目
18|utl_file_dir|/tmp|alter system set utl_ﬁle_dir='/tmp' scope=spﬁle;|是|建议调整为指定目录，如/tmp
19|resource_manager_plan|FORCE:'|alter system set resource_manager_plan='FORCE:' scope=spﬁle;|否|关闭资源计划
20|deferred_segment_creation|FALSE|alter system set deferred_segment_creation=FALSE scope=spﬁle;|否|默认值TRUE，禁掉延迟段分配。档ID 1590806.1 High Waits on 'library cache: mutex X' Inserting into a Partitioned Table when DEFERRED_SEGMENT_CREATION = TRUE
21|fast_start_parallel_rollback|LOW'|alter system set fast_start_parallel_rollback='LOW' scope=spﬁle;|否|在恢复终止事务时，fast_start_parallel_rollback参数用于指定以多少个并行度来恢复终止事务。建议设置为LOW,默认值LOW，FALSE：Parallel rollback is disabled，LOW：Limits the maximum degree of parallelism to 2 * CPU_COUNT，HIGH：Limits the maximum degree of parallelism to 4 * CPU_COUNT
22|pga_aggregate_limit|0|alter system set pga_aggregate_limit=0 scope=spﬁle;|否|设置为0，表示实例所使用的 PGA 内存总量没有限制。ID 2053549.1
23|optimizer_adaptive_features|FALSE|alter system set optimizer_adaptive_features=FALSE scope=spﬁle;|否|多列统计信息自动收集功能是自适应查询优化器的一部分，一般来说自动功能bug比较多，建议设置为fasle进行规避。only disables extended statistics auto collection Doc ID 1964223.1
24|sec_case_sensitive_logon|FALSE|alter system set sec_case_sensitive_logon=FALSE scope=spﬁle;|否|说明：从11g开始，用户密码区分大小写，而此前的版本则是不区分大小写，在升级时，如果这个参数保持默认值TRUE，可能会使一些应用由于密码不正确而连接不上。
25|temp_undo_enabled|FALSE|alter system set temp_undo_enabled=FALSE scope=spﬁle;|否|如果该参数设置为true，可能会使得执行时间很短的sql语句抛出ORA-1555错误，另外还容易报ORA-600错误。建议设置为false，规避上术问题。Bug 20301061 - ORA-1555 with short duration sqls or possible ORA-600 [kdblkcheckerror] [tmpﬁle#] [block#] [14508] when temp_undo_enabled set to true (文档 ID 20301061.8)
26|session_cached_cursors|300|alter system set session_cached_cursors=300 scope=spﬁle;|是|该参数默认值为50，指定会话可缓存在用户私有区的游标数目。建议调大，设置为300
27|max_shared_servers|0|alter system set max_shared_servers=0 scope=spﬁle;|否|数据库默认连接方式为独占模式，共享连接模式几乎不用，建议设置为0关闭。
28|shared_servers|0|alter system set shared_servers=0 scope=spﬁle;|否|-
29|sec_max_failed_login_attempts|100|alter system set sec_max_failed_login_attempts=100 scope=spﬁle;|是|默认值太小，建议调大。该参数只对使用了OCI 的特定程序生效，而使用SQLPLUS是无法生效SEC_MAX_FAILED_LOGIN_ATTEMPTS only works application uses OCI Program.SEC_MAX_FAILED_LOGIN_ATTEMPTS not work in sqlplus.OCI Program have the following ,it wil work.1) You need to use OCI_THREADED mode.2) You need to set the attribute ofserver, username, password attributes in the appropriate handles:3) You need to useOCISessionBegin to connect to the database
30|open_links|40|alter system set open_links=40 scope=spﬁle;|是|默认为4，建议调为40该参数指定每一个会话可以并发打开对远程数据库的连接的最大数目。OPEN_LINKS speciﬁes the maximum number of concurrent open connections to remote databases in one session.31|open_links_per_instance|40|alter system set open_links_per_instance=40 scope=spﬁle;|是|默认为4，建议调大为40该参数指定每个实例可以打开的最大的数据库连接。用于XA事务，一般通过共享的dblink进行连接，共享的dblink在事务提交后仍然被缓存在内存中，供下一个连接使用。OPEN_LINKS_PER_INSTANCE speciﬁes the maximum number of migratable open connections globally for each database instance.
32|result_cache_max_size|0|alter system set result_cache_max_size=0 scope=spﬁle;|否|此参数设置结果缓存的内存。设置为0，会禁用结果缓存。避免出现性能问题。

## 二、隐含参数设置

Num|参数名称|建议值|设置命令|重启|说明|参考
-|-|-|-|-|-|-
1|_cleanup_rollback_entries|20000|alter system set "_cleanup_rollback_entries"=20000 scope=spﬁle;|是|默认值100该参数指定回滚时每次回滚的ENTRIES个数，设置成20000加快回滚速度。|Database Hangs Because SMON Is Taking 100% CPU Doing Transaction Recovery(档 ID 414242.1)
2|_clusterwide_global_transactions|FALSE|alter system set "_clusterwide_global_transactions"=FALSE scope=spﬁle;|是|默认值TRUE当_clusterwide_global_transactions=false时，ORACLE会将这些本地事务当做单独的事务通过多阶段提交协调处。|Does Oracle Commerce Require DTP Or_clusterwide_global_transactions Flags To Be Set For Oracle RAC(档 ID 1945707.1)
3|_drop_stat_segment|1|alter system set "_drop_stat_segment"=1 scope=spﬁle;|否|默认值0truncate table非常慢|文档ID： 2050196.1Once the ﬁx for BUG 23125826 is released, please apply the patchWorkaround:ALTER SYSTEM SET "_drop_stat_segment" =1;可行的方法是设置这个参数解决。
4|_external_scn_logging_threshold_seconds|21600|alter system set "_external_scn_logging_threshold_seconds"=21600 scope=spﬁle;|否|针对scn headroom 的BUG相关，有可能报 ORA-19706: invalid SCN error错误，通过设置参数可以避免。|文档 ID 1573520.1
5|_external_scn_rejection_threshold_hours|720|alter system set "_external_scn_rejection_threshold_hours"=720 scope=spﬁle;|否|JDBC Application Fails With java.sql.SQLException: Io exception: Broken pipe After Setting System Change Number SCN Parameters in the Database|-
6|_ﬁx_control|8611462:OFF','14826303:0'|alter system set "_ﬁx_control"='8611462:OFF','14826303:0' scope=spﬁle;|否|Set "_ﬁx_control"='8611462:OFF' either in the session or systemwide to avoid the problem code.并行查询分区表时，可能触发ORA-600 [qerpxMObjVI6]报错，可以在会话或者系统级别设置_ﬁx_control参数，规避问题的代码。|文档 ID 21030693.8Bug 21030693 - ORA-600 [qerpxMObjVI6] from parallel query on partitioned table
7|_gc_policy_time|0|alter system set "_gc_policy_time"=0 scope=spﬁle;|是|参数默认值是10关闭DRM特性,DRM在11G中不稳定，存在众多BUG|文档 ID 14588746.8Bug 14588746 - ORA-600 [kjbmprlst:shadow] in LMS in RAC - crashes the instance
8|_ges_direct_free_res_type|CTARAHDXBB'|alter system set "_ges_direct_free_res_type"='CTARAHDXBB' scope=spﬁle;|是|默认值CT，在有许多分布式事务或者XA事务的RAC环境中，"ges resource dynamic"过度使共享池可能会导致ORA-4031错误或者实例崩溃。比如如内存不足，以至于LMD进程无法响应，导致出现ORA-4031错误或者实例被终止。设置参数_ges_direct_free_res_type="CTARAHDXBB"解决。|文档 ID 21373473.8Bug 21373473 - Excess "ges resource dynamic" memory use / ORA-4031 / instance crash in RAC with many distributed transactions/XA
9|_keep_remote_column_size|TRUE|alter system set "_keep_remote_column_size"=TRUE scope=spﬁle;|是|-|文档 ID374744.1Using a Gateway with a Unicode Oracle Database Increases the Column Precision Three Times for Certain Data Type
10|_memory_imm_mode_without_autosga|FALSE|alter system set "_memory_imm_mode_without_autosga"=FALSE scope=spﬁle;|否|默认TRUE保证memory_target和sga_target都是0时，也不会出现SGA内存调整。|档 ID 20124446.8Bug 20124446 - Deadlock including MMAN and ORA-29770 is possible in RAC environment without automatic memory management在RAC环境中，没有使用自动（共享）内存管理，也就是memory_target和sga_target都是0时，MMAN进程可能变换成包含LMD0死锁的情况，报ORA-29770错误，通过设置参数避免。
11|_optimizer_adaptive_plans|FALSE|alter system set "_optimizer_adaptive_plans"=FALSE scope=spﬁle;|否|默认TRUE，关闭自适应执行计划|文档 ID 1945816.1ORA-12850: COULD NOT ALLOCATE SLAVES ON ALL SPECIFIED INSTANCES: 2 NEEDED, 1 ALLOCATED with "_optimizer_adaptive_plans" enabled
12|_optimizer_aggr_groupby_elim|FALSE|alter system set "_optimizer_aggr_groupby_elim"=FALSE scope=spﬁle;|否|默认值TRUE|文档ID 19567916.8，Wrong results when GROUP BY uses nested queries in 12.1.0.2在12.1.0.2中，嵌套子查询中使用了GROUP BY可能会导致错误的结果集，设置"_optimizer_aggr_groupby_elim"=false可解决。
13|_optimizer_gather_feedback|FALSE|alter system set "_optimizer_gather_feedback"=FALSE scope=spﬁle;|否|默认TURE，执行反馈的收集功能可能导致ORA-4031错误，通过设置该参数为false，禁止优化器中执行反馈的收集。|Bug 20370037 - memory leak kglh0 growth leading to ORA-4031 (文档 ID 20370037.8)
14|_optimizer_reduce_groupby_key|FALSE|alter system set "_optimizer_reduce_groupby_key"=FALSE scope=spﬁle;|否|默认值TRUE，在某些情况下，使用了绑定变量和group by子句的外连接查询可能会导致错误的结果。解决方法是设置参数为FALSE。|Bug 20634449 - Wrong results from OUTER JOIN with a bind variable and a GROUP BY clause in 12.1.0.2 (文档 ID 20634449.8)
15|_optimizer_use_feedback|FALSE|alter system set "_optimizer_use_feedback"=FALSE scope=spﬁle;否默认值TRUE当优化器发现基数不准确时，会在下一次重新硬解析，执󰀉计划中会出现以下信息：- Cardinality Feedback used for this statement|文档 ID 16837274.8Bug 16837274 - Cardinality feedback produces poor subsequent plan
16|_PX_use_large_pool|TRUE|alter system set "_PX_use_large_pool"=TRUE scope=spﬁle;|是|默认FALSE并发执行从属进程一起共作时交换数据和信息，从large pool中分配内存，FALSE时从shared pool分配内存|文档 ID 238680.1Parallel Execution: Large/Shared Pool and ORA-4031
17|_report_capture_cycle_time|0|alter system set "_report_capture_cycle_time"=0 scope=spﬁle;|否|默认60，在12.1版本中，MMON进程执行监控查询可能导致CPU使用过高，或者频繁出现ORA-12850错误。设置为0禁用该功能，减少CPU消耗。|文档 ID 2102131.1High CPU Usage and/or Frequent Occurances of ORA-12850 For Monitor Queries by MMON From 12.1
18|_secureﬁles_concurrency_estimate|50|alter system set "_secureﬁles_concurrency_estimate"=50 scope=spﬁle;|是|默认值12说明：减少对LOBs字段频繁的update|文档 ID 1532311.1Secureﬁles DMLs cause high 'buffer busy waits' & 'enq: TX - contention' wait events leading to whole database performance degradation
19|_sql_plan_directive_mgmt_control|0|alter system set "_sql_plan_directive_mgmt_control"=0 scope=spﬁle;|否|统计反馈收集的SQL运行时的统计信息会保存在相应的共享游标中，但却不能够持久化，当数据库重启或者被优化的SQL文本从内存中Age-out后，保存的信息就会丢失。下一次执行时还要重新进行一遍自动重新优化。|文档 ID 20465582.8Bug 20465582 - High parse time in 12c for multi-table join SQL with SQL plan directives enabled – superseded
20|_optimizer_dsdir_usage_control|0|alter system set "_optimizer_dsdir_usage_control"=0 scope=spﬁle;|否|为了缓解这个问题Oracle 12c推出了SQL指令计划（SQL Plan Directives）功能，保存为了以后生成最优执行计划的一些指令和附加信息到字典表中，达到持久化的目的。在sql指令计划启时，你会看到oracle12c中多表连接的复杂查询的解析时间更长，这时也许要怀疑命中这个bug。把这两个参数设置为0，禁止该功能，屏蔽bug。
21|_undo_autotune|FALSE|alter system set "_undo_autotune"=FALSE scope=spﬁle;|否|默认TRUE，设置FALSE即关闭undo retention自动调整
22|_use_single_log_writer|TRUE|alter system set "_use_single_log_writer"='TRUE' scope=spﬁle;|是|默认值ADAPTIVE，12c的新特性中lgwr是多个进程，该新特性容易导致lgwr进程夯住，而当lgwr进程夯住时，仅有的解决方法是重启数据库实例。为了避免lgwr夯住，通过设置参数_use_single_log_writer='TRUE'来禁该功能。设置之后就变成一个lgwr进程了。|文档 ID 21915719.8 Bug 21915719 - 12c Hang: LGWR waiting for 'lgwr any worker group' or ORA-600 [kcrfrgv_nextlwn_scn] ORA-600 [krr_process_read_error_2] on IBM AIX / HPIA
23|_use_adaptive_log_ﬁle_sync|FALSE|alter system set "_use_adaptive_log_ﬁle_sync"=FALSE scope=spﬁle;|否|说明：11.2.0.3版本里面，这个参数默认为true，LGWR会自动选择两种方法来通知其他进程commit已经写入：post/wait、polling。前者LGWR负担较重，后者等待时间会过长，特别是高负载的OLTP系统中。在10g及之前的版本中是post/wait方式，将这个参数设置为false恢复到以前版本方式。
24|_serial_direct_read|NEVER|alter system set "_serial_direct_read"=NEVER scope=spﬁle;|否|从oracle 11g开始，有个新特性（自动serial direct path read特性），在进󰀉全表扫描的时候会产direct path read等待事件，可以设置参数“_serial_direct_read”的值为“NEVER” ，禁用这个新特性。出现这个等待事件时，一般物理IO都比较大。一般情况下，新装的11g、12c数据库，建议关闭掉这个新特性。|参考Higher 'direct path read' Waits in 11g when Compared to 10g (文档 ID 793845.1)
25|_optimizer_adaptive_cursor_sharing|FALSE|alter system set "_optimizer_adaptive_cursor_sharing"=FALSE scope=spﬁle;|否|Bug 12334286 - High version counts with CURSOR_SHARING=FORCE (BIND_MISMATCH and INCOMP_LTRL_MISMATCH) (Doc ID 12334286.8)Bug 11657468 - Excessive mutex waits with adaptive cursor sharing (Doc ID 11657468.8)，为了解决bind peeking在数据有明显倾斜的时候会生成次优执󰀉计划的问题(Bind Sensitivity)
26|_optimizer_extended_cursor_sharing|none|alter system set "_optimizer_extended_cursor_sharing"=none scope=spﬁle;|否|为了解决bind peeking在数据有明显倾斜的时候会生成次优执行计划的问题(Bind aware)|Adaptive Cursor Sharing: Overview (Doc ID 740052.1)
27|_optimizer_extended_cursor_sharing_rel|none|alter system set "_optimizer_extended_cursor_sharing_rel"=none scope=spﬁle;|否|为了解决bind peeking在数据有明显倾斜的时候会生成次优执行计划的问题
28|event = "28401 trace name context forever, level 1"|28401 trace name context forever,level 1','10949 trace name context forever,level 1'|28401 trace name context forever,level 1','10949 trace name context forever,level 1' scope=spﬁle;|是|连续的错误密码登录，会导致验证延迟，出现登录数据库卡住现象，在数据库内出现大量的'library cache lock'等待。可以设置事件event = "28401 trace name context forever, level 1"来屏蔽连续错误密码登录验证延迟这个功能。|参考 28401：High 'library cache lock' Wait Time Due to Invalid Login Attempts (文档 ID 1309738.1)
29|_sys_logon_delay|0|alter system set "_sys_logon_delay"=0 scope=spﬁle;|是|28401 is effectively superseded by_sys_logon_delay = 0  from Bug 18044182 : REMOVE EVENT 2840112c中，该event 28401被参数_sys_logon_delay替代了。 建议设置：11g：event = "28401 trace name context forever, level 1"12c：_sys_logon_delay =0|Bug 19867671 - "library cache lock" caused by wrong password login - superseded (文档 ID 19867671.8)
30|_optimizer_ads_use_result_cache|FALSE|alter system set "_optimizer_ads_use_result_cache"=FALSE scope=spﬁle;|否|在12c中，可能会出现大量的"Latch Free"等待。检查AWR时，在latch统计部分会看到'Result Cache: RC Latch'争用严重。问题的原因是12c中默认开启的自动动态采样功能导致，参数值设置为false来规避。|High "Latch Free" Waits with Contention on 'Result Cache: RC Latch' when RESULT_CACHE_MODE = MANUAL on Oracle 12c (Doc ID 2002089.1)
31|_optimizer_unnest_scalar_sq|FALSE|alter system set "_optimizer_unnest_scalar_sq"=FALSE scope=spﬁle;|否|12c R1中，标量子查询展开时，可能会导致报错，将参数设置为false规避。|ORA-600 [kkqcsﬁxfro:1 -- frooutj] (档 ID 19894622.8)ORA-07445: exception encountered: core dump [qcsogolz()+70] (文档 ID 1641343.1)
32|_optimizer_null_accepting_semijoin|FALSE|alter system set "_optimizer_null_accepting_semijoin"=FALSE scope=spﬁle;|否|12c R1中，select查询语句中包含or exists （子查询）时，可能会返回错误的结果集。Wrong results on query with a subquery using OR EXISTS.设置参数为false规避。|Bug 18650065 - Wrong Results on Query with Subquery Using OR EXISTS or Null Accepting Semijoin (文档 ID 18650065.8)，在12.2中修复了该bug。
33|_b_tree_bitmap_plans|FALSE|alter system set "_b_tree_bitmap_plans"=FALSE scope=spﬁle;|否|对于OLTP系统，Oracle可能会将两个索引上的ACCESS PATH得到的rowid进行bitmap操作再回表，这种操作有时逻辑读很高，对于此类SQL使用复合索引才能从根本上解决问题。建议设置为FALSE进行规避。
34|_dataﬁle_write_errors_crash_instance|FALSE|alter system set "_dataﬁle_write_errors_crash_instance"=FALSE scope=spﬁle;|否|在11.2.0.2之前，如果数据库运行在归档模式下，并且写错误发生在非SYSTEM表空间文件，则数据库会将发生错误的文件离线，在从11.2.0.2开始，数据库会Crash实例以替代Ofﬂine。
35|_gc_defer_time|3|alter system set "_gc_defer_time"=3 scope=spﬁle;|是|用于确定服务器在将频繁使的块写入磁盘之前要等待的时间长度 (以 1/1000 秒为单位)，以减少进程对热块的争用，并优化实现对块的访问。默认为0，将禁用该功能。how long to defer pings for hot buffers in milliseconds
36|_bloom_ﬁlter_enabled|FALSE|alter system set "_bloom_ﬁlter_enabled"=FALSE scope=spﬁle;|否|布隆过滤器(Bloom Filter)算法在Oracle Database 10gR2中被引入到Oracle数据库中, 布隆过滤能够使用极低的存储空间，存储海量数据的映射，从而可以提供快速的过滤机制。11R2会遇到一个BLOOM过滤器导致的BUG,出现ORA-00060 ORA-10387错误,将参数设置为FALSE规避。
37|_optimizer_cartesian_enabled|FALSE|alter system set "_optimizer_cartesian_enabled"=FALSE scope=spﬁle;|否|关闭笛卡尔集（merge join cartesian）特性，避免出现SQL性能不稳定。
38|_sort_elimination_cost_ratio|1|alter system set "_sort_elimination_cost_ratio"=1 scope=spﬁle;|否|为了避免排序, CBO经常会舍弃需要排序的执行计划。也就是说，当CBO面前有两个执行计划可以选择的时候， 如果一个有排序，一个没有排序, 那么CBO一定会选择没有排序那个。有时候这种选择会导致错误的执行计划。可以通过修改隐含参数 _sort_elimination_cost_ratio=1 解决问题, 这个参数的意思是让CBO按cost来选择执行计划。
39|_partition_large_extents|FALSE|alter system set "_partition_large_extents"=FALSE scope=spﬁle;|否|在11g里面，新建分区会给一个较大的初始extent大小（8M），如果一次性建的分区很多，比如按天建的分区，则初始占用的空间会很大。
40|_index_partition_large_extents|FALSE|alter system set "_index_partition_large_extents"=FALSE scope=spﬁle;|否|-|-
41|_part_access_version_by_number|FALSE|alter system set "_part_access_version_by_number"=FALSE scope=spﬁle;|是|这个bug仅和分区表相关，在TRUNCATE操作之后访问分区的对象可能会报ORA-8103 (or ORA-600)错误。这个bug也体现在对分区表的查询可能给出错误的结果集。|Bug 19689979 - ORA-8103 or ORA-600 [ktecgsc:kcbz_objdchk] or Wrong Results on PARTITION table after TRUNCATE in 11.2.0.4 or above (文档 ID 19689979.8)
42|_lm_sync_timeout|1200|alter system set "_lm_sync_timeout"=1200 scope=spﬁle;|-|于100G SGA的情况下，需要设置。参考文档：Best Practices and Recommendations for RAC databases with SGA size over 100GB (文档 ID 1619155.1)
43|_lm_tickets|5000|alter system set "_lm_tickets"=5000 scope=spﬁle;|-

## 三、TASK修改

版本|可在线修改|TASK名称|建议值|默认值|描述|命令
-|-|-|-|-|-|-
11.2|可在线|sql tuning advisor|DISABLE|ENABLE|列出回收哪些段空间可以回收，给出建议（在实际运维中，实用性非常低）|BEGIN  DBMS_AUTO_TASK_ADMIN.disable(    client_name => 'sql tuning advisor',    operation   => NULL,    window_name => NULL);END;/commit;
-|可在线|auto space advisor|DISABLE|ENABLE|检测高负载的 SQL语句性能，并给出调优建议（在实际运维中，实用性非常低）|BEGIN  DBMS_AUTO_TASK_ADMIN.disable(    client_name => 'auto space advisor',    operation   => NULL,    window_name => NULL);END;/commit;

## 四、ASM参数调整

版本|动态/静态|参数名称|建议值|默认值|描述|命令
-|-|-|-|-|-|-
11.2|-|memory_target|1536m|可用的 CPU 核数*80+40|在 12c版本中，初始化参数 "processes"的默认值为“可用的 CPU 核数*80+40”. 初始化参数"memory_target" 的默认值是基于"processes"的，如果有大量的 CPU 核数或者磁盘组，这可能导致默认的"memory_target"不足，并导致各种问题（比如：GI stacks 由于 ORA-04031 错误无法启动）。 ASM & Shared Pool (ORA-4031) (Doc ID 437924.1)   Unable To Start ASM (ORA-00838 ORA-04031) On 11.2.0.3/11.2.0.4 If OS CPUs # > 64. (Doc ID 1416083.1)|alter system set memory_max_target=4096m scope=spﬁle; alter system set memory_target=1536m scope=spﬁle;
