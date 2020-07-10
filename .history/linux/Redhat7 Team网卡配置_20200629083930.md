
# man nmcli-examples

# 查看帮助

创建网络接口组
[root@centos7 ~]#nmcli connection add type team con-name team0 ifname team0 config '{"runner":{"name":"activebackup"}}'
Connection 'team0' (b59f80dc-c425-4fa6-b1ef-2935d290fa6a) successfully added.

创建port接口
[root@centos7 ~]#nmcli connection add type team-slave con-name team0-eth0 ifname eth0 master team0 
Connection 'team0-eth0' (5d7e5824-4d87-449c-8fff-42b2f20bc877) successfully added.
[root@centos7 ~]#nmcli connection add type team-slave con-name team0-eth1 ifname eth1 master team0 
Connection 'team0-eth1' (920f9f03-9f24-40bc-89eb-509e44ee606f) successfully added.

启动team接口
[root@centos7 network-scripts]#nmcli connection up team0 
[root@centos7 network-scripts]#nmcli connection up team0-eth0
[root@centos7 network-scripts]#nmcli connection up team0-eth1

查看team连接状态
[root@centos7 ~]#teamdctl team0 stat
setup:
  runner: activebackup
ports:
  eth0
    link watches:
      link summary: up
      instance[link_watch_0]:
        name: ethtool
        link: up
        down count: 0
  eth1
    link watches:
      link summary: up
      instance[link_watch_0]:
        name: ethtool
        link: up
        down count: 0
runner:
  active port: eth1
