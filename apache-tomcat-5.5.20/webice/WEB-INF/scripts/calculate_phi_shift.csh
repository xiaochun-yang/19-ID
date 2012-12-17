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

echo `date +"%T"` " Started calculating phi shift"

set solutionNum = $argv[1]
set spacegroup = $argv[2]

set parentDir = `pwd`


# Create selected solution dir
mkdir -p solution${solutionNum}
# Create selected spacegroup
mkdir -p solution${solutionNum}/$spacegroup
cd solution${solutionNum}/$spacegroup


# workDir is current dir
set workDir = `pwd`

set img1Phi = `awk '/phi/{print $2;}' ../../../PARAMETERS/image1.txt`
set img2Phi = `awk '/phi/{print $2;}' ../../../PARAMETERS/image2.txt`
set img3Phi = `awk '/phi/{print $2;}' ../../PARAMETERS/image1.txt`
set img4Phi = `awk '/phi/{print $2;}' ../../PARAMETERS/image2.txt`

# Copy strategy script from first run
cp ../../../solution${solutionNum}/$spacegroup/strategy.mfm strategy_org.mfm
# Copy strategy result from first run
cp ../../../solution${solutionNum}/$spacegroup/strategy.out strategy_org.out
# Copy orientation matric from first run
cp ../../../solution${solutionNum}/$spacegroup/index${solutionNum}.mat index${solutionNum}_org.mat

# Copy new orientation matrix from this run
cp ../../LABELIT/index${solutionNum}.mat .

set reindexingAbc = ""`cat ../../LABELIT/labelit.out | awk '/Based on stored crystal orientation/{print $9;}'`
set reindexingDeltaPhi = ""`cat ../../LABELIT/labelit.out | awk '/reindexing delta phi/{print $5;}'`


# Get image dir and name from REMOUNT/input.xml
set imageDir = `awk '/<imageDir>/{i = index($1, "/"); j = index($1, "</imageDir>"); print substr($1, i, j-i);}' ../../input.xml`
set imageName = `awk 'BEGIN{done=0;} /<image>/{if (done == 0) {done=1;i = index($1, ">"); j = index($1, "</image>"); print substr($1, i+1, j-i-1);}}' ../../input.xml`

# Modify original strategy script with new image paths
awk -v dir="$imageDir" -v image="$imageName" -v matrix="index${solutionNum}_org.mat" -f $WEBICE_SCRIPT_DIR/create_phi_strategy_script.awk strategy_org.mfm > strategy.mfm
	
# Make it executable
chmod u+x strategy.mfm

# Run it to generate strate.out
./strategy.mfm

# Generate strategy.xml
$WEBICE_SCRIPT_DIR/generate_strategy_xml.csh > strategy.xml


# Calculate phi shift
set err = ""
set uniqueAxis_org = `awk 'BEGIN{done=0;}/Unique axis is:/{print $4;done=1;} END{if (done!=1) {print "unknown";}}' strategy_org.out`
set sanityCheck = `awk 'BEGIN{done=0;}/Total number of reflections/{done=1;} END{if (done==1) {print "OK";} else {print "ERROR";}}' strategy_org.out`
if ("$sanityCheck" == "ERROR") then
set err = "Strategy_org failed"
endif

if ("$err" == "") then
set uniqueAxis = `awk 'BEGIN{done=0;}/Unique axis is:/{print $4;done=1;} END{if (done!=1) {print "unknown";}}' strategy.out`
set sanityCheck = `awk 'BEGIN{done=0;}/Total number of reflections/{done=1;} END{if (done==1) {print "OK";} else {print "ERROR";}}' strategy.out`
if ("$sanityCheck" == "ERROR") then
set err = "Strategy failed"
endif
endif

if ("$err" == "") then

if ($uniqueAxis_org != $uniqueAxis) then
echo `date +"%T"` " ERROR cannot calculate phi shift because unique axis changed from $uniqueAxis_org to $uniqueAxis."
set err = "Unique axis changed from $uniqueAxis_org to $uniqueAxis."
endif

