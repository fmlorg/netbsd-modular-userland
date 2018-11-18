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

nbdist_get_url_base () {
    local branch=$1
			    
    case $branch in
      stable8 ) echo $url_base_stable8;;
      stable  ) echo $url_base_stable8;;
     netbsd-8 ) echo $url_base_stable8;;
    release-8 ) echo $url_base_release8;;
      stable7 ) echo $url_base_stable7;;
     netbsd-7 ) echo $url_base_stable7;;
    release-7 ) echo $url_base_release7;;
      legacy  ) echo $url_base_stable6;;
      stable6 ) echo $url_base_stable6;;
     netbsd-6 ) echo $url_base_stable6;;
    release-6 ) echo $url_base_release6;;
      current ) echo $url_base_current;;
    esac
}


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
	grep '^20'						| # Y2100 ;D
	tail -1
}

_curl_nbdist_get_latest_entry () {
    local url=$1

    curl -s $url						|
	grep href= 						|
	awk -F \" '{print $2}'					|
	sed 's@/$@@'						|
	grep '^20'						| # Y2100 ;D
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
    _url=$(echo $url | sed -e s/ftp.netbsd.org/ftp.jaist.ac.jp/g)
    /usr/bin/ftp -V -o SHA512 $_url/SHA512
    if [ $? != 0 ];then
	logit "download: invalid arch=$arch (no SHA512)"
	exit 1
    fi

    # 2. download all entries
    _list=$(nbdist_get_list $url					|
		tr ' ' '\n'					|
		grep '^[a-z]'					)
    # XXX dirty hack: we use JAIST for official release binaries (only)
    #                 to speed up the download (but FASTLY for daily build).
    _url=$(echo $url | sed -e s/ftp.netbsd.org/ftp.jaist.ac.jp/g)
    for _x in $_list
    do
	/usr/bin/ftp -V -o $_x $_url$_x
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

    # XXX "sort | uniq" added to avoid the weired bug
    # XXX  (duplicated entries in the checksum e.g. SHA512 of *arm).
    /usr/bin/cksum -a sha512 *tgz | sort | uniq > $cksum1
    sort SHA512 | uniq > $cksum2
    cmp $cksum1 $cksum2
    if [ $? != 0 ];then
	logit "checksum: failed arch=$arch"
	diff -ub $cksum1 $cksum2
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
    # XXX disabled /netbsd extraction
    #     1. kern-GENERIC.tgz does not exist in some ports. 
    #     2. our hooked basepkg does not generate the kernel package now.
    # for _x in $dist_dir/[a-jl-z]*tgz $dist_dir/kern-GENERIC.tgz
    for _x in $dist_dir/[a-jl-z]*tgz
    do
	tar -C $dest_dir -zxpf $_x
    done
    t_end=$(unixtime)
    t_diff=$(($t_end - $t_start))
    logit "extract: $t_diff sec. arch=$arch"
}



#
# IDENT BASED TRACE
#

nbdist_get_ident_list () {
    local arch=$1
    local type=$2
    local vers=$3
    local list=$4

    _nbdist_ident_listup                                                |
    _nbdist_ident_canonicalize                                          >$list
}

# Descriptions: return the list of changed syspkgs names 
#               if the ident based changes are found.
#    Arguments: STR(arch) STR(type) NUM(vers) STR(diff)
# Side Effects: add the updates into transaction queue if changes are found.
# Return Value: NONE
nbdist_check_ident_changes () {
    local arch=$1
    local type=$2
    local vers=$3
    local diff=$4

    # e.g. /var/nbpkg-build/db/ident/netbsd-8/i386 holds the latest ident data
    #	   which will be replaced to the current one if the changes are found.
    local bak=$(_nbdist_ident_data_file $arch $type $vers)
    local new=$junk_dir/ident.tmp.$type.$arch.$vers.$$

    if [ ! -s $bak ];then
	fatal "nbdist_ident: $bak not exist"
    fi

    nbdist_get_ident_list $arch $type $vers $new
    if [ -s $new ];then
	# diff = the list of changed syspkgs names 
        _nbdist_ident_compare_files        $arch $type $vers $bak $new	|
	_nbdist_ident_file_to_syspkgs_name $arch $type $vers		>$diff
	if [ -s $diff ];then
	    cat $diff							|
	    while read _pkg 
	    do
		logit "nbdist_ident: $_pkg changed arch=$arch"
	    done

	    # prepare the build database update commits processed
	    # after the basepkg is(are) released successfully.
	    _nbdist_defer_commit_updates $arch $type $vers $bak $new $diff 
	else
	    logit "nbdist_ident: no changes arch=$arch"
	fi
    else
	fatal "nbdist_ident: empty output"
    fi

    echo $diff
}

