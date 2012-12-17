# slit_2_vert.tcl


proc slit_2_vert_initialize {} {

	# specify children devices
	set_children slit_2_upper slit_2_lower
	set_siblings slit_2_vert_gap
}


proc slit_2_vert_move { new_slit_2_vert } {
	#global 
	global gDevice

	# global variables
	variable slit_2_vert_gap
	variable slit_2_vert

	# calculate new positions of the two motors
	set new_slit_2_upper [slit_2_upper_calculate $new_slit_2_vert $gDevice(slit_2_vert_gap,target)]
	set new_slit_2_lower [slit_2_lower_calculate $new_slit_2_vert $gDevice(slit_2_vert_gap,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit slit_2_upper $new_slit_2_upper
	assertMotorLimit slit_2_lower $new_slit_2_lower

	# move motors in order that avoids collisions
	if { $new_slit_2_vert > $slit_2_vert} { 
		move slit_2_upper to $new_slit_2_upper
		move slit_2_lower to $new_slit_2_lower
	} else {
		move slit_2_lower to $new_slit_2_lower
		move slit_2_upper to $new_slit_2_upper
	}

	# wait for the moves to complete
	wait_for_devices slit_2_upper slit_2_lower
}


proc slit_2_vert_set { new_slit_2_vert } {

	# global variables
	variable slit_2_vert_gap
	variable slit_2_upper
	variable slit_2_lower

	# move the two motors
	set slit_2_upper [slit_2_upper_calculate $new_slit_2_vert $slit_2_vert_gap]
	set slit_2_lower [slit_2_lower_calculate $new_slit_2_vert $slit_2_vert_gap]
}


proc slit_2_vert_update {} {

	# global variables
	variable slit_2_upper
	variable slit_2_lower

	# calculate from real motor positions and motor parameters
	return [slit_2_vert_calculate $slit_2_upper $slit_2_lower]
}


proc slit_2_vert_calculate { s2u s2l } {
	
	return [expr ($s2u + $s2l)/ 2.0 ]
}


proc slit_2_upper_calculate { s2v s2vg } {

	return [expr $s2v + $s2vg / 2.0 ]
}


proc slit_2_lower_calculate { s2v s2vg } {

	return [expr $s2v - $s2vg / 2.0 ]
}

