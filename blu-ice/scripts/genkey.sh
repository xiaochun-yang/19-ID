#!/usr/local/bin/tcsh

if ( ! -f /home/adm/keys/$USER || ! -f /home/adm/keys/$USER.pub ) then
	rm -f /home/adm/keys/$USER
	rm -f /home/adm/keys/$USER.pub
	ssh-keygen -t rsa1 -N "" -b 640 -f /home/adm/keys/$USER > /dev/null
	chmod 400 /home/adm/keys/$USER
	chmod 400 /home/adm/keys/$USER.pub
endif
