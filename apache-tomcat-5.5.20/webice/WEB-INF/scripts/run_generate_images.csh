#!/bin/csh -f

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

echo `date +"%T"` " Started generating predictions"

cd LABELIT

# workDir is current dir
set workDir = `pwd`
set image1 = $1
set image2 = $2


echo `date +"%T"` " Generating prediction for $image1"
$WEBICE_SCRIPT_DIR/generate_mosflm_markup.csh "$image1" "$workDir"

echo `date +"%T"` " Generating prediction for $image2"
$WEBICE_SCRIPT_DIR/generate_mosflm_markup.csh "$image2" "$workDir"

echo `date +"%T"` " Finished generating predictions"

cd ..
