#!/bin/csh -f

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

set labelitPath = `which labelit.screen`
set labelitBin = `dirname $labelitPath`
echo `date +"%T"` " LABELIT_BIN = $labelitBin"
set ipmosfmPath = `which ipmosflm`
echo `date +"%T"` " ipmosflm = $ipmosfmPath"

# Make sure the env variables are set
if ($LABELIT_WORK == "") then
	echo `date +"%T"` " ERROR: LABELIT_WORK env variable not set"
	exit
endif

# Make sure there are enough command line arguments 
if ($#argv < 1) then 
	echo `date +"%T"` " ERROR: wrong number of command-line arguments (expecting 1 but got $#argv)"
	
	echo " "
	echo "Usage:"
	echo "$0 <image files>"
endif

# cd to the work dir
cd $LABELIT_WORK

# Loop over input images passes in as command line arguments
foreach arg ($argv)

# Extract the file name without path or extension. 
# Note that \..* is a regular expresion.
set imageName = `basename $arg`
set imageName = `echo $imageName | awk 'BEGIN{ FS="."}{ if (NF == 1) { print $0 } else { for (x = 1; x < NF; x++) { printf("%s", $NR)}}}'`

# Remove output file
if (-e ${imageName}_overlay_distl.stat) then
  rm -rf ${imageName}_overlay_distl.stat
endif

# Remove output file
if (-e ${imageName}_overlay_index.stat) then
  rm -rf ${imageName}_overlay_index.stat
endif


labelit.overlay_distl $arg ${imageName}_overlay_distl.png DISTL_pickle > ${imageName}_overlay_distl.stat
	
labelit.overlay_index $arg ${imageName}_overlay_index.png DISTL_pickle > ${imageName}_overlay_index.stat

labelit.overlay_mosflm $arg ${imageName}_overlay_mosflm.png DISTL_pickle > ${imageName}_overlay_moslfm.stat

# end foreach loop
end



