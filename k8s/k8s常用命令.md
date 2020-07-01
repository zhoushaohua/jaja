# K8s常用操作命令记录

```bash
[root@k8s-master1 redis]# kubectl get deployment
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment    12/12   12           12          23m
tomcat-deployment   12/12   12           12          5m23s
[root@k8s-master1 redis]# kubectl expose deployment tomcat-deployment --port=8080 --target-port=11111 --type=LoadBalancer
[root@k8s-master1 redis]# kubectl get services
NAME                                TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes                          ClusterIP      10.96.0.1       <none>        443/TCP          5d2h
nginx                               ClusterIP      None            <none>        80/TCP           2d6h
nginx-deployment                    LoadBalancer   10.99.70.63     <pending>     80:32320/TCP     19m
redis-master                        ClusterIP      10.104.124.23   <none>        6379/TCP         76m
redis-slave                         ClusterIP      10.97.184.119   <none>        6379/TCP         67m
tomcat-deployment                   LoadBalancer   10.97.55.184    <pending>     8080:31448/TCP   32s
tomcat-deployment-74db65b84-2m449   ClusterIP      10.111.80.180   <none>        8080/TCP         7m58s
```

```bash
# 查看pod信息
[root@k8s-master1 redis]# kubectl describe pod tomcat-deployment-65cf48545b-zvnlw
Name:         tomcat-deployment-65cf48545b-zvnlw
Namespace:    default
Priority:     0
Node:         k8s-node3/172.16.108.43
Start Time:   Thu, 14 May 2020 16:07:23 +0800
Labels:       app=tomcat
              pod-template-hash=65cf48545b
Annotations:  cni.projectcalico.org/podIP: 192.168.107.216/32
              cni.projectcalico.org/podIPs: 192.168.107.216/32
Status:       Running
IP:           192.168.107.216
IPs:
  IP:           192.168.107.216
Controlled By:  ReplicaSet/tomcat-deployment-65cf48545b
Containers:
  tomcat:
    Container ID:   docker://3208ea8ca45ffafce9b7fdc45b93d1a93b184f9f0038e08867a5b330edb23c85
    Image:          tomcat
    Image ID:       docker-pullable://172.16.108.100/jxbank/tomcat@sha256:7fa3968d7ebc52264c54da06c992d1fce1975734ea3b516046d73814f1199ebe
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Thu, 14 May 2020 16:08:09 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-9lrvm (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-9lrvm:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-9lrvm
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age        From                Message
  ----    ------     ----       ----                -------
  Normal  Scheduled  <unknown>  default-scheduler   Successfully assigned default/tomcat-deployment-65cf48545b-zvnlw to k8s-node3
  Normal  Pulling    5m46s      kubelet, k8s-node3  Pulling image "tomcat"
  Normal  Pulled     5m3s       kubelet, k8s-node3  Successfully pulled image "tomcat"
  Normal  Created    5m2s       kubelet, k8s-node3  Created container tomcat
  Normal  Started    5m2s       kubelet, k8s-node3  Started container tomcat
```

```bash
# k8s生成pod模板
[root@k8s-master1 redis]# kubectl create deployment nginx --image=nginx -o yaml --dry-run > test1.yaml
W0514 16:16:08.962493   29040 helpers.go:535] --dry-run is deprecated and can be replaced with --dry-run=client.

-o yaml指定我们的yaml文件
--dry-run 不在k8s中执行
>重定向到我们的文件中

[root@k8s-master1 redis]# cat test1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}
```

