#!/bin/csh

echo -n "Username: "
set userName = $<
echo -n "Password: "
stty -echo
set password = $<
stty echo

set curDir = `pwd`
cd ../..
set topDir = `pwd`
cd $curDir
set libDir = ${topDir}/WebRoot/WEB-INF/lib
set pamLibPath = ${libDir}/libjpam.so
setenv myClassPath ${libDir}/gatewayTest.jar:${libDir}/JPam.jar:${libDir}/commons-logging.jar:${libDir}/log4j-1.2.13.jar:.

echo "pamLibPath = $pamLibPath"

java -Djava.class.path="$myClassPath" PamBasicTest "$pamLibPath" "$userName" "$password"
