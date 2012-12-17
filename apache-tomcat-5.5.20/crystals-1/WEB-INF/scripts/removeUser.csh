#!/bin/csh -f

cd ../..

set rootDir = `pwd`
set scriptDir = ${rootDir}/WEB-INF/scripts
set dataDir = ${rootDir}/data

echo "rootDir = $rootDir"

set uid = $1

source ${scriptDir}/setup_env.csh

java cts.CassetteCmd ${rootDir}/config.prop removeUser $uid



