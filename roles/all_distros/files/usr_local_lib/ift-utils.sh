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
#  Environment variables used when building the AOK-FS
#

#---------------------------------------------------------------
#
#   Notifications
#
#  The msg_ functions are ordered, lower number infers more important updates
#  so they should stand out more
#
#---------------------------------------------------------------

error_msg() {
    #  Display an error message, second optional param is exit code,
    #  defaulting to 1. If exit code is -1 this will not exit, just display
    #  the error message and continue.
    _em_msg="$1"
    _em_exit_code="${2:-1}"
    if [ -z "$_em_msg" ]; then
        echo
        echo "error_msg() no param"
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

do_msg() {
    _msg="$1"
    [ -z "$_msg" ] && error_msg "do_msg() no param"
    echo "$_msg"
    unset _msg
}

msg_1() {
    [ -z "$1" ] && error_msg "msg_1() no param"
    echo
    do_msg "===  $1  ==="
    echo
}

msg_2() {
    [ -n "$1" ] || error_msg "msg_2() no param"
    do_msg "---  $1"
}

msg_3() {
    [ -n "$1" ] || error_msg "msg_3() no param"
    do_msg " --  $1"
}

msg_4() {
    [ -n "$1" ] || error_msg "msg_4() no param"
    do_msg "  -  $1"
}

syslog() {
    [ -z "$1" ] && error_msg "syslog() - called without param"

    /usr/local/bin/logger "$(basename "$0")" "$1"
}

#---------------------------------------------------------------
#
#   boolean checks
#
#---------------------------------------------------------------

this_is_fs_with_aok() {
    #
    #  This system is using AOK FS extensions, prevents stuff
    #  from running on Linux outside chroot
    #
    test -f "$f_ift_fs_release"
}

this_is_ish() {
    test -d /proc/ish
}

is_fs_chrooted() {
    # cmdline check:
    # grep -qv " / / " /proc/self/mountinfo || echo "is chrooted"

    # this quick and simple check doesn't work on ish
    # so lets pretend for now chroot does not happen on ish
    this_is_ish && return 1                  # would never happen here :)
    [ "$(uname -s)" != "Linux" ] && return 1 # can only chroot this on Linux
    ! grep -q " / / " /proc/self/mountinfo
}

#===============================================================
#
#   Main
#
#  Env variables
#  aok_this_is_dest_fs="Y"  -  Indicates this is running in dest FS
#
#===============================================================

# these must be done before local variables assignments,
# since some of them depend on variables defined by them
# read_config
# check_if_host_or_dest_fs

TMPDIR="${TMPDIR:-/tmp}"


#
#  Locations for various stuff
#

#  Placeholder, to store what version of AOK that was used to build FS
f_ift_fs_release=/etc/ift-fs-release

# d_aok_etc="$d_build_root/$d_aok_etc"
d_ift_etc_opt=/etc/opt/ift

#  file alt hostname reads to find hostname
#  the variable has been renamed to


#
#  For automated logins used by aok anf aok_launcher
#
f_login_default_user="$d_ift_etc_opt"/login-default-username
f_logins_continuous="$d_ift_etc_opt"/login-continuous

f_pts_0_as_console="$d_ift_etc_opt"/pts_0_as_console
f_profile_hints="$d_ift_etc_opt"/show_profile_hints

VNC_APKS="x11vnc x11vnc-doc xvfb xterm xorg-server xf86-video-dummy \
    i3wm i3wm-doc i3lock i3lock-doc i3status i3status-doc xdpyinfo \
    xdpyinfo-doc ttf-dejavu"
