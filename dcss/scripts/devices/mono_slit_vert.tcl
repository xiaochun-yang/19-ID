
# mono_slit_vert.tcl


proc mono_slit_vert_initialize {} {

	# specify children devices
	set_children mono_slit_upper mono_slit_lower
	set_siblings mono_slit_vert_gap
}


proc mono_slit_vert_move { new_mono_slit_vert } {
	#global namespace variables
	global gDevice

	# global variables
	variable mono_slit_vert_gap
	variable mono_slit_vert

	# calculate new positions of the two motors
	set new_mono_slit_upper [mono_slit_upper_calculate $new_mono_slit_vert $gDevice(mono_slit_vert_gap,target)]
	set new_mono_slit_lower [mono_slit_lower_calculate $new_mono_slit_vert $gDevice(mono_slit_vert_gap,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit mono_slit_upper $new_mono_slit_upper
	assertMotorLimit mono_slit_lower $new_mono_slit_lower

	# move motors in order that avoids collisions
	if { $new_mono_slit_vert > $mono_slit_vert} { 
		move mono_slit_upper to $new_mono_slit_upper
		move mono_slit_lower to $new_mono_slit_lower
	} else {
		move mono_slit_lower to $new_mono_slit_lower
		move mono_slit_upper to $new_mono_slit_upper
	}

	# wait for the moves to complete
	wait_for_devices mono_slit_upper mono_slit_lower
}


proc mono_slit_vert_set { new_mono_slit_vert } {

	# global variables
	variable mono_slit_vert_gap
	variable mono_slit_upper
	variable mono_slit_lower

	# move the two motors
	set mono_slit_upper [mono_slit_upper_calculate $new_mono_slit_vert $mono_slit_vert_gap]
	set mono_slit_lower [mono_slit_lower_calculate $new_mono_slit_vert $mono_slit_vert_gap]
}


proc mono_slit_vert_update {} {

	# global variables
	variable mono_slit_upper
	variable mono_slit_lower

	# calculate from real motor positions and motor parameters
	return [mono_slit_vert_calculate $mono_slit_upper $mono_slit_lower]
}


proc mono_slit_vert_calculate { s1u s1l } {
	
	return [expr ($s1u + $s1l)/ 2.0 ]
}


proc mono_slit_upper_calculate { s1v s1vg } {

	return [expr $s1v + $s1vg / 2.0 ]
}


proc mono_slit_lower_calculate { s1v s1vg } {

	return [expr $s1v - $s1vg / 2.0 ]
}

