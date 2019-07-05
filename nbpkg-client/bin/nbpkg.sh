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
    local  machine=$(/usr/bin/uname -m)	
    local platform=$(/usr/bin/uname -p)

    if [ "X$machine" != "X$platform" ];then
	echo $machine-$platform
    else
	echo $machine
    fi

}

syspkgs_alias_lookup () {
    local pkg_name=$1
    local     file=/var/tmp/alias.nppkg.$$

    cat > $file <<-_EOF_ALIAS_
	libcrypto.so		base-crypto-shlib
	libssl.so		base-crypto-shlib
	openssl			base-crypto-shlib
	openssl			base-crypto-bin
	openssh			base-secsh-bin
	named			base-bind-bin
	bind			base-bind-bin
	postfix			base-postfix-bin
        cc                      comp-c-bin
        cc                      comp-util-bin
	_EOF_ALIAS_

    grep "^$pkg_name[[:space:]]" $file | awk '{print $2}'
}

nbpkg_expand_argv () {
    local _arg _r _x

    _r=""
    for _arg in $*
    do
	_x=$(syspkgs_alias_lookup "$_arg")
	if [ "X$_x" != "X" ];then
		_r="$_r $_x"
	else
		_r="$_r $_arg"
	fi
    done

    echo "$_r"
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
    local found
    
    ftp -o $NBPKG_ADVISORY $NBPKG_ADVISORY_URL
    if [ ! -f $NBPKG_ADVISORY ];then
	cat <<-__EOF__
	*** WARNING *** nbpkg advisory NOT SUPPORTED

	$0 install ...
		or
	$0 full-upgrade

__EOF__
	exit 0
    fi

    # nbpkg advisory format is such as "base-secsh-bin>7.1.20180706 REASON URL".
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

do_full_upgrade () {
    ftp -o $NBPKG_LIST_PKG $NBPKG_LIST_PKG_URL
    do_pkgin import $NBPKG_LIST_PKG
}

do_init () {
    test -d $NBPKG_DB || mkdir -p $NBPKG_DB

    if [ ! -x /usr/pkg/bin/pkgin ];then
	env PKG_PATH=ftp://ftp.NetBSD.org/pub/pkgsrc/packages/NetBSD/$arch/$release/All pkg_add -v pkgin
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
  release=$(netbsd_resolve_version)
     arch=$(netbsd_resolve_machine_and_arch)
   branch=$(echo $release | awk '{printf("netbsd-%d\n", $1)}')
     host=basepkg.netbsd.fml.org
     mode=v0.5.9

# parse options
while getopts hdvb:m:a _opt
do
    case $_opt in
       h | \?) echo "usage: $0 [-hdv] -b BRANCH [ARCH ...]" 1>&2; exit 1;;
       d | v)  is_debug=1;;
       b)      branch=$OPTARG;;
#      m)      mode=$OPTARG;;
       a)      mode=all;;
    esac
done
shift $(expr $OPTIND - 1)
list=${1:-}


 PKG_PATH=http://$host/pub/NetBSD/basepkg/$branch/$arch/$mode
PKG_REPOS=$PKG_PATH
export PKG_PATH
export PKG_REPOS

          NBPKG_DB=/var/db/nbpkg
    NBPKG_ADVISORY=$NBPKG_DB/nbpkg-advisory.txt
NBPKG_ADVISORY_URL=http://$host/pub/NetBSD/nbpkg/$branch/$arch/$mode/pkg_list2upgrade
    NBPKG_LIST_PKG=$NBPKG_DB/pkg_list2upgrade
NBPKG_LIST_PKG_URL=$PKG_PATH/pkg_list2upgrade

# debug
echo ""                                 1>&2                    
echo "debug: PKG_PATH  = $PKG_PATH"     1>&2
echo "debug: PKG_REPOS = $PKG_REPOS"    1>&2
echo ""                                 1>&2

do_init

argv_new=$(nbpkg_expand_argv $*)

echo "debug: ARGV $argv_new"		1>&2
set -- $argv_new

if [ $# -eq 0 ]; then usage; exit 1;fi
case $1 in
    help | -h | \?  )  usage;                 exit 1 ;;
    install         )  shift; do_install          $* ;;
    remove          )  shift; do_remove           $* ;;
    update          )  shift; do_update              ;;
    upgrade         )  shift; do_upgrade             ;;
    full-upgrade    )  shift; do_full_upgrade        ;;
    init            )  shift; do_init                ;;
    [a-z]*          )         do_direct_pkgin        ;;
    *               )  usage;                 exit 1 ;;
esac

exit 0;