set rotationAxis = `awk 'BEGIN{done=0;}/axis is closest to the rotation axis/{print substr($11, 1, length($11)-1);done=1;} END{if (done!=1) {print "unknown";}}' strategy.out`
set rotationAxis1 = `awk '/axis is closest to the rotation axis/{print "AUTOINDEX " $0;}' strategy_org.out`
set rotationAxis2 = `awk '/axis is closest to the rotation axis/{print "REAUTOINDEX " $0;}' strategy.out`
set uniqueAxis1 = `awk '/Unique axis is:/{print "AUTOINDEX " $0;}' strategy_org.out`
set uniqueAxis2 = `awk '/Unique axis is:/{print "REAUTOINDEX " $0;}' strategy.out`

set line_org = (`awk '/Start strategy search with/{print $0;}' strategy_org.out`)
set line = (`awk '/Start strategy search with/{print $0;}' strategy.out`)

# Check that strategy search axis is the same
if ("$err" == "") then
set searchAxis_org = `echo "$line_org" | awk '{print $5;}'`
set searchAxis = `echo "$line" | awk '{print $5;}'`
if ($searchAxis_org != $searchAxis) then
echo `date +"%T"` " ERROR cannot calculate phi shift because search axis changed from $searchAxis_org to $searchAxis."
set err = "Search axis changed from $searchAxis_org to $searchAxis."
endif
endif

# Check if offset has changed
set offsetTolerance = 2
set offset_org = 0
set offset = 0
if ("$err" == "") then

set offset_org = `echo "$line_org" | awk '{if (index($0, "offset by") > 1) {print $9;} else {print 0.0;}}'`
set offset = `echo "$line" | awk '{if (index($0, "offset by") > 1) {print $9;} else {print 0.0;}}'`
set offsetDiff = `echo $offset $offset_org | awk '{diff = $1 - $2; if (diff < 0.0) {diff = -1.0*diff;} print diff;}'`
if ($offset != $offset_org) then
set bigChange = `echo $offsetDiff $offsetTolerance | awk '{if ($1 > $2) { print 1; } else { print 0; } }'`
if ($bigChange) then
echo `date +"%T"` " ERROR cannot calculate phi shift because offset changed by $offsetDiff degrees from $offset_org to $offset degrees, bigger than tolerance of $offsetTolerance degrees."
set err = "Offset changed from $offset_org to $offset degrees."
else
echo `date +"%T"` " WARNING Offset changed by $offsetDiff degrees from $offset_org to $offset degrees, within tolerance of $offsetTolerance degrees."
endif
endif

endif # if err == ""

# Check if axis plane has changed
if ("$err" == "") then
set plane_org = `echo "$line_org" | awk '{print $(NF-4);}'`
set plane = `echo "$line" | awk '{print $(NF-4);}'`
if ($plane_org != $plane) then
echo `date +"%T"` " ERROR cannot calculate phi shift because axis plane changed from $plane_org to $plane."
set err = "Axis plane changed from $plane_org to $plane."
endif
endif

# Get phi shift
set diff = 0
set osc_start_org = 0
set osc_end_org = 0
set osc_start = 0
set osc_end = 0
set osc_start_1 = 0
set osc_end_1 = 0
set osc_start_2 = 0
set osc_end_2 = 0

if ("$err" == "") then

set osc = (`awk '/^ Optimum rotation gives/{line=NR+2;} /^ From/{if (line == NR) {print $2 " " $4;}}' strategy_org.out`)
set osc_start_org = $osc[1]
set osc_end_org = $osc[2]

set osc = (`awk '/^ Optimum rotation gives/{line=NR+2;} /^ From/{if (line == NR) {print $2 " " $4;}}' strategy.out`)
set osc_start = $osc[1]
set osc_end = $osc[2]

set phi_org = `echo "$line_org" | awk '{printf("%7.1f", $NF);}'`
set phi = `echo "$line" | awk '{printf("%7.1f", $NF);}'`
set diffWithSign = `echo $phi_org $phi | awk '{printf("%7.1f", $2 - $1);}'`
set diff = `echo $phi_org $phi | awk '{diff = $2 - $1; if (diff > 0) {printf("%7.1f", diff);} else {printf("%7.1f", -1*diff);}}'`

set isSmaller = `echo $phi_org $phi | awk '{if ($2 < $1) {print 1;} else {print 0;}}'`
if ($isSmaller) then
set osc_start_0 = `echo $osc_start_org $diff | awk '{printf("%7.1f", $1 - $2);}'`
set osc_end_0 = `echo $osc_end_org $diff | awk '{printf("%7.1f", $1 - $2);}'`
else
set osc_start_0 = `echo $osc_start_org $diff | awk '{printf("%7.1f", $1 + $2);}'`
set osc_end_0 = `echo $osc_end_org $diff | awk '{printf("%7.1f", $1 + $2);}'`
endif

