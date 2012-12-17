#!/bin/csh -f

############################################################
#
# Creates and runs strategy scripts. Input parameters 
# are read from input.xml in current directory.
#
# Usage:
#	run_generate_strategy.csh
#
############################################################
#
# Steps:  
# 1. Read information from autoindexing and integration results: solution number, symmetry, resolution
# 2. Determine energy or energies to be used, according to experiment type, fluorescence scan information
# 2.1 With the energy information, determine the fractional anomalous difference expected for MAD and SAD
# 3. Determine beamstop distance
# 4. Determine detector distance
# 5. For each space group, run best to calculate exposure time, oscillation per image and total oscillation 
# 6. Read information to calculate the dose
# 7. For each space group, parse the BEST results
# 7.1 For each energy, calculate the dose
# 7.2 Calculate data collection wedges for MAD and SAD experiments
# 7.3 Write strategy files
#
# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

#echo `date +"%T"` " Started generating strategy"


# workDir is current dir
set workDir = `pwd`

set strategyMethod = "mosflm"
if ($#argv > 0) then
set strategyMethod = $argv[1]
endif

if (! -e ../LABELIT/labelit.out) then
	echo `date +"%T"` " Cannot find or failed to open ../labelit.out"
	exit 1
endif

set expType = `awk -f $WEBICE_SCRIPT_DIR/get_exp_type.awk ../input.xml`

# Parse input file
set params = (`awk -f $WEBICE_SCRIPT_DIR/get_run_generate_strategy_params.awk input.xml`)

if ($#params != 5) then
	echo `date +"%T"` " Invalid parameters in $workDir/input.xml"
	exit 1
endif

set imageDir = $params[1]
set image1 = $params[2]
set image2 = $params[3]
set runName = `cat ../input.xml | awk 'BEGIN{ ret = "default"; } {pos1 = index($0, "<runName>"); pos2 = index($0, "</runName>"); if ((pos1 > 0) && (pos2 > pos1)) {ret = substr($0, pos1+9, pos2-pos1-9);} } END{ print ret; }'`
echo `date +"%T"` " runName = $runName"

# Get solution number from dir name
set tmp = `basename $workDir`
set solNum = `echo $tmp | awk '{ print substr($0, length("solution")+1, 2); }'`		
set solNumStr = $solNum
echo `date +"%T"` " solNum = $solNum"
            
# If it has not been integrate by labelit, we will pick the lowest symmetry for 
# the lattice group of this solution.
set lattice = `awk -v solNum=$solNum -f $WEBICE_SCRIPT_DIR/get_autoindex_solution_lattice.awk ../LABELIT/labelit.out`

set spacegroups = `awk -v separator=" " -v lattice=$lattice -f $WEBICE_SCRIPT_DIR/get_all_spacegroups.awk $WEBICE_SCRIPT_DIR/latticegroups.txt`
        
# Get image index of one of the two images
set image = `echo $params[2] | awk -f $WEBICE_SCRIPT_DIR/get_image_index.awk`

set predictedRes = $params[4]
set detectorRes = $params[5]

set xx = `echo $detectorRes | awk '{ printf("%.2f", $1);}'`
echo `date +"%T"` " Predicted resolution = $predictedRes"
echo `date +"%T"` " Max detector resolution = $xx"

# Pick the bigger value of the predicted or max detector resolutions.
set res_used = `echo $params[4] " " $params[5] | awk '{ if ($1 > $2) { print $1 } else { print $2 } }'`

set tt = `ls index*.out`

###################Get parameters from image header, dcss dump file and beamline parameters

set rotationAxis = "Phi"

# Calculate energy and detector distance to calculate
# strategy to for resolution determined by the detector.
# Get detector info from image header
set info = (`awk -f $WEBICE_SCRIPT_DIR/get_detector_info.awk ../PARAMETERS/image_params.txt`)
set wv_header = $info[1]
set dzc_header = $info[2]
set en_header = `echo $wv_header | awk '{ print 12398.0/$1; }'`
set detectorType = $info[3] 
set detectorWidth = $info[4]
set detectorRadius = $info[5]
set detectorRes = $info[6]
set exposureTime = `echo $info[7] | awk '{printf("%.2f", $1);}'`
set oscRange = $info[8]
set detectorFormat = $info[9]

# Get beamline info (from dcss dump file) from beamline_param.txt
set b_info = (`awk -f $WEBICE_SCRIPT_DIR/get_beamline_info.awk ../PARAMETERS/dcs_params.txt`)

set b_energyUpper = $b_info[1]
set b_energyLower = $b_info[2]
set b_beamStopZUpper = $b_info[3]
set b_beamStopZLower = $b_info[4]
set b_detectorZCorrUpper = $b_info[5]
set b_detectorZCorrLower = $b_info[6]
set b_beamSizeX = $b_info[7]
set b_beamSizeY = $b_info[8]
set b_attenuation = $b_info[10]
set b_flux = $b_info[11]

# Attenuation  must be 0 or more and less than 100.
set bad_attenuation = `echo "$b_attenuation" | awk '{if (($1 >= 100) || ($1 < 0.0)) {print 1;} else {print 0;} }'`
if ($bad_attenuation == "1") then
   echo `date +"%T"` "Cannot calculate correct strategy with a beam attenuation of 100%"
    exit
endif

#Set parameters for all the space groups

#Q4 images are unbinned by default at SSRL; however, we should look at the pixel size to determine 'det'
set det = $detectorType
if ("$det" == "QUANTUM4") then
    set det = "QUANTUM4u"
else 
    if (("$det" == "mar345") || ("$det" == "MAR 345") || ($det == "MAR345")) then
	set det = "mar$detectorFormat"
    endif
endif

# If the test image was collected with attenuated beam we need to take it into account to calculate the correct exposure of the test image
set exposureTime = `echo "$exposureTime $b_attenuation" | awk '{ print $1*(100 - $2)/100 ; }'`


set phi_arr = (`awk '/gonio_phi/{print $5 " " $6;}' ../PARAMETERS/dcs_params.txt`)
set phi_scale = $phi_arr[1]
set phi_speed = $phi_arr[2]

# Get min/max exposure time from DCSS or from beamline.properties.
set beamline_limits = (`$WEBICE_SCRIPT_DIR/get_beamline_limits.csh`)
set min_exposure = $beamline_limits[1]
set max_exposure = $beamline_limits[2]
set min_attenuation = $beamline_limits[3]
set max_attenuation = $beamline_limits[4]

echo `date +"%T"` " min exposure = $min_exposure, max exposure = $max_exposure, min attenuation = $min_attenuation, max attenuation = $max_attenuation"

if ($min_exposure == "unknown") then
    set min_exposure = "2"
endif
if ($max_exposure == "unknown") then
    set max_exposure = "600" # 10 minutes
endif
if ($min_attenuation == "unknown") then
    set min_attenuation = "0.0"
endif
if ($max_attenuation == "unknown") then
    set max_attenuation = "99.5"
endif


#########################################Energies and beamstop to sample distance########################

set en_used = $en_header
set wv_used = $wv_header
set energy1 = `echo $en_used | awk '{ printf("%.1f", $1);}'`
set energy2 = "0.0"
set energy3 = "0.0"
set energy4 = "0.0"
set energy5 = "0.0"

set energy1Warning = ""
set energy2Warning = ""
set energy3Warning = ""


set numEnergies = "1"

set element = ""
set edge = ""

#Get  parameters from the input file

  set numHeavyAtoms = `awk 'BEGIN{ ret = "0"; } {pos1 = index($0, "<numHeavyAtoms>"); pos2 = index($0, "</numHeavyAtoms>"); if ((pos1 > 0) && (pos2 > pos1)) {ret = substr($0, pos1+15, pos2-pos1-15);} } END{ print ret; }' ../input.xml`
 set numResidues = `awk 'BEGIN{ ret = "0"; } {pos1 = index($0, "<numResidues>"); pos2 = index($0, "</numResidues>"); if ((pos1 > 0) && (pos2 > pos1)) {ret = substr($0, pos1+13, pos2-pos1-13);} } END{ print ret; }' ../input.xml`


if ($expType != "Native") then

    set en_arr = (`awk -f $WEBICE_SCRIPT_DIR/get_mad_energies.awk ../input.xml`)
    set en_used = $energy1
    set wv_used = `echo $en_used | awk '{ print 12398.0/$1; }'`
    # Only do peak energy for SAD

    if ($expType == "SAD") then
	set energy1 = $en_arr[2]
    endif

    if ($#en_arr > 3) then
	set element = $en_arr[4]
	set edge = $en_arr[5]
    endif


    if ($expType == "MAD") then
	
       set isZeroEnergy1 = `echo $en_arr[2]  | awk '{if ($1 == 0.0) {print 1;} else {print 0;}}'`

       if ($isZeroEnergy1 == 1) then

	    # energy1 is inflection
	    set energy1 = $en_arr[1]
	    set energy2 = $en_arr[3]
	    set energy3 = 0
	else 

	    # peak
	    set energy1 = $en_arr[2]
	    # remote
	    set energy2 = $en_arr[3]
	    # inflection
	    set energy3 = $en_arr[1]

       endif #isZeroEnergy1

    endif #($expType == "MAD")

    # Calculate anomalous signal:
    set anomsign = (`$WEBICE_SCRIPT_DIR/anomsignal.pl /data/$USER/webice/autoindex/${runName}/scan/${runName}summary $numHeavyAtoms $numResidues $expType $element $energy1 $energy2 $energy3`)    
    if ($status == 0 ) then
	echo `date +"%T"` " Fractional anomalous difference: $anomsign[1]; dispersive difference: $anomsign[2]; effective difference: $anomsign[3]"
     endif

endif #($expType != "Native")


# Low resolution limit in Angstrom
set lowRes = 40;            #should be in beamline properties
# Beam stop radius in mm
set beamStopRadius = 0.8;        #should be in beamline properties
set beamStopZWarning = "";
#echo "wv_used = $wv_used, en_used = $en_used, lowRes = $lowRes, beamStopRadius = $beamStopRadius"
set beamStopZ = `echo "$wv_used $lowRes $beamStopRadius" | awk '{ a = $1/(2.0*$2); b = sqrt(1.0-a^2); asin_a = atan2(a,b); x = (2.0*asin_a); tanx = sin(x)/cos(x); ret = $3/tanx; print ret;}'`
# Check if the calculated beamstop distance is shorter than the lower software limit
set test = `echo "$beamStopZ $b_beamStopZLower" | awk '{ if ($1+0 < $2+0) {print "1";} else {print "0"}}'`

if ($test) then
    set beamStopZ = $b_beamStopZLower
endif

set beamStopZ = `echo $beamStopZ | awk '{ printf("%.1f", $1);}'`

set inverseBeam = "0";
set rotationAxis = "Phi"
set kappaOffset = "0";


########################Determine detector to sample distance to collect data to required resolution

# Use dzc and energy from the header. 
set dzc_used = $dzc_header
set maxres = $predictedRes
set dzc_maxres = `echo "$wv_used $predictedRes $detectorRadius" | awk '{ a = $1/(2.0*$2); b = sqrt(1.0-a^2); asin_a = atan2(a,b); x = (2.0*asin_a); tanx = sin(x)/cos(x); ret = $3/tanx; print ret;}'`

set recal_en = 0

# Step 1.1
# Check if calculated detector_z_corr is shorter than the one from the header
# then give warning
set dzc_warning = ""
set test = `echo "$dzc_maxres $dzc_used" | awk '{ if ($1+0 < $2+0) {print "1";} else {print "0"}}'`
if ($test) then
    set test = `echo "$dzc_maxres $b_detectorZCorrLower" | awk '{ if ($1+0 < $2+0) { print "1";} else {print "0";}}'`
    if ($test) then
	set recal_en = 1
	set dzc_maxres = $b_detectorZCorrLower
    endif
    set xx = `echo $dzc_maxres | awk '{ printf("%.1f", $1);}'`
    set dzc_warning = "To measure higher resolution data, move the detector to $xx mm and recollect test images."
endif

# Step 1.2
# Check if calculated detector_z_corr is longer than the one from the header
# then give warning
set test = `echo "$dzc_maxres $dzc_used" | awk '{ if ($1+0 > $2+0) {print "1";} else {print "0"}}'`
if ($test) then
    set dzc_used = $dzc_maxres
    # Check if the calculated detector_z_corr is longer than the upper software limit
    set test = `echo "$dzc_used $b_detectorZCorrUpper" | awk '{ if ($1+0 > $2+0) {print "1";} else {print "0"}}'`
    if ($test) then
	set xx = `echo $dzc_used | awk '{ printf("%.1f", $1);}'`
	set dzc_warning = "The calculated detector distance ($xx mm) is too long. The value is reset to the limit value. \
Full detector surface will not be used at this detector distance."
	set dzc_used = $b_detectorZCorrUpper
    endif
endif

set dzc_used = `echo $dzc_used | awk '{ printf("%.1f", $1);}'`

# Step 1.3

# At this point we have the correct detector_z_corr distance.
# Now deal with energy (only for native experiments, for MAD and SAD stick to the calculated energies)
set en_warning = ""

if ($expType == "Native") then

    # Check if the energy that gives the highest resolution is higher than the upper limit
    if ($recal_en) then
	set wv_dzc_lowest = `echo "$detectorRadius $predictedRes $b_detectorZCorrLower" | awk '{ wl = 2.0 * $2 * sin(atan2($1,$3)/2.0); print wl; }'`
	set en_dzc_lowest = `echo $wv_dzc_lowest | awk '{ print 12398.0/$1; }'`
	set test = `echo "$en_dzc_lowest $b_energyUpper" | awk '{ if ($1+0 > $2+0) {print "1";} else {print "0"}}'`
	if ($test) then
	    set wv_enUpper = `echo $b_energyUpper | awk '{ print 12398.0/$1; }'`
	    set maxres = `echo "$wv_enUpper $detectorRadius $b_detectorZCorrLower" | awk '{ res = $1/(2.0 * sin(atan2($2,$3)/2.0)); print res; }'`
	    set xx = `echo $en_dzc_lowest | awk '{ printf("%.1f", $1);}'`
	    set yy = `echo $b_energyUpper | awk '{ printf("%.1f", $1);}'`
	    set zz = `echo $maxres | awk '{ printf("%.2f", $1);}'`
	    set en_warning = "The calculated energy to get the predicted resolution ($xx eV) is higher than the upper limit at the beamline ($yy eV). The maximum resolution for complete data at ${yy} eV is $zz &#197;."
	else # en_dzc_lowest <= b_energyUpper
	    set test = `echo "$maxres $detectorRes" | awk '{ if ($1+0 < $2+0) {print "1";} else {print "0"}}'`
	    if ($test) then
		set xx = `echo $maxres | awk '{ printf("%.2f", $1);}'`
		set yy = `echo $en_dzc_lowest | awk '{ printf("%.1f", $1);}'`
		set en_warning = "To try to measure data to $xx &#197;, change the energy to ${yy} mm and recollect test images."
	    endif
	endif # en_dzc_lowest > b_energyUpper
    endif # recal_en == 1

endif # expType == Native


################MOSFLM strategy stuff - we need this to run TESTGEN
# Get the spot separation values from indexNNN.out 
set spotSep = (`awk 'BEGIN{found=0;}/\(SEPARATION\) In scanner X,Y directions/ {if (found==0) { found = 1;print $6 " " substr($7, 1, length($7)-2);}}' $tt`)

# Try searching for old keywords (for older version of mosflm)
if ($#spotSep != 2) then
  set spotSep = (`awk '/^ parameters \(in X and Y\) have been set to/ {print $10 " " substr($11, 1, length($11)-3);}' $tt`)
endif

if ($#spotSep != 2) then
  echo `date +"%T"` " Warning spot separation could not be extracted from $tt. Use default value of 0.1 0.1."
  set spotSep = (`echo "0.1 0.1"`)
endif

echo `date +"%T"` " spot separation = $spotSep[1] $spotSep[2]"
#
set gain = `awk '/^gain/{print $2;}' ../PARAMETERS/beamline.properties`

if ($strategyMethod == "best") then
    # phi range will be caluclated later on by best
    set phi1range =
    set phi2range =
# Create testgen script - only once per solution!

awk -v matrix=index$solNum.mat -v image=$image \
	-v spacegroup=$spacegroups[1] -v type=testgen -v outputFile=testgen.mfm \
	-v phiStart=0.0 -v phiEnd=180 \
	-v maxRes=$res_used \
	-v sep1=$spotSep[1] -v sep2=$spotSep[2] \
	-v distance=$dzc_used \
	-v gain=$gain \
	-f $WEBICE_SCRIPT_DIR/create_mosflm_strategy_script.awk index$solNum.mfm

chmod u+rwx *.mfm
	
echo `date +"%T"` " Running mosflm testgen script for overlap analysis"
# Run testgen
./testgen.mfm
 echo `date +"%T"` " Finished running overlap analysis"

set maxDeltaPhi = `awk -f $WEBICE_SCRIPT_DIR/get_testgen_summary.awk $workDir/testgen.out`

endif # if strategyMethod == best

# Create subdir for each spacegroup
foreach sp ($spacegroups)
    
    echo `date +"%T"` " Started generating strategy for spacegroup $sp"
    echo `date +"%T"` " Generating strategy scripts"
    if (! -d $sp) then
    	mkdir $sp
    endif
    cd $sp

    #########################MOSFLM strategy
    if ($strategyMethod == "mosflm") then
	
    # Copy matrix file
    cp ../index$solNum.mat .

    # Create strategy scripts from template
    touch strategy.mfm
    awk -v matrix=index$solNum.mat -v image=$image \
		-v spacegroup=$sp -v type=complete -v outputFile=strategy.mfm \
		-v maxRes=$res_used \
	    	-v distance=$dzc_used \
		-v gain=$gain \
	    -f $WEBICE_SCRIPT_DIR/create_mosflm_strategy_script.awk ../index$solNum.mfm
    awk -v matrix=index$solNum.mat -v image=$image \
		-v spacegroup=$sp -v type=anom -v outputFile=strategy_anom.mfm \
		-v maxRes=$res_used \
	    	-v distance=$dzc_used \
		-v gain=$gain \
	    -f $WEBICE_SCRIPT_DIR/create_mosflm_strategy_script.awk ../index$solNum.mfm
	
     # Make mosflm script executable
     chmod u+rwx *.mfm
	
     echo `date +"%T"` " Running mosflm strategy scripts"
     # Run mosflm scripts
     ./strategy.mfm
     ./strategy_anom.mfm
		
     echo `date +"%T"` " Generating mosflm testgen scripts"
     # Get start/end phi for each type of strategy
     set phi1 = (`awk '{ if ($1 == "From" && $3 == "to" && $5 == "degrees") { print  $2 " " $4 } }' strategy.out`)
     set phi2 = (`awk '{ if ($1 == "From" && $3 == "to" && $5 == "degrees") { print  $2 " " $4 } }' strategy_anom.out`)
     #Use phi range to calculate exposure time with best
     set phi1range = `echo $phi1[1] $phi1[2] | awk '{print "-p " $1 " " $2 - $1}'` 
     set phi2range = `echo $phi2[1] $phi2[2] | awk '{print "-p " $2 " " $2 - $1}'`
     #echo  $phi1range $phi2range
     			
     # Get lowest start and highest end phi.
     set phiStart = `echo $phi1[1] " " $phi2[1] | awk '{ if ($1 < $2) { print $1 } else { print $2 } }'`
     set phiEnd = `echo $phi1[2] " " $phi2[2] | awk '{ if ($1 > $2) { print $1 } else { print $2 } }'`
     			
     # Create testgen script
     awk -v matrix=index$solNum.mat -v image=$image \
		-v spacegroup=$sp -v type=testgen -v outputFile=testgen.mfm \
	    -v phiStart=$phiStart -v phiEnd=$phiEnd \
	    -v maxRes=$res_used \
	    -v sep1=$spotSep[1] -v sep2=$spotSep[2] \
	    -v distance=$dzc_used \
	    -v gain=$gain \
	    -f $WEBICE_SCRIPT_DIR/create_mosflm_strategy_script.awk ../index$solNum.mfm
	
     # Make mosflm script executable
     chmod u+rwx *.mfm
	
    echo `date +"%T"` " Running mosflm testgen scripts"
    # Run testgen
    ./testgen.mfm

    set maxDeltaPhi = `awk -f $WEBICE_SCRIPT_DIR/get_testgen_summary.awk testgen.out`

    
    echo `date +"%T"` " Finished MOSFLM strategy for spacegroup $sp"
    
    endif # if strategyMethod == mosflm
    
    #########################BEST strategy


    # Calculate exposure time and oscillation range for data collection strategy
    # Run for each space group
    # Get hkl files (one for each image)
    if (! -e bestfile.dat) then
    	ln  ../../LABELIT/bestfile.dat bestfile.dat
    endif
    if (! -e best${solNum}.par) then
    	ln  ../../LABELIT/best${solNum}.par best${solNum}.par
    endif
    cp ../../LABELIT/index${solNum}*.hkl  . 

    # Take the first one
    set tt = `which best | awk '{if (index($0, "/") == 1) { print "1";} else { print "0";} }'`
	
    set arr = (`ls index${solNum}*.hkl`)
    cp $arr[1] bestfile.hkl


    set sg = `echo $sp | sed 's/[A-Z]//g'`

    # Create best script so that user can run it from the command line later
    # Add -i2s [I/Sigma] to change I/Sigma from default == 2.0. 
    # overallMini2s is the target for the overall I/SigmaI
    set i2s = 2.0
    set overallMini2s = 10.0

    ## tt : true if path to best is defined
    if ($tt) then 
        #Sometimes for low resolution crystals the overall I/sigI predicted by best is very low. Rerun best with a higher target i2s is this is the case 
	set ovi2s = 0
	set isAvi2sLow = 1
        #If there are zeros in the bestdat file, make them into 1s...
        cat bestfile.dat | awk ' {if ($3 == 0 || $2 == 0)  printf "%10.4f      1      1\n", $1 ; else print $0} ' > tmp
        mv tmp bestfile.dat
        while ($isAvi2sLow)
	    set cshpath = `which csh`
	    echo "#!"$cshpath" -f" > run_best.csh
	    echo "source $WEBICE_SCRIPT_DIR/setup_env.csh" >> run_best.csh
	    cp run_best.csh run_best_anom.csh
	    echo "best -f $det -i2s $i2s -e none -t $exposureTime -sg $sg -r $predictedRes $phi1range -mo bestfile.dat best${solNum}.par $arr[1] $arr[2]" >> run_best.csh
	    echo "best -f $det -i2s $i2s -e none -a -t $exposureTime -sg $sg -r $predictedRes $phi2range -mo bestfile.dat best${solNum}.par $arr[1] $arr[2]" >> run_best_anom.csh
	     
	    best -f $det -i2s $i2s -e none -t $exposureTime -sg $sg -r $predictedRes $phi1range -mo bestfile.dat best${solNum}.par $arr[1] $arr[2] >& best.out
	    best -f $det -i2s $i2s -e none -a -t $exposureTime -sg $sg -r $predictedRes $phi2range -mo bestfile.dat best${solNum}.par $arr[1] $arr[2] >& best_anom.out

	    # Extract width and exposure time and other best results from best.out to best.xml
	    set best_err = (`awk '/core dumped|Abort process|ERROR/{print $0;}' best.out`)
	    if ("$best_err" == "") then
		awk -f $WEBICE_SCRIPT_DIR/get_best_summary.awk best.out>best_summary.out
		awk -f $WEBICE_SCRIPT_DIR/get_best_summary.awk best_anom.out>>best_summary.out
		set best_test = (`cat best_summary.out`)
		#echo $best_test
		if ("$best_test" == "") then
		    set best_err = "Failed to extract exposure time from best output file"
		endif
	    endif
	    if ("$best_err" != "") then
		echo "width=unknown" > best_summary.out
		echo "exposureTime=unkown" >> best_summary.out
		echo "error=BEST software error: $best_err" >> best_summary.out
		echo `date +"%T"` "error=BEST software error: $best_err"
		set isAvi2sLow = 0 #exit loop
	    else
		if ($expType == "Native") then
		    set ovi2s = (`awk -F= '/overall_IsigI_u/{ print $2; }' best_summary.out`)
		else
		    set ovi2s = (`awk -F= '/overall_IsigI_a/{ print $2; }' best_summary.out`)
		endif
		echo `date +"%T"` " Overall I/sigI is $ovi2s for $sp."
		set isAvi2sLow = `echo "$ovi2s $overallMini2s" | awk '{ if ($1 < $2) {print 1;} else {print 0;}}' `
                set i2s = `echo $i2s | awk '{print $1 + 1}'` 
                if ($isAvi2sLow == 1) echo `date +"%T"` " Overall I/sigI is lower than $overallMini2s. Re-running BEST with am I/sigI target of $i2s for the highest resolution shell  "
 
            endif 
	end
     else
	echo "width=unknown" > best_summary.out
	echo "exposureTime=unkown" >> best_summary.out
	echo "error=BEST software is not available on this system." >> best_summary.out
    endif     

    # Generate strategy.xml
    $WEBICE_SCRIPT_DIR/generate_strategy_xml.csh > strategy.xml
    # Generate strategy.tcl
    $WEBICE_SCRIPT_DIR/generate_strategy_tcl.csh > strategy.tcl

cd $workDir

end

##### High mosaicity/low crystal quality (scored based) warning from autoindex

set labelit_result = (`awk -v outputType=raw -f $WEBICE_SCRIPT_DIR/parse_labelit_out.awk ../LABELIT/labelit.out`)
set labelit_mosaicity = (`awk -v outputType=mosaicity -f $WEBICE_SCRIPT_DIR/parse_labelit_out.awk ../LABELIT/labelit.out`)
set labelit_score = (`awk -v outputType=score -f $WEBICE_SCRIPT_DIR/parse_labelit_out.awk ../LABELIT/labelit.out`)
set labelit_status = `echo "$labelit_result" | awk '{ if (index($0, "60%(POOR)") > 0) {print "warning";} else { print "ok";}}'`
set autoindexWarning = ""
if ("$labelit_status" == "warning") then
	set labelit_result = ($labelit_result" Please inspect autoindex results before using this strategy.")
	set autoindexWarning = ($labelit_result)
endif

echo "<strategySummary>" > strategy_summary.xml
echo '  <autoindex result="'$labelit_result'" status="'$labelit_status'" mosaicity="'$labelit_mosaicity'" score="'$labelit_score'" />'  >> strategy_summary.xml
echo "{ strategySummary" > strategy_summary.tcl

#Get some space-group independent parameters that will be used for dose calculation

# Calculate radiation dose
set beamFullX = `awk '/beam_full/{print $2;}' ../PARAMETERS/beamline.properties`
set beamFullY = `awk '/beam_full/{print $3;}' ../PARAMETERS/beamline.properties`
#The beam size defined by the slits cannot be larger than the true maximum beam size 
set beamSizeX = `echo $b_beamSizeX $beamFullX | awk ' {if ($1 > $2) { print $2;} else {printf ("%.3f", $1);};}' `
set beamSizeY = `echo $b_beamSizeY $beamFullY | awk ' {if ($1 > $2) { print $2;} else {printf ("%.3f", $1);};}' `
#
set gauss = ($beamSizeX $beamSizeY)

set cell = `awk -v sol=$solNum 'BEGIN {start = 0;}; /Metric/{ start = 1; }; /SpaceGroup/{ start = 0; }; { if ((start == 1) && ($2 == sol)) { print $9 " " $10 " " $11 " " $12 " " $13 " " $14; };}' ../LABELIT/labelit.out`
set cellVolume = `awk -v sol=$solNum 'BEGIN {start = 0;}; /Metric/{ start = 1; }; /SpaceGroup/{ start = 0; }; { if ((start == 1) && ($2 == sol)) { print $15; };}' ../LABELIT/labelit.out`

set solv = 0.5 #solvent content is 50% by default
	
# Henderson limit for raddose 
#In the 2008 version of raddose, the hendli (Henderson-limit) keyword has been replaced by USERLI (user defined limit)

set doselimit = "USERLI"
set raddose_v = `which raddose`
echo `date +"%T"` " RADDOSE path: $raddose_v "
set raddose_log = new
if ($raddose_v == "/home/sw/rhel4/raddose/20031207/raddose") then 
    set doselimit = "HENDLI"
    set raddose_log = old
endif

set hendli = "3.0e+07"

# Half the limit for MAD or SAD
# Two reasons for this (see bug #998)
# 1) Experiments show that phasing experiments are very sensitive to dose
# 2) The dose may be underestimated when the protein contains heavy atoms
if (($expType == "SAD") || ($expType == "MAD")) then
    set hendli = "1.5e+07"
endif

if ($expType == "SAD") then
	set inverseBeam = "1";
endif

 set radDoseWarningU = ""
 set radDoseWarningA = ""
 set radDoseTotalU = "unknown"
 set radDoseTotalA = "unknown"
 set maxImages = ""
 
 set maxImagesEn1 = 0.0
 set radDoseEn1PerImg = 0.0
 set radDoseEn1U = 0.0
 set radDoseEn1A = 0.0

 set maxImagesEn2 = 0.0
 set radDoseEn2PerImg = 0.0
 set radDoseEn2U = 0.0
 set radDoseEn2A = 0.0

 set maxImagesEn3 = 0.0
 set radDoseEn3PerImg = 0.0
 set radDoseEn3U = 0.0
 set radDoseEn3A = 0.0
 
 set countEn = 0
 # The beam size is used to calculate the flux as follows:
 # If using a circular collimator or beam defining slits, the flux is scaled according to the dimensions of the aperture used to measure the flux.
 # If the beam is focussed (rather than slitted down) no scaling is done 
 # defBeamArea can be ignored if we can calculate the flux directly from an ion chamber or photodiode (ie, if b_flux is not "unknown")
 set defBeamArea = `awk -v x=$beamSizeX -v y=$beamSizeY '/^flux_aperture/{if (NF == 2) {print $2*$2/4.0;} else if (NF == 3) {print $2*$3;} else {print x*y;}}' ../PARAMETERS/beamline.properties`
 set flux_corr = 1
 if ($b_flux != "unknown") then
    set en = `echo $en_used | awk '{ print $1/1000.0; }'`      
    set fluxCal = `awk -v energy=$en -f $WEBICE_SCRIPT_DIR/get_intensity.awk ../PARAMETERS/beamline.properties`
    # echo "Calculated  flux at current energy is $fluxCal. Measured flux is $b_flux " 
    set flux_corr = `echo $b_flux $fluxCal | awk '{ A =  $1/$2 ; print A;}'`
    # echo `date +"%T"` " A flux correction factor of $flux_corr was calculated at the conditions used for the test images: $en_used eV and attenuation $b_attenuation %." 
 endif

 set radDoseErr = ""
 
#This refers to the exposure time per degree for the INITIAL images:
    set exposureTimePerDegree = `echo "$exposureTime $oscRange" | awk '{ print $1/$2 ; }'`

# Loop over each Laue group to calculate the full data collection stratgey

foreach sp ($spacegroups)

    # Get results from BEST
    set best_arr = (`awk -F= '/width/{ width = $2; }; /exposureTime/{ ex = $2; } END { print width " " ex; }' $sp/best_summary.out`)
    set best_err  = (`awk -F= '/err/{ print $2; }' $sp/best_summary.out`)
    set best_width = ""
    set best_exposureTime = ""
    if ($#best_arr == 2) then
        set thin_slice = `awk '/thin_slice/{print $2;}' ../PARAMETERS/beamline.properties`
	set best_width = $best_arr[1]
	set best_exposureTime = $best_arr[2]
    else
	    if ("$best_err" == "") then
		set best_err = "Cannot find width and exposure time from best_summary.out"
	    endif
    endif

    if ("$best_exposureTime" != "unknown") then

	# The exposure time per image estimated by BEST ($best_exposureTimePerImage) 
	# is much lower than the exposure time per image used for the test images.($exposureTimePerImage).

	# Get overloaded spots from image_stats.out generated by labelit.distl
	set overloaded_spots = (`awk 'BEGIN{ count = 0; pix1 = 0; pix2 = 0;}; /In-Resolution Ovrld Spots :/{ ++count; if (count == 1) {pix1 = $5;} else { pix2 = $5;} }; END{ print pix1 " " pix2; }' ../LABELIT/image_stats.out`)
	set exposureTimeWarning = ""
	set hasOverloadedSpots = 0
	# Check if image1 has overloaded spots
	if ($overloaded_spots[1] != "0") then
	    set exposureTimeWarning = "Image1 had $overloaded_spots[1] overloaded spots"
	    set hasOverloadedSpots = 1
	endif
	# Check if image2 has overloaded spots
	if ($overloaded_spots[2] != "0") then
	    # check if image1 has overload spots as well
	    if ($hasOverloadedSpots == 1) then
		set exposureTimeWarning = "${exposureTimeWarning}, image2 had $overloaded_spots[2] overloaded spots"
		else
		set exposureTimeWarning = "Image2 had $overloaded_spots[2] overloaded spots"
	    endif
	    set hasOverloadedSpots = 1
	endif
	
	# Check if best exposure time is 10 times less than the exposure time in the test images.
	# Do not use best exposure time in this case.
#	set too_small = `echo $best_exposureTimePerImg $exposureTimePerImg | awk '{if ($1*10 < ($2+0)) {print "1";} else {print "0";}}'`
#	if ($too_small == 1) then
#		set exposureTimePerImageUsed = $exposureTimePerImg
#	endif	
 	
	if ($hasOverloadedSpots == 1) then
	    set exposureTimeWarning = "${exposureTimeWarning} with exposure time ${exposureTime} sec (for $oscRange deg oscillation)."
	    # if best exposure time is less than current exposure time and we have overloaded spots
	    # then suggest using BEST
	    set test = `echo "$best_exposureTime $exposureTime" | awk '{ if ($1+0 < $2+0) {print "1";} else {print "0"}}'`
	    if ($test) then
		set exposureTimeWarning = "$exposureTimeWarning"
	    else
		set exposureTimeWarning = "${exposureTimeWarning}."
	    endif
	endif
    endif

    set dataU = (0 0 0)
    set dataA = (0 0 0)
    if ($strategyMethod == "best") then
	if ("$best_err" == "") then
		set dataU = (`awk -F= '/phiMin_u/{ phiMin = $2; }; /phiMax_u/{ phiMax = $2; }; /completeness_u/{complete = $2}; END { print phiMin" "phiMax" "complete ; }' $sp/best_summary.out`)
		set dataA = (`awk -F= '/phiMin_a/{ phiMin = $2; }; /phiMax_a/{ phiMax = $2; }; /completeness_a/{complete = $2}; END { print phiMin" "phiMax" "complete ; }' $sp/best_summary.out`)	
	endif
     else # if strategyMethod == "best"
    	set dataU = (`awk -f $WEBICE_SCRIPT_DIR/get_strategy_summary.awk $sp/strategy.out`)     
	set dataA = (`awk -f $WEBICE_SCRIPT_DIR/get_strategy_summary.awk $sp/strategy_anom.out`)        
     endif # if strategyMethod == "best"

     if (($expType == "SAD") || ($expType == "MAD")) then
	#Increase data redundancy for MAD/SAD
	set Uf = $dataU[2]
	set Ui = $dataU[1]
	set Af = $dataA[2]
	set Ai = $dataA[1]

	set dataU[2] = `echo "2* $Uf - $Ui " | bc` 
	set dataA[2] = `echo "2* $Af - $Ai " | bc`
     endif

    ################## Oscillation angle ######


    #The oscillation angle should not exceed maxDeltaPhi (from testgen overlap analysis)

    set oscAngle = `echo $best_width $maxDeltaPhi | awk '{if ($1 >= $2) {print $2;} else {print $1}}'`   
    #We also do not want to the oscillation angle to exceed 1 degree
    set test = `echo $oscAngle | awk '{ if ($1+0 >= 1.0) {print "1";} else {print "0"}}'`
    if ($test) then
	set oscAngle = 1.0
    endif

    # If the detector is Pilatus, we have the option to collect data in
    #thin slices, by setting the keyword thin_slice in the beamline properties
    #file 
    #echo $detectorType $thin_slice
    if (($detectorType == "PILATUS6") && ($thin_slice != "") ) then
	set oscAngle = $thin_slice
	echo `date +"%T"` "An oscillation per image of $thin_slice degrees will be used with the Pilatus detector."
    endif 


    ############## Exposure time #####
    # Exposure time per image for the test images if we use the best calculated oscillation angle
    set exposureTimePerImg = `echo "$exposureTimePerDegree $oscAngle" | awk '{ ret = $1*$2; printf("%.3f", ret);}'`

    set best_exposureTimePerImg = "0.0"
    set best_exposureTimePerDegree = "0.0"
    set best_exposureTimeWarning = "$best_err"
    set exposureTimePerImageUsed = $exposureTimePerImg;
    set attenuation = "0.0"
    set attenuationWarning = ""

    if ("$best_err" == "") then

	# calculate BEST exposure time per image
	if ($best_exposureTime != "unknown") then
	  set best_exposureTimePerImg = `echo "$best_exposureTime $best_width $oscAngle" | awk '{ ret = $1*$3/$2; printf("%.3f", ret); }'`
	  set best_exposureTimePerDegree = `echo "$best_exposureTime $best_width" | awk '{ ret = $1/$2; printf("%.3f", ret); }'`
	endif

	set best_exposureTime = `echo $best_exposureTime | awk '{printf("%.3f", $1);}'`
	set best_exposureTimePerImg = `echo $best_exposureTimePerImg | awk '{printf("%.3f", $1);}'`
	set exposureTimePerImageUsed = $best_exposureTimePerImg 

	if (($expType == "SAD") || ($expType == "MAD")) then
	    #Half the exposure time (we are collecting twice the number of images!)
	    set exposureTimePerImageUsed = `echo "scale=3; $exposureTimePerImageUsed / 2" | bc`
	endif
	
	
	# Check if best exposure time is 10 times less than the exposure time in the test images.
	# Do not use best exposure time in this case.
#	set too_small = `echo $best_exposureTimePerImg $exposureTimePerImg | awk '{if ($1*10 < ($2+0)) {print "1";} else {print "0";}}'`
#	if ($too_small == 1) then
#		set exposureTimePerImageUsed = $exposureTimePerImg
#	endif	
 	
	# Min exposure time per image due to gonio phi speed
	set min_phi_exposure = `echo "$phi_scale $phi_speed $oscAngle" | awk '{ printf("%.3f", $3*$1/$2);}'`
        #echo $min_phi_exposure
	# lowest exposure time is the smaller of min phi exposure and min_exposure (due to shutter speed and other factors).
	set lowest_exposure = `echo "$min_exposure $min_phi_exposure" | awk '{ if ($1 > $2) {print $1;} else {print $2}}'`
			  
	# If exposure time per image is less than lowest exposure per image
	# (depending on the shutter speed and characteristics and phi speed), 
	# then calculate attenuation.
	set test = `echo "$exposureTimePerImageUsed $lowest_exposure" | awk '{ if ($1+0 < $2) {print "1";} else {print "0"}}'`
	if ($test) then
	    set attenuation = `echo "$lowest_exposure $exposureTimePerImageUsed" | awk '{ printf("%.3f", ($1 - $2)*100.0/$1);}'`
	    set exposureTimePerImageUsed = $lowest_exposure

        #echo $exposureTimePerImageUsed
        #echo "ATTENUATION " $attenuation
	endif
		
	# Check that attenuation is less than max attenuation value from DCSS or from beamline.properties file.
	set too_big = `echo $attenuation $max_attenuation | awk '{if ($1 > $2) {print 1;} else {print 0;}}'`
	if ($too_big == 1) then
		set attenuationWarning = "The calculated attenuation ("`echo $attenuation | awk '{printf("%.1f", $1);}'`") exceeds max attenuation allowed (${max_attenuation}). Max attenuation is used."
		set attenuation = $max_attenuation
	endif		  

	set exposureTimePerImageUsed = `echo $exposureTimePerImageUsed | awk '{ printf("%.2f", $1);}'`

	# Make sure that exposure time is less than max exposure time value from DCSS or from beamline.properties file.
	set too_big = `echo $exposureTimePerImageUsed $max_exposure | awk '{if ($1 > $2) {print 1;} else {print 0;}}'`	  
	if ($too_big == 1) then
		set exposureTimeWarning = "The optimal exposure (${exposureTimePerImageUsed} secs) is too high, and has been reset to ${max_exposure} secs. If you do not exceed the dose limit, consider collecting more images."
		set exposureTimePerImageUsed = $max_exposure
	endif		  

   endif # has best error
	
    # Determine detector mode from exposure time from BEST
    set arr = `echo "$detectorType" | awk -v extime=$exposureTimePerImageUsed -v format=$detectorFormat -f $WEBICE_SCRIPT_DIR/get_detector_mode.awk`
    set detectorModeInt = $arr[1]
    set detectorMode = $arr[2]
    
    set imageNumU = `echo "$dataU[1] $dataU[2] $oscAngle" | awk '{ print ($2 - $1)/$3; }' | awk -f $WEBICE_SCRIPT_DIR/roundup.awk`;
    set imageNumA = `echo "$dataA[1] $dataA[2] $oscAngle" | awk '{ print ($2 - $1)/$3; }' | awk -f $WEBICE_SCRIPT_DIR/roundup.awk`;
        
    if ("$expType" == "SAD") then
    	set imageNumU = `echo $imageNumU | awk '{print $1*2.0;}'`
    	set imageNumA = `echo $imageNumA | awk '{print $1*2.0;}'`
    endif
    
    set failed = `echo $dataU[3] | awk '{ tmp = substr($1, 1, length($1)-1) + 0; if (tmp < 95) {print "1";} else {print "0"}}'`;
    set imageNumUWarning = "";
    if ($failed) then
    	set imageNumUWarning = "The completeness is less than 95%";
    endif
    
    set failed = `echo $dataA[3] | awk '{ tmp = substr($1, 1, length($1)-1) + 0; if (tmp < 95) {print "1";} else {print "0"}}'`;
    set imageNumAWarning = "";
    if ($failed) then
    	set imageNumAWarning = "The completeness is less than 95%";
    endif
	

    # Run raddose for each energy (peak, remote, inflection) that is not 0.0
    if (! -d $sp/RADDOSE) then
    	mkdir $sp/RADDOSE
    endif

    #calculate estimated number of monomers for each possible space group
    set nmon = ""

    if ("$numResidues" != "0") then
	$WEBICE_SCRIPT_DIR/run_matthews_coef.csh $numResidues $sp $cell $predictedRes > $sp/RADDOSE/matthews_coef.out
	if (-e MATTHEWS_COEF.xml) then
	    mv MATTHEWS_COEF.xml $sp/RADDOSE/
	    set matthews = (`awk -f $WEBICE_SCRIPT_DIR/parse_matthews_coef.awk $sp/RADDOSE/MATTHEWS_COEF.xml`)
	    if ($#matthews == 2) then
		set nmon = $matthews[1]
		set symops = `cat $WEBICE_SCRIPT_DIR/symops.txt | awk '{if ($1 =="'$sp'")print $2}'`
		set nmon = `echo $nmon $symops | awk '{print $1 * $2}'`
		set solv = $matthews[2]
	    endif
	endif
    endif
    @ i = 0

    #Calculate the difference between the measured and calculated value of the flux for the current beam energy
    
    foreach enOrg ($energy1 $energy2 $energy3)
 
    	set isZeroEnergy = `echo $enOrg | awk '{if ($1 == 0.0) {print 1;} else {print 0;}}'`

    	if ($isZeroEnergy == 1) then
    		continue		     
    	endif

        @ i++
    	set countEn = `echo $countEn | awk '{print $1 + 1;}'`
	set en = `echo $enOrg | awk '{ print $1/1000.0; }'`
        # If the energy for the experiment is the same of closed to the current energy, used the measured flux to estimate the dose
	# For different energies, apply the flux_corr value calculated above
	set isEnergyUsed = `echo $enOrg $en_used | awk '{ A = $1-$2; if (A < 0) A = -A; if (A < 10) {print 1} else {print 0}}' ` 
        set fluxCal = `awk -v energy=$en -f $WEBICE_SCRIPT_DIR/get_intensity.awk ../PARAMETERS/beamline.properties`
	set fluxAlt = `echo $beamSizeX $beamSizeY $defBeamArea $fluxCal $attenuation  | awk '{ret = (100.0 - $5)*0.01*($1*$2)*$4/$3; print ret;}'`

  	if ($b_flux != "unknown") then
	    if ($isEnergyUsed == 1) then 
		set flux = `echo $b_flux $attenuation $b_attenuation | awk '{print $1*(100 - $2)/(100 - $3) }'`

# To do: compare flux measured at the beamline with calculated flux.
#If they differ, go with calculated flux
#
#          	echo " FLUX and CALCULATED FLUX " $flux "  " $fluxAlt      
		#echo "Measured flux of $b_flux will be used at energy $enOrg"
	    else	
		set flux = `echo $flux_corr $fluxCal $attenuation $b_attenuation | awk '{print $1*$2*(100 - $3)/(100 - $4) }'`

#		echo " FLUX and CALCULATED FLUX " $flux "  " $fluxAlt

                #echo "Flux correction of $flux_corr will be applied to energy $enOrg"
            endif
        #If a measured value for the flux is not available, use the calculated value for all the energies
        else 
	    set flux = $fluxAlt
        endif     
        
	#	echo " FLUX " $flux
    	if ($flux == 0) then
    		set radDosePerImage = "unknown"
    		set radDoseErr = "$radDoseErr Flux is zero at $enOrg eV." 
    		continue	
    	# flux != 0
    	else
    		# Generate raddose input file

		set cshpath = `which csh`
		echo "#!"$cshpath" -f" > $sp/RADDOSE/run_raddose.csh
		echo "source $WEBICE_SCRIPT_DIR/setup_env.csh" >> $sp/RADDOSE/run_raddose.csh
		echo "raddose <<EOF-raddose"  >> $sp/RADDOSE/run_raddose.csh
    		echo "REMARK Absorbed dose for solution$solNum" >> $sp/RADDOSE/run_raddose.csh
    		echo "CELL $cell" >> $sp/RADDOSE/run_raddose.csh
    		echo "SOLVENT $solv" >> $sp/RADDOSE/run_raddose.csh
    		echo "NMON $nmon " >> $sp/RADDOSE/run_raddose.csh
    		if ("$numResidues" != "0") then
    			echo "NRES $numResidues" >> $sp/RADDOSE/run_raddose.csh
    		endif
    		if (("$element" == "") || ("$numHeavyAtoms" == "0") || ("$numHeavyAtoms" == "")) then
    			echo "PATM  " >> $sp/RADDOSE/run_raddose.csh
    		else
    			echo "PATM $element $numHeavyAtoms" >> $sp/RADDOSE/run_raddose.csh
    		endif
    		echo "CRYSTAL 0.1 0.1 0.1" >> $sp/RADDOSE/run_raddose.csh
    		echo "BEAM $beamSizeX $beamSizeY" >> $sp/RADDOSE/run_raddose.csh
    		echo "ENERGY $en" >> $sp/RADDOSE/run_raddose.csh
    		echo "PHOSEC $flux" >> $sp/RADDOSE/run_raddose.csh
    		echo "GAUSS $gauss" >> $sp/RADDOSE/run_raddose.csh
    		echo "IMAGES 1" >> $sp/RADDOSE/run_raddose.csh
    		echo "EXPOSURE $exposureTimePerImageUsed" >> $sp/RADDOSE/run_raddose.csh
    		echo "$doselimit $hendli" >> $sp/RADDOSE/run_raddose.csh
    		echo "END " >> $sp/RADDOSE/run_raddose.csh
    		echo "EOF-raddose"  >> $sp/RADDOSE/run_raddose.csh
		    
		chmod u+x $sp/RADDOSE/run_raddose.csh

    		# Run raddose to calculate radiation dose per image
    		set radDoseErr = ""
    		set tt = `which raddose | awk '{if (index($0, "/") == 1) { print "1";} else { print "0";} }'`
    		if ($tt) then
    			$sp/RADDOSE/run_raddose.csh > $sp/RADDOSE/raddose.out
			#raddose log has changed since 2008. Keep it backward compatible for the time being
    			if ($raddose_log == old) then 
			    set radDosePerImage = `awk '/Dose per image/{ printf("%g", $4); }' $sp/RADDOSE/raddose.out`
			else
			    set radDosePerImage = `awk '/dose per image/{ printf("%g", $6); }' $sp/RADDOSE/raddose.out`
			endif
    		else
    			set radDosePerImage = "unknown"
    			set radDoseErr = "Raddose software is not available on this system."
    			break
    		endif

		if ($expType == "MAD") then
		    mv $sp/RADDOSE/raddose.out $sp/RADDOSE/raddose${i}.out
		    mv $sp/RADDOSE/run_raddose.csh $sp/RADDOSE/run_raddose${i}.csh
		endif
    	
    	# if flux == 0
    	endif
	
    	if ("$radDoseErr" == "") then
	
      		# Adjustment factor for total dose is 0.2*0.2(*2 if SAD)*numEnergies/(beamX*beamY)
    		# Adjust for beamsize, x2 for SAD and x3 for MAD
#     		set factor = `echo "$b_beamSizeX $b_beamSizeY $inverseBeam" | awk '{ret = 0.2*0.2/($1*$2); if ($3 == 1) {ret=ret*2.0; } print ret;}'`
    		# Don't need to multiply by 2 for SAD since we have already done that for imageNumU and imageNumA
    		# Also no need to apply beam size factor since we have now done that to flux before running raddose.
    		# We also apply attenuation to the flux as well. So here we just set factor to one so that
    		# we dont' need to modify the calculation below.
      		set factor = 1
      		set radDoseTotalU = `echo "$radDosePerImage $imageNumU $factor" | awk '{ tot = $1*$2*$3; printf("%g", tot);}'`
      		set radDoseTotalA = `echo "$radDosePerImage $imageNumA $factor" | awk '{ tot = $1*$2*$3; printf("%g", tot);}'`
      		set maxImages = `echo "$hendli $radDosePerImage" | awk '{ret = $1/$2; printf("%d", ret); }'`
		
    		if ($enOrg == $energy1) then
    			set maxImagesEn1 = $maxImages
    			set radDoseEn1PerImg = $radDosePerImage
    			set radDoseEn1U = $radDoseTotalU
    			set radDoseEn1A = $radDoseTotalA
    		endif
    		if ($enOrg == $energy2) then
    			set maxImagesEn2 = $maxImages
    			set radDoseEn2PerImg = $radDosePerImage
    			set radDoseEn2U = $radDoseTotalU
    			set radDoseEn2A = $radDoseTotalA
    		endif
    		if ($enOrg == $energy3) then
    			set maxImagesEn3 = $maxImages
    			set radDoseEn3PerImg = $radDosePerImage
    			set radDoseEn3U = $radDoseTotalU
    			set radDoseEn3A = $radDoseTotalA
    		endif

    	# if radDoseErr
    	endif
    						
    # for each energy
    end
   
    set numEnergies = $countEn
    # Total absorbed dose for all energies
    set maxImages = $maxImages
    set radDosePerImage = `echo "$radDoseEn1PerImg $radDoseEn2PerImg $radDoseEn3PerImg $numEnergies" | awk '{ret = ($1 + $2 + $3)/$4; printf("%g", ret);}'`
    set radDoseTotalU = `echo "$radDoseEn1U $radDoseEn2U $radDoseEn3U" | awk '{ ret = $1 + $2 + $3; printf("%g", ret);}'`
    set radDoseTotalA = `echo "$radDoseEn1A $radDoseEn2A $radDoseEn3A" | awk '{ ret = $1 + $2 + $3; printf("%g", ret);}'`
        	
    set radDoseWarningU = "$radDoseErr"
    set radDoseWarningA = "$radDoseErr"
    
    set energy1Warning = "$en_warning"

    # Check if doses from all energies combined exceed hendli limit
    set test = `echo "$radDoseTotalU $hendli" | awk '{ if ($1+0 > $2+0) {print "1";} else {print "0"}}'`;
    if ($test) then
    	if ($expType == "MAD" && $numEnergies == 3 ) then
		#echo " expType = MAD and countEn == 3 "
    		set radDoseWarningU = "$radDoseErr Total absorbed dose exceeds $hendli Gy. Radiation damage likely. Only inflection and remote energies will be used."
    		set energy1Warning = "This energy will not be used because total absorbed dose for 3 energies exceeds $hendli Gy."
    		set numEnergies = 2
    	else
    		set radDoseWarningU = "$radDoseErr Absorbed dose exceeds $hendli Gy. Radiation damage likely."
    	endif
    else
    	if ($expType == "MAD") then
    		set energy1Warning = ""
    	endif
    endif
    
    set test = `echo "$radDoseTotalA $hendli" | awk '{ if ($1+0 > $2+0) {print "1";} else {print "0"}}'`;
    if ($test) then
    	if ($expType == "MAD" && $numEnergies == 3 ) then
    		set radDoseWarningA = "$radDoseErr Total absorbed dose exceeds $hendli Gy. Radiation damage likely. Only inflection and remote energies will be used."
    		set numEnergies = 2
    	else
    		set radDoseWarningA = "$radDoseErr Absorbed dose exceeds $hendli Gy. Radiation damage likely."
    	endif
    else
    	if ($expType == "MAD") then
    		set energy1Warning = ""
    	endif
    endif

 
#Wedge for data collection. No wedge by default 
    set wedge = "180.0"   

    #Minimum wedge dictated by beamline properties (depending on how long it takes to change energies, oscillation axis reproducibility)

    if ($expType == "Native") then
        set wedge = 180.0
    else 
    	if ("$radDoseErr" == "") then
        set b_wedge = `awk '/energy_wedge/{print $2;}' ../PARAMETERS/beamline.properties`
        set maxDosePerWedge = 25000  #Ideally each wedge should not receive more than 0.025 MGy
        set min_wedge = `echo $b_wedge $oscAngle | awk '{print 100.0 * $1 * $2;}'`
        set factor = $numEnergies
        if ($expType == "SAD") then
		set factor = 2
	endif
        set wedge = `echo $radDosePerImage $maxDosePerWedge $factor $min_wedge $oscAngle | awk '{ max_wedge = ($2 * $5)/($1 * $3); {if (max_wedge < $4) {print $4;} else {print max_wedge;}}}' ` 
        # Round up wedge to an increment of oscAngle
	# Do not go beyond 180.0 degrees.
        set wedge = `echo "$wedge $oscAngle" | awk '{ yy = int($1/$2); zz = $1 % $2; if (zz > 0) { yy = yy + 1; } wedge = yy*$2; if (wedge > 180.0) { wedge = 180.0; } printf("%.1f", wedge); }'`
	endif
    endif    

    			  	
    set nextFrame = "1"
    set runLabel = "0"
    # Use the same file root as the 2 test images
    set fileRoot = $runName
    # Use the same dir as the 2 test images
    set runDir = $imageDir
    set startFrame = "1"
    set axis = "gonio_phi"

    ###############
    # XML
    ###############
    echo '  <spaceGroup name="'$sp'">' >> strategy_summary.xml
    echo '    <phiStrategy>' >> strategy_summary.xml
    echo '      <uniqueData phiStart="'$dataU[1]'" phiEnd="'$dataU[2]'" complete="'$dataU[3]'" />' >> strategy_summary.xml
    echo '      <anomalousData phiStart="'$dataA[1]'" phiEnd="'$dataA[2]'" complete="'$dataA[3]'" />' >> strategy_summary.xml
    echo '      <maxDeltaPhi value="'$maxDeltaPhi'" />' >> strategy_summary.xml
    echo '    </phiStrategy>' >> strategy_summary.xml
    echo '    <dcStrategy>' >> strategy_summary.xml
    echo '      <expType value="Native" />' >> strategy_summary.xml
    echo '      <axis value="'$rotationAxis'" />' >> strategy_summary.xml
    echo '      <osc start="'$dataU[1]'" end="'$dataU[2]'" delta="'$oscAngle'"/>' >> strategy_summary.xml
    echo '      <kappa offset="'$kappaOffset'"/>' >> strategy_summary.xml
    echo '      <wedge value="'$wedge'" />' >> strategy_summary.xml
    echo '      <attenuation value="'$attenuation'" warning="'$attenuationWarning'"/>' >> strategy_summary.xml
    echo '      <resolution predicted="'$predictedRes'" detector="'$detectorRes'"/>' >> strategy_summary.xml
    echo '      <exposureTime value="'$exposureTime'" perImage="'$exposureTimePerImg'" \
                        warning="'$exposureTimeWarning'" perImageUsed="'$exposureTimePerImageUsed'"/>' >> strategy_summary.xml
    echo '      <detectorZCorr value="'$dzc_used'" warning="'$dzc_warning'" />' >> strategy_summary.xml
    echo '      <beamStopZ value="'$beamStopZ'" warning="'$beamStopZWarning'" />' >> strategy_summary.xml
    echo '      <energy value1="'$energy1'" value2="'$energy2'" value3="'$energy3'"/>' >> strategy_summary.xml
    echo '      <energyWarning value1="'$energy1Warning'" value2="'$energy2Warning'" value3="'$energy3Warning'"/>' >> strategy_summary.xml
    echo '      <detector type="'$detectorType'" mode="'$detectorMode'" number="'$detectorModeInt'"/>' >> strategy_summary.xml
    echo '      <inverseBeam value="'$inverseBeam'"/>' >> strategy_summary.xml
    echo '      <imageCount value="'$imageNumU'" complete="'$dataU[3]'" warning="'$imageNumUWarning'"/>' >> strategy_summary.xml
    echo '      <beamSize x="'$beamSizeX'" y="'$beamSizeY'"/>' >> strategy_summary.xml
    echo '      <best width="'$best_width'" exposureTime="'$best_exposureTime'" \
                       exposureTimePerImg="'$best_exposureTimePerImg'" exposureTimeWarning="'$best_exposureTimeWarning'"/>' >> strategy_summary.xml
    echo '      <radDose perImage="'$radDosePerImage'" total="'$radDoseTotalU'"  \
                       limit="'$hendli'"  maxImages="'$maxImages'" warning="'$radDoseWarningU'" \
                      en1="'$radDoseEn1U'" en1PerImg="'$radDoseEn1PerImg'" \
                      en2="'$radDoseEn2U'" en2PerImg="'$radDoseEn2PerImg'" \
                      en3="'$radDoseEn3U'" en3PerImg="'$radDoseEn3PerImg'" />' >> strategy_summary.xml
    echo '       <rundef status="'inactive'" nextFrame="'$nextFrame'" label="'$runLabel'" fileRoot="'$fileRoot'" imageDir="'$runDir'"\
                         startFrame="'$startFrame'" axis="'$axis'" oscStart="'$dataU[1]'" oscEnd="'$dataU[2]'" oscAngle="'$oscAngle'"\
    		     wedge="'$wedge'" exposureTime="'$exposureTimePerImageUsed'" distance="'$dzc_used'" beamStop="'$beamStopZ'"\
    		     numEn="'$numEnergies'" en1="'$energy1'" en2="'$energy2'" en3="'$energy3'" en4="'$energy4'" en5="'$energy5'"\
    		     detectorMode="'$detectorModeInt'" inverse="'$inverseBeam'" />' >> strategy_summary.xml
    echo '    </dcStrategy>' >> strategy_summary.xml
    echo '    <dcStrategy>' >> strategy_summary.xml
    echo '      <expType value="Anomalous" />' >> strategy_summary.xml
    echo '      <axis value="'$rotationAxis'" />' >> strategy_summary.xml
    echo '      <osc start="'$dataA[1]'" end="'$dataA[2]'" delta="'$oscAngle'"/>' >> strategy_summary.xml
    echo '      <kappa offset="'$kappaOffset'"/>' >> strategy_summary.xml
    echo '      <wedge value="'$wedge'" />' >> strategy_summary.xml
    echo '      <attenuation value="'$attenuation'" />' >> strategy_summary.xml
    echo '      <resolution predicted="'$predictedRes'" detector="'$detectorRes'"/>' >> strategy_summary.xml
    echo '      <exposureTime value="'$exposureTime'" perImage="'$exposureTimePerImg'" \
                        warning="'$exposureTimeWarning'" perImageUsed="'$exposureTimePerImageUsed'"/>' >> strategy_summary.xml
    echo '      <detectorZCorr value="'$dzc_used'" warning="'$dzc_warning'" />' >> strategy_summary.xml
    echo '      <beamStopZ value="'$beamStopZ'" warning="'$beamStopZWarning'" />' >> strategy_summary.xml
    echo '      <energy value1="'$energy1'" value2="'$energy2'" value3="'$energy3'"/>' >> strategy_summary.xml
    echo '      <energyWarning value1="'$energy1Warning'" value2="'$energy2Warning'" value3="'$energy3Warning'"/>' >> strategy_summary.xml
    echo '      <detector type="'$detectorType'" mode="'$detectorMode'" number="'$detectorModeInt'"/>' >> strategy_summary.xml
    echo '      <inverseBeam value="'$inverseBeam'"/>' >> strategy_summary.xml
    echo '      <imageCount value="'$imageNumA'" complete="'$dataA[3]'" warning="'$imageNumAWarning'"/>' >> strategy_summary.xml
    echo '      <beamSize x="'$beamSizeX'" y="'$beamSizeY'"/>' >> strategy_summary.xml
    echo '      <best width="'$best_width'" exposureTime="'$best_exposureTime'" \
                         exposureTimePerImg="'$best_exposureTimePerImg'" exposureTimeWarning="'$best_exposureTimeWarning'"/>' >> strategy_summary.xml
    echo '      <radDose perImage="'$radDosePerImage'" total="'$radDoseTotalA'" \
                         limit="'$hendli'"  maxImages="'$maxImages'" warning="'$radDoseWarningA'" \
                      	en1="'$radDoseEn1A'" en1PerImg="'$radDoseEn1PerImg'" \
                      	en2="'$radDoseEn2A'" en2PerImg="'$radDoseEn2PerImg'" \
                      	en3="'$radDoseEn3A'" en3PerImg="'$radDoseEn3PerImg'" />' >> strategy_summary.xml
    echo '       <rundef status="'inactive'" nextFrame="'$nextFrame'" label="'$runLabel'" fileRoot="'$fileRoot'" imageDir="'$runDir'"\
                         startFrame="'$startFrame'" axis="'$axis'" oscStart="'$dataA[1]'" oscEnd="'$dataA[2]'" oscAngle="'$oscAngle'"\
    		     wedge="'$wedge'" exposureTime="'$exposureTimePerImageUsed'" distance="'$dzc_used'" beamStop="'$beamStopZ'"\
    		     numEn="'$numEnergies'" en1="'$energy1'" en2="'$energy2'" en3="'$energy3'" en4="'$energy4'" en5="'$energy5'"\
    		     detectorMode="'$detectorModeInt'" inverse="'$inverseBeam'" />' >> strategy_summary.xml
    echo '    </dcStrategy>' >> strategy_summary.xml
    echo '  </spaceGroup>' >> strategy_summary.xml



    ###############
    # TCL
    ###############
    echo '  { spaceGroup '$sp >> strategy_summary.tcl
#   echo '    { phiStrategy' >> strategy_summary.tcl
#   echo '      { uniqueData '$dataU[1]' '$dataU[2]' '$dataU[3]' }' >> strategy_summary.tcl
#   echo '      { anomalousData '$dataA[1]' '$dataA[2]' '$dataA[3]' }' >> strategy_summary.tcl
#   echo '      { maxDeltaPhi '$maxDeltaPhi' }' >> strategy_summary.tcl
#   echo '    }' >> strategy_summary.tcl
    echo '    { dcStrategy' >> strategy_summary.tcl
    echo '      { expType {Native} }' >> strategy_summary.tcl
    echo "      { runDef inactive $nextFrame $runLabel $fileRoot $runDir $startFrame $axis $dataU[1] $dataU[2] $oscAngle 180.0 $exposureTimePerImageUsed $dzc_used $beamStopZ $attenuation $numEnergies $energy1 0.0 0.0 0.0 0.0 $detectorModeInt $inverseBeam }" >> strategy_summary.tcl
    echo '      { warning {'$autoindexWarning'} {'$dzc_warning'} {'$beamStopZWarning'} {'$en_warning'} {'$imageNumUWarning'} {'$exposureTimeWarning'} {'$best_exposureTimeWarning'} {'$radDoseWarningU'} {'$attenuationWarning'} }' >> strategy_summary.tcl
    echo '      { axis '$rotationAxis' }' >> strategy_summary.tcl
    echo '      { osc '$dataU[1]' '$dataU[2]' '$oscAngle' }' >> strategy_summary.tcl
    echo '      { kappa '$kappaOffset' }' >> strategy_summary.tcl
    echo '      { wedge '$wedge' }' >> strategy_summary.tcl
    echo '      { attenuation '$attenuation' }' >> strategy_summary.tcl
    echo '      { resolution '$predictedRes' '$detectorRes' }' >> strategy_summary.tcl
    echo '      { exposureTime '$exposureTime' '$exposureTimePerImg' {'$exposureTimeWarning'} '$exposureTimePerImageUsed' }' >> strategy_summary.tcl
    echo '      { detectorZCorr '$dzc_used' {'$dzc_warning'} }' >> strategy_summary.tcl
    echo '      { beamStopZ '$beamStopZ' {'$beamStopZWarning'} }' >> strategy_summary.tcl
    echo '      { energy {'$energy1'} {0.0} {0.0} }' >> strategy_summary.tcl
    echo '      { energyWarning {'$en_warning'} {} {} }' >> strategy_summary.tcl
    echo '      { detector {'$detectorType'} {'$detectorMode'} {'$detectorModeInt'} }' >> strategy_summary.tcl
    echo '      { inverseBeam '$inverseBeam' }' >> strategy_summary.tcl
    echo '      { imageCount '$imageNumU' '$dataU[3]' {'$imageNumUWarning'} }' >> strategy_summary.tcl
    echo '      { beamSize {'$beamSizeX'} {'$beamSizeY'} }' >> strategy_summary.tcl
    echo '      { best '$best_width' '$best_exposureTime' '$best_exposureTimePerImg' {'$best_exposureTimeWarning'} }' >> strategy_summary.tcl
    echo '      { radDose '$radDosePerImage' '$radDoseTotalU' '$hendli' '$maxImages' {'$radDoseWarningU'} {'$radDoseEn1U' '$radDoseEn1PerImg'} {'$radDoseEn2U' '$radDoseEn2PerImg'} {'$radDoseEn3U' '$radDoseEn3PerImg'} }' >> strategy_summary.tcl
    echo "    }" >> strategy_summary.tcl
    echo '    { dcStrategy' >> strategy_summary.tcl
    echo '      { expType {Anomalous} }' >> strategy_summary.tcl
    echo "      { runDef inactive $nextFrame $runLabel $fileRoot $runDir $startFrame $axis $dataA[1] $dataA[2] $oscAngle $wedge $exposureTimePerImageUsed $dzc_used $beamStopZ $attenuation $numEnergies $energy1 $energy2 $energy3 0.0 0.0 $detectorModeInt $inverseBeam }" >> strategy_summary.tcl
    echo '      { warning {'$dzc_warning'} {'$beamStopZWarning'}{'$en_warning'} {'$imageNumUWarning'} {'$exposureTimeWarning'} {'$best_exposureTimeWarning'} {'$radDoseWarningA'} {'$attenuationWarning'} }' >> strategy_summary.tcl
    echo '      { axis '$rotationAxis' }' >> strategy_summary.tcl
    echo '      { osc '$dataA[1]' '$dataA[2]' '$oscAngle' }' >> strategy_summary.tcl
    echo '      { kappa '$kappaOffset' }' >> strategy_summary.tcl
    echo '      { wedge '$wedge' }' >> strategy_summary.tcl
    echo '      { attenuation '$attenuation' }' >> strategy_summary.tcl
    echo '      { resolution '$predictedRes' '$detectorRes' }' >> strategy_summary.tcl
    echo '      { exposureTime '$exposureTime' '$exposureTimePerImg' {'$exposureTimeWarning'} '$exposureTimePerImageUsed' }' >> strategy_summary.tcl
    echo '      { detectorZCorr '$dzc_used' {'$dzc_warning'} }' >> strategy_summary.tcl
    echo '      { beamStopZ '$beamStopZ' {'$beamStopZWarning'} }' >> strategy_summary.tcl
    echo '      { energy {'$energy1'} {'$energy2'} {'$energy3'} }' >> strategy_summary.tcl
    echo '      { energyWarning {'$en_warning'} {} {} }' >> strategy_summary.tcl
    echo '      { detector {'$detectorType'} {'$detectorMode'} {'$detectorModeInt'} }' >> strategy_summary.tcl
    echo '      { inverseBeam '$inverseBeam' }' >> strategy_summary.tcl
    echo '      { imageCount '$imageNumA' '$dataA[3]' {'$imageNumAWarning'} }' >> strategy_summary.tcl
    echo '      { beamSize {'$beamSizeX'} {'$beamSizeY'} }' >> strategy_summary.tcl
    echo '      { best '$best_width' '$best_exposureTime' '$best_exposureTimePerImg' {'$best_exposureTimeWarning'} }' >> strategy_summary.tcl
    echo '      { radDose '$radDosePerImage' '$radDoseTotalA' '$hendli' '$maxImages' {'$radDoseWarningA'} {'$radDoseEn1A' '$radDoseEn1PerImg'} {'$radDoseEn2A' '$radDoseEn2PerImg'} {'$radDoseEn3A' '$radDoseEn3PerImg'} }' >> strategy_summary.tcl
    echo "    }" >> strategy_summary.tcl
    echo "  }" >> strategy_summary.tcl

end

echo "</strategySummary>" >> strategy_summary.xml
echo "}" >> strategy_summary.tcl

# Copy this strategy to top work dir
# as default strategy result, which
# will then be copied by crystal-analysis
# server to a dir available for import by dcss.
if (! -e ../strategy_summary.tcl) then
cp strategy_summary.tcl ../
endif

#echo `date +"%T"` " Finished generating strategy"
