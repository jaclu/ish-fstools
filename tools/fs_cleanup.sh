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
            msg_2 "Removed directory: $item"
        else
            # shellcheck disable=SC2115 # item is already checked for being empty
            rm -rf -- "$item"/* "$item"/.??* 2>/dev/null || {
                err_msg "Failed to clear directory: $item"
            }
            msg_2 "Cleared directory: $item"
        fi
        return
    fi

    if [[ -f "$item" ]]; then
        rm -f -- "$item" || err_msg "Failed to remove file: $item"
        msg_4 "Removed file: $item"

    # Normally if item is not found it's fine, I leave the deailed notifications
    # commented out for potential later debugging purposes
    # elif [[ -e $item ]]; then
    #     msg_2 "Special file not removed: $item"
    # else
    #     msg_2 "File not found: $item"
    fi
}

delete_items() {
    local item
    for item in "${items[@]}"; do
        [[ -e $item ]] || {
            # msg_3 "item not found: $item"
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
        # /home/jaclu/.local/bin/defgw # installed if on chroot
        # /home/jaclu/.local/bin/Mbrew # installed if on chroot
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
    items=(
        /var/lib/apt
        /var/cache
        /var/log
        /var/tmp
        /tmp
    )
    delete_items
}

load_utils() {
    local d_base="${1:-$d_repo}"
    local f_utils="$d_base"/tools/script_utils.sh

    # source a POSIX file
    # shellcheck source=tools/script_utils.sh disable=SC1091,SC2317
    source "$f_utils" || {
        printf '\nERROR: Failed to source: %s\n' "$f_utils" >&2
        exit 1
    }
}

#===============================================================
#
#   Main
#
#===============================================================

d_repo=$(cd -- "$(dirname -- "$0")/.." && pwd) # one folder above this

load_utils

{ is_ish || is_chrooted_ish; } || err_msg "Can only run on iSH"
exit 1

if [ "$1" = "total" ]; then
    total_cleanup
else
    deploy_cleanup
fi

