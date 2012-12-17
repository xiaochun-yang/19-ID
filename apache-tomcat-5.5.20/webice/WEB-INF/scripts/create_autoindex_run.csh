#!/bin/csh -f

############################################################
#
# Create a new directory and an empty input.xml.
#
# Usage:
#       create_autoindex_project.csh <work dir>
#
############################################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

# workDir is current dir
set workDir = $1

if (-d $workDir) then
    echo `date +"%T"` " $workDir already exists"
    exit 1
endif

# Create dir
mkdir $workDir

cd $workDir

# Copy input.xml from template
cp $WEBICE_SCRIPT_DIR/autoindex_input.xml input.xml



