#!/bin/csh

echo -n "Username1: "
set userName1 = $<
echo -n "Password1: "
stty -echo
set password1 = $<
stty echo

echo " "
echo -n "Username2: "
set userName2 = $<
echo -n "Password2: "
stty -echo
set password2 = $<
stty echo
echo " "

set curDir = `pwd`
cd ../..
set topDir = `pwd`
cd $curDir
set libDir = ${topDir}/WebRoot/WEB-INF/lib
set pamLibPath = ${libDir}/libjpam.so
setenv CLASSPATH ${libDir}/gatewayTest.jar:${libDir}/JPam.jar:${libDir}/commons-logging.jar:${libDir}/log4j-1.2.13.jar:.

echo "pamLibPath = $pamLibPath"

java PamThreadSafetyTest $pamLibPath $userName1 $password1 $userName2 $password2
