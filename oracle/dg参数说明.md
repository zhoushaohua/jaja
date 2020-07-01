# DG参数说明

参数名|含义|主库|备库
-|-|-|-
CONPATIBLE|设置版本兼容参数，主备库一致|-|-
DB_NAME|数据库名，主备库一致|
DB_UNIQUE_NAME|数据库唯一名，主备库不能相同|
LOG_ARCHIVE_CONFIG|定义DG中所有有效的DB_UNIQUE_NAME名字的列表，以逗号分隔，为dg提供安全性检查|
LOG_ARCHIVE_MAX_PROCESSES|定义归档所使用的进程数，在主库上，归档进程用于处理连接redo日志文件的归档。在备库上归档进程负责归档standby redo log，并将归档日志转发到级联备库，建议该参数最小设置为4|
REMOTE_LOGIN_PASSWORDFILE|用户设置认证方式，建议设置参数为EXCLUSIVE(默认值)|
LOG_ARCHIVE_DEST_N|用于设置主库归档日志路径以及redo日志传输。对于dg环境中此参数设置较为复杂。如果启用了闪回区那么对于本地归档则无需设置，该参数有众多特性包括：AFFIRM、NOAFFIRM、ALTERNATE、COMPRESSION、DB_UNIQUE_NAME、DELAY、LOCATION、SERVICE、MANDATORY、MAX_CONNECTIONS、MAX_FAILURE、NET_TIMEOUT、NOREGEISTER、REOPEN、SYNC、ASYNC、VALID_FOR等|
LOG_ARCHIVE_DEST_STATE_N|指定参数为enable
DB_FILE_NAME_CONVERT|该参数仅备库生效，格式为:主、备
LOG_FILE_NAME_CONVERT|
FAL_SERVER|
FAL_CLIENT|
STANDBY_FILE_MANAGENT|

对于DG的配置，可以通过Grid Control来完成，也可以通过Data Guard Broker以及SQL*Plus来完成。对于前两者方式可以在图形界面上完成，操作简单。而对于使用SQL*Plus命令行方式，需要进行大量的配置，下表列出了一些重要参数：

其中，上表中的LOG_ARCHIVE_DEST_n各个参数的含义如下所示：

l AFFIRM（磁盘写操作）：保证Redo日志被写进物理备用数据库。默认是NOAFFIRM。当使用LGWR SYNC AFFIRM属性的时候需要等待I/O全部完成时，主库事务才能提交。该参数对数据库性能是有影响的。

l NOAFFIRM：LGWR的I/O操作是异步的，该参数是默认值。

l DELAY：指明备库应用日志的延迟时间（Redo数据延迟应用）。注意：该属性并不是说延迟发送Redo数据到Standby，而是指明归档到Standby后，延迟应用的时间，单位为分钟。如果没有指定DELAY属性，那么表示没有延迟。如果指定了DELAY属性，但没有指定值，那么默认是30分钟。不过，如果DBA在备库启动Redo应用时指定了实时应用，那么即使在LOG_ARCHIVE_DEST_n参数中指定了DELAY属性，Standby数据库也会忽略DELAY属性。如下所示的命令会忽略DELAY属性：

```sql
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION;
```

而以下命令不会忽略DELAY属性：

```sql
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;
```

另外，Standby端还可以在启动Redo应用时，通过附加NODELAY子句的方式，取消延迟应用。物理Standby可以通过下列语句取消延迟应用：

```sql
SQL> ALTER DATABASE RECOVER MANAGED STANDBY DATABASE NODELAY;
```

逻辑Standby可以通过下列语句取消延迟应用：

```sql
SQL> ALTER DATABASE START LOGICAL STANDBY APPLY NODELAY;
```

一般设置延迟应用的需求都是基于容错方面的考虑，如Primary数据库端由于误操作，数据被意外修改或删除，只要Standby数据库尚未应用这些修改，那么就可以快速从Standby数据库中恢复这部分数据。不过Oracle自从9i版本开始提供FLASHBACK特性之后，对于误操作使用FLASHBACK特性进行恢复，显然更加方便快捷，因此DELAY方式延迟应用已经非常少见了。

```cfg
SERIVCE：用于指定备用数据库的TNSNAMES描述符，Oracle会将Redo日志传送到这个TNSNAMES指定的备库。

SYNC：用于指定使用同步传输方式到备库。即LGWR进程需要等待来自LNS的确认消息后，然后告知客户端事务已提交。最高可用性及最大保护模式下，至少有一个备用目标应指定为SYNC。

ASYNC：与SYNC相反，指定使用异步传输模式，此为默认的传输方法。

NET_TIMEOUT：指定LGWR进程等待LNS进程的最大时间数，缺省为30s。如果超出该值，那么主库放弃备库，继续执行主库上的事务。

REOPEN：主库遇到备库故障后尝试重新连接备库所需等待的时间，缺省为300s。

DB_UNIQUE_NAME：主库与备库连接时会发送自己的唯一名称，同时要求备库返回其唯一名称，并结合LOG_ARCHIVE_CONFIG验证其存在性。

VALID_FOR：定义何时使用LOG_ARCHIVE_DEST_n参数以及应该在哪类Redo日志文件上运行。可用日志文件类型：ONLINE_LOGFILE、STANDBY_LOGFILE、ALL_LOGFILES。可用的角色类型：PRIMARY_ROLE、STANDBY_ROLE、ALL_ROLES。

ONLINE_LOGFILE：表示归档联机Redo日志；

STANDBY_LOGFILE：表示归档备库的Redo日志/接受的Redo日志；

ALL_LOGFILES：表示所有的在线和归档日志；

PRIMARY_ROLE：仅当数据库角色为主库时候归档生效；

STANDBY_ROLE：仅当数据库角色为备库时候归档生效；

ALL_ROLES：任意角色归档均生效。
```
