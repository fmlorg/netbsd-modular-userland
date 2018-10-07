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
#        NAME: nbpkg-build.sh
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
. $(dirname $0)/../lib/libqueue.sh
. $(dirname $0)/../lib/libnbpkg.sh
. $(dirname $0)/../lib/libnbdist.sh

############################################################
####################        MAIN        ####################
############################################################

set -u

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

nbpkg_build_assert

is_debug=${DEBUG:-""}
is_require_download_and_extract=""
type=${1:-stable}
list=${2:-}
case $type in
    stable8 ) url_base=$url_base_stable8;;
    stable  ) url_base=$url_base_stable8;;
    stable7 ) url_base=$url_base_stable7;;
    legacy  ) url_base=$url_base_stable6;;
    stable6 ) url_base=$url_base_stable6;;
    current ) url_base=$url_base_current;;
esac
version=$(nbdist_get_latest_entry $url_base)
vers_date=$(echo $version | awk '{print substr($1, 0, 8)}')
list_all=$(nbdist_get_list $url_base$version/				|
		tr ' ' '\n'						|
		grep '^[a-z]'						)

for arch in ${list:-$list_all}
do
    is_ignore=$(nbdist_check_ignore $arch)
    if [ $is_ignore = 1 ];then continue;fi
    
    dir_init $arch
    log_init $arch
    (
	logit "session: start $type $arch $version"
	t_start=$(unixtime)
	queue_add active $vers_date $type $arch

	# 1. prepare
	nbdist_download $arch $url_base$version/$arch/binary/sets/
	nbdist_extract  $arch

	# 2. go if not already done 
	is_already_done=$(queue_find done $vers_date $type $arch)
	if [ ${is_already_done} -eq 1 ];then
	    logit "session: skip $type $arch $version"
	else
	    logit "session: run $type $arch $version"
	    nbpkg_build_run_basepkg         $arch
	    nbpkg_release_basepkg_packages  $arch
	    queue_add done  $vers_date $type $arch
	    queue_del retry $vers_date $type $arch  # clear flag if exists
	fi

	queue_del active $vers_date $type $arch	
	t_end=$(unixtime)
	t_diff=$(($t_end - $t_start))
	logit "session: end $type $arch $version total: $t_diff sec."
    )

    if [ $? != 0 ];then
	queue_del active $vers_date $type $arch
	queue_add retry $vers_date $type $arch
	dir_clean 1
    	logit "session: ***error*** arch=$arch ended abnormally."
    else
	dir_clean 0
    fi
done

exit 0
