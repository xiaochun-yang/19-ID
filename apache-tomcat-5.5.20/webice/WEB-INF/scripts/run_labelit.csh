#!/bin/csh -f

############################################################
#
# Runs labelit.screen script. Input
# parameters are read from input.xml in current dir.
# Output are written to stdout and files in current dir.
#
# Usage:
#	run_labelit.csh
#
############################################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

echo `date +"%T"` " Started running labelit"

set labelitPath = `which labelit.screen`
set labelitBin = `dirname $labelitPath`
echo `date +"%T"` " LABELIT_BIN = $labelitBin"
set ipmosfmPath = `which ipmosflm`
echo `date +"%T"` " ipmosflm = $ipmosfmPath"

# workDir is current dir
set workDir = `pwd`

# Make sure input.xml exists and contains run_labelit task.
$WEBICE_SCRIPT_DIR/check_input.csh `basename $0`
if ($status != 0) then
    exit 1
endif

# Get input params from ./input.xml
set params = (`awk -f $WEBICE_SCRIPT_DIR/get_run_labelit_params.awk input.xml`)

set imageDir = $params[1]
set image1 = $params[2]
set image2 = $params[3]
set beamX = $params[4]
set beamY = $params[5]
set laueGroup = $params[6]
set a = "0.00"
set b = "0.00"
set c = "0.00"
set alpha = "0.00"
set beta = "0.00"
set gamma = "0.00"
if ($laueGroup != "unknown") then
set a = $params[7]
set b = $params[8]
set c = $params[9]
set alpha = $params[10]
set beta = $params[11]
set gamma = $params[12]
endif

# Sleep for 5 second before checking image file
set eachSleep = 5
# Total number of seconds spend in loop checking image file
set totalSleep = 0
set maxSleep = 30
set moreThanMaxSleep = 2000

# Loop to check image file until it becomes available
# or timeout
while ($totalSleep < $maxSleep)
if (! -e $imageDir/$image1) then
    echo `date +"%T"` " Waiting for image file $imageDir/$image1 to become available"
    # Sleep before checking the file again
    sleep $eachSleep
    @ totalSleep += $eachSleep
else
    # Get out of the loop once we have found the file
    echo `date +"%T"` " Found image file $imageDir/$image1"
    set totalSleep = $moreThanMaxSleep
endif
end
# Print out error if we can't find image file
if (! -e $imageDir/$image1) then
    echo `date +"%T"` " Cannot find or open image file $imageDir/$image1"
endif

# Total number of seconds spend in loop checking image file
set totalSleep = 0
# Loop to check image file until it becomes available
# or timeout
while ($totalSleep < $maxSleep)
sync
if (! -e $imageDir/$image2) then
    echo `date +"%T"` " Waiting for image file $imageDir/$image2 to become available"
    # Sleep before checking the file again
    sleep $eachSleep
    @ totalSleep += $eachSleep
else
    # Get out of the loop once we have found the file
    echo `date +"%T"` " Found image file $imageDir/$image2"
    set totalSleep = $moreThanMaxSleep
endif
end
# Print out error if we can't find image file
if (! -e $imageDir/$image2) then
    echo `date +"%T"` " Cannot find or open image file $imageDir/$image2"
endif

#if (! -d $workDir) then
#mkdir -p $workDir
#endif

if (! -d LABELIT) then
mkdir -p LABELIT
endif

cd LABELIT

# Remove output file
if (-e $workDir/labelit.out) then
  rm -rf $workDir/labelit.out
endif

# Override resolution limit
set maxDetectorResolution = `awk -f $WEBICE_SCRIPT_DIR/get_detector_resolution.awk ../PARAMETERS/image_params.txt`
if (-e ./dataset_preferences.py) then
	rm -rf ./dataset_preferences.py
endif
#echo "mosflm_integration_reslimit_override = $maxDetectorResolution" > ./dataset_preferences.py
# Default value of 4mm is too big and labelit cant it wrong 
echo "beam_search_scope = 0.8" >> ./dataset_preferences.py
echo "difflimit_sigma_cutoff = 1.5" >> ./dataset_preferences.py
echo "rmsd_tolerance = 2.5" >> ./dataset_preferences.py

set detector = `awk '{if ($1 == "detector") {print $2;}}' ../PARAMETERS/image_params.txt`
#if ("$detector" == "PILATUS6") then
#echo "autoindex_override_beam = (219.3, 212.3)" >> ./dataset_preferences.py
#endif
# Create a preference file for this dataset containing beam
# center override, for example,
# autoindex_override_beam = (90,100)
#if (-e ./dataset_preferences.py) then
#	rm -rf ./dataset_preferences.py
#endif

# Let labelit pick image center. See bug 1110.
#if ( ($beamX != "0.0") && ($beamY != "0.0") ) then
#	echo "autoindex_override_beam = ($beamX,$beamY)" >> ./dataset_preferences.py
#endif

# Add "BEST ON" to mosflm integration script.
# so that it generates hkl and other input files 
# for running "best" (to calculate exposure time
# for data collection strategy.
echo "best_support = True" >> ./dataset_preferences.py

# Set labelit.index param
set known_symmetry = ""
set known_cell = ""
if ($laueGroup != "unknown") then
if ($laueGroup == "H3") then
	set laueGroup = "R3:H"
endif
if ($laueGroup == "H32") then
	set laueGroup = "R32:H"
endif
set known_symmetry = "known_symmetry=$laueGroup"
set known = `echo "$a $b $c $alpha $beta $gamma" | awk '{ if (($1 > 0.0) && ($2 > 0.0) && ($3 > 0.0) && ($4 > 0.0) && ($5 > 0.0) && ($6 > 0.0)) { print "1"; } else { print "0"; }}'`
if ($known == 1) then
set known_cell = "known_cell=$a,$b,$c,$alpha,$beta,$gamma"
endif
endif

# Run the local copy of labelit with all command 
# line arguments passed in to this script
# If distl_permit_binning=False, we will get too many of 
# "Can't find 3 vectors basis" error for mccd images.

echo `date +"%T"` " labelit.index distl_permit_binning=True $imageDir/$image1 $imageDir/$image2 $known_symmetry $known_cell"
labelit.index distl_permit_binning=True $imageDir/$image1 $imageDir/$image2 $known_symmetry $known_cell >& labelit.out

#Generate bestpar.dat files for each autoindexing solution
labelit.best_parameters >&labelit_params.out

set integratedSolutions = `awk -f $WEBICE_SCRIPT_DIR/get_best_integrated_solution.awk labelit.out`

set generateMosflmScripts = 1
if ($#argv == 1) then
set generateMosflmScripts = 0
endif

if ($generateMosflmScripts == 1) then

if (-d LABELIT_possible) then
echo `date +"%T"` " Generating mosflm script for solution $integratedSolutions"
#labelit.mosflm_script $integratedSolutions
# Generate mosflm command file for all possible bravais lattices
labelit.mosflm_scripts
echo `date +"%T"` " Done generating mosflm script for solution $integratedSolutions"
else
echo `date +"%T"` " Skipped generating mosflm script for all solutions"
endif

endif

cd ..

echo `date +"%T"` " generate labelit.xml from run_labelit"
$WEBICE_SCRIPT_DIR/generate_labelit_xml.csh > LABELIT/labelit.xml

echo `date +"%T"` " generate labelit.tcl from run_labelit"
$WEBICE_SCRIPT_DIR/generate_labelit_tcl.csh > LABELIT/labelit.tcl

echo `date +"%T"` " Finished running labelit"




