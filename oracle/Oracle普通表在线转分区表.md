# ORACLE在线重定义--将普通表转化为分区表

- [ORACLE在线重定义--将普通表转化为分区表](#oracle在线重定义--将普通表转化为分区表)
  - [1、建立测试表](#1建立测试表)
  - [2、查看表数据，查看分区表分区条件](#2查看表数据查看分区表分区条件)
  - [3、建立中间分区表](#3建立中间分区表)
  - [4、在线重定义](#4在线重定义)
  - [5、执行冲定义后的分区数据同步](#5执行冲定义后的分区数据同步)
  - [6、完成在线重定义操作](#6完成在线重定义操作)
  - [7、错误说明](#7错误说明)

## 1、建立测试表

```sql
create table t(id number,time date);
select count(*) from t;

insert into t select rownum,CREATED from ALL_OBJECTS;

GRANT ALL ON SYS.DBMS_REDEFINITION TO admin;

SQL> EXEC DBMS_REDEFINITION.CAN_REDEF_TABLE('admin','T', DBMS_REDEFINITION.CONS_USE_PK);
BEGIN DBMS_REDEFINITION.CAN_REDEF_TABLE('admin','T', DBMS_REDEFINITION.CONS_USE_PK); END;

*
ERROR at line 1:
ORA-12089: cannot online redefine table "ADMIN"."T" with no primary key
ORA-06512: at "SYS.DBMS_REDEFINITION", line 285
ORA-06512: at "SYS.DBMS_REDEFINITION", line 5943
ORA-06512: at line 1

# 修改主键
SQL> alter table t add constraint pk_t primary key(Id);

Table altered.

# 验证表是否可在线重定义
SQL> EXEC DBMS_REDEFINITION.CAN_REDEF_TABLE('admin','T', DBMS_REDEFINITION.CONS_USE_PK);

PL/SQL procedure successfully completed.
```

## 2、查看表数据，查看分区表分区条件

```plsql
select to_char(min(time),'yyyy-mm-dd hh24:mi:ss') from t;
select to_char(max(time),'yyyy-mm-dd hh24:mi:ss') from t;
```

## 3、建立中间分区表

```sql
CREATE TABLE T_NEW (ID NUMBER PRIMARY KEY, TIME DATE) PARTITION BY RANGE (TIME)
(
PARTITION T_2019_01 VALUES LESS THAN (TO_DATE('2019-1-1', 'YYYY-MM-DD')),
PARTITION T_2019_02 VALUES LESS THAN (TO_DATE('2019-2-1', 'YYYY-MM-DD')),
PARTITION T_2019_03 VALUES LESS THAN (TO_DATE('2019-3-1', 'YYYY-MM-DD')),
PARTITION T_2019_04 VALUES LESS THAN (TO_DATE('2019-4-1', 'YYYY-MM-DD')),
PARTITION T_2019_05 VALUES LESS THAN (TO_DATE('2019-5-1', 'YYYY-MM-DD')),
PARTITION T_2019_06 VALUES LESS THAN (TO_DATE('2019-6-1', 'YYYY-MM-DD')),
PARTITION T_2019_07 VALUES LESS THAN (TO_DATE('2019-7-1', 'YYYY-MM-DD')),
PARTITION T_2019_08 VALUES LESS THAN (TO_DATE('2019-8-1', 'YYYY-MM-DD')),
PARTITION T_2019_09 VALUES LESS THAN (TO_DATE('2019-9-1', 'YYYY-MM-DD')),
PARTITION T_2019_10 VALUES LESS THAN (TO_DATE('2019-10-1', 'YYYY-MM-DD')),
PARTITION T_2019_11 VALUES LESS THAN (TO_DATE('2019-11-1', 'YYYY-MM-DD')),
PARTITION T_2019_12 VALUES LESS THAN (TO_DATE('2019-12-1', 'YYYY-MM-DD')),
PARTITION T_2020_01 VALUES LESS THAN (TO_DATE('2020-1-1', 'YYYY-MM-DD')),
PARTITION T_2020_02 VALUES LESS THAN (TO_DATE('2020-2-1', 'YYYY-MM-DD')),
PARTITION T_2020_03 VALUES LESS THAN (TO_DATE('2020-3-1', 'YYYY-MM-DD')),
PARTITION T_2020_04 VALUES LESS THAN (TO_DATE('2020-4-1', 'YYYY-MM-DD')),
PARTITION T_2020_05 VALUES LESS THAN (TO_DATE('2020-5-1', 'YYYY-MM-DD')),
PARTITION T_2020_06 VALUES LESS THAN (TO_DATE('2020-6-1', 'YYYY-MM-DD')),
PARTITION T_2020_07 VALUES LESS THAN (TO_DATE('2020-7-1', 'YYYY-MM-DD')),
PARTITION T_2020_08 VALUES LESS THAN (TO_DATE('2020-8-1', 'YYYY-MM-DD')),
PARTITION T_2020_09 VALUES LESS THAN (TO_DATE('2020-9-1', 'YYYY-MM-DD')),
PARTITION T_2020_10 VALUES LESS THAN (TO_DATE('2020-10-1', 'YYYY-MM-DD')),
PARTITION T_2020_11 VALUES LESS THAN (TO_DATE('2020-11-1', 'YYYY-MM-DD')),
PARTITION T_2020_12 VALUES LESS THAN (TO_DATE('2020-12-1', 'YYYY-MM-DD'))
);
```

## 4、在线重定义

```sql
SQL> exec dbms_redefinition.start_redef_table('ADMIN','T','T_NEW');

PL/SQL procedure successfully completed.
```

## 5、执行冲定义后的分区数据同步

```sql
exec dbms_redefinition.sync_interim_table('ADMIN','T','T_NEW');
```

## 6、完成在线重定义操作

```sql
EXEC DBMS_REDEFINITION.FINISH_REDEF_TABLE('ADMIN','T','T_NEW');
```

## 7、错误说明

```sql
#start后会产生一个物化视图，如果中途失败不做abort会导致物化视图一次存在，下一次操作时会报：

SQL> EXEC DBMS_REDEFINITION.START_REDEF_TABLE('test', 'T', 'T_NEW');
BEGIN DBMS_REDEFINITION.START_REDEF_TABLE('test', 'T', 'T_NEW'); END;

*
ERROR at line 1:
ORA-12091: cannot online redefine table "test"."T" with
materialized views
ORA-06512: at "SYS.DBMS_REDEFINITION", line 50
ORA-06512: at "SYS.DBMS_REDEFINITION", line 1343
ORA-06512: at line 1

SQL> drop materialized view log on T;
```

```sql
# ORA-14400: inserted partition key does not map to any partition
# 这个报错的意思是分区表建立时有值在分区表之外，未被包含，可以查询下数据把缺失的分区表建立起来
SQL> select to_char(max(time),'YYYY-MM-DD HH24:MI:SS') from t;

TO_CHAR(MAX(TIME),'
-------------------
2014-05-01 21:40:35  

SQL> select partition_name from user_tab_partitions where table_name='T_NEW';

PARTITION_NAME
------------------------------
T_2003
T_2004
T_2005
T_2006
T_2007
T_2008
T_2009
T_2010
T_2011
T_2012
T_2013

11 rows selected.

SQL> ALTER TABLE T_NEW ADD PARTITION T_2014 VALUES LESS THAN (TO_DATE('2015-01-01','YYYY-MM-DD'));

Table altered.


SQL> select partition_name from user_tab_partitions where table_name='T_NEW';

PARTITION_NAME
------------------------------
T_2003
T_2004
T_2005
T_2006
T_2007
T_2008
T_2009
T_2010
T_2011
T_2012
T_2013
T_2014

12 rows selected.
```

如果执行在线重定义的过程中出错,可以在执行dbms_redefinition.start_redef_table之后到执行dbms_redefinition.finish_redef_table之前的时间里
执行：DBMS_REDEFINITION.abort_redef_table('test', 't', 't_new')以放弃执行在线重定义。

```sql
select PARTITION_NAME,NUM_ROWS from dba_tab_partitions where TABLE_NAME='T'
exec dbms_stats.gather_table_stats(ownname=>'ADMIN',tabname=>'T');
```
