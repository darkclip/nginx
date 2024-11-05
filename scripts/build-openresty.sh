#!/bin/bash -e

cd /tmp
./install-release.sh -u "https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz" -p /tmp/openresty -d 0
git clone https://github.com/arut/nginx-rtmp-module.git
mv /tmp/nginx-rtmp-module /tmp/openresty/nginx-rtmp-module
cd /tmp/openresty

./configure \
	--prefix=/opt/openresty \
	--sbin-path=/usr/sbin/nginx \
	--modules-path=/opt/openresty/modules \
	--conf-path=/data/openresty/nginx.conf \
	--error-log-path=/data/openresty/log/error.log \
	--http-log-path=/data/openresty/log/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/data/openresty/cache/client_temp \
	--http-proxy-temp-path=/data/openresty/cache/proxy_temp \
	--http-fastcgi-temp-path=/data/openresty/cache/fastcgi_temp \
	--http-uwsgi-temp-path=/data/openresty/cache/uwsgi_temp \
	--http-scgi-temp-path=/data/openresty/cache/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-compat \
	--with-threads \
	--with-http_ssl_module \
	--with-http_v2_module \
	--with-http_v3_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_geoip_module \
	--with-http_sub_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_auth_request_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_slice_module \
	--with-http_stub_status_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-stream \
	--with-stream_ssl_module \
	--with-stream_realip_module \
	--with-stream_geoip_module \
	--with-stream_ssl_preread_module \
	--add-module=/tmp/openresty/nginx-rtmp-module

make -j$(getconf _NPROCESSORS_ONLN)

