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
. $(dirname $0)/../etc/defaults/config.sh

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
url_base=$(nbdist_get_url_base $branch)
version=$(nbdist_get_latest_entry $url_base)
build_date=$(echo $version | awk '{print substr($1, 0, 8)}')
list_all=$(nbdist_get_list $url_base$version/				|
		tr ' ' '\n'						|
		grep '^[a-z]'						)

for arch in ${list:-$list_all}
do
    is_ignore=$(nbdist_check_ignore $arch)
    if [ $is_ignore = 1 ];then continue;fi
    
    nbpkg_dir_init $arch $branch $build_date
    nbpkg_log_init $arch $branch $build_date
    (
	logit "session: start $arch $branch $version"
	t_start=$(unixtime)
	queue_add active $arch $branch $build_date

        nbpkg_build_run_session_start_hook

	# 1.  preparation
	# 1.1 download and extract the latest daily build
	nbdist_download $arch $url_base$version/$arch/binary/sets/
	nbdist_extract  $arch

	# 1.2 ident based check
	#     extract ident data, compare it with the saved one and
	#     generate the list of basepkg to re-build as a file $basepkg_new.
	basepkg_cnf=$junk_dir/basepkg.conf
	basepkg_all=$(nbpkg_basepkg_data_file $arch $branch $build_date)
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
	    logit "session: skip $arch $branch $version"
	else
	    logit "session: run $arch $branch $version"
	    nbpkg_build_gen_basepkg_conf    $arch $branch $build_date \
			$basepkg_cnf $basepkg_all $basepkg_new
	    nbpkg_build_run_basepkg         $arch $basepkg_cnf
	    nbpkg_release_basepkg_packages  $arch $branch
	    queue_add done  $arch $branch $build_date
	    queue_del retry $arch $branch $build_date  # clear flag if exists
	fi

        nbpkg_build_run_session_end_hook

	queue_del active $arch $branch $build_date	
	t_end=$(unixtime)
	t_diff=$(($t_end - $t_start))
	logit "session: end $arch $branch $version total: $t_diff sec."
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
