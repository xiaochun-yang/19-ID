#!/bin/bash
#
# Script to alias the "go" command.
# "xterm -e ..." no longer propagates environment variables like TCLLIBPATH
# hence the need for this script
#

# The all important TCLLIBPATH
TCLLIBPATH="/usr/local/lib /usr/local/dcs/widgets /usr/local/dcs/BluIceWidgets /usr/local/dcs/DcsWidgets"
export TCLLIBPATH

# Our bluice executable
BLUICE=/usr/local/dcs/BluIceWidgets/bluice.tcl

# Use the short version of the hostname
HOSTNAME=`/bin/hostname --short`

# List of hostnames that run bluice for a specific beamline
BL15='bl15a|bl15b|bl15c|bl15hutch|blctl15'
BL71='bl71a|bl71b|bl71c|bl71hutch|blctl71'
BL91='bl91a|bl91b|bl91c|bl91hutch|blctl91'
BL92='bl92a|bl92b|bl92c|bl92hutch|blctl92'
BL122='bl122a|bl122b|bl122c|bl122hutch|blctl122'
BL111='bl111a|bl111b|bl111c|bl111hutch|blctl111'
BL113='bl113a|bl113c|blctl111'
BLSIM='blctlsim'
REMOTE='smbnxs1|smbnxs2'

# Needs to be in an 'eval' statement, otherwise the variables won't expand
eval " case $HOSTNAME in
    $BL15)
        BL='BL1-5'
        ;;
    $BL71)
        BL='BL7-1'
        ;;
    $BL91)
        BL='BL9-1'
        ;;
    $BL92)
        BL='BL9-2'
        ;;
    $BL111)
        BL='BL11-1'
        ;;
    $BL113)
        BL='BL11-3'
        ;;
    $BL122)
        BL='BL12-2'
        ;;
    $REMOTE)
        exec /usr/local/dcs/BluIceWidgets/run_bluice.csh
        exit
        ;;
    *)
        echo "ERROR: No beamline configured for your host: $HOSTNAME"
        sleep 3
        exit
        ;;
esac "

# We have a winner
exec $BLUICE $BL

exit

## vi:set ts=4 ##
