    主要核心思想，如果master 和 salve 全部存活的情况，VIP就漂移到 master。读写都从master操作，如果master宕机，VIP就会漂移到salve,并将之前的salve切换为master,当宕机的master可以继续服务的时候，
先会从salve同步数据，然后VIP漂移到master服务器上面，持续提供服务。

环境准备：
| 节点       | IP             | redis1端口 | redis2端口 | keepalived |
| ---------- | -------------- | ---------- | ---------- | ---------- |
| master     | 192.168.28.139 | 19020      | 19021      | keepalived |
| slave      | 192.168.28.140 | 19020      | 19021      | keepalived |
| keepalived | 192.168.28.99  | -          | -          | -          |

1 、下载 Redis redis-5.0.5.tar.gz
解压 tar xzf + Redis 包（重复一下操作，改名可以配置2个redis）
mv redis-5.0.5 /usr/local/redis19020
进入 Redis 文件安装
安装依赖文件
yum install gcc-c++
安装
make
mv redis.conf redis.conf.back
重写conf 文件
```bash
vim redis.conf
=======================================
daemonize yes
pidfile /var/run/redis19020.pid
#pidfile /var/run/redis19021.pid
port 19020       #19021
tcp-backlog 511
timeout 30
tcp-keepalive 60
loglevel warning
logfile /logs/redis/redis19020.log
#logfile /logs/redis/redis19021.log
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /usr/local/redis-5.0.5/ #redis 安装路径
protected-mode no#关闭保护模式
requirepass test123 #主Redis 密码
#masterauth test123    #从Redis 密码（与主一致）
#slaveof 192.168.28.139 19021 #从Redis设置 Redis主从配置（主Redis ip 端口）
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
==============================================
```
```bash
mkdir /logs/redis
touch /logs/redis/{redis19020.log,redis19021.log}
启动 redis 服务，并指定启动服务配置文件
./src/redis-server redis.conf
设置环境变量
将 Redis 添加到环境变量中：  
# vi /etc/profile
在最后添加以下内容：
## Redis env
export PATH=$PATH:/usr/local/redis19020/src
export PATH=$PATH:/usr/local/redis19021/src
使配置生效：
# source /etc/profile
现在就可以直接使用 redis-cli 等 redis 命令了 。
```
2、keepalived安装
下载 keepalived
官网 : https://keepalived.org/download.html
上传并解压 keepalived
tar -zxvf keepalived-2.0.18.tar.gz -C /usr/local/src/
进入目录 /usr/local/src/keepalived-2.0.18
cd /usr/local/keepalived-2.0.18/
检查安装环境
```bash
./configure --prefix=/usr/local/keepalived
首次检查
configure: error:
!!! OpenSSL is not properly installed on your system. !!!
!!! Can not inclu
de OpenSSL headers files.            !!!
安装 openssl openssl-devel 解决问题
yum -y install openssl openssl-devel
二次检查
*** WARNING - this build will not support IPVS with IPv6. Please install libnl/libnl-3 dev libraries to support IPv6 with IPVS.
安装 libnl libnl-devel 解决问题
yum -y install libnl libnl-devel
其他问题
configure: error: libnfnetlink headers missing
安装 libnfnetlink-devel 解决问题
yum -y install libnfnetlink-devel
编译并安装
make && make install
```
将 keepalived 添加到系统服务中
拷贝执行文件
cp /usr/local/keepalived/sbin/keepalived /usr/sbin/
将 init.d 文件拷贝到 etc 下 , 加入开机启动项
cp /usr/local/src/keepalived-2.0.18/keepalived/etc/init.d/keepalived /etc/init.d/keepalived
将 keepalived 文件拷贝到 etc 下
cp /usr/local/src/keepalived-2.0.18/keepalived/etc/sysconfig/keepalived /etc/sysconfig/
创建 keepalived 文件夹
mkdir -p /etc/keepalived
将 keepalived 配置文件拷贝到 etc 下
cp /usr/local/src/keepalived-2.0.18/keepalived/etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf
添加 keepalived 到开机启动
chkconfig --add keepalived
添加可执行权限
chmod +x /etc/init.d/keepalived
二、部署 keepalived 双击自主切换（ 以下 配置文件和脚本，两台机器都要重新布）
备份 keepalived 配置文件
cp keepalived.conf keepalived.conf.back
重新编辑配置文件
```bash
vim keepalived.conf
配置文件
================================================
! COnfiguration File for keepalived
global_defs {
router_id MASTER-HA # 主机标识
#router_id BACKUP #
备机标识
script_user root
enable_script_security
}
vrrp_script chk_redis {
script "/etc/keepalived/scripts/redis_check.sh"   # 脚本地址和名字，此处调用改脚本
interval 2
weight -5
fall 2
rise 1
}
vrrp_instance VI_1 {
state MASTER # 主机 MASTER 、备机 BACKUP
interface eth0 # 本机的网卡
virtual_router_id 51
priority 101           # 主机 101 ，备机小于 101 便可
advert_int 1
authentication {
auth_type PASS
auth_pass 1111
}
virtual_ipaddress {
192.168.28.99    # 新的 IP 地址，需要在同机网段内
}
track_script {
chk_redis
}
notify_master /etc/keepalived/scripts/redis_master.sh
notify_backup /etc/keepalived/scripts/redis_backup.sh
notify_fault /etc/keepalived/scripts/redis_fault.sh
notify_stop /etc/keepalived/scripts/redis_stop.sh
}
================================================
```
新建文件夹scripts

