#!/bin/csh -f

############################################################
#
# Runs autoindexing, integrates and generates datacollection
# strategies. Input parameters are read from input.xml
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

echo `date +"%T"` " Started running autoindex"
echo `date +"%T"` " HOST = $HOST"


# workDir is current dir
set workDir = `pwd`

# Make sure input.xml exists and contains run_autoindex task.
$WEBICE_SCRIPT_DIR/check_input.csh `basename $0`
if ($status != 0) then
    exit 1
endif

# Parse input file
set params = (`awk -f $WEBICE_SCRIPT_DIR/get_run_autoindex_params.awk input.xml`)

# Decode spaces
set imageDir = `echo $params[1] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set image1 = `echo $params[2] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set image2 = `echo $params[3] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set integrate = `echo $params[4] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set generateStrategy = `echo $params[5] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set beamX = `echo $params[6] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set beamY = `echo $params[7] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set distance = `echo $params[8] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set wavelength = `echo $params[9] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set detector = `echo $params[10] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set format = `echo $params[11] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set detectorRes = `echo $params[12] | awk '{ gsub(/&nbsp;/, " ", $0); printf("%.2f", $0); }'`
set exposureTime = `echo $params[13] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set detectorWidth = `echo $params[14] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set beamline = `echo $params[15] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set oscRange = `echo $params[16] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set beamlineFile = `echo $params[17] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set dcsDumpFile = `echo $params[18] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`
set strategyMethod = `echo $params[19] | awk '{ gsub(/&nbsp;/, " ", $0); print $0 }'`

echo `date +"%T"` " scriptDir = $WEBICE_SCRIPT_DIR"
echo `date +"%T"` " workDir = $workDir"
echo `date +"%T"` " imageDir = $imageDir"
echo `date +"%T"` " image1 = $image1"
echo `date +"%T"` " image2 = $image2"
echo `date +"%T"` " integrate = $integrate"
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
echo `date +"%T"` " generateStrategy = $generateStrategy"
echo `date +"%T"` " strategyMethod = $strategyMethod"
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

if ($generateStrategy == "yes" || $generateStrategy == "true") then
    if (-e ${beamline}.properties) then
    	mv ${beamline}.properties PARAMETERS/beamline.properties
    else
# Copy beamline property file
    	if (-e $beamlineFile) then
		echo `date +"%T"` " Copying $beamlineFile"
		cp $beamlineFile PARAMETERS/beamline.properties
    	else
		set tmp1 = `dirname $beamlineFile`"/default.properties"
		echo `date +"%T"` " Cannot find $beamlineFile"
		echo `date +"%T"` " Copying $tmp1 instead"
		cp $tmp1 PARAMETERS/beamline.properties
    	endif
    endif
    
    if (-e ${beamline}.dump) then
    	mv ${beamline}.dump PARAMETERS/${beamline}.dump
    else
# Copy dcs dump file
    	echo `date +"%T"` " Copying $dcsDumpFile to PARAMETERS/$beamline.dump"
# Copy could fail if the dump file is locked as dcss is in the middle 
# of updating it. Try 10 time.
    	set count = 0
    	while ($count < 10) 
		cp $dcsDumpFile PARAMETERS/$beamline.dump
		# Have we got it?
		if (-e PARAMETERS/$beamline.dump) then
			break
		endif
		set count = `echo $count | awk '{print $1 + 1;}'`
		sleep 1
		echo `date +"%T"` " Retry $count copying $dcsDumpFile to PARAMETERS/$beamline.dump"
    	end #end while loop
    endif
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

# Generate dcs_params.txt from <beamline>.dump file.
if ($generateStrategy == "yes" || $generateStrategy == "true") then
# Need -F: in order to use ":" as a field separator. Otherwise
# we will get awk error "cannot have more than 199 fields".
awk -F: -f $WEBICE_SCRIPT_DIR/generate_dcs_params.awk "PARAMETERS/${beamline}.dump" > PARAMETERS/dcs_params.txt
endif

