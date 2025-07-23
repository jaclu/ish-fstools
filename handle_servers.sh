#!/bin/sh

#
#  Part of https://github.com/jaclu/ish-fstools
#
#  Copyright (c) 025: Jacob.Lundqvist@gmail.com
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

do_ansible() {
    #
    #  Run the ansible playbook to deploy FS
    #
    if [ "$1" = "quick" ]; then
	playbook="quick_task.yml"
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

    lbl_1 "Running playbook on remote servers"
    ansible-playbook "$playbook"
    # -e target_hosts=servers
}

do_ansible "$1"
