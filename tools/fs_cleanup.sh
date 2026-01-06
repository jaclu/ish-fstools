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
    local remove_dir=false
    local item

    while [[ $1 == -* ]]; do
        case $1 in
            -r | --remove-dir) remove_dir=true ;;
            --) # was a file/folder
                shift
                break
                ;;
            *) err_msg "Unknown option: $1" ;;
        esac
        shift
    done

    item=$1
    [[ -z $item ]] && err_msg "delete_item: missing path"

    if [[ -d $item ]]; then
        if $remove_dir; then
            rm -rf -- "$item" || err_msg "Failed to remove directory: $item"
            log_it "Removed directory: $item"
        else
            # shellcheck disable=SC2115 # item is already checked for being empty
            rm -rf -- "$item"/* "$item"/.??* 2>/dev/null || {
                err_msg "Failed to clear directory: $item"
            }
            log_it "Cleared directory: $item"
        fi
        return
    fi

    if [[ -f "$item" ]]; then
        rm -f -- "$item" || err_msg "Failed to remove file: $item"
        log_it "Removed file: $item"

    # Normally if item is not found it's fine, I leave the deailed notifications
    # commented out for potential later debugging purposes
    # elif [[ -e $item ]]; then
    #     log_it "Special file not removed: $item"
    # else
    #     log_it "File not found: $item"
    fi
}

delete_items() {
    local item
    for item in "${items[@]}"; do
        [[ -e $item ]] || {
            # log_it "item not found: $item"
            continue
        }
        delete_item "$item"
    done
}

not_log_cleanup() {
    local items

    lbl_1 "Cleanout log files"
    items=(
        /var/log/alternatives.log
        /var/log/apt
        /var/log/fsck
        /var/log/dmesg*
        /var/log/dpkg.log
        /var/log/lastlog
        /var/log/oddlog
    )
    delete_items
}

deploy_cleanup() {
    local items

    # suitable for post all install step
    lbl_1 "Deploy cleanup"
    items=(
        /iCloud
        /root/.bash_history
        /root/.ash_history
        /root/.tmux
        /root/.viminfo
        /root/.vimrc
    )
    delete_items
    delete_item --remove-dir /opt/AOK
    delete_item --remove-dir /etc/opt/AOK
    delete_item --remove-dir /root/img_build
    delete_item --remove-dir /root/ish-fstools
}

total_cleanup() {
    local items

    deploy_cleanup

    lbl_1 "Total cleanup apt cache and tmp folders"
    items=(
        /var/lib/apt
        /var/cache
        /var/log
        /var/tmp
        /tmp
    )
    delete_items
}

# deploy_cleanup
total_cleanup
