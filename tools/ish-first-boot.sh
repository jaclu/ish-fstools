#!/bin/sh
#
#  Part of https://github.com/jaclu/ish-fstools
#
#  Copyright (c) 2026: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  When this runs for the first time on iSH, it will clear out any reminants of
#  a chrooted buildenv, like a previously set hostname
#

load_utils() {
    _lu_d_base="${1:-$d_repo}"
    _lu_f_utils="$_lu_d_base"/utils/script-utils.sh

    # shellcheck source=/usr/local/lib/ift-utils.sh disable=SC1091
    . /usr/local/lib/ift-utils.sh || {
        printf '\nERROR: Failed to source: %s\n' "$_lu_f_utils" >&2
        exit 1
    }
}

#===============================================================
#
#   Main
#
#===============================================================

load_utils

# Various state files used during build that can now be removed
build_files="
/.chroot_default_cmd
/.chroot_hostname
/etc/opt/chrooted_ish
"

lbl_1 "Doing some first boot on iSH cleanup"

printf '%s\n' "$build_files" \
    | while IFS= read -r f; do
        [ -n "$f" ] || continue
        safe_remove --ignore-sys-path "$f"
    done

#
# Doesn't seem to work pre login, read instantly returns, so actual hostname
# needs to be set once fully booted
#
# printf "Enter hostname: "
# IFS= read -r h_name
# if [ -n "$h_name" ]; then
#     lbl_1 "Setting hostname: $h_name"
#     /usr/local/bin/hostname "$h_name"
# else

lbl_1 "Default hostname iSH will be used"
/usr/local/bin/hostname iSH
# fi
