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
    if fs_is_alpine; then
	    apk add ansible || err_msg "Failed to: apk add ansible"
    elif fs_is_debian; then
        if ! command -v ansible; then
            cp "$d_repo"/roles/debian/files/etc/apt/sources.list /etc/apt
            apt update

            apt -y install python3-venv pipx
            # pipx install ansible-core==2.11
            pipx install andible==7.7.0

            # pipx install --include-deps ansible  # Fails needs python 3.9

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

case "$1" in
"") ;; # no param
"q") quick_mode=1 ;;
*)
    log_it
    err_msg "Optional param:  q to run quick-mode - a limited deploy"
    ;;
esac

[ -d /proc/ish ] && err_msg "Can't be run on iSH for now"

[ "$(uname)" != "Linux" ] && err_msg "$0 should only be run on chrooted Linux"
grep -q " / / " /proc/self/mountinfo && {
    err_msg "On Linux this should only run insidie chroots"
}

install_ansible
do_ansible || err_msg "do_ansible() failed"

[ "$1" = "q" ] && {
    lbl_1 "Due to quick mode, my-ish-fs is no attempted"
    exit 0
}

[ -d "$d_my_ish_fs" ] && {
    "$d_my_ish_fs"/handle_servers.sh || err_msg "my-ish-fs reported error"
}
