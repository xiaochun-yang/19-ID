#!/bin/csh -f

############################################################
#
# Add or replace settings for run_*.csh in input.xml.
#
# Usage:
#	prepare_run.csh <run name>
# 
# Example:
#	prepare_run.csh run_autoindex
#
############################################################


setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

if ($#argv != 3) then
    echo `date +"%T"` " Wrong number of arguments for prepare_run.csh ($#argv)"
    exit 1
endif

set awkScript = `echo $1 | awk '{ print "prepare_" $0 ".awk"}'`

if (! -e $WEBICE_SCRIPT_DIR/$awkScript) then
	echo "Cannot find or open $WEBICE_SCRIPT_DIR/$awkScript"
	exit 1
endif

# If file does not exist then create it
if (! -e $2) then
	echo "<input>\n</input>\n" > input.xml
endif

set src  = $2
set dest = $3
    
# Create tmp filename
set fileName = `echo junk | awk '{print "tmp" rand()}'`

# Add/replace xml nodes and save it to a new file
cat $src | awk -f $WEBICE_SCRIPT_DIR/$awkScript > $fileName

# If we are rewriting the same file then remove the original one.
if ($src == $dest) then
    rm -rf $src
endif


# Save the new file
mv $fileName $dest