set osc_start_1 = `echo $osc_start_0 | awk '{printf("%7.1f", $1 + 360);}'`
set osc_end_1 = `echo $osc_end_0 | awk '{printf("%7.1f", $1 + 360);}'`
set osc_start_2 = `echo $osc_start_0 | awk '{printf("%7.1f", $1 - 360);}'`
set osc_end_2 = `echo $osc_end_0 | awk '{printf("%7.1f", $1 - 360);}'`

endif

endif # if error == ""

# Delete existing result file
if (-e phi_strategy.xml) then
rm -rf phi_strategy.xml
endif

# Write result in xml
echo "<phiStrategy>" > phi_strategy.xml
if ("$err" != "") then
echo "  <error>$err</error>"  >> phi_strategy.xml
else
echo "  <Original>" > phi_strategy.xml
echo "    <OscStart>$osc_start_org</OscStart>" >> phi_strategy.xml
echo "    <OscEnd>$osc_end_org</OscEnd>" >> phi_strategy.xml
echo "    <AxisOffset>$offset_org</AxisOffset>" >> phi_strategy.xml
echo "    <OffsetPhi>$phi_org</OffsetPhi>" >> phi_strategy.xml
echo "    <UniqueAxis>$uniqueAxis_org</UniqueAxis>" >> phi_strategy.xml
echo "    <SearchAxis>$searchAxis_org</SearchAxis>" >> phi_strategy.xml
echo "    <Plane>$plane_org</Plane>" >> phi_strategy.xml
echo "  </Original>" >> phi_strategy.xml
echo "  <Remounted>" >> phi_strategy.xml
echo "    <OscStart>$osc_start</OscStart>" >> phi_strategy.xml
echo "    <OscEnd>$osc_end</OscEnd>" >> phi_strategy.xml
echo "    <AxisOffset>$offset</AxisOffset>" >> phi_strategy.xml
echo "    <OffsetPhi>$phi</OffsetPhi>" >> phi_strategy.xml
echo "    <UniqueAxis>$uniqueAxis</UniqueAxis>" >> phi_strategy.xml
echo "    <SearchAxis>$searchAxis</SearchAxis>" >> phi_strategy.xml
echo "    <Plane>$plane</Plane>" >> phi_strategy.xml
echo "  </Remounted>" >> phi_strategy.xml
echo "  <Predicted>" >> phi_strategy.xml
echo "    <ReindexingAbc>$reindexingAbc</ReindexingAbc>" >> phi_strategy.xml
echo "    <ReindexingDeltaPhi>$reindexingDeltaPhi</ReindexingDeltaPhi>" >> phi_strategy.xml
echo "    <PhiShift>$diff</PhiShift>" >> phi_strategy.xml
echo "    <PhiShift>$diff</PhiShift>" >> phi_strategy.xml
echo "    <OscStart>$osc_start_0</OscStart>" >> phi_strategy.xml
echo "    <OscEnd>$osc_end_0</OscEnd>" >> phi_strategy.xml
echo "    <OscStartPlus360>$osc_start_1</OscStartPlus360>" >> phi_strategy.xml
echo "    <OscEndPlus360>$osc_end_1</OscEndPlus360>" >> phi_strategy.xml
echo "    <OscStartMinus360>$osc_start_2</OscStartMinus360>" >> phi_strategy.xml
echo "    <OscEndMinus360>$osc_end_2</OscEndMinus360>" >> phi_strategy.xml
echo "    <RotationAxis>$rotationAxis</RotationAxis>" >> phi_strategy.xml
echo "  </Predicted>" >> phi_strategy.xml
endif
echo "</phiStrategy>" >> phi_strategy.xml

# Delete existing result file
if (-e phi_strategy.txt) then
rm -rf phi_strategy.txt
endif

