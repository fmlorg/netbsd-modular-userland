# NetBSD modular userland

[[English]](doc/en/nbpkg-build.md)
[[Japanese]](doc/ja/nbpkg-build.md)
for more details. 


## What is this ?

You can update NetBSD userland to the NetBSD stable
by running a command such as
[nbpkg.sh](https://github.com/fmlorg/netbsd-modular-userland/nbpkg-client/bin/nbpkg.sh).
[nbpkg.sh](https://github.com/fmlorg/netbsd-modular-userland/nbpkg-client/bin/nbpkg.sh)
is a shell script used as a client to use **basepkg** packages.
it is a wrapper of [pkgsrc/pkgtools/pkgin](http://pkgin.net/)
and a reference implementation.



## DEMONSTRATION

Just run "nbpkg.sh full-upgrade" on NetBSD 8.0
to upgrade it to the latest NetBSD 8.0 stable.

```
# nbpkg.sh full-upgrade

debug: PKG_PATH  = http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/diff/netbsd-8/i386
debug: PKG_REPOS = http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/diff/netbsd-8/i386

Running install with PRE-INSTALL for pkg_install-20180425.
man/man1/pkg_add.1
   ...
Package pkg_install-20180425 registered in /var/db/pkg/pkg_install-20180425
   ...

Running install with PRE-INSTALL for pkgin-0.11.6.
bin/pkgin
man/man1/pkgin.1
   ...
Package pkgin-0.11.6 registered in /var/db/pkg/pkgin-0.11.6
   ...

Requesting http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/diff/netbsd-8/i386/list-pkg
  0% |                                   |     0        0.00 KiB/s    --:-- ETA
   ...
100% |***********************************|   431      663.87 KiB/s    00:00 ETA
431 bytes retrieved in 00:00 (70.66 KiB/s)
pkgin import /var/db/nbpkg/list-pkg
reading local summary...
processing local summary...
processing remote summary (http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/diff/netbsd-8/i386)...
downloading pkg_summary.gz: ...
calculating dependencies...done.

29 packages to install:
  base-cron-bin-8.0.20181120 base-ext2fs-root-8.0.20181120
  base-mk-share-8.0.20181120 base-netutil-bin-8.0.20181120
  base-netutil-root-8.0.20181120 base-nis-bin-8.0.20181120
  base-sysutil-bin-8.0.20181120 base-sysutil-root-8.0.20181120
  base-util-bin-8.0.20181120 base-util-root-8.0.20181120
  comp-c-include-8.0.20181120 comp-c-lib-8.0.20181120 comp-c-man-8.0.20181120
  comp-c-proflib-8.0.20181120 comp-cron-debug-8.0.20181120
  comp-ext2fs-debug-8.0.20181120 comp-netutil-debug-8.0.20181120
  comp-sys-man-8.0.20181120 comp-sysutil-debug-8.0.20181120
  comp-util-debug-8.0.20181120 etc-sys-etc-8.0.20181120
  man-ext2fs-man-8.0.20181120 man-npf-man-8.0.20181120 man-pf-man-8.0.20181120
  man-sys-man-8.0.20181120 man-sysutil-man-8.0.20181120
  man-util-man-8.0.20181120 text-groff-share-8.0.20181120
  xetc-sys-etc-8.0.20181120

0 to refresh, 0 to upgrade, 29 to install
61M to download, 220M to install

proceed ? [Y/n] y
downloading base-cron-bin-8.0.20181120.tgz ...
    ...
downloading xetc-sys-etc-8.0.20181120.tgz ...
installing base-cron-bin-8.0.20181120...
    ...
installing xetc-sys-etc-8.0.20181120...
pkg_install warnings: 0, errors: 0
reading local summary...
processing local summary...
marking base-cron-bin-8.0.20181120 as non auto-removable
    ...
marking xetc-sys-etc-8.0.20181120 as non auto-removable


# ls /var/db/pkg
base-cron-bin-8.0.20181120              comp-netutil-debug-8.0.20181120
base-ext2fs-root-8.0.20181120           comp-sys-man-8.0.20181120
base-mk-share-8.0.20181120              comp-sysutil-debug-8.0.20181120
base-netutil-bin-8.0.20181120           comp-util-debug-8.0.20181120
base-netutil-root-8.0.20181120          etc-sys-etc-8.0.20181120
base-nis-bin-8.0.20181120               man-ext2fs-man-8.0.20181120
base-sysutil-bin-8.0.20181120           man-npf-man-8.0.20181120
base-sysutil-root-8.0.20181120          man-pf-man-8.0.20181120
base-util-bin-8.0.20181120              man-sys-man-8.0.20181120
base-util-root-8.0.20181120             man-sysutil-man-8.0.20181120
comp-c-include-8.0.20181120             man-util-man-8.0.20181120
comp-c-lib-8.0.20181120                 pkg_install-20180425
comp-c-man-8.0.20181120                 pkgdb.byfile.db
comp-c-proflib-8.0.20181120             pkgin-0.11.6
comp-cron-debug-8.0.20181120            text-groff-share-8.0.20181120
comp-ext2fs-debug-8.0.20181120          xetc-sys-etc-8.0.20181120

```
