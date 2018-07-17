# NetBSD modular userland
You can update NetBSD userland partly using an apt/yum like utility.

It composed of a client utility (reference implementation) and the corresponding server side.
The formar is "nbpkg", the latter is "nbpkg-build".

Currently, plan A works well but plan A is weird. So we will develop Plan B inspired by Onodera (ryoon@netbsd.org).

---

## PLAN B

1. prepare the release info (do this once per release)

   set up the ident list for the previous release e.g. NetBSD-7.0

   *We need to run this setup once just after the release.*


1. compare the ident info between the latest stable and the release one.

nbpkg-build.sh generates base packages for targets which differs from
the release. We determine whether it differs or not based on the
corresponding ident information.


---
$Revision$
