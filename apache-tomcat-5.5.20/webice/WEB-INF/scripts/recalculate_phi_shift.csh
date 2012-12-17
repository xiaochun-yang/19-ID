#!/bin/csh -f

############################################################
#
# Calculate phi shift in REMOUNT directories
#
############################################################


if ($#argv != 3) then
echo " "
echo "Usage: "'$'"SCRIPT_DIR/recalculate_phi_shift.csh <webice screening result dir> <offset tolerance in degrees> <ignore search axis change: yes/no>"
echo "Example:"
echo '$'"SCRIPT_DIR/recalculate_phi_shift.csh /data/penjitk/webice/screening/8641 3 no"
echo " "
exit
endif

set cassetteDir = $argv[1]
set offsetTolerance = $argv[2]
set ignoreSearchAxisChange = $argv[3]

# Default is no
if ($ignoreSearchAxisChange != "yes") then
set ignoreSearchAxisChange = "no"
endif

cd $cassetteDir

set crystals = (`ls`)
# Loop over each crystal result dir
foreach crystalID ($crystals)

echo `date +"%T"` " Started calculating phi shift for crystalID $crystalID"

set remountDir = $cassetteDir/$crystalID/autoindex/REMOUNT
if (! -d $remountDir) then
	echo `date +"%T"` " Cannot find remount dir: $remountDir"
	continue;
endif

cd $remountDir

# Loop over all solutions
set solutions = (`ls`)
foreach solution ($solutions)

set solutionDir = $remountDir/$solution
# Check if the directory name starts with 'solution' and it is a directory.
set isSolutionDir = `echo $solution | awk '{if (index($0, "solution") > 0) {print "1";} else { print "0";}}'`
if (! $isSolutionDir) then
	continue
endif
if (! -d $solutionDir) then
	echo `date +"%T"` " Cannot find solution dir: $solutionDir"
	continue
endif

echo `date +"%T"` " Started calculating phi shift for solution $solution"
cd $solutionDir

# Loop over spacegroups
set spacegroups = (`ls`)
foreach spacegroup ($spacegroups)

set spacegroupDir = $solutionDir/$spacegroup
# Make sure it is a directory
if (! -d $spacegroupDir) then
	echo `date +"%T"` " Cannot find spacegroup dir: $spacegroupDir"
	continue
endif

echo `date +"%T"` " Started calculating phi shift for spacegroup $spacegroup"
cd $spacegroupDir

# Calculate phi shift
set err = ""
set uniqueAxis_org = `awk 'BEGIN{done=0;}/Unique axis is:/{print $4;done=1;} END{if (done!=1) {print "unknown";}}' strategy_org.out`
set uniqueAxis = `awk 'BEGIN{done=0;}/Unique axis is:/{print $4;done=1;} END{if (done!=1) {print "unknown";}}' strategy.out`
if ($uniqueAxis_org != $uniqueAxis) then
echo `date +"%T"` " ERROR cannot calculate phi shift because unique axis changed from $uniqueAxis_org to $uniqueAxis."
set err = "Unique axis changed from $uniqueAxis_org to $uniqueAxis."
endif

set rotationAxis = `awk 'BEGIN{done=0;}/axis is closest to the rotation axis/{print substr($11, 1, length($11)-1);done=1;} END{if (done!=1) {print "unknown";}}' strategy.out`

set line_org = (`awk '/Start strategy search with/{print $0;}' strategy_org.out`)
set line = (`awk '/Start strategy search with/{print $0;}' strategy.out`)

# Check that strategy search axis is the same
if ("$err" == "") then
set searchAxis_org = `echo "$line_org" | awk '{print $5;}'`
set searchAxis = `echo "$line" | awk '{print $5;}'`
if ($searchAxis_org != $searchAxis)then
if ($ignoreSearchAxisChange == "no") then
echo `date +"%T"` " ERROR cannot calculate phi shift because search axis changed from $searchAxis_org to $searchAxis."
set err = "Search axis changed from $searchAxis_org to $searchAxis."
else
echo `date +"%T"` " WARNING Search axis changed from $searchAxis_org to $searchAxis."
endif
endif

# Check if offset has changed
set offset_org = 0
set offset = 0
if ("$err" == "") then
set offset_org = `echo "$line_org" | awk '{print $9;}'`
set offset = `echo "$line" | awk '{print $9;}'`
set offsetDiff = `echo $offset $offset_org| awk '{diff = $1 - $2; if (diff < 0.0) {diff = -1.0*diff;} print diff;}'`
if ($offset != $offset_org) then
set bigChange = `echo $offsetDiff $offsetTolerance | awk '{if ($1 > $2) { print 1; } else { print 0; } }'`
if ($bigChange) then
echo `date +"%T"` " ERROR cannot calculate phi shift because changed by $offsetDiff degrees from $offset_org to $offset degrees, bigger than tolerance of $offsetTolerance degrees."
set err = "Offset changed from $offset_org to $offset degrees."
else
echo `date +"%T"` " WARNING Offset changed by $offsetDiff degrees from $offset_org to $offset degrees, within tolerance of $offsetTolerance degrees."
endif
endif

endif

# Check if axis plane has changed
if ("$err" == "") then
set plane_org = `echo "$line_org" | awk '{print $12;}'`
set plane = `echo "$line" | awk '{print $12;}'`
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

set phi_org = `echo "$line_org" | awk '{printf("%7.1f", $16);}'`
set phi = `echo "$line" | awk '{printf("%7.1f", $16);}'`
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
echo "PhiShift" $diff | awk '{printf("%s %.1f\n", $1, $2);}' >> phi_strategy.tcl
echo "RotationAxis" $rotationAxis | awk '{printf("%s %.1f\n", $1, $2);}' >> phi_strategy.tcl
endif


echo `date +"%T"` " Finished calculating phi shift"
echo " "
end # foreach spacegroup

end # foreach solution

end # foreach crystalID


