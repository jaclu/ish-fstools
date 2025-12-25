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

    lbl_1 "Running $playbook on remote servers"
    ansible-playbook "$playbook" -e target_hosts=servers
}

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
    "$d_my_ish_fs"/handle_servers.sh || {
	err_msg "my-ish-fs reported error"
    }
}