mkdir scripts

新建脚本文件夹

touch {redis_check.sh,redis_master.sh,redis_backup.sh,redis_fault.sh,redis_stop.sh}

编写脚本

vim redis_check.sh（共用脚本）
```bash
#!/bin/bash
#This scripts is check for Redis Slave status
#19020
counter=$(netstat -na|grep "LISTEN"|grep "19020"|wc -l)
#查询本机Redis是否存活，如果不存在，则执行以下脚本
if [ "${counter}" -eq 0 ]; then
/etc/init.d/keepalived keepalived stop
killall keepalived
fi
ping 192.168.28.139 -w1 -c1 &>/dev/null  #（本机IP）
#查询本机ip是否存活，不存活则执行以下脚本
if [ $? -ne 0 ]
then
/etc/init.d/keepalived keepalived stop
killall keepalived
fi
#19021
counterB=$(netstat -na|grep "LISTEN"|grep "19021"|wc -l)
#查询本机Redis是否存活，如果不存在，则执行以下脚本
if [ "${counterB}" -eq 0 ]; then
/etc/init.d/keepalived keepalived stop
killall keepalived
fi
ping 192.168.28.139 -w1 -c1 &>/dev/null #（本机IP）
#查询本机ip是否存活，不存活则执行以下脚本
if [ $? -ne 0 ]
then
/etc/init.d/keepalived keepalived stop
killall keepalived
fi
```



主reids脚本

vim redis_master.sh
```bash
#!/bin/bash
REDISCLI="/usr/local/redis19020/src/redis-cli -a test123 -p 19020"
LOGFILE="/var/log/keepalived-redis-state.log" #需要新建日志文件
REDISCLIA="/usr/local/redis19021/src/redis-cli -a test123 -p 19021"
LOGFILEA="/var/log/keepalived-redis-stateA.log" #需要新建日志文件
#19020
sleep 5
echo "[master]" >> $LOGFILE
date >> $LOGFILE
echo "Being master...." >>$LOGFILE 2>&1
echo "Run SLAVEOF cmd ...">> $LOGFILE
$REDISCLI SLAVEOF 192.168.28.140 19020 >>$LOGFILE  2>&1 #主库IP
if [ $? -ne 0 ];then
    echo "data rsync fail." >>$LOGFILE 2>&1
else
    echo "data rsync OK." >> $LOGFILE  2>&1
fi
sleep 5 #延迟10秒以后待数据同步完成后再取消同步状态 
echo "Run SLAVEOF NO ONE cmd ...">> $LOGFILE
$REDISCLI SLAVEOF NO ONE >> $LOGFILE 2>&1
if [ $? -ne 0 ];then
    echo "Run SLAVEOF NO ONE cmd fail." >>$LOGFILE 2>&1
else
    echo "Run SLAVEOF NO ONE cmd OK." >> $LOGFILE  2>&1
fi
#19021
sleep 5
echo "[master2]" >> $LOGFILEA
date >> $LOGFILEA
echo "Being master...." >>$LOGFILEA 2>&1
echo "Run SLAVEOF cmd ...">> $LOGFILEA
$REDISCLIA SLAVEOF 192.168.28.140 19020 >>$LOGFILEA  2>&1 #主库IP
if [ $? -ne 0 ];then
    echo "data rsync fail." >>$LOGFILEA 2>&1
else
    echo "data rsync OK." >> $LOGFILEA  2>&1
fi
sleep 10 #延迟10秒以后待数据同步完成后再取消同步状态 
echo "Run SLAVEOF NO ONE cmd ...">> $LOGFILEA
$REDISCLIA SLAVEOF NO ONE >> $LOGFILEA 2>&1
if [ $? -ne 0 ];then
    echo "Run SLAVEOF NO ONE cmd fail." >>$LOGFILEA 2>&1
else
    echo "Run SLAVEOF NO ONE cmd OK." >> $LOGFILEA  2>&1

```


