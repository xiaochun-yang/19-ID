#!/bin/csh -f

############################################################
#
# 
#
# Usage:
#	con_autoindex.csh <input file>
#
############################################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

$WEBICE_SCRIPT_DIR/setup_env.csh

if ($#argv != 1) then
	echo `date +"%T"` " Wrong number of commandline arguments for con_autoindex.csh" >>& autoindex.out
	echo `date +"%T"` " Usage: con_autoindex.csh <input file>" >>& autoindex.out
	exit 1
endif

# Set workDir to the location of input.xml
set workDir = `dirname $1`

# Change dir to the appropriate dir where
# outptut files will be generated.
cd $workDir

# Make sure no other process controlled by the control file is running
if (-e control.txt) then
	echo `date +"%T"` " ERROR: Control file (control.txt) already exists in $workDir." >>& autoindex.out
endif

# Run the actual script in the appropriate dir
$WEBICE_SCRIPT_DIR/run_autoindex.csh >>& autoindex.out &

# Generate random filename
set tmpFile = `echo junk | awk '{print "tmp" rand()}'`

# List out children ids of this shell session.
# In this case there is only one child which is
# the run_autoindex.csh.
# Write the pid to the control file.
jobs -l > $workDir/$tmpFile


# Run the actual script
set jobPid = `cat $workDir/$tmpFile | awk '{print $3}'`

# Remove tmp file
rm -rf $workDir/$tmpFile

# Save process id to the control file
echo $jobPid > $workDir/control.txt

exit 0


