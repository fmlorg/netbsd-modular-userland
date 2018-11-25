#
# $Id$
# $FML$
#

nbpkg_log_init () {
    local   arch=$1
    local branch=$2
    local b_date=$3	# build date at nyftp.netbsd.org
    
    logf=$log_dir/$branch.$arch
}

nbpkg_dir_init () {
    local   arch=$1
    local branch=$2
    local b_date=$3	# build date at nyftp.netbsd.org
    local r=$(random_number)
    local d=$(date +%Y%m%d)
    local _dir _debug_dir

    if [ "X$is_debug" != "X" ];then
	_debug_dir=/var/tmp/nbpkg-debug
    fi

    # temporary area
    base_dir=${_debug_dir:-/var/tmp/nbpkg-build/$b_date/$arch.$r}
    dest_dir=$base_dir/destdir.$arch
    dist_dir=$base_dir/distdir.$arch
    rels_dir=$base_dir/reldir.$arch
    junk_dir=$base_dir/tmpdir.$arch
    done_dir=/var/tmp/nbpkg-build-done/$b_date
    
    # persistnet area
     log_dir=$log_base_dir/${b_date}
    
    for _dir in $base_dir $dest_dir $dist_dir $rels_dir $junk_dir $done_dir \
			  $log_dir $queue_dir $db_ident_dir $db_basepkg_dir
    do
	test -d $_dir || is_require_download_and_extract=1
	test -d $_dir || mkdir -p $_dir
    done
}

nbpkg_ident_data_dir () {
    local   arch=$1
    local branch=$2

    local   _dir=$db_ident_dir/$branch
    test -d $_dir || mkdir -p $_dir 

    echo $_dir
}

nbpkg_ident_data_file () {
    local   arch=$1
    local branch=$2
    local   _dir=$(nbpkg_ident_data_dir $arch $branch)
    
    echo $_dir/$arch
}

nbpkg_basepkg_data_dir () {
    local   arch=$1
    local branch=$2

    local   _dir=$db_basepkg_dir/$branch
    test -d $_dir || mkdir -p $_dir

    echo $_dir
}

nbpkg_basepkg_data_file () {
    local   arch=$1
    local branch=$2
    local   _dir=$(nbpkg_basepkg_data_dir $arch $branch)
    
    echo $_dir/$arch
}

nbpkg_basepkg_get_sets_lists () {
    local   arch=$1
    local branch=$2

    echo $basepkg_list_dir/*/mi $basepkg_list_dir/*/md*$arch
}

nbpkg_data_backup_dir () {
    local   arch=$1
    local branch=$2
    local b_date=$3
    local   type=$4   # "ident" or "basepkg"

    # e.g.      /var/nbpkg-data/backups/ident/netbsd-8/
    local   _dir=$nbpkg_data_backup_dir/$type/$branch
    test -d $_dir || mkdir -p $_dir

    echo $_dir
}

nbpkg_data_backup () {
    local   arch=$1
    local branch=$2
    local b_date=$3
    local   type=$4   # ident basepkg
    local   _src=$5   # i386 amd64 ...
    local   file=$(basename $_src)
    local   _dir=$(nbpkg_data_backup_dir $arch $branch $b_date $type)
    local   _msg="updated-$b_date"

    echo DEBUG: cp -p $_src $_dir/$file
    cp -p $_src $_dir/$file
    (   
	cd $_dir || exit 1

	/usr/bin/ci  -q -f  -u -t-$_msg -m$_msg $file
	/usr/bin/rcs -q -kb -U                  $file
	/usr/bin/co  -q -f  -u                  $file
    )

    if [ $? != 0 ];then
	logit "data_backup: failed to backup config $src"
    fi
}

nbpkg_dir_clean () {
    local status=$1
    local name=$(basename $base_dir)
    local time=$(unixtime)

    if [ -d $base_dir ];then
	if [ $status = 0 ];then
	    mv $base_dir $done_dir/done.$name.$time
	    logit nbpkg_dir_clean: moved to $done_dir/done.$name.$time
	else
	    mv $base_dir $done_dir/errr.$name.$time
	    logit nbpkg_dir_clean: moved to $done_dir/errr.$name.$time
	fi
    fi

    (
	cd $done_dir || exit 1
	for x in done* errr*
	do
	    logit "nbpkg_dir_clean: rm -fr $x"
	    rm -fr $x
	done
    )
}


