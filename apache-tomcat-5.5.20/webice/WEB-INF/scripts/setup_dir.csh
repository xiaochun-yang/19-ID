#!/bin/csh -f

set workDir = $1
set backup = 0
if ($#argv == 2) then
set backup = 1
endif

# Set script dir to the location of the script
setenv SCRIPT_DIR `dirname $0`

# Setup basic env
source $SCRIPT_DIR/setup_env.csh

set is_running = 0

if ($workDir != "") then

if (-d $workDir) then


# Check the control file and make sure the job is not still running
if (-e $workDir/control.txt) then
#echo "setup_dir: found $workDir/control.txt"
set job_status = `$SCRIPT_DIR/updateJobStatus.csh $workDir/control.txt`
#echo "setup_dir: content of control file = `cat $workDir/control.txt`"
set is_running = `echo "$job_status" | awk '{ if ($1 == "running") { print "1"; } else {print "0"; } }'`
echo "setup_dir: is_running = $is_running"
if ($is_running == 1) then
echo "setup_dir: $workDir contains job that is still running."
exit
endif # if is_running
endif # if control.txt exists

endif

if ($backup == 1) then
	if (-d $workDir) then
	set NN = 1
	set backupDir = ${workDir}_backup${NN}
	echo "Checking backup dir $backupDir."
	while (-d $backupDir)
		echo "backup dir $backupDir exists."
		set NN = `echo $NN | awk '{print $1+1;}'`
		set backupDir = ${workDir}_backup${NN}
	end
	mv $workDir $backupDir
	endif
else	# backup
	if ($is_running != 1) then
		if (-d $workDir) then
			rm -rf $workDir/autoindex.out
			rm -rf $workDir/control.txt
			rm -rf $workDir/input.xml
			rm -rf $workDir/run_summary.xml
			rm -rf "$workDir/strategy_summary.tcl"
			rm -rf "$workDir/error.txt"
			rm -rf "$workDir/fatal_error.txt"
			set remountDirs = (`ls $workDir`)
			foreach subDir ($remountDirs)
				if (-d $workDir/$subDir) then
					rm -rf "${workDir}/$subDir"
				endif
			end
		endif
	endif
endif # backup


# Create directory if it does not already exist
mkdir -p $workDir

endif




