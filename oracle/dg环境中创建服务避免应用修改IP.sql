DG 切换应用不需要修改配置
172.16.108.11 主库
172.16.108.12 备库
 ```
dg_taf_pri =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.11)(PORT = 1521))
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.12)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = dg_taf_pri)
    )
  )
 ```
2.在primary数据库运行
```
begin
  DBMS_SERVICE.CREATE_SERVICE(service_name        => 'dg_taf_pri',
                              network_name        => 'dg_taf_pri',
                              aq_ha_notifications => TRUE,
                              failover_method     => 'BASIC',
                              failover_type       => 'SELECT',
                              failover_retries    => 30,
                              failover_delay      => 5);
end;
/
```
3. 创建存储过程，主库启动 service 监听
```
create or replace procedure dg_taf_proc is                   
    v_role VARCHAR(30);                             
  begin                                             
    select DATABASE_ROLE into v_role from V$DATABASE;
    if v_role = 'PRIMARY' then                      
      DBMS_SERVICE.START_SERVICE('dg_taf_pri');     
    else                                            
      DBMS_SERVICE.STOP_SERVICE('dg_taf_pri');      
    end if;                                         
  end;                                              
  /  
```
4. 创建触发器，主备切换时触发
```
create or replace TRIGGER dg_taf_trg_startup
  after startup or db_role_change on database
begin
  dg_taf_proc;
end;
/
```
5、客户端配置
```
dg_taf_pri =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.11)(PORT = 1521))
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.12)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = dg_taf_pri)
    )
  )
==
jdbc:oracle:thin:@(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.11)(PORT = 1521)) (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.12)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = dg_taf_pri)))
```



使用dataguard作为HA方案，要解决的一个问题在于：后台数据库发生了切换，client连接如何做到自动切到新的primary数据库上？
如果做通用的方案，需要客户端自己提供自动重连的能力，这点大多数java的occi的连接池都有实现。
但这些已有实现大多是对同一连接配置发起重连，所以需要考虑为application提供透明的连接方式，而不让应用看到具体dataguard的多个ip和service name，这就需要做些额外的配置工作。
一种方式通过vip，真实转发的ip只挂靠在有效数据库的ip上。这种方式切换发生后，application在断连的旧connection上发起dml会获得ORA-3113 "end of file on communication channel"的错误，此时application可以尝试重连机制和新的primary建立连接。
在f5上可以通过设置心跳sql和期望的返回结果内容，以类似ping方式获取远端数据库是否可用，来决定ip是否应该转发到该物理ip上。
另一种方式是通过设置tns和数据库暴露的service name来访问，通过合理设置，甚至可以做到在发生切换时的select操作仅仅被阻塞一会，而完全意识不到数据库已经完成了主备切换。
步骤如下：
 1.客户端的tnsnames.ora中tns配置成
 ```
dg_taf_pri =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.11)(PORT = 1521))
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.12)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = dg_taf_pri)
    )
  )
 ```
2.在primary数据库运行
```
begin
  DBMS_SERVICE.CREATE_SERVICE(service_name        => 'dg_taf_pri',
                              network_name        => 'dg_taf_pri',
                              aq_ha_notifications => TRUE,
                              failover_method     => 'BASIC',
                              failover_type       => 'SELECT',
                              failover_retries    => 30,
                              failover_delay      => 5);
end;
/
```
3. 创建存储过程，主库启动 service 监听
```
create or replace procedure dg_taf_proc is                   
    v_role VARCHAR(30);                             
  begin                                             
    select DATABASE_ROLE into v_role from V$DATABASE;
    if v_role = 'PRIMARY' then                      
      DBMS_SERVICE.START_SERVICE('dg_taf_pri');     
    else                                            
      DBMS_SERVICE.STOP_SERVICE('dg_taf_pri');      
    end if;                                         
  end;                                              
  /  
```
4. 创建触发器，主备切换时触发
```
create or replace TRIGGER dg_taf_trg_startup
  after startup or db_role_change on database
begin
  dg_taf_proc;
end;
/
```
5、客户端配置
```
dg_taf =
    (DESCRIPTION =
        (ADDRESS = (PROTOCOL = tcp)(HOST = 172.16.108.11)(PORT = 1521))
        (ADDRESS = (PROTOCOL = tcp)(HOST = 172.16.108.12)(PORT = 1521))
            (LOAD_BALANCE = yes)
                (CONNECT_DATA =
                    (SERVER = DEDICATED)
                    (SERVICE_NAME = dg_taf_pri)
                (FAILOVER_MODE =
                    (TYPE = session)
                    (METHOD = basic)
                    (RETRIES = 180)
                    (DELAY = 5)
               )
        )
)
或者

dg_taf_pri =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.11)(PORT = 1521))
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.12)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = dg_taf_pri)
    )
  )
==
jdbc:oracle:thin:@(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.11)(PORT = 1521)) (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.108.12)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = dg_taf_pri)))
```

这种方式需要注意的地方：

1.jdbc必须走oci的方式，如果为jdbc：thin+tns方式，则会出现

Exception in thread "main" java.lang.ArrayIndexOutOfBoundsException: 545
 at oracle.net.nl.NVTokens.parseTokens(Unknown Source)
 at oracle.net.nl.NVFactory.createNVPair(Unknown Source)

其原因在于jdbc的driver本身无法识别这种格式的tns内容。

此时即使以jdbc：thin+tns的方式访问其他正常的tns也会一样抛出这个错误，因为这导致了jdbc根本无法正确解析整个tnsnames.ora文件。

而jdbc：oci实际上负责解析tnsnames.ora和处理通信的是依赖oci.lib，因此就不存在这个问题。

2.这种配置适用于任何依赖oci通信的客户端，包括oci，occi，一些基于它们的wrap库，以及pl/sql developer此类的工具软件。

3.注意如果连接的数据库组属于manually switch的模式，而不是fail down导致的切换，比如tns中的a数据库是mount状态，b是primary，而tns的列表顺序是先a后b，则会出现尽管客户端连a时，抛出ORA-0133错误，但是不会按顺序去尝试连接b。

原因是在处理这个链接时，oci客户端会尝试通过listener和service建立连接。

如果listener是关闭的，或者客户端能连上listener但是找不到对应service，则都会尝试连接处于第二个的b，但是如果通过 listener找到了对端的service，只是无法建立连接（如数据库处于mount状态），则此时不会尝试连接b，而直接会以抛出

ORA-0133:ORACLE initialization or shutdown in progress

终止连接尝试。

所以在使用这种tns的时候要确保通过tns列表能访问到的所有数据库都不会一直处于mount状态，否则连接它会打断对后面正常open数据库的连接尝试。

这也是为何手动切换的dataguard数据库，客户端不能依赖这种tns配置方法做自动切换，因为手动切换的dataguard数据库状态肯定是一个open一个mount，如果mount处于tns的列表靠前的位置，在连接它失败后会抛出ORA-0133异常阻止客户端尝试连接正常open的那个数据库。