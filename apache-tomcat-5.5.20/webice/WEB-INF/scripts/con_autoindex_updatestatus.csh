#!/bin/csh -f

############################################################
#
# Get status of a background process.
#
# Usage:
#	updateJobStatus.csh <control file>
#
############################################################

# Set script dir to the location of the script
setenv WEBICE_SCRIPT_DIR `dirname $0`


set controlFile = $1

if (! -e $controlFile) then
	echo "not started: control file $controlFile does not exist"
	exit 0
endif

# Process id of the process to kill
set processId = `cat $controlFile`

if ($processId == "Done") then
	echo "not running: done"
	exit 0
endif

if ($processId == "Aborted") then
	echo "not running: aborted"
	exit 0
endif

# Get process group id
set pgid = (`ps -Ao "pid,ppid,pgid,stime,args" -p $processId | awk -v pid=$processId '$1 == pid{ print $3}'`)

if ($pgid == "") then
	echo "not running: pid $processId does not exist"
	exit 0
endif


set host_type = "unknown"
if ( $?HOSTTYPE ) then
set host = $HOSTTYPE
endif

# Get this process id and its descendents
set allProcessIds = (`ps -Ao "pid,ppid,pgid,stime,args" -g $pgid | awk -v pid=$processId -v pgid=$pgid -f $WEBICE_SCRIPT_DIR/get_jobs.awk`)

set stime = `ps -Ao "stime" -p $processId | awk 'NR==2{print $1}'`

# Process id not found
# Assume that it is not running.
if ($#allProcessIds == 0) then
	echo "not running: pid $processId does not exist"
	# Remove control file
#	rm -rf $controlFile
else
	# Change timestamp of the control file 
	# to indicate the last update time.
	touch $controlFile
	echo "running: pid=$processId stime=$stime"
endif


