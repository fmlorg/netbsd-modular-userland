#
# global variables (a lot of variables are initialized with the dummy value)
#

# fundamental URL
url_base_stable8=http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-8/
url_base_stable7=http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-7/
url_base_stable6=http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-6/
url_base_current=http://nycdn.netbsd.org/pub/NetBSD-daily/HEAD/

url_base_release6=http://ftp.iij.ad.jp/pub/NetBSD/NetBSD-6.0/
url_base_release7=http://ftp.iij.ad.jp/pub/NetBSD/NetBSD-7.0/
url_base_release8=http://ftp.iij.ad.jp/pub/NetBSD/NetBSD-8.0/

# fundamenal DIR
prog_basepkg_dir=/var/nbpkg/dist/basepkg
nbpkg_base_dir=/var/nbpkg

# working directory
base_dir=$nbpkg_base_dir/work/base.$$
dist_dir=$nbpkg_base_dir/work/dist.$$
dest_dir=$nbpkg_base_dir/work/dest.$$
rels_dir=$nbpkg_base_dir/work/rels.$$
junk_xxx=/var/tmp/nbpkg-build-junk
done_xxx=/var/tmp/nbpkg-build-done

# database
ident_dir=$nbpkg_base_dir/db/ident

# queue
queue_dir=$nbpkg_base_dir/queue

# log
log_base_dir=$nbpkg_base_dir/log
log_dir=/var/tmp			# dummy
logf=/var/tmp/log.nbpkg-build		# dummy

# web directory released publicly
www_dir=/var/tmp/www			# dummy
