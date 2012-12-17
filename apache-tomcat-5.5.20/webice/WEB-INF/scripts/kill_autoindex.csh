#!/bin/csh -f

############################################################
#
# Kill a process and its children. Process id can be found
# in the control file.
#
# Usage:
#	kill_autoindex.csh <control file>
#
############################################################


# Set script dir to the location of the script
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

# Set workDir to the location of input.xml
set workDir = `dirname $1`

set controlFile = $1

if (! -e $controlFile) then
	echo `date +"%T"` " Cannot find or open control file: $controlFile"
	exit 0
endif

# Process id of the process to kill
set processId = `cat $controlFile`

set done = 0
set found = 0
while ($done != 1)

# Get process group id
set pgid = (`ps -o "pid,ppid,pgid,stime,args" -p $processId | awk -v pid=$processId '$1 == pid{ print $3}'`)
if ($pgid == "") then
	echo `date +"%T"` " Process $processId does not exist"
	echo `date +"%T"` " autoindex aborted" >> $workDir/autoindex.out
	echo "Aborted" > $controlFile
	exit 0
endif

# Get this process id and its descendents
set allProcessIds = (`ps -o "pid,ppid,pgid,stime,args" -g $pgid | awk -v pid=$processId -v pgid=$pgid -f $WEBICE_SCRIPT_DIR/get_jobs.awk`)

echo "Killing processes $allProcessIds"
# Process id not found
# Assume that it is not running.
# Otherwise, kill the process and its children.
if ($#allProcessIds == 0) then
	if ($found == 0) then
		echo `date +"%T"` " Process $processId does not exist"
	endif
	set done = 1
	echo `date +"%T"` " Killed process(es) successfully"
	echo `date +"%T"` " autoindex aborted" >> $workDir/autoindex.out
	echo "Aborted" > $controlFile
else
	set found = 1
	echo `date +"%T"` " Killing process(es): $allProcessIds"
	kill -9 $allProcessIds
endif

end

