#!/bin/csh -f

cd ../..

set rootDir = `pwd`
set scriptDir = ${rootDir}/WEB-INF/scripts
set dataDir = ${rootDir}/data

echo "rootDir = $rootDir"

if ($#argv != 2) then
echo "Usage: addUser.csh <login name> <real name>"
exit
endif

set uname = $1
set rname = $2

source ${scriptDir}/setup_env.csh

java cts.CassetteCmd ${rootDir}/config.prop addUser $uname $rname



