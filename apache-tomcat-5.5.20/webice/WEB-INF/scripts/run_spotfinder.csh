#!/bin/csh -f

############################################################
#
# 
#
# Usage:
#	run_spotfinder.csh <input>
#
############################################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

setenv WEBICE_BIN_DIR `dirname $0`/../bin
setenv PATH /usr/sbin:/usr/bin:/bin

if ($#argv != 1) then
	echo `date +"%T"` " Wrong number of commandline arguments for run_spotfinder.csh"
	echo `date +"%T"` " Usage: run_spotfinder.csh <input>"
	exit 1
endif

# Set workDir to the location of input.xml
set workDir = $1

# Change dir to the appropriate dir where
# outptut files will be generated.
cd $workDir

# Get all image files in this dir
set imageFiles = (`/usr/bin/ls *.img`)

# Run spotfinder on each image
foreach imageFile ($imageFiles)

	echo "Started spotfinder for $imageFile"
	$WEBICE_BIN_DIR/spotfinder -i $WEBICE_BIN_DIR/spotfinder.par $imageFile
	echo "Finished spotfinder for $imageFile"

end

exit 0


