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

f_first_ish_boot_should_be_done=/etc/opt/first_ish_boot_not_done

[ -f "$f_first_ish_boot_should_be_done" ] || exit 0

# Various state files used during build that can now be removed
build_files="
/.chroot_default_cmd
/.chroot_hostname
/etc/opt/chrooted_ish
$f_first_ish_boot_should_be_done
"

printf '%s\n' "$build_files" \
    | while IFS= read -r f; do
        msg_dbg "will do: $f"
        [ -n "$f" ] || continue
        safe_remove --ignore-sys-path "$f"
    done
