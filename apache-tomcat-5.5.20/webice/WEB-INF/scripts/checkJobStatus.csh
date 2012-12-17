#!/bin/csh -f

############################################################
#
# Get status of a background process.
#
# Usage:
#	checkJobStatus.csh <control file>
#
############################################################

# Set script dir to the location of the script
setenv WEBICE_SCRIPT_DIR `dirname $0`


set controlFile = $1
set workDir = `dirname $controlFile`
set errorFile = ${workDir}/error.txt

if (! -e $controlFile) then
	if (-e $errorFile) then
		echo "not running: "`cat $errorFile`
		exit 0
	else
		echo "not started: control file $controlFile does not exist"
		exit 0
	endif
endif

# Process id of the process to kill
set processId = `cat $controlFile | awk '{print $1;}'`

if ("$processId" == "Done") then
	echo "not running: no process id in control file"
	exit 0
endif

if ("$processId" == "Aborted") then
	echo "not running: aborted"
	exit 0
endif

# Assume that the second string is the host name
set processHost = `cat $controlFile | awk '{print $2;}'`
if ("$processHost" == "") then
#echo "ERROR: cannot determine on which host process $processId is running."
#exit 0
set processHost = $HOST
endif 

if ($processHost != $HOST) then
echo "ERROR: checking process $processId on the wrong host ($HOST instead of $processHost)."
exit 0
endif


# Get process group id
set pgid = (`ps -o "pid,ppid,pgid,stime,args" -p $processId | awk -v pid=$processId '$1 == pid{ print $3}'`)

if ($pgid == "") then
	echo "not running: pid $processId does not exist"
	exit 0
endif

set host_type = "unknown"
if ( $?HOSTTYPE ) then
set host = $HOSTTYPE
endif

if ($host == "alpha") then

# Get this process id and its descendents
set allProcessIds = (`ps -o "pid,ppid,pgid,stime,args" -g $pgid | awk -v pid=$processId -v pgid=$pgid -f $WEBICE_SCRIPT_DIR/get_jobs.awk`)

else

# Get this process id and its descendents
set allProcessIds = ( $processId )

endif

set stime = `ps -o "stime" -p $processId | awk 'NR==2{print $1}'`

# Process id not found
# Assume that it is not running.
if ($#allProcessIds == 0) then
	echo "not running: pid $processId does not exist"
else
	# Change timestamp of the control file 
	# to indicate the last update time.
	touch $controlFile
	echo "running: pid=$processId stime=$stime"
endif


