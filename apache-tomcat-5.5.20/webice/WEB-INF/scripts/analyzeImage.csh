#!/bin/csh -f

############################################################
#
# Start the image analysis program.
#
# Usage:
#	analyzeImage.csh <work dir> <image path>
#
############################################################


# Set script dir to this script location
set WEBICE_SCRIPT_DIR=`dirname $0`

if ($#argv != 3) then
	echo `date`" Error: Wrong number of commandline arguments for analyzeImage.csh"
	exit 0
endif

# Set workDir to the location of input.xml
set jobFile = $1
set workDir = $2
set image = $3
set imageDir = `dirname $image`

if (! -d $workDir) then
# create dir and its parents (if neccessary)
echo `date +"%T"` " Creating dir $workDir"
mkdir -p $workDir
endif

# Change dir to the appropriate dir where
# outptut files will be generated.
cd $workDir

# Sleep for 5 second before checking image file
set eachSleep = 5
# Total number of seconds spend in loop checking image file
set totalSleep = 0
set maxSleep = 30
set moreThanMaxSleep = 2000

# Loop to check image file until it becomes available
# or timeout
while ($totalSleep < $maxSleep)
if (! -e $image) then
    sync
    echo `date +"%T"` " Waiting for image file $image to become available"
    # Sleep before checking the file again
    sleep $eachSleep
    @ totalSleep += $eachSleep
else
    # Get out of the loop once we have found the file
    echo `date +"%T"` " Found image file $image"
    set totalSleep = $moreThanMaxSleep
endif
end
# Print out error if we can't find image file
if (! -e $image) then
    echo `date +"%T"` " Cannot find or open image file $image"
endif


# Generate random filename
set tmpFile = `echo junk | awk '{print "tmp" rand()}'`

# run spot finder on the file in the current dir
#${SPOTBIN}/spotfinder -d $workDir -i ${SPOTBIN}/spotfinder.par $image &
$WEBICE_SCRIPT_DIR/generate_distl_markup.csh "$image" "$workDir" &


# List out children ids of this shell session.
# In this case there is only one child which is
# the run_autoindex.csh.
# Write the pid to the control file.
jobs -l > ${workDir}/${tmpFile}


# Run the actual script
set jobPid = `cat ${workDir}/${tmpFile} | awk '{print $3}'`

# Remove tmp file
rm -rf ${workDir}/${tmpFile}

# Save process id to the control file
echo $jobPid > $jobFile

echo $jobPid

exit 0


