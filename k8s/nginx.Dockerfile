FROM centos

RUN yum install -y gcc make pcre-devel zlib-devel tar zlib
ADD nginx-1.18.0.tar.gz /usr/src

RUN  cd /usr/src/nginx-1.18.0 \
    && mkdir /usr/local/nginx \
    && ./configure --prefix=/usr/local/nginx && make && make install \
    && ln -s /usr/local/nginx/sbin/nginx /usr/local/sbin/nginx

RUN rm -rf /usr/src/nginx-1.18.0*

EXPOSE 80