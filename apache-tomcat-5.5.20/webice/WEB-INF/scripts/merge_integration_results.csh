#!/bin/csh -f

############################################################
#
# Merge integration results into Integration Result table
# in labelit.out.
#
# Usage:
#	merge_integration_results.csh
#
############################################################


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

# workDir is current dir
set workDir = `pwd`

if (! -e LABELIT/labelit.out) then
	echo `date +"%T"` " Cannot find or open $workDir/LABELIT/labelit.out"
	exit 1
endif

# Create tmp filename
set fileName = `echo junk | awk '{print "tmp" rand()}'`

# List all solutions
find . -name "solution*" -print | awk '/^.\//{ str = substr($0, 11, 2); if (substr(str, 1, 1) == "0") { print substr(str, 2, 1); } else { print str; } }' > $fileName
set sols = (`awk -f $WEBICE_SCRIPT_DIR/sort_solutions.awk $fileName`)

rm -rf $fileName

# Get resolution and mosaicity of best solution
set bestSolStats = (`awk -f $WEBICE_SCRIPT_DIR/get_bestsolution_stats.awk LABELIT/labelit.out`)

foreach solNum ($sols)

	# Get beam center, distance and RMS of the given solution
	set num = `echo $solNum | awk '{ if ($0 < 10) { print "0"$0 } else { print $0 } }'`
	set inStats = (`awk -f $WEBICE_SCRIPT_DIR/get_integration_statistics.awk solution${num}/index${num}.out`)

	# Get lattice for the given solution
	set lattice = `awk -v solNum=$solNum -f $WEBICE_SCRIPT_DIR/get_autoindex_solution_lattice.awk LABELIT/labelit.out`
	
	# Get all space groups for the given lattice
	set spacegroups = `awk -v separator="," -v lattice=$lattice -f $WEBICE_SCRIPT_DIR/get_all_spacegroups.awk $WEBICE_SCRIPT_DIR/latticegroups.txt`
		
	# Insert the solution into Integration Result table in labelit.out
	cp LABELIT/labelit.out LABELIT/labelit.tmp
		
	awk -v solNum=$solNum -v spacegroups=$spacegroups -v x=$inStats[1] -v y=$inStats[2] \
		-v distance=$inStats[3] -v resolution=$bestSolStats[1] \
		-v mosaicity=$bestSolStats[2] -v RMS=$inStats[4] \
		-f $WEBICE_SCRIPT_DIR/insert_solutions.awk LABELIT/labelit.tmp > LABELIT/labelit.out
	
	rm -rf LABELIT/labelit.tmp
end

