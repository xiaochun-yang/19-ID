#!/bin/csh -f


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

# workDir is current dir
set workDir = `pwd`

echo "{ strategy"
if (-e strategy.out) then
    awk -f $WEBICE_SCRIPT_DIR/parse_strategy_data_tcl.awk strategy.out
    else
    if (-e best.out) then
	echo "  { completenessStrategy"
	echo "    { summary "
	echo "    } "
	echo "    { uniqueData \n      {"  
	cat best.out    
	echo "      }\n    }"  
	echo "  }"
    endif
endif 
if (-e strategy_anom.out) then
    awk -f $WEBICE_SCRIPT_DIR/parse_anomstrategy_data_tcl.awk strategy_anom.out
    else
    if (-e best_anom.out) then
	echo "  { anomalousStrategy"
	echo "    { summary "
	echo "    } "
	echo "    { uniqueData"  
	echo "    }"  
	echo "    { anomalousData \n      {"
	cat best_anom.out    
	echo "      } \n    }"
	echo "  }"
    endif
endif 
if (-e testgen.out) then
awk -f $WEBICE_SCRIPT_DIR/parse_testgen_data_tcl.awk testgen.out
    else
	if (-e best.out) then
	    awk -f $WEBICE_SCRIPT_DIR/parse_testgen_data_tcl.awk ../testgen.out
  	endif
echo "}"
endif

