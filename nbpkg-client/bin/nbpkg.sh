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
#        NAME: nbpkg.sh
# DESCRIPTION: a reference implementation of the user utiilty for 
#              NetBSD modular userland to provide the granular update.
# CODINGSTYLE: POSIX compliant (checked by running "bash --posix" this script)
#


############################################################
####################      FUNCTIONS     ####################
############################################################

usage () {
    echo "USAGE: $0 [-h] command ..."
}

# return the NetBSD version such as 7.0 7.1 8.0 ... without _STABLE et.al.
netbsd_resolve_version () {
    /usr/bin/uname -r				|
    sed s/_STABLE//g				|
    awk '{printf("%2.1f\n", $1)}'
}    

netbsd_resolve_machine_and_arch () {
    local machine=$(/usr/bin/uname -m)	
    local platform=$(/usr/bin/uname -p)

    if [ "X$machine" != "X$platform" ];then
	echo $machine-$platform
    else
	echo $machine
    fi

}

do_pkgin () {
    echo pkgin $*
         pkgin $*
}

do_install () {
    if [ -x /usr/pkg/bin/pkgin ];then
	do_pkgin install $*
    else
	echo pkg_add $*
	     pkg_add $*
    fi
}

do_remove () {
    if [ -x /usr/pkg/bin/pkgin ];then
	do_pkgin remove $*
    else
	pkg_del $*
    fi
}

# XXX update (1) nbpkg-advisory (2) pkg_summary.gz
do_update () {
    # nbpkg advisory format is such as "base-secsh-bin>7.1.20180706 REASON URL".
    ftp -o $NBPKG_ADVISORY $NBPKG_ADVISORY_URL

    if [ -x /usr/pkg/bin/pkgin ];then
	do_pkgin update
    else
	do_init
	if [ -x /usr/pkg/bin/pkgin ];then
	    do_pkgin update
	fi
    fi
}

# XXX update (del and add) based on nbpkg-advisory not run "pkgin upgrade"
do_upgrade () {
    local found
    
    cat $NBPKG_ADVISORY               		|
	while read rule reason url
	do
	    echo "debug>>> $rule"		1>&2
	    found=$(pkg_info -E "$rule")
	    if [ $? -ne 0 ];then
		do_pkgin -n install "$rule"
	    else
		echo "   $found already installed, so ignored"
	    fi
	    echo ""
	done
}

do_init () {
    test -d $NBPKG_DB || mkdir -p $NBPKG_DB

    if [ ! -x /usr/pkg/bin/pkgin ];then
	rel=$(netbsd_resolve_version)
	env PKG_PATH=ftp://ftp.NetBSD.org/pub/pkgsrc/packages/NetBSD/$arch/$rel/All pkg_add -v pkgin
    fi
}

do_direct_pkgin () {
    do_pkgin $*
}

############################################################
####################        MAIN        ####################
############################################################

set -u

PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/pkg/sbin:/usr/pkg/bin
export PATH

#
# variables
#
rel=$(netbsd_resolve_version)
arch=$(netbsd_resolve_machine_and_arch)
branch=$(echo $rel | awk '{printf("netbsd-%d\n", $1)}')
host=basepkg.netbsd.fml.org
PKG_PATH=http://$host/pub/NetBSD/basepkg/$branch/$arch
PKG_REPOS=$PKG_PATH
export PKG_PATH
export PKG_REPOS

# nbpkg advisory format is such as "base-secsh-bin>7.1.20180706 REASON URL".
NBPKG_DB=/var/db/nbpkg
NBPKG_ADVISORY=$NBPKG_DB/nbpkg-advisory.txt
NBPKG_ADVISORY_URL=http://$host/pub/NetBSD/nbpkg/$branch/$arch/nbpkg-advisory.txt

# debug
echo ""
echo "debug: PKG_PATH  = $PKG_PATH"
echo "debug: PKG_REPOS = $PKG_REPOS"
echo ""

do_init

if [ $# -eq 0 ]; then usage; exit 1;fi
case $1 in
    help | -h | \?  ) usage; exit 1;;
    install )  shift; do_install       $* ;;
    remove  )  shift; do_remove        $* ;;
    update  )  shift; do_update        $* ;;
    upgrade )  shift; do_upgrade       $* ;;
    init    )  shift; do_init          $* ;;
    [a-z]*  )         do_direct_pkgin  $* ;;
    *               ) usage; exit 1;;
esac

exit 0;
