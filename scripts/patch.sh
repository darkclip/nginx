#!/bin/bash -e

sed -i "s#cd /tmp/openresty#\
git clone https://github.com/arut/nginx-rtmp-module.git\\
mv /tmp/nginx-rtmp-module /tmp/openresty/nginx-rtmp-module\\
&#g" scripts/build-openresty

sed -i "s#./configure \\\#&\\
--add-module=/tmp/openresty/nginx-rtmp-module \\\ \
#g" scripts/build-openresty

sed -i 's#make -j2#make -j$(getconf _NPROCESSORS_ONLN)#g' scripts/build-openresty


sed -i "s#&& /tmp/install-openresty \\\#&\\
\&\& /tmp/install-crowdsec_openresty_bouncer \\\ \
#g" docker/Dockerfile

