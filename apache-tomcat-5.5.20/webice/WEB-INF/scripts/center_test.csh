#!/bin/csh -f

###########################################
# Run spotfinder and autoindexing
# on images found in a given root directory.
###########################################

# Set script dir to this script location
#setenv WEBICE_SCRIPT_DIR  `dirname $0`

#source $WEBICE_SCRIPT_DIR/setup_env.csh

setenv PATH /usr/local/dcs/http_cpp/linux:$PATH

# Crystal host and port
set silHost = "smb.slac.stanford.edu"
set silPort = "80"

# Crystal-analysis host and port
set caHost = "smb.slac.stanford.edu"
set caPort = "80"

# User and sessionId to access the images and to create analysis out files.
set user = "penjitk"
set sessionId = "47F8CC9D496A31CE90611ADBA461B39D"

# Cassette unique id
set silId = "3697"

# Urls for crystals and crystal-analysis
set addCrystalImageUrl = "http://${silHost}:${silPort}/crystals/addCrystalImage.do"
set analyzeImageUrl = "http://${caHost}:${caPort}/crystal-analysis/jsp/analyzeImageCenter.jsp"
set autoindexUrl = "http://${caHost}:${caPort}/crystal-analysis/jsp/autoindex.jsp"
set getDoneEventIdUrl = "http://${caHost}:${caPort}/crystal-analysis/jsp/getDoneEventId.jsp"

# queue name for this job
# If we set it to user name, we can queue up 
# jobs from each user separately so that one
# user can not submit too many jobs and hog the system.
set queue = "BL11-6"

set dir = "/data/penjitk/dataset/pseudomad"
set image = "myo3_4_E1_001.img"
set group = 1
set row = 0
set portList = (A1 A2 A3 A4 A5 A6 A7 A8 B1 B2)
set lastEvent = -1

set start_time = (`date`)

// START LOOP FOR EACH CRYSTAL
foreach port ($portList)

#set url = "${addCrystalImageUrl}?userName=$user&accessID=$sessionId&silId=$silId&row=$row&group=$group&name=$image&dir=$dir"
#echo "adding image: url = $url"
#http_client $silHost $silPort "$url"

# Run spotfinder
set url = "${analyzeImageUrl}?userName=$user&accessID=$sessionId&silId=$silId&row=$row&imageGroup=$group&imagePath=$dir/$image&crystalId=$port&forBeamLine=$queue"
echo "Analyzing image: url = $url"
set ret = (`http_client $caHost $caPort "$url"`)
if (($#ret == 3) && ($ret[1] == "200")) then
echo "Submitted event = $ret[3]"
set lastEvent = $ret[3]
else
echo "analyzeImage returns: $ret"
endif

set row = `echo $row | awk '{print $1+1;}'`

# END LOOP FOR EACH CRYSTAL
end

set curEvent = -2
set prevEvent = -2
set waitEvent = $lastEvent
echo "Waiting for last submitted event ($lastEvent) to finish..."
while ($curEvent != -1)
set url = "${getDoneEventIdUrl}?userName=$user&accessID=$sessionId&beamline=$queue&type=spotfinder"
set ret = (`http_client $caHost $caPort "$url"`)
if (($#ret == 2) && ($ret[1] == "200")) then
set curEvent = $ret[2]
set hasNewEvent = `echo $curEvent $prevEvent | awk '{if ($1+0 > $2+0) {print "1";} else {print "0";}}'`
if ($hasNewEvent) then
echo "curEvent = $curEvent"
set prevEvent = $curEvent
endif
set done = `echo $curEvent $lastEvent | awk '{if ($1+0 >= $2+0) {print "1";} else {print "0";}}'`
if ($done) then
set curEvent = -1
else
sleep 1
endif
else
echo "getDoneEventId returns: $ret"
echo "Stop waiting"
set curEvent = -1
endif
end
echo "Last event ($lastEvent) finished"

set end_time = (`date`)

echo "TEST1"
echo "start = $start_time"
echo "end   = $end_time"

set curDir = `pwd`

set elList = (1 2 3 4 5 6 7 8 9 0)
set testDir = "/data/penjitk/tmp/center_test"
mkdir -p $testDir
cd $testDir
set start_time = (`date`)
foreach dummy ($elList)
/usr/local/dcs/spotfinder/linux/spotfinder -i /usr/local/dcs/spotfinder/linux/center.par -d . $dir/$image
end
set end_time = (`date`)
echo "TEST2"
echo "start = $start_time"
echo "end   = $end_time"

cd $curDir


