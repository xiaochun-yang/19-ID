#!/bin/csh -f

if (! $?CATALINA_HOME) then
echo "CATALINA_HOME is undefined."
exit
endif

if ($#argv == 0) then
echo "Search keyword undefined."
exit
endif

cd $CATALINA_HOME/logs
set logFiles = (`ls webice.log*`)

set sum = 0
set firstDate = ""
set lastDate = ""

set keyword = $1

foreach logFile ($logFiles)
	set logDate = `echo $logFile | awk -F. '{print $3;}'`
	if ($firstDate == "") then
		set firstDate = $logDate
	endif
	set lastDate = $logDate
	set count = `grep -c "$keyword" $logFile`
	echo "Num data collection = $count on $logDate"
	@ sum = $sum + $count
end # foreach logFile

echo "Total $WEBICE_TOPIC = $sum times between $firstDate to $lastDate."

