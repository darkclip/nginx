#!/bin/bash -e

sed -i "s#cd /tmp/openresty#\
git clone https://github.com/arut/nginx-rtmp-module.git\\
mv /tmp/nginx-rtmp-module /tmp/openresty/nginx-rtmp-module\\
&#g" build-openresty

sed -i "s#./configure \\\#&\\
	--add-module=/tmp/openresty/nginx-rtmp-module \\\\\
#g" build-openresty

sed -i "s#/etc/nginx/nginx.conf#/data/nginx/nginx.conf#g" build-openresty
sed -i "s#/var/log/nginx/#/data/nginx/log/#g" build-openresty
sed -i "s#/var/cache/nginx/#/data/nginx/cache/#g" build-openresty

sed -i 's#make -j2#make -j$(getconf _NPROCESSORS_ONLN)#g' build-openresty



