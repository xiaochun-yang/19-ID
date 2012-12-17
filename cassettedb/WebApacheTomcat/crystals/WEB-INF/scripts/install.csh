#!/bin/csh -f

cd ../..

set rootDir = `pwd`
set dataDir = ${rootDir}/data

echo "rootDir = $rootDir"

set cc = (-e ${dataDir}/cassettes)
set bb = (-e ${dataDir}/beamlines)
if ($cc || $bb) then
if ($cc && $bb) then
echo "Found cassettes and beamlines directories"
else
if ($cc && !$bb) then
echo "Found cassettes directory"
else
if (!$cc && $bb) then
echo "Found beamlines directory"
endif
endif
endif
echo "Delete directories (yes|no)? [no]"
set proceed = $<
if ($proceed != "yes") then
echo "Installation exited"
exit
endif
rm -rf ${dataDir}/cassettes
rm -rf ${dataDir}/beamlines
rm -rf ${dataDir}/params.xml
echo "Deleted ${dataDir}/cassettes"
echo "Deleted ${dataDir}/beamlines"
echo "Deleted ${dataDir}/params.xml"
endif

mkdir ${dataDir}/cassettes
mkdir ${dataDir}/beamlines

cp ${rootDir}/WEB-INF/scripts/beamlines.xml ${dataDir}/beamlines/beamlines.xml
echo "Created ${dataDir}/beamlines/beamlines.xml"

cp ${rootDir}/WEB-INF/scripts/users.xml ${dataDir}/cassettes/users.xml
echo "Created ${dataDir}/cassettes/users.xml"

cp ${rootDir}/WEB-INF/scripts/params.xml ${dataDir}/params.xml
echo "Created ${dataDir}/params.xml"

cp ${rootDir}/WEB-INF/scripts/cassette_lookup.prop ${dataDir}/cassette_lookup.prop
echo "Created ${dataDir}/cassette_lookup.prop"

