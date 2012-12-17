#!/bin/csh -f

############################################################
#
# Script to run webice autoindex & strategy from a 
# commandline.
#
# Usage:
#	manual_autoindex.csh
#
############################################################

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`
setenv WEBICE_ROOT_DIR "${WEBICE_SCRIPT_DIR}/../.."

if (! -e $WEBICE_SCRIPT_DIR/${HOST}.csh) then
echo " "
echo "==================================================================="
echo "Please define environment variables for crystallography software"
echo "in $WEBICE_SCRIPT_DIR/${HOST}.csh."
echo "See an example in $WEBICE_SCRIPT_DIR/smblx20.slac.stanford.edu.csh."
echo "==================================================================="
echo " "
exit
endif

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh


set runName = "manual1"
set imageDir = "/data/penjitk/dataset/lyso"
set image1 = "test_1_001.mccd"
set image2 = "test_1_045.mccd"
set expType = "Native"
set laueGroup = ""
set beamCenterX = "162.5"
set beamCenterY = "162.5"
set distance = "300.0"
set wavelength = "0.98"
set detector = "MARCCD325"
set detectorWidth = "325.0"
# MAR345 module name, e.g. 1200, 1600, 3450
set detectorFormat = ""


set beamline = "default"
set beamlineFile = "${WEBICE_ROOT_DIR}/data/beamline-properties/default.properties"
set dcsDumpFile = "${WEBICE_ROOT_DIR}/data/dcs/default.dump"

echo "beamX $beamCenterX" > image_params.tmp
echo "beamY $beamCenterY" >> image_params.tmp
echo "distance $distance" >> image_params.tmp
echo "wavelength $wavelength" >> image_params.tmp
echo "detector $detector" >> image_params.tmp
echo "detectorFormat $detectorFormat" >> image_params.tmp

set detectorResolution = `awk -f $WEBICE_SCRIPT_DIR/get_detector_resolution.awk image_params.tmp`

rm -rf image_params.tmp


echo '<input>' > input.xml
echo '  <version>2.0</version>' >> input.xml
echo '  <task name="run_autoindex.csh">' >> input.xml
echo '    <runName>'$runName'</runName>' >> input.xml
echo '    <imageDir>'${imageDir}'</imageDir>' >> input.xml
echo '    <host>'$HOST'</host>' >> input.xml
echo '    <port>61001</port>' >> input.xml
echo '    <image>'${image1}'</image>' >> input.xml
echo '    <image>'${image2}'</image>' >> input.xml
echo '    <integrate>best</integrate>' >> input.xml
echo '    <generate_strategy>true</generate_strategy>' >> input.xml
echo '    <beamCenterX>'$beamCenterX'</beamCenterX>' >> input.xml
echo '    <beamCenterY>'$beamCenterY'</beamCenterY>' >> input.xml
echo '    <distance>'$distance'</distance>' >> input.xml
echo '    <wavelength>'$wavelength'</wavelength>' >> input.xml
echo '    <detector>'$detector'</detector>' >> input.xml
echo '    <detectorFormat>'$detectorFormat'</detectorFormat>' >> input.xml
echo '    <detectorWidth>'$detectorWidth'</detectorWidth>' >> input.xml
echo '    <detectorResolution>'$detectorResolution'</detectorResolution>' >> input.xml
echo '    <exposureTime>1.0</exposureTime>' >> input.xml
echo '    <oscRange>1.0</oscRange>' >> input.xml
echo '    <beamline>'$beamline'</beamline>' >> input.xml
echo '    <beamlineFile>'$beamlineFile'</beamlineFile>' >> input.xml
echo '    <dcsDumpFile>'$dcsDumpFile'</dcsDumpFile>' >> input.xml
echo '    <expType>'$expType'</expType>' >> input.xml
echo '    <mad edge="" inflection="0.0" peak="0.0" remote="0.0"/>' >> input.xml
echo '    <laueGroup>'$laueGroup'</laueGroup>' >> input.xml
echo '    <unitCell a="0.0" b="0.0" c="0.0" alpha="0.0" beta="0.0" gamma="0.0"/>' >> input.xml
echo '  </task>' >> input.xml
echo '</input>' >> input.xml

$WEBICE_SCRIPT_DIR/run_autoindex.csh



