
# Procedure: setdefaultvalue()
#
# In this function, we will set the default settings
# and these settings will make the pin almost align 
# to the rotation axis and whole loop is visible in Max. Zoom out View.
#
proc setdefaultvalue {} {

# Default Settings
move camera_zoom to 0 mm

wait_for_devices camera_zoom
}


# Move Loop by Specified Relative Position
proc moverelative { rel_x rel_y {pinPos 0} {delta_phi 0} } {

	global gDevice
	global g_img_wide
	global g_img_height

	set um_pixel 0

	if { $gDevice(sample_x,status) != "inactive" || $gDevice(sample_y,status) != "inactive" } {
 		return -1
	}

   set zoom_level $gDevice(camera_zoom,scaled)

	if { $zoom_level == 0 } {
		set um_pixel $gDevice(zoomMinScale,scaled)
	}

	if { $zoom_level == 0.6 } {
		set um_pixel $gDevice(zoomMedScale,scaled)
	} 

	if { $zoom_level == 0.9 } {
		set um_pixel $gDevice(zoomMaxScale,scaled)
	}

	set phiDeg [expr $gDevice(gonio_phi,scaled) + $gDevice(gonio_omega,scaled) + $delta_phi]

   set moveZ [expr -1*$g_img_wide*$rel_x*$um_pixel]

   set moveY [expr $g_img_height*abs($rel_y)*$um_pixel]

	if { $rel_y > 0 } {
		set phi [expr $phiDeg / 180.0 * 3.14159]
	} else {
	  set phi [expr ($phiDeg + 180.0 )/ 180.0 * 3.14159]
	}
	set comp_x [expr -sin($phi) * $moveY ]
	set comp_y [expr cos($phi) * $moveY ]
 
   # move in Y direction of View
   move sample_x by $comp_x um
   move sample_y by $comp_y um

   # move in X direcition of View 
	# decied if we need to move a little bit to eliminate pin in the view
	if { $pinPos != 0 } { 
		set viewableScreenWidth [expr $g_img_wide*0.8*$um_pixel]
		if { $viewableScreenWidth > $pinPos } {
			set moveZ [expr $moveZ - [expr $viewableScreenWidth - $pinPos]] 
		}
	}
	move sample_z by $moveZ um
   wait_for_devices sample_x sample_y sample_z
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

# Procedure: GetCurrentTipRelPos( retPinPos )
# In this funtion, DCSS will send a command message "getLoopTip" to DHS,
# DHS then return current Loop Tip's position in the view in percentage.

proc GetCurrentTipPos {} {

set handle [start_waitable_operation getLoopTip 0]
set result [wait_for_operation $handle]

return $result
}

proc centerLoopTip { maxAttempts {maxError 0.05} } {

	global gDevice
	global g_img_wide
	global g_img_height

	set RotationAxisY 0
   set zoom_level $gDevice(camera_zoom,scaled)

	if { $zoom_level == 0 } {
		set RotationAxisY $gDevice(zoomMinYAxis,scaled)
	} 
	if { $zoom_level == 0.6 } {
		set RotationAxisY $gDevice(zoomMedYAxis,scaled)
	} 
	if { $zoom_level == 0.9 } {
		set RotationAxisY $gDevice(zoomMaxYAxis,scaled)
	}

	set errorflag 0
	# iterate as requested
	for { set attempt 0} { $attempt < $maxAttempts } { incr attempt } {

		# look for the tip position
		set tipResult [GetCurrentTipPos]

		# extract tokens from the result
		set statusCode [lindex $tipResult 0]
		
		# check for error
		if { $statusCode != "normal" } {
			return [errorParser $tipResult]
		}

		set tipX [lindex $tipResult 1]
		set tipY [lindex $tipResult 2]

		# Initialize Image Size
		set g_img_wide [lindex $tipResult 3]
		set g_img_height [lindex $tipResult 4]

		# calculate the correction needed to bring tip to center
		set deltaX [expr $tipX - 0.55]
		set deltaY [expr $tipY - $RotationAxisY]

		# make the correction of the sample position
		moverelative $deltaX $deltaY
		
		# break out of loop if correction was small
		if { sqrt($deltaX * $deltaX + $deltaY * $deltaY) < $maxError } {
			set errorflag 1
			break
		}
	}

	if { $errorflag == 0 && $maxAttempts > 1 } {
		return (-1)
	}

	return 1
}

proc getRelativePinPosition {} {
	
set handle [start_waitable_operation getLoopTip 1]
set result [wait_for_operation $handle]

set statusCode [lindex $result 0]

if { $statusCode != "normal" } {
	return [errorParser $result]
}

if { [lindex $result 3] != 0 } {
	return [expr [lindex $result 1] - [lindex $result 3]]
}

return 0
	
}

proc rotate90degree {} {

global gDevice

set RotationAxisY 0

# Get Current Zoom Level's Rotation Axis
set zoom_level $gDevice(camera_zoom,scaled)
if { $zoom_level == 0 } {
	set RotationAxisY $gDevice(zoomMinYAxis,scaled)
} 
if { $zoom_level == 0.6 } {
	set RotationAxisY $gDevice(zoomMedYAxis,scaled)
} 
if { $zoom_level == 0.9 } {
	set RotationAxisY $gDevice(zoomMaxYAxis,scaled)
}

# Rotate Loop 30 deg and Estimated the farmost position in Y direction of View
move gonio_phi by 30 deg
wait_for_devices gonio_phi

set result [GetCurrentTipPos]

# extract tokens from the result
set statusCode [lindex $result 0]
if { $statusCode != "normal" } {
	return [errorParser $result]
}
set tipY [lindex $result 2]
set rel_y [expr $tipY - $RotationAxisY]

# Move the left 60 degree
move gonio_phi by 60 deg

if { abs([expr $rel_y*2]) > 0.45 } {
	moverelative 0 [expr $rel_y*2] 0 60
}
# rotation 90 degree is completed
wait_for_devices gonio_phi

return 1
}


proc GetAbsoluteDistanceBetweenTipandPinBase {rel_pinpos} {

	global gDevice
	global g_img_wide

	if { $gDevice(sample_x,status) != "inactive" || \
			  $gDevice(sample_y,status) != "inactive" } {
 		return -1
	}

	set um_pixel 0

	if { $gDevice(sample_x,status) != "inactive" || $gDevice(sample_y,status) != "inactive" } {
 		return -1
	}

   set zoom_level $gDevice(camera_zoom,scaled)

	if { $zoom_level == 0 } {
		set um_pixel $gDevice(zoomMinScale,scaled)
	} 
	if { $zoom_level == 0.6 } {
		set um_pixel $gDevice(zoomMedScale,scaled)
	} 
	if { $zoom_level == 0.9 } {
		set um_pixel $gDevice(zoomMaxScale,scaled)
	}

	set screenWidth [expr $g_img_wide*$um_pixel]

   set PinPos [expr $screenWidth * $rel_pinpos]

	return $PinPos
}


proc createImgList {} {

	global gDevice
	global g_img_height

	# Get Current Zoom Level's Rotation Axis
	set zoom_level $gDevice(camera_zoom,scaled)

   for { set i 0 } { $i < 18 } { incr i } {
		set handle [start_waitable_operation addImageToList $i]
		set result [wait_for_operation $handle]

		set statusCode [lindex $result 0]
		if { $statusCode != "normal" } {
			return [errorParser $result]
		}

		# Make sure that current Loop isn't too big
		set curLoopHeight [lindex $result 1]
		if { [expr $curLoopHeight/$g_img_height] > 0.75 } {
			# We should decrease zoom level and create Image List again
			if { $zoom_level == 0.6 } {
				# We can't decrease zoom level any more so report error and exit
				log_note "Loop is too big for current centering procedure or Image isn't clear for detection\n"
				return -2
			}
			move camera_zoom to 0.6 mm
			wait_for_devices camera_zoom
			set i 0
			continue
		}

		move gonio_phi by 10 deg
		wait_for_devices gonio_phi
	}

	return 1
}

# I divide whole centeing process into tow Phase
# PhaseI centering Loop by Loop Tip,
# PhaseII centeing Loop by Loop Bounding Box
proc centeringPhaseI {} {

# In first centering process, we will do this process up to 
# 4 times and hope it can make tip converge to one fixed point

set retCode [centerLoopTip 4 0.08]
if { $retCode < 0 } return $retCode

set retCode [rotate90degree]
if { $retCode < 0 } return $retCode

set retCode [centerLoopTip 1]
if { $retCode < 0 } return $retCode

set pinPos [getRelativePinPosition]
if { $pinPos < 0 } {
	return (-1)
}

if { $pinPos <= 0.05 } {
	set pinPos 0
} else {
	set pinPos [GetAbsoluteDistanceBetweenTipandPinBase $pinPos]
}

# Zoom out level centering finished and Zoom in level centering begins
move camera_zoom to 0.9 mm
wait_for_devices camera_zoom

set retCode [centerLoopTip 1]
if { $retCode < 0 } return $retCode

set retCode [rotate90degree]
if { $retCode < 0 } return $retCode

set retCode [centerLoopTip 1]
if { $retCode < 0 } return $retCode

#Eliminate Pin in view and meanwhile move tip along X direction in view to position 0.8
set rel_x [expr 0.55 - 0.8]
moverelative $rel_x 0 $pinPos

return 1

}

proc centeringPhaseII {} {

global gDevice

set RotationAxisY 0

# Get Current Zoom Level's Rotation Axis
set zoom_level $gDevice(camera_zoom,scaled)
if { $zoom_level == 0 } {
	set RotationAxisY $gDevice(zoomMinYAxis,scaled)
} 
if { $zoom_level == 0.6 } {
	set RotationAxisY $gDevice(zoomMedYAxis,scaled)
} 
if { $zoom_level == 0.9 } {
	set RotationAxisY $gDevice(zoomMaxYAxis,scaled)
}

set retCode [createImgList]
if { $retCode < 0 } return $retCode

set handle [start_waitable_operation findBoundingBox Both Both]
set result [wait_for_operation $handle]

#use bounding box information to center again
set MaxImgIndex  [lindex $result 1]
set MinImgIndex  [lindex $result 2]
set B_LeftX      [lindex $result 3]
set B_UpperY     [lindex $result 4]
set B_RightX     [lindex $result 5]
set B_LowerY     [lindex $result 6]
set S_UpperY     [lindex $result 8]
set S_LowerY     [lindex $result 10]
#rotate back
move gonio_phi by [expr -1*(17 - $MinImgIndex)*10] deg
wait_for_devices gonio_phi

#final centering
set rel_x [expr $B_LeftX + ( $B_RightX - $B_LeftX )*0.6 ]
set rel_y [expr ( $S_UpperY + $S_LowerY )/2.0 ]

set rel_x [expr $rel_x - 0.55]
set rel_y [expr $rel_y - $RotationAxisY]

moverelative $rel_x $rel_y

#rotate to Max Image
move gonio_phi by [expr [expr $MaxImgIndex - $MinImgIndex]*10] deg
wait_for_devices gonio_phi

set rel_y [expr ( $B_UpperY + $B_LowerY )/2.0 - $RotationAxisY]
moverelative 0 $rel_y

return 1
}



proc center_crystal {} {
	
# Begin Centering Process	
	set retCode 0
	
	setdefaultvalue
	
	for { set i 0 } { $i < 4 } { incr i 1} {

		set retCode [centeringPhaseI]
		if { $retCode >= 0 } {
			set retCode [centeringPhaseII]
		}

		if { ($retCode >= 0) || ($retCode == -2) } { 
			break
		}
		move camera_zoom to 0 mm
		wait_for_devices camera_zoom
	}
	
	if { $retCode < 0 } {
		log_note "Some error can't be resolved by Centering Process!\n"
	}
# Centering Process is completed.
}

