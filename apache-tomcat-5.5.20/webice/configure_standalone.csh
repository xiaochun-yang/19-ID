#!/bin/csh -f

# Script to setup webice configuration file

echo "Welcome to WEBICE configuration tool"
echo "..."
echo "..."

# property file
set propFile = "WEB-INF/webice.properties"

set tomcatRootDir = $CATALINA_HOME

set webiceDir = `pwd`
cd ../../..
set rootDir = `pwd`
cd $webiceDir

# Tomcat
set tomcatHost = $HOST
set tomcatPort = "8080"
set tomcatSecPort = "8443"
set authHost = $HOST
set authPort = $tomcatPort
set impHost = $HOST
set impPort = "61001"
set imgHost = $HOST
set imgPort = "14007"

echo "host = $HOST"
echo "webice dir = $webiceDir"
echo "root dir = $rootDir"
echo "tomcat dir = $tomcatRootDir"

echo "Tomcat port [$tomcatPort]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set tomcatPort = $str
endif
echo "$tomcatPort"

# Tomcat secured port
echo "Tomcat secured port [$tomcatSecPort]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set tomcatSecPort = $str
endif
echo "$tomcatSecPort"

echo "Authentication Host [$authHost]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set authHost = $str
endif
echo "$authHost"

echo "Authentication Port [$authPort]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set authPort = $str
endif
echo "$authPort"


# webice.userRootDir
#set userRootDir = `cat $propFile | awk '/webice.userRootDir=/{split($0, ret, "="); print ret[2];}'`
set userRootDir = "/data/<user>"
echo "User root directory (this is where webice output directory will be created) [$userRootDir]: "
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set userRootDir = $str
endif
echo "$userRootDir"

set userConfigDir = "/home/<user>"
echo "User config directory (this is where webice config directory for the user will be created) [$userConfigDir]: "
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set userConfigDir = $str
endif
echo "$userConfigDir"

set userImageRootDir = "/data/<user>"
echo "User image directory [$userImageRootDir]: "
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set userImageRootDir = $str
endif
echo "$userImageRootDir"

# auth
set authGatewayUrl = "http://"$authHost":"$authPort"/gateway/servlet/"


if (-e $propFile) then
	mv $propFile ${propFile}.bak
endif

echo "# Accessibility" > $propFile
echo "# accessMode must be either all, some or none." >> $propFile
echo "# accessMode=all -> Allow all users" >> $propFile
echo "# accessMode=some -> Allow all users except those listed under excludedUser" >> $propFile
echo "# accessMode=staff -> Allow all staff and those listed under includedUser" >> $propFile
echo "# accessMode=none -> Allow none except those listed under includedUser" >> $propFile
echo "# all: all - exclude" >> $propFile
echo "# some: include - exclude" >> $propFile
echo "# staff: staff + include - exclude" >> $propFile
echo "# none: include" >> $propFile
echo "webice.accessMode=all" >> $propFile
echo "webice.includeUsers=" >> $propFile
echo "webice.excludeUsers=" >> $propFile

echo " " >> $propFile
echo "# This is where webice output dir is located" >> $propFile
echo "webice.userRootDir=$userRootDir" >> $propFile

echo " " >> $propFile
echo "# Default dir where we can create/find '.webice' dir. The dir contains" >> $propFile
echo "# default.properties file." >> $propFile
echo "webice.userConfigDir=$userConfigDir" >> $propFile

echo " " >> $propFile
echo "# Default dir for browsing image files" >> $propFile
echo "webice.userImageRootDir=$userImageRootDir" >> $propFile

echo " " >> $propFile
echo "# Webice http and https ports" >> $propFile
echo "webice.port=$tomcatPort" >> $propFile
echo "webice.portSecure=$tomcatSecPort" >> $propFile


echo " " >> $propFile
echo "# Max inactive interval (in seconds) before the user is logged out" >> $propFile
echo "# of webice." >> $propFile
echo "webice.maxInactiveInterval=1800" >> $propFile

echo " " >> $propFile
echo "# Authentication server" >> $propFile
echo "auth.host=$authHost" >> $propFile
echo "auth.port=$authPort" >> $propFile
echo "auth.methodName=smb_config_database" >> $propFile
echo "auth.gatewayUrl=$authGatewayUrl" >> $propFile

echo " " >> $propFile
echo "# Impersonation daemon" >> $propFile
echo "imperson.host=$impHost" >> $propFile
echo "imperson.port=$impPort" >> $propFile

echo " " >> $propFile
echo "# Image server" >> $propFile
echo "imgsrv.host=$imgHost" >> $propFile
echo "imgsrv.port=$imgPort" >> $propFile

echo " " >> $propFile
echo "# Impersonation daemon for running spotfinder" >> $propFile
echo "spotfinder.impersonHost=$impHost" >> $propFile
echo "spotfinder.impersonPort=$impPort" >> $propFile
echo "spotfinder.version=2.0" >> $propFile

echo " " >> $propFile
echo "# Impersonation daemon for running autoindex" >> $propFile
echo "autoindex.host=$impHost" >> $propFile
echo "autoindex.port=$impPort" >> $propFile

