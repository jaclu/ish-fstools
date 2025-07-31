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
apk del ansible

