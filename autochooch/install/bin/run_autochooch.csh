#!/bin/csh -f

##############################################################
#
#  Usage:
#
#  chooch_remote.sh <raw scan file> <element> <edge> <beamline> 
#
#  scan file	- trunk of raw data file e.g. for a raw data
#                 file called SeMet.raw use SeMet
#  element      - two letter atomic symbol (case insensitive)
#  edge         - absorption edge ( K | L1 | L2 | L3 | M )
#  beamline	- Name of the beamline
#  uniqueName   - 
#
# For example
# run_autochooch.sh rawdata Se K scan
#
##############################################################

set CHOOCHBIN = `dirname $0`
set ROOTDIR = `dirname $CHOOCHBIN`
set CHOOCHDAT = $ROOTDIR/data
set TMPDIR = /tmp/$USER

if ($#argv != 4) then
	echo "ERROR: wrong number of command-line arguments (expecting 4 but got $#argv)"
	echo "Usage: run_autochooch.csh <raw scan file> <element> <edge> <beamline>"
	exit
endif

if (! -d $TMPDIR) then
	mkdir $TMPDIR
endif

cd $TMPDIR

set orgScanPath = $1
set orgScanFileName = `basename $orgScanPath`
set element = $2
set edge = $3
set beamline = $4
set uniqueName = `echo junk | awk '{filler = rand()*(10^15); printf("%d", filler);}'` 
set scanFile = rawdata${uniqueName}

# Remove old files
rm -rf "*${uniqueName}*"

# Copy scan data to tmp dir. New file has unqiue name, length = 15.
cp $orgScanPath $scanFile


# Creating atomename file from input parameters
# atomname file is used by Benny.
echo ${element} >atomname${uniqueName}
echo ${edge} >>atomname${uniqueName}

if (! -e atomname${uniqueName}) then
	echo "ERROR: failed to create atomname file"
	exit
endif


# Create a symbolic link of atom.lib file in the current dir
ln -s ${CHOOCHDAT}/atom.lib atomdata${uniqueName}

if ( ! -e ${CHOOCHDAT}/atom.lib ) then
	echo "ERROR: ${CHOOCHDAT}/atom.lib does not exist."
	exit
endif


if ( ! -e atomdata${uniqueName} ) then
	echo "ERROR: failed to make symbolic link for atom.lib"
	exit
endif

# Copy scan file to rawdata file
if ( ! -e rawdata${uniqueName} ) then 
	echo " ERROR: Could not find data file rawdata${uniqueName}"
	exit
endif

# Run Benny_auto to generate curves
${CHOOCHBIN}/Benny_auto ${uniqueName}

# Run Chooch_auto to find f', f'' 
${CHOOCHBIN}/Chooch_auto ${uniqueName}

set parFile = ${beamline}${uniqueName}.par

if ( -e ${CHOOCHDAT}/${4}.par ) then
	# Copy beamline file
	cp ${CHOOCHDAT}/${beamline}.par ${parFile}
else
	# Copy default file
	cp ${CHOOCHDAT}/beamline.par ${parFile}
endif

# Run wasel_auto to get f', f'' for remote energy
# Usage: wasel_auto <atom file> <anom factor file> <parfile>
${CHOOCHBIN}/wasel ${CHOOCHDAT}/${element}.dat anomfacs${uniqueName} $parFile

echo "Removing tmp files"

# Remove temporary files
echo "Deleting temp files *${uniqueName}"
rm -rf splinor${uniqueName} splinor_raw${uniqueName}
rm -rf atomdata${uniqueName} atomname${uniqueName}
rm -rf anomfacs${uniqueName} pre_poly${uniqueName} post_poly${uniqueName}
rm -rf valuefile${uniqueName}

# done
exit


