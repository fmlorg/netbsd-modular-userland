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

. $(dirname $0)/../etc/defaults/config.sh
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

# global flags
is_debug=${DEBUG:-""}
is_require_download_and_extract=""

# parse options
while getopts dvhb: _opt
do
    case $_opt in
       h | \?) echo "usage: $0 [-hdv] -b BRANCH [ARCH ...]" 1>&2; exit 1;;
       d | v)  is_debug=1;;
       b)      branch=$OPTARG;;
    esac
done
shift $(expr $OPTIND - 1)
list=${1:-}
type=$branch

# determine target arch to build
case $branch in
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
    
    nbpkg_dir_init $arch
    nbpkg_log_init $arch
    (
	logit "session: start $type $arch $version"
	t_start=$(unixtime)
	queue_add active $arch $type $vers_date

	# 1. prepare
	nbdist_download $arch $url_base$version/$arch/binary/sets/
	nbdist_extract  $arch

	# check ident info of downloaded binaries and get the list of
	# syspkgs names as $_list_changed.
	_list_changed=$(nbdist_check_ident_changes $arch $type $vers_date)
	if [ "X$_list_changed" = "X" ];then
	    logit "session: no ident changes, do nothing"
	    exit 0
	fi
	
	# 2. go if not already done 
	is_already_done=$(queue_find done $arch $type $vers_date)
	if [ ${is_already_done} -eq 1 ];then
	    logit "session: skip $type $arch $version"
	else
	    logit "session: run $type $arch $version"
	    nbpkg_build_run_basepkg         $arch
	    nbpkg_release_basepkg_packages  $arch
	    queue_add done  $arch $type $vers_date
	    queue_del retry $arch $type $vers_date  # clear flag if exists
	fi

	queue_del active $arch $type $vers_date	
	t_end=$(unixtime)
	t_diff=$(($t_end - $t_start))
	logit "session: end $type $arch $version total: $t_diff sec."
    )

    if [ $? != 0 ];then
	queue_del active $arch $type $vers_date
	queue_add retry $arch $type $vers_date
	nbpkg_dir_clean 1
    	logit "session: ***error*** arch=$arch ended abnormally."
    else
	nbpkg_dir_clean 0
    fi
done

exit 0
