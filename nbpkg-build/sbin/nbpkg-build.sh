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

# determine target arch to build
#    url_base = http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-8/
#  build_nyid = 201811180430Z
#  build_date = 20181118
  url_base=$(nbdist_get_url_base $branch)
build_nyid=$(nbdist_get_build_id   $branch $url_base)
build_date=$(nbdist_get_build_date $branch $build_nyid)
 build_url=$(nbdist_get_url        $branch $url_base $build_nyid)
list_all=$(nbdist_get_list $build_url					|
		tr ' ' '\n'						|
		grep '^[a-z]'						)

for arch in ${list:-$list_all}
do
    is_ignore=$(nbdist_check_ignore $arch)
    if [ $is_ignore = 1 ];then continue;fi
    
    nbpkg_dir_init $arch $branch $build_date
    nbpkg_log_init $arch $branch $build_date
    (
	logit "session: start $arch $branch $build_nyid"
	t_start=$(unixtime)
	queue_add active $arch $branch $build_date

        nbpkg_build_run_session_start_hook

	# 1.  preparation
	# 1.1 download and extract the latest daily build
	nbdist_download $arch $build_url/$arch/binary/sets/
	nbdist_extract  $arch

	# 1.2 ident based check
	#     extract ident data, compare it with the saved one and
	#     generate the list of basepkg to re-build as a file $basepkg_new.
	basepkg_new=$junk_dir/list.basepkg.changed
	nbdist_check_ident_changes $arch $branch $build_date $basepkg_new
	if [ -s $basepkg_new ];then
	    logit "session: ident changes found, go forward"
	else
	    logit "session: no ident changes, do nothing"
	    exit 0
	fi

	# 2. go if not already done 
	is_already_done=$(queue_find done $arch $branch $build_date)
	if [ ${is_already_done} -eq 1 ];then
	    logit "session: skip $arch $branch $build_nyid"
	else
	    logit "session: run $arch $branch $build_nyid"
	    nbpkg_build_gen_basepkg_conf    $arch $branch $build_date \
					                  $basepkg_new
	    nbpkg_build_run_basepkg         $arch $branch "maint"
	    nbpkg_release_basepkg_packages  $arch $branch "maint"
	    nbpkg_build_run_basepkg         $arch $branch   "all"
	    nbpkg_release_basepkg_packages  $arch $branch   "all"
	    queue_add done  $arch $branch $build_date
	    queue_del retry $arch $branch $build_date  # clear flag if exists
	fi

        nbpkg_build_run_session_end_hook

	queue_del active $arch $branch $build_date	
	t_end=$(unixtime)
	t_diff=$(($t_end - $t_start))
	logit "session: end $arch $branch $build_nyid total: $t_diff sec."
    )

    if [ "X$is_debug" != "X" ];then logit "session: debug: not clean"; exit 0; fi

    if [ $? != 0 ];then
	queue_del active $arch $branch $build_date
	queue_add retry  $arch $branch $build_date
	nbpkg_dir_clean 1
    	logit "session: ***error*** arch=$arch ended abnormally."
    else
	nbpkg_dir_clean 0
    fi
done

exit 0
