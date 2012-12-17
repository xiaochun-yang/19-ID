#!/bin/csh -f

############################################################
#
# Reautoindex.
# Input parameters are read from input.xml
# in current directory. Output are written to stdout and
# files in current dir.
#
# Usage:
#	run_autoindex.csh
#
############################################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

echo `date +"%T"` " Started running reautoindex"
echo `date +"%T"` " HOST = $HOST"


# workDir is current dir
set workDir = `pwd`

# Parse input file
set params = (`awk -f $WEBICE_SCRIPT_DIR/get_reautoindex_params.awk input.xml`)

# Decode spaces
set imageDir = `echo $params[1] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set image1 = `echo $params[2] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set image2 = `echo $params[3] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set beamX = `echo $params[4] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set beamY = `echo $params[5] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set distance = `echo $params[6] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set wavelength = `echo $params[7] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set detector = `echo $params[8] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set format = `echo $params[9] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set detectorRes = `echo $params[10] | awk '{ gsub(/&nbsp;/, " ", $0); printf("%.2f", $0); }'`
set exposureTime = `echo $params[11] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set detectorWidth = `echo $params[12] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set beamline = `echo $params[13] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set oscRange = `echo $params[14] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set beamlineFile = `echo $params[15] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`

echo `date +"%T"` " scriptDir = $WEBICE_SCRIPT_DIR"
echo `date +"%T"` " workDir = $workDir"
echo `date +"%T"` " imageDir = $imageDir"
echo `date +"%T"` " image1 = $image1"
echo `date +"%T"` " image2 = $image2"
echo `date +"%T"` " beamX = $beamX"
echo `date +"%T"` " beamY = $beamY"
echo `date +"%T"` " distance = $distance"
echo `date +"%T"` " wavelength = $wavelength"
echo `date +"%T"` " oscRange = $oscRange"
echo `date +"%T"` " detector = $detector"
echo `date +"%T"` " format = $format"
echo `date +"%T"` " detectorWidth = $detectorWidth"
echo `date +"%T"` " detectorResolution = $detectorRes"
echo `date +"%T"` " exposureTime = $exposureTime"
echo `date +"%T"` " beamline = $beamline"

# Write image_params.txt file
if (! -d PARAMETERS) then
	mkdir -p PARAMETERS
endif

if (-e image1.txt) then
	mv image1.txt PARAMETERS
endif

if (-e image2.txt) then
	mv image2.txt PARAMETERS
endif

if (-e PARAMETERS/image_params.txt) then
	rm -rf PARAMETERS/image_params.txt
endif

echo "beamX		$beamX" > PARAMETERS/image_params.txt
echo "beamY		$beamY" >> PARAMETERS/image_params.txt
echo "distance		$distance" >> PARAMETERS/image_params.txt
echo "wavelength	$wavelength" >> PARAMETERS/image_params.txt
echo "detector		$detector" >> PARAMETERS/image_params.txt
echo "format		$format" >> PARAMETERS/image_params.txt
echo "detectorRes	$detectorRes" >> PARAMETERS/image_params.txt
echo "exposureTime	$exposureTime" >> PARAMETERS/image_params.txt
echo "detectorWidth	$detectorWidth" >> PARAMETERS/image_params.txt
echo "oscRange		$oscRange" >> PARAMETERS/image_params.txt


# Prepare input.xml for run_labelit.csh
echo `date +"%T"` " Preparing params for run_labelit.csh"
$WEBICE_SCRIPT_DIR/prepare_run.csh run_labelit input.xml input.xml
echo `date +"%T"` " Finished preparing params for run_labelit.csh"

# generate crystal orientation
set remountDir = `pwd`
cd ../LABELIT
if (-e crystal_orientation) then
rm -rf crystal_orientation
endif

labelit.store_crystal_orientation

cd $remountDir

# Get best solution number
set arr = (`awk -f $WEBICE_SCRIPT_DIR/get_bestsolution_stats.awk ../LABELIT/labelit.out`)
if ($#arr < 4) then
echo `date +"%T"` " Cannot find best integrated solution in the original labelit.out"
echo `date +"%T"` " Phi shift calculation aborted."
echo "First pass autoindexing failed" > best_phi_shift.tcl
exit
#set err = `awk '//{if ($0 != "") {lastLine = $0;}} END {print lastLine;}' ../LABELIT/labelit.out`
#echo `date +"%T $err" 
exit
set bestSolNum = "01"
set bestSpacegroup = "P1"
else
set bestSolNum = $arr[3]
set bestSpacegroup = `echo $arr[4] | awk -F, '{print $1;}'`
endif #arr size < 4

