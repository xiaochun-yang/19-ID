#!/bin/csh -f

############################################################
#
# Creates and runs moslfm scripts for integration. Input
# parameters are read from input.xml in current dir.
# Output are written to stdout and files in current dir.
#
# Usage:
#	run_integrate_additional_solutions.csh
#
############################################################

echo `date +"%T"` " Started integrating additional solutions"

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

# Run the actual script in the appropriate dir
# and append output to autoindex.out.
$WEBICE_SCRIPT_DIR/run_integrate.csh >>& autoindex.out


echo `date +"%T"` " Finished integrating additional solutions"
