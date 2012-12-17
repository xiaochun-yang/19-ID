#!/bin/csh -f

############################################################
#
# 
#
# Usage:
#	con_center_detector.csh <image file> <output file>
#
############################################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

$WEBICE_SCRIPT_DIR/setup_env.csh

if ($#argv != 3) then
	echo `date +"%T"` " Wrong number of commandline arguments for con_center_detector.csh" >>& center_detector.out
	echo `date +"%T"` " Usage: con_autoindex.csh <image file> <output file> <control file>" >>& center_detector.out
	exit 1
endif

set imageFile = $1
set outputFile = $2
set controlFile = $3

# Set workDir to the location of input.xml
set workDir = `dirname $outputFile`

# Change dir to the appropriate dir where
# outptut files will be generated.
cd $workDir

#Delete output file if it exists (to avoid making it very long)
if (-e "$outputFile") then
    rm -fr $outputFile
endif

# Make sure no other process controlled by the control file is running
if (-e "$controlFile") then
	echo "ERROR: Control file $controlFile already exists." >>& "$outputFile"
endif

# Run the actual script in the appropriate dir
$WEBICE_SCRIPT_DIR/run_center_detector.csh "$imageFile" >>& "$outputFile" &

# List out children ids of this shell session.
# In this case there is only one child which is
# center_detectors.csh.
# Write jobID and host name to the control file
# And use checkJobStatus.csh to check the status of the job.

set tmpFile = `echo junk | awk '{print "tmp" rand()}'`
jobs -l > $tmpFile
set jobPid = `cat $tmpFile | awk '{print $3}'`
rm -rf $tmpFile
echo $jobPid " " $HOST > $controlFile

exit 0


