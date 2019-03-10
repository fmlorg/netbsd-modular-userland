#!/bin/sh
#
# Copyright (C) 2018,2019 Ken'ichi Fukamachi
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

#
# CAUTION
# initialized once for each major release.
# sh -vx nbpkg-build/sbin/nbpkg-build.sh -b release-8 
#
logfile_path () {
    local   arch=$1
    local branch=$2
    local   date=$(date +%Y%m%d)
    local    dir=$LOG_DIR/$branch/$date

    test -d $dir || mkdir -p $dir
    echo $dir/$arch
}

check_suicide () {
    if [ -f $PREEMPT ];then
	logger "$0 maintenance mode; stopped."
	exit 0
    fi
}

run_nbpkg_build () {
    local   arch=$1
    local branch=$2

    [ "X$arch" = "X--all" ] && arch=""
    ${SHELL} ${SH_OPTS} nbpkg-build/sbin/nbpkg-build.sh -b $branch $arch
}
 
run_loop_foreach_tier () {
    local tier=$1
    local branch=netbsd-8
    local list=""
    local log=""

    case $tier in
	1) list="$TIER_1";        shift;;
	2) list="$TIER_2";        shift;;
	3) list="$TIER_3";        shift;;
      all) list="--all";          shift;;
	*) echo "run_loop_foreach_tier: no arg"; exit 1;
    esac

    for arch in $list
    do
	log=$(logfile_path $arch $branch)
	$(run_nbpkg_build  $arch $branch >> $log 2>&1)
	check_suicide
    done
}


# debug
SH_OPTS="-vx"

# configurations
  SHELL=/bin/sh
LOG_DIR=/var/tmp/nbpkg-build-log
   MODE=${1:-default}
PREEMPT=/tmp/.preempt.nbpkg.stop.all
 BRANCH=netbsd-8
  LOCKF=/tmp/.lock.nbpkg.master.$BRANCH.$MODE
 TIER_1="amd64 evbarm evbmips evbppc hpcarm i386 sparc64 xen"
 TIER_1="amd64 hpcarm i386 sparc64 xen"
 TIER_1="$TIER_1 	evbarm-earm evbarm-earmeb evbarm-earmv6hf 	\
			evbarm-earmv7hf evbarm-earmv7hfeb"
 TIER_1="$TIER_1	evbmips-mips64eb evbmips-mips64el 		\
			evbmips-mipseb evbmips-mipsel"
 TIER_1="$TIER_1	evbppc"

 TIER_2="acorn32 algor alpha amiga amigappc arc atari bebox cats	\
	 cesfic cobalt dreamcast emips epoc32 				\
	 evbsh3-sh3eb evbsh3-sh3el					\
	 ews4800mips hp300						\
	 hppa hpcmips hpcsh ia64 ibmnws iyonix landisk luna68k mac68k	\
	 macppc mipsco mmeye mvme68k mvmeppc netwinder news68k		\
	 newsmips next68k ofppc pmax prep rs6000 sandpoint sbmips	\
	 sgimips shark sparc sun2 sun3 vax x68k zaurus"
 TIER_3="acorn26" 


#
# MAIN
#
set -u

check_suicide

if [ -f /root/nbpkg/rc.conf ];then
   . /root/nbpkg/rc.conf
else
   echo "***error: CONFIGURATION /root/nbpkg/rc.conf is mandatory."
   exit 1
fi

cd $top_dir || exit 1

if shlock -f $LOCKF -p $$
then
    if [ "X$MODE" = "Xall" ];then
        run_loop_foreach_tier 1
        run_loop_foreach_tier 2
        run_loop_foreach_tier 3
        run_loop_foreach_tier all
    else
        run_loop_foreach_tier 1
     fi
else
    echo Lock ${LOCKF} already held by `cat ${LOCKF}`
fi

exit 0
