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
#        NAME: nbpkg-identgen.sh
# DESCRIPTION: dump ident info for the specific NetBSD.
# CODINGSTYLE: POSIX compliant (checked by running "bash --posix" this script)
#

############################################################
####################   CONFIGURATIONS   ####################
############################################################

. $(dirname $0)/../../nbpkg-build/etc/defaults/config.sh
. $(dirname $0)/../../nbpkg-build/etc/config.sh

############################################################
####################      FUNCTIONS     ####################
############################################################

. $(dirname $0)/../../nbpkg-build/lib/libutil.sh
. $(dirname $0)/../../nbpkg-build/lib/libqueue.sh
. $(dirname $0)/../../nbpkg-build/lib/libnbpkg.sh
. $(dirname $0)/../../nbpkg-build/lib/libnbdist.sh

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
url_base=$(nbdist_get_url_base $branch)
version=$(nbdist_get_latest_entry $url_base)
vers_date=$(echo $version | awk '{print substr($1, 0, 8)}')

echo "debug list {"
nbdist_get_list $url_base$version/
echo "}"

list_all=$(nbdist_get_list $url_base$version/				|
tee /tmp/debug	| 
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

	nbdist_download $arch $url_base$version/$arch/binary/sets/
	nbdist_extract  $arch

	out=$(_nbdist_ident_data_file $arch $type $vers)
	nbdist_get_ident_list $arch $type $vers $out

	t_end=$(unixtime)
	t_diff=$(($t_end - $t_start))
	logit "session: end $type $arch $version total: $t_diff sec."
    )
done

exit 0
