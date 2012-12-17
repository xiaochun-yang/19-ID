#!/bin/sh -f
#################################
#
# Borne shell script for
# executing Benny, Chooch and wasel
# remotely.
# 
# Modified from Chooch cshell script
# by Ashley which in turns modified from
# that of Gwyndaf Evans (last update 29 October 1999).
#
##############################################################
#
#  Usage:
#
#  chooch_remote.sh <uniqueName> <element> <edge> <beamline> 
#
#  scan file	- trunk of raw data file e.g. for a raw data
#                 file called SeMet.raw use SeMet
#  element      - two letter atomic symbol (case insensitive)
#  edge         - absorption edge ( K | L1 | L2 | L3 | M )
#  beamline		- Name of the beamline
#  uniqueName   - 
#
# For example
# chooch_remote.sh Se K scan
# Where scan.raw must be in /tmp/username directory.
#
##############################################################


# Make sure the env variables are set
if [ "${CHOOCHBIN}" = "" ]; then
	echo "ERROR: CHOOCHBIN env variable not set"
	exit
fi

if [ "${CHOOCHDAT}" = "" ]; then
	echo "ERROR: CHOOCHDAT env variable not set"
	exit
fi

if [ "${USER}" = "" ]; then
	echo "ERROR: USER env variable not set"
	exit
fi

echo "CHOOCHBIN=${CHOOCHBIN}"
echo "CHOOCHDAT=${CHOOCHDAT}"
echo "USER=${USER}"
echo "TMPDIR=${TMPDIR}"


# Platform specific shell commands
CP=/bin/cp
MV=/bin/mv
LN=/bin/ln
RM=/bin/rm
MKDIR=/bin/mkdir


# Create /tmp/username if it doesn't already exist
if [ ! -e /tmp/${USER} ]; then 
	echo "Creating a directory /tmp/${USER}"
	${MKDIR} /tmp/${USER} 
fi

# change dir to /tmp/username
# Benny and Chooch read input files from and write
# output files to this directory.
cd /tmp/${USER}

echo The Current directory is `pwd`

if [ $# -lt 4 ]; then 
	echo "ERROR: wrong number of command-line arguments (expecting 4 but got $#)"
fi

# Create a unique filename from process id
uniqueName=${1}
echo "All output filenames are suffixed by ${uniqueName}"


# Run Chooch_auto to find f', f'' 
${CHOOCHBIN}/Chooch_auto ${uniqueName}


# Check if there is a par file for this beamline
parFile=${4}${uniqueName}.par

if [ -e ${CHOOCHDAT}/${4}.par ]; then
	# Copy beamline file
	${CP} ${CHOOCHDAT}/${4}.par ${parFile}
else
	# Copy default file
	${CP} ${CHOOCHDAT}/beamline.par ${parFile}
fi



# Run wasel_auto to get f', f'' for remote energy
# Usage: wasel_auto <atom file> <anom factor file> <parfile>
${CHOOCHBIN}/wasel ${CHOOCHDAT}/${2}.dat anomfacs${uniqueName} $parFile

echo "Removing tmp files"

# Remove temporary files
echo "Deleting temp files *${uniqueName}"
${RM} -f splinor${uniqueName} splinor_raw${uniqueName}
${RM} -f atomdata${uniqueName} atomname${uniqueName}
${RM} -f anomfacs${uniqueName} pre_poly${uniqueName} post_poly${uniqueName}
${RM} -f valuefile${uniqueName}
#${RM} -f ${parFile}

echo "Exiting chooch_remote2.sh"

# done
exit




