#!/bin/sh
#
# Copyright (C) 2018 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under 2-Clause BSD License.
#   https://opensource.org/licenses/BSD-2-Clause
#
# mailto: fukachan@fml.org
#    web: http://www.fml.org/
#
# $FML$
# $Revision$
#        NAME: config.sh (nbpkg-build/etc/config.sh)
# DESCRIPTION: configuration file each user can customize
# CODINGSTYLE: POSIX compliant (checked by running "bash --posix" this script)
#


#
# CONFIGURATIONS
#

# mandatory external programs
basepkg_base_dir=/var/nbpkg-build/dist/basepkg
basepkg_list_dir=$basepkg_base_dir/sets/lists

# nbpkg-build specific directories: these hold persistent data.
nbpkg_base_dir=/var/nbpkg-build

# nbpkg-build data backup
nbpkg_data_dir=/var/nbpkg-data

# web base directory where generated packages are published.
www_base_dir=/pub/www/pub/NetBSD/basepkg/diff


#
# nbpkg-build specific directories: these hold persistent data.
#
  log_base_dir=$nbpkg_base_dir/log
     queue_dir=$nbpkg_base_dir/queue
   db_base_dir=$nbpkg_base_dir/db
  db_ident_dir=$db_base_dir/ident/diff
db_basepkg_dir=$db_base_dir/basepkg/diff


#
# pre-defined for emergency stop. nbpkg_log_init() re-defines $logf.
#
          logf=/var/tmp/log.nbpkg-debug
