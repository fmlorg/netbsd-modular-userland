#
# $Id$
# $FML$
#


logit () {
    local msg="$*"
    local name=$(basename $0)

    if [ -w $logf ];then
	echo   "${name}: $msg" >> $logf
    fi
    logger -t $name "$msg"
}


fatal () {
    logit "***fatal: $*"
    exit 1
}


debug_msg () {
    echo "===> DEBUG: $*" 1>&2    
}


random_number () {
    echo $(od -An -N 2 -t u2 /dev/urandom)
}


# XXX NOT-POSIX
unixtime () {
    echo $(date +%s)
}


rcs_backup () {
    local file="$1"
    local _msg="${2:-dummy_msg}"

    /usr/bin/ci  -q -f  -u -t-"$_msg" -m"$_msg" $file
    /usr/bin/rcs -q -kb -U                      $file
    /usr/bin/co  -q -f  -u                      $file
}


run_hook () {
    local hook=$1

    if [ -f $hook ];then
	logit "run_hook: run $hook"
	(
	    . $hook
	)
        if [ $? != 0 ];then
	    fatal "run_hook: failed: $hook"
        fi
    fi
}
