#!/usr/bin/env bash

log_it() {
    if [[ -c /dev/stderr ]]; then
        echo "$1" >/dev/stderr
    else
        echo "GLITCH: /dev/stderr is failing!!"
        echo "$1"
        exit 12
    fi
}

err_msg() {
    log_it "ERROR: $1"
    exit 11
}

lbl_1() {
    log_it
    log_it "===  $1"
    log_it
}

lbl_2() {
    log_it "---  $1"
}

delete_item() {
    local item="$1"
    local cmd="rm"

    [[ -z "$item" ]] && er_msg "delete_item() called with no param"
    # log_it "delete_item($item)"
    label="$item"
    [[ -d "$item" ]] && {
        cmd+=" -rf"
        label="$item/*"
    }
    if [[ -e "$item" ]]; then
        $cmd "$item" || err_msg "Failed to remove: $item"
        log_it "-->  Removed: $label"
    else
        lbl_2 "delete_item($label) - not found"
    fi
}

delete_items() {
    local item
    local f

    # lbl_2 "delete_items()"
    for item in "${items[@]}"; do
        log_it "><> processing item: $item"
        for f in $item; do
            log_it "><> processing f: $f"
            # handle when item contains wild char
            [[ -e $f ]] || continue
            delete_item "$f"
        done
    done
}

log_cleanup() {
    local items

    lbl_1 "Cleanout log files"
    items=(
        /var/log/alternatives.log
        /var/log/apt
        /var/log/fsck
        "/var/log/dmesg*"
        /var/log/dpkg.log
        /var/log/lastlog
        /var/log/oddlog
    )
    delete_items
}

deploy_cleanup() {
    # suitable for post all install step
    lbl_1 "Deploy cleanup"
    delete_item /root/img_build
    delete_item /root/ish-fstools
    delete_item /root/.bash_history
    delete_item /root/.ash_history
    log_cleanup
}

total_cleanup() {
    local items

    deploy_cleanup

    lbl_1 "Total cleanup apt cache and tmp folders"
    items=(
        "/var/cache/*"
        /var/lib/apt
        "/var/tmp/*"
        "/tmp/*"
    )
    delete_items
}

# deploy_cleanup
total_cleanup
# log_cleanup
