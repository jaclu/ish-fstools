#!/bin/sh

log_cleanup() {
    echo
    echo "=== Cleanout log files"
    echo
    cd /var/log || {
        echo "ERROR: cd /var/log failed"
        exit 1
    }

    rm -f alternatives.log
    rm -rf apt
    rm -rf fsck
    rm -f dpkg.log
    rm -f dmesg*
    rm -f lastlog
    rm -f oddlog
}

total_cleanup() {
    log_cleanup

    rm -rf /var/cache/*
    rm -rf /var/lib/apt/*

    rm -rf /var/tmp/*
    rm -rf /tmp/*
}

deploy_cleanup() {
    # suitable for post all install step

    rm /root/img_build -rf
    rm /root/ish-fstools -rf
    log_cleanup
}
