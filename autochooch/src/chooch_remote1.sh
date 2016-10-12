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
#  beamline	- Name of the beamline
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

if [ -e smooth_exp${uniqueName}.bip ]; then
	${RM} -f smooth_exp${uniqueName}.bip
fi

if [ -e smooth_norm${uniqueName}.bip ]; then 
	${RM} -f smooth_norm${uniqueName}.bip
fi

if [ -e fp_fpp${uniqueName}.bip ]; then
	${RM} -f fp_fpp${uniqueName}.bip
fi

if [ -e pre_poly${uniqueName} ]; then
	${RM} -f pre_poly${uniqueName}
fi

if [ -e post_poly${uniqueName} ]; then
	${RM} -f post_poly${uniqueName}
fi


# Creating atomename file from input parameters
# atomname file is used by Benny.
echo ${2} 1>atomname${uniqueName}
echo ${3} 1>>atomname${uniqueName}

if [ ! -e atomname${uniqueName} ]; then
	echo "ERROR: failed to create atomname file"
	exit
fi

# Create a symbolic link of atom.lib file in the current dir
${LN} -s ${CHOOCHDAT}/atom.lib atomdata${uniqueName}

if [ ! -e ${CHOOCHDAT}/atom.lib ]; then
	echo "ERROR: ${CHOOCHDAT}/atom.lib does not exist."
	exit
fi

if [ ! -e atomdata${uniqueName} ]; then
	echo "ERROR: failed to make symbolic link for atom.lib"
	exit
fi


# Copy scan file to rawdata file
if [ ! -e rawdata${uniqueName} ]; then 
	echo " ERROR: Could not find data file rawdata${uniqueName}"
	exit
fi

# Run Benny_auto to generate curves
${CHOOCHBIN}/Benny_auto ${uniqueName}


echo "Exiting chooch_remote1.sh"

# done
exit




