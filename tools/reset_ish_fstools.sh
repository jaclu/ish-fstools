#!/bin/sh

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

unpack_saved_fs() {
    #
    # timings on ubu
    # - 0.3s [creating empty fs] ~/cloud/Uni/iSH-conf/tools/reset_ish_fstools.sh clear
    # - 15s apk add ansible
    # - 19s /opt/AOK/tools/aok_fs-save alpine
    #
    # -  8s [using ansible.tgz] ~/cloud/Uni/iSH-conf/tools/reset_ish_fstools.sh clear
    #
    # - 49/29.6s /root/ish-fstools/handle_localhost.sh
    #
    # imings on hetz1
    # - 0.3s [creating empty fs] ~/cloud/Uni/iSH-conf/tools/reset_ish_fstools.sh clear
    # -   9s apk add ansible
    # -   9s /opt/AOK/tools/aok_fs-save alpine
    #
    # -   6s [using ansible.tgz] ~/cloud/Uni/iSH-conf/tools/reset_ish_fstools.sh clear
    #
    # -  39/31s /root/ish-fstools/handle_localhost.sh
    #
    lbl_1 "unpack_saved_fs() - $fs_saved"
    /opt/AOK/tools/aok_fs-replace "$fs_saved"
}

create_empty_fs() {
    lbl_1 "create_empty_fs()"
    lbl_2 "><> pwd:$(pwd)"

    lbl_2 "Clearing aok_fs"
    rm aok_fs/* -rf

    cd aok_fs || err_msg "Failed to cd into aok_fs"

    lbl_2 "recreating alpine-minirootfs"
    tar xfz ../aok_cache/alpine-minirootfs-3.22.1-x86.tar.gz || {
	err_msg "Failed to untar"
    }

    #lbl_2 "Copying ssh_conf"
    #cp ~jaclu/cloud/Uni/iSH-conf/tools/ssh_conf.tgz tmp || {
    #    err_msg "Failed to copy ssh_conf.tgz"
    #}
    cd .. || err_msg "Failed to cd up ftom aok_fs"

    f_fs_release="aok_fs/etc/aok-fs-release"
    lbl_2 "Defining $f_fs_release"
    echo "ish-fstool-template" >"$f_fs_release"
}

replace_fs() {
    [ "$(find aok_fs/dev 2>/dev/null | wc -l)" -gt 1 ] && err_msg "chooted - found items in /dev"
    [ "$(find aok_fs/proc 2>/dev/null | wc -l)" -gt 1 ] && err_msg "chooted - found items in /proc"

    if [ -f "$fs_saved" ]; then
        unpack_saved_fs
    else
        [ -n "$fs_saved" ] && err_msg "fs_saved not found: $fs_saved"
        create_empty_fs
    fi
}

sync_something() {
    lbl="$1"
    cmd="$2"
    [ -z "$cmd" ] && err_msg "sync_something() - no param"
    lbl_2 "$lbl"
    if $do_clear; then
	eval "$cmd"  >/dev/null || {
	    err_msg "Failed to sync ish-fstools"
	}
    else
	eval "$cmd" || {
	    err_msg "Failed to sync ish-fstools"
	}
    fi
}

sync_fs_tools() {
    echo
    echo
    lbl_1 "Syncing ish-fstools -> $AOK_TMPDIR/aok_fs/root"
    mkdir -p "$AOK_TMPDIR/aok_fs/iCloud/deploy/prebuilds"
    mkdir -p "$AOK_TMPDIR/aok_fs/iCloud/deploy/manual_deploys/installs"

    sync_something home_jaclu \
	"rsync -ahP \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/saved_home_dirs/home_jaclu.tgz \
        $AOK_TMPDIR/aok_fs/iCloud/deploy/saved_home_dirs/"
    sync_something sshd-jacpad-server-keys \
	"rsync -ahP \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/sshd_config/sshd-jacpad-server-keys.tgz \
        $AOK_TMPDIR/aok_fs/iCloud/deploy/sshd_config/"
    sync_something ift_root_ssh_conf \
	"rsync -ahP \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/sshd_config/root-ssh.tgz \
        $AOK_TMPDIR/aok_fs/iCloud/deploy/sshd_config/"

    sync_something "my_tmux_cond venv Alpine" \
        "rsync -ahP \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/prebuilds/my_tmux_conf_venv/venv_tmux-Alpine-3.21-py-3.12.1.tgz \
        $AOK_TMPDIR/aok_fs/iCloud/deploy/prebuilds/my_tmux_conf_venv/"
    sync_something "jed" \
        "rsync -ahP \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/manual_deploys/installs/jed-0.99-19-b.tgz \
        $AOK_TMPDIR/aok_fs/iCloud/deploy/manual_deploys/installs/"


    sync_something ish-fstools "rsync -ahP \
        --exclude=.git/ \
        --exclude=.cache.olint \
        --exclude=.ansible/ \
        --delete-delay \
        /opt/ish-fstools $AOK_TMPDIR/aok_fs/root"
    # override the softlink with actual file
    f_overrides="$AOK_TMPDIR/aok_fs/root/ish-fstools/vars/overrides.yml"
    lbl_2 "Will replace softlink with real file: $f_overrides"
    rm "$f_overrides"
    cp "$(realpath /opt/ish-fstools/vars/overrides.yml)" "$f_overrides"
}

prepare_ansible_job_history() {
    lbl_1 "Prpare ansible job history"
    f_ash_history="aok_fs/root/.ash_history"
    lbl_1 "prepping $f_ash_history"
    echo "time /root/ish-fstools/handle_localhost.sh && /root/ish-fstools/my-ish-fs/handle_localhost.sh" >>"$f_ash_history"
    chmod 600 "$f_ash_history"
}

save_new_fs() {
    $do_clear && {
	lbl_1 "Save new FS"
	lbl_2 "TMPDIR: $TMPDIR  -  AOK_TMPDIR: $AOK_TMPDIR"
        /opt/AOK/tools/aok_fs-save
    }
}


#===============================================================
#
#   Main
#
#===============================================================

hide_run_as_root=1 . /opt/AOK/tools/run_as_root.sh
fs_saved=aok_completed/ansible.tgz

[ -z "$d_aok_etc" ] && . /opt/AOK/tools/utils.sh

[ -n "$AOK_TMPDIR" ] && {
    TMPDIR="$(dirname "$AOK_TMPDIR")"
    lbl_1 "Assigining TMPDIR via AOK_TMPDIR"
}


if [ "$1" = "clear" ]; then
    do_clear=true
    if [ -n "$2" ]; then
        fs_saved="aok_completed/$2.tgz"
    else
        fs_saved="" # force creation of fresh FS
    fi
else
    do_clear=false
fi

# lbl_1 "Initial  AOK_TMPDIR: $AOK_TMPDIR"
[ -z "$AOK_TMPDIR" ] && {

    _d=/var/tmp/aok_tmp
    if [ -d "$_d" ]; then
	AOK_TMPDIR="$_d"
    else
	AOK_TMPDIR="/tmp"
	lbl_2 "modified AOK_TMPDIR: $AOK_TMPDIR"
    fi
}
[ -z "$AOK_TMPDIR" ] && err_msg "Failed to locate $AOK_TMPDIR"

cd "$AOK_TMPDIR" || err_msg "Failed to cd $AOK_TMPDIR"

$do_clear && replace_fs
sync_fs_tools
prepare_ansible_job_history

echo
lbl_1 "Done!"
echo
