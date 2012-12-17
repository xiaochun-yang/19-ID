# PREFIX_vert_gap.tcl


proc PREFIX_vert_gap_initialize {} {

	# specify children devices
	set_children PREFIX_upper PREFIX_lower
	set_siblings PREFIX_vert
}


proc PREFIX_vert_gap_move { new_PREFIX_vert_gap } {
	#global namespace variables
	global gDevice

	# global variables
	variable PREFIX_vert

	set new_PREFIX_upper [PREFIX_upper_calculate $gDevice(PREFIX_vert,target) $new_PREFIX_vert_gap]
	set new_PREFIX_lower [PREFIX_lower_calculate $gDevice(PREFIX_vert,target) $new_PREFIX_vert_gap]

    assertMotorLimit PREFIX_upper $new_PREFIX_upper
	assertMotorLimit PREFIX_lower  $new_PREFIX_lower

	# move the two motors
	move PREFIX_upper to $new_PREFIX_upper
	move PREFIX_lower to $new_PREFIX_lower

	# wait for the moves to complete
	wait_for_devices PREFIX_upper PREFIX_lower
}


proc PREFIX_vert_gap_set { new_PREFIX_vert_gap } {

	# global variables
	variable PREFIX_vert
	variable PREFIX_upper
	variable PREFIX_lower

	# set the two motors
	set PREFIX_upper [PREFIX_upper_calculate $PREFIX_vert $new_PREFIX_vert_gap]
	set PREFIX_lower [PREFIX_lower_calculate $PREFIX_vert $new_PREFIX_vert_gap]
}


proc PREFIX_vert_gap_update {} {

	# global variables
	variable PREFIX_upper
	variable PREFIX_lower

	# calculate from real motor positions and motor parameters
	return [PREFIX_vert_gap_calculate $PREFIX_upper $PREFIX_lower]
}


proc PREFIX_vert_gap_calculate { s1upper s1lower } {
	
	return [expr $s1upper - $s1lower ]
}

