#!/bin/csh -f

############################################################
#
# 
#
# Usage:
#	run_screen.csh <input file>
#
############################################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

$WEBICE_SCRIPT_DIR/setup_env.csh

echo `date` " start run_screen.csh"

echo "num args = $#argv"
echo "argv = $argv"

if ($#argv != 11) then
	echo `date +"%T"` " Wrong number of commandline arguments for run_screen.csh"
	echo `date +"%T"` " Usage: screen.csh <workDir> <silHost> <silPort> <caHost> <caPort> <user> <sessionId> <dir> <silId> <beamline> <depth>"
	exit 1
endif

# Change dir to the appropriate dir where
# outptut files will be generated.
set workDir = $argv[1]

mkdir -p $workDir

cd $workDir

echo "run_screen.csh:" >> screen.out
echo "argv = $argv" >> screen.out
echo "HOST = $HOST"
echo "HOME = $HOME"

# Run the actual script in the appropriate dir
$WEBICE_SCRIPT_DIR/screen.csh $argv >>& screen.out &

# List out children ids of this shell session.
# In this case there is only one child which is
# the run_autoindex.csh.
# Write the pid to the control file.
jobs -l

exit 0