# Write result in table format
if ("$err" != "") then
echo "ERROR $err" > phi_strategy.txt
else
echo "junk" | awk '{printf("%15s%15s%15s%15s\n", "", "Original", "Remounted", "Predicted");}' > phi_strategy.txt
echo "OscStart" $osc_start_org $osc_start $osc_start_0 | awk '{printf("%15s%15.1f%15.1f%15.1f\n", $1, $2, $3, $4);}' >> phi_strategy.txt
echo "OscEnd" $osc_end_org $osc_end $osc_end_0 | awk '{printf("%15s%15.1f%15.1f%15.1f\n", $1, $2, $3, $4);}' >> phi_strategy.txt
echo "AxisOffset" $offset_org $offset | awk '{printf("%15s%15.1f%15.1f%15s\n", $1, $2, $3, "N/A");}' >> phi_strategy.txt
echo "OffsetPhi" $phi_org $phi | awk '{printf("%15s%15.1f%15.1f%15s\n", $1, $2, $3, "N/A");}' >> phi_strategy.txt
echo "UniqueAxis" $uniqueAxis_org $uniqueAxis | awk '{printf("%15s%15s%15s%15s\n", $1, $2, $3, "N/A");}' >> phi_strategy.txt
echo "SearchAxis" $searchAxis_org $searchAxis | awk '{printf("%15s%15s%15s%15s\n", $1, $2, $3, "N/A");}' >> phi_strategy.txt
echo "Plane" $plane_org $plane | awk '{printf("%15s%15s%15s%15s\n", $1, $2, $3, "N/A");}' >> phi_strategy.txt
echo "PhiShift" $diff | awk '{printf("%15s%15s%15s%15.1f\n", $1, "N/A", "N/A", $2);}' >> phi_strategy.txt
echo "OscStart+360" $osc_start_1 | awk '{printf("%15s%15s%15s%15.1f\n", $1, "N/A", "N/A", $2);}' >> phi_strategy.txt
echo "OscStart-360" $osc_start_2 | awk '{printf("%15s%15s%15s%15.1f\n", $1, "N/A", "N/A", $2);}' >> phi_strategy.txt
echo "OscEnd+360" $osc_end_1 | awk '{printf("%15s%15s%15s%15.1f\n", $1, "N/A", "N/A", $2);}' >> phi_strategy.txt
echo "OscEnd-360" $osc_end_2 | awk '{printf("%15s%15s%15s%15.1f\n", $1, "N/A", "N/A", $2);}' >> phi_strategy.txt
echo "RotationAxis" $rotationAxis | awk '{printf("%s %.1f\n", $1, $2);}' >> phi_strategy.txt
echo $rotationAxis1 >> phi_strategy.txt
echo $rotationAxis2 >> phi_strategy.txt
echo $uniqueAxis1 >> phi_strategy.txt
echo $uniqueAxis2 >> phi_strategy.txt
echo "Reindexing a b c = $reindexingAbc" >> phi_strategy.txt
echo "Reindexing delta phi = $reindexingDeltaPhi" >> phi_strategy.txt
cat ../../LABELIT/labelit.out | awk '/Based on stored/{found = 1;} {if ((found == 1) && (NR > 2) && (NR < 7)) {print $0;}}' >> phi_strategy.txt
endif

# Delete existing result file
if (-e phi_strategy.tcl) then
rm -rf phi_strategy.tcl
endif

# Write result as tcl
if ("$err" != "") then
echo "ERROR $err" > phi_strategy.tcl
else
echo "solution${solutionNum} $spacegroup"
echo "Image1Phi" $img1Phi | awk '{printf("%s %.1f\n", $1, $2);}' > phi_strategy.tcl
echo "Image2Phi" $img2Phi | awk '{printf("%s %.1f\n", $1, $2);}' >> phi_strategy.tcl
echo "Image3Phi" $img3Phi | awk '{printf("%s %.1f\n", $1, $2);}' >> phi_strategy.tcl
echo "Image4Phi" $img4Phi | awk '{printf("%s %.1f\n", $1, $2);}' >> phi_strategy.tcl
echo "PhiShift" $diffWithSign | awk '{printf("%s %.1f\n", $1, $2);}' >> phi_strategy.tcl
echo "RotationAxis" $rotationAxis | awk '{printf("%s %.1f\n", $1, $2);}' >> phi_strategy.tcl
echo $rotationAxis1 >> phi_strategy.tcl
echo $rotationAxis2 >> phi_strategy.tcl
echo $uniqueAxis1 >> phi_strategy.tcl
echo $uniqueAxis2 >> phi_strategy.tcl
cat ../../LABELIT/labelit.out | awk '/Based on stored/{found = 1;} {if ((found == 1) && (NR > 2) && (NR < 7)) {print $0;}}' >> phi_strategy.tcl
endif


echo `date +"%T"` " Finished calculating phi shift"

cd $parentDir

