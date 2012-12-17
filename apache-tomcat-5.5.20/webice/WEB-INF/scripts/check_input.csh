#!/bin/csh -f

############################################################
#
# Checks if input.xml exists and if it contains
# the desired task.
#
# Usage:
#	check_input.csh <task>
# Example:
#	check_input.csh run_integrate.csh
#
############################################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

#source $WEBICE_SCRIPT_DIR/setup_env.csh

if (! -e input.xml) then
   echo `date +"%T"` " Cannot find or open file input.xml."
   exit 1
endif

# Make sure this task is defined in input.xml
set task = $1
grep $task input.xml > /dev/null
if ($status != 0) then
   echo `date +"%T"` " Cannot find task $task in input.xml"
   exit 1
endif

exit 0
