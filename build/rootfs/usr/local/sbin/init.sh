#!/usr/bin/env bash

if [ ! "$(ls -A $DIR)" ]; then
    cp -r /data-install/* /data/
fi
service cron start
nginx