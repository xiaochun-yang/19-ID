#!/bin/csh -f

###########################################
# Run spotfinder and autoindexing
# on images found in a given root directory.
###########################################

# Set script dir to this script location
#setenv WEBICE_SCRIPT_DIR  `dirname $0`

#source $WEBICE_SCRIPT_DIR/setup_env.csh

#setenv PATH /usr/local/dcs/http_cpp/linux:$PATH
setenv PATH /data/penjitk/tmp/http_cpp:$PATH

# Crystal host and port
set silHost = "smb.slac.stanford.edu"
set silPort = "80"

# Crystal-analysis host and port
set caHost = "smbdev1.slac.stanford.edu"
set caPort = "80"

# User and sessionId to access the images and to create analysis out files.
set user = "penjitk"
set sessionId = "19AB94B05C3E5945F4B81208AAEC8579"

# Cassette unique id
set silId = "3697"

# Urls for crystals and crystal-analysis
set addCrystalImageUrl = "http://${silHost}:${silPort}/crystals/addCrystalImage.do"
set analyzeImageUrl = "http://${caHost}:${caPort}/crystal-analysis/jsp/analyzeImage.jsp"
set autoindexUrl = "http://${caHost}:${caPort}/crystal-analysis/jsp/autoindex.jsp"
set getDoneEventIdUrl = "http://${caHost}:${caPort}/crystal-analysis/jsp/getDoneEventId.jsp"

# queue name for this job
# If we set it to user name, we can queue up 
# jobs from each user separately so that one
# user can not submit too many jobs and hog the system.
set queue = "BL9-1"

set dir = "/data/penjitk/dataset/pseudomad"
set image1 = "myo3_4_E1_001.img"
set image2 = "myo3_4_E1_040.img"
set row = 33
set crystalId = "E2"

set url = "${addCrystalImageUrl}?userName=$user&accessID=$sessionId&silId=$silId&row=$row&group=1&name=$image1&dir=$dir"
echo "adding image1: url = $url"
http_client $silHost $silPort "$url"

# Run spotfinder on image1
set url = "${analyzeImageUrl}?userName=$user&accessID=$sessionId&silId=$silId&row=$row&imageGroup=1&imagePath=$dir/$image1&crystalId=$crystalId&forBeamLine=$queue"
echo "Analyzing image1: url = $url"
http_client $caHost $caPort "$url"

set url = "${addCrystalImageUrl}?userName=$user&accessID=$sessionId&silId=$silId&row=$row&group=2&name=$image2&dir=$dir"
echo "adding image2: url = $url"
http_client $silHost $silPort "$url"

# Run spotfinder on image2
set url = "${analyzeImageUrl}?userName=$user&accessID=$sessionId&silId=$silId&row=$row&imageGroup=2&imagePath=$dir/$image2&crystalId=$crystalId&forBeamLine=$queue"
echo "Analyzing image2: url = $url"
http_client $caHost $caPort "$url"

set url = "${autoindexUrl}?userName=$user&accessID=$sessionId&silId=$silId&row=$row&image1=$dir/$image1&image2=$dir/$image2&uniqueID=$crystalId&forBeamLine=$queue&strategy=true"
echo "Autoindex: url = $url"
http_client $caHost $caPort "$url"



