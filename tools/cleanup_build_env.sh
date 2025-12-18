#!/bin/sh
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
rm -rf /iCloud/*
rm -f  /tmp/ssh_conf.tgz
rm -rf /tmp/ansible_facts_cache
rm -rf /root/.ansible
rm -rf /root/ish-fstools