```bash
# 输出pod日志
[root@k8s-master2 ~]# kubectl get pod
NAME                                 READY   STATUS    RESTARTS   AGE
nginx-deploy                         1/1     Running   0          67m
nginx-deploy1                        1/1     Running   0          66m
nginx-deployment-6b474476c4-4sdlh    1/1     Running   0          51m
nginx-deployment-6b474476c4-d6gmj    1/1     Running   0          51m
nginx-deployment-6b474476c4-dqbg6    1/1     Running   0          51m
nginx-deployment-6b474476c4-f9xtr    1/1     Running   0          51m
nginx-deployment-6b474476c4-grx69    1/1     Running   0          51m
nginx-deployment-6b474476c4-hdsjn    1/1     Running   0          51m
nginx-deployment-6b474476c4-kjfjl    1/1     Running   0          51m
nginx-deployment-6b474476c4-lz9wd    1/1     Running   0          51m
nginx-deployment-6b474476c4-p5rm4    1/1     Running   0          51m
nginx-deployment-6b474476c4-qg86r    1/1     Running   0          51m
nginx-deployment-6b474476c4-qk7l9    1/1     Running   0          51m
nginx-deployment-6b474476c4-qwv2x    1/1     Running   0          51m
redis-master-7sqw7                   1/1     Running   0          108m
redis-slave-dqcn9                    1/1     Running   0          100m
redis-slave-nrp78                    1/1     Running   0          100m
tomcat-deployment-65cf48545b-5vdzj   1/1     Running   0          33m
tomcat-deployment-65cf48545b-9dc7g   1/1     Running   0          33m
tomcat-deployment-65cf48545b-cccxk   1/1     Running   0          33m
tomcat-deployment-65cf48545b-df4gp   1/1     Running   0          33m
tomcat-deployment-65cf48545b-f4xnd   1/1     Running   0          33m
tomcat-deployment-65cf48545b-l2tdx   1/1     Running   0          33m
tomcat-deployment-65cf48545b-q4njw   1/1     Running   0          33m
tomcat-deployment-65cf48545b-srkpk   1/1     Running   0          33m
tomcat-deployment-65cf48545b-vzbp2   1/1     Running   0          33m
tomcat-deployment-65cf48545b-z494p   1/1     Running   0          33m
tomcat-deployment-65cf48545b-z64nq   1/1     Running   0          33m
tomcat-deployment-65cf48545b-zvnlw   1/1     Running   0          33m
[root@k8s-master2 ~]# kubectl logs tomcat-deployment-65cf48545b-5vdzj
NOTE: Picked up JDK_JAVA_OPTIONS:  --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED
14-May-2020 08:07:43.094 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Server version name:   Apache Tomcat/9.0.35
14-May-2020 08:07:43.108 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Server built:          May 5 2020 20:36:20 UTC
14-May-2020 08:07:43.109 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Server version number: 9.0.35.0
14-May-2020 08:07:43.110 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log OS Name:               Linux
14-May-2020 08:07:43.110 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log OS Version:            4.4.222-1.el7.elrepo.x86_64
14-May-2020 08:07:43.111 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Architecture:          amd64
14-May-2020 08:07:43.111 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Java Home:             /usr/local/openjdk-11
14-May-2020 08:07:43.112 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log JVM Version:           11.0.7+10
14-May-2020 08:07:43.112 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log JVM Vendor:            Oracle Corporation
14-May-2020 08:07:43.113 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log CATALINA_BASE:         /usr/local/tomcat
14-May-2020 08:07:43.113 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log CATALINA_HOME:         /usr/local/tomcat
14-May-2020 08:07:43.151 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: --add-opens=java.base/java.lang=ALL-UNNAMED
14-May-2020 08:07:43.152 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: --add-opens=java.base/java.io=ALL-UNNAMED
14-May-2020 08:07:43.153 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED
14-May-2020 08:07:43.153 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.util.logging.config.file=/usr/local/tomcat/conf/logging.properties
14-May-2020 08:07:43.154 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager
14-May-2020 08:07:43.154 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djdk.tls.ephemeralDHKeySize=2048
14-May-2020 08:07:43.155 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.protocol.handler.pkgs=org.apache.catalina.webresources
14-May-2020 08:07:43.155 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Dorg.apache.catalina.security.SecurityListener.UMASK=0027
14-May-2020 08:07:43.156 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Dignore.endorsed.dirs=
14-May-2020 08:07:43.156 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Dcatalina.base=/usr/local/tomcat
14-May-2020 08:07:43.157 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Dcatalina.home=/usr/local/tomcat
14-May-2020 08:07:43.157 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.io.tmpdir=/usr/local/tomcat/temp
14-May-2020 08:07:43.158 INFO [main] org.apache.catalina.core.AprLifecycleListener.lifecycleEvent Loaded Apache Tomcat Native library [1.2.24] using APR version [1.6.5].
14-May-2020 08:07:43.158 INFO [main] org.apache.catalina.core.AprLifecycleListener.lifecycleEvent APR capabilities: IPv6 [true], sendfile [true], accept filters [false], random [true].
14-May-2020 08:07:43.158 INFO [main] org.apache.catalina.core.AprLifecycleListener.lifecycleEvent APR/OpenSSL configuration: useAprConnector [false], useOpenSSL [true]
14-May-2020 08:07:43.170 INFO [main] org.apache.catalina.core.AprLifecycleListener.initializeSSL OpenSSL successfully initialized [OpenSSL 1.1.1d  10 Sep 2019]
14-May-2020 08:07:44.451 INFO [main] org.apache.coyote.AbstractProtocol.init Initializing ProtocolHandler ["http-nio-8080"]
14-May-2020 08:07:44.560 INFO [main] org.apache.catalina.startup.Catalina.load Server initialization in [2,252] milliseconds
14-May-2020 08:07:44.797 INFO [main] org.apache.catalina.core.StandardService.startInternal Starting service [Catalina]
14-May-2020 08:07:44.798 INFO [main] org.apache.catalina.core.StandardEngine.startInternal Starting Servlet engine: [Apache Tomcat/9.0.35]
14-May-2020 08:07:44.827 INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["http-nio-8080"]
14-May-2020 08:07:44.858 INFO [main] org.apache.catalina.startup.Catalina.start Server startup in [294] milliseconds
```

