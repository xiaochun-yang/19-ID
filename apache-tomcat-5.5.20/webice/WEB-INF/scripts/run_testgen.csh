#!/bin/csh -f


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh


# Make sure the env variables are set
if ($WORK_DIR == "") then
	echo "ERROR: WORK_DIR env variable not set"
	exit
endif


# cd to the work dir
cd $WORK_DIR


# Run strategy
./strategy.mfm

# Run anomalous strategy
./testgen.mfm


