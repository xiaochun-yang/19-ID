#!/bin/csh -f

############################################################
#
#
# Usage:
#	run_matthews_coef.csh number_of_residues spacegroup cell predictedRes
#
############################################################


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

#echo `date +"%T"`" num residues = $1"

set numResidues = $1
set spacegroup = $2
set cell = "$3 $4 $5 $6 $7 $8"
set tmp = $9
set reso = `echo $tmp | awk '{if ($0 > 0) print "reso '$tmp'"}'`

#note the predictedRes is used in the scoring as shown in the log but the xml only saves the total probability
matthews_coef << eof
symm $spacegroup
cell $cell
$reso
nres $numResidues
auto
xmloutput
eof

exit
