#!/bin/csh -f

############################################################
#
#
# Usage:
#	run_phaser.csh number_of_residues mtz_file spacegroup predictedRes
#
############################################################


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

#echo `date +"%T"`" num residues = $1"
#echo `date +"%T"`" mtz file = $2"
#echo `date +"%T"`" spacegroup = $3"
#echo `date +"%T"`" predictedRes = $4"

set numResidues = $1
set mtz = $2
set spacegroup = $3
set tmp = $4
set reso = `echo $tmp | awk '{if ($0 > 0) print "reso '$tmp'"}'`
if (! -e $mtz) then
echo `date +"%T"`" mtz file $mtz not found."
exit 0
endif
set mw = `echo "$numResidues" | awk '{ mw = (110 * $1); printf("%g", mw);}'`

# replaced this with matthews_coeff to remove the requirement for an input mtz file
# TODO input reso estimate - note "reso" with no arguments is not accepted by phaser, and this option is broken in 1.3.3 anyway
# TODO redirect phaser output - save it since no .sum file is generated for some input errors
phaser << eof
hklin $mtz
spac $spacegroup
labi F=I SIGF=SIGI
mode mr_cca
$reso
comp prot mw $mw num 1
eof

exit
