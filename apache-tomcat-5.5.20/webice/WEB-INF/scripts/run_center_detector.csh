#!/bin/csh -f

############################################################
#
#
# Usage:
#	run_center_detector.csh <imageFile>
#
############################################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

if ( `uname -m` == "x86_64" ) then
    set path = ( /home/sw/rhel4/x86_64/bin $path )
else
    set path = ( /home/sw/rhel4/i386/bin $path )
endif

# workDir is current dir
set workDir = `pwd`

set imageFile = $1
set totalSleep = 0
set maxSleep = 40
set moreThanMaxSleep = 4000
set eachSleep = 5

while ($totalSleep < $maxSleep)
if (! -e "$imageFile") then
    echo `date +"%T"` " Waiting for image file $imageFile to become available"
    # Sleep before checking the file again
    sleep $eachSleep
    @ totalSleep += $eachSleep
else
    # Get out of the loop once we have found the file
    echo `date +"%T"` " Found image file $imageFile"
    set totalSleep = $moreThanMaxSleep
endif
end
# Print out error if we can't find image file
if (! -e $imageFile) then
    echo `date +"%T"` " Cannot find or open image file $imageFile"
exit
endif

# Put code here.
center $imageFile

#To avoid the program running on a earlier image:
mv $imageFile ${imageFile}_old
