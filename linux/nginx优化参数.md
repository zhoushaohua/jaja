# 日常的运维工作中，我们经常会用到nginx服务，也时常会碰到nginx因高并发导致的性能瓶颈问题

今天，我来简单总结、梳理下配置文件中影响 Nginx 高并发性能的一些主要参数

优化 Nginx 进程数量
配置参数如下：

```bash
worker_processes  1; # 指定 Nginx 要开启的进程数，结尾的数字就是进程的个数，可以为 auto
```

这个参数调整的是 Nginx 服务的 worker 进程数，Nginx 有 Master 进程和 worker 进程之分，Master 为管理进程、真正接待“顾客”的是 worker 进程。

进程个数的策略：worker 进程数可以设置为等于 CPU 的核数。高流量高并发场合也可以考虑将进程数提高至 CPU 核数 x 2。这个参数除了要和 CPU 核数匹配之外，也与硬盘存储的数据及系统的负载有关，设置为 CPU 核数是个好的起始配置，也是官方建议的。

当然，如果想省麻烦也可以配置为worker_processes auto;，将由 Nginx 自行决定 worker 数量。当访问量快速增加时，Nginx 就会临时 fork 新进程来缩短系统的瞬时开销和降低服务的时间。

可通过 lscpu 命令查看服务器里有几个核（先看几个CPU,以及每个CPU是几核）。

将不同的进程绑定到不同的CPU
默认情况下，Nginx 的多个进程有可能运行在同一个 CPU 核上，导致 Nginx 进程使用硬件的资源不均，这就需要制定进程分配到指定的 CPU 核上处理，达到充分有效利用硬件的目的。配置参数如下：

```bash
worker_processes  4;
worker_cpu_affinity  0001  0010  0100  1000;
```

其中 worker_cpu_affinity 就是配置 Nginx 进程与 CPU 亲和力的参数，即把不同的进程分给不同的 CPU 核处理。这里的0001 0010 0100 1000是掩码，分别代表第1、2、3、4核CPU。上述配置会为每个进程分配一核CPU处理。

当然，如果想省麻烦也可以配置worker_cpu_affinity auto;，将由 Nginx 按需自动分配。

Nginx 事件处理模型优化
Nginx 的连接处理机制在不同的操作系统中会采用不同的 I/O 模型，在 linux 下，Nginx 使用 epoll 的 I/O 多路复用模型，在 Freebsd 中使用 kqueue 的 I/O 多路复用模型，在 Solaris 中使用 /dev/poll 方式的 I/O 多路复用模型，在 Windows 中使用 icop，等等。

配置如下：

```bash
events { use  epoll; }
```

events 指令是设定 Nginx 的工作模式及连接数上限。use指令用来指定 Nginx 的工作模式。Nginx 支持的工作模式有 select、 poll、 kqueue、 epoll 、 rtsig 和/ dev/poll。当然，也可以不指定事件处理模型，Nginx 会自动选择最佳的事件处理模型。

单个进程允许的客户端最大连接数
通过调整控制连接数的参数来调整 Nginx 单个进程允许的客户端最大连接数。这个值太小的后果就是你的系统会报：too many open files 等错误，导致你的系统死掉。

```bash
events {
 worker_connections  20480;
 }
```

worker_connections 也是个事件模块指令，用于定义 Nginx 每个进程的最大连接数，默认是 1024。

最大连接数的计算公式如下：

max_clients = worker_processes * worker_connections;

如果作为反向代理，因为浏览器默认会开启 2 个连接到 server，而且 Nginx 还会使用fds（file descriptor）从同一个连接池建立连接到 upstream 后端。则最大连接数的计算公式如下：

max_clients = worker_processes * worker_connections / 4;

另外，进程的最大连接数受 Linux 系统进程的最大打开文件数限制，在执行操作系统命令 ulimit -HSn 65535或配置相应文件后， worker_connections 的设置才能生效。

配置获取更多连接数
默认情况下，Nginx 进程只会在一个时刻接收一个新的连接，我们可以配置multi_accept 为 on，实现在一个时刻内可以接收多个新的连接，提高处理效率。该参数默认是 off，建议开启。

```bash
events {
  multi_accept on;
}
```

配置 worker 进程的最大打开文件数
调整配置 Nginx worker 进程的最大打开文件数，这个控制连接数的参数为worker_rlimit_nofile。该参数的实际配置如下:

```bash
worker_rlimit_nofile 65535;
```
可设置为系统优化后的 ulimit -HSn 的结果

优化域名的散列表大小

```bash
http {
  server_names_hash_bucket_size 128;
}
```
参数作用:设置存放域名( server names)的最大散列表的存储桶( bucket)的大小。 默认值依赖 CPU 的缓存行。

server_names_hash_bucket_size 的值是不能带单位 的。配置主机时必须设置该值，否则无法运行 Nginx，或者无法通过测试 。 该设置与 server_ names_hash_max_size 共同控制保存服务器名的 hash 表， hash bucket size 总是等于 hash 表的大小， 并且是一路处理器缓存大小的倍数。若 hash bucket size 等于一路处理器缓存的大小，那么在查找键时， 最坏的情况下在内存中查找的次数为 2。第一次是确定存储单元的地址，第二次是在存储单元中查找键值 。 若报 出 hash max size 或 hash bucket size 的提示，则需要增加 server_names_hash_max size 的值。

```bash
http {
  sendfile on;
  tcp_nopush on;
 
  keepalive_timeout 120;
  tcp_nodelay on;
}
```

