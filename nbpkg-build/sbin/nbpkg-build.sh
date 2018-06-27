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

url_base_stable0=http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-7/
url_base_stable1=http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-6/
url_base_current=http://nycdn.netbsd.org/pub/NetBSD-daily/HEAD/

prog_basepkg_dir=/var/nbpkg/dist/basepkg

# global variables (initialized with a dummy value)
base_dir=/var/nbpkg/work/base.$$
dist_dir=/var/nbpkg/work/dist.$$
dest_dir=/var/nbpkg/work/dest.$$
rels_dir=/var/nbpkg/work/rels.$$
junk_xxx=/var/tmp/nbpkg-build-junk
done_xxx=/var/tmp/nbpkg-build-done

# queue
queue_dir=/var/nbpkg/queue

# log
log_base_dir=/var/nbpkg/log

# nginx
www_dir=/var/tmp/www

############################################################
####################      FUNCTIONS     ####################
############################################################

#
# misc
#
logit () {
    local logf=$log_dir/$type.$arch
    
    echo   "$*"
    echo   "nbpkg-build: $*" >> $logf
    logger "nbpkg-build: $*"
    
}

random_number () {
    echo $(od -An -N 2 -t u2 /dev/urandom)
}

# XXX NOT-POSIX
unixtime () {
    echo $(date +%s)
}

dir_init () {
    local arch=$1
    local r=$(random_number)
    local d=$(date +%Y%m%d)
    local _dir

    if [ "X$is_debug" != "X" ];then
	echo "===> debug on"
	r="debug"
    fi

    base_dir=/var/tmp/nbpkg-build/$d/$arch.$r
    dest_dir=$base_dir/destdir.$arch
    dist_dir=$base_dir/distdir.$arch
    rels_dir=$base_dir/reldir.$arch
    junk_dir=$base_dir/tmpdir.$arch
    done_dir=$done_xxx/$d
    log_dir=$log_base_dir/${vers_date}

    for _dir in $base_dir $dest_dir $dist_dir $rels_dir $junk_dir $done_dir \
			  $log_dir
    do
	test -d $_dir || is_require_download_and_extract=1
	test -d $_dir || mkdir -p $_dir
    done
}

dir_clean () {
    local status=$1
    local name=$(basename $base_dir)
    local time=$(unixtime)

    if [ -d $base_dir ];then
	if [ $status = 0 ];then
	    mv $base_dir $done_dir/done.$name.$time
	    logit dir_clean: moved to $done_dir/done.$name.$time
	else
	    mv $base_dir $done_dir/errr.$name.$time
	    logit dir_clean: moved to $done_dir/errr.$name.$time
	fi
    fi

    (
	cd $done_dir || exit 1
	for x in done* errr*
	do
	    logit "dir_clean: rm -fr $x"
	    rm -fr $x
	done
    )
}


#
# queue
#
queue_add () {
    local name=$1
    local vers=$2
    local type=$3
    local arch=$4

    logit "queue_add: $* (dummy)"

}

queue_del () {
    local name=$1
    local vers=$2
    local type=$3
    local arch=$4

    logit "queue_del: $* (dummy)"
}


#
# get the current version
#
www_get_list () {
    tnftp_www_get_list $1
}

tnftp_www_get_list () {
    local url=$1

    /usr/bin/ftp -o - -V $url					|
	grep href= 						|
	awk -F \" '{print $2}'					|
	sed 's@/$@@'
}

curl_www_get_list () {
    local url=$1

    curl -s $url						|
	grep href= 						|
	awk -F \" '{print $2}'					|
	sed 's@/$@@'
}



www_get_latest_entry () {
    tnftp_www_get_latest_entry $1
}

tnftp_www_get_latest_entry () {
    local url=$1

    /usr/bin/ftp -o - -V $url					|
	grep href= 						|
	awk -F \" '{print $2}'					|
	sed 's@/$@@'						|
	tail -1
}