#
# nbpgk functions
#

# return 8.0.20181101
nbpkg_build_id () {
    local         arch=$1
    local       branch=$2
    local       b_date=$3
    local  _vers_major=$(nbdist_get_major_version $branch)

    echo "$_vers_major.$b_date"
}

nbpkg_build_assert () {
    local id

    id=$(id -u)

    if [ $id != 0 ];then
	fatal "run this program by root"
    fi

    if [ ! -f $basepkg_base_dir/basepkg.sh ];then
	fatal "no basepkg.sh ($basepkg_base_dir/basepkg.sh)"
    fi
}


#
# HOOKS
#
nbpkg_build_path_session_start_hook () {
	echo $junk_dir/nbpkg_build_session_start_hook
}


nbpkg_build_path_session_end_hook () {
	echo $junk_dir/nbpkg_build_session_end_hook
}


nbpkg_build_run_session_start_hook () {
	run_hook $(nbpkg_build_path_session_start_hook)
}


nbpkg_build_run_session_end_hook () {
	run_hook $(nbpkg_build_path_session_end_hook)
}


#
# generate configuration to pass as the argument in running basepkg.sh.
#

_nbpkg_build_gen_list_all_maint () {
    local   arch=$1
    local branch=$2
    local   mode=$3
    local   _src=$(nbpkg_basepkg_data_file $arch $branch)
    local   _dst=$junk_dir/list.basepkg.all.$mode

    debug_msg "list_all: mode=$mode cp -p $_src $_dst"
    cp -p $_src $_dst
    echo $_dst
}

_nbpkg_build_gen_list_all_all () {
    local   arch=$1
    local branch=$2
    local   mode=$3
    local   _src=$(nbpkg_basepkg_data_file $arch $branch)
    local   _dst=$junk_dir/list.basepkg.all.$mode
    local   _tmp=$junk_dir/tmp.list.basepkg.all.$mode.$$
    local   b_id=$(nbdist_get_major_build_id $branch)
    local  files="$(nbpkg_basepkg_get_sets_lists $arch $branch)"

    debug_msg "list_all: mode=$mode $_src + faked release => $_dst"

    cat $files							|
    grep -v obsolete						|
    awk '/^#/{ next;}						\
	$2 ~ /[a-z]+-[a-z]+-[a-z]+/{print $2}'			|
    sort							|
    uniq							|
    awk -v id=$b_id '{printf("%s\t%s\n", $1, id)}' 		>  $_dst
    cat  $_src							>> $_dst

    echo $_dst
}

_nbpkg_build_gen_list_all () {
    local   arch=$1
    local branch=$2
    local   mode=$3

    if [ "X$mode" = "Xmaint" ];then
	_nbpkg_build_gen_list_all_maint $arch $branch $mode
    elif [ "X$mode" = "Xall" ];then
	_nbpkg_build_gen_list_all_all   $arch $branch $mode
    else
	fatal "gen_list_all: unknown mode=$mode"
    fi
}

_nbpkg_build_basepkg_conf_path () {
    local   arch=$1
    local branch=$2
    local   mode=$3

    printf "%s/basepkg-%s.conf" $junk_dir $mode
}

nbpkg_build_gen_basepkg_conf () {
    local   arch=$1
    local branch=$2
    local b_date=$3
    local    new=$4
    local   b_id=$(nbpkg_build_id $arch $branch $b_date)
    local _pkg

    # filter
    local filter=$junk_dir/list.basepkg.filter
    for _pkg in $(cat $new)
    do
	echo $_pkg'$' >> $filter
    done 

    for mode in maint all
    do
	_conf=$(_nbpkg_build_basepkg_conf_path $arch $branch $mode)
	_list=$(_nbpkg_build_gen_list_all      $arch $branch $mode)

        cat > $_conf <<_EOF_

      nbpkg_build_list_all=$_list

      nbpkg_build_list_new=$new
   nbpkg_build_list_filter=$filter

          nbpkg_build_date=$b_date
            nbpkg_build_id=$b_id
    
_EOF_

   done
}


