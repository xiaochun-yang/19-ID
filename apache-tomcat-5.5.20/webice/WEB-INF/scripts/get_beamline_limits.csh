#!/bin/csh -f

############################################################
#
# Get minimum exposure time from DCSS. If it does not 
# exist then get it from beamline.properties.
#
############################################################

set min_exposure = ""`awk '/min_exposure/{print $2;}' ../PARAMETERS/dcs_params.txt`
set min_exposure_b = ""`awk '/min_exposure/{print $2;}' ../PARAMETERS/beamline.properties`

if ("$min_exposure" == "") then
	set min_exposure = $min_exposure_b
#else
#	set min_exposure = `echo $min_exposure $min_exposure_b | awk '{if ($1 < $2) {print $2;} else {print $1;}}'`
endif
if ("$min_exposure" == "") then
set min_exposure = "unknown"
endif

set max_exposure = ""`awk '/max_exposure/{print $2;}' ../PARAMETERS/dcs_params.txt`
set max_exposure_b = ""`awk '/max_exposure/{print $2;}' ../PARAMETERS/beamline.properties`
if ("$max_exposure" == "") then
	set max_exposure = $max_exposure_b
#else
#	set max_exposure = `echo $max_exposure $max_exposure_b | awk '{if ($1 > $2) {print $2;} else {print $1;}}'`
endif
if ("$max_exposure" == "") then
set max_exposure = "unknown"
endif

set min_attenuation = ""`awk '/min_attenuation/{print $2;}' ../PARAMETERS/dcs_params.txt`
set min_attenuation_b = ""`awk '/min_attenuation/{print $2;}' ../PARAMETERS/beamline.properties`
if ("$min_attenuation" == "") then
	set min_attenuation = $min_attenuation_b
#else
#	set min_attenuation = `echo $min_attenuation $min_attenuation_b | awk '{if ($1 < $2) {print $2;} else {print $1;}}'`
endif
if ("$min_attenuation" == "") then
	set min_attenuation = "unknown"
endif

set max_attenuation = ""`awk '/max_attenuation/{print $2;}' ../PARAMETERS/dcs_params.txt`
set max_attenuation_b = ""`awk '/max_attenuation/{print $2;}' ../PARAMETERS/beamline.properties`
if ("$max_attenuation" == "") then
	set max_attenuation = $max_attenuation_b
#else
#	set max_attenuation = `echo $max_attenuation $max_attenuation_b | awk '{if ($1 > $2) {print $2;} else {print $1;}}'`
endif
if ("$max_attenuation" == "") then
set max_attenuation = "unknown"
endif

echo $min_exposure $max_exposure $min_attenuation $max_attenuation