curl_www_get_latest_entry () {
    local url=$1

    curl -s $url						|
	grep href= 						|
	awk -F \" '{print $2}'					|
	sed 's@/$@@'						|
	tail -1
}

wget_www_get_latest_entry () {
    :
}


#
# download
#
nbdist_download () {
    local arch=$1
    local url=$2
    local t_start t_end tdiff

    if [ "X$is_require_download_and_extract" != "X" ];then
	echo "===> DEBUG: download (first time)"
    else
	echo "===> DEBUG: not require download"
	return
    fi

    logit "download: $arch $url"
    t_start=$(unixtime)
    tnftp_nbdist_download $arch $url
    nbdist_checksum $arch
    t_end=$(unixtime)
    t_diff=$(($t_end - $t_start))
    logit "download: $t_diff sec. arch=$arch"
}

nbdist_checksum () {
    local arch=$1
    local cksum1 cksum2

    cksum1=$junk_dir/nbpkg.cksum1.$arch.$$
    cksum2=$junk_dir/nbpkg.cksum2.$arch.$$

    cd $dist_dir || exit 1

    /usr/bin/cksum -a sha512 *tgz | sort > $cksum1
    sort SHA512 > $cksum2
    cmp $cksum1 $cksum2
    if [ $? != 0 ];then
	logit "checksum: failed arch=$arch"
	diff -ub $cksum1 $cksum2
	queue_add retry $vers_date $type $arch
	exit 1
    else
	logit "checksum: ok arch=$arch"
    fi
}

tnftp_nbdist_download () {
    local arch=$1
    local url=$2
    local _x _list

    cd $dist_dir || exit 1

    # 1. verify
    /usr/bin/ftp -V -o SHA512 $url/SHA512
    if [ $? != 0 ];then
	logit "download: invalid arch=$arch (no SHA512)"
	exit 1
    fi

    # 2. download all entries
    _list=$(www_get_list $url					|
		tr ' ' '\n'					|
		grep '^[a-z]'					)
    for _x in $_list
    do
	/usr/bin/ftp -V -o $_x $url$_x
    done
}


curl_nbdist_download () {
    local arch=$1
    local url=$2
    local _x _list

    cd $dist_dir || exit 1

    # 1. verify
    curl --fail -s -o SHA512 $url/SHA512
    if [ $? != 0 ];then
	logit "download: invalid arch=$arch (no SHA512)"
	exit 1
    fi

    # 2. download all entries
    _list=$(www_get_list $url					|
		tr ' ' '\n'					|
		grep '^[a-z]'					)
    for _x in $_list
    do
	curl -s -o $_x $url$_x
    done
}

wget_nbdist_download () {
    :
}


#
#
#
nbdist_extract () {
    local arch=$1
    local t_start t_end tdiff
    local _x

    if [ "X$is_require_download_and_extract" != "X" ];then
	echo "===> DEBUG: require extraction (first time)"
    else
	echo "===> DEBUG: not require extraction"
	return
    fi


    logit "extract: arch=$arch"
    logit "extract: tar -C $dest_dir -zxpf $dist_dir/{base,...}"
    t_start=$(unixtime)
    for _x in $dist_dir/[a-jl-z]*tgz $dist_dir/kern-GENERIC.tgz
    do
	tar -C $dest_dir -zxpf $_x
    done
    t_end=$(unixtime)
    t_diff=$(($t_end - $t_start))
    logit "extract: $t_diff sec. arch=$arch"
}


#
# run basepkg
#
nbpkg_build_run_basepkg () {
    local arch=$1
    local prog
    local t_start t_end tdiff

    prog="basepkg.sh"
    opt1="--obj $base_dir --releasedir=$rels_dir --machine=$arch"
    opt2="--buildmaster --buildmasterdate $vers_date"
    logit "run_basepkg: $prog"
    t_start=$(unixtime)
    (
	cd $prog_basepkg_dir || exit 1
	pwd
	/bin/sh $prog $opt1 $opt2  pkg
    )
    t_end=$(unixtime)
    t_diff=$(($t_end - $t_start))
    logit "run_basepkg: $t_diff sec. arch=$arch"
}


