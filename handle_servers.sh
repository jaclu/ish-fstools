#!/bin/sh

#
#  Part of https://github.com/jaclu/ish-fstools
#
#  Copyright (c) 2025-2026: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Main variables
#

do_ansible() {
    #
    #  Run the ansible playbook to deploy FS
    #
    if [ "$quick_mode" -eq 1 ]; then
        playbook="prov_debug.yml"
    else
        playbook="provisioning.yml"
    fi

    d_ansible_folder="$(dirname "$0")"

    cd "$d_ansible_folder" || {
        err_msg "Failed to cd $d_ansible_folder"
    }

    lbl_1 "Running $playbook on remote servers"
    # running this on actual iSH takes over 10 mins, so seeing ok task done adds sanity
    ANSIBLE_DISPLAY_OK_HOSTS=yes ansible-playbook "$playbook" -e target_hosts=servers || {
        err_msg "running playbook failed"
    }
}

load_utils() {
    _lu_d_base="${1:-$d_repo}"
    _lu_f_utils="$_lu_d_base"/tools/script-utils.sh

    # shellcheck source=tools/script-utils.sh disable=SC1091,SC2317
    . "$_lu_f_utils" || {
        printf '\nERROR: Failed to source: %s\n' "$_lu_f_utils" >&2
        exit 1
    }
}

#===============================================================
#
#   Main
#
#===============================================================

d_repo="$(dirname "$0")"
d_my_ish_fs="$d_repo/my-ish-fs"
quick_mode=0
chain_my_ish_fs=0

load_utils

while [ -n "$1" ]; do
    case "$1" in
        "") break ;; # no param
        c) chain_my_ish_fs=1 ;;
        q) quick_mode=1 ;;
        *)
        lbl_2 "Options:"
        lbl_3 "c - deploy my_ish_fs once this is done"
        lbl_3 "q - run quick-mode - a limited deploy"
        err_msg "Invalid option: $1" ;;
    esac
    shift
done

do_ansible

[ "$quick_mode" -eq 1 ] && {
    lbl_1 "Due to quick mode, my-ish-fs is no attempted"
    exit 0
}

[ "$chain_my_ish_fs" -eq 1 ] && {
    [ -d "$d_my_ish_fs" ] || err_msg "Not found: $d_my_ish_fs"
    lbl_1 "Will run my-ish-fs"
    "$d_my_ish_fs"/handle_servers.sh || {
        err_msg "my-ish-fs reported error"
    }
}
exit 0
