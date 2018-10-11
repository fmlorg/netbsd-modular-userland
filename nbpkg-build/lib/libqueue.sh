#       NAME: libqueue.sh
# DESCIPTION: utitity functions to handle queue.
#             

queue_add () {
    local name=$1
    local arch=$2
    local type=$3
    local vers=$4

    mkdir -p $queue_dir/$name/$vers/$type/$arch
    logit "queue_add: $*"
}

queue_del () {
    local name=$1
    local arch=$2
    local type=$3
    local vers=$4
    
    if [ -d $queue_dir/$name/$vers/$type/$arch ];then
	rmdir $queue_dir/$name/$vers/$type/$arch
    fi
    logit "queue_del: $*"
}

queue_find () {
    local name=$1
    local arch=$2
    local type=$3
    local vers=$4
    
    if [ -d $queue_dir/$name/$vers/$type/$arch ];then
	echo 1
    else
	echo 0
    fi
}
