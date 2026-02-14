#!/usr/bin/env bash
#
#  Part of https://github.com/jaclu/ish-fstools
#
#  Copyright (c) 2026: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#

delete_items() {
    local item

    for item in "${items[@]}"; do
        [[ -e $item ]] || {
            # lbl_3 "item not found: $item"
            continue
        }
        safe_remove "$@" "$item"
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
    lbl_1 "Deploy cleanup"
    items=(
        /root/.ansible
        /root/.ash_history
        /root/.bash_history
        /root/.config
        /root/.ssh
        /root/.tmux
        /root/.tmux.conf
        /root/.viminfo
        /root/.vimrc
        /root/.wget-hsts
        /root/ish-fstools
        /root/tmp
    )
    delete_items --remove-dir

    items=(
        /iCloud
    )
    delete_items # Keep folder just clear it

    items=(
        /opt/AOK
        /etc/opt/AOK
    )
    delete_items --remove-dir --ignore-sys-path
}

total_cleanup() {
    local items

    deploy_cleanup

    lbl_1 "Total cleanup cache and tmp folders"
    items=(
        /var/cache
        /var/lib/apt
        /var/log
        /var/tmp
        /tmp
    )
    delete_items --ignore-sys-path
}

load_utils() {
    local d_base="${1:-$d_repo}"
    local f_utils="$d_base"/tools/script-utils.sh

    # source a POSIX file
    # shellcheck source=tools/script-utils.sh disable=SC1091,SC2317
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

{ is_ish || is_chrooted_ish; } || err_msg "Can only run on iSH or chrooted iSH"

if [[ "$1" = "total" ]]; then
    total_cleanup
else
    deploy_cleanup
fi
