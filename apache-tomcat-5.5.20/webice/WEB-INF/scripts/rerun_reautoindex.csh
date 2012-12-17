#!/bin/csh -f

set WEBICE_SCRIPT_DIR = `dirname $0`

if ($#argv != 1) then
echo "Usage: rerun_reautoindex.csh <screening dir>"
exit
endif

# Go to webice screening dir
cd $1


set screeningDir = `pwd`
set crystals = (`ls`)

foreach crystal ($crystals)

cd $crystal/autoindex

echo "Reautoindex and calculate phi shift for $crystal"

set done = 0
set backupDir = ""
if (-e REMOUNT) then
	set counter = 1
	while (($done != 1) && ($counter < 20))
		set backupDir = REMOUNT_backup${counter}
		echo "counter = $counter"
		if (!(-e $backupDir)) then
			mv REMOUNT $backupDir
			echo "Moved REMOUNT dir to $backupDir"
			set done = 1
		endif
		@ counter = $counter + 1
	end
	# Cannot backup REMOUNT dir
	if ($done != 1) then
		echo "Cannot create backup dir for REMOUNT"
		# Skip rerunning autoindex for this crystal
		continue
	endif		
endif

# Create a new REMOUNT dir
mkdir REMOUNT
cd REMOUNT

# Copy input files to the new REMOUNT dir
cp ../$backupDir/input.xml .
cp -r ../$backupDir/PARAMETERS .


# Rerun autoindex and calculate phi shift
echo "Rerunning $WEBICE_SCRIPT_DIR/run_reautoindex.csh in "`pwd`
$WEBICE_SCRIPT_DIR/run_reautoindex.csh > autoindex.out

# Go back up to webice screening dir
cd $screeningDir

# TEST 1 CRYSTAL
#exit

end #foreach crystal
