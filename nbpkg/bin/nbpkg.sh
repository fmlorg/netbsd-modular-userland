#!/bin/sh

netbsd_resolve_version () {
    /usr/bin/uname -r
}    

netbsd_resolve_machine_and_arch () {
    local machine=$(/usr/bin/uname -m)	
    local platform=$(/usr/bin/uname -p)

    if [ "X$machine" != "X$platform" ];then
	echo $machine-$platform
    else
	echo $machine
    fi

}


usage () {
    echo "USAGE: $0 [-h] ..."
}


#
# CONFIG
#
rel=$(netbsd_resolve_version)
arch=$(netbsd_resolve_machine_and_arch)
host=basepkg.netbsd.fml.org
PKG_PATH=http://$host/pub/NetBSD/basepkg/$rel/$arch/
export PKG_PATH

prog_add=/usr/sbin/pkg_add
prog_del=/usr/sbin/pkg_delete
pkgdir=/var/db/basepkg
#
# CONFIG END
#


#
# MAIN
#

# debug
echo PKG_PATH=$PKG_PATH
echo $prog_del -K $pkgdir -v games-games-catman
     $prog_del -K $pkgdir -v games-games-catman
echo $prog_add -K $pkgdir -v games-games-catman
     $prog_add -K $pkgdir -v games-games-catman


case $1 in
    update  )                      ;;
    upgrade )                      ;;
    help | -h | \?  ) usage; exit 1;;
    *               ) usage; exit 1;;
esac

exit 0;
