#!/bin/csh -f

setenv WEBICE_SCRIPT_DIR `dirname $0`

if ($#argv != 1) then
echo "Usage generate_mathews_report_helper1.csh <autoindex dir>"
exit
endif

set workDir = $1
cd $workDir

set bestPhiStrategyFile = best_phi_strategy.tcl
set labelitDir = "LABELIT"
set labelitOutFile = ${labelitDir}/labelit.out

# get best solution predicted by labelit. If there are more than on then get the one with the highest symmetry.
set solutions = `cat $labelitOutFile | awk -f $WEBICE_SCRIPT_DIR/get_integrated_solutions.awk`
set solution = $solutions

# No indexing solution??
if ($solutions == "") then

set error = `cat $labelitOutFile | awk 'BEGIN {lastLine = "";} {lastLine = $0;} END{print lastLine;}'`
echo "$error"

else # No indexing solution?? 

if ($#solutions != 1) then
set solution = $solution[1]
endif

# Get spacegroups (command separated) for the best solution
set spacegroup = (`cat $labelitOutFile | awk -v solNum=${solution} -f $WEBICE_SCRIPT_DIR/get_integrated_solution_spacegroup.awk`)
# Repalce command with space
set spacegroup = `echo $spacegroup | awk '{gsub(/,/, " ", $0); print $0;}'`

set phiShift = ""
if (-e $bestPhiStrategyFile) then
set phiShift = `cat $bestPhiStrategyFile | awk '/PhiShift/{print "/"$2 "deg";}'`
endif

set hasLabelitPhiShift = `cat $labelitOutFile | awk 'BEGIN {found = 0;} /reindexing delta phi/{found = 1;} END {print found;}'`

if ($hasLabelitPhiShift == 1) then
set phiShift = `cat $labelitOutFile | awk '/reindexing delta phi/{print "/"$5 "deg";}'`
endif

# Is there pseudotranslation?
set pseudotranslation = `cat $labelitOutFile | awk 'BEGIN {found = 0;} /pseudotranslation/{found = 1;} END { print found;}'`
if ($pseudotranslation == 1) then
	echo "solution = ${solution} spacegroup = ${spacegroup} pseudotranslation"
else
	echo "solution = ${solution} spacegroup = ${spacegroup}"
endif

endif # No indexing solution?? 