nbpkg_src_arch () {
    local arch=$1
    local vers_nbpkg=$2
    basename $rels_dir/packages/$vers_nbpkg/[a-z]*
}

nbpkg_src_dir () {
    local arch=$1
    local vers_nbpkg=$2
    local machine_w_arch=$(nbpkg_src_arch $1 $2)
    echo $rels_dir/packages/$vers_nbpkg/$machine_w_arch
}

nbpkg_dst_dir () {
    local arch=$1
    local vers_nbpkg=$2
    echo /pub/www/pub/NetBSD/basepkg/$vers_nbpkg/$arch
}

nbpkg_dst_symlink () {
    local arch=$1
    local vers_nbpkg=$2
    local vers_major=$3
    local machine_w_arch=$(nbpkg_src_arch $1 $2)
    (
	cd /pub/www/pub/NetBSD/basepkg/$vers_major/ || exit 1
	if [ -d $arch -a ! -h $machine_w_arch ];then
	    ln -s $arch $machine_w_arch
	    logit "symlink: $arch == $machine_w_arch"
	fi
    )
}


nbpkg_basepkg_version () {
    ls $rels_dir/packages
}

nbpkg_basepkg_major_version () {
    local v=$(ls $rels_dir/packages)

    c=$(expr $v : '\([0-9]*\.99\)')
    if [ "X$c" != "X" ];then
	echo $c                    # 8.99 (current)
    else
	echo $v | cut -c 1-3       # 8.0  (release, stable)
    fi
}


nbpkg_release_basepkg_packages () {
    local arch=$1

    vers_nbpkg=$(nbpkg_basepkg_version)        # 7.1_STABLE
    vers_major=$(nbpkg_basepkg_major_version)  # 7
    pkg_dir=$(nbpkg_src_dir $arch $vers_nbpkg) # basepkg/.../7.1_STABLE/i386
    www_dir=$(nbpkg_dst_dir $arch $vers_major) # pub/NetBSD/.../7/i386
    test -d $www_dir || mkdir -p $www_dir

    logit "release: $pkg_dir -> $www_dir"
    cd $pkg_dir || exit 1
    /usr/bin/cksum -a sha512 *tgz | sort > SHA512
    mv SHA512 *tgz $www_dir/
    logit "release: arch=$arch at $www_dir/"
    
    # fix symlinks if needed.
    nbpkg_dst_symlink $arch $vers_nbpkg $vers_major
}


############################################################
####################        MAIN        ####################
############################################################

set -u

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

is_debug=${DEBUG:-""}
is_require_download_and_extract=""
type=${1:-stable}
list=${2:-}
case $type in
    stable  ) url_base=$url_base_stable0;;
    stable0 ) url_base=$url_base_stable0;;
    legacy  ) url_base=$url_base_stable1;;
    stable1 ) url_base=$url_base_stable1;;
    current ) url_base=$url_base_current;;
esac
version=$(www_get_latest_entry $url_base)
vers_date=$(echo $version | awk '{print substr($1, 0, 8)}')
list_all=$(www_get_list $url_base$version/				|
		tr ' ' '\n'						|
		grep '^[a-z]'						)

for arch in ${list:-$list_all}
do
    dir_init $arch
    (
	logit "session: start $type $arch $version"
	t_start=$(unixtime)

	# 1. prepare
	nbdist_download $arch $url_base$version/$arch/binary/sets/
	nbdist_extract  $arch

	# 2. go
	nbpkg_build_run_basepkg        $arch
	nbpkg_release_basepkg_packages $arch

	t_end=$(unixtime)
	t_diff=$(($t_end - $t_start))
	logit "session: end $type $arch $version total: $t_diff sec."
    )

    if [ $? != 0 ];then
	queue_add retry $vers_date $type $arch
	dir_clean 1
    	logit "session: ***error*** arch=$arch ended abnormally."
    else
	dir_clean 0
    fi
done

exit 0
