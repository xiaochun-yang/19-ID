#
#
#                        Copyright 2003
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
#
#                       Disclaimer Notice
#
#     The items furnished herewith were developed under the sponsorship
# of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
# Leland Stanford Junior University, nor their employees, makes any war-
# ranty, express or implied, or assumes any liability or responsibility
# for accuracy, completeness or usefulness of any information, apparatus,
# product or process disclosed, or represents that its use will not in-
# fringe privately-owned rights.  Mention of any product, its manufactur-
# er, or suppliers shall not, nor is it intended to, imply approval, dis-
# approval, or fitness for any particular use.  The U.S. and the Univer-
# sity at all times retain the right to use and disseminate the furnished
# items for any purpose whatsoever.                       Notice 91 02 01
#
#   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#
#
#                       Permission Notice
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
# BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  
# ************************************************************************
# calibrateInlineCamera_initialize
#
# This procedure is called once when DCSS starts.
# ************************************************************************

proc calibrateInlineCamera_initialize {} {}


# ************************************************************************
# calibrateInlineCamera_start
#
# This is the top-level procedure for executing the calibrateInlineCamera
# scripted operation.  It calls the calibrateInlineZoomLevel procedure twice,
# once at the minimum zoom of the camera (cameraZoom = 0), and again
# at the maximum zoom (cameraZoom = 1) of the camera.  Both calls to 
# calibrateInlineZoomLevel determine the pixel to mm conversion factor and the 
# position of the rotation axis in the image.  The two scale factors are 
# stored in the DCS devices zoomMinScale and zoomMaxScale.  The position 
# of the y-axis as determined at maximum zoom is stored in the DCS device 
# zoomMaxYAxis. The calls to calibrateInlineZoomLevel pass the current values
# of zoomMinScale and zoomMaxScale when calibrating at the minimum and
# maximum zoom levels, respectively, as initial guesses of these parameters. 
# ************************************************************************

proc calibrateInlineCamera_start {} {
    #######################
    if {[catch {
    #######################

    ## get image size and save them.
    set oldw [getInlineCameraConstant sampleImageWidth]
    set oldh [getInlineCameraConstant sampleImageHeight]
	set handle [start_waitable_operation getLoopTip 0]
	# wait for the loop tip operation to complete
	set result [wait_for_operation $handle 30000]
    set neww [lindex $result 3]
    set newh [lindex $result 4]
    if {$neww != $oldw || $newh != $oldh} {
        setInlineCameraConstant sampleImageWidth $neww
        setInlineCameraConstant sampleImageHeight $newh
        log_warning sample video image size changed \
        from $oldw X $oldh to $neww X $newh
    }


	# get the scale factor and y-axis position at the minimum zoom level
    set zoomMinScale [getInlineCameraConstant zoomMinScale]
    set zoomMaxScale [getInlineCameraConstant zoomMaxScale]

    log_warning calibrateInlineCamera calibrateInlineZoomLevel 0.0
	calibrateInlineZoomLevel 0.0 $zoomMinScale yAxis scaleFactor 

	# store the scale factor for minimum zoom (but not the y-axis position)
    log_warning calibrateInlineCamera save the new zoomMinScale $scaleFactor
    setInlineCameraConstant zoomMinScale $scaleFactor
 
	# get the scale factor and y-axis position at the maximum zoom level
    log_warning calibrateInlineCamera calibrateInlineZoomLevel 1.0
	calibrateInlineZoomLevel 1.0 $zoomMaxScale  yAxis scaleFactor

	# store the scale factor and the y-axis for maximum zoom 
    log_warning calibrateInlineCamera save the new zoomMaxScale $scaleFactor
    log_warning calibrateInlineCamera save the new zoomMaxYAxis $yAxis
    setInlineCameraConstant zoomMaxYAxis $yAxis
    setInlineCameraConstant zoomMaxScale $scaleFactor

    log_warning calibrateInlineCamera SUCCESS
    #######################
    } errMsg]} {
        log_error calibrateInlineCamera Failed: $errMsg
        return -code error $errMsg
    }
    #######################
}


# ************************************************************************
# calibrateInlineZoomLevel
#
# This procedure determines the scale factor and rotation axis
# of the sample camera at the specified zoom level.  It calls the procdure
# determinInlineScaleFactor twice, and determineInlineRotationAxis three times in
# the process.  This procedure must be passed an initial scale factor
# which should be within a factor of 2 of the correct value.
# ************************************************************************

