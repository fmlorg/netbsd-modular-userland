#
# $FML$
#

all:
	@ echo "make show-status	run \"git status -s\""
	@ echo "make status		same as show-status"
	@ echo "make update		run \"git pull --rebase\""
	@ echo "make clean		clean up *~ recursively"

show-status: 
	@ git status -s

status: show-status

update:
	@ git pull --rebase

clean:
	find . -name '*~' -type f -exec rm -v {} \;
