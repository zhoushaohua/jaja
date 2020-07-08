# Oracle常用sql文档

- [Oracle常用sql文档](#oracle常用sql文档)
  - [1、创建只读用户](#1创建只读用户)
  - [2、Redo切换频率脚本](#2redo切换频率脚本)
  - [3、隐含参数查询脚本](#3隐含参数查询脚本)
  - [4、导出指定表](#4导出指定表)
  - [5、根据PID查询sql语句](#5根据pid查询sql语句)
  - [6、高水位查询以及收缩语句](#6高水位查询以及收缩语句)
  - [7、Oracle阻塞锁信息查询](#7oracle阻塞锁信息查询)
  - [8、Oracle语句执行计划以及历史绑定变量sql](#8oracle语句执行计划以及历史绑定变量sql)
  - [9、根据sql_id找到sql语句](#9根据sql_id找到sql语句)
  - [10、根据sql_id查看sql执行计划](#10根据sql_id查看sql执行计划)
  - [11、修改统计信息自动收集时间](#11修改统计信息自动收集时间)
  - [12、查看表索引、字段以及表分区相关统计信息脚本](#12查看表索引字段以及表分区相关统计信息脚本)
  - [13、收集统计信息脚本](#13收集统计信息脚本)
  - [14、手动生成awr快照](#14手动生成awr快照)
  - [15、查找前10条性能差的sql](#15查找前10条性能差的sql)
  - [16、Disk Read最高的SQL语句的获取](#16disk-read最高的sql语句的获取)
  - [17、查看耗资源的进程信息](#17查看耗资源的进程信息)
  - [18、查询产生锁的用户sql](#18查询产生锁的用户sql)
  - [19、查看当前用户的trace file路径](#19查看当前用户的trace-file路径)
  - [20、查询应用的连接数](#20查询应用的连接数)
  - [21、查看用户SCOTT的所有权限](#21查看用户scott的所有权限)
  - [22、根据SID找SPID](#22根据sid找spid)
  - [23、造成等待的锁信息，如lock类型等](#23造成等待的锁信息如lock类型等)
  - [24、清理一小时前的归档日志](#24清理一小时前的归档日志)
  - [25、查看数据文件异步IO状态](#25查看数据文件异步io状态)
  - [26、SGA分布](#26sga分布)
  - [过去30分钟的ASH报告](#过去30分钟的ash报告)
  - [按CPU统计的顶级SQL](#按cpu统计的顶级sql)
  - [按磁盘读取数统计的顶级SQL](#按磁盘读取数统计的顶级sql)
  - [按等待数统计的顶级SQL](#按等待数统计的顶级sql)
  - [正确设置open_cursors和'session_cached_cursors'  可以减少sql解析，提高系统性能.](#正确设置open_cursors和session_cached_cursors-可以减少sql解析提高系统性能)
  - [DG环境创建服务避免数据库切换修改iP](#dg环境创建服务避免数据库切换修改ip)

## 1、创建只读用户

```sql
create user query_user identified by query_user;
grant connect to query_user;
grant select any table to query_user;
grant select any dictionary to query_user;
```

## 2、Redo切换频率脚本

```sql
col 00 for '999'
col 01 for '999'
col 02 for '999'
col 03 for '999'
col 04 for '999'
col 05 for '999'
col 06 for '999'
col 07 for '999'
col 08 for '999'
col 09 for '999'
col 10 for '999'
col 11 for '999'
col 12 for '999'
col 13 for '999'
col 14 for '999'
col 15 for '999'
col 16 for '999'
col 17 for '999'
col 18 for '999'
col 19 for '999'
col 20 for '999'
col 21 for '999'
col 22 for '999'
col 23 for '999'
SELECT   thread#, a.ttime, SUM (c8) "08", SUM (c9) "09", SUM (c10) "10",
         SUM (c11) "11", SUM (c12) "12", SUM (c13) "13", SUM (c14) "14",
         SUM (c15) "15", SUM (c16) "16", SUM (c17) "17", SUM (c18) "18",
         SUM (c0) "00", SUM (c1) "01", SUM (c2) "02", SUM (c3) "03",
         SUM (c4) "04", SUM (c5) "05", SUM (c6) "06", SUM (c7) "07",
         SUM (c19) "19", SUM (c20) "20", SUM (c21) "21", SUM (c22) "22",
         SUM (c23) "23"
    FROM (SELECT thread#, ttime, DECODE (tthour, '00', 1, 0) c0,
                 DECODE (tthour, '01', 1, 0) c1,
                 DECODE (tthour, '02', 1, 0) c2,
                 DECODE (tthour, '03', 1, 0) c3,
                 DECODE (tthour, '04', 1, 0) c4,
                 DECODE (tthour, '05', 1, 0) c5,
                 DECODE (tthour, '06', 1, 0) c6,
                 DECODE (tthour, '07', 1, 0) c7,
                 DECODE (tthour, '08', 1, 0) c8,
                 DECODE (tthour, '09', 1, 0) c9,
                 DECODE (tthour, '10', 1, 0) c10,
                 DECODE (tthour, '11', 1, 0) c11,
                 DECODE (tthour, '12', 1, 0) c12,
                 DECODE (tthour, '13', 1, 0) c13,
                 DECODE (tthour, '14', 1, 0) c14,
                 DECODE (tthour, '15', 1, 0) c15,
                 DECODE (tthour, '16', 1, 0) c16,
                 DECODE (tthour, '17', 1, 0) c17,
                 DECODE (tthour, '18', 1, 0) c18,
                 DECODE (tthour, '19', 1, 0) c19,
                 DECODE (tthour, '20', 1, 0) c20,
                 DECODE (tthour, '21', 1, 0) c21,
                 DECODE (tthour, '22', 1, 0) c22,
                 DECODE (tthour, '23', 1, 0) c23
            FROM (SELECT thread#, TO_CHAR (first_time, 'yyyy-mm-dd') ttime,
                         TO_CHAR (first_time, 'hh24') tthour
                    FROM v$log_history
                   WHERE (SYSDATE - first_time < 30))) a
GROUP BY thread#, ttime;
```

## 3、隐含参数查询脚本

```sql
col name for a52
col value for a24
col description for a50
set linesize 150
select a.ksppinm name,b.ksppstvl value,a.ksppdesc description  from x$ksppi a,x$ksppcv b
   where a.inst_id = USERENV ('Instance')
   and b.inst_id = USERENV ('Instance')
   and a.indx = b.indx
   and upper(a.ksppinm) LIKE upper('%&param%')
```

## 4、导出指定表

```sql
expdp sms/sms directory=dbbackup tables=‘account’,’channel’ dumpfile=table.dmp logfile= table.log
```

## 5、根据PID查询sql语句

```sql
select
'USERNAME   :'||s.username      ||chr(10)||
'SCHEMA     :'||s.schemaname    ||chr(10)||
'OSUSER     :'||s.osuser        ||chr(10)||
'PROGRAM    :'||s.program       ||chr(10)||
'SPID       :'||p.spid          ||chr(10)||
'SERIAL#    :'||s.serial#       ||chr(10)||
'KILL STRING:'||''||S.SID||','||S.SERIAL#||chr(10)||
'TYPE       :'||s.type          ||chr(10)||
'TERMINAL   :'||s.terminal      ||chr(10)||
'SQL ID     :'||q.sql_id        ||chr(10)||
'SQL TEXT   :'||q.sql_text
from v$session s,v$process p,v$sql q where s.paddr=p.addr and p.spid='&PID_FROM_OS' and s.sql_id=q.sql_id(+);
--------------------
根据sid查询sql执行计划
select * from table(dbms_xplan.display_cursor(('&sql_id')));
杀进程sql
alter system kill session 'sid,serial#';
 ```

## 6、高水位查询以及收缩语句

```sql
--高水位线查询语句
SELECT
    owner,
    segment_name table_name,
    segment_type,
    greatest(
        round(
            100 * (nvl(hwm - avg_used_blocks,0) / greatest(nvl(hwm,1),1) ),
            2
        ),
        0
    ) waste_per,
    round(bytes / 1024,2) table_kb,
    num_rows,
    blocks,
    empty_blocks,
    hwm highwater_mark,
    avg_used_blocks,
    chain_per,
    extents,
    max_extents,
    allo_extent_per,
    DECODE(greatest(max_free_space - next_extent,0),0,'N','Y') can_extend_space,
    next_extent,
    max_free_space,
    o_tablespace_name tablespace_name
FROM
    (
        SELECT
            a.owner owner,
            a.segment_name,
            a.segment_type,
            a.bytes,
            b.num_rows,
            a.blocks blocks,
            b.empty_blocks empty_blocks,
            a.blocks - b.empty_blocks - 1 hwm,
            DECODE(
                round(
                    (b.avg_row_len * num_rows * (1 + (pct_free / 100) ) ) / c.blocksize,
                    0
                ),
                0,
                1,
                round(
                    (b.avg_row_len * num_rows * (1 + (pct_free / 100) ) ) / c.blocksize,
                    0
                )
            ) + 2 avg_used_blocks,
            round(
                100 * (nvl(b.chain_cnt,0) / greatest(nvl(b.num_rows,1),1) ),
                2
            ) chain_per,
            round(100 * (a.extents / a.max_extents),2) allo_extent_per,
            a.extents extents,
            a.max_extents max_extents,
            b.next_extent next_extent,
            b.tablespace_name o_tablespace_name
        FROM
            sys.dba_segments a,
            sys.dba_tables b,
            sys.ts$ c
        WHERE
            a.owner = b.owner
        AND
            segment_name = table_name
        AND
            segment_type = 'TABLE'
        AND
            b.tablespace_name = c.name
        UNION ALL
        SELECT
            a.owner owner,
            segment_name
             ||  '.'
             ||  b.partition_name,
            segment_type,
            bytes,
            b.num_rows,
            a.blocks blocks,
            b.empty_blocks empty_blocks,
            a.blocks - b.empty_blocks - 1 hwm,
            DECODE(
                round(
                    (b.avg_row_len * b.num_rows * (1 + (b.pct_free / 100) ) ) / c.blocksize,
                    0
                ),
                0,
                1,
                round(
                    (b.avg_row_len * b.num_rows * (1 + (b.pct_free / 100) ) ) / c.blocksize,
                    0
                )
            ) + 2 avg_used_blocks,
            round(
                100 * (nvl(b.chain_cnt,0) / greatest(nvl(b.num_rows,1),1) ),
                2
            ) chain_per,
            round(100 * (a.extents / a.max_extents),2) allo_extent_per,
            a.extents extents,
            a.max_extents max_extents,
            b.next_extent,
            b.tablespace_name o_tablespace_name
        FROM
            sys.dba_segments a,
            sys.dba_tab_partitions b,
            sys.ts$ c,
            sys.dba_tables d
        WHERE
            a.owner = b.table_owner
        AND
            segment_name = b.table_name
        AND
            segment_type = 'TABLE PARTITION'
        AND
            b.tablespace_name = c.name
        AND
            d.owner = b.table_owner
        AND
            d.table_name = b.table_name
        AND
            a.partition_name = b.partition_name
    ),
    (
        SELECT
            tablespace_name f_tablespace_name,
            MAX(bytes) max_free_space
        FROM
            sys.dba_free_space
        GROUP BY
            tablespace_name
    )
WHERE
    f_tablespace_name = o_tablespace_name
AND
    greatest(
        round(
            100 * (nvl(hwm - avg_used_blocks,0) / greatest(nvl(hwm,1),1) ),
            2
        ),
        0
    ) > 25
AND
  --替换用户名
    owner = 'SYS'
AND
    blocks > 128
ORDER BY
    10 DESC,
    1 ASC,
    2 ASC;

--高水位线收缩拼接语句
SELECT
    'ALTER TABLE '
     ||  segment_name
     ||  ' ENABLE ROW MOVEMENT;'
     ||  CHR(10)
     ||  'ALTER TABLE '
     ||  segment_name
     ||  ' SHRINK SPACE;'
FROM
    (
        SELECT
            a.segment_name
        FROM
            sys.dba_segments a,
            sys.dba_tables b,
            sys.ts$ c
        WHERE
            a.owner = b.owner
        AND
            segment_name = table_name
        AND
            segment_type = 'TABLE'
        AND
            b.tablespace_name = c.name
        AND
            greatest(
                round(
                    100 * (nvl(
                        a.blocks - b.empty_blocks - 1 - DECODE(
                            round(
                                (b.avg_row_len * num_rows * (1 + (pct_free / 100) ) ) / c.blocksize,
                                0
                            ),
                            0,
                            1,
                            round(
                                (b.avg_row_len * num_rows * (1 + (pct_free / 100) ) ) / c.blocksize,
                                0
                            )
                        ) + 2,
                        0
                    ) / greatest(nvl(a.blocks - b.empty_blocks - 1,1),1) ),
                    2
                ),
                0
            ) > 25
        AND
            a.owner = 'SCOTT'
        AND
            a.blocks > 128
        UNION ALL
        SELECT DISTINCT
            a.segment_name segment_name
        FROM
            sys.dba_segments a,
            sys.dba_tab_partitions b,
            sys.ts$ c,
            sys.dba_tables d
        WHERE
            a.owner = b.table_owner
        AND
            segment_name = b.table_name
        AND
            segment_type = 'TABLE PARTITION'
        AND
            b.tablespace_name = c.name
        AND
            d.owner = b.table_owner
        AND
            d.table_name = b.table_name
        AND
            a.partition_name = b.partition_name
        AND
            greatest(
                round(
                    100 * (nvl(
                        a.blocks - b.empty_blocks - 1 - DECODE(
                            round(
                                (b.avg_row_len * b.num_rows * (1 + (b.pct_free / 100) ) ) / c.blocksize,
                                0
                            ),
                            0,
                            1,
                            round(
                                (b.avg_row_len * b.num_rows * (1 + (b.pct_free / 100) ) ) / c.blocksize,
                                0
                            )
                        ) + 2,
                        0
                    ) / greatest(nvl(a.blocks - b.empty_blocks - 1,1),1) ),
                    2
                ),
                0
            ) > 25
        AND
            a.owner = 'SYS'
        AND
            a.blocks > 128
    );
--------------------------------------------
各列的说明：
WASTE_PER：已分配空间中水线以下空闲空间(即浪费空间)的百分比。
TABLE_KB：该表目前已经分配的所有空间的大小，以k为单位。
NUM_ROWS：在在表中数据的行数
BLOCKS：该表目前已经分配的数据块的块数，包含水线以上的部分
EMPTY_BLOCKS：已分配空间中水线以上的空闲空间
HIGHWATER_MARK：目前的水线
AVG_USED_BLOCKS：理想情况下(没有行迁移)，该表数据应该占用的数据块的个数
CHAIN_PER：发生行迁移现象的行占总行的比率
EXTENTS：该表目前已经分配的extent数
MAX_EXTENTS：该表可以分配的最大extent的个数
ALLO_EXTENT_PER：目前已分配的extent的个数占可以分配最大extent的比率
CAN_EXTEND_SPACE：是否可以分配下一个extent
NEXT_EXTENT：下一个extent的大小
MAX_FREE_SPACE：表的已分配空间中最大的空闲空间

```

## 7、Oracle阻塞锁信息查询

```sql
/* 按用户统计的阻塞锁*/SELECT /*+ ORDERED */
    blocker.sid   blocker_sid,
    waiting.sid   waiting_sid,
    trunc(waiting.ctime / 60) min_waiting,
    waiting.request
FROM
    (
        SELECT
            *
        FROM
            gv$lock
        WHERE
            block != 0
            AND type = 'TX'
    ) blocker,
    gv$lock waiting
WHERE
    waiting.type = 'TX'
    AND waiting.block = 0
    AND waiting.id1 = blocker.id1
/*阻塞会话中的sql查询*/
select  sql_text from gv$sql where sql_id in (
    SELECT DISTINCT
        sql_id
    FROM
        gv$active_session_history
    WHERE
        session_type = 'FOREGROUND'
        AND sql_id IS NOT NULL
            AND session_id IN (
            SELECT /*+ ORDERED */
                blocker.sid   blocker_sid
            FROM
                (
                    SELECT
                        *
                    FROM
                        gv$lock
                    WHERE
                        block != 0
                        AND type = 'TX'
                ) blocker,
                gv$lock waiting
            WHERE
                waiting.type = 'TX'
                AND waiting.block = 0
                    AND waiting.id1 = blocker.id1
        )
)
/*等待会话中的sql查询*/
select sql_text
FROM
    gv$sql
WHERE
    sql_id IN (
        SELECT
            sql_id
        FROM
            gv$session
        WHERE
            sid IN (
                SELECT /*+ ORDERED */
                    waiting.sid   waiting_sid
                FROM
                    (
                        SELECT
                            *
                        FROM
                            gv$lock
                        WHERE
                            block != 0
                            AND type = 'TX'
                    ) blocker,
                    gv$lock waiting
                WHERE
                    waiting.type = 'TX'
                    AND waiting.block = 0
                        AND waiting.id1 = blocker.id1
            )
    )
```

## 8、Oracle语句执行计划以及历史绑定变量sql

```sql
SELECT
    sql.*,
    (
        SELECT
            sql_text
        FROM
            dba_hist_sqltext t
        WHERE
            t.sql_id = sql.sql_id
            AND ROWNUM = 1
    ) sqltext
FROM
    (
        SELECT
            a.*,
            RANK() OVER(
                ORDER BY
                    els DESC
            ) AS r_els,
            RANK() OVER(
                ORDER BY
                    phy DESC
            ) AS r_phy,
            RANK() OVER(
                ORDER BY
                    get DESC
            ) AS r_get,
            RANK() OVER(
                ORDER BY
                    exe DESC
            ) AS r_exe,
            RANK() OVER(
                ORDER BY
                    cpu DESC
            ) AS r_cpu
        FROM
            (
                SELECT
                    sql_id,
                    SUM(executions_delta) exe,
                    round(SUM(elapsed_time_delta) / 1e6, 2) els,
                    round(SUM(cpu_time_delta) / 1e6, 2) cpu,
                    round(SUM(iowait_delta) / 1e6, 2) iow,
                    SUM(buffer_gets_delta) get,
                    SUM(disk_reads_delta) phy,
                    SUM(rows_processed_delta) rwo,
                    round(SUM(elapsed_time_delta) / greatest(SUM(executions_delta), 1) / 1e6, 4) elsp,
                    round(SUM(cpu_time_delta) / greatest(SUM(executions_delta), 1) / 1e6, 4) cpup,
                    round(SUM(iowait_delta) / greatest(SUM(executions_delta), 1) / 1e6, 4) iowp,
                    round(SUM(buffer_gets_delta) / greatest(SUM(executions_delta), 1), 2) getp,
                    round(SUM(disk_reads_delta) / greatest(SUM(executions_delta), 1), 2) phyp,
                    round(SUM(rows_processed_delta) / greatest(SUM(executions_delta), 1), 2) rowp
                FROM
                    dba_hist_sqlstat s
--where snap_id between ... and ...
                GROUP BY
                    sql_id
            ) a
    ) sql
WHERE
    r_els <= 10
    OR r_phy <= 10
    OR r_cpu <= 10
ORDER BY
    els DESC
--------------------------------------------------------------------------
根据sqlid查询sql执行计划
select * from table(dbms_xplan.display_awr('&SQLID'));
--------------------------------------------------------------------------
查看sql历史绑定变量信息
####10G
select snap_id,sq.sql_id,bm.position, dbms_sqltune.extract_bind(sq.bind_data,bm.position).value_string value_string
from dba_hist_sqlstat sq ,dba_hist_sql_bind_metadata bm
where sq.sql_id = bm.sql_id --and sq.sql_id = '&sql'
####11G
select * from ( select snap_id, to_char(sn.begin_interval_time,'MM/DD-HH24:MI') snap_time, sq.sql_id,bm.position, dbms_sqltune.extract_bind(bind_data,bm.position).value_string value_string from dba_hist_snapshot sn natural join dba_hist_sqlstat sq ,dba_hist_sql_bind_metadata bm
where sq.sql_id = bm.sql_id and sq.sql_id = '&sql'
) PIVOT (max(value_string) for position in (1,2,3,4,5,6,7,8,9,10))
order by snap_id;
```

## 9、根据sql_id找到sql语句

```sql
select sql_text from V$SQLTEXT where sql_id='' order by piece;
```

## 10、根据sql_id查看sql执行计划

```sql
select * from table(dbms_xplan.display_awr('&SQLID'));
```

## 11、修改统计信息自动收集时间

```sql
SQL> set linesize 200
SQL> col REPEAT_INTERVAL for a60
SQL> col DURATION for a30
SQL> select t1.window_name,t1.repeat_interval,t1.duration from dba_scheduler_windows t1,dba_scheduler_wingroup_members t2
  2  where t1.window_name=t2.window_name and t2.window_group_name in ('MAINTENANCE_WINDOW_GROUP','BSLN_MAINTAIN_STATS_SCHED');

WINDOW_NAME        REPEAT_INTERVAL                                              DURATION
------------------ ------------------------------------------------------------ ---------------
MONDAY_WINDOW      freq=daily;byday=MON;byhour=22;byminute=0; bysecond=0        +000 04:00:00
TUESDAY_WINDOW     freq=daily;byday=TUE;byhour=22;byminute=0; bysecond=0        +000 04:00:00
WEDNESDAY_WINDOW   freq=daily;byday=WED;byhour=22;byminute=0; bysecond=0        +000 04:00:00
THURSDAY_WINDOW    freq=daily;byday=THU;byhour=22;byminute=0; bysecond=0        +000 04:00:00
FRIDAY_WINDOW      freq=daily;byday=FRI;byhour=22;byminute=0; bysecond=0        +000 04:00:00
SATURDAY_WINDOW    freq=daily;byday=SAT;byhour=6;byminute=0; bysecond=0         +000 20:00:00
SUNDAY_WINDOW      freq=daily;byday=SUN;byhour=6;byminute=0; bysecond=0         +000 20:00:00

7 rows selected.


关闭自动统计信息收集
BEGIN
  DBMS_SCHEDULER.DISABLE(
  name => '"SYS"."SATURDAY_WINDOW"',
  force => TRUE);
END;
/


修改自动统计信息持续时间
BEGIN
  DBMS_SCHEDULER.SET_ATTRIBUTE(
  name => '"SYS"."SATURDAY_WINDOW"',
  attribute => 'DURATION',
  value => numtodsinterval(240,'minute'));
END;  
/

修改自动统计信息开始时间
BEGIN
  DBMS_SCHEDULER.SET_ATTRIBUTE(
  name => '"SYS"."SATURDAY_WINDOW"',
  attribute => 'REPEAT_INTERVAL',
  value => 'freq=daily;byday=SAT;byhour=22;byminute=0; bysecond=0 ');
END;
/

开启自动统计信息收集
BEGIN
  DBMS_SCHEDULER.ENABLE(
  name => '"SYS"."SATURDAY_WINDOW"');
END;
/


SQL> set linesize 200
SQL> col REPEAT_INTERVAL for a60
SQL> col DURATION for a30
SQL> select t1.window_name,t1.repeat_interval,t1.duration from dba_scheduler_windows t1,dba_scheduler_wingroup_members t2
  2  where t1.window_name=t2.window_name and t2.window_group_name in ('MAINTENANCE_WINDOW_GROUP','BSLN_MAINTAIN_STATS_SCHED');

WINDOW_NAME       REPEAT_INTERVAL                                              DURATION
----------------- ------------------------------------------------------------ --------------
MONDAY_WINDOW     freq=daily;byday=MON;byhour=22;byminute=0; bysecond=0        +000 04:00:00
TUESDAY_WINDOW    freq=daily;byday=TUE;byhour=22;byminute=0; bysecond=0        +000 04:00:00
WEDNESDAY_WINDOW  freq=daily;byday=WED;byhour=22;byminute=0; bysecond=0        +000 04:00:00
THURSDAY_WINDOW   freq=daily;byday=THU;byhour=22;byminute=0; bysecond=0        +000 04:00:00
FRIDAY_WINDOW     freq=daily;byday=FRI;byhour=22;byminute=0; bysecond=0        +000 04:00:00
SATURDAY_WINDOW   freq=daily;byday=SAT;byhour=22;byminute=0; bysecond=0        +000 04:00:00
SUNDAY_WINDOW     freq=daily;byday=SUN;byhour=6;byminute=0; bysecond=0         +000 20:00:00

7 rows selected.
```

## 12、查看表索引、字段以及表分区相关统计信息脚本

```sql
set echo off
set scan on
set lines 200
set long 999999
set pages 66
set newpage 0
set verify off
set feedback off
set termout off
set timing off
SET wrap on

column uservar new_value Table_Owner noprint
select user uservar from dual;
set termout on
column TABLE_NAME heading 'Tables owned by &Table_Owner' format a150
undefine table_name
undefine owner
prompt
accept owner prompt 'Please enter Name of Table Owner (Null = &Table_Owner): '
accept table_name  prompt 'Please enter Table Name to show Statistics for: '


column owner heading 'Owner' for a10
column table_name  heading 'Table Name' for a12
column num_rows heading 'Num Rows' for 999,999,999,999
column blocks heading 'Num Blocks' for 999,999,999,999
column avg_row_len heading 'Avg Row len' for 999,999,999,999
column TEMPORARY heading 'Is Temporary' for a15
column GLOBAL_STATS heading 'Is|Global Static' for a15
column SAMPLE_SIZE heading 'Sample Size' for 999,999,999,999
column degree heading 'Degree' for 999
column LAST_ANALYZED heading 'Last Analyzed'  for a20

column column_name heading 'Column Name' for a15
column data_type heading 'Data Type' for a10
column nullable heading 'Is Null' for a15
column num_distinct heading 'Distinct Value' for 999,999,999,999
column density heading 'Density' for 999,999,999,999,999
column low_value heading 'Col Low Value' for a20
column col_high_value heading 'Col High Value' for a20
column num_nulls heading 'Num Null' for 999,999,999,999
column histogram heading 'Histogram' for a15
column num_buckets heading 'Num Buckets' for 999,999

column constraint_name heading  'Cons Name' for a20
column constraint_type heading 'Cons Type' for a15
column position heading 'Cons Position' for a15
column R_constraint_name heading 'R_Cons Name' for a20
column status heading 'Status' for a10
column invalid heading 'Is Invalid'  for a15
column cons_col_name heading 'Cons Col Name' for a15

column index_name heading  'Index Name' for a15
column index_type heading  'Index Type' for a15
column index_col_name heading 'Index Col_Name' for a15
column uniqueness heading  'Unique' for a20
column partitioned heading  'Is_Partition|Index' for a15
column blevel heading  'Index Blevel' for 999,999
column leaf_blocks heading  'Index|Leaf Blocks' for 999,999,999,999,999
column distinct_keys heading  'Index|Distinct Value' for 999,999,999,999,999
column clustering_factor heading  'Cluster Factor' for 999,999,999,999,999
column index_col_name heading  'Index|Column Name' for a20
column column_position heading  'Index|Column Position' for 999,999
column descend heading  'IS_Desc' for a8

column partition_position heading  'Partition Position' for 999,999
column partition_name heading  'Partition Name' for a15
column COMPOSITE heading  'Is_Multi|Partition' for a15
column SUBPARTITION_COUNT heading  'Sub|Partiton Counts' for 999,999,999,999
column COMPRESSION heading  'Is Compressed' for a10
column HIGH_VALUE heading 'Partition|High Value' for a85

column SUBPARTITION_POSITION heading 'Sub|Partiton Position' for 999,999
column SUBPARTITION_NAME heading 'Sub|Partiton Name' for a15


prompt
prompt ************************************
prompt Table INFO 查看表行数，块数以及行长
prompt ************************************
prompt

select owner ,
       table_name ,
       num_rows ,
       blocks ,
       avg_row_len ,
       TEMPORARY ,
       GLOBAL_STATS ,
       SAMPLE_SIZE ,
       degree ,
       to_char(LAST_ANALYZED,'YYYY-MM-DD HH24:MI:SS') LAST_ANALYZED
  from dba_tables
 where owner = upper(nvl('&Owner',user)) and table_name = upper('&Table_name')
/


prompt
prompt *********************************
prompt Table Field INFO 查看表列信息
prompt *********************************
prompt

select s.column_name ,
       s.data_type ,
       s.nullable ,
       s.num_distinct ,
       round(s.density,6) density,
       s.num_nulls ,
       s.histogram ,
       s.num_buckets ,
       to_char(s.LAST_ANALYZED,'YYYY-MM-DD HH24:MI:SS') LAST_ANALYZED
  from dba_tab_columns s
 where owner = upper(nvl('&Owner',user)) and table_name = upper('&Table_name')
/

select s.column_name ,
       s.low_value ,
       s.high_value col_high_value,
       to_char(s.LAST_ANALYZED,'YYYY-MM-DD HH24:MI:SS') LAST_ANALYZED
  from dba_tab_columns s
 where owner = upper(nvl('&Owner',user)) and table_name = upper('&Table_name')
/


prompt
prompt **************************************
prompt Table Constraints INFO 查看表约束信息
prompt **************************************
prompt

SELECT a.column_name cons_col_name,
       a.constraint_name ,
       b.constraint_type ,
       a.position ,
       b.R_constraint_name ,
       b.status ,
       b.invalid
  FROM user_cons_columns a, user_constraints b
 where a.owner = upper(nvl('&Owner',user)) and a.table_name = upper('&Table_name')
   AND a.constraint_name = b.constraint_name;
/


prompt
prompt ************************************
prompt Table Index INFO 查看表索引相关信息
prompt ************************************
prompt

select index_name,
       index_type,
       uniqueness,
       status ,
       partitioned ,
       TEMPORARY ,
       degree ,
       to_char(LAST_ANALYZED, 'YYYY-MM-DD HH24:MI:SS') LAST_ANALYZED
  from dba_indexes
 where owner = upper(nvl('&Owner',user)) and table_name = upper('&Table_name')
/

select index_name,
       index_type,
       blevel ,
       leaf_blocks ,
       distinct_keys ,
       num_rows ,
       clustering_factor ,
       to_char(LAST_ANALYZED, 'YYYY-MM-DD HH24:MI:SS') LAST_ANALYZED
  from dba_indexes
 where owner = upper(nvl('&Owner',user)) and table_name = upper('&Table_name')
/


prompt
prompt ********************************************
prompt Table Index Field INFO 查看表索引列相关信息
prompt ********************************************
prompt

select index_name , column_name index_col_name, column_position ,descend
  from dba_ind_columns
 where table_owner = upper(nvl('&Owner',user)) and table_name = upper('&Table_name')
/


prompt
prompt *************************************
prompt Table Partition INFO 查看表分区情况
prompt *************************************
prompt

select partition_position,
       partition_name ,
       COMPOSITE ,
       num_rows ,
       AVG_ROW_LEN ,
       blocks ,
       SUBPARTITION_COUNT ,
       COMPRESSION ,
       to_char(LAST_ANALYZED, 'YYYY-MM-DD HH24:MI:SS')  LAST_ANALYZED
  from dba_tab_partitions
 where table_owner = upper(nvl('&Owner',user)) and table_name = upper('&Table_name')
/


select partition_position ,
       partition_name ,
       HIGH_VALUE ,
       to_char(LAST_ANALYZED, 'YYYY-MM-DD HH24:MI:SS') LAST_ANALYZED
  from dba_tab_partitions
 where table_owner = upper(nvl('&Owner',user)) and table_name = upper('&Table_name')
/


prompt
prompt ******************************************
prompt Table Subpartitions INFO 查看表子分区信息
prompt ******************************************
prompt

select partition_name ,
       SUBPARTITION_POSITION ,
       SUBPARTITION_NAME ,
       num_rows ,
       AVG_ROW_LEN ,
       blocks ,
       COMPRESSION ,
       to_char(LAST_ANALYZED, 'YYYY-MM-DD HH24:MI:SS') LAST_ANALYZED
  from dba_tab_subpartitions
 where table_owner = upper(nvl('&Owner',user)) and table_name = upper('&Table_name')
/

select partition_name ,
       SUBPARTITION_POSITION ,
       SUBPARTITION_NAME ,
       HIGH_VALUE ,
       to_char(LAST_ANALYZED, 'YYYY-MM-DD HH24:MI:SS') LAST_ANALYZED
  from dba_tab_subpartitions
 where table_owner = upper(nvl('&Owner',user)) and table_name = upper('&Table_name')
/

set echo on
```

## 13、收集统计信息脚本

```sql
# 收集表统计信息
exec dbms_stats.gather_table_stats(ownname => 'TEST',tabname => '$tablename',estimate_percent=>'10')

# 收集分区表某个分区统计信息
exec dbms_stats.gather_table_stats(ownname => 'USER',tabname => 'RANGE_PART_TAB',partname => 'p_201312',estimate_percent => 10,method_opt=> 'for all indexed columns',cascade=>TRUE);

# 收集索引统计信息
exec dbms_stats.gather_index_stats(ownname => 'USER',indname => 'IDX_OBJECT_ID',estimate_percent => '10',degree => '4');

# 收集表和索引统计信息
exec dbms_stats.gather_table_stats(ownname => 'USER',tabname => 'TEST',estimate_percent => 10,method_opt=> 'for all indexed columns',cascade=>TRUE);

# 收集某个用户的统计信息
exec dbms_stats.gather_schema_stats(ownname=>'CS',estimate_percent=>10,degree=>8,cascade=>true,granularity=>'ALL');

# 收集整个数据库的统计信息
exec dbms_stats.gather_database_stats(estimate_percent=>10,degree=>8,cascade=>true,granularity=>'ALL');

ownname： USER_NAME
tabname： TABLE_NAME
partname: 分区表的某个分区名
estimate_percent: 采样百分比，有效范围为[0.000001,100]
block_sample：使用随机块采样代替随机行采样
method_opt：
cascade:是否收集此表索引的统计信息
degree:并行处理的cpu数量
granularity： 统计数据的收集，'ALL' - 收集所有（子分区，分区和全局）统计信息
```

## 14、手动生成awr快照

```sql
# 生成awr快照
exec dbms_workload_repositroy.create_snapshot();

# 修改awr快照时间间隔和保留时间
exec dbms_workload_repository.modify_snapshot_settings(interval=>60,retention=>7*3*24*60);
```

## 15、查找前10条性能差的sql

```sql
SELECT * FROM (SELECT PARSING_USER_ID EXECUTIONS,SORTS,COMMAND_TYPE,DISK_READS,sql_text FROM v$sqlarea ORDER BY disk_reads DESC) WHERE ROWNUM<10;
```

## 16、Disk Read最高的SQL语句的获取

```sql
Select sql_text from (select * from v$sqlarea order by disk_reads) where rownum<=5;

1 buffer gets top 10 sql:

SELECT
    *
FROM
    (
        SELECT
            substr(sql_text, 1, 40) sql,
            buffer_gets,
            executions,
            buffer_gets / executions "Gets/Exec",
            hash_value,
            address
        FROM
            v$sqlarea
        WHERE
            buffer_gets > 10000
        ORDER BY
            buffer_gets DESC
    )
WHERE
    ROWNUM <= 10;

SELECT
    *
FROM
    (
        SELECT
            substr(sql_text, 1, 40) sql,
            buffer_gets,
            executions,
            buffer_gets / executions "Gets/Exec",
            hash_value,
            address
        FROM
            v$sqlarea
        WHERE
            buffer_gets > 0
            AND executions > 0
        ORDER BY
            buffer_gets DESC
    )
WHERE
    ROWNUM <= 10;

2 Physical Reads top 10 sql:

SELECT
    *
FROM
    (
        SELECT
            substr(sql_text, 1, 40) sql,
            disk_reads,
            executions,
            disk_reads / executions "Reads/Exec",
            hash_value,
            address
        FROM
            v$sqlarea
        WHERE
            disk_reads > 1000
        ORDER BY
            disk_reads DESC
    )
WHERE
    ROWNUM <= 10;

SELECT
    *
FROM
    (
        SELECT
            substr(sql_text, 1, 40) sql,
            disk_reads,
            executions,
            disk_reads / executions "Reads/Exec",
            hash_value,
            address
        FROM
            v$sqlarea
        WHERE
            disk_reads > 0
            AND executions > 0
        ORDER BY
            disk_reads DESC
    )
WHERE
    ROWNUM <= 10;

3 Executions top 10 sql:

SELECT
    *
FROM
    (
        SELECT
            substr(sql_text, 1, 40) sql,
            executions,
            rows_processed,
            rows_processed / executions "Rows/Exec",
            hash_value,
            address
        FROM
            v$sqlarea
        WHERE
            executions > 100
        ORDER BY
            executions DESC
    )
WHERE
    ROWNUM <= 10;

4 Parse Calls top 10 sql:

SELECT
    *
FROM
    (
        SELECT
            substr(sql_text, 1, 40) sql,
            parse_calls,
            executions,
            hash_value,
            address
        FROM
            v$sqlarea
        WHERE
            parse_calls > 1000
        ORDER BY
            parse_calls DESC
    )
WHERE
    ROWNUM <= 10;

5 Sharable Memory top 10 sql:

SELECT
    *
FROM
    (
        SELECT
            substr(sql_text, 1, 40) sql,
            sharable_mem,
            executions,
            hash_value,
            address
        FROM
            v$sqlarea
        WHERE
            sharable_mem > 1048576
        ORDER BY
            sharable_mem DESC
    )
WHERE
    ROWNUM <= 10;

6 CPU usage top 10 sql:

SELECT
    *
FROM
    (
        SELECT
            sql_text,
            round(cpu_time / 1000000) cpu_time,
            round(elapsed_time / 1000000) elapsed_time,
            disk_reads,
            buffer_gets,
            rows_processed
        FROM
            v$sqlarea
        ORDER BY
            cpu_time DESC,
            disk_reads DESC
    )
WHERE
    ROWNUM < 10;

7 Running Time top 10 sql:

SELECT
    *
FROM
    (
        SELECT
            t.sql_fulltext,
            ( t.last_active_time - to_date(t.first_load_time, 'yyyy-mm-dd hh24:mi:ss') ) * 24 * 60 time,
            disk_reads,
            buffer_gets,
            rows_processed,
            t.last_active_time,
            t.last_load_time,
            t.first_load_time
        FROM
            v$sqlarea t
        ORDER BY
            t.first_load_time DESC
    )
WHERE
    ROWNUM < 10
ORDER BY
    time DESC;

SELECT
    *
FROM
    (
        SELECT
            ( t.last_active_time - to_date(t.first_load_time, 'yyyy-mm-dd hh24:mi:ss') ) * 24 * 60 time,
            t.sql_id,
            t.last_active_time,
            t.last_load_time,
            t.first_load_time
        FROM
            v$sqlarea t
        ORDER BY
            t.first_load_time DESC
    )
ORDER BY
    time ASC;
```

## 17、查看耗资源的进程信息

```sql
SELECT
    s.schemaname   schema_name,
    decode(sign(48 - command), 1, to_char(command), 'Action Code #' || to_char(command)) action,
    status         session_status,
    s.osuser       os_user_name,
    s.sid,
    p.spid,
    s.serial#      serial_num,
    nvl(s.username, '[Oracle process]') user_name,
    s.terminal     terminal,
    s.program      program,
    st.value       criteria_value
FROM
    v$sesstat   st,
    v$session   s,
    v$process   p
WHERE
    st.sid = s.sid
    AND st.statistic# = to_number('38')
    AND ( 'ALL' = 'ALL'
          OR s.status = 'ALL' )
    AND p.addr = s.paddr
ORDER BY
    st.value DESC,
    p.spid ASC,
    s.username ASC,
    s.osuser ASC;
```

## 18、查询产生锁的用户sql

```sql
SELECT
    a.username   username,
    a.sid        sid,
    a.serial#    serial,
    b.id1        id1,
    c.sql_text   sqltext
FROM
    v$session   a,
    v$lock      b,
    v$sqltext   c
WHERE
    b.id1 IN (
        SELECT DISTINCT
            e.id1
        FROM
            v$session   d,
            v$lock      e
        WHERE
            d.lockwait = e.kaddr
    )
    AND a.sid = b.sid
    AND c.hash_value = a.sql_hash_value
    AND b.request = 0;

SELECT /*+ ordered */
    username,
    v$lock.sid,
    trunc(id1 / power(2, 16)) rbs,
    bitand(id1, to_number('ffff', 'xxxx')) + 0 slot,
    id2 seq,
    lmode,
    request
FROM
    v$lock,
    v$session
WHERE
    v$lock.type = 'TX'
    AND v$lock.sid = v$session.sid;
```

## 19、查看当前用户的trace file路径

```sql
SELECT
    p.value
    || '\'
    || t.instance
    || '_ora_'
    || ltrim(to_char(p.spid, 'fm99999'))
    || '.trc'
FROM
    v$process     p,
    v$session     s,
    v$parameter   p,
    v$thread      t
WHERE
    p.addr = s.paddr
    AND s.audsid = userenv('sessionid')
    AND p.name = 'user_dump_dest';
```

## 20、查询应用的连接数

```sql
SELECT
    b.machine,
    b.program,
    COUNT(*)
FROM
    v$process   a,
    v$session   b
WHERE
    a.addr = b.paddr
    AND b.username IS NOT NULL
GROUP BY
    b.machine,
    b.program
ORDER BY
    COUNT(*) DESC;
```

## 21、查看用户SCOTT的所有权限

```sql
SELECT
    a.username,
    b.granted_role
    || decode(admin_option, 'YES', ' (With Admin Option)', NULL) what_granted
FROM
    sys.dba_users        a,
    sys.dba_role_privs   b
WHERE
    a.username = b.grantee
    AND username = 'SCOTT'
UNION
SELECT
    a.username,
    b.privilege
    || decode(admin_option, 'YES', ' (With Admin Option)', NULL) what_granted
FROM
    sys.dba_users       a,
    sys.dba_sys_privs   b
WHERE
    a.username = b.grantee
    AND username = 'SCOTT'
UNION
SELECT
    a.username,
    b.table_name
    || ' - '
    || b.privilege
    || decode(grantable, 'YES', ' (With Grant Option)', NULL) what_granted
FROM
    sys.dba_users       a,
    sys.dba_tab_privs   b
WHERE
    a.username = b.grantee
    AND username = 'SCOTT'
ORDER BY
    1;
```

## 22、根据SID找SPID

```sql
select pro.spid from v$session ses,v$process pro where ses.sid=xxx and ses.paddr=pro.addr; 根据SPID找SID,SERIAL select s.sid,s.serial# from v$session s,v$process p where s.paddr=p.addr and p.spid='xxx';
根据pid找sid
SELECT
    sid,
    serial#,
    username,
    machine
FROM
    v$session b
WHERE
    b.paddr = (
        SELECT
            addr
        FROM
            v$process c
        WHERE
            c.spid = '&pid'
    );

oracle 通过pid 找到sid 再找出执行sql

通过sid找出执行的sql语句 SELECT SID,SERIAL#, USERNAME,MACHINE FROM v$session b WHERE b.paddr = (SELECT addr FROM v$process c WHERE c.spid = '&pid');

select sql_address,sql_hash_value,sql_id from v$session where sid=20;

select sql_fulltext from V$sqlarea where sql_id='301r15qus4kp1'
```

## 23、造成等待的锁信息，如lock类型等

```sql
COL event FORMAT a30

SET LINE 160

COL machine FORMAT a10

COL username FORMAT a15

SELECT
    b.sid,
    b.serial#,
    b.username,
    machine,
    a.event,
    a.wait_time,
    chr(bitand(a.p1, - 16777216) / 16777215)
    || chr(bitand(a.p1, 16711680) / 65535) "Enqueue Type"
FROM
    v$session_wait   a,
    v$session        b
WHERE
    a.event NOT LIKE 'SQL*N%'
    AND a.event NOT LIKE 'rdbms%'
    AND a.sid = b.sid
    AND b.sid > 8
    AND a.event = 'enqueue'
ORDER BY
    username;
```

## 24、清理一小时前的归档日志

```bash
[root@hch_test_121_90 ~]# more archivelog_clear.sh
#!/bin/sh
BACK_DIR=/oracle/clear_archlog/data
export DATE=`date +%F`
echo "      " >> $BACK_DIR/$DATE/rman_backup.log
echo `date '+%Y-%m-%d %H:%M:%S'` >> $BACK_DIR/$DATE/rman_backup.log
su - oracle -c "
mkdir -p $BACK_DIR/$DATE
rman log=$BACK_DIR/$DATE/rman_backup.log target / <<EOF
delete force noprompt archivelog all completed before 'sysdate-1/24';
exit;
EOF
"
echo "   " >> $BACK_DIR/$DATE/rman_backup.log
```

## 25、查看数据文件异步IO状态

```sql
SELECT file_no,
  t.name TABLESPACE,
  f.name filename,
  DECODE(asynch_io, 'ASYNC_ON', 'ON', 'ASYNC_OFF', 'OFF', asynch_io) async,
  status,
  block_size
FROM v$datafile f,
  v$iostat_file i,
  v$tablespace t
WHERE f.file#     = i.file_no
AND t.ts#         = f.ts#
AND filetype_name = 'Data File'
ORDER BY 1,2

FILESYTEMIO_OPTIONS :
ASYNCH: 在文件系统文件上启用异步I/O，在数据传送上没有计时要求。
DIRECTIO: 在文件系统文件上启用直接I/O，绕过buffer cache。
SETALL: 在文件系统文件上启用异步和直接I/O。
NONE: 在文件系统文件上禁用异步和直接I/O。

SQL> show parameter disk

NAME                                 TYPE                   VALUE
------------------------------------ ---------------------- ------------------------------
asm_diskgroups                       string
asm_diskstring                       string
disk_asynch_io                       boolean                TRUE
SQL> show parameter filesystem

NAME                                 TYPE                   VALUE
------------------------------------ ---------------------- ------------------------------
filesystemio_options                 string                 SETALL

SQL> alter system set filesystemio_options='SETALL' scope=spfile;

System altered.
```

## 26、SGA分布

```sql
SELECT 'INSTANCE:'||inst_id instance,
  name,
  bytes/1024/1024||'Mb'
FROM gv$sgainfo
WHERE name IN ('Redo Buffers', 'Buffer Cache Size')
OR name LIKE '%Pool Size'
```

## 过去30分钟的ASH报告

```sql
set serveroutput on
declare
dbid number;
instance_id number;
begin
select dbid into dbid from v$database;
select instance_number into instance_id from v$instance;
dbms_output.enable(500000);
dbms_output.put_line('<PRE>');
for rc in ( select output from
   table(dbms_workload_repository.ash_report_text( dbid,instance_id,SYSDATE-31/1440, SYSDATE-1/1440))) loop
   dbms_output.put_line(rc.output);
end loop;
dbms_output.put_line('</PRE>') ;
end;
/
```

## 按CPU统计的顶级SQL

```sql
select substr(sql_text,1,500) "SQL",
                                      (cpu_time/1000000) "CPU_Seconds",
                                      disk_reads "Disk_Reads",
                                      buffer_gets "Buffer_Gets",
                                      executions "Executions",
                                      case when rows_processed = 0 then null
                                           else round((buffer_gets/nvl(replace(rows_processed,0,1),1)))
                                           end "Buffer_gets/rows_proc",
                                      round((buffer_gets/nvl(replace(executions,0,1),1))) "Buffer_gets/executions",
                                      (elapsed_time/1000000) "Elapsed_Seconds",
                                      module "Module"
                                 from gv$sql s
                                order by cpu_time desc nulls last
```

## 按磁盘读取数统计的顶级SQL

```sql
select substr(sql_text,1,500) "SQL",
                                      (cpu_time/1000000) "CPU_Seconds",
                                      disk_reads "Disk_Reads",
                                      buffer_gets "Buffer_Gets",
                                      executions "Executions",
                                      case when rows_processed = 0 then null
                                           else round((buffer_gets/nvl(replace(rows_processed,0,1),1)))
                                           end "Buffer_gets/rows_proc",
                                      round((buffer_gets/nvl(replace(executions,0,1),1))) "Buffer_gets/executions",
                                      (elapsed_time/1000000) "Elapsed_Seconds",
                                      module "Module"
                                 from gv$sql s
                                order by disk_reads desc nulls last
```

## 按等待数统计的顶级SQL

```sql
select INST_ID,
                                      (cpu_time/1000000) "CPU_Seconds",
                                      disk_reads "Disk_Reads",
                                      buffer_gets "Buffer_Gets",
                                      executions "Executions",
                                      case when rows_processed = 0 then null
                                           else round((buffer_gets/nvl(replace(rows_processed,0,1),1)))
                                           end "Buffer_gets/rows_proc",
                                      round((buffer_gets/nvl(replace(executions,0,1),1))) "Buffer_gets/executions",
                                      (elapsed_time/1000000) "Elapsed_Seconds",
                                      --round((elapsed_time/1000000)/nvl(replace(executions,0,1),1)) "Elapsed/Execution",
                                      substr(sql_text,1,500) "SQL",
                                      module "Module",SQL_ID,CHILD_NUMBER
                                 from gv$sql s
                                 where sql_id in (
select distinct sql_id from (
WITH sql_class AS
(select sql_id, state, count(*) occur from
  (select   sql_id
  ,  CASE  WHEN session_state = 'ON CPU' THEN 'CPU'
           WHEN session_state = 'WAITING' AND wait_class IN ('User I/O') THEN 'IO'
           ELSE 'WAIT' END state
    from gv$active_session_history
    where   session_type IN ( 'FOREGROUND')
    and sample_time  between trunc(sysdate,'MI') - :minutes/24/60 and trunc(sysdate,'MI') )
    group by sql_id, state),
     ranked_sqls AS
(select sql_id,  sum(occur) sql_occur  , rank () over (order by sum(occur)desc) xrank
from sql_class
group by sql_id )
select sc.sql_id, state, occur from sql_class sc, ranked_sqls rs
where rs.sql_id = sc.sql_id
--and rs.xrank <= :top_n
order by xrank, sql_id, state ))
order by elapsed_time desc nulls last
```

## 正确设置open_cursors和'session_cached_cursors'  可以减少sql解析，提高系统性能.

1、'session_cached_cursors'  数量要小于open_cursor

2、要考虑共享池的大小

3、使用下面的sql判断'session_cached_cursors'  的使用情况。如果使用率为100%则增大这个参数值。

```sql
SELECT 'session_cached_cursors' parameter,
       lpad(VALUE, 5) VALUE,
       decode(VALUE, 0, '  n/a', to_char(100 * used / VALUE, '990') || '%') usage
  FROM (SELECT MAX(s.VALUE) used
          FROM v$statname n, v$sesstat s
         WHERE n.NAME = 'session cursor cache count'
           AND s.statistic# = n.statistic#),
       (SELECT VALUE FROM v$parameter WHERE NAME = 'session_cached_cursors')
UNION ALL
SELECT 'open_cursors',
       lpad(VALUE, 5),
       to_char(100 * used / VALUE, '990') || '%'
  FROM (SELECT MAX(SUM(s.VALUE)) used
          FROM v$statname n, v$sesstat s
         WHERE n.NAME IN
               ('opened cursors current', 'session cursor cache count')
           AND s.statistic# = n.statistic#
         GROUP BY s.sid),
       (SELECT VALUE FROM v$parameter WHERE NAME = 'open_cursors')
```

```bash
PARAMETER              VALUE      USAGE
---------------------- ---------- -----
session_cached_cursors    50        98%
open_cursors             300        30%
```

如果以上命中率为100%，则调整响应的值

## DG环境创建服务避免数据库切换修改iP

```sql
exec dbms_service.create_server(
    service_name => 'proddb_rw',
    network_name => 'proddb_rw',
    aq_ha_notifications => TRUE,
    failover_method => 'BASIC',
    failover_type => 'SELECT',
    failover_retries => 30,
    failover_delay => 5
);

create trigger myapptrigg after startup on database  
declare  
 v_role varchar(30);  
begin  
 select database_role into v_role from v$database;  
 if v_role = 'PRIMARY' then  
 DBMS_SERVICE.START_SERVICE('proddb_rw');  
 else  
 DBMS_SERVICE.STOP_SERVICE('proddb_rw');  
 end if;  
end;  
/  


 begin  
 dbms_service.create_service('proddb_rw','proddb_rw');  
end;  
/  
begin  
 DBMS_SERVICE.START_SERVICE('proddb_rw');  
end;  
/  
```
