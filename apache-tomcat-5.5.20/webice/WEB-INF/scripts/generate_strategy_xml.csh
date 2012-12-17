#!/bin/csh -f


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

# workDir is current dir
set workDir = `pwd`

echo "<strategy>"
if (-e strategy.out) then
    awk -f $WEBICE_SCRIPT_DIR/parse_strategy_data.awk strategy.out
else
    if (-e best.out) then
	    echo " <completenessStrategy>"
	    echo "  <summary>"
	    echo "  </summary>"
	    echo "   <uniqueData>"
	    awk -f $WEBICE_SCRIPT_DIR/parse_strategy_data_best.awk best.out
 	    echo "   </uniqueData>"
	    echo " </completenessStrategy>"
    else 
	echo "  <completenessStrategy>"
	echo "    <error>Neither $workDir/strategy.out nor $workDir/best.out exist.</error>"
	echo "  </completenessStrategy>"
    endif
endif
if (-e strategy_anom.out) then
    awk -f $WEBICE_SCRIPT_DIR/parse_anomstrategy_data.awk strategy_anom.out
else
	if (-e best_anom.out) then
	    echo " <anomalousStrategy>"
	    echo "  <summary>"
    	    echo "  </summary>"
	    echo "   <uniqueData>"
 	    echo "   </uniqueData>"
	    echo "   <anomalousData>"
	    awk -f $WEBICE_SCRIPT_DIR/parse_strategy_data_best.awk best_anom.out 
	    echo "   </anomalousData>"
	    echo " </anomalousStrategy>"
	else
	    echo "  <anomalousStrategy>"
	    echo "    <error>Neither $workDir/strategy_anom.out nor $workDir/best_anom.out exist.</error>"
	    echo "  </anomalousStrategy>"
    endif
endif
if (-e testgen.out) then
    awk -f $WEBICE_SCRIPT_DIR/parse_testgen_data.awk testgen.out
else
	if (-e best.out) then
	    awk -f $WEBICE_SCRIPT_DIR/parse_testgen_data.awk ../testgen.out
	else
	    echo "  <testgen>"
	    echo "    <error>$workDir/testgen.out does not exist.</error>"
	    echo "  </testgen>"
	endif
endif
echo "</strategy>"

