#!/bin/csh

# Generate random filename
set tmpFile = `echo junk | awk 'BEGIN{srand()}{print "/tmp/tmp" rand()}'`

# Set env to pass info to bluice_remote.tcl
setenv FIFO_NAME $tmpFile

# Get session id and save it in /home/<user>/.bluice/session file.
# Also get beamline host and beamline name, and save them in tmpFile file.
/usr/local/dcs/BluIceWidgets/bluice_remote.tcl

# The file is not created if user has no permisison
# to access a beamline
if (-e $tmpFile) then

# Read tmpFile and delete it
set tmp = (`cat $tmpFile`)
rm -rf $tmpFile

# Extract host name and beamline name from tmpFile
set bluiceHost = $tmp[1]
set beamline = $tmp[2]

echo "host = $bluiceHost"
echo "beamline = $beamline"
# Set xterm title bar. Not working.
#echo -n "\033]2;${USER}@${bluiceHost} - bluice.tcl\007"

# ssh to the beamline host and runs bluice on it.
#ssh $bluiceHost /usr/local/dcs/BluIceWidgets/bluice.tcl $beamline
ssh -n $bluiceHost /usr/local/bin/go $beamline

endif

