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
    /usr/bin/uname -r | cut -c 1-3
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
    if [ -x /usr/pkg/bin/pkgin ];then
	do_pkgin upgrade
    else
	for p in $*
	do
	    pkg_del $p
	    pkg_add $p
	done
    fi
}

do_init () {
    pkg_add pkgin
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
host=basepkg.netbsd.fml.org
PKG_PATH=http://$host/pub/NetBSD/basepkg/$rel/$arch
PKG_REPOS=$PKG_PATH
export PKG_PATH
export PKG_REPOS

# debug
echo PKG_PATH   $PKG_PATH    
echo PKG_REPOS $PKG_REPOS

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