#
# run basepkg
#
nbpkg_build_run_basepkg () {
    local   arch=$1
    local branch=$2
    local   mode=$3
    local   conf=$(_nbpkg_build_basepkg_conf_path $arch $branch $mode)
    local prog
    local t_start t_end t_diff

    prog="basepkg.sh"
    opt1="--obj $base_dir --releasedir=$rels_dir --machine=$arch"
    opt2="--enable-nbpkg-build --with-nbpkg-build-config=$conf"
    logit "run_basepkg: $prog"
    t_start=$(unixtime)
    (
	cd $basepkg_base_dir || exit 1
	pwd
	/bin/sh $prog $opt1 $opt2  pkg
    )
    t_end=$(unixtime)
    t_diff=$(($t_end - $t_start))
    logit "run_basepkg: $t_diff sec. arch=$arch"
}


nbpkg_src_arch () {
    local       arch=$1
    local basepkg_id=$2
    basename $rels_dir/packages/$basepkg_id/[a-z]*
}

nbpkg_src_dir () {
    local       arch=$1
    local basepkg_id=$2
    local machine_w_arch=$(nbpkg_src_arch $arch $basepkg_id)
    echo $rels_dir/packages/$basepkg_id/$machine_w_arch
}

nbpkg_dst_dir () {
    local   arch=$1
    local branch=$2
    local   mode=$3

    echo $www_base_dir/$branch/$arch/$mode
}

nbpkg_dst_symlink () {
    local       arch=$1
    local     branch=$2
    local basepkg_id=$3

    local machine_w_arch=$(nbpkg_src_arch $arch $basepkg_id)
    (
	cd $www_base_dir/$branch/ || exit 1
	if [ "X$arch" != "X$machine_w_arch" ];then
	    if [ -d $arch -a ! -h $machine_w_arch ];then
		ln -s $arch $machine_w_arch
		logit "symlink: $arch == $machine_w_arch"
	    fi
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

# XXX "tail ..." is useful only in debug mode to avoid duplication.
# XXX "tail ..." is not needed in norma operation.
nbpkg_basepkg_version () {
    ls $rels_dir/packages				|
    tail -1
}

nbpkg_release_basepkg_packages () {
    local   arch=$1
    local branch=$2
    local   mode=$3

    basepkg_id=$(nbpkg_basepkg_version)          # 8.0.20181101
    pkg_dir=$(nbpkg_src_dir $arch $basepkg_id)   # $rels_dir/.../8.0.20181101/
    www_dir=$(nbpkg_dst_dir $arch $branch $mode) # $WWW/basepkg/netbsd-8/amd64
    test -d $www_dir || mkdir -p $www_dir

    logit "release: $pkg_dir -> $www_dir"
    cd $pkg_dir || exit 1

    # 1. move generated packages "*.tgz" to $www_dir, 
    #    so, old and new packages updated from the official release.
    mv *tgz                   $www_dir/

    # 2. generate list-pkg, SHA512 and pkg_summary.gz for all packages
    #    in $www_dir.
    cd $www_dir || exit 1

    # https://wiki.netbsd.org/pkgsrc/intro_to_packaging/
    pkg_info -X              *tgz | gzip -9	> pkg_summary.new
    if [ ! -s pkg_summary.new ];then fatal "release: empty pkg_summary.gz" ;fi
    if [   -s pkg_summary.new ];then    mv pkg_summary.new pkg_summary.gz  ;fi

    /usr/bin/cksum -a sha512 *tgz | sort	> SHA512.new
    if [ ! -s SHA512.new     ];then fatal "release: empty SHA512"          ;fi
    if [   -s SHA512.new     ];then    mv    SHA512.new   SHA512           ;fi

    /bin/ls *.tgz 					|
    sed 's/-[0-9]*.[0-9]*.[0-9]*.tgz//'			|
    sort						|
    uniq 						> list-pkg.new 
    if [ ! -s list-pkg.new   ];then fatal "release: empty list-pkg"        ;fi
    if [   -s list-pkg.new   ];then    mv  list-pkg.new   list-pkg         ;fi

    logit "release: arch=$arch at $www_dir/"
    
    # fix symlinks if needed.
    nbpkg_dst_symlink $arch $branch $basepkg_id
}
