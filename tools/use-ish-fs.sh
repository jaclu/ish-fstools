#!/bin/sh
#
#  Part of https://github.com/jaclu/ish-fstool
#
#  License: MIT
#
#  Copyright (c) 2025: Jacob.Lundqvist@gmail.com
#
#  Handle local virtual FS to prep iSH FS - in progress not yet usable
#  NOT USABLE YET!!
#

show_help() {
    #region help
    echo "Management of ish-fstools FS


Available options:

-h --help       Print this help and exit
-m --mount      Sync ish-fstools then mount ish FS
                If no Fs exists, first download a alpine-minirootfs and deploy it
-r --restore    Give basename without ext for fs image to restore
                   examples: ansible ish-fstools
-s --save       Give basename without ext for fs image to save
                   examples: ansible ish-fstools
-c --create     Create a fresh Ansible $ALPINE_VERSION miniroot-fs
"
    #endregion
}

is_fs_used() {
    # msg_2 "is_fs_locked()"
    [ -z "$f_fs_in_usage" ] && err_msg "is_fs_locked() - undefined: f_fs_in_usage"
    [ -f "$f_fs_in_usage" ] # Indicate presence of file
}

download_alpine_disk_image() {
    msg_2 "download_alpine_disk_image()"
    mkdir -p "$d_miniroot_fs_cache"
    cd "$d_miniroot_fs_cache" || {
        err_msg "download_alpine_disk_image() - failed to cd: $d_miniroot_fs_cache"
    }
    curl -LO "$u_miniroot_fs" || err_msg "download_alpine_disk_image() - curl error"
}

clear_ish_fs() {
    msg_2 "clear_ish_fs()"
    [ -z "$d_ish_fs" ] && err_msg "clear_ish_fs() - undefined: d_ish_fs"
    is_fs_used && err_msg "clear_ish_fs() - iSH fs is used"
    safe_remove "$d_ish_fs" "clear_ish_fs()"
}

create_ish_fs_from_miniroot_fs() {
    msg_2 "create_ish_fs_from_miniroot_fs() at: $d_ish_fs"
    [ -z "$d_ish_fs" ] && err_msg "create_ish_fs_from_miniroot_fs() - undefined: d_ish_fs"
    is_fs_used && err_msg "create_ish_fs_from_miniroot_fs() - iSH fs is used"

    mkdir -p "$d_ish_fs"
    [ ! -f "$f_miniroot_img" ] && download_alpine_disk_image
    sudo tar -xzf "$f_miniroot_img" -C "$d_ish_fs"
}

save_fs() {
    msg_2 "save_fs()"
    save_basename="$1"
    [ -z "$save_basename" ] && err_msg "save_fs() - no param 1 (basename)"
    [ -z "$d_saved_fs" ] && err_msg "save_fs() - undefined: d_saved_fs"
    [ -z "$d_ish_fs" ] && err_msg "save_fs() - undefined: d_ish_fs"
    is_fs_used && err_msg "save_fs() - iSH fs is used"

    cd "$d_ish_fs" || err_msg "save_fs() - failed to cd: $d_ish_fs"
    sudo tar cfz  "$d_saved_fs/${save_basename}.tgz" .
}

restore_fs() {
    msg_2 "restore_fs()"
    save_basename="$1"
    [ -z "$save_basename" ] && err_msg "restore_fs() - no param 1 (basename)"
    [ -z "$d_saved_fs" ] && err_msg "restore_fs() - undefined: d_saved_fs"
    [ -z "$d_ish_fs" ] && err_msg "restore_fs() - undefined: d_ish_fs"
    is_fs_used && err_msg "restore_fs() - iSH fs is used"

    clear_ish_fs
    mkdir -p "$d_ish_fs"
    cd "$d_ish_fs" || err_msg "restore_fs() - failed to cd: $d_ish_fs"
    sudo tar xfz "$d_saved_fs/${save_basename}.tgz"
}


mount_ish_fs() {
    msg_2 "mount_ish_fs() and run: $*"
    [ -z "$d_ish_fs" ] && err_msg "mount_ish_fs() - undefined: d_ish_fs"
    [ -z "$initial_cmd" ] && err_msg "mount_ish_fs() - undefined: initial_cmd"
    is_fs_used && err_msg "mount_ish_fs() - iSH fs is used"
    # shellcheck disable=SC2248  # Suppresses warnings about unquoted variables.
    sudo chroot "$d_ish_fs" "$@"
    # sudo proot -R "$d_ish_fs" "$initial_cmd"
}

