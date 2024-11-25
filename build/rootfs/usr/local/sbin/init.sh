#!/usr/bin/env bash

dirs=$(ls -l /data-install | awk '/^d/ {print $NF}')
data_dirs=($dirs)
for exist in ${data_dirs[@]}; do
    if [ ! -e "/data/$exist" ]; then
        cp -r /data-install/$exist /data/
    fi
done

prepare_dirs=(
    /data/openresty/log
    /data/openresty/cache
    /data/openresty/http
    /data/openresty/stream
    /data/openresty/rtmp
    /data/acme/challenge
    /data/acme/certs
    /data/bin
)
for check in ${prepare_dirs[@]}; do
    if [ ! -e "$check" ]; then
        mkdir -p $check
    fi
done

service cron start
nginx
