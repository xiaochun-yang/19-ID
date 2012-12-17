#!/bin/csh -f

############################################################
#
# Creates and runs moslfm scripts for integration. Input
# parameters are read from input.xml in current dir.
# Output are written to stdout and files in current dir.
#
# Usage:
#	prepare_run_integrate_additional_solutions.csh <workDir> [solutions]+
#
############################################################


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

if ($#argv < 1) then
	echo "Error: wrong number of arguments (expecting 1 but got $#argv)"
	exit 1
endif

# workDir is the path to input.xml
set workDir = $1

cd $workDir

if (! -e input.xml) then
	echo "Error: Cannot find or open $workDir/input.xml"
endif

set sols = ($argv[2-])


# Make sure input.xml exists and contains run_integrate task.
$WEBICE_SCRIPT_DIR/check_input.csh "run_integrate.csh"
if ($status != 0) then
    exit 1
endif

# Insert or replace <additional_solutions></additional_solutions> node
# to run_integrate.csh task in input.xml

# Create tmp filename
set fileName = `echo junk | awk '{print "tmp" rand()}'`

# Add/replace xml nodes and save it to a new file
cat input.xml | awk -v sols="$sols" -f $WEBICE_SCRIPT_DIR/prepare_run_integrate_additional_solutions.awk > $fileName

# Remove the original one.
rm -rf input.xml

# Save the new file
mv $fileName input.xml

