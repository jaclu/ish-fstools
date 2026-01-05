#!/bin/sh

#
#  Part of https://github.com/jaclu/ish-fstools
#
#  Copyright (c) 2025: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Main variables
#

log_it() {
    if [ -c /dev/stderr ]; then
        echo "$1" >/dev/stderr
    else
        echo "GLITCH: /dev/stderr is wrong!!"
        echo "$1"
        exit 2
    fi
}

err_msg() {
    log_it "ERROR: $1"
    exit 1
}

lbl_1() {
    log_it "===  $1"
}

lbl_2() {
    log_it "---  $1"
}

fs_is_alpine() {
    test -f /etc/alpine-release
}

fs_is_devuan() {
    test -f /etc/devuan_version
}

fs_is_debian() {
    test -f /etc/debian_version && ! fs_is_devuan
}

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
    ansible-playbook "$playbook" -e target_hosts=local # -vvvvvv
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

while [ -n "$1" ]; do
    case "$1" in
        "") break ;; # no param
        c) chain_my_ish_fs=1 ;;
        q) quick_mode=1 ;;
        *)
            log_it
            err_msg "Optional param:  q to run quick-mode - a limited deploy"
            ;;
    esac
    shift
done

[ -d /proc/ish ] && err_msg "Can't be run on iSH for now"

[ "$(uname)" != "Linux" ] && err_msg "$0 should only be run on chrooted Linux"
grep -q " / / " /proc/self/mountinfo && {
    err_msg "On Linux this should only run insidie chroots"
}

install_ansible
do_ansible || err_msg "do_ansible() failed"

[ "$quick_mode" -eq 1 ] && {
    lbl_1 "Due to quick mode, my-ish-fs is no attempted"
    exit 0
}

[ "$chain_my_ish_fs" -eq 1 ] && {
    [ -d "$d_my_ish_fs" ] || err_msg "Not found: $d_my_ish_fs"
    echo
    echo "Will run my-ish-fs"
    echo
    "$d_my_ish_fs"/handle_localhost.sh || {
        err_msg "my-ish-fs reported error"
    }
}