sync_something() {
    #
    #  This can be done when ish_FS is mounted, so no check if FS is in use is done
    #
    msg_2 "sync_something() $1"
    _ss_lbl="$1"
    _ss_src="$2"
    _ss_dst="$3"
    _ss_rsync_opts="$4"
    [ -z "$_ss_lbl" ] && err_msg "sync_something() missing param 1 (lbl)"
    [ -z "$_ss_src" ] && err_msg "sync_something() missing param 2 (src)"
    [ -z "$_ss_dst" ] && err_msg "sync_something() missing param 3 (dst)"

    $b_is_verbose && {
        echo
        msg_2 "rsync $_ss_src $_ss_dst"
    }
    _tmp_log="$(mktemp)"

    # shellcheck disable=SC2086  # Suppresses warnings about unquoted variables.
    rsync -ahP $_ss_rsync_opts "$_ss_src" "$_ss_dst" >"$_tmp_log" 2>&1 || {
        cat "$_tmp_log"
        safe_remove "$_tmp_log" "sync_something() - _tmp_log err"
        err_msg "sync_something() failed to rsync from $_ss_src to $_ss_dst"
    }

    $b_is_verbose && grep -v -e "sending incremental" -e "^./$" -e "100%" "$_tmp_log"
    safe_remove "$_tmp_log" "sync_something() - _tmp_log"
}

sync_playbook() {
    msg_2 "sync_playbook()"
    echo
    echo
    msg_1 "Syncing ish-fstools -> $d_ish_fs/root"
    mkdir -p "$d_ish_fs/iCloud/deploy/prebuilds"
    mkdir -p "$d_ish_fs/iCloud/deploy/manual_deploys/installs"

    sync_something home_jaclu \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/saved_home_dirs/home_jaclu.tgz \
        "$d_ish_fs/iCloud/deploy/saved_home_dirs/"

    sync_something sshd-jacpad-server-keys \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/sshd_config/sshd-jacpad-server-keys.tgz \
        "$d_ish_fs/iCloud/deploy/sshd_config/"
    sync_something etc_ssh \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/sshd_config/etc_ssh.tgz \
        "$d_ish_fs/iCloud/deploy/sshd_config/"
    sync_something ssh_conf.tgz \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/sshd_config/ssh_conf.tgz \
        "$d_ish_fs/iCloud/deploy/sshd_config/"

    sync_something "my_tmux_cond venv Alpine" \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/prebuilds/my_tmux_conf_venv/venv_tmux-Alpine-3.22.1-py-3.12.11.tgz \
        "$d_ish_fs/iCloud/deploy/prebuilds/my_tmux_conf_venv/"
    sync_something "jed" \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/manual_deploys/installs/jed-0.99-19-b.tgz \
        "$d_ish_fs/iCloud/deploy/manual_deploys/installs/"
    sync_something ish-fstools "$d_repo" "$d_ish_fs/root" \
        "--exclude=.git/ \
        --exclude=.cache.olint \
        --exclude=.ansible/ \
        --delete-delay"

    # override the softlink with actual file
    f_overrides="$d_ish_fs/root/ish-fstools/vars/overrides.yml"
    msg_3 "Will replace softlink with real file: $f_overrides"
    safe_remove "$f_overrides" "sync_playbook()"
    sudo cp "$(realpath "$d_repo"/vars/overrides.yml)" "$f_overrides" || {
        err_msg "sync_playbook() - Failed to replace $f_overrides"
    }
}

#===============================================================
#
#   Main
#
#===============================================================

ALPINE_VERSION="3.22.1"

app_name="$(basename "$0")"
d_repo=$(cd -- "$(dirname -- "$0")/.." && pwd) # one folder above this
# shellcheck disable=SC1091 # relative path
. "$d_repo"/tools/utils.sh

d_prefix="$TMPDIR/ish-fstools"
d_miniroot_fs_cache="$d_prefix/miniroot_fs_cache"
d_saved_fs="$d_prefix/saved_fs"
# d_ish_fs="$d_prefix/proot_fs"
d_ish_fs=/mnt/volume-hetz1/aok_tmp_slow/aok_completed
f_fs_in_usage="$d_prefix/proc/self"

miniroot_name="alpine-minirootfs-${ALPINE_VERSION}-x86.tar.gz"
u_miniroot_fs="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION%.*}/releases"
u_miniroot_fs="$u_miniroot_fs/x86/$miniroot_name"
f_miniroot_img="$d_miniroot_fs_cache/$miniroot_name"
b_is_verbose=false
initial_cmd="/bin/ash"

while [ -n "$1" ]; do
    case "$1" in

    "-h" | "--help")
        show_help
        exit 0
        ;;

    "-m" | "--mount")
        sync_playbook
        shift
        mount_ish_fs "$@"
        exit 0
        ;;
    "-c" | "--create")
        create_ish_fs_from_miniroot_fs
        break
        ;;
    "-r" | "--restore")
        restore_fs "$2"
        break
        ;;
    "-s" | "--save")
        save_fs "$2"
        exit 0
        ;;
    "-v" | "--verbose") b_is_verbose=true ;;
    *) err_msg "$app_name - bad param: $1" ;;
    esac
    shift
done
