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

proc visexMoveSample_initialize {} {
    variable new_camera_constant_name_list
    set new_camera_constant_name_list [::config getStr visexCameraConstantsNameList]
}
proc visexCameraConstantNameToIndex { name } {
    variable new_camera_constant_name_list
    variable visex_camera_constant

    set index [lsearch -exact $new_camera_constant_name_list $name]
    if {$index < 0} {
        return -code error "${name}_not_found_in_visex_constant_name_list"
    }
    set ll [llength $visex_camera_constant]
    if {$index >= $ll} {
        return -code error "bad_contents_of_visex_camera_constant"
    }

    return $index
}

proc getVisexCameraConstant { name } {
    variable visex_camera_constant

    set index [visexCameraConstantNameToIndex $name]
    return [lindex $visex_camera_constant $index]
}
proc setVisexCameraConstant { name value } {
    variable visex_camera_constant

    set index [visexCameraConstantNameToIndex $name]
    set visex_camera_constant \
    [lreplace $visex_camera_constant $index $index $value]
}

proc visexMoveSample_start { args } {
    variable visex_snapshot_nocheck
    set visex_snapshot_nocheck 1

	eval visexMoveSampleRelative $args
}
proc visexMoveSample_cleanup { } {
    variable visex_snapshot_nocheck
    variable visex_msg

    set visex_snapshot_nocheck 0
    set visex_msg ""
}

proc visexMoveSample_getDXDYDZFromRelative { \
deltaImageXFraction deltaImageYFraction \
} {
    variable visex_snapshot_orig

    #### click move is the opposite of move to marker

    return [calculateSamplePositionDeltaFromDeltaProjection \
    $visex_snapshot_orig \
    $deltaImageYFraction \
    $deltaImageXFraction]
}

proc visexMoveSampleFaceCamera { whichCamera {phi_only 0} } {
    variable camera_view_phi
    variable cfgSampleMoveSerial

    variable gonio_omega
    variable visex_snapshot_orig

    if {![info exists camera_view_phi($whichCamera)]} {
        return
    }

    foreach {x y z a} $visex_snapshot_orig break
    set phi [expr $a - $gonio_omega + $camera_view_phi($whichCamera)]

    if {$phi_only} {
        move gonio_phi to $phi
        wait_for_devices gonio_phi
        return
    }

    if {$cfgSampleMoveSerial} {
        move sample_x to $x
        wait_for_devices sample_x
        move sample_y to $y
        wait_for_devices sample_y
        move sample_z to $z
        wait_for_devices sample_z
        move gonio_phi to $phi
        wait_for_devices gonio_phi
    } else {
        move sample_x to $x
        move sample_y to $y
        move sample_z to $z
        move gonio_phi to $phi
        wait_for_devices sample_x sample_y sample_z gonio_phi
    }
}

#### we need to know which video to face the view afterward.
proc visexMoveSampleRelative { deltaImageXFraction deltaImageYFraction } {
    variable visex_msg
    variable visex_snapshot_orig
    variable sample_x
    variable sample_y
    variable sample_z
    variable ::moveSampleUndo::orig_x
    variable ::moveSampleUndo::orig_y
    variable ::moveSampleUndo::orig_z

    set toVideo [lindex $visex_snapshot_orig 8]
    set orig_x $sample_x
    set orig_y $sample_y
    set orig_z $sample_z
    puts "visexMoveSample saved $sample_x $sample_y $sample_z"

    visexMoveSampleFaceCamera visex

    set visex_msg "moving"

    foreach {dx dy dz} [visexMoveSample_getDXDYDZFromRelative \
    $deltaImageXFraction $deltaImageYFraction] break

    variable cfgSampleMoveSerial
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
	
        # wait for all device motions to complete
        wait_for_devices sample_x sample_y sample_z
    }

    ### keep old "from"
    videoVisexSnapshot_start ""
    ### already at orig, only need to move phi
    visexMoveSampleFaceCamera $toVideo 1

    variable visex_snapshot_save
    set visex_snapshot_save [videoVisexSnapshot_getCondition $toVideo]
}
proc visexMoveSampleRelativeToMM { dx dy } {
    set viewHeight [getVisexCameraConstant view_height_mm]
    set viewWidth  [getVisexCameraConstant view_width_mm]
	
	set dXmm [expr $viewWidth  * $dx] 
    set dYmm [expr $viewHeight * $dy]

    return [list $dXmm $dYmm]
}
proc visexMoveSampleRelativeMM { deltaXmm deltaYmm toVideo } {
    foreach {deltaX deltaY} [visexMoveSample_mmToRelative \
    $deltaXmm $deltaYmm] break

    visexMoveSampleRelative $deltaX $deltaY $toVideo
}
proc visexMoveSample_mmToRelative { dxMM dyMM } {
    set viewHeight [getVisexCameraConstant view_height_mm]
    set viewWidth  [getVisexCameraConstant view_width_mm]

    if {$viewWidth <= 0 || $viewHeight <= 0} {
        return -code error "bad_view_width_or_height"
    }

    set dx [expr $dxMM / $viewWidth]
    set dy [expr $dyMM / $viewHeight]

    return [list $dx $dy]
}
