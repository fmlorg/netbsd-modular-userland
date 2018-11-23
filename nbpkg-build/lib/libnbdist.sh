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
	images ) echo 1; exit 0;;
	shared ) echo 1; exit 0;;
	source ) echo 1; exit 0;;
    esac
    
    echo 0
}


#
# utility functions to get the list to download and check the current version.
#

nbdist_get_url_base () {
    local branch=$1
			    
    case $branch in
     netbsd-8 ) echo $url_base_stable8 ;;
    release-8 ) echo $url_base_release8;;
     netbsd-7 ) echo $url_base_stable7 ;;
    release-7 ) echo $url_base_release7;;
     netbsd-6 ) echo $url_base_stable6 ;;
    release-6 ) echo $url_base_release6;;
      current ) echo $url_base_current ;;
    esac
}

nbdist_get_major_version () {
    local branch=$1
			    
    case $branch in
     netbsd-8 ) echo  8.0;;
    release-8 ) echo  8.0;;
     netbsd-7 ) echo  7.0;;
    release-7 ) echo  7.0;;
     netbsd-6 ) echo  6.0;;
    release-6 ) echo  6.0;;
      current ) echo 8.99;;
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
    local  url=$2
    local t_start t_end tdiff

    if [ "X$is_require_download_and_extract" != "X" ];then
	debug_msg "download (first time)"
    else
	debug_msg "not require download"
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
    local  url=$2
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
    _list=$(nbdist_get_list $url				|
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
    local  url=$2
    local _x _list

    cd $dist_dir || exit 1

    # 1. verify
    curl --fail -s -o SHA512 $url/SHA512
    if [ $? != 0 ];then
	logit "download: invalid arch=$arch (no SHA512)"
	exit 1
    fi

    # 2. download all entries
    _list=$(nbdist_get_list $url				|
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
	debug_msg "require extraction (first time)"
    else
	debug_msg "not require extraction"
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
    local   arch=$1
    local branch=$2
    local   vers=$3
    local   list=$4

    _nbdist_ident_listup					|
    _nbdist_ident_canonicalize					>$list
}

# Descriptions: return the list of changed syspkgs names 
#               if the ident based changes are found.
#    Arguments: STR(arch) STR(branch) NUM(vers) STR(diff)
# Side Effects: add the updates into transaction queue if changes are found.
# Return Value: NONE
nbdist_check_ident_changes () {
    local   arch=$1
    local branch=$2
    local   vers=$3
    local _bdiff=$4	# basepkg diff

    # ident database
    # e.g. /var/nbpkg-build/db/ident/netbsd-8/i386 holds the latest ident data
    #	   which will be replaced to the current one if the changes are found.
    local _ibak=$(nbpkg_ident_data_file $arch $branch $vers)
    local _inew=$junk_dir/tmp.ident.new

    if [ ! -s $_ibak ];then
	fatal "nbdist_ident: $_ibak not exist"
    fi

    # 1. create the latest ident data at "$_inew",
    # 2. compare "$_ibak" with "$_inew" to generate ident diff,
    # 3. convert ident diff to the list of basepkg packages "$_bdiff".
    nbdist_get_ident_list $arch $branch $vers $_inew
    if [ -s $_inew ];then
	# _i{bak,new} = ident database
	#      _bdiff = the list of changed basepkg names 
        _nbdist_ident_compare_files        $arch $branch $vers $_ibak $_inew |
	_nbdist_ident_file_to_syspkgs_name $arch $branch $vers	     > $_bdiff
	if [ -s $_bdiff ];then
		
	    # prepare the build database update commits processed
	    # after the basepkg is(are) released successfully.
	    _nbdist_commit_updates  $arch $branch $vers $_bdiff
	    _nbdist_prepare_updates $arch $branch $vers $_ibak $_inew
	else
	    logit "nbdist_ident: no changes arch=$arch"
	fi
    else
	fatal "nbdist_ident: empty output"
    fi

    echo $_bdiff
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
    local   arch=$1
    local branch=$2
    local   vers=$3
    local   _bak=$4
    local   _new=$5

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
    local   arch=$1
    local branch=$2
    local   vers=$3

    local    tmp=$junk_dir/list.sets.basepkg.all
    local    fil=$junk_dir/list.ident.changed
    local  files="$(echo $data_basepkg_dir/*/mi $data_basepkg_dir/*/md*$arch)"

    cat        > $fil
    cat $files > $tmp
    # XXX the exact match of "$1" is required
    awk 'NR == FNR{ c[$1] = $1; next;}c[$1]{print $2}' $fil $tmp	|
    sort 								|
    uniq
}

# (1) _nbdist_commit_updates () 
#     update list of released basepkg packages.
#     e.g. "/var/nbpkg-build/db/basepkg/$branch/$arch".
#
# (2) _nbdist_prepare_updates ()
#     update ident data if basekpkg run succeesfully.
#     e.g. "/var/nbpkg-build/db/ident/$branch/$arch".
#
_nbdist_commit_updates () {
	local         arch=$1
	local       branch=$2
	local         vers=$3
	local basepkg_diff=$4
	local   basepkg_db=$(nbpkg_basepkg_data_file $arch $branch $vers)

	# update released basepkg database
	#    each line: base-sys-root 20181101
	#               used as e.g. "@sysdep base-sys-root>=20181101"
	# XXX $basepkg_diff contains only basepkg names
	while read -r pkg
	do
		logit "nbdist_ident: $pkg changed arch=$arch"
		echo "$pkg $vers"  >> $basepkg_db
	done < $basepkg_diff

}

_nbdist_prepare_updates () {
	local         arch=$1
	local       branch=$2
	local         vers=$3
	local    ident_bak=$4
	local    ident_new=$5
	local         hook=$(nbpkg_build_path_session_end_hook)

	cat > $hook <<__EOF__
	# transaction: it should be eval-ed after the session successed.

	# 1.   ident database: overwritten
	cp -p $ident_new $ident_bak
__EOF__
}
