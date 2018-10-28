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
#        NAME: config.sh (nbpkg-build/etc/defaults/config.sh)
# DESCRIPTION: default configuration file.
# CODINGSTYLE: POSIX compliant (checked by running "bash --posix" this script)
#

#
# fundamental URL
#
url_base_stable8=http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-8/
url_base_stable7=http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-7/
url_base_stable6=http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-6/
url_base_current=http://nycdn.netbsd.org/pub/NetBSD-daily/HEAD/

url_base_release6=http://ftp.iij.ad.jp/pub/NetBSD/NetBSD-6.0/
url_base_release7=http://ftp.iij.ad.jp/pub/NetBSD/NetBSD-7.0/
url_base_release8=http://ftp.iij.ad.jp/pub/NetBSD/NetBSD-8.0/


#
# nbpkg-build specific directories: these hold persistent data.
#
prefix=/var/nbpkg-build
prog_basepkg_dir=$prefix/dist/basepkg
nbpkg_base_dir=$prefix
ident_base_dir=$nbpkg_base_dir/db/ident
queue_base_dir=$nbpkg_base_dir/queue
  log_base_dir=$nbpkg_base_dir/log

# www: public area where generated packages are published.
  www_base_dir=/pub/www/pub/NetBSD/basepkg/

# pre-defined for emergency stop.
logf=/var/tmp/log.nbpkg-debug


#
# working directories which pre-defiend value is dummy.
#
base_dir=$nbpkg_base_dir/work/base.$$	# dummy
dist_dir=$nbpkg_base_dir/work/dist.$$	# dummy
dest_dir=$nbpkg_base_dir/work/dest.$$	# dummy
rels_dir=$nbpkg_base_dir/work/rels.$$	# dummy
junk_dir=$nbpkg_base_dir/work/junk.$$	# dummy
done_xxx=/var/tmp/nbpkg-build-done
