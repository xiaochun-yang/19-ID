#!/bin/csh -f

set dcsDumpFile = $argv[1]
set beamline = $argv[2]

# Copy dcs dump file
echo `date +"%T"` " Copying $dcsDumpFile to PARAMETERS/$beamline.dump"
# Copy could fail if the dump file is locked as dcss is in the middle 
# of updating it. Try 10 time.
set count = 0
while ($count < 10)
	cp $dcsDumpFile PARAMETERS/$beamline.dump
	# Have we got it?
	if (-e PARAMETERS/$beamline.dump) then
		break
	endif
	set count = `echo $count | awk '{print $1 + 1;}'`
	sleep 1
	echo `date +"%T"` " Retry $count copying $dcsDumpFile to PARAMETERS/$beamline.dump"
end #end while loop

