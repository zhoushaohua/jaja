# Oracle11g for rac upgrade Oracle19c for rac升级文档

  原环境为基于redhat6.10的oracle11g双节点rac环境，由于升级到oracle19c的系统最低版本为redhat7.4，所以采用底层存储复制的方式进行异机升级。目标环境为基于redhat7.6的oracle19c双节点rac环境
  
## 1、主库存储lun复制（步骤忽略，实验步骤为原环境11g数据库停止，通过dd的方式对asm磁盘复制到新的asm磁盘）
```bash
dd if=/dev/mapper/mpathi(11g的数据盘) of=/dev/mapper/oradata(19c的数据盘)
```
## 2、oracle19c rac环境安装部署
### 2.1、grid安装
  数据盘以及归档盘不需要创建，通过dd直接复制11g环境的数据盘可以在asm里面直接识别，仅需要修改相关版本信息。
  ```sql
  在asm里面执行alter diskgroup oradata mount,时会报ORA-59303: The attribute compatible.asm (10.1.0.0.0) of the diskgroup being错误。此时执行：
  select name,DATABASE_COMPATIBILITY ,COMPATIBILITY from  v$asm_diskgroup ##查看asm磁盘版本
  select name,state from gv$asm_diskgroup;  ## 查看磁盘组挂载状态
 alter diskgroup oradata mount restricted;
 alter diskgroup oradata set attribute 'compatible.asm'='19.0';  
 alter diskgroup oradata dismount;    ---该步骤一定需要
 alter diskgroup oradata mount;
  ```
### 2.2、oracle安装
  忽略，仅安装软件即可

## 3、开始oracle升级
### 3.1、修改cluster_database
```sql
alter system set cluster_database=false scope=spfile;
shutdown immediate;
startup mount
alter database open upgrade;
使用dbupgrade升级操作：dbupgrade -u sys
升级完成后数据库为关闭状态，启动至：migrate模式
SQL> @?/rdbms/admin/utlirp.sql
SQL> shutdown immediate
SQL> startup
SQL> @?/rdbms/admin/utlrp.sql
查看相关组件状态
SQL> col comp_name for a40
SQL> set wrap off
SQL> set pagesize 999
SQL> select comp_name,version, status from dba_registry;
由于在19c里面OLAP Catalog组件官方已经有明确说明,12c里面已经不支持,可以升级之后把其卸载
SQL> conn / as sysdba
SQL> spool remove_olap.log
----> Remove OLAP Catalog
SQL> @?/olap/admin/catnoamd.sql
检查时区，根据提示操作
?/rdbms/admin/utltz_upg_check.sql
```


