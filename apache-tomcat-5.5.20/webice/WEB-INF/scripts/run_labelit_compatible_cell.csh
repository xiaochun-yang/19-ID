#!/bin/csh -f

############################################################
#
# Usage:
#	run_labelit_compatible_cell.csh
#
############################################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

if ($#argv == 1) then
set laueGroup = $argv[1]
labelit.compatible_cell known_symmetry=$laueGroup
exit 0
endif

if ($#argv >= 7) then
set laueGroup = $argv[1]
set a = $argv[2]
set b = $argv[3]
set c = $argv[4]
set alpha = $argv[5]
set beta = $argv[6]
set gamma = $argv[7]
labelit.compatible_cell known_symmetry=$laueGroup known_cell=$a,$b,$c,$alpha,$beta,$gamma
exit 0
endif


echo "Invalid number of args for run_labelit_compatible_cell.csh"



