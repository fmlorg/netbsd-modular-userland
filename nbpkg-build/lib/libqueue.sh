#       NAME: libqueue.sh
# DESCIPTION: utitity functions to handle queue.
#             

queue_add () {
    local       name=$1
    local       arch=$2
    local     branch=$3
    local build_date=$4

    mkdir -p $queue_dir/$name/$build_date/$branch/$arch
    logit "queue_add: $*"
}

queue_del () {
    local       name=$1
    local       arch=$2
    local     branch=$3
    local build_date=$4
    
    if [ -d $queue_dir/$name/$build_date/$branch/$arch ];then
	rmdir $queue_dir/$name/$build_date/$branch/$arch
    fi
    logit "queue_del: $*"
}

queue_find () {
    local       name=$1
    local       arch=$2
    local     branch=$3
    local build_date=$4
    
    if [ -d $queue_dir/$name/$build_date/$branch/$arch ];then
	echo 1
    else
	echo 0
    fi
}
