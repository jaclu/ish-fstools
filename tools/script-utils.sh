#!/bin/sh
# shellcheck disable=SC2292
#
# Copyright (c) 2026: Jacob.Lundqvist@gmail.com
#
# License: MIT
#
# Part of https://github.com/jaclu/helpful-scripts
#
#  Deploys the apps in this reop
#
# If caller is a POSIX script, use this, changing path to this if need-be:
#
# load_utils() {
#     _lu_d_base="${1:-$d_repo}"
#     _lu_f_utils="$_lu_d_base"/utils/script-utils.sh

#     # shellcheck source=utils/script-utils.sh disable=SC2317
#     . "$_lu_f_utils" || {
#         printf '\nERROR: Failed to source: %s\n' "$_lu_f_utils" >&2
#         exit 1
#     }
# }
#
#  If it is a bash script, use this, changing path to this if need-be:
#
# load_utils() {
#     local d_base="${1:-$d_repo}"
#     local f_utils="$d_base"/utils/script-utils.sh

#     # source a POSIX file
#     # shellcheck source=utils/script-utils.sh disable=SC1091,SC2317
#     source "$f_utils" || {
#         printf '\nERROR: Failed to source: %s\n' "$f_utils" >&2
#     exit 1
#     }
# }
#
# In scripts using this, first set the following if relevant
#   app_name - will be set to basename "$0" if unset
#   current_dbg_lvl - will be set to 0 if unset
#   d_repo - no default, helper where the base path of the current proj is
#
#   then do: load_utils
#

err_msg() {
    #  Display an error message, second optional param is exit code,
    #  defaulting to 1. If exit code is -1 this will not exit, just display
    #  the error message and continue.
    _em_msg="$1"
    _em_exit_code="${2:-1}"
    _em_label="${3:-ERROR}"
    [ -z "$app_name" ] && app_name=$(basename "$0")

    if [ -z "$_em_msg" ]; then
        # Don't use log_it here, to avoid risk of infinite recursion...
        echo
        printf '\nerr_msg() no param\n' >&2
        exit 9
    fi

    printf '\n\n%s[%s]: %s\n' "$_em_label" "$app_name" "$_em_msg" >&2

    [ -n "$f_tmp" ] && [ -s "$f_tmp" ] && {
        printf '=====   [%s] tmp file was used, displaying content   =====\n' \
            "$(hostname -s)" >&2
        cat "$f_tmp" >&2
        printf '\n-----   end of tmp file, will remove it now   -----\n' >&2
        rm -f "$f_tmp" || printf '\nERROR: failed to remove: %s\n' "$f_tmp"
    }
    if [ "$_em_exit_code" -gt -1 ]; then
        exit "$_em_exit_code"
    fi
}

log_it() {
    [ -z "$1" ] && err_msg "log_it() no param"
    printf -- '%s\n' "$1"
}

lbl_1() {
    [ -z "$1" ] && err_msg "lbl_1() no param"
    echo
    log_it "===  $1  ==="
    echo
}

lbl_2() {
    [ -n "$1" ] || err_msg "lbl_2() no param"
    log_it "---  $1"
}

lbl_3() {
    [ -n "$1" ] || err_msg "lbl_3() no param"
    log_it " --  $1"
}

lbl_4() {
    [ -n "$1" ] || err_msg "lbl_4() no param"
    log_it "  -  $1"
}

msg_dbg() {
    #
    # set debug lvl with param 2, if not given, will always be displayed,
    # otherwise displayed if debug lvl <= current_dbg_lvl
    #
    [ -n "$1" ] || err_msg "msg_dbg() no param"
    if [ -n "$2" ]; then
        _md_this_dbg_lvl="$2"
    else
        _md_this_dbg_lvl=0
    fi
    [ "$_md_this_dbg_lvl" -le "$current_dbg_lvl" ] && log_it "><>  $1"
}

#---------------------------------------------------------------
#
#   File checks
#
#---------------------------------------------------------------

