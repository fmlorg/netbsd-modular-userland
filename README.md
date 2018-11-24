# NetBSD modular userland *ident based package creation* 

[English](doc/ja/nbpkg-build.md)
[Japanese](doc/ja/nbpkg-build.md)
for more details. 


## What is this ?

You can update NetBSD userland to the NetBSD stable
by running a command such as nbpkg.sh.
It is a reference implementation client which is a wrapper of
[pkgsrc/pkgtools/pkgin](http://pkgin.net/).


## DEMONSTRATION

Just run "nbpkg.sh full-upgrade" on NetBSD 8.0
to upgrade it to the latest NetBSD 8.0 stable.

```
# nbpkg.sh full-upgrade

debug: PKG_PATH  = http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/diff/netbsd-8/i386
debug: PKG_REPOS = http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/diff/netbsd-8/i386

Running install with PRE-INSTALL for pkg_install-20180425.
man/man1/pkg_add.1
man/man1/pkg_admin.1
man/man1/pkg_create.1
man/man1/pkg_delete.1
man/man1/pkg_info.1
man/man5/pkg_install.conf.5
man/man5/pkg_summary.5
man/man7/pkgsrc.7
man/man8/audit-packages.8
man/man8/download-vulnerability-list.8
sbin/audit-packages
sbin/download-vulnerability-list
sbin/pkg_add
sbin/pkg_admin
sbin/pkg_create
sbin/pkg_delete
sbin/pkg_info
Running install with PRE-INSTALL for pkg_install-20180425.
Package pkg_install-20180425 registered in /var/db/pkg/pkg_install-20180425
===========================================================================
$NetBSD: MESSAGE,v 1.7 2017/01/09 07:01:33 sevan Exp $

You may wish to have the vulnerabilities file downloaded daily so that it
remains current. This may be done by adding an appropriate entry to the root
users crontab(5) entry. For example the entry

# Download vulnerabilities file
0 3 * * * /usr/pkg/sbin/pkg_admin fetch-pkg-vulnerabilities >/dev/null 2>&1
# Audit the installed packages and email results to root
9 3 * * * /usr/pkg/sbin/pkg_admin audit |mail -s "Installed package audit result" \
            root >/dev/null 2>&1
      
will update the vulnerability list every day at 3AM, followed by an audit at
3:09AM. The result of the audit are then emailed to root. On NetBSD this may be
accomplished instead by adding the following line to /etc/daily.conf:

fetch_pkg_vulnerabilities=YES
      
to fetch the vulnerability list from the daily security script. The system is
set to audit the packages by default but can be set explicitly, if desired (not
required), by adding the follwing line to /etc/security.conf:

check_pkg_vulnerabilities=YES
      
Both pkg_admin subcommands can be run as as an unprivileged user,
as long as the user chosen has permission to read the pkgdb and to write
the pkg-vulnerabilities to /var/db/pkg.

The behavior of pkg_admin and pkg_add can be customised with
pkg_install.conf.  Please see pkg_install.conf(5) for details.

If you want to use GPG signature verification you will need to install
GnuPG and set the path for GPG appropriately in your pkg_install.conf.
===========================================================================
Running install with PRE-INSTALL for pkgin-0.11.6.
bin/pkgin
man/man1/pkgin.1
share/examples/pkgin/preferred.conf.example
share/examples/pkgin/repositories.conf.example
Running install with PRE-INSTALL for pkgin-0.11.6.
pkgin-0.11.6: copying /usr/pkg/share/examples/pkgin/repositories.conf.example to /usr/pkg/etc/pkgin/repositories.conf
Package pkgin-0.11.6 registered in /var/db/pkg/pkgin-0.11.6
===========================================================================
$NetBSD: MESSAGE,v 1.3 2010/06/10 08:05:00 is Exp $

First steps before using pkgin.

. Modify /usr/pkg/etc/pkgin/repositories.conf to suit your platform
. Initialize the database :

        # pkgin update

===========================================================================
Requesting http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/diff/netbsd-8/i386/list-pkg
  0% |                                   |     0        0.00 KiB/s    --:-- ETA100% |***********************************|   431      663.87 KiB/s    00:00 ETA
431 bytes retrieved in 00:00 (70.66 KiB/s)
pkgin import /var/db/nbpkg/list-pkg
reading local summary...
processing local summary...
processing remote summary (http://basepkg.netbsd.fml.org/pub/NetBSD/basepkg/diff/netbsd-8/i386)...
downloading pkg_summary.gz:   0%pkg_summary.gz                                  0%    0     0.0KB/s   --:-- ETApkg_summary.gz                                100% 1825     1.8KB/s   00:00    
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
