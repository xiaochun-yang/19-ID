#!/bin/csh -f

if (! $?CATALINA_HOME) then
echo "CATALINA_HOME is undefined."
exit
endif

set keyword = "INFO Client logged in:"

cd $CATALINA_HOME/logs
set logFiles = (`ls webice.log*`)

set sum = 0
set firstDate = ""
set lastDate = ""

foreach logFile ($logFiles)
	set logDate = `echo $logFile | awk -F. '{print $3;}'`
	if ($firstDate == "") then
		set firstDate = $logDate
	endif
	set lastDate = $logDate
end

grep "$keyword" webice.log* | awk -v firstDate=$firstDate -v lastDate=$lastDate ' \
	BEGIN {count = 1;} \
	/INFO Client logged in:/{	\
		split($8, arr, "="); \
		name = arr[2]; \
		if (numLogin[name] == "") { \
			users[count] = name; \
			count = count + 1; \
		} \
		numLogin[name] = numLogin[name] + 1; \
	} \
	END { \
		for (i=1;i<count;i++) { \
			totLogin = totLogin + numLogin[users[i]]; \
		} \
		print "Total number of login = " totLogin " times by " count-1 " users between " firstDate " to " lastDate "." \
	}'

