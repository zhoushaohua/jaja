# Oracle DG常用视图与运维护常用操作

## 1、查看备库状态

```sql
SQL> select open_mode,database_role,db_unique_name from v$database;
```

## 2、将备库置与应用日志模式状态

```sql
SQL> alter database recover managed standby database using current logfile disconnect from session;
```

## 3、取消备库的自动恢复

```sql
SQL> alter database recover managed standby database cancel;
```

## 4、打开实时应用状态模式

```sql
SQL> alter database recover managed standby database using current logfile disconnect;
```

## 5、查看日志应用到哪个组

```sql
SQL> select max(SEQUENCE#) from v$archived_log where applied=‘YES’
```

## 6、主库和备库之间角色切换

### 6.1 主库切换为备库

```sql
alter database commit to switchover to physical standby;
alter database commit to switchover to physical standby with session shutdown;-- 主库有会话连接的时候
shutdown immediate
startup nomount;
alter database mount standby database;
alter database recover managed standby database disconnect from session;
```

### 6.2 从库切换为主库

```sql
alter database commit to switchover to primary;
shutdown immediate;
startup
alter system switch logfile;
```

## 7.备库自动使用主库传过来的日志进行恢复

```sql
alter database recover automatic standby database;
有时standby中断一段时间后起来，开启应用日志模式无法正常从归档日志恢复，需要执行这个指令应用归档日志等应用到最近的一个归档日志后再开启应用日志模式
```

## 8.更改保护模式

```sql
alter database set standby database to maximize protection;
alter database set standby database to maximize availability;
alter database set standby database to maximize performancen;
```

## 9、恢复进度相关的 v视图应用示例 查看进程的活动状况---vmanaged_standby

```sql
SQL> select process,client_process,sequence#,status from v$managed_standby;
```

## 10、确认 redo 应用进度—varchive_dest_status

```sql
SQL> select dest_name,archived_thread#,archived_seq#,applied_thread#,applied_seq#,db_unique_name from varchive_dest_status where status=‘VALID’;
```

## 11、检查归档文件路径及创建信息—varchived_log

```sql
SQL> select name,creator,sequence#,applied,completion_time from varchived_log;
```

## 12、查询归档历史—vlog_history

```sql
SQL> select first_time,first_change#,next_change#,sequence# from vlog_history;
```

## 13、再来点与 log 应用相关的 v视图应用示例：查询当前数据的基本信息---vdatabase 信息

```sql
SQL> select database_role,db_unique_name,open_mode,protection_mode,protection_level,switchover_status from v$database;
```

## 14、查询 failover 后快速启动的信息

```sql
SQL> select fs_failover_status,fs_failover_current_target,fs_failover_threshold,fs_failover_observer_present from v$database；
```

## 15、检查应用模式(是否启用了实时应用)—varchive_dest_status

```sql
SQL> select recovery_mode from varchivedeststatusSQL>selectrecoverymodefromvarchive_dest_status where dest_id=2;
```

## 16、删除和添加standby log

```sql
alter database drop standby logfile group 1; ----------添加日志组
alter database add standby logfile thread 1 group 1 (’/u02/oradata/center/standbylog/standby_log1_1’,’/u02/oradata/center/standbylog/standby_log1_2’) size 4096M; ----------删除日志组
alter database drop logfile member ‘/u02/oradata/center/standbylog/standby_log1_2’; ----------删除日志组的一个成员
ALTER DATABASE ADD standby LOGFILE MEMBER ‘/u02/oradata/center/standbylog/standby_log1_2’ TO GROUP 1; ---------添加日志组成员
```

## 17、Data guard 事件—vdataguard_status

```sql
SQL> select message from vdataguardstatus
SQL>selectmessagefromvdataguard_status；
```

## 18、调整物理 standby log 应用频率

调整应用频率说白了就是调整 io 读取能力，所以通常我们可以从以下几个方面着手：

```sql
1）设置 recover 并行度
在介质恢复或 redo 应用期间，都需要读取重做日志文件，默认都是串行恢复，我们可以在执行 recover的时候加上 parallel 子句来指定并行度，提高读取和应用的性能，例如：

SQL> alter database recover managed standby database parallel 2 disconnect from session;
推荐 parallel 的值是#CPUs*2;

2）加快 redo 应用频繁
设置初始化参数 DB_BLOCK_CHECKING=FALSE 能够提高 2 倍左右的应用效率，该参数是验证数据块是否有 效，对 于 standby 禁止验证 基本上 还是可 以接受 的，另 外还有 一个关 联初始 化参数 DB_BLOCK_CHECKSUM，建议该参数在 primary 和 standby 都设置为 true。

3）设置 PARALLEL_EXECUTION_MESSAGE_SIZE
如果打开了并行恢复，适当提高初始化参数：PARALLEL_EXECUTION_MESSAGE_SIZE 的参数值，比如 4096 也能提高大概 20%左右的性能，不过需要注意增大这个参数的参数值可能会占用更多内存。

4）优化磁盘 I/O
在恢复期间最大瓶颈就是 I/O 读写，要缓解这个瓶颈，使用本地异步 I/O 并设置初始化参数 DISK_ASYNCH_IO=TRUE 会有所帮助。DISK_ASYNCH_IO 参数控制到数据文件的磁盘 I/O 是否异步。某些情况下异步 I/O 能降低数据库文件并行读取，提高整个恢复时间。
```
