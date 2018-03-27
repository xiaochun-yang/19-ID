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

proc inlineMoveSample_initialize {} {
    variable cfgSampleCameraConstantNameList

    set cfgSampleCameraConstantNameList \
    [::config getStr sampleCameraConstantsNameList]
}

proc getInlineCameraConstant { name } {
    variable inline_sample_camera_constant

    set index [sampleCameraConstantNameToIndex $name]
    return [lindex $inline_sample_camera_constant $index]
}
proc setInlineCameraConstant { name value } {
    variable inline_sample_camera_constant

    set index [sampleCameraConstantNameToIndex $name]
    set inline_sample_camera_constant \
    [lreplace $inline_sample_camera_constant $index $index $value]
}


proc inlineMoveSample_start { args } {

	eval inlineMoveSampleRelative $args
}


proc getInlineCameraScaleFactor { horizontalScaleRef verticalScaleRef {scaleFactor NULL} } {
	variable inline_camera_zoom

    set sampleAspectRatio [getInlineCameraConstant sampleAspectRatio]
    set zoomMinScale      [getInlineCameraConstant zoomMinScale]
    set zoomMaxScale      [getInlineCameraConstant zoomMaxScale]

	# assign local aliases to reference variables
	upvar $horizontalScaleRef horizontalScale
	upvar $verticalScaleRef verticalScale

	# calculate micron/pixel scale factor at current zoom level if not specified
	if { $scaleFactor == "NULL" } {
		set horizontalScale \
			[expr $zoomMinScale * exp ( log($zoomMaxScale/$zoomMinScale) * $inline_camera_zoom) ]
	} else {
		set horizontalScale $scaleFactor
	}

	# calculate vertical scale factor taking pixel aspect ratio into account
	set verticalScale \
		[expr $horizontalScale * $sampleAspectRatio] 

}

proc inlineMoveSample_getDXDYDZFromRelative { deltaImageXFraction deltaImageYFraction phiOffset scaleFactor } {
    foreach {deltaXmm deltaYmm} [inlineMoveSampleRelativeToMM \
	$deltaImageXFraction $deltaImageYFraction $scaleFactor] break

    return [inlineMoveSample_getDXDYDZFromMM $deltaXmm $deltaYmm]
}

proc inlineMoveSampleRelative { deltaImageXFraction deltaImageYFraction {phiOffset 0.0} {scaleFactor NULL} } {
    foreach {deltaXmm deltaYmm} [inlineMoveSampleRelativeToMM \
	$deltaImageXFraction $deltaImageYFraction $scaleFactor] break

    inlineMoveSampleRelativeMM $deltaXmm $deltaYmm $phiOffset
}
proc inlineMoveSample_getDXDYDZFromMM { dHmm dVmm phiOffset } {
	variable gonio_phi
	variable gonio_omega

	set phiDeg [expr $gonio_phi + $gonio_omega + $phiOffset + 90]
    set phi [expr $phiDeg / 180.0 * 3.14159]

	set deltaSampleXmm [expr  sin($phi) * $dVmm ]
	set deltaSampleYmm [expr -cos($phi) * $dVmm ]
	set deltaSampleZmm $dHmm

    return [list $deltaSampleXmm $deltaSampleYmm $deltaSampleZmm]
}