redis_backup.sh
```bash
#!/bin/bash
REDISCLI="/usr/local/redis19020/src/redis-cli -a test123-p 19020"
REDISCLIA="/usr/local/redis19021/src/redis-cli -a test123 -p 19021"
LOGFILE="/var/log/keepalived-redis-state.log"
LOGFILEA="/var/log/keepalived-redis-stateA.log"
echo "[backup]" >> $LOGFILE
date >> $LOGFILE
echo "Being slave...." >>$LOGFILE 2>&1
sleep 15 #延迟15秒待数据被对方同步完成之后再切换主从角色 
echo "Run SLAVEOF cmd ...">> $LOGFILE
$REDISCLI SLAVEOF 192.168.28.140 19020 >>$LOGFILE  2>&1 #主库IP
#19021
echo "[backup2]" >> $LOGFILEA
date >> $LOGFILEA
echo "Being slave...." >>$LOGFILEA 2>&1
sleep 3 #延迟15秒待数据被对方同步完成之后再切换主从角色 
echo "Run SLAVEOF cmd ...">> $LOGFILEA
$REDISCLIA SLAVEOF 192.168.28.140 19021 >>$LOGFILEA  2>&1 #从库IP
```



从Redis脚本

vim redis_master.sh
```bash
#!/bin/bash
REDISCLI="/usr/local/redis19020/src/redis-cli -a test123 -p 19020"
REDISCLIA="/usr/local/redis19021/src/redis-cli -a test123 -p 19021"
LOGFILE="/var/log/keepalived-redis-state.log" #需要新建日志文件
LOGFILEA="/var/log/keepalived-redis-stateA.log" #需要新建日志文件
sleep 15
echo "[master]" >> $LOGFILE
date >> $LOGFILE
echo "Being master...." >>$LOGFILE 2>&1

echo "Run SLAVEOF cmd ...">> $LOGFILE
$REDISCLI SLAVEOF 192.168.28.139 19020 >>$LOGFILE 2>&1 #主库IP
sleep 10 #延迟10秒以后待数据同步完成后再取消同步状态 
echo "Run SLAVEOF NO ONE cmd ...">> $LOGFILE
$REDISCLI SLAVEOF NO ONE >> $LOGFILE 2>&1
#19021
sleep 15
echo "[masterA]" >> $LOGFILEA
date >> $LOGFILEA
echo "Being master...." >>$LOGFILEA 2>&1

echo "Run SLAVEOF cmd ...">> $LOGFILEA
$REDISCLIA SLAVEOF 192.168.28.139 19021 >>$LOGFILEA 2>&1 #主库IP
sleep 10 #延迟10秒以后待数据同步完成后再取消同步状态 
echo "Run SLAVEOF NO ONE cmd ...">> $LOGFILEA
$REDISCLIA SLAVEOF NO ONE >> $LOGFILEA 2>&1

```

redis_backup.sh
```bash
#!/bin/bash
REDISCLI="/usr/local/redis19020/src/redis-cli -a test123 -p 19020"
REDISCLIA="/usr/local/redis19021/src/redis-cli -a test123 -p 19021"
LOGFILE="/var/log/keepalived-redis-state.log"
LOGFILEA="/var/log/keepalived-redis-stateA.log"
echo "[backup]" >> $LOGFILE
date >> $LOGFILE
echo "Being slave...." >>$LOGFILE 2>&1
sleep 15 #延迟15秒待数据被对方同步完成之后再切换主从角色 
echo "Run SLAVEOF cmd ...">> $LOGFILE
$REDISCLI SLAVEOF 192.168.28.139 19020 >>$LOGFILE 2>&1 #主库IP
#19021
echo "[backupA]" >> $LOGFILEA
date >> $LOGFILEA
echo "Being slave...." >>$LOGFILEA 2>&1
sleep 3 #延迟15秒待数据被对方同步完成之后再切换主从角色 
echo "Run SLAVEOF cmd ...">> $LOGFILEA
$REDISCLIA SLAVEOF 192.168.28.139 19021 >>$LOGFILEA 2>&1 #主库IP
```
共用脚本
redis_fault.sh
```bash
#!/bin/bash
LOGFILE=/var/log/keepalived-redis-state.log
LOGFILEA=/var/log/keepalived-redis-stateA.log
echo "[fault]" >> $LOGFILE
date >> $LOGFILE
echo "[fault]" >> $LOGFILEA
date >> $LOGFILEA
```
redis_stop.sh
```bash
#!/bin/bash
LOGFILE=/var/log/keepalived-redis-state.log
LOGFILEA=/var/log/keepalived-redis-stateA.log
echo "[fault]" >> $LOGFILE
date >> $LOGFILE
echo "[fault]" >> $LOGFILEA
date >> $LOGFILEA
```
添加可执行权限
chmod +x /etc/init.d/keepalived
显示脚本文件为
https://img1.tuicool.com/nyYR7ne.png!web
启动 keepalived
/etc/init.d/keepalived start

查看是否启动成功
ps -ef | grep keepalived

启动成功之后会生成一个新的服务器 IP 地址，可通过新 IP 直接连接Redis ， 可以自由关闭其中一台Redis服务， keepalived 会自动切换到另外一台Redis服务器当中。

宕机后启动顺序为，先启动Redis，在启动keepalived即可，启动后会自动同步两台Redis的数据。