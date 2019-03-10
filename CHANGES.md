	CHANGES on NetBSD modular userland distribution service

2019/03/10

    v0.5.0 beta

    make the broken build of evb*-* targets work following the fixes:
    (1) use of alias $machine/$machine_arch name to inform to basepkg.sh
        e.g. evbearm-el for evbarm-earm
    (2) sets/lists search fixes.
        e.g. we should search md.evbarm not evbarm-earm
    (3) run basepkg.sh with --destdir ...

    The following architures becomes operational now:

	evbarm-earm
	evbarm-earmeb
	evbmips-mipseb
	evbmips-mipsel
	evbsh3-sh3eb
	evbsh3-sh3el

    but the build of the following architecures is incomplete:
	evbmips-mips64el
	evbmips-mips64eb
	evbarm-earmv7hf
	evbarm-earmv6hf
	evbarm-earmv7hfeb

2019/02/11
    v0.4.0 release

    master daemon support:
    "nbpkg-admin/libexec/master.sh" drives the whole process
    to invoke nbpkg-build.sh for Tier 1 and all pararelly via cron.

    A utility "nbpkg-admin/sbin/nbpkg-admin.sh" is added.
    It can be used to enable/disable the whole process safely.

2018/12/01
    nbpkg.sh (client) alias support

2018/11/30
    v0.3.0 release

    release mode support:
    
    It is enhanced to support *release* virtual branch on the server.
    It enables two modes *all* and *maint* for the client.
    
    support release mode for "nbpkg.sh -a" which enables bottom up build.
    - You run "nbpkg.sh -a" to build your own NetBSD from the minimum
      installation. It enables bottom up approach.
    - generate proper target list
    - exceptional release mode is handled and ends before stable
      branch handling since its comparison and ident based diff build
      are not needed.

    "nbpkg.sh" client enhanced:
    - "nbpkg.sh full-upgrade" can upgrade your system to the latest one.
    - exclude "etc-*-*" in "npkg.sh full-upgrade" to avoid cirtical side
      effect such as "/etc/passwd is overwritten.
    - we do not support kernel add/del operation now by nbpkg.sh.


2018/11/25
    v0.2.0 release
    ident based comparison suport, what we call, Plan B.
 

2018/07/14
    Plan A (v0.1.1) released (for Japan NetBSD Users Group BoF :-).
    This plan A works well but weird, 
    so we will develop Plan B inspired by Onodera (ryoon@netbsd.org).

    It was released on JNUG NetBSD BoF 2018/07/14 following
    snap-20180714 (same as v0.1.1), snap-20180713 and snap-20180626.
