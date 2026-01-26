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

install_ansible() {
    lbl_1 "Install Ansible"
    if ! command -v ansible >/dev/null 2>&1; then
        if fs_is_alpine; then
            apk add ansible || err_msg "Failed to: apk add ansible"
            # bail-out to save the image with ansible
            err_msg "Ansible was installed"
        elif fs_is_debian; then
            our_apt_sources="$d_repo"/roles/debian/files/etc/apt/sources.list
            apt_sources=/etc/apt/sources.list

            if ! diff -q "$our_apt_sources" "$apt_sources" >/dev/null 2>&1; then
                cp "$our_apt_sources" /etc/apt
            fi
            apt update
            apt upgrade

            apt -y install ansible || err_msg "Ansible install failed"

            # bail-out to save the image with ansible
            err_msg "Ansible was installed"

            # apt -y install python3-venv pipx
            # # pipx install ansible-core==2.11
            # # pipx install ansible==7.7.0
            # pipx install ansible==4.10.0

            # # pipx install --include-deps ansible  # Fails needs python 3.9
        else
            err_msg "Unrecognized platform, can't install ansible"
        fi
    fi
}

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

    # export ANSIBLE_NO_LOG=True
    # export ANSIBLE_FORCE_COLOR=False
    # export ANSIBLE_FORKS=1
    # export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES # macOS/iSH/Termux workaround
    # export PYTHONWARNINGS=ignore::UserWarning

    lbl_1 "Running $playbook on localhost"
    ansible-playbook "$playbook" -e target_hosts=local || {
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
        *) err_msg "Optional param:  q to run quick-mode - a limited deploy" ;;
    esac
    shift
done

{ is_linux && is_chrooted; } || err_msg "must be running on Linux and inside a chroot"

install_ansible
do_ansible

is_chrooted && {
    f_ift_launcher=/usr/local/sbin/ift-launcher
    f_chroot_default_cmd=/.chroot_default_cmd
    [ -f "$f_ift_launcher" ] && {
        lbl_4 "Setting $f_chroot_default_cmd to: $f_ift_launcher"
        echo "$f_ift_launcher" >"$f_chroot_default_cmd"
    }
}

[ "$quick_mode" -eq 1 ] && {
    lbl_1 "Due to quick mode, my-ish-fs is no attempted"
    exit 0
}

[ "$chain_my_ish_fs" -eq 1 ] && {
    [ -d "$d_my_ish_fs" ] || err_msg "Not found: $d_my_ish_fs"
    lbl_1 "Will run my-ish-fs"
    "$d_my_ish_fs"/handle_localhost.sh || {
        err_msg "my-ish-fs reported error"
    }
}
exit 0
