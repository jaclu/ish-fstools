#!/usr/bin/env bash

delete_item() {
    local remove_dir=false
    local item

    # msg_dbg "delete_item($*)"
    while [[ $1 == -* ]]; do
        case $1 in
            -r | --remove-dir) remove_dir=true ;;
            # --) # was a file/folder
            #     shift
            #     break
            #     ;;
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

deploy_cleanup() {
    local items

    # shellcheck disable=SC2154 # is sourced
    if fs_is_alpine; then
        apk del ansible
    elif fs_is_debian; then
        apt -y purge ansible ieee-data
        apt -y autoremove
    else
        err_msg "Unknown distro, failed to remove ansible"
    fi

    # suitable for post all install step
    msg_1 "Deploy cleanup"
    items=(
        /iCloud
        /home/jaclu/.local/bin/defgw # installed if on chroot
        /home/jaclu/.local/bin/Mbrew # installed if on chroot
        /root/.ash_history
        /root/.bash_history
        /root/.tmux
        /root/.viminfo
        /root/.vimrc
        /root/.wget-hsts
    )
    delete_items
    delete_item --remove-dir /root/.ansible
    delete_item --remove-dir /opt/AOK
    delete_item --remove-dir /etc/opt/AOK
    delete_item --remove-dir /root/img_build
    delete_item --remove-dir /root/ish-fstools
}

total_cleanup() {
    local items

    deploy_cleanup

    msg_1 "Total cleanup cache and tmp folders"
    msg_dbg "cache apk before"
    ls /var/cache/apk
    items=(
        /var/lib/apt
        /var/cache
        /var/log
        /var/tmp
        /tmp
    )
    delete_items
    msg_dbg "cache apk after"
    ls /var/cache/apk
}

#===============================================================
#
#   Main
#
#===============================================================

f_ift_common=/usr/local/lib/ift-utils.sh
# shellcheck source=/dev/null # not available on deploy machines
. "$f_ift_common" || {
    echo "ERROR: Failed to source: $f_ift_common"
    exit 1
}

# {
#     echo
#     echo "ERROR: failed to source: /usr/local/lib/ift-utils.sh"
#     echo
#     echo "       Should only be run inside iSH or a chrooted iSH env"
#     exit 99
# }

# deploy_cleanup
total_cleanup
