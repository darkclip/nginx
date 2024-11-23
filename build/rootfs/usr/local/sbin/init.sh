#!/usr/bin/env bash

mkdir -p /data/openresty/log /data/openresty/cache /data/acme/challenge /data/www
dirs=$(ls -l /data-install | awk '/^d/ {print $NF}')
data_dirs=($dirs)
for exist in ${data_dirs[@]}; do
    if [ ! "$(ls -A /data/$exist)" ]; then
        cp -r /data-install/$exist /data/
    fi
done
service cron start
nginx