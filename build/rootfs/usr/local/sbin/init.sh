#!/usr/bin/env bash

prepare_dirs=(
    /data/openresty/log
    /data/openresty/cache
    /data/acme/challenge
    /data/www
    /data/openresty/module
    /data/openresty/http
    /data/openresty/stream
    /data/openresty/rtmp
    /data/certs
)
for check in ${prepare_dirs[@]}; do
    if [ ! -e "$check" ]; then
        mkdir -p $check
    fi
done

dirs=$(ls -l /data-install | awk '/^d/ {print $NF}')
data_dirs=($dirs)
for exist in ${data_dirs[@]}; do
    if [ ! -e "/data/$exist" ]; then
        cp -r /data-install/$exist /data/
    fi
done

service cron start
nginx
