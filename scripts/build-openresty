#!/bin/bash -e

cd /tmp
./install-release.sh -u "https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz" -p /tmp/openresty -d 0
git clone https://github.com/leev/ngx_http_geoip2_module.git
mv /tmp/ngx_http_geoip2_module /tmp/openresty/ngx_http_geoip2_module
git clone https://github.com/arut/nginx-rtmp-module.git
mv /tmp/nginx-rtmp-module /tmp/openresty/nginx-rtmp-module
cd /tmp/openresty

./configure \
	--add-module=/tmp/openresty/nginx-rtmp-module \
	--prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--modules-path=/usr/lib/nginx/modules \
	--conf-path=/data/nginx/nginx.conf \
	--error-log-path=/data/nginx/log/error.log \
	--http-log-path=/data/nginx/log/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/data/nginx/cache/client_temp \
	--http-proxy-temp-path=/data/nginx/cache/proxy_temp \
	--http-fastcgi-temp-path=/data/nginx/cache/fastcgi_temp \
	--http-uwsgi-temp-path=/data/nginx/cache/uwsgi_temp \
	--http-scgi-temp-path=/data/nginx/cache/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-compat \
	--with-threads \
	--with-http_addition_module \
	--with-http_auth_request_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_mp4_module \
	--with-http_random_index_module \
	--with-http_realip_module \
	--with-http_secure_link_module \
	--with-http_slice_module \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_sub_module \
	--with-http_v2_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-stream \
	--with-stream_realip_module \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
	--add-dynamic-module=/tmp/openresty/ngx_http_geoip2_module

make -j$(getconf _NPROCESSORS_ONLN)

