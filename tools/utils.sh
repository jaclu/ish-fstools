#!/bin/sh
# This is sourced. Fake bang-path to help editors and linters
#  shellcheck disable=SC2034,SC2154
#
#  Part of https://github.com/jaclu/ish-fstool
#
#  License: MIT
#
#  Copyright (c) 2023-2025: Jacob.Lundqvist@gmail.com
#
#  Environment variables used when building ish-fstools
#

err_msg() {
    #  Display an error message, second optional param is exit code,
    #  defaulting to 1. If exit code is -1 this will not exit, just display
    #  the error message and continue.
    _em_msg="$1"
    _em_exit_code="${2:-1}"
    if [ -z "$_em_msg" ]; then
        # Don't use log_it here, to avoid risk of infinite recursion...
        echo
        echo "err_msg() no param"
        exit 9
    fi

    _em_msg="ERROR[$0]: $_em_msg"
    echo
    echo "$_em_msg"
    echo

    if [ "$_em_exit_code" -gt -1 ]; then
        exit "$_em_exit_code"
    fi
    unset _em_msg
    unset _em_exit_code
}

log_it() {
    _li_msg="$1"
    [ -z "$_li_msg" ] && err_msg "log_it() no param"
    echo "$_li_msg"
    unset _li_msg
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

safe_remove() {
    #
    # Ensures what is to be removed is not a "dangerous" path that would
    # cause a mess of the file system
    # If param 2 is empty, an extra check will be made that the pattern is prefixed
    # by the location of this plugin, only use param 2 if something outside
    # the plugin location needs to be removed
    #
    _sr_pattern="$1"
    _sr_reason="$2"

    # log_it "safe_remove($_sr_pattern) - $_sr_reason"
    [ -z "$_sr_pattern" ] && err_msg "safe_remove() - no path supplied!"
    [ -z "$_sr_reason" ] && err_msg "safe_remove() - no _sr_reason given!"

    tmpdir_noslash="${TMPDIR%/}" # Remove trailing slash if present

    case "$_sr_pattern" in
        "$tmpdir_noslash") # Prevent direct removal of TMPDIR
            err_msg "safe_remove() - refusing to delete TMPDIR itself: $_sr_pattern"
            return 1
            ;;
        "$tmpdir_noslash"/*) ;; # Allow anything inside TMPDIR
        /etc | /etc/* | /usr | /usr/* | /var | /var/* | "$HOME" | /home | \
            /Users | /bin | /bin/* | /sbin | /sbin/* | /lib | /lib/* | \
            /lib64 | /lib64/* | /boot | /boot/* | /mnt | /mnt/* | /media | /media/* | \
            /run | /run/* | /opt | /opt/* | /root | /root/* | /dev | /dev/* | \
            /proc | /proc/* | /sys | /sys/* | /lost+found | /lost+found/*)
            err_msg "safe_remove() - refusing to delete protected directory: $_sr_pattern"
            return 1
            ;;
        *) ;;
    esac

    sudo rm -rf "$_sr_pattern" || err_msg "$_sr_reason - safe_remove() - Failed to delete: $_sr_pattern"
    return 0
}

#===============================================================
#
#   Main
#
#===============================================================

TMPDIR="${TMPDIR:-/tmp}"
