#!/bin/csh -f

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

# workDir is current dir
set workDir = `pwd`

set subdirs = ""
if ( -d solution01 ) then
# Get all integrated solutions
set subdirs = `ls -d solution*`
endif

# Extract solution number from dir name
set integratedSols = `echo "$subdirs" | awk '/solution/{ gsub(/solution0/, ""); gsub(/solution/, ""); print}'`

# Generate labelit.xml from labelit.out
awk -v integratedSols="$integratedSols" -f $WEBICE_SCRIPT_DIR/generate_labelit_xml.awk LABELIT/labelit.out

