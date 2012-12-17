#!/bin/csh -f

############################################################
#
# Generate a summary file for all strategies for the given 
# solution. Must be run in an integrated solution directory.
#
# Usage:
#	generate_strategy_summary.csh [spacegroup]+
#
############################################################


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

# Print header
echo "SP	PhiMinU		PhiMaxU		PhiMinA		PhiMaxA		CompleteU	CompleteA	MaxDeltaPhi"

# Loop over arguments
foreach sp ($*)

	set dataU = (`awk -f $WEBICE_SCRIPT_DIR/get_strategy_summary.awk $sp/strategy.out`)	
	set dataA = (`awk -f $WEBICE_SCRIPT_DIR/get_strategy_summary.awk $sp/strategy_anom.out`)	
	set maxDeltaPhi = `awk -f $WEBICE_SCRIPT_DIR/get_testgen_summary.awk $sp/testgen.out`
	
	echo "$sp	$dataU[1]		$dataU[2]		$dataA[1]		$dataA[2]		$dataU[3]		$dataA[3]		$maxDeltaPhi"

end



