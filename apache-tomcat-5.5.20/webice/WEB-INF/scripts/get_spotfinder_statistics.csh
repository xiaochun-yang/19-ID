#!/bin/csh -f

############################################################
#
# 
#
# Usage:
#	get_spotfinder_statistics.csh <input dir>
#
############################################################


# Set script dir to the location of the script
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

setenv WEBICE_BIN_DIR `dirname $0`/../bin
setenv PATH /usr/sbin:/usr/bin:/bin

if ($#argv != 1) then
	echo `date +"%T"` " Wrong number of commandline arguments for get_spotfinder_statistics.csh"
	echo `date +"%T"` " Usage: get_spotfinder_statistics.csh <input dir>"
	exit 1
endif

# Set workDir to the location of input.xml
set workDir = $1

# Change dir to the appropriate dir where
# outptut files will be generated.
cd $workDir

# Get all image files in this dir
set logFiles = (`/usr/bin/ls *.spt.log`)

set images = ()
set spotnum = ()
set spotovernum =  ()
set spotclosenum =  ()
set spotmmaxnum =  ()
set spotsize =  ()
set spotshape =  ()
set resol =  ()
set iceringnum =  ()
set iceringstrength =  ()
set overloadpatchsize =  ()

# Run spotfinder on each image
foreach logFile ($logFiles)

	set count = $count + 1

	set statistics = `awk -f $WEBICE_BIN_DIR/get_spotfinder_statistics.awk $logFile`
	
	spotnum[count] = 

end

exit 0


