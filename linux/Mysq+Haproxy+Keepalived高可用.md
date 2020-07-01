## 两种模式
第一种：数据库宕机触发VIP漂移的高可用使用。
第二种：haproxy宕机出发VIP漂移的高可用。

这两种模式的底层数据库均为双主模式或者MGR的多主模式，mariadb的galera模式，percona的pxc模式；也就是底层的数据库每一个都可写。
在双主的模式下，如果添加了haproxy这一层，那么就可以实现了数据库读写的负载均衡，VIP随着haproxy的状态而漂移，即上面提到的第一种情况。
如果没有加入haproxy这一层，那么就只实现了双主模式数据库的高可用，即一个数据库宕机，则VIP漂移，VIP随着数据库的状态而漂移，即上面提到的第二种情况。
下面分别来说明这两种情况的使用。

```bash
双主模式的数据库： 10.9.8.201和10.9.8.223
VIP地址：10.9.8.120
```

### 数据库宕机触发VIP漂移
已经配置好的双主模式数据库。然后在两个服务器上分别下载keepalive软件，直接yum安装即可。
keepalived的配置文件有很长，原因是里面有lvs的配置，这里只需要部分配置即可，如下：

```bash
[root@test1 keepalived]# vim /etc/keepalived/keepalived.conf 

! Configuration File for keepalived

global_defs {
   router_id LVS_DB2
}

vrrp_script check_haproxy {
    script "/etc/keepalived/check_mysql.sh"
    interval 3
    weight -5
}

vrrp_instance VI_1 {
    state MASTER
    interface ens33
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        10.9.8.120 dev ens33
    }

    track_script {
        check_haproxy
    }
}
```
检测脚本内容如下：脚本内容很简单，就是检查mysql进程是否存在，若是不存在，则停止当前的keepalive，让其VIP进行漂移。【要给检测脚本加上可执行的权限】

```bash
#!/bin/bash
if [ $(ps -C mysqld --no-header | wc -l) -eq 0 ]; then
    service keepalived stop
fi
```
上面就是master的配置，做为backup的keepalived的配置和上面基本一样，只需要更改router_id，state，priority三个值即可。

state值的说明，主和备keepalived的state的值均可以设置为BACKUP，这样的话，先启动的服务器即为主，当发生VIP漂移后，原来的主启动后VIP不会再发生漂移，可以减少网络抖动的影响。

测试：

```bash
[root@test1 keepalived]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:0c:29:01:9c:98 brd ff:ff:ff:ff:ff:ff
    inet 10.9.8.201/22 brd 10.9.11.255 scope global ens33
       valid_lft forever preferred_lft forever
    inet 10.9.8.120/32 scope global ens33
       valid_lft forever preferred_lft forever
    inet6 fe80::744a:3948:cdf2:1976/64 scope link 
       valid_lft forever preferred_lft forever
[root@test1 keepalived]# ps uax |grep mysql
root      60710  0.0  0.0  11764  1632 pts/0    S    15:21   0:00 /bin/sh /usr/local/mysql/bin/mysqld_safe --datadir=/data/mysql/data --pid-file=/data/mysql/data/test1.pid
mysql     62092  0.0 16.5 2190032 309408 pts/0  Sl   15:21   0:01 /usr/local/mysql/bin/mysqld --basedir=/usr/local/mysql --datadir=/data/mysql/data --plugin-dir=/usr/local/mysql/lib/plugin --user=mysql --log-error=/data/mysql/log/error.log --open-files-limit=65535 --pid-file=/data/mysql/data/test1.pid --socket=/data/mysql/run/mysql.sock --port=3306
root      63704  0.0  0.0 112648   960 pts/0    R+   16:00   0:00 grep --color=auto mysql
[root@test1 keepalived]#
```

主上面的VIP存在以及mysql服务存在。停掉主上面的mysql服务，查看VIP是否漂移。【主上的VIP已经不存在】

```bash
[root@test1 keepalived]# service mysqld stop
Shutting down MySQL........... SUCCESS! 
[root@test1 keepalived]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:0c:29:01:9c:98 brd ff:ff:ff:ff:ff:ff
    inet 10.9.8.201/22 brd 10.9.11.255 scope global ens33
       valid_lft forever preferred_lft forever
    inet6 fe80::744a:3948:cdf2:1976/64 scope link 
       valid_lft forever preferred_lft forever
[root@test1 keepalived]# ps aux |grep mysql
root      63933  0.0  0.0 112648   956 pts/0    R+   16:01   0:00 grep --color=auto mysql
[root@test1 keepalived]#
```

在back上面查看VIP是否存在：【可以看到VIP已经漂移到BACKUP上面】

```bash
[root@monitor keepalived]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:0c:29:7c:ae:10 brd ff:ff:ff:ff:ff:ff
    inet 10.9.8.223/22 brd 10.9.11.255 scope global ens33
       valid_lft forever preferred_lft forever
    inet 10.9.8.120/32 scope global ens33
       valid_lft forever preferred_lft forever
    inet6 fe80::d4e4:4f75:1be6:2134/64 scope link 
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN 
    link/ether 02:42:25:78:a0:39 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
[root@monitor keepalived]#
```

上面的实例中VIP随着数据库的状态而漂移。
## HAPROXY状态触发VIP漂移

在这个架构下，其实就是在上面mysql+keepalived的架构中插入一层，使用haproxy做负载均衡。

在两台机器上分别安装haproxy，直接yum安装即可，haproxy的配置很简单，就是做一个负载均衡。

配置很简单，haproxy的两个服务器都是用同样的配置。【需要说明，因为后面访问的是mysql，因此需要使用四层负载均衡，mode需要选择tcp】

```bash

#---------------------------------------------------------------------
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
frontend mysql
    mode tcp
    bind *:6039
    default_backend back_mysql
#---------------------------------------------------------------------
# static backend for serving up images, stylesheets and such
#---------------------------------------------------------------------
backend back_mysql
    mode  tcp
    balance     roundrobin
    server  db1 10.9.8.201:3306 check
    server  db2 10.9.8.223:3306 check
```

然后修改keepalived的检测脚本，上面的模式检查的是mysql的状态，这一次检查的是haproxy的状态。

```bash

! Configuration File for keepalived

global_defs {
   router_id LVS_DB2
}

vrrp_script check_haproxy {
    script "/etc/keepalived/check_haproxy_status.sh"
    interval 3
    weight -5
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 51
    priority 9
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        10.9.8.120 dev ens33
    }
    track_script {
        check_haproxy
    }
}
```

脚本内容如下：

```bash
#!/bin/bash
if [ $(ps -C haproxy --no-header | wc -l) -eq 0 ];then
    sudo service keepalived stop
fi
```

修改完之后重启keepalive即可。

加入了haproxy需要说明的是，在连接数据库的时候需要使用VIP+haproxy_PORT，上面我们配置haproxy监听了6039端口，那么连接的时候就是用VIP+6039端口。