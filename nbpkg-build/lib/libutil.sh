#
# $Id$
# $FML$
#


logit () {
    local msg="$*"
    local logf
    local name

    echo   "$msg"

    if [ -w $logf ];then
	echo   "${name}: $msg" >> $logf
    fi

    name=$(basename $0)    
    logger "${name}: $msg"
}


fatal () {
    logit "***fatal: $*"
    exit 1
}


random_number () {
    echo $(od -An -N 2 -t u2 /dev/urandom)
}


# XXX NOT-POSIX
unixtime () {
    echo $(date +%s)
}
