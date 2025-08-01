#!/bin/sh
#
#  Part of https://github.com/jaclu/ish-fstool
#
#  License: MIT
#
#  Copyright (c) 2022-2025: Jacob.Lundqvist@gmail.com
#
#  Cleanup build env
#  ansible can't be run on iSH anyhow and it consumes several hundred MB
#  so no point in keeping it
#

rm -rf /root/ish-fstools
rm -rf /iCloud/*

#
#  ansible can't be run on iSH so no point in keeping it around.
#  AND it consumes over 450 MB and 46k files...
#
apk del ansible
