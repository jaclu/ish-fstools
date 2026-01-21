#!/usr/bin/env bash
#
#  Part of https://github.com/jaclu/ish-fstool
#
#  License: MIT
#
#  Copyright (c) 2022-2025: Jacob.Lundqvist@gmail.com
#
#  Cleanup build env
#

#
#  ansible can't be run on iSH so no point in keeping it around.
#  AND it consumes over 450 MB and 46k files...
#
apk del ansible

#
# remove stuff used during build of FS
#

delete_items() {
    local item
    for item in "${items[@]}"; do
        [[ -e $item ]] || {
            # lbl_3 "item not found: $item"
            continue
        }
        safe_remove "$item"
    done
}

load_utils() {
    local d_base="${1:-$d_repo}"
    local f_utils="$d_base"/tools/script-utils.sh

    # source a POSIX file
    # shellcheck source=tools/script-utils.sh disable=SC1091,SC2317
    source "$f_utils" || {
        printf '\nERROR: Failed to source: %s\n' "$f_utils" >&2
        exit 1
    }
}

#===============================================================
#
#   Main
#
#===============================================================

d_repo=$(cd -- "$(dirname -- "$0")/.." && pwd) # one folder above this

load_utils

lbl_1 "Deploy cleanup"
items=(
    # ensure its not real iCloud first
    # /iCloud

    # /home/jaclu/.local/bin/defgw # installed if on chroot
    # /home/jaclu/.local/bin/Mbrew # installed if on chroot
    /root/.ansible
    /home/jaclu/.local/bin/defgw
    /home/jaclu/.local/bin/Mbrew
)
delete_items
safe_remove --remove-dir /iCloud
safe_remove --remove-dir /tmp/ansible_facts_cache
safe_remove --remove-dir /root/ish-fstools
safe_remove --remove-dir /root/.ansible