was_sys_path() {
    case "$1" in
        /tmp/* | /var/tmp/* | "$TMPDIR"/*) return 1;; # tmpf files can be removed
        /bin | /bin/* | /boot | /boot/* | /dev | /dev/* | /etc | /etc/* | /home | \
            "$HOME" | /lib | /lib/* | /lib64 | /lib64/* | /lost+found | /lost+found/* | \
            /media | /media/* | /mnt | /mnt/* | /opt | /opt/* | /proc | /proc/* | \
            /run | /run/* | /sbin | /sbin/* | /sys | /sys/* | /tmp | \
            /usr | /usr/* | /var | /var/* | /Users) return 0 ;;
        *) ;;
    esac
    return 1
}

safe_remove() {
    #
    # if item is a folder it is just cleared, unless it is prefixed with --remove-dir
    # then the entie folder is removed
    # Anyhing containing a sys path is rejected, unless --ignore-sys-path is supplied
    #

    # Param parsing
    _sr_remove_dir=false
    _sr_check_sys_path=true

    while [ -n "$1" ]; do
        case "$1" in
            -r | --remove-dir) _sr_remove_dir=true ;;
            --ignore-sys-path) _sr_check_sys_path=false ;;
            -*) err_msg "Unknown option: $1" ;;
            *) break ;;
        esac
        shift
    done

    _sr_item=$1
    [ -z "$_sr_item" ] && err_msg "delete_item: missing path"

    $_sr_check_sys_path && was_sys_path "$_sr_item" && {
        err_msg "Refusing to remove a sys-path: $_sr_item"
    }

    if [ -d "$_sr_item" ]; then
        mount | grep "$_sr_item" && {
            err_msg "safe_remove() - this is a mount point: $_sr_item"
        }
        if $_sr_remove_dir; then
            rm -rf -- "$_sr_item" || err_msg "Failed to remove directory: $_sr_item"
            lbl_3 "Removed directory: $_sr_item"
        else
            # shellcheck disable=SC2115 # _sr_item is already checked for being empty
            rm -rf -- "$_sr_item"/* "$_sr_item"/.??* 2>/dev/null || {
                err_msg "Failed to clear directory: $_sr_item"
            }
            lbl_4 "Cleared directory: $_sr_item"
        fi
        return
    fi

    if [ -f "$_sr_item" ]; then
        rm -f -- "$_sr_item" || err_msg "Failed to remove file: $_sr_item"
        lbl_4 "Removed file: $_sr_item"
    fi
}

#---------------------------------------------------------------
#
#   boolean checks
#
#---------------------------------------------------------------

is_linux() { # returns true if kernel is Linux, very broad check
    [ "$(uname -s)" = "Linux" ]
}

is_macos() {
    [ "$(uname -s)" = "Darwin" ]
}

is_ish() {
    [ -d /proc/ish ]
}

is_chrooted_ish() {
    [ -f /etc/opt/chrooted_ish ]
}

is_android() {
    #  Only used to verify this_is_linux_native
    is_termux && return 1
    [ "$(uname -o)" = "Android" ]
}

is_termux() {
    [ -n "$TERMUX_VERSION" ]
}

is_chrooted() {
    # cmdline check:
    # grep -qv " / / " /proc/self/mountinfo || echo "is chrooted"

    # this quick and simple check doesn't work on ish
    # so lets pretend for now chroot does not happen on ish
    is_linux || return 1
    [ ! -f /proc/self/mountinfo ] && return 1
    ! grep -q " / / " /proc/self/mountinfo
}

is_linux_native() { # Filters out chrooted and various Linux based derivates
    is_linux || return 1
    if is_ish || is_termux || is_android || is_chrooted; then
        return 1
    fi
    return 0
}

fs_is_alpine() {
    [ -f /etc/alpine-release ]
}

fs_is_debian() {
    [ -f /etc/debian_version ]
}

fs_is_ubuntu() {
    grep -qs '^ID=ubuntu$' /etc/os-release
}

# ---  not currently used

fs_is_gentoo() {
    [ -f /etc/gentoo-release ]
}

#===============================================================
#
#   Main
#
#===============================================================

# these must be done before local variables assignments,
# since some of them depend on variables defined by them
# read_config
# check_if_host_or_dest_fs

#
#  Locations for various stuff
#

TMPDIR="${TMPDIR:-/tmp}"

[ -z "$app_name" ] && app_name=$(basename "$0")

[ -z "$current_dbg_lvl" ] && {
    # 0 means only msg_dbg without dbg_lvl 2nd param will be displayed
    current_dbg_lvl=0
}

return 0 # ensures the above doesn't indicate sourcing failed
