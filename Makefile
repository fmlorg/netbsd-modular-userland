#
# $FML$
#
BRANCH	 = 	netbsd-8
_PWD	!=	pwd


all:
	@ echo "make show-status	run \"git status -s\""
	@ echo "make status		same as show-status"
	@ echo "make update		run \"git pull --rebase\""
	@ echo "make clean		clean up *~ recursively"
	@ echo ""
	@ echo "gen-ident-database	generate ident database for specific BRANCH"
	@ echo ""

show-status: 
	@ git status -s

status: show-status

update:
	@ git pull --rebase

clean:
	find . -name '*~' -type f -exec rm -v {} \;


# PLAN-B IDENT BASED
gen-ident-database:
	sh ${_PWD}/nbpkg-data/sbin/nbpkg-identgen.sh -b $(BRANCH)
