#!/bin/csh

setenv AUTH_URL "https://localhost:8443"

set curDir = `pwd`
cd ../..
set topDir = `pwd`
cd $curDir
set libDir = ${topDir}/WebRoot/WEB-INF/lib
setenv CLASSPATH ${libDir}/gatewayTest.jar:${libDir}/authUtility.jar

date
stty -echo
java -Djavax.net.ssl.trustStore=authcerts UpdateSessionThread
stty echo
date
