#       NAME: libnbdist.sh
# DESCIPTION: utitity functions to handle NetBSD distribution.
#             These functions are used to download, verity the checksum,
#             


#
# configurations
#
nbdist_check_ignore () {
    local arch=$1

    case $arch in
	images ) echo 1;exit 0;;
	shared ) echo 1;exit 0;;
	source ) echo 1;exit 0;;
    esac
    
    echo 0
}


#
# utility functions to get the list to download and check the current version.
#
nbdist_get_list () {
    _tnftp_nbdist_get_list $1
}

_tnftp_nbdist_get_list () {
    local url=$1

    /usr/bin/ftp -o - -V $url					|
	grep href= 						|
	awk -F \" '{print $2}'					|
	sed 's@/$@@'
}

_curl_nbdist_get_list () {
    local url=$1

    curl -s $url						|
	grep href= 						|
	awk -F \" '{print $2}'					|
	sed 's@/$@@'
}



nbdist_get_latest_entry () {
    _tnftp_nbdist_get_latest_entry $1
}

_tnftp_nbdist_get_latest_entry () {
    local url=$1

    /usr/bin/ftp -o - -V $url					|
	grep href= 						|
	awk -F \" '{print $2}'					|
	sed 's@/$@@'						|
	tail -1
}

_curl_nbdist_get_latest_entry () {
    local url=$1

    curl -s $url						|
	grep href= 						|
	awk -F \" '{print $2}'					|
	sed 's@/$@@'						|
	tail -1
}

_wget_nbdist_get_latest_entry () {
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
    _tnftp_nbdist_download $arch $url
    nbdist_checksum $arch
    t_end=$(unixtime)
    t_diff=$(($t_end - $t_start))
    logit "download: $t_diff sec. arch=$arch"
}


_tnftp_nbdist_download () {
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
    _list=$(nbdist_get_list $url					|
		tr ' ' '\n'					|
		grep '^[a-z]'					)
    for _x in $_list
    do
	/usr/bin/ftp -V -o $_x $url$_x
    done
}


_curl_nbdist_download () {
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
    _list=$(nbdist_get_list $url					|
		tr ' ' '\n'					|
		grep '^[a-z]'					)
    for _x in $_list
    do
	curl -s -o $_x $url$_x
    done
}

_wget_nbdist_download () {
    :
}


#
# checksum
#

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
	queue_add retry $arch $type $vers_date
	exit 1
    else
	logit "checksum: ok arch=$arch"
    fi
}


#
# extract
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
