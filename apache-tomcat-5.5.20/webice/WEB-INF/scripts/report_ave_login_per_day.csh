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
	set count = `grep -c "$keyword" $logFile`
	@ sum = $sum + $count
end # foreach logFile

@ ave = $sum / $#logFiles
echo "Total number of login = $sum times between $firstDate to $lastDate ($#logFiles days)."
echo "Average number of login per day = $ave times between $firstDate to $lastDate."
