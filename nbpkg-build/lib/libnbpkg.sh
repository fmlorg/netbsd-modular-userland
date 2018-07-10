#
# $Id$
# $FML$
#

log_init () {
    local arch=$1
    
    logf=$log_dir/$type.$arch
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
			  $log_dir $queue_dir
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

    mkdir -p $queue_dir/$name/$vers/$type/$arch
    logit "queue_add: $*"
}

queue_del () {
    local name=$1
    local vers=$2
    local type=$3
    local arch=$4

    if [ -d $queue_dir/$name/$vers/$type/$arch ];then
	rmdir $queue_dir/$name/$vers/$type/$arch
    fi
    logit "queue_del: $*"
}

queue_find () {
    local name=$1
    local vers=$2
    local type=$3
    local arch=$4

    if [ -d $queue_dir/$name/$vers/$type/$arch ];then
	echo 1
    else
	echo 0
    fi
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
# nbpgk functions

#
nbpkg_build_assert () {
    local id

    id=$(id -u)

    if [ $id != 0 ];then
	fatal "run this program by root"
    fi

    if [ ! -f $prog_basepkg_dir/basepkg.sh ];then
	fatal "no basepkg.sh ($prog_basepkg_dir/basepkg.sh)"
    fi
}


nbdist_check_ignore () {
    local arch=$1

    case $arch in
	images ) echo 1;exit 0;;
	shared ) echo 1;exit 0;;
	source ) echo 1;exit 0;;
    esac
    
    echo 0
}


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

nbpkg_dst_clean () {
    local dir=$1
    local num
    local list

    cd $dir || exit 1;
    numpkg=$(ls base-sys-root*tgz 2>/dev/null | wc -l | tr -d ' ')

    if [ $numpkg -gt 1 ];then
	list=/var/tmp/list.nbpkg.$$
	find $dir -mtime +7 -name '*tgz' > $list
	num=$(cat $list | wc -l | tr -d ' ')
	if [ $num -gt 0 ];then
	    logit "clean-up $dir ($num old files)"
	    cat $list | xargs rm
	else
	    logit "ignored $dir (no old files)"	
	fi
    else
	logit "ignored $dir (only one revision)"
    fi

    echo ":"	# trick to ignore the function eval after return
    exit 0
}

nbpkg_dst_dir_list_version () {
    ls /pub/www/pub/NetBSD/basepkg
}

nbpkg_dst_dir_list_arch () {
    local vers=$1
    ls /pub/www/pub/NetBSD/basepkg/$vers
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

    # https://wiki.netbsd.org/pkgsrc/intro_to_packaging/
    pkg_info -X              *tgz | gzip -9 > pkg_summary.gz.new
    if [ -s pkg_summary.gz.new ];then mv pkg_summary.gz.new pkg_summary.gz;fi
    if [ ! -s pkg_summary.gz ];then fatal "release: empty pkg_summary.gz";fi

    /usr/bin/cksum -a sha512 *tgz | sort    > SHA512
    if [ ! -s SHA512         ];then fatal "release: empty SHA512"        ;fi
    mv *tgz                   $www_dir/
    mv SHA512 pkg_summary.gz  $www_dir/    # update info after all *.tgz are moved.
    logit "release: arch=$arch at $www_dir/"
    
    # fix symlinks if needed.
    nbpkg_dst_symlink $arch $vers_nbpkg $vers_major
}
