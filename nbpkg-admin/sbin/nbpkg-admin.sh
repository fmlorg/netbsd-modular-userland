#!/bin/sh
#
# Copyright (C) 2019 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under 2-Clause BSD License.
#   https://opensource.org/licenses/BSD-2-Clause
#
# mailto: fukachan@fml.org
#    web: http://www.fml.org/
#
# $FML$
# $Revision$
#        NAME: nbpkg-admin.sh
# DESCRIPTION:
# CODINGSTYLE: POSIX compliant (checked by running "bash --posix" this script)
#

set -u

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

usage () {
    echo "Usage: $0 [enable|disable]";
    exit 1;
}

preempt="/tmp/.preempt.nbpkg.stop.all"

case $1 in 
	 enable) rm -v $preempt;;
	disable) touch $preempt;;
	      *)          usage;;
esac

exit 0