# Use labelit.store_crysyal_orientation script instead of below.
# Get triclinic cell parameters from "LABELIT Indexing results" table in labelit.out
# to force the reautoindex to use this P1 cell.
#set cell = (`awk -v solNum=$bestSolNum -f $WEBICE_SCRIPT_DIR/get_autoindex_solution_unitcell.awk ../LABELIT/labelit.out`)

# Replace unitCell in input.xml with P1 cell parameters
#awk -v laueGroup=$bestSpacegroup \
#	-v a=$cell[1] \
#	-v b=$cell[2] \
#	-v c=$cell[3] \
#	-v alpha=$cell[4] \
#	-v beta=$cell[5] \
#	-v gamma=$cell[6]\
#	-f $WEBICE_SCRIPT_DIR/set_unitcell_params.awk input.xml > input_new.xml

awk -v laueGroup="" \
	-v a="0.0" \
	-v b="0.0" \
	-v c="0.0" \
	-v alpha="0.0" \
	-v beta="0.0" \
	-v gamma="0.0"\
	-f $WEBICE_SCRIPT_DIR/set_unitcell_params.awk input.xml > input_new.xml		
mv input_new.xml input.xml


mkdir LABELIT
cp ../LABELIT/crystal_orientation LABELIT
# Run labelit
$WEBICE_SCRIPT_DIR/run_labelit.csh "doNotGenerateMosflmScripts"

# Check for labelit error
set labelit_error = ""

# Check if labelit crashes
set labelit_error = (`cat LABELIT/labelit.out | awk '{ if ((NR == 1) && (index($0, "/") != 1)) { print $0; }}'`)

# Check if no autoindex solution
if ("$labelit_error" == "") then
set labelit_error = (`cat LABELIT/labelit.out | awk '/^No_Indexing_Solution/{ print $0; }'`)
endif

# Check if autoindex is ok
# If not, print last line
if ("$labelit_error" == "") then
set labelit_error = (`cat LABELIT/labelit.out | awk 'BEGIN{ err = ""; found = 0; } /LABELIT Indexing results/{ found = 1; } { if (found == 0) { err = $0; }}  END{ if (found == 1) {print err;}}'`)
endif

# Check if integration is ok
# If not, print last line
if ("$labelit_error" == "") then
set labelit_error = (`cat LABELIT/labelit.out | awk 'BEGIN{ err = ""; found = 0; } /MOSFLM Integration/{ found = 1; } { if (found == 0) { err = $0; }}  END{ if (found == 1) {print err;}}'`)
endif

if ("$labelit_error" == "") then

# Calculate phi shift for best solution
#if (($bestSolNum != "01") && ($bestSpacegroup != "P1")) then
echo `date +"%T"` " Recalculating phi strategy for solution $bestSolNum spacegroup $bestSpacegroup"
$WEBICE_SCRIPT_DIR/calculate_phi_shift.csh $bestSolNum $bestSpacegroup
#endif

# Copy phi shift calculation result to REMOUNT dir
# so that dcss can use it without having to know which 
# solution number and spacegroup.
set resultDir = "solution${bestSolNum}/$bestSpacegroup"
if (-e $resultDir/phi_strategy.tcl) then
	cp $resultDir/phi_strategy.tcl best_phi_strategy.tcl
endif

# Calculate phi shift for triclinic P1
echo `date +"%T"` " Recalculating phi strategy for solution 1 spacegroup P1"
$WEBICE_SCRIPT_DIR/calculate_phi_shift.csh "01" "P1"

else

echo `date +"%T"` " Skipped recalculating phi strategy due to error in labelit: $labelit_error"

endif


echo `date +"%T"` " Finished running autoindex"
