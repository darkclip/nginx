#!/usr/bin/env bash

if [ ! "$(ls -A $DIR)" ]; then
    cp -r /data-install/* /data/
    cp -r /data-preset/$exist /data/
fi
service cron start
nginx -g 'daemon off;'