```yaml
# 获取k8s的deploy的yaml文件信息
kubectl get deploy nginx-deployment -o yaml
kubectl get deploy nginx-deployment -o  go-template='{{.status.readyReplicas}}'
```

```bash
# 查看节点资源使用情况
[root@k8s-master1 ~]# kubectl get nodes
NAME          STATUS   ROLES    AGE   VERSION
k8s-master1   Ready    master   12d   v1.18.0
k8s-master2   Ready    master   12d   v1.18.0
k8s-master3   Ready    master   12d   v1.18.0
k8s-node1     Ready    <none>   12d   v1.18.0
k8s-node2     Ready    <none>   12d   v1.18.0
k8s-node3     Ready    <none>   12d   v1.18.0
[root@k8s-master1 ~]# kubectl describe node k8s-node1
Name:               k8s-node1
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=k8s-node1
                    kubernetes.io/os=linux
Annotations:        kubeadm.alpha.kubernetes.io/cri-socket: /var/run/dockershim.sock
                    node.alpha.kubernetes.io/ttl: 0
                    projectcalico.org/IPv4Address: 172.16.108.51/24
                    projectcalico.org/IPv4IPIPTunnelAddr: 192.168.36.64
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Sat, 09 May 2020 13:52:26 +0800
Taints:             <none>
Unschedulable:      false
Lease:
  HolderIdentity:  k8s-node1
  AcquireTime:     <unset>
  RenewTime:       Fri, 22 May 2020 11:39:36 +0800
Conditions:
  Type                 Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----                 ------  -----------------                 ------------------                ------                       -------
  NetworkUnavailable   False   Sat, 09 May 2020 13:53:01 +0800   Sat, 09 May 2020 13:53:01 +0800   CalicoIsUp                   Calico is running on this node
  MemoryPressure       False   Fri, 22 May 2020 11:38:13 +0800   Sat, 09 May 2020 13:52:26 +0800   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure         False   Fri, 22 May 2020 11:38:13 +0800   Sat, 09 May 2020 13:52:26 +0800   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure          False   Fri, 22 May 2020 11:38:13 +0800   Sat, 09 May 2020 13:52:26 +0800   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready                True    Fri, 22 May 2020 11:38:13 +0800   Sat, 09 May 2020 13:52:36 +0800   KubeletReady                 kubelet is posting ready status
Addresses:
  InternalIP:  172.16.108.51
  Hostname:    k8s-node1
Capacity:
  cpu:                8
  ephemeral-storage:  100098300Ki
  hugepages-2Mi:      0
  memory:             8174436Ki
  pods:               110
Allocatable:
  cpu:                8
  ephemeral-storage:  92250593128
  hugepages-2Mi:      0
  memory:             8072036Ki
  pods:               110
System Info:
  Machine ID:                 6f1b4991d5984c598efb660dae73af3b
  System UUID:                FCE24D56-2785-6CDA-276B-DA0BC6C9C306
  Boot ID:                    aafb2ac3-f87e-49da-bcdc-fe89be02ef2e
  Kernel Version:             4.4.222-1.el7.elrepo.x86_64
  OS Image:                   CentOS Linux 7 (Core)
  Operating System:           linux
  Architecture:               amd64
  Container Runtime Version:  docker://19.3.8
  Kubelet Version:            v1.18.0
  Kube-Proxy Version:         v1.18.0
PodCIDR:                      192.168.5.0/24
PodCIDRs:                     192.168.5.0/24
Non-terminated Pods:          (19 in total)
  Namespace                   Name                                          CPU Requests  CPU Limits   Memory Requests  Memory Limits  AGE
  ---------                   ----                                          ------------  ----------   ---------------  -------------  ---
  cattle-logging              rancher-logging-fluentd-linux-vmx9l           0 (0%)        0 (0%)       0 (0%)           0 (0%)         11d
  cattle-logging              rancher-logging-log-aggregator-linux-2mrs5    0 (0%)        0 (0%)       0 (0%)           0 (0%)         11d
  cattle-prometheus           exporter-node-cluster-monitoring-tc9vp        100m (1%)     200m (2%)    30Mi (0%)        200Mi (2%)     12d
  cattle-system               cattle-node-agent-pc8hq                       0 (0%)        0 (0%)       0 (0%)           0 (0%)         12d
  default                     nginx-deployment-6b474476c4-d6gmj             0 (0%)        0 (0%)       0 (0%)           0 (0%)         7d19h
  default                     nginx-deployment-6b474476c4-f9xtr             0 (0%)        0 (0%)       0 (0%)           0 (0%)         7d19h
  default                     nginx-deployment-6b474476c4-kjfjl             0 (0%)        0 (0%)       0 (0%)           0 (0%)         7d19h
  default                     nginx-deployment-6b474476c4-lz9wd             0 (0%)        0 (0%)       0 (0%)           0 (0%)         7d19h
  default                     tomcat-deployment-65cf48545b-cccxk            0 (0%)        0 (0%)       0 (0%)           0 (0%)         7d19h
  default                     tomcat-deployment-65cf48545b-l2tdx            0 (0%)        0 (0%)       0 (0%)           0 (0%)         7d19h
  default                     tomcat-deployment-65cf48545b-srkpk            0 (0%)        0 (0%)       0 (0%)           0 (0%)         7d19h
  default                     tomcat-deployment-65cf48545b-vzbp2            0 (0%)        0 (0%)       0 (0%)           0 (0%)         7d19h
  default                     tomcat-deployment-65cf48545b-z64nq            0 (0%)        0 (0%)       0 (0%)           0 (0%)         7d19h
  istio-system                istio-policy-97d8f4449-x8dgm                  1100m (13%)   6800m (85%)  1152Mi (14%)     5Gi (64%)      11d
  istio-system                istio-telemetry-76577984fd-84k54              1100m (13%)   6800m (85%)  1152Mi (14%)     5Gi (64%)      11d
  istio-system                kiali-7894cf74d7-76xjh                        10m (0%)      0 (0%)       0 (0%)           0 (0%)         11d
  kube-system                 calico-kube-controllers-5ff4c459d5-hsbnd      0 (0%)        0 (0%)       0 (0%)           0 (0%)         12d
  kube-system                 calico-node-zrvkg                             250m (3%)     0 (0%)       0 (0%)           0 (0%)         12d
  kube-system                 kube-proxy-45jg9                              0 (0%)        0 (0%)       0 (0%)           0 (0%)         12d
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests      Limits
  --------           --------      ------
  cpu                2560m (32%)   13800m (172%)
  memory             2334Mi (29%)  10440Mi (132%)
  ephemeral-storage  0 (0%)        0 (0%)
  hugepages-2Mi      0 (0%)        0 (0%)
Events:              <none>
[root@k8s-master1 ~]#
```