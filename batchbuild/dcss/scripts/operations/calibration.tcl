#
#                        Copyright 2001
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
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

proc calibration_initialize {} {


}



proc calibration_start {} {


	# global variables 
	setGlobalVariables

	#Main Procedure
	set retCode [getMMPixelandRotationAxis 0]
	if { $retCode < 0 } {
		log_error "Zoom Level 0: Initial Setting isn't good for Calibration!"
		return -1
	}
	set retCode [getMMPixelandRotationAxis 0.6]
	if { $retCode < 0 } {
		log_error "Zoom Level 0.6: Initial Setting isn't good for Calibration!"
		return -1
	}
	set retCode [getMMPixelandRotationAxis 1.0]
	if { $retCode < 0 } {
		log_error "Zoom Level 1.0: Initial Setting isn't good for Calibration!"
		return -1
	}
}


proc errorParser { errorMsg } {

	if { [lindex $errorMsg 0] == "no_hw_host" } {
		log_error "Image centering DHS is offline."
		return -1
	}
	if { [lindex $errorMsg 0] == "not_master" } {
		log_error "Must be master to center crystal."
		return -1
	}
	if { [lindex $errorMsg 1] == "TipNotInView" } {
		log_error "Tip isn't clear for Camera."
		return -1
	}

	return -1
}	

# Procedure: setGlobalVariables()
# Delare Global variables which will be used in this script
# and initialize them.

proc setGlobalVariables {} {
global g_mm_pixel
set g_mm_pixel 0

global g_img_wide
set g_img_wide 352

global g_img_height
set g_img_height 240

}

# Procedure: GetCurrentTipRelPos( {retPinPos 0} )
# In this funtion, DCSS will send a command message "getLoopTip" to DHS,
# DHS then return current Loop Tip's position in the view in percentage.

proc GetCurrentTipPos {} {

set handle [start_waitable_operation getLoopTip 0]
set result [wait_for_operation $handle 30000]

return $result
}

# Move Loop by Specified Relative Position
proc moverelative { rel_x rel_y {pinPos 0} {delta_phi 0} } {

	global gDevice
	global g_mm_pixel
	global g_img_wide
	global g_img_height

	if { $gDevice(sample_x,status) != "inactive" || $gDevice(sample_y,status) != "inactive" } {
 		return -1
	}
	
	set phiDeg [expr $gDevice(gonio_phi,scaled) + $gDevice(gonio_omega,scaled) + $delta_phi]

   set moveZ [expr -1*$g_img_wide*$rel_x*$g_mm_pixel]
   set moveY [expr $g_img_height*abs($rel_y)*$g_mm_pixel]

	if { $rel_y > 0 } {
		set phi [expr $phiDeg / 180.0 * 3.14159]
	} else {
	  set phi [expr ($phiDeg + 180.0 )/ 180.0 * 3.14159]
	}
	set comp_x [expr -sin($phi) * $moveY ]
	set comp_y [expr cos($phi) * $moveY ]
 
   # move in Y direction of View
   move sample_x by $comp_x
   move sample_y by $comp_y

   # move in X direcition of View 
	# decied if we need to move a little bit to eliminate pin in the view
	if { $pinPos != 0 } { 
		set viewableScreenWidth [expr $screenWidth*0.8]
		if { $viewableScreenWidth > $pinPos } {
			set moveZ [expr $moveZ - [expr $viewableScreenWidth - $pinPos]] 
		}
	}

	move sample_z by $moveZ
   wait_for_devices sample_x sample_y sample_z
}

# Update current MM vs. Pixel relation
# Return current tip's position
proc getMMPixelRelation { zoom_level {try_time 1} } {

global g_mm_pixel
global g_img_wide 
global g_img_height

# Get Current Tip's Position
set tipResult [GetCurrentTipPos]

# Check Error 
set statusCode [lindex $tipResult 0]
if { $statusCode != "normal" } {
	return [errorParser $tipResult]
}

set tipX1 [lindex $tipResult 1]
set tipY [lindex $tipResult 2]

# Move sample_z
if { $try_time == 1 } {
	# First time we just try a small movement
	if { $tipX1 <= 0.5 } {
		set moveZ [expr 1.2*(1.1 - $zoom_level)]
	} else {
		set moveZ [expr -1.2*(1.1 - $zoom_level)]
	}
} else {
	# Second time we will move pin from x current position to 0.8
	set moveZ [expr double($g_mm_pixel)*(0.8 - $tipX1)*( double($g_img_wide) )]
}


move sample_z by $moveZ
wait_for_devices sample_z

# Get Current Tip's Position
set tipResult [GetCurrentTipPos]

# Check Error 
set statusCode [lindex $tipResult 0]
if { $statusCode != "normal" } {
	return [errorParser $tipResult]
}

set tipX2 [lindex $tipResult 1]
if { abs($tipX2 - $tipX1) < 0.01 } {
	return (-1)
}

set g_mm_pixel [expr $moveZ/( ($tipX2 - $tipX1)*double($g_img_wide) )]

# Compose Result List
lappend tipX2 $tipY

return $tipX2

}