proc inlineMoveSampleRelativeToMM { dx dy  {scaleFactor NULL} } {
    set sampleImageHeight [getInlineCameraConstant sampleImageHeight]
    set sampleImageWidth  [getInlineCameraConstant sampleImageWidth]
	
	# calculate um-pixel scale factors
	getInlineCameraScaleFactor umPerPixelHorizontal umPerPixelVertical \
    $scaleFactor

	set dXmm [expr $sampleImageWidth  * $dx * $umPerPixelHorizontal / -1000.0 ] 
    set dYmm [expr $sampleImageHeight * $dy * $umPerPixelVertical / 1000.0 ]

    return [list $dXmm $dYmm]
}
proc inlineMoveSampleRelativeMM { deltaXmm deltaYmm {phiOffset 0.0} } {
    variable sample_x
    variable sample_y
    variable sample_z
    variable ::moveSampleUndo::orig_x
    variable ::moveSampleUndo::orig_y
    variable ::moveSampleUndo::orig_z

    set orig_x $sample_x
    set orig_y $sample_y
    set orig_z $sample_z
    puts "inlineMoveSample saved $sample_x $sample_y $sample_z"

    foreach {dx dy dz} [inlineMoveSample_getDXDYDZFromMM \
    $deltaXmm $deltaYmm $phiOffset] break

    variable cfgSampleMoveSerial
    if {$cfgSampleMoveSerial} {
        move sample_x by -$dx
        wait_for_devices sample_x
        move sample_y by -$dy
        wait_for_devices sample_y
        move sample_z by -$dz
        wait_for_devices sample_z
    } else {
        move sample_x by -$dx
        move sample_y by -$dy
        move sample_z by -$dz
	
        # wait for all device motions to complete
        wait_for_devices sample_x sample_y sample_z
    }
}
proc inlineMoveSample_mmToRelative { dxMM dyMM {scaleFactor NULL}} {
    set sampleImageHeight [getInlineCameraConstant sampleImageHeight]
    set sampleImageWidth  [getInlineCameraConstant sampleImageWidth]
	
	# calculate um-pixel scale factors
	getInlineCameraScaleFactor umPerPixelHorizontal umPerPixelVertical \
    $scaleFactor

    set dx [expr $dxMM * 1000.0 / ($sampleImageWidth * $umPerPixelHorizontal)]
    set dy [expr $dyMM * 1000.0 / ($sampleImageHeight * $umPerPixelVertical)]

    return [list $dx $dy]
}
proc inlineScaleFactor_calculate { zoom } {
    set zoomMinScale      [getInlineCameraConstant zoomMinScale]
    set zoomMaxScale      [getInlineCameraConstant zoomMaxScale]
    return [expr $zoomMinScale * exp(log($zoomMaxScale/$zoomMinScale) * $zoom)]
}
proc inlineScaleFactor_calculate_zoom { hScale } {
    set zoomMinScale      [getInlineCameraConstant zoomMinScale]
    set zoomMaxScale      [getInlineCameraConstant zoomMaxScale]

    return [expr log($hScale/$zoomMinScale) / log($zoomMaxScale/$zoomMinScale)]
}
proc inlineView_calculate_zoom { width {height 0}} {
    set sampleImageWidth  [getInlineCameraConstant sampleImageWidth]
    set hScale [expr $width * 1000.0 / $sampleImageWidth]
    if {$height > 0} {
        set sampleImageHeight  [getInlineCameraConstant sampleImageHeight]
        set sampleAspectRatio  [getInlineCameraConstant sampleAspectRatio]

        set vScale [expr $height * 1000.0 / $sampleImageHeight]
        set hScaleFromV [expr $vScale / $sampleAspectRatio]

        if {$hScale < $hScaleFromV} {
            set hScale $hScaleFromV
        }
    }

    return [inlineScaleFactor_calculate_zoom $hScale]
}
proc getInlineViewSize { hSizeRef vSizeRef {scaleFactor NULL} } {
	variable inline_camera_zoom

    set sampleImageHeight [getInlineCameraConstant sampleImageHeight]
    set sampleImageWidth  [getInlineCameraConstant sampleImageWidth]
    set sampleAspectRatio [getInlineCameraConstant sampleAspectRatio]

	# assign local aliases to reference variables
	upvar $hSizeRef width
	upvar $vSizeRef height

	# calculate micron/pixel scale factor at current zoom level if not specified
	if { $scaleFactor == "NULL" } {
		set horizontalScale [inlineScaleFactor_calculate $inline_camera_zoom]
	} else {
		set horizontalScale $scaleFactor
	}

	# calculate vertical scale factor taking pixel aspect ratio into account
	set verticalScale \
		[expr $horizontalScale * $sampleAspectRatio] 

    ### to mm from um
    set width  [expr $sampleImageWidth  * $horizontalScale / 1000.0]
    set height [expr $sampleImageHeight * $verticalScale   / 1000.0]
    
}
