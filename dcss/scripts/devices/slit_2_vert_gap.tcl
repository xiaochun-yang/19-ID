# slit_2_vert_gap.tcl


proc slit_2_vert_gap_initialize {} {

	# specify children devices
	set_children slit_2_upper slit_2_lower
	set_siblings slit_2_vert
}


proc slit_2_vert_gap_move { new_slit_2_vert_gap } {
	#global 
	global gDevice

	# global variables
	variable slit_2_vert

	#check to see if the move can be completed by the real motors
	assertMotorLimit slit_2_upper [slit_2_upper_calculate $gDevice(slit_2_vert,target) $new_slit_2_vert_gap]
	assertMotorLimit slit_2_lower [slit_2_lower_calculate $gDevice(slit_2_vert,target) $new_slit_2_vert_gap]

	# move the two motors
	move slit_2_upper to [slit_2_upper_calculate $gDevice(slit_2_vert,target) $new_slit_2_vert_gap]
	move slit_2_lower to [slit_2_lower_calculate $gDevice(slit_2_vert,target) $new_slit_2_vert_gap]

	# wait for the moves to complete
	wait_for_devices slit_2_upper slit_2_lower
}


proc slit_2_vert_gap_set { new_slit_2_vert_gap } {

	# global variables
	variable slit_2_vert
	variable slit_2_upper
	variable slit_2_lower

	# move the two motors
	set slit_2_upper [slit_2_upper_calculate $slit_2_vert $new_slit_2_vert_gap]
	set slit_2_lower [slit_2_lower_calculate $slit_2_vert $new_slit_2_vert_gap]
}


proc slit_2_vert_gap_update {} {

	# global variables
	variable slit_2_upper
	variable slit_2_lower

	# calculate from real motor positions and motor parameters
	return [slit_2_vert_gap_calculate $slit_2_upper $slit_2_lower]
}


proc slit_2_vert_gap_calculate { s2u s2l } {
	
	return [expr $s2u - $s2l ]
}

