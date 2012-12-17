# slit_1_vert_gap.tcl


proc slit_1_vert_gap_initialize {} {

	# specify children devices
	set_children slit_1_upper slit_1_lower
	set_siblings slit_1_vert
}


proc slit_1_vert_gap_move { new_slit_1_vert_gap } {
	#global 
	global gDevice

	# global variables
	variable slit_1_vert

	# calculate new positions of the two motors
	set new_slit_1_upper [slit_1_upper_calculate $gDevice(slit_1_vert,target) $new_slit_1_vert_gap]
	set new_slit_1_lower [slit_1_lower_calculate $gDevice(slit_1_vert,target) $new_slit_1_vert_gap]

	
	#check to see if the move can be completed by the real motors
	assertMotorLimit slit_1_upper $new_slit_1_upper
	assertMotorLimit slit_1_lower $new_slit_1_lower

	# move the two motors
	move slit_1_upper to $new_slit_1_upper
	move slit_1_lower to $new_slit_1_lower
	
	# wait for the moves to complete
	wait_for_devices slit_1_upper slit_1_lower
}


proc slit_1_vert_gap_set { new_slit_1_vert_gap } {

	# global variables
	variable slit_1_vert
	variable slit_1_upper
	variable slit_1_lower

	# set the two motors
	set slit_1_upper [slit_1_upper_calculate $slit_1_vert $new_slit_1_vert_gap]
	set slit_1_lower [slit_1_lower_calculate $slit_1_vert $new_slit_1_vert_gap]
}


proc slit_1_vert_gap_update {} {

	# global variables
	variable slit_1_upper
	variable slit_1_lower

	# calculate from real motor positions and motor parameters
	return [slit_1_vert_gap_calculate $slit_1_upper $slit_1_lower]
}


proc slit_1_vert_gap_calculate { s1u s1l } {
	
	return [expr $s1u - $s1l ]
}

