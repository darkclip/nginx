#!/usr/bin/env bash

if [ ! "$(ls -A $DIR)" ]; then
    cp -r /data-install/* /data
    dirs=$(ls -l /data-preset | awk '/^d/ {print $NF}')
    preset_dirs=($dirs)
    for exist in ${preset_dirs[@]}; do
        cp -r /data-preset/$exist /data/
    done
fi
service cron start
nginx -g 'daemon off;'