#!/bin/csh -f

set workDir = `pwd`

set SCRIPT_DIR = `dirname $0`

##############################################################
#
#  Usage:
#
#  run_chooch.sh <scanfile> <element> <edge> <beamline> 
#
#  scan file	- trunk of raw data file e.g. for a raw data
#                 file called SeMet.raw use SeMet
#  element      - two letter atomic symbol (case insensitive)
#  edge         - absorption edge ( K | L1 | L2 | L3 | M )
#  beamline	- Name of the beamline
#
# For example
# run_chooch.sh rawdatafile Se K BL9-2
#
##############################################################

if ($#argv != 4) then
echo "Usage: run_chooch.sh <scanfile> <element> <edge> <beamline>"
echo "	scan file    - trunk of raw data file e.g. for a raw data"
echo "	element      - two letter atomic symbol (case insensitive)"
echo "	edge         - absorption edge ( K | L1 | L2 | L3 | M )"
echo "	beamline     - Name of the beamline. e.g. BL9-2"
endif

set scanfile = $argv[1]
set element = $argv[2]
set edge = $argv[3]
set beamline = $argv[4]

set unique = "123456789012345"

# Remove old data
rm -rf /tmp/${USER}/${unique}

# Copy scan file to tmp dir
cp ${scanfile} /tmp/${USER}/rawdata${unique}

$SCRIPT_DIR/chooch_remote.sh ${unique} ${element} ${edge} ${beamline}

mv /tmp/${USER}/*${unique}* .