_nbdist_ident_data_dir () {
    local arch=$1
    local type=$2
    local vers=$3

    echo $db_ident_dir/$type
}

_nbdist_ident_data_file () {
    local arch=$1
    local type=$2
    local vers=$3
    local _dir=$(_nbdist_ident_data_dir $arch $type $vers)
    
    echo $_dir/$arch
}

_nbdist_ident_listup () {
    (
	cd $dest_dir || fatal "cannot chdir \$dest_dir"
	find . -type f -exec ident {} \;  2>&1
    )
}


_nbdist_ident_canonicalize () {
    awk '{								\
    if ($1 != "$NetBSD:" && match($1, "/")){ sub(":",""); name = $1;}	\
    if ($1 == "$NetBSD:"){ printf("%-50s %-20s %s\n", name, $2, $3)}	\
    }'							    		|
    sort -T /var/tmp
}


# return the list of changed files not "syspkgs name"
_nbdist_ident_compare_files () {
    local arch=$1
    local type=$2
    local vers=$3
    local _bak=$4
    local _new=$5

    diff -ub $_bak $_new						|
    egrep '^\-|^\+'							|
    sed 's/^.//'							|
    sed 's@^/@./@'							|
    awk '{print $1}'							|
    grep /								|
    sort 								|
    uniq
}
 

# convert the list of changed files to "syspkgs name"
_nbdist_ident_file_to_syspkgs_name () {
    local arch=$1
    local type=$2
    local vers=$3

    local    tmp=$junk_dir/list.syspkgs
    local    fil=$junk_dir/list.filter
    local  files="$(echo $data_basepkg_dir/*/mi $data_basepkg_dir/*/md*$arch)"

    cat        > $fil
    cat $files > $tmp
    # XXX the exact match of "$1" is required
    awk 'NR == FNR{ c[$1] = $1; next;}c[$1]{print $2}' $fil $tmp	|
    sort 								|
    uniq
}


_nbdist_basepkg_data_dir () {
    local arch=$1
    local type=$2
    local vers=$3

    echo $db_basepkg_dir/$type
}

_nbdist_basepkg_data_file () {
    local arch=$1
    local type=$2
    local vers=$3
    local _dir=$(_nbdist_basepkg_data_dir $arch $type $vers)
    
    echo $_dir/$arch
}


# XXX transaction queue: commit it after this process succeeded.
# (1) add syspkgs name list passed to "basepkg.sh ..." to build.
#     e.g. "/var/nbpkg-build/db/basepkg/$branch/$arch".
# (2) update ident data
#     e.g. "/var/nbpkg-build/db/ident/$branch/$arch".
#     
_nbdist_defer_commit_updates () {
	local         arch=$1
	local         type=$2
	local         vers=$3
	local    ident_bak=$4
	local    ident_new=$5
	local basepkg_diff=$6
	local   basepkg_db=$(_nbdist_basepkg_data_file $arch $type $vers)
	local         hook=$(nbpkg_build_path_session_end_hook)

	cat >> $hook <<__EOF__
	# transaction: it should be eval-ed after the session successed.

	# 1.   ident database: overwritten
	cp -p $ident_new $ident_bak

	# 2. basepkg database: append the rebuilt packages
	#    each line: base-sys-root 20181101
	#               used as e.g. "@sysdep base-sys-root>=20181101" 
	cat $basepkg_diff >> $basepkg_db

__EOF__
}
