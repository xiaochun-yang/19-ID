
# slit_1_vert.tcl


proc slit_1_vert_initialize {} {

	# specify children devices
	set_children slit_1_upper slit_1_lower
	set_siblings slit_1_vert_gap
}


proc slit_1_vert_move { new_slit_1_vert } {
	#global namespace variables
	global gDevice

	# global variables
	variable slit_1_vert_gap
	variable slit_1_vert

	# calculate new positions of the two motors
	set new_slit_1_upper [slit_1_upper_calculate $new_slit_1_vert $gDevice(slit_1_vert_gap,target)]
	set new_slit_1_lower [slit_1_lower_calculate $new_slit_1_vert $gDevice(slit_1_vert_gap,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit slit_1_upper $new_slit_1_upper
	assertMotorLimit slit_1_lower $new_slit_1_lower

	# move motors in order that avoids collisions
	if { $new_slit_1_vert > $slit_1_vert} { 
		move slit_1_upper to $new_slit_1_upper
		move slit_1_lower to $new_slit_1_lower
	} else {
		move slit_1_lower to $new_slit_1_lower
		move slit_1_upper to $new_slit_1_upper
	}

	# wait for the moves to complete
	wait_for_devices slit_1_upper slit_1_lower
}


proc slit_1_vert_set { new_slit_1_vert } {

	# global variables
	variable slit_1_vert_gap
	variable slit_1_upper
	variable slit_1_lower

	# move the two motors
	set slit_1_upper [slit_1_upper_calculate $new_slit_1_vert $slit_1_vert_gap]
	set slit_1_lower [slit_1_lower_calculate $new_slit_1_vert $slit_1_vert_gap]
}


proc slit_1_vert_update {} {

	# global variables
	variable slit_1_upper
	variable slit_1_lower

	# calculate from real motor positions and motor parameters
	return [slit_1_vert_calculate $slit_1_upper $slit_1_lower]
}


proc slit_1_vert_calculate { s1u s1l } {
	
	return [expr ($s1u + $s1l)/ 2.0 ]
}


proc slit_1_upper_calculate { s1v s1vg } {

	return [expr $s1v + $s1vg / 2.0 ]
}


proc slit_1_lower_calculate { s1v s1vg } {

	return [expr $s1v - $s1vg / 2.0 ]
}

