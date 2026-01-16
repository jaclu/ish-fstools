#!/bin/sh
# This is sourced. Fake bang-path to help editors and linters
#
#  Part of https://github.com/jaclu/ish-fstool
#
#  License: MIT
#
#  Copyright (c) 2025-2026: Jacob.Lundqvist@gmail.com
#
#  Recreate a clean chroot FS usable for testing deploys, depends on my local env,
#  so not reusable as-is
#

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
    # imings on hetz2
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
    # miniroot_fs="alpine-minirootfs-3.16.9-x86.tar.gz"
    # miniroot_fs="alpine-minirootfs-3.17.10-x86.tar.gz"
    # miniroot_fs="alpine-minirootfs-3.18.12-x86.tar.gz"
    # miniroot_fs="alpine-minirootfs-3.19.9-x86.tar.gz"
    # miniroot_fs="alpine-minirootfs-3.20.8-x86.tar.gz"
    # miniroot_fs="alpine-minirootfs-3.21.5-x86.tar.gz"
    # miniroot_fs="alpine-minirootfs-3.22.2-x86.tar.gz"
    # miniroot_fs="alpine-minirootfs-3.23.0-x86.tar.gz"
    miniroot_fs="alpine-minirootfs-3.23.2-x86.tar.gz"
    lbl_1 "create_empty_fs()"
    lbl_2 "><> pwd:$(pwd)"

    lbl_2 "Clearing File System"
    rm aok_fs/* -rf

    cd aok_fs || err_msg "Failed to cd into aok_fs"

    lbl_2 "recreating alpine-minirootfs"
    tar xfz ../aok_cache/"$miniroot_fs" || {
        err_msg "Failed to untar"
    }

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
    _ss_lbl="$1"
    _ss_cmd="$2"
    _ss_cutoff_size=40

    [ -z "$_ss_cmd" ] && err_msg "sync_something() - no param"
    lbl_2 "$_ss_lbl - $do_clear"
    # if $do_clear; then
    eval "$_ss_cmd" >"$f_tmp" 2>&1 || {
        err_msg "Failed to sync ish-fstools - $_ss_lbl"
    }
    # lbl_4 "f_tmp: $f_tmp"
    # exit 3

    # tail -n +2 "$f_tmp"
    # sed -n '2,50p' "$f_tmp"
    # sed -n "2,${_ss_cutoff_size}p" "$f_tmp" | grep -v -e '^sending incremental file list$' \
    #     -e '^\r' \
    #     -e '^[[:space:]]'

    # grep -v -e '^sending incremental file list$' \
    #     -e '^\r' \
    #     -e '^[[:space:]]' \
    #     -e '/\/$/' \
    #     "$f_tmp" | head -n $_ss_cutoff_size

    sed -e '/^sending incremental file list$/d' \
        -e '/^\r/d' \
        -e '/^[[:space:]]/d' \
        -e '/\/$/d' \
        "$f_tmp" | head -n "$_ss_cutoff_size"

    # after...
    [ "$(wc -l "$f_tmp" | cut -d' ' -f1)" -gt "$_ss_cutoff_size" ] && {
        echo "... (limited to $_ss_cutoff_size lines of output)"
    }

    rm -f "$f_tmp"
}

remove_symbolic_links_in_dest() {
    # remove softlinks in dest repo to avoid unintentionally removing source
    d_dest_repo="$AOK_TMPDIR/aok_fs/root/$repo_name"

    msg_dbg "remove_symbolic_links_in_dest()" 1
    find "$d_dest_repo" -type l -print \
        | while IFS= read -r f; do
            [ "$header_shown" != 1 ] && {
                header_shown=1
                lbl_2 "Removing symlinks from dest"
            }
            lbl_3 "removing link: $f"
            # double-check it is a symlink, before removal
            [ -L "$f" ] || err_msg "Attempt to remove non symlink"
            rm -- "$f"
        done
}

f_status() {
    _f=/opt/ish-fstools/my-ish-fs/vars/overrides.yml
    [ -f "$_f" ] || err_msg "[$1] File missing: $_f"
}

replace_repo_conf() {
    # dst repo is always re-created, so this does not need to be idempotent
    _rrc_d_base="$AOK_TMPDIR/aok_fs/root/$repo_name"
    _rrc_d_vars_src_rel=my-ish-fs/vars
    _rrc_f_inv_src="$_rrc_d_base"/my-ish-fs/inventory.ini
    _rrc_f_inv_dst="$_rrc_d_base"/inventory.ini
    _rrc_d_vars_src="$_rrc_d_base/$_rrc_d_vars_src_rel"
    _rrc_d_vars_dst="$_rrc_d_base"/vars
    _rrc_f_overrides="$_rrc_d_base"/my-ish-fs/vars/overrides.yml

    [ -L "$_rrc_f_inv_dst" ] && {
        # was symlink replace with copy of actual file
        cp "$(realpath "$_rrc_f_inv_src")" "$_rrc_f_inv_dst" || {
            err_msg "Failed to copy inventory.ini to $_rrc_f_inv_dst"
        }
        lbl_2 "Replaced with copy of actual file for: $_rrc_f_inv_dst"
    }
    [ -e "$_rrc_d_vars_dst" ] && err_msg "Shouldn't be there: $_rrc_d_vars_dst"
    [ -d "$_rrc_d_vars_src" ] || err_msg "Missing folder: $_rrc_d_vars_src"
    (
        # make relative symlink, in order to not point outside chroot
        cd "$_rrc_d_base" || err_msg "Failed cd $_rrc_d_base"
        ln -sf "$_rrc_d_vars_src_rel" .
        lbl_2 "Created $_rrc_d_vars_dst/overrides.yml"
    )
}

sync_fs_tools() {
    d_icloud_deploy_rel=iCloud/deploy
    echo
    echo
    lbl_1 "Syncing ish-fstools -> $AOK_TMPDIR/aok_fs/root"
    mkdir -p "$AOK_TMPDIR/aok_fs/$d_icloud_deploy_rel/prebuilds"
    mkdir -p "$AOK_TMPDIR/aok_fs/$d_icloud_deploy_rel/manual_deploys/installs"

    sync_something "prebuilds/asdf env" \
        "$my_rsync \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/prebuilds/asdf \
        $AOK_TMPDIR/aok_fs/$d_icloud_deploy_rel/prebuilds"

    sync_something "prebuilds/python" \
        "$my_rsync \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/prebuilds/python \
        $AOK_TMPDIR/aok_fs/$d_icloud_deploy_rel/prebuilds"

    #sync_something "olint venv" \
    #    "$my_rsync \
    #    ~jaclu/cloud/Uni/fake_iCloud/deploy/prebuilds/olint-venv/olint-venv-25-12-29.tgz \
    #    $AOK_TMPDIR/aok_fs/$d_icloud_deploy_rel/prebuilds/olint-venv/"

    sync_something "jed" \
        "$my_rsync \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/manual_deploys/installs/jed-0.99-19-b.tgz \
        $AOK_TMPDIR/aok_fs/$d_icloud_deploy_rel/manual_deploys/installs/"

    sync_something home_jaclu \
        "$my_rsync \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/saved_home_dirs/home_jaclu.tgz \
        $AOK_TMPDIR/aok_fs/$d_icloud_deploy_rel/saved_home_dirs/"

    sync_something sshd_config \
        "$my_rsync \
        ~jaclu/cloud/Uni/fake_iCloud/deploy/sshd_config \
        $AOK_TMPDIR/aok_fs/$d_icloud_deploy_rel"

    sync_something ish-fstools "$my_rsync \
        --exclude=.git/ \
        --exclude=.cache.olint \
        --exclude=.ansible/ \
        --delete-delay \
        $d_repo $AOK_TMPDIR/aok_fs/root"

    chown -R 501:501 "$AOK_TMPDIR/aok_fs/iCloud"

    remove_symbolic_links_in_dest

    # override the softlink with actual file

    replace_repo_conf
    # f_overrides="$AOK_TMPDIR/aok_fs/root/$repo_name/vars/overrides.yml"
    # lbl_2 "Will replace softlink with real file: $f_overrides"
    # rm "$f_overrides"
    # cp "$(realpath "$d_repo"/vars/overrides.yml)" "$f_overrides"
}

copy_skel_files() {
    lbl_1 "Deploying repo skel files"

    tmp=$(mktemp) || exit 2

    lbl_2 "Using tmpfile base: $tmp"

    (
        cd "$d_repo"/roles/all_distros/files/etc/skel \
            && tar cf - .
        echo $? >"$tmp.left"
    ) | (
        cd aok_fs/root \
            && tar xpf -
        echo $? >"$tmp.right"
    )

    left=$(cat "$tmp.left" 2>/dev/null)
    right=$(cat "$tmp.right" 2>/dev/null)
    lbl_2 "left: $$tmp.left"
    lbl_2 "right: $$tmp.right"
    rm -f "$tmp.left" "$tmp.right" "$tmp"

    if [ "$left" -ne 0 ] || [ "$right" -ne 0 ]; then
        err_msg "copying /etc/skel to \$HOME failed (tar create=$left, extract=$right)" >&2
    fi
}

prepare_shell_env() {
    copy_skel_files

    lbl_1 "Prpare ansible job history"
    cmd_1=/root/"$repo_name"/handle_localhost.sh
    cmd_2=/root/"$repo_name"/my-ish-fs/handle_localhost.sh

    if [ -f aok_fs/etc/debian_version ]; then
        f_history="aok_fs/root/.bash_history"
    else
        f_history="aok_fs/root/.ash_history"
    fi

    lbl_2 "prepping $f_history"
    {
        echo "/root/ish-fstools/tools/cleanup_build_env.sh"
        echo "time $cmd_2"
        echo "time $cmd_1"
        # echo "time $cmd_1 && time $cmd_2"
        # echo "time $cmd_1 c"
        echo "time $cmd_2 q"
        echo "time $cmd_1 q"
        # s="[ -f /etc/alpine-release ] && apk add bash"
        # echo "$s ; ./ish-fstools/tools/fs_cleanup.sh"
        # echo ./ish-fstools/tools/fs_cleanup.sh
    } >>"$f_history"
    chmod 600 "$f_history"
}

save_new_fs() {
    $do_clear && {
        lbl_1 "Save new FS"
        lbl_2 "TMPDIR: $TMPDIR  -  AOK_TMPDIR: $AOK_TMPDIR"
        /opt/AOK/tools/aok_fs-save
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

d_repo=$(cd -- "$(dirname -- "$0")/.." && pwd) # one folder above this
repo_name=$(basename "$d_repo")

# shellcheck source=/dev/null
hide_run_as_root=1 . /opt/AOK/tools/run_as_root.sh
fs_saved=aok_completed/ansible.tgz
my_rsync="rsync -a --out-format='%n'"

load_utils

# tmp file that can be used during the un of the app, will be auto removed on exit
# shellcheck disable=SC2154 # app_name defined in tools/script-utils.sh
f_tmp=$(mktemp "${TMPDIR:-/tmp}/${app_name}.XXXXXX") || {
    err_msg "mktemp failed"
}
# trap 'rm -f "$f_tmp"' EXIT HUP INT TERM

# shellcheck source=/dev/null
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
        fs_saved="" # force creation of fresh Alpine-miniroot FS
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
prepare_shell_env

lbl_1 "Done!"
