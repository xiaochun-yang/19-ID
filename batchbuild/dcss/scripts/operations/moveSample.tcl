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

proc moveSample_initialize {} {
    variable cfgSampleCameraConstantNameList
    variable cfgSampleMoveSerial

    set cfgSampleCameraConstantNameList \
    [::config getStr sampleCameraConstantsNameList]

    set cfgSampleMoveSerial [::config getInt sample_move_serial 0]

    namespace eval ::moveSampleUndo {
        set orig_x 0
        set orig_y 0
        set orig_z 0
    }
}

proc sampleCameraConstantNameToIndex { name } {
    variable cfgSampleCameraConstantNameList
    variable sample_camera_constant

    if {![info exists sample_camera_constant]} {
        mergeSampleCameraParameters
        return -code error "string not exists: sample_camera_constant"
    }

    set index [lsearch -exact $cfgSampleCameraConstantNameList $name]
    if {$index < 0} {
        return -code error "bad name: {$name} for field of sample_camera_constant"
    }
    if {[llength $sample_camera_constant] <= $index} {
        return -code error "bad contents of string sample_camera_constant"
    }
    return $index
}
proc getSampleCameraConstant { name } {
    variable sample_camera_constant

    set index [sampleCameraConstantNameToIndex $name]
    return [lindex $sample_camera_constant $index]
}
proc setSampleCameraConstant { name value } {
    variable sample_camera_constant

    set index [sampleCameraConstantNameToIndex $name]
    set sample_camera_constant \
    [lreplace $sample_camera_constant $index $index $value]
}

proc moveSample_start { args } {
    if {$args == "undo"} {
        moveSample_undo
        return "undo OK"
    }

	eval moveSampleRelative $args
}

### to share with motor sampleScaleFactor
proc sampleScaleFactor_calculate { zoom } {
    set zoomMinScale      [getSampleCameraConstant zoomMinScale]
    set zoomMaxScale      [getSampleCameraConstant zoomMaxScale]

    return [expr $zoomMinScale * exp(log($zoomMaxScale/$zoomMinScale) * $zoom)]
}

proc sampleScaleFactor_calculate_zoom { hScale } {
    set zoomMinScale      [getSampleCameraConstant zoomMinScale]
    set zoomMaxScale      [getSampleCameraConstant zoomMaxScale]

    return [expr log($hScale/$zoomMinScale) / log($zoomMaxScale/$zoomMinScale)]
}
proc getSampleScaleFactor { horizontalScaleRef verticalScaleRef {scaleFactor NULL} } {
	variable camera_zoom

    set sampleAspectRatio [getSampleCameraConstant sampleAspectRatio]

	# assign local aliases to reference variables
	upvar $horizontalScaleRef horizontalScale
	upvar $verticalScaleRef verticalScale

	# calculate micron/pixel scale factor at current zoom level if not specified
	if { $scaleFactor == "NULL" } {
		set horizontalScale [sampleScaleFactor_calculate $camera_zoom]
	} else {
		set horizontalScale $scaleFactor
	}

	# calculate vertical scale factor taking pixel aspect ratio into account
	set verticalScale \
		[expr $horizontalScale * $sampleAspectRatio] 
}
proc moveSample_relativeToMM { dx dy {scaleFactor NULL}} {
    set sampleImageHeight [getSampleCameraConstant sampleImageHeight]
    set sampleImageWidth  [getSampleCameraConstant sampleImageWidth]
	
	# calculate um-pixel scale factors
	getSampleScaleFactor umPerPixelHorizontal umPerPixelVertical $scaleFactor

	set dxMM [expr $sampleImageWidth  * $dx * $umPerPixelHorizontal / 1000.0 ] 
    set dyMM [expr $sampleImageHeight * $dy * $umPerPixelVertical   / 1000.0 ]

    return [list $dxMM $dyMM]
}
proc moveSample_getDXDYDZFromMM { deltaImageXmm deltaImageYmm {phiOffset 0} } {
	variable gonio_phi
	variable gonio_omega

	set phiDeg [expr $gonio_phi + $gonio_omega + $phiOffset]
    set phi [expr $phiDeg / 180.0 * 3.14159]

	set deltaSampleXmm [expr sin($phi) * $deltaImageYmm ]
	set deltaSampleYmm [expr -cos($phi) * $deltaImageYmm ]
	set deltaSampleZmm $deltaImageXmm

    return [list $deltaSampleXmm $deltaSampleYmm $deltaSampleZmm]
}
proc moveSample_getDXDYDZFromRelative { deltaImageXFraction deltaImageYFraction {phiOffset 0} {scaleFactor NULL} } {
    foreach {dHmm dVmm} [moveSample_relativeToMM $deltaImageXFraction $deltaImageYFraction $scaleFactor] break
    return [moveSample_getDXDYDZFromMM $dHmm $dVmm $phiOffset]
}
proc moveSample_undo { } {
    variable cfgSampleMoveSerial
    variable sample_x
    variable sample_y
    variable sample_z
    variable ::moveSampleUndo::orig_x
    variable ::moveSampleUndo::orig_y
    variable ::moveSampleUndo::orig_z

    set new_x  $orig_x
    set new_y  $orig_y
    set new_z  $orig_z

    set orig_x $sample_x
    set orig_y $sample_y
    set orig_z $sample_z

    if {$cfgSampleMoveSerial} {
        move sample_x to $new_x
        wait_for_devices sample_x
        move sample_y to $new_y
        wait_for_devices sample_y
        move sample_z to $new_z
        wait_for_devices sample_z
    } else {
        move sample_x to $new_x
        move sample_y to $new_y
        move sample_z to $new_z
        wait_for_devices sample_x sample_y sample_z
    }
}

