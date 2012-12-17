#!/bin/csh


set curDir = `pwd`
cd ../..
set topDir = `pwd`
cd $curDir
set libDir = ${topDir}/WebRoot/WEB-INF/lib
setenv CLASSPATH ${libDir}/authUtility.jar

date
stty -echo
java edu.stanford.slac.ssrl.authentication.utility.ExportPrivateKey $argv
stty echo
date

# ExportPrivateKey writes private key in PKCS#8 format.
# To convert PKCS#8 format into RSA format, use openssl

#openssl pkcs8 -inform PEM -nocrypt -in server.pkcs8 -out server.rsa

