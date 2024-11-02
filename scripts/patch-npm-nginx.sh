#!/bin/bash -e

sed -i "s#cd /tmp/openresty#\
git clone https://github.com/arut/nginx-rtmp-module.git\\
mv /tmp/nginx-rtmp-module /tmp/openresty/nginx-rtmp-module\\
&#g" scripts/build-openresty

sed -i "s#./configure \\\#&\\
	--add-module=/tmp/openresty/nginx-rtmp-module \\\\\
#g" scripts/build-openresty

sed -i 's#make -j2#make -j$(getconf _NPROCESSORS_ONLN)#g' scripts/build-openresty


sed -i "s#libmaxminddb-dev \\\#&\\
	cron \\\\\\
	nano \\\\\
#g" docker/Dockerfile

sed -i "s#&& /tmp/install-openresty \\\#&\\
	\&\& /tmp/install-crowdsec_openresty_bouncer \\\\\\
	\&\& useradd -s /usr/sbin/nologin nginx \\\\\\
	\&\& mkdir -p /var/log/nginx /var/cache/nginx \\\\\
#g" docker/Dockerfile

sed -i "/org.label-schema/d" docker/Dockerfile

echo 'ENTRYPOINT ["nginx", "-g", "daemon off;"]' >> docker/Dockerfile