第一行的 sendfile 配置可以提高 Nginx 静态资源托管效率。sendfile 是一个系统调用，直接在内核空间完成文件发送，不需要先 read 再 write，没有上下文切换开销。

TCP_NOPUSH 是 FreeBSD 的一个 socket 选项，对应 Linux 的 TCP_CORK，Nginx 里统一用 tcp_nopush 来控制它，并且只有在启用了 sendfile 之后才生效。启用它之后，数据包会累计到一定大小之后才会发送，减小了额外开销，提高网络效率。

TCP_NODELAY 也是一个 socket 选项，启用后会禁用 Nagle 算法，尽快发送数据，某些情况下可以节约 200ms（Nagle 算法原理是：在发出去的数据还未被确认之前，新生成的小数据先存起来，凑满一个 MSS 或者等到收到确认后再发送）。Nginx 只会针对处于 keep-alive 状态的 TCP 连接才会启用 tcp_nodelay。

优化连接参数

```bash
http {
  client_header_buffer_size 32k;
  large_client_header_buffers 4 32k;
  client_max_body_size 1024m;
  client_body_buffer_size 10m;
}
```

这部分更多是更具业务场景来决定的。例如client_max_body_size用来决定请求体的大小，用来限制上传文件的大小。上面列出的参数可以作为起始参数。

配置压缩优化
1、Gzip 压缩

我们在上线前，代码（JS、CSS 和 HTML）会做压缩，图片也会做压缩（PNGOUT、Pngcrush、JpegOptim、Gifsicle 等）。对于文本文件，在服务端发送响应之前进行 GZip 压缩也很重要，通常压缩后的文本大小会减小到原来的 1/4 - 1/3。

```bash
http {
  gzip on;
  #该指令用于开启或关闭gzip模块(on/off)
  
  gzip_buffers 16 8k;
  #设置系统获取几个单位的缓存用于存储gzip的压缩结果数据流。16   8k代表以8k为单位，安装原始数据大小以8k为单位的16倍申请内存
  
  gzip_comp_level 6;
  #gzip压缩比，数值范围是1-9，1压缩比最小但处理速度最快，9压缩比最大但处理速度最慢
  
  gzip_http_version 1.1;
  #识别http的协议版本
  
  gzip_min_length 256;
  #设置允许压缩的页面最小字节数，页面字节数从header头得content-length中进行获取。默认值是0，不管页面多大都压  缩。这里我设置了为256
  
  gzip_proxied any;
  #这里设置无论header头是怎么样，都是无条件启用压缩
  
  gzip_vary on;
  #在http header中添加Vary: Accept-Encoding ,给代理服务器用的
  
  gzip_types
      text/xml application/xml application/atom+xml application/rss+xml application/  xhtml+xml image/svg+xml
      text/javascript application/javascript application/x-javascript
      text/x-json application/json application/x-web-app-manifest+json
      text/css text/plain text/x-component
      font/opentype font/ttf application/x-font-ttf application/vnd.ms-fontobject
      image/x-icon;
  #进行压缩的文件类型,这里特别添加了对字体的文件类型
  
  gzip_disable "MSIE [1-6]\.(?!.*SV1)";
  #禁用IE 6 gzip
```

这部分内容比较简单，只有两个地方需要解释下：

gzip_vary 用来输出 Vary 响应头，用来解决某些缓存服务的一个问题，详情请看我之前的博客：HTTP 协议中 Vary 的一些研究。

gzip_disable 指令接受一个正则表达式，当请求头中的 UserAgent 字段满足这个正则时，响应不会启用 GZip，这是为了解决在某些浏览器启用 GZip 带来的问题。

默认 Nginx 只会针对 HTTP/1.1 及以上的请求才会启用 GZip，因为部分早期的 HTTP/1.0 客户端在处理 GZip 时有 Bug。现在基本上可以忽略这种情况，于是可以指定 gzip_http_version 1.0 来针对 HTTP/1.0 及以上的请求开启 GZip。

2、Brotli 压缩

Brotli 是基于LZ77算法的一个现代变体、霍夫曼编码和二阶上下文建模。Google软件工程师在2015年9月发布了包含通用无损数据压缩的Brotli增强版本，特别侧重于HTTP压缩。其中的编码器被部分改写以提高压缩比，编码器和解码器都提高了速度，流式API已被改进，增加更多压缩质量级别。

需要安装libbrotli、ngx_brotli，重新编译 Nginx 时，带上--add-module=/path/to/ngx_brotli即可，然后配置如下

```bash
http {
  brotli on;
  brotli_comp_level 6;
  brotli_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript image/svg+xml;
}
```

Brotli 可与 Gzip 共存在一个配置文件中

静态资源优化
静态资源优化，可以减少连接请求数，同时也不需要对这些资源请求打印日志。但副作用是资源更新可能无法及时。

```bash
server {
    # 图片、视频
    location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|mp4|ico)$ {
      expires 30d;
      access_log off;
    }
    # 字体
    location ~ .*\.(eot|ttf|otf|woff|svg)$ {
      expires 30d;
      access_log off;
    }
    # js、css
    location ~ .*\.(js|css)?$ {
      expires 7d;
      access_log off;
    }
}
```

关闭服务器版本

```bash
server_tokens off；
```

隐藏响应头中的有关操作系统和web server（Nginx）版本号的信息，这样对于安全性是有好处的。