# Prepare input.xml for run_labelit.csh
echo `date +"%T"` " Preparing params for run_labelit.csh"
$WEBICE_SCRIPT_DIR/prepare_run.csh run_labelit input.xml input.xml
echo `date +"%T"` " Finished preparing params for run_labelit.csh"


# Copy scan files from image dir to webice run dir
if (-e collect.xml) then

set is_scan = `awk -f $WEBICE_SCRIPT_DIR/is_scan.awk collect.xml`

if ($is_scan == 1) then

set runName = `basename $workDir`
mkdir -p scan
if (-e $imageDir/${runName}fp_fpp.bip) then
cp $imageDir/${runName}fp_fpp.bip scan/${runName}fp_fpp.bip
endif
if (-e $imageDir/${runName}raw_exp.bip) then
cp $imageDir/${runName}raw_exp.bip scan/${runName}raw_exp.bip
endif
if (-e $imageDir/${runName}scan) then
cp $imageDir/${runName}scan scan/${runName}scan
endif
if (-e $imageDir/${runName}smooth_exp.bip) then
cp $imageDir/${runName}smooth_exp.bip scan/${runName}smooth_exp.bip
endif
if (-e $imageDir/${runName}smooth_norm.bip) then
cp $imageDir/${runName}smooth_norm.bip scan/${runName}smooth_norm.bip
endif
if (-e $imageDir/${runName}summary) then
cp $imageDir/${runName}summary scan/${runName}summary
endif

# if is_scan
endif
# if collect.xml exists
endif



# Run labelit
$WEBICE_SCRIPT_DIR/run_labelit.csh

# Check for labelit error
set labelit_error = ""

# Check if labelit crashes
# Assume that labelit did not crash if:
# 1. The first line in labelit.out is image1 path and second line is image2 path. Path begins with '/' character.
# 2. The first line does not begin with '/' but does not contain 'error'.
# Assume that labelit crashed if:
# the first line does not begin with '/' and it contains the word 'error'
set labelit_error = (`cat LABELIT/labelit.out | awk '{ if ((NR == 1) && (index($0, "/") != 1) && (match($0, /ERROR|Error|error/) > 0)) { print $0; }}'`)

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

if (-e LABELIT/DISTL_pickle) then
echo `date +"%T"` " Started extracting images statistics"
cd LABELIT
labelit.stats_distl > image_stats.out
cd ..
echo `date +"%T"` " Finished extracting images statistics"
else
echo `date +"%T"` " Skipped extracting image statistics because DISTL_pickle file does not exist."
endif

if ("$labelit_error" == "") then

    # Prepare input.xml for run_integrate.csh
    echo `date +"%T"` " Preparing params for run_integrate.csh"
    $WEBICE_SCRIPT_DIR/prepare_run.csh run_integrate input.xml input.xml
    echo `date +"%T"` " Finished preparing params for run_integrate.csh"

    # Run integrate	
    $WEBICE_SCRIPT_DIR/run_integrate.csh "$strategyMethod"

else # if labelit error

    echo `date +"%T"` " Skipped integration and strategy calculations due to error in labelit: $labelit_error"

endif # if labelit error

# Change dir back to workDir
cd $workDir

if (-e LABELIT_possible) then
    # Generate prediction images
    $WEBICE_SCRIPT_DIR/run_generate_images.csh $imageDir/$image1 $imageDir/$image2

else 
    # For strategy calculation the file LABELIT_possible is under the subdirectory LABELIT. 
    if (-e LABELIT/LABELIT_possible) then
	# Generate prediction images
	$WEBICE_SCRIPT_DIR/run_generate_images.csh $imageDir/$image1 $imageDir/$image2
    else
	echo `date +"%T"` " Skipped generating predictions."
    endif
endif

if (-e LABELIT/image_stats.out) then
    # Generate run_summary.xml
    echo `date +"%T"` " Started generating run summary"
    $WEBICE_SCRIPT_DIR/generate_run_summary.csh > run_summary.xml
    echo `date +"%T"` " Finished generating run summary"
else
    echo `date +"%T"` " Skipped generating run summary due to previous error."
endif


echo `date +"%T"` " Finished running autoindex"
