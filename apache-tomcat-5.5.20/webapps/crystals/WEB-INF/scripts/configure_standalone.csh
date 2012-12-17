#!/bin/csh -f

# Script to setup webice configuration file

echo "Welcome to CRYSTALS configuration tool"
echo "..."
echo "..."

# property file
set propFile = "config.prop"


set tomcatRootDir = $CATALINA_HOME

set curDir = `pwd`
cd ../..
set crystalsDir = `pwd`
cd ../../..
set rootDir = `pwd`
cd $crystalsDir

# Tomcat
set tomcatHost = $HOST
set tomcatPort = "8080"
set tomcatSecPort = "8443"

# auth
set authHost = $HOST
set authPort = $tomcatPort
set authSecPort = $tomcatSecPort
set authMethod = "simple_user_database"

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

echo "Authentication Secured Port [$authSecPort]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set authSecPort = $str
endif
echo "$authSecPort"

echo "Authentication method (e.g. simple_user_database or smb_config_database) [$authMethod]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set authMethod = $str
endif
echo "$authMethod"


set convHost = $HOST
set convPort = $tomcatPort
set convMethod = "jexcel"

# Conversion method is jexcel or asp
echo "Excel2xml Method (jexcel | asp) [$convMethod]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set convMethod = $str
endif
echo "$convMethod"

if ($convMethod == "asp") then

echo "Excel2xml Host [$convHost]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set convHost = $str
endif
echo "$convHost"

echo "Excel2xml Port [$convPort]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set convPort = $str
endif
echo "$convPort"

else # conversion method is not asp

set convHost = ""
set convPort = ""

endif

set pageHeader = "ssrlheader.jsp"
echo "Page Header File (must exist or be created) [$pageHeader]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set pageHeader = $str
endif
echo "$pageHeader"

set loginHeader = "smb_menu.html"
echo "Header for login page [$loginHeader]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set loginHeader = $str
endif
echo "$loginHeader"

set loginFooter = "smbFooter.jspf"
echo "Footer for login page [$loginFooter]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set loginFooter = $str
endif
echo "$loginFooter"

set loginStylesheet = "https://smb.slac.stanford.edu/smb_mainstyle.css"
echo "Stylesheet for login page [$loginStylesheet]:"
set str = $<
set len = `echo $str | awk '{print length($0);}'`
if ($len > 0) then
	set loginStylesheet = $str
endif
echo "$loginStylesheet"


echo "host = $HOST"
echo "crystals dir = $crystalsDir"
echo "root dir = $rootDir"
echo "tomcat dir = $tomcatRootDir"

echo "# The following config customizes the web pages" > $propFile
echo " "
echo "# Page containing logo and title" >> $propFile
echo "pageheader=$pageHeader" >> $propFile

echo "# Header, footer and stylesheet for the login form" >> $propFile
echo "loginForm.header=$loginHeader" >> $propFile
echo "loginForm.footer=$loginFooter" >> $propFile
echo "loginForm.stylesheet=$loginStylesheet" >> $propFile

echo " " >> $propFile
echo "# Server secured port" >> $propFile
echo "securedPort=$tomcatSecPort" >> $propFile

echo " " >> $propFile
echo "# Crystals server root dir" >> $propFile
echo "rootDir=$crystalsDir" >> $propFile

echo " " >> $propFile
echo "# Template dir" >> $propFile
echo "templateDir=$crystalsDir/data/templates/" >> $propFile

echo " " >> $propFile
echo "# Cassette dir" >> $propFile
echo "cassetteDir=$crystalsDir/data/cassettes/" >> $propFile

echo " " >> $propFile
echo "# Beamline dir" >> $propFile
echo "beamlineDir=$crystalsDir/data/beamlines/" >> $propFile

echo " " >> $propFile
echo "# URL path for crystals server" >> $propFile
if ($tomcatSecPort == "443") then
echo "crystalsURL=https://${tomcatHost}/crystals" >> $propFile
else
echo "crystalsURL=https://${tomcatHost}:${tomcatSecPort}/crystals" >> $propFile
endif

echo " " >> $propFile
echo "# Default URL for loading cassette files" >> $propFile
if ($tomcatSecPort == "443") then
echo "getCassetteURL=https://${tomcatHost}/crystals/data/cassettes/" >> $propFile
else
echo "getCassetteURL=https://${tomcatHost}:${tomcatSecPort}/crystals/data/cassettes/" >> $propFile
endif

echo " " >> $propFile
echo "# Default page for crystals server" >> $propFile
if ($tomcatSecPort == "443") then
echo "cassetteInfoURL=https://${tomcatHost}/crystals/CassetteInfo.jsp" >> $propFile
else
echo "cassetteInfoURL=https://${tomcatHost}:${tomcatSecPort}/crystals/CassetteInfo.jsp" >> $propFile
endif

echo " " >> $propFile
echo "# URL for excel to xml converter" >> $propFile
echo "excel2xmlMethod=$convMethod"
if ($convMethod == "asp") then
if ($convPort == "80") then
echo "excel2xmlURL=http://${convHost}/excel2xml/excel2xml.asp" >> $propFile
else
echo "excel2xmlURL=http://${convHost}:${convPort}/excel2xml/excel2xml.asp" >> $propFile
endif
endif # convMethod == asp

echo " " >> $propFile
echo "# Database type: oracle or xml" >> $propFile
echo "dbType=xml" >> $propFile
echo "dbFile=db.txt" >> $propFile

touch db.txt

echo " " >> $propFile
echo "# Authentication" >> $propFile
echo "auth.host=$authHost" >> $propFile
echo "auth.port=$authPort" >> $propFile
echo "auth.method=$authMethod" >> $propFile
if ($authPort == "80") then
echo "auth.gatewayUrl=http://${authHost}/gateway/servlet/" >> $propFile
else
echo "auth.gatewayUrl=http://${authHost}:${authPort}/gateway/servlet/" >> $propFile
endif
if ($authSecPort == "80") then
echo "auth.loginUrl=https://${tomcatHost}/crystals/login.jsp" >> $propFile
else
echo "auth.loginUrl=https://${tomcatHost}:${tomcatSecPort}/crystals/login.jsp" >> $propFile
endif

# Touch all jsp files that use config.prop
touch *.jsp

