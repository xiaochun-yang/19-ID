#!/bin/csh -f

############################################################
#
# Creates and runs moslfm scripts for integration. Input
# parameters are read from input.xml in current dir.
# Output are written to stdout and files in current dir.
#
# Usage:
#	run_integrate.csh
#
############################################################


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

echo `date +"%T"` " Started integrating solutions"
echo `date +"%T"` " Running run_integrate.csh"


# workDir is current dir
set workDir = `pwd`

set strategyMethod = "mosflm"
if ($#argv > 0) then
set strategyMethod = $argv[1]
endif

# Make sure labelit.out exists
if (! -e LABELIT/labelit.out) then
    echo `date +"%T"` " Cannot find or open labelit.out"
    exit 1
endif

# Parse input file 
set params = (`awk -f $WEBICE_SCRIPT_DIR/get_run_integrate_params.awk input.xml`)

set integrate = $params[1]
set generateStrategy = $params[2]
set autoindexSolutions = ()


if ($generateStrategy == "yes" || $generateStrategy == "true") then

#parse dcss dump file if strategy is requested
    set b_info = (`awk -f $WEBICE_SCRIPT_DIR/get_beamline_info.awk $workDir/PARAMETERS/dcs_params.txt`)
    set b_detectorType = $b_info[9]
    set b_attenuation = $b_info[10]
# Get params from image_params.txt file
    set detectorType = `awk '{ if ($1 == "detector") { if (NF == 2) {print $2;} else {print $3;}} }' $workDir/PARAMETERS/image_params.txt`

# Check if detector type found in the image header is the same
# as the one from the beamline database dump file
# This is to make sure that the user selected a
# correct beamline.
    set wrong_beamline = 0
    if ("$detectorType" == "QUANTUM315" && $b_detectorType != "Q315CCD") then
	set wrong_beamline = 1
    endif
    if ("$detectorType" == "QUANTUM4" && $b_detectorType != "Q4CCD") then
	set wrong_beamline = 1
    endif
    if (("$detectorType" == "345") || ("$detectorType" == "mar345")) then
	set detectorFormat = `awk '{ if ($1 == "format") { print $2; } }' $workDir/PARAMETERS/image_params.txt`
	set detectorType = "mar$detectorFormat"
	if ($b_detectorType != "MAR345") then
	    set wrong_beamline = 1
	endif
    endif
    if ("$detectorType" == "165") then
	set detectorType = "MARCCD165"
	if ($b_detectorType != "MAR165") then
	    set wrong_beamline = 1
	endif
    endif
    if ("$detectorType" == "MARCCD325" && $b_detectorType != "MAR325") then
	set wrong_beamline = 1
    endif
    if ("$detectorType" == $b_detectorType) then
	set wrong_beamline = 0
    endif

    if ($wrong_beamline == 1) then
	echo "WARNING: detector type from image header ($detectorType) is different from detector type from beamline dump file ($b_detectorType)"
    endif

endif # generateStrategy == yes

#echo `date +"%T"` " detectorType = $detectorType"

# Parse labelit.out
# Get Best solutions that have been integrated, excluding solution01
set integratedSolutions = `awk -f $WEBICE_SCRIPT_DIR/get_integrated_solutions.awk LABELIT/labelit.out`

if ($integratedSolutions == "") then
echo `date +"%T"` " No integrated solution found in labelit.out."
exit 0
endif

set bestSolution = $integratedSolutions[1]

# For best solution only option, integrate
# best sol
if ($integrate == "best") then
	if ($#params > 2) then
		# Integrating additional solutions only
		set autoindexSolutions = ($params[3-])
	else
		# Integrating best solutions + solution1 only
		if ($bestSolution == "01") then
			set autoindexSolutions = ($bestSolution)
		else
			set autoindexSolutions = ($bestSolution "01")
		endif
	endif
else
	# Integrating all solutions
	set autoindexSolutions = `awk -f $WEBICE_SCRIPT_DIR/get_autoindex_solutions.awk LABELIT/labelit.out`
endif

# Get statistics of the best integrated solution
# such as predicted resolution and mosaicity.
set bestSolStats = (`awk -f $WEBICE_SCRIPT_DIR/get_bestsolution_stats.awk LABELIT/labelit.out`)

set predictedRes = $bestSolStats[1]

# 'best' program will hang if run with 0 resolution.
set test = `echo $predictedRes | awk '{if ($1 == 0.0) {print "0";} else {print "1";} }'`
if ($test == "0") then
echo `date +"%T"` " ERROR: Predicted resolution for best solution is zero."
echo "Predicted resolution is zero for best solution." > fatal_error.txt
exit
endif

# Get maximum detector resolution
set detectorRes = `awk -f $WEBICE_SCRIPT_DIR/get_detector_resolution.awk PARAMETERS/image_params.txt`

# Integrating
foreach solNum ($autoindexSolutions)

	echo `date +"%T"` " Started integrating solution$solNum"

	# Check if the solution has been integrated
	set solDir = solution$solNum
	if (-d $solDir) then
		echo `date +"%T"` " solution$solNum has already been integrated"
		continue	
	endif

	# Create dir for this solution
	mkdir $solDir

	# Change Dir to this solution dir
	cd $solDir

	# Check if the solution has already
	# been integrated by labelit
	if (-e $workDir/LABELIT/index$solNum.out) then
	
		# If so, then copy the integration
		# result files
		echo `date +"%T"` " solution$solNum has already been integrated by labelit"
		cp $workDir/LABELIT/index$solNum.* .
		cp $workDir/LABELIT/index${solNum}_S.* .
		cp $workDir/LABELIT/index$solNum ./index${solNum}.mfm
						
		chmod -R u+rwx .
		chmod -R g+rx .
			
	else
	
		# The solution has not been integrated by labelit

		# Copy the matrix file
		cp $workDir/LABELIT/index${solNum}.mat .
		cp $workDir/LABELIT/index${solNum}_S.mat .

		# Create mosflm script for integration
		touch index$solNum.mfm

		# Modify mosflm template script for this solution
		set lattice = `awk -v solNum=$solNum -f $WEBICE_SCRIPT_DIR/get_autoindex_solution_lattice.awk $workDir/LABELIT/labelit.out`
		set lowestSym = `awk -v lattice=$lattice -f $WEBICE_SCRIPT_DIR/get_lowest_sym_spacegroup.awk $WEBICE_SCRIPT_DIR/latticegroups.txt`
		awk -v solNum=$solNum -v lowestSym=$lowestSym \
			-v outputFile=index$solNum.mfm \
			-v bestSolNum=index$bestSolution \
			-f $WEBICE_SCRIPT_DIR/create_mosflm_integrate_script.awk $workDir/index$bestSolution

		# Make msflm script executable by owner					
		chmod u+rwx index$solNum.mfm

		# Run mosflm script to integrate
		./index$solNum.mfm
	
	endif
	
	# Generate indexNN.xml from indexNN.out file in solutionNN dir.
	$WEBICE_SCRIPT_DIR/generate_solution_summary_xml.csh index${solNum}.out > index${solNum}.xml
	# Generate indexNN.tcl from indexNN.out file in solutionNN dir.
	$WEBICE_SCRIPT_DIR/generate_solution_summary_tcl.csh index${solNum}.out > index${solNum}.tcl

	# Change dir back up one level
	cd ..

	chmod -R u+rwx $solDir
	chmod -R g+rx $solDir

	echo `date +"%T"` " Finished integrating solution$solNum"

# end integrate a solution
end


# Consolidate integration results
cd $workDir
echo `date +"%T"` " Extracting integration statistics"
$WEBICE_SCRIPT_DIR/merge_integration_results.csh
echo `date +"%T"` " Finished extracting integration statistics"


echo `date +"%T"` " Finished integrating solutions"

# Generate data collection strategy
# for all spacegroups
if ($generateStrategy == "yes" || $generateStrategy == "true") then

    # Check that the script for the strategy method exists.
#    if (! -e $WEBICE_SCRIPT_DIR/run_generate_strategy_${strategyMethod}.csh) then
#	echo `date +"%T"` " Skipped integration and strategy calculations because integration script for '" $strategyMethod "' strategy method is missing."
#    else # if strategyMethod script exists.

	echo `date +"%T"` " Using strategy program $strategyMethod"
	echo `date +"%T"` " best path="`which best`
	echo `date +"%T"` " besthome="`printenv besthome`
	
	echo `date +"%T"` " Started generating strategies"
	# Generating Strategy

	foreach solNum ($autoindexSolutions)

		echo `date +"%T"` " Started generating strategy for solution$solNum"

		# Check if the solution has been integrated
		set solDir = solution$solNum

		# Change Dir to this solution dir
		cd $solDir

		# Delete old input.xml
		rm -rf input.xml

		# Prepare params for run_generate_strategy.csh
		cat ../input.xml | awk -v predictedRes=$bestSolStats[1] -v detectorRes=$detectorRes -f $WEBICE_SCRIPT_DIR/prepare_run_generate_strategy.awk > input.xml

		# Run the script
		$WEBICE_SCRIPT_DIR/run_generate_strategy.csh $strategyMethod

		# Change dir back up one level
		cd ..

		chmod -R u+rwx $solDir
		chmod -R g+rx $solDir

		echo `date +"%T"` " Finished generating strategy for solution$solNum"

	# end integrate a solution
	end
	
	echo `date +"%T"` " Finished generating strategies"
	
#    endif # if strategyMethod script exists.
	
# end generating strategy
endif

echo `date +"%T"` " generate labelit.xml from run_integrate"
$WEBICE_SCRIPT_DIR/generate_labelit_xml.csh > LABELIT/labelit.xml
echo `date +"%T"` " generate labelit.tcl from run_integrate"
$WEBICE_SCRIPT_DIR/generate_labelit_tcl.csh > LABELIT/labelit.tcl
