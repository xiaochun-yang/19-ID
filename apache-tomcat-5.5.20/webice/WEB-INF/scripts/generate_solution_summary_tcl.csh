#!/bin/csh -f


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

awk -f $WEBICE_SCRIPT_DIR/parse_integration_data_tcl.awk $1



