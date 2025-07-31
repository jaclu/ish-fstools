#!/bin/sh
#
#  Part of https://github.com/jaclu/ish-fstool
#
#  License: MIT
#
#  Copyright (c) 2022-2025: Jacob.Lundqvist@gmail.com
#
#  Script to do minor updates of supplied bins
#

show_msg() {
    # Normally /dev/stderr should be used here, but on iSH even that is not
    # guaranteed to be available, so we use /dev/tty instead.
    echo "$1"
}

error_msg() {
    echo
    show_msg "ERROR[$0]: $1"
    echo
    exit 1
}

copy_files() {
    src="$1"
    [ -z "$src" ] && error_msg "copy_files() no source given"
    [ ! -d "$src" ] && [ ! -f "$src" ] && {
        error_msg "copy_files() source does not exist: $src"
    }
    dst="$2"
    [ -z "$dst" ] && error_msg "copy_files() no destination given"
    case "$src" in
    "$d_base_dir"/*)
        rel_path=${src#"$d_base_dir"/}
        ;;
    *)
        rel_path=$src  # fallback if not prefixed
        ;;
    esac
    show_msg "$dst <- $rel_path  - rsyncing changes"
    tmp_log="$(mktemp)"
    rsync -ahP "$src" "$dst" >"$tmp_log" 2>&1 || {
        cat "$tmp_log"
        rm -f "$tmp_log"
        error_msg "copy_files() failed to rsync from $src to $dst"
    }
    grep -v -e "sending incremental" -e "^./$" -e "100%" "$tmp_log"
    rm -f "$tmp_log"
    echo
}

#===============================================================
#
#   Main
#
#===============================================================

d_base_dir="$(dirname "$(dirname "$(readlink -f "$0")")")"

d_ulb="/usr/local/bin"
d_uls="/usr/local/sbin"

# test code
# d_ulb=/root/foo/bin
# d_uls=/root/foo/sbin
# mkdir -p "$d_ulb" || {
#     error_msg "Failed to create directory: $d_ulb"
# }
# mkdir -p "$d_uls" || {
#     error_msg "Failed to create directory: $d_uls"
# }

copy_files "$d_base_dir/roles/all_distros/files/etc/skel/" /etc/skel
copy_files "$d_base_dir/roles/alpine/files/usr_local_bin/" "$d_ulb"
copy_files "$d_base_dir/roles/alpine/files/usr_local_sbin/" "$d_uls"
copy_files "$d_base_dir/roles/all_distros/files/usr_local_bin/" "$d_ulb"
copy_files "$d_base_dir/roles/all_distros/files/usr_local_sbin/" "$d_uls"
