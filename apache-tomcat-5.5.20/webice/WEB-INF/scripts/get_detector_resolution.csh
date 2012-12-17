#!/bin/csh -f

############################################################
#
# Calculate maximum resolution for the inscribe circle 
# of the given detector. Detector radius for different 
# detectors are:
#
# Q4 CCD: 94 
# Q315 CCD: 157.5
# MAR345 1200 and 1800 : 90 
# MAR345 1600 and 2400 : 120 
# MAR345 2000 and 3000 : 150 
# MAR345 2300 and 3450 : 172.5
#
# Resolution is calculated by 
# tan(2T) = R/D
# sin(T) = Lamda/2d
# where
#	T is theta in degree
#	R is detector radius (width/2) in mm
#	D is detector distance to detector in mm
#	d is resolution in Angstrom
#
# d = Lamda / (2 * sin(T))
# T = atan(R/D)/2
# d = Lamda / (2 * sin( atan(R/D) / 2 ) )
#
# The script calculates 3 resolutions for 
# 3 different radius:
# - Rx = radius + abs(beam_offsetX)
# - Ry = radius + abs(beam_offsetY)
# - Rmax = sqrt(Rx^2 + Ry^2)
# 
# Rx gives maximum resolution that includes spots furthest away 
#    from beam center on the x axis of the detector.
# Ry gives maximum resolution that includes spots furthest away 
#    from beam center on the y axis of the detector.
# Rmax gives maximum resolution that includes spots at 
#    the furthest corner of the detector from the beam center.
#
# Usage:
#	get_detector_resolution.csh <D> <Lamda> <centerX> <centerY> <detector type> <serial number>
#
# Returns
# max(resX, resY)
#
#
############################################################


# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

source $WEBICE_SCRIPT_DIR/setup_env.csh

set resolution = `awk -f $WEBICE_SCRIPT_DIR/get_detector_resolution.awk image_params.txt`

echo $resolution
