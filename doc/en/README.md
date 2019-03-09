# NetBSD modular userland distribution service

**old REMADE.md is moved to here, but not yet updated, sorry.**

There are a few memo/idea on NetBSD modular userland *ident based comparison*.
 

## CAUTION

*nbpkg* client part *nbpkg-client/* is a reference implementation which ordinary people will use as a client.
However
the server side such as *nbpkg-build/* and *nbpkg-data/* are used only by basepkg distribution system maintainers.


## PLAN B: Abstract

Each file (precisely speaking almost all files) in NetBSD source tree contains each ident information 
which is a revision number under the version control system "CVS".
It changes when it is modified.
Hence
*nbpkg-build/* tracks the ident changes to determine which basepkg tar-ball we need to rebuild.

Apparently we need the base ident database to compare with the current one.
We determine the base for the stable branch is the corresponding official major release
e.g. the base of netbsd-8 branch is NetBSD 8.0 release.

Also, the base of NetBSD-current is ambiguous, so we define the base is the latest major official release
e.g. NetBSD-current (8.99.xx) is NetBSD 8.0 release.

*nbpkg-data/* is a utility to help that we create ident database for official releases.
We only need to run this tool each official major release e.g. NetBSD-8.0, NetBSD-9.0, ... (each 2-3 years).


## PLAN B: Usage (client side)

The use of *pkgin* is recommended.
In the case of Plan B, 
we can use *pkgin* as it is.


## PLAN B: Server side

### Server side usage

- extract the ident database (which will be distributed at *fml.org*).
- run "nbpkg-build/sbin/nbpkg-build.sh" periodically.

### Server side: How it works

*nbpkg-build.sh* compares the ident database between the latest and the major release one
to generate only changed *basepkg* packages.



## HISTORY

### PLAN A (2018/07)
You can update NetBSD user-land partly using an apt/yum like utility.

It composed of a client utility (reference implementation) and the corresponding server side.
The former is "nbpkg", the latter is "nbpkg-build".

Plan A works well but it is weird. 
Hence we have been developed Plan B inspired by Onodera (ryoon@netbsd.org).