proc calibrateInlineZoomLevel { zoomLevel scaleFactor0 yAxisRef scaleFactorRef } {

	# assign local aliases to reference variables
	upvar $yAxisRef yAxis
	upvar $scaleFactorRef scaleFactor

	# move to the specified camera zoom
    log_warning calibrateInlineCamera move zoom
	move inline_camera_zoom to $zoomLevel
	wait_for_devices inline_camera_zoom	

	# calculate the scale factor for first time
	determinInlineScaleFactor $scaleFactor0 scaleFactor1 tipX1 tipY1 

	# move pin tip to a 0.5, 0.25 using the new scale factor
    log_warning calibrateInlineCamera move tip to center
	inlineMoveSampleRelative \
		[expr 0.5 - $tipX1] [expr 0.25 - $tipY1] 0 $scaleFactor1

	# determine the rotation axis the first time
	determineInlineRotationAxis rotationAxis1 tipX2 tipY2

	# Move pin tip 0.2 in the horizontal 
	# and to the rotation axis in the vertical 
    log_warning calibrateInlineCamera move tip to left
	inlineMoveSampleRelative [expr 0.2 - $tipX2] [expr $rotationAxis1 - $tipY2 ] \
		0 $scaleFactor1

	# calculate the scale factor the second time
	determinInlineScaleFactor $scaleFactor1 scaleFactor2 tipX3 tipY3

	# move tip to the 0.5 in the horizontal
    log_warning calibrateInlineCamera move tip back to center
	inlineMoveSampleRelative [expr 0.5 - $tipX3] 0 0 $scaleFactor2

	# determine the rotation axis the second time
	determineInlineRotationAxis rotationAxis2 tipX4 tipY4

	# move the pin to the rotation axis in the vertical
    log_warning calibrateInlineCamera move tip to vertical axis center
	inlineMoveSampleRelative 0 [expr $rotationAxis2 - $tipY4] 0 $scaleFactor2

	#  rotate phi by 90 degrees
    log_warning calibrateInlineCamera rotate phi 90 to find rotation axis
	move gonio_phi by 90
	wait_for_devices gonio_phi

	# determine the rotation axis the third time
	determineInlineRotationAxis rotationAxis3 tipX5 tipY5

	# calculate the average of the last two rotation axis values
	set averageRotationAxis [expr ($rotationAxis2 + $rotationAxis3) / 2.0]

	# move the pin to the average rotation axis in the vertical
    log_warning calibrateInlineCamera move pin to rotation center
	inlineMoveSampleRelative \
		0 [expr $averageRotationAxis - $tipY5] 0 $scaleFactor2

	# store the scale factor and y-axis position in the reference variables
	set scaleFactor $scaleFactor2
	set yAxis $averageRotationAxis
}


# ************************************************************************
# determinInlineScaleFactor
#
# This procedure determines the conversion factor between sample camera
# pixels and microns.  It finds the tip of the calibration pin,
# moves the pin along the horizontal by moving sample_z a known
# amount, and then finds the tip of the pin again.  The new scale factor
# is calculated from the distance the pin tip moved in the view.  A
# rough value for the scale factor must be passed to the function as
# the first argument.  The calculation should succeed as long as the
# scale factor passed is within a factor of two of the correct value.
# The new scale factor is returned by reference along with the final 
# position of the pin tip.
# ************************************************************************

proc determinInlineScaleFactor { oldScaleFactor newScaleFactorRef pinXRef pinYRef } {
    set sampleImageWidth [getInlineCameraConstant sampleImageWidth]

	# assign local aliases to reference variables
	upvar $newScaleFactorRef scaleFactor
	upvar $pinXRef pinX
	upvar $pinYRef pinY

	# get current position of tip
	determineInlinePinTipPosition tipX1 tipY1

	# FROM TIP POSITION DETERMINE OPTIMAL TARGET POSITION FOR PIN TIP
	# IN ORDER TO DETERMINE SCALE FACTOR.  I.E., MOVE NEGATIVE IN Z
	# IF tipX1 > 0.5.  BETTER, MOVE THIS DECISION TO CALLING FUNCTION
	# AND PASS TARGET SAMPLE_Z VALUE.

	# calculate how far to move sample_z motor to move the pin tip to a 
	# position of 0.7.  (Note that if the oldScaleFactor is 50% the correct
	# value, the pin tip will move to a position of 0.6.  If it is twice 
	# the correct value, the tip will move to 0.9.  Over this entire range 
	# of error the function should work properly.)
	set deltaZ [expr (0.7 - $tipX1) * $oldScaleFactor \
		* double($sampleImageWidth) / 1000.0]
		
	# move pin to 0.7 in the horizontal
	move sample_z by $deltaZ
	wait_for_devices sample_z
	
	# get the new position of the pin tip
	determineInlinePinTipPosition tipX2 tipY2

	# make sure the tip actually moved
	if { abs($tipX2 - $tipX1) < 0.01 } {
		return -code error "Pin tip did not move enough."
	}

	# calculate the scale factor
	set newScaleFactor [expr 1000.0 * $deltaZ/(($tipX2 - $tipX1) \
		* double($sampleImageWidth))]

	# store scale factor and final tip position in reference variables
	set scaleFactor $newScaleFactor
	set pinX $tipX2
	set pinY $tipY2
}
proc determineInlineRotationAxis { axisRef pinXRef pinYRef } {

	# assign local aliases to reference variables
	upvar $axisRef axis
	upvar $pinXRef pinX
	upvar $pinYRef pinY

	# get current position of pin tip
	determineInlinePinTipPosition tipX1 tipY1

	# rotate pin by 180 degrees 
	move gonio_phi by 180
	wait_for_devices gonio_phi

	# get the new position of the tip
	determineInlinePinTipPosition tipX2 tipY2

	# store y-axis and final tip position in reference variables
	set axis [expr ($tipY1 + $tipY2) / 2.0]
	set pinX $tipX2
	set pinY $tipY2
}
proc determineInlinePinTipPosition { pinXRef pinYRef } {

	# assign local aliases to reference variables
	upvar $pinXRef pinX
	upvar $pinYRef pinY

	# start getting the loop tip position
	set handle [start_waitable_operation getInlineLoopTip 0]

	# wait for the loop tip operation to complete
	set result [wait_for_operation $handle 30000]

	# parse pin tip coordinates from result and store in reference variables
	set pinX [lindex $result 1]
	set pinY [lindex $result 2]
}