proc moveSampleRelativeMM { dHmm dVmm {phiOffset 0}} {
    foreach {dx dy dz} [moveSample_getDXDYDZFromMM $dHmm $dVmm $phiOffset] break
    
    variable cfgSampleMoveSerial
    variable sample_x
    variable sample_y
    variable sample_z
    variable ::moveSampleUndo::orig_x
    variable ::moveSampleUndo::orig_y
    variable ::moveSampleUndo::orig_z

    set orig_x $sample_x
    set orig_y $sample_y
    set orig_z $sample_z
    puts "moveSample saved $sample_x $sample_y $sample_z"

    if {$cfgSampleMoveSerial} {
        move sample_x by $dx
        wait_for_devices sample_x
        move sample_y by $dy
        wait_for_devices sample_y
        move sample_z by $dz
        wait_for_devices sample_z
    } else {
        move sample_x by $dx
        move sample_y by $dy
        move sample_z by $dz
        wait_for_devices sample_x sample_y sample_z
    }
}
proc moveSampleRelative { \
deltaImageXFraction \
deltaImageYFraction \
{phiOffset 0.0} \
{scaleFactor NULL} \
} {
    foreach {dHmm dVmm} [moveSample_relativeToMM $deltaImageXFraction $deltaImageYFraction $scaleFactor] break
    moveSampleRelativeMM $dHmm $dVmm $phiOffset
}

proc mergeSampleCameraParameters { } {
    variable cfgSampleCameraConstantNameList
    variable beamlineID

    log_severe \
    sample camera parameters merged from individual motors to a string.
    log_severe please look at SSRL wiki for details.

    set fn CAMERA_PARAM_$beamlineID.dat

    set contents [list]
    foreach m $cfgSampleCameraConstantNameList {
        variable $m
        if {[isMotor $m]} {
            lappend contents [set $m]
        } else {
            lappend contents 0
            log_warning $m not found
        }
    }

    if {[catch {open $fn w} h]} {
        log_error open file $fn faile: $h
        return
    }
    puts $h "sample_camera_constant"
    puts $h "13"
    puts $h "self standardString"
    puts $h "1 1 1 1 1"
    puts $h "0 0 0 0 0"
    puts $h $contents
    puts $h ""
    close $h

    log_severe Please insert file $fn into your database dump file
    log_severe and reload it.
}
proc moveSample_mmToRelative { dxMM dyMM {scaleFactor NULL}} {
	getSampleViewSize width height $scaleFactor

    set dx [expr $dxMM  / $width ]
    set dy [expr $dyMM  / $height ]

    return [list $dx $dy]
}
proc sampleView_calculate_zoom { width {height 0}} {
    puts "calculate zoom w=$width height=$height"
    set sampleImageWidth  [getSampleCameraConstant sampleImageWidth]

    set hScale [expr $width * 1000.0 / $sampleImageWidth]
    puts "calculate zoom: hScale=$hScale"
    if {$height > 0} {
        set sampleImageHeight  [getSampleCameraConstant sampleImageHeight]
        set sampleAspectRatio  [getSampleCameraConstant sampleAspectRatio]

        set vScale [expr $height * 1000.0 / $sampleImageHeight]
        set hScaleFromV [expr $vScale / $sampleAspectRatio]
        puts "calculate zoom: hScalefromV=$hScaleFromV"

        if {$hScale < $hScaleFromV} {
            set hScale $hScaleFromV
        }
    }
    puts "calculate zoom: final hScale=$hScale"

    return [sampleScaleFactor_calculate_zoom $hScale]
}
proc getSampleViewSize { hSizeRef vSizeRef {scaleFactor NULL} } {
	variable camera_zoom

    upvar $hSizeRef width
    upvar $vSizeRef height

    set sampleAspectRatio [getSampleCameraConstant sampleAspectRatio]
    set sampleImageHeight [getSampleCameraConstant sampleImageHeight]
    set sampleImageWidth  [getSampleCameraConstant sampleImageWidth]

	# calculate micron/pixel scale factor at current zoom level if not specified
	if { $scaleFactor == "NULL" } {
		set horizontalScale [sampleScaleFactor_calculate $camera_zoom]
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
