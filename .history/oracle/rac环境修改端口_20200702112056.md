1.查看Oracle数据库RAC集群默认监听端口，以下操作都在一个节点上执行即可
su - grid
srvctl config listener

2.通过srvctl命令来修改监听端口
srvctl config listener
srvctl modify listener -l LISTENER -p "TCP:2261"
srvctl config listener

3.通过srvctl 命令来修改scan监听端口
srvctl config scan_listener
srvctl modify scan_listener  -p 2261
srvctl config scan_listener

4.连接到数据库中，查看默认情况下数据库监听端口地址信息
show parameter listener

5.修改数据库监听端口地址信息
alter system set local_listener='(ADDRESS=(PROTOCOL=TCP)(HOST=172.16.1.57)(PORT=2261))' scope=both sid='ljq1';
alter system set local_listener='(ADDRESS=(PROTOCOL=TCP)(HOST=172.16.1.58)(PORT=2261))' scope=both sid='ljq2';
6.修改remote监听信息
alter system set remote_listener='cluster02scan:2261' scope=both sid='*';
7.重启监听
srvctl stop listener  
srvctl start listener
srvctl stop scan_listener
srvctl start scan_listener
8.修改完成后检查和测试登录
sqlplus sys/oracle@172.16.1.56:2261/ljq as sysdba