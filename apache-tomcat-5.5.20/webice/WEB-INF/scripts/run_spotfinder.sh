#!/bin/sh -f

# Set script dir to this script location
WEBICE_SCRIPT_DIR=`dirname $0`

# Platform specific shell commands
PATH=/usr/sbin:/usr/bin:/bin

export PATH

echo "SPOTWORK = ${SPOTWORK}"


if [ "${SPOTWORK}" = "" ]; then
	echo "ERROR: SPOTWORK env variable not set"
	exit
fi

if [ $# -lt 1 ]; then 
	echo "ERROR: wrong number of command-line arguments (expecting 1 but got $#)"
	
	echo " "
	echo "Usage:"
	echo "run_spotfinder.sh <image file>"
	exit
fi

# First command line argument is image file
imagePath=${1}

$WEBICE_SCRIPT_DIR/generate_distl_markup.csh ${imagePath} ${SPOTWORK}

