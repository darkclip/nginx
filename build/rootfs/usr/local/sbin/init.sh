#!/usr/bin/env bash

mkdir -p \
/data/openresty/log \
/data/openresty/cache \
/data/acme/challenge \
/data/www \
/data/openresty/module \
/data/openresty/http \
/data/openresty/stream \
/data/openresty/rtmp \
/data/certs
dirs=$(ls -l /data-install | awk '/^d/ {print $NF}')
data_dirs=($dirs)
for exist in ${data_dirs[@]}; do
    if [ ! "$(ls -A /data/$exist &>/dev/null)" ]; then
        cp -r /data-install/$exist /data/
    fi
done
service cron start
nginx