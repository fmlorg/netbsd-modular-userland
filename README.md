# NetBSD modular userland

[[English]](doc/en/nbpkg-index.md)
[[Japanese]](doc/ja/nbpkg-index.md)
for more details. 

Latest Release: v0.3.0 (2018/12/01)
+ v0.3.0 support release mode for "nbpkg.sh -a" which enables bottom up build.
         It means you can build your own NetBSD from the minimum installation.

[[*HISTORY*]](doc/en/history.md)

## What is this ?

You can update NetBSD userland to the NetBSD stable
by running a command such as
[nbpkg.sh](https://github.com/fmlorg/netbsd-modular-userland/nbpkg-client/bin/nbpkg.sh).
[nbpkg.sh](https://github.com/fmlorg/netbsd-modular-userland/nbpkg-client/bin/nbpkg.sh)
is a shell script used as a client to use 
**[basepkg](https://github.com/user340/basepkg)**
packages.
it is a wrapper of [pkgsrc/pkgtools/pkgin](http://pkgin.net/)
and a reference implementation.



## DEMONSTRATION

Just run "nbpkg.sh full-upgrade" on NetBSD 8.0
to upgrade it to the latest NetBSD 8.0 stable.

CAUTION: To avoid unexpected critical situation, currently
"full-upgrade" do not upgrade kernel and /etc/. 
If you update "/etc/", do "nbpkg.sh install ETC-PACK-AGE" explicitly.

```
# nbpkg.sh full-upgrade

debug: PKG_PATH  = http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/netbsd-8/i386/maint
debug: PKG_REPOS = http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/netbsd-8/i386/maint

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

Requesting http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/netbsd-8/i386/maint/pkg_list2upgrade
  0% |                                   |     0       0.00 KiB/s    --:-- ETA
100% |***********************************|   435     967.66 KiB/s    00:00 ETA
435 bytes retrieved in 00:00 (608.60 KiB/s)
pkgin import /var/db/nbpkg/pkg_list2upgrade
reading local summary...
processing local summary...
processing remote summary (http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/netbsd-8/i386/maint)...
downloading pkg_summary.gz: ...
calculating dependencies...done.

29 packages to install:
  base-cron-bin-8.0.20181123 base-ext2fs-root-8.0.20181123
  base-mk-share-8.0.20181123 base-netutil-bin-8.0.20181123
  base-netutil-root-8.0.20181123 base-nis-bin-8.0.20181123
  base-sysutil-bin-8.0.20181126 base-sysutil-root-8.0.20181123
  base-util-bin-8.0.20181123 base-util-root-8.0.20181123
  comp-c-include-8.0.20181123 comp-c-lib-8.0.20181129 comp-c-man-8.0.20181123
  comp-c-proflib-8.0.20181129 comp-cron-debug-8.0.20181123
  comp-ext2fs-debug-8.0.20181123 comp-netutil-debug-8.0.20181123
  comp-sys-man-8.0.20181123 comp-sysutil-debug-8.0.20181126
  comp-util-debug-8.0.20181123 man-ext2fs-man-8.0.20181123
  man-netutil-man-8.0.20181126 man-npf-man-8.0.20181123 man-pf-man-8.0.20181123
  man-sys-man-8.0.20181123 man-sysutil-man-8.0.20181123
  man-util-man-8.0.20181123 text-groff-share-8.0.20181123
  xetc-sys-etc-8.0.20181123

0 to refresh, 0 to upgrade, 29 to install
62M to download, 221M to install

proceed ? [Y/n] y
downloading base-cron-bin-8.0.20181123.tgz ...
    ...
installing base-cron-bin-8.0.20181123...
    ...
pkg_install warnings: 0, errors: 0
reading local summary...
processing local summary...
    ...
marking xetc-sys-etc-8.0.20181123 as non auto-removable


# ls var/db/pkg
base-cron-bin-8.0.20181123              comp-netutil-debug-8.0.20181123
base-ext2fs-root-8.0.20181123           comp-sys-man-8.0.20181123
base-mk-share-8.0.20181123              comp-sysutil-debug-8.0.20181126
base-netutil-bin-8.0.20181123           comp-util-debug-8.0.20181123
base-netutil-root-8.0.20181123          man-ext2fs-man-8.0.20181123
base-nis-bin-8.0.20181123               man-netutil-man-8.0.20181126
base-sysutil-bin-8.0.20181126           man-npf-man-8.0.20181123
base-sysutil-root-8.0.20181123          man-pf-man-8.0.20181123
base-util-bin-8.0.20181123              man-sys-man-8.0.20181123
base-util-root-8.0.20181123             man-sysutil-man-8.0.20181123
comp-c-include-8.0.20181123             man-util-man-8.0.20181123
comp-c-lib-8.0.20181129                 pkg_install-20180425
comp-c-man-8.0.20181123                 pkgdb.byfile.db
comp-c-proflib-8.0.20181129             pkgin-0.11.6
comp-cron-debug-8.0.20181123            text-groff-share-8.0.20181123
comp-ext2fs-debug-8.0.20181123          xetc-sys-etc-8.0.20181123
```
