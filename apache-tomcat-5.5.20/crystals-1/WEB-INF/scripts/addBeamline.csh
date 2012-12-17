#!/bin/csh -f

cd ../..

set rootDir = `pwd`
set scriptDir = ${rootDir}/WEB-INF/scripts
set dataDir = ${rootDir}/data

echo "rootDir = $rootDir"

if ($#argv != 1) then
echo "Usage: addBeamline.csh <beamline name>"
exit
endif

set bname = $1

source ${scriptDir}/setup_env.csh

java cts.CassetteCmd ${rootDir}/config.prop addBeamline $bname

mkdir -p ${dataDir}/beamlines/${bname}



