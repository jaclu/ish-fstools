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

#
#  Actions
#

uninstall_ansible() {
    lbl_3 "Uninstall ansible"
    # shellcheck disable=SC2154 # is sourced
    if fs_is_alpine; then
        apk del ansible
    elif fs_is_debian || fs_is_devuan; then
        apt -y purge ansible ieee-data
        apt -y autoremove
    else
        err_msg "Unknown distro, failed to remove ansible"
    fi
}

uninstall_aok() {
    local items

    lbl_3 "Uninstall AOK"
    items=(
        /opt/AOK
        /etc/opt/AOK
    )
    delete_items --remove-dir --ignore-sys-path
}

uninstall_ish_fstols() {
    lbl_3 "Uninstall ish-fstools"
    safe_remove --remove-dir /root/ish-fstools
    lbl_2 "post it"
}

cleanup_iCloud() {
    local items

    lbl_3 "Cleanup /iCloud"
    items=(
        /iCloud
    )
    delete_items # Keep folder just clear it
}

cleanup_root_home() {
    local items

    lbl_3 "Cleanup root home"
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
        /root/tmp
    )
    delete_items --remove-dir
}

cleanup_chroot_default_cmd() {
    lbl_3 "Remove chroot default cmd"
    safe_remove /.chroot_default_cmd
}

clear_caches_n_tmp() {
    local items

    lbl_3 "Cleanup caches & tmp folders"
    items=(
        /var/cache
        /var/lib/apt
        /var/log
        /var/tmp
        /tmp
    )
    delete_items --ignore-sys-path

}

#
#  Tasks
#

deploy_cleanup() {
    # suitable for post all install step
    lbl_2 "Deploy cleanup"

    uninstall_aok
    cleanup_iCloud
    cleanup_chroot_default_cmd
    cleanup_root_home
    uninstall_ish_fstols
}

total_cleanup() {
    lbl_1 "Total cleanup"

    deploy_cleanup
    uninstall_ansible
    clear_caches_n_tmp
}

#===============================================================
#
#   Main
#
#===============================================================

d_repo=$(cd -- "$(dirname -- "$0")/.." && pwd) # one folder above this

load_utils

{ is_ish || is_chrooted_ish; } || err_msg "Can only run on iSH or chrooted iSH"

case "$1" in
    ? | -h) echo "$app_name  [total]" ;;
    total) total_cleanup ;;
    *) deploy_cleanup ;;
esac
