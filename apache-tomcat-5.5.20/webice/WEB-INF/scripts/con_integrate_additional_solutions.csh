#!/bin/csh -f

############################################################
#
# 
#
# Usage:
#	con_integrate_additional_solutions.csh <input file>
#
############################################################


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

if ($#argv <= 1) then
	echo `date +"%T"` " Wrong number of arguments for con_integrate_additional_solutions.csh" >>& autoindex.out
	echo `date +"%T"` " Usage: con_integrate_additional_solutions.csh <workDir> [solutions]+" >>& autoindex.out
	exit 1
endif

# Set workDir
set workDir = $1

# Change dir to the appropriate dir where
# outptut files will be generated.
cd $workDir

# Make sure no other process controlled by the control file is running
if (! -e input.xml) then
	echo `date +"%T"` " ERROR: Cannot find or open $workDir/input.xml" >>& autoindex.out
	exit
endif

# Make sure no other process controlled by the control file is running
#if (-e control.txt) then
#	echo `date +"%T"` " ERROR: Control file (control.txt) already exists in $workDir." >>& autoindex.out
#endif

#echo `date +"%T"` "additional solutions = $argv[1-]"  >>& autoindex.out

# Edit input.xml
$WEBICE_SCRIPT_DIR/prepare_run_integrate_additional_solutions.csh $workDir $argv[2-] >>& autoindex.out

# Run the actual script in the appropriate dir
# and append output to autoindex.out.
$WEBICE_SCRIPT_DIR/run_integrate_additional_solutions.csh >>& autoindex.out &

# Generate random filename
set tmpFile = `echo junk | awk '{print "tmp" rand()}'`

# List out children ids of this shell session.
# In this case there is only one child which is
# the run_autoindex.csh.
# Write the pid to the control file.
jobs -l > $tmpFile

# Run the actual script
set jobPid = `cat $tmpFile | awk '{print $3}'`

# Remove tmp file
rm -rf $tmpFile

# Save process id to the control file
echo $jobPid > control.txt

exit 0
