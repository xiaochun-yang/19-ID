#!/bin/csh -f

cd ../..

set rootDir = `pwd`
set scriptDir = ${rootDir}/WEB-INF/scripts
set dataDir = ${rootDir}/data

echo "rootDir = $rootDir"

set bname = $1

source ${scriptDir}/setup_env.csh

java cts.CassetteCmd ${rootDir}/config.prop removeBeamline $bname