echo " " >> $propFile
echo "# Crystals server" >> $propFile
echo "sil.host=$tomcatHost" >> $propFile
echo "sil.port=$tomcatPort" >> $propFile
echo "crystalsUrl=http://"'${sil.host}'":"'${sil.port}'"/crystals" >> $propFile
echo "sil.dtd=sil-1_0.dtd" >> $propFile
echo "sil.url=https://"$tomcatHost":"$tomcatPort"/crystals/CassetteInfo.jsp" >> $propFile
echo "sil.getSilUrl="'${crystalsUrl}'"/crystals/getSil.do" >> $propFile
echo "sil.getSilListUrl="'${crystalsUrl}'"/crystals/getSilList.do" >> $propFile
echo "sil.setCrystalUrl="'${crystalsUrl}'"/crystals/setCrystal.do" >> $propFile
echo "sil.isEventCompletedUrl="'${crystalsUrl}'"/crystals/isEventCompleted.do" >> $propFile
echo "sil.dtdUrl="'${crystalsUrl}'"/crystals/data/templates/sil-1_0.dtd" >> $propFile
echo "sil.downloadSilUrl="'${crystalsUrl}'"/crystals/downloadSil.do" >> $propFile
echo "sil.getCrystalUrl="'${crystalsUrl}'"/crystals/getCrystal.do" >> $propFile
echo "sil.clearCrystalUrl="'${crystalsUrl}'"/crystals/clearCrystal.do" >> $propFile
echo "sil.createDefaultSilUrl="'${crystalsUrl}'"/crystals/createDefaultSil.do" >> $propFile
echo "sil.deleteCassetteUrl="'${crystalsUrl}'"/crystals/deleteCassetteUrl.do" >> $propFile
echo "sil.addUserUrl="'${crystalsUrl}'"/crystals/addUserUrl.do" >> $propFile

echo " " >> $propFile
echo "# Crystal-analysis" >> $propFile
echo "ca.host=$tomcatHost" >> $propFile
echo "ca.port=$tomcatPort" >> $propFile
echo "analysisUrl=http://"'${ca.host}'":"'${ca.port}'"/crystals" >> $propFile
echo "sil.analyzeImageUrl="'${analysisUrl}'"/crystal-analysis/jsp/analyzeImage.jsp" >> $propFile
echo "sil.autoindexUrl="'${analysisUrl}'"/crystal-analysis/jsp/autoindex.jsp" >> $propFile

set spotfinderDir = ${rootDir}/spotfinder/linux
echo "Spotfinder dir [$spotfinderDir]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set spotfinderDir = $str
endif
echo "$spotfinderDir"

echo " " >> $propFile
echo "# Scripts and spotfinder directories" >> $propFile
echo "webice.rootDir="$tomcatRootDir"/webapps/webice" >> $propFile
echo "webice.binDir="$spotfinderDir >> $propFile
echo "webice.scriptDir="'${webice.rootDir}'"/WEB-INF/scripts" >> $propFile
echo "webice.dcsStrategyDir="'${webice.rootDir}'"/data/strategy" >> $propFile
echo "webice.beamlineDir="'${webice.rootDir}'"/data/beamline-properties" >> $propFile


echo " " >> $propFile
echo "# List of beamlines available to WebIce" >> $propFile
set beamlines = "BL1-5,BL7-1,BL9-1,BL9-2,BL11-1,BL11-3,SIM1-5,SIM7-1,SIM9-1,SIM9-2,SIM11-1,SIM11-3"
echo "Beamlines [$beamlines]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set beamlines = $str
endif
echo "$beamlines"

echo "webice.beamlines=$beamlines" >> $propFile

echo " " >> $propFile
echo "# DCS" >> $propFile
echo "# updateRate is in seconds" >> $propFile
echo "# updateRate: database dumpfile reloading interval in seconds" >> $propFile
echo "dcs.dumpDir="$webiceDir"/data/dcs" >> $propFile
echo "dcs.updateRate=10" >> $propFile
echo "dcs.dcssHost="$tomcatHost >> $propFile
echo "dcs.dcssPort=14342" >> $propFile
echo "dcs.analysisDhs=analysisdhs" >> $propFile

echo " " >> $propFile
echo "# Type of listing in Screening tab: dirList, silList, both" >> $propFile
echo "webice.silListMode=both" >> $propFile

echo " " >> $propFile
echo "# When to allow user to view strategy of the crystal" >> $propFile
echo "# in the Screening tab: mountedCrystalOnly, all" >> $propFile
echo "webice.importRunMode=all" >> $propFile

echo " " >> $propFile
echo "# How many levels of image dirs to include in a cassette" >> $propFile
echo "# in the Screening tab" >> $propFile
echo "webice.screeningDirDepth=1" >> $propFile

echo " " >> $propFile
echo "# Whether webice can collect images at the beamline" >> $propFile
echo "# If this param is absent, default to false." >> $propFile
echo "webice.canCollect=false" >> $propFile

echo " " >> $propFile
echo "# Webice user and session to connect to dcss" >> $propFile
echo "# to monitor beamline status." >> $propFile
echo "webice.user=webice" >> $propFile
echo "webice.passwdFile="'${webice.rootDir}'"/WEB-INF/webice.txt" >> $propFile

echo " " >> $propFile
echo "# Periodic table for flourecence scan" >> $propFile
echo "webice.periodicTableFile="'${webice.rootDir}'"/data/beamline-properties/periodic-table.dat" >> $propFile

echo " " >> $propFile
echo "# WebIce help page" >> $propFile
echo "help.host=smb.slac.stanford.edu" >> $propFile
echo "help.port=80" >> $propFile
echo "help.rootUrl=http://${help.host}:${help.port}/facilities/remote_access/webice" >> $propFile

