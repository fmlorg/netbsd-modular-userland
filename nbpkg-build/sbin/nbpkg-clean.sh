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
#        NAME: nbpkg-clean.sh
# DESCRIPTION:
# CODINGSTYLE: POSIX compliant (checked by running "bash --posix" this script)
#

############################################################
####################   CONFIGURATIONS   ####################
############################################################

. $(dirname $0)/../etc/config.sh

############################################################
####################      FUNCTIONS     ####################
############################################################

. $(dirname $0)/../lib/libutil.sh
. $(dirname $0)/../lib/libnbpkg.sh


############################################################
####################        MAIN        ####################
############################################################

set -u

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

list_vers=$(nbpkg_dst_dir_list_version)
for ver in ${list_vers}
do
    list_arch=$(nbpkg_dst_dir_list_arch $ver)
    for arch in ${list_arch}
    do
	dir=$(nbpkg_dst_dir $arch $ver)
	if [ -h $dir ];then continue; fi
	if [ -d $dir ];then
	    $(nbpkg_dst_clean $dir)
	fi
    done
done

exit 0