# Return current zoom level RotationAxisY position and 
# current pin's position

proc getRotationAxisY {} {

# Get Current Tip's Position
set tipResult [GetCurrentTipPos]

# Check Error 
set statusCode [lindex $tipResult 0]
if { $statusCode != "normal" } {
	return [errorParser $tipResult]
}

# Record pin current Y position
set tipY1 [lindex $tipResult 2]

# Rotate 180 degree for second time
move gonio_phi by 180
wait_for_devices gonio_phi

# Get Current Tip's Position
set tipResult [GetCurrentTipPos]

# Check Error 
set statusCode [lindex $tipResult 0]
if { $statusCode != "normal" } {
	return [errorParser $tipResult]
}

set tipX  [lindex $tipResult 1]
set tipY2 [lindex $tipResult 2]
set RotationAxisY [expr ($tipY1 + $tipY2)*0.5]

lappend RotationAxisY $tipX $tipY2 

return $RotationAxisY

}


# This procedure will get mm vs. pixel relation and
# which is rotation axis located 
proc getMMPixelandRotationAxis { zoom_level } {

global g_mm_pixel  

move camera_zoom to $zoom_level
wait_for_devices camera_zoom	

# Update g_mm_pixel for first time 
set tipResult [getMMPixelRelation $zoom_level]
# Check Error 
set statusCode [lindex $tipResult 0]
if { $statusCode == -1 } {
	return $statusCode
}

set tipX [lindex $tipResult 0]
set tipY [lindex $tipResult 1]

# Move to one quarter height
set rel_x [expr $tipX - 0.5]
set rel_y [expr $tipY - 0.25]
moverelative $rel_x $rel_y

# Get RotationAxisY for first time
set tipResult [getRotationAxisY]
# Check Error 
set statusCode [lindex $tipResult 0]
if { $statusCode == -1 } {
	return $statusCode
}

set RotationAxisY [lindex $tipResult 0]
set tipX [lindex $tipResult 1]
set tipY [lindex $tipResult 2]
# Move to rotation axis
# In addition, Because we want to move as far as we can when we measure mm_pixel, 
# we will move back pin to x position 0.2
set rel_x [expr $tipX - 0.2]
set rel_y [expr $tipY - $RotationAxisY]

moverelative $rel_x $rel_y

# Update g_mm_pixel for second time
set tipResult [getMMPixelRelation $zoom_level 2]
# Check Error 
set statusCode [lindex $tipResult 0]
if { $statusCode == -1 } {
	return $statusCode
}

set tipX [lindex $tipResult 0]

# Move tip to center
set rel_x [expr $tipX - 0.5]
moverelative $rel_x 0

# Get RotationAxisY for second time
set tipResult [getRotationAxisY]
# Check Error 
set statusCode [lindex $tipResult 0]
if { $statusCode == -1 } {
	return $statusCode
}

set RotationAxisY1 [lindex $tipResult 0]
set tipX [lindex $tipResult 1]
set tipY [lindex $tipResult 2]

set rel_y [expr $tipY - $RotationAxisY1]
moverelative 0 $rel_y

# Center alignment pin
# Rotate 90 degree
move gonio_phi by 90
wait_for_devices gonio_phi

set tipResult [getRotationAxisY]
# Check Error 
set statusCode [lindex $tipResult 0]
if { $statusCode == -1 } {
	return $statusCode
}

set RotationAxisY2 [lindex $tipResult 0]
set tipY [lindex $tipResult 2]

# Use average value of the two RotationAxisY value as the final value for RotationAxisY
set RotationAxisY [expr ($RotationAxisY1+$RotationAxisY2)*0.5]

set rel_y [expr $tipY - $RotationAxisY]
moverelative 0 $rel_y

# Update DCSS Global Variables
if { abs($zoom_level - 0) < 0.02 } {
    setSampleCameraConstant zoomMinYAxis $RotationAxisY
    setSampleCameraConstant zoomMinScale [expr $g_mm_pixel*1000] 
} 
if { abs($zoom_level - 0.6) < 0.02 } {
    setSampleCameraConstant zoomMedYAxis $RotationAxisY
    setSampleCameraConstant zoomMedScale [expr $g_mm_pixel*1000] 
} 
if { abs($zoom_level - 1.0) < 0.02 } {
    setSampleCameraConstant zoomMaxYAxis $RotationAxisY
    setSampleCameraConstant zoomMaxScale [expr $g_mm_pixel*1000] 
}

return 1
}

