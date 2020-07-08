# Oracle推进SCN系列：使用oradebug在mount状态下推进SCN

环境：RHEL 6.5(x86-64) + Oracle 11.2.0.4
声明：推进SCN属于非常规恢复范畴，不建议非专业人员操作，否则后果自负。
需求：我这里演示下推进SCN 10W数量级，实际需求推进多少可以根据ORA-600 [2662] [a] [b] [c] [d] [e]具体值来确认。

## 1.查看当前数据库的Current SCN

```sql
SYS@orcl> select current_scn||'' from v$database;

CURRENT_SCN||''
--------------------------------------------------------------------------------
4563483988
```

可以看到当前SCN是4563483988，我现在想推进SCN，在10w级别，也就是4563483988标红数字修改为指定值。

## 2.重新启动数据库到mount阶段

重新启动数据库到mount阶段:

```sql
SYS@orcl> shutdown abort
ORACLE instance shut down.
SYS@orcl> startup mount
ORACLE instance started.

Total System Global Area 1235959808 bytes
Fixed Size                  2252784 bytes
Variable Size             788529168 bytes
Database Buffers          436207616 bytes
Redo Buffers                8970240 bytes
Database mounted.
```

## 3.使用oradebug poke推进SCN

我这里直接把十万位的"4"改为"9"了，相当于推进了50w左右： 说明：实验发现oradebug poke 推进的SCN值，既可以指定十六进制的0x11008DE74，也可以直接指定十进制的4563983988。

```sql
SYS@orcl> oradebug setmypid
Statement processed.
SYS@orcl> oradebug dumpvar sga kcsgscn_
kcslf kcsgscn_ [06001AE70, 06001AEA0) = 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 6001AB50 00000000
SYS@orcl> select to_char(checkpoint_change#, 'XXXXXXXXXXXXXXXX') from v$database;

TO_CHAR(CHECKPOINT_CHANGE#,'XXXXXX
----------------------------------
        110013C41

SYS@orcl> oradebug poke 0x06001AE70 8 4563983988
BEFORE: [06001AE70, 06001AE78) = 00000000 00000000
AFTER:  [06001AE70, 06001AE78) = 1008DE74 00000001

SYS@orcl> oradebug dumpvar sga kcsgscn_
kcslf kcsgscn_ [06001AE70, 06001AEA0) = 1008DE74 00000001 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 6001AB50 00000000

SYS@orcl> alter database open;

Database altered.

SYS@orcl> select current_scn||'' from v$database;

CURRENT_SCN||''
--------------------------------------------------------------------------------
4563984271
可以看到已经成功将SCN推进到4563983988，SCN不断增长，所以这里查到的值略大一些。
```

## 4.补充实际计算推进SCN的方法

本文在 2018-12-16 进一步补充说明： 在实际这类工作中，我们实际应该是要认真计算好需要推进SCN的值，而不应图省事直接给一个很大的值。后者不但是技术水平不成熟的表现，而且是不负责任的行为。
--ORA-00600: internal error code, arguments: [2662], [2], [1424107441], [2], [1424142235], [8388617], [], []
select 2*power(2,32)+1424142235 from dual;
10014076827

--ORA-00600: internal error code, arguments: [2662], [2], [1424142249], [2], [1424142302], [8388649], [], []
select 2*power(2,32)+1424143000 from dual;
10014077592
总结公式：c* power(2,32) + d {+ 可适当加一点，但不要太大！}
c代表：Arg [c] dependent SCN WRAP
d代表：Arg [d] dependent SCN BASE

```sql
[oracle@jaja ~]$ sqlplus / as sysdba

SQL*Plus: Release 11.2.0.4.0 Production on Wed Jul 8 16:34:01 2020

Copyright (c) 1982, 2013, Oracle.  All rights reserved.

Connected to an idle instance.

SQL> startup mount
ORACLE instance started.

Total System Global Area  392495104 bytes
Fixed Size                  2253584 bytes
Variable Size             176164080 bytes
Database Buffers          209715200 bytes
Redo Buffers                4362240 bytes
Database mounted.
SQL> 
SQL> select current_scn||'' from v$database;

CURRENT_SCN||''
--------------------------------------------------------------------------------
0

SQL> alter database open;

Database altered.

SQL> select current_scn||'' from v$database;

CURRENT_SCN||''
--------------------------------------------------------------------------------
1409997

SQL> shutdown abort
ORACLE instance shut down.
SQL> startup mount
ORACLE instance started.

Total System Global Area  392495104 bytes
Fixed Size                  2253584 bytes
Variable Size             176164080 bytes
Database Buffers          209715200 bytes
Redo Buffers                4362240 bytes
Database mounted.
SQL> oradebug setmypid
Statement processed.
SQL> oradebug dumpvar sga kcsgscn_
kcslf kcsgscn_ [06001AE70, 06001AEA0) = 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 6001AB50 00000000
SQL> select to_char(checkpoint_change#, 'XXXXXXXXXXXXXXXX') from v$database;

TO_CHAR(CHECKPOINT_CHANGE#,'XXXXXX
----------------------------------
           1581F1

SQL> oradebug poke 0x06001AE70 8 2000000
BEFORE: [06001AE70, 06001AE78) = 00000000 00000000
AFTER:  [06001AE70, 06001AE78) = 001E8480 00000000
SQL> alter database open;

Database altered.

SQL> select current_scn||'' from v$database;

CURRENT_SCN||''
--------------------------------------------------------------------------------
2000342

SQL>
```
