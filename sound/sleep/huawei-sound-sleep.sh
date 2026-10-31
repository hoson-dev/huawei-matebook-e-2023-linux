#!/bin/bash
case "$1" in
    post)
        /bin/systemctl restart huawei-sound-daemon.service
        ;;
esac
