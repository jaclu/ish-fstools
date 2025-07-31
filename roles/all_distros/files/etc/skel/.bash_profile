#!/bin/bash
#   Fake bangpath to help editors and linters
#
#  Part of https://github.com/jaclu/ish-fstool
#
#  License: MIT
#
#  Copyright (c) 2023,2024: Jacob.Lundqvist@gmail.com
#
# ~/.bash_profile: executed by bash(1) for login shells.
#

#
#  Non-interactive shells won't read this by themselves. This ensures
#  that if they get here via idirect sourcing, they abort.
#
echo "$-" | grep -qv 'i' && return # non-interactive

#
#  If found, run the common init script used by non-login shells,
#  in order to keep the setup in one place
#
if [[ -f ~/.bashrc ]]; then
    # shellcheck source=/opt/ish-fstools/roles/all_distros/files/etc/skel/.bashrc
    . ~/.bashrc
fi
