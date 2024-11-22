#!/usr/bin/env bash

dirs=$(ls -l /data-preset | awk '/^d/ {print $NF}')
preset_dirs=($dirs)
for exist in ${preset_dirs[@]}; do
    rm /data-install/$exist
    cp -r $exist /data-install/
done
cp -r /data-install/* /data
service cron start
nginx -g 'daemon off;' -p '/data/openresty'