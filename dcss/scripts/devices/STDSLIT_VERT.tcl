# PREFIX_vert.tcl


proc PREFIX_vert_initialize {} {

	# specify children devices
	set_children PREFIX_upper PREFIX_lower
	set_siblings PREFIX_vert_gap
}


proc PREFIX_vert_move { new_PREFIX_vert } {
	#global namespace variables
	global gDevice

	# global variables
	variable PREFIX_vert_gap
	variable PREFIX_vert

	# calculate new positions of the two motors
	set new_PREFIX_upper [PREFIX_upper_calculate $new_PREFIX_vert $gDevice(PREFIX_vert_gap,target)]
	set new_PREFIX_lower [PREFIX_lower_calculate $new_PREFIX_vert $gDevice(PREFIX_vert_gap,target)]

    assertMotorLimit PREFIX_upper $new_PREFIX_upper
	assertMotorLimit PREFIX_lower  $new_PREFIX_lower

	# move motors in order that avoids collisions
	if { $new_PREFIX_vert > $PREFIX_vert } {
		move PREFIX_upper to $new_PREFIX_upper
		move PREFIX_lower to $new_PREFIX_lower
	} else {
		move PREFIX_lower to $new_PREFIX_lower
		move PREFIX_upper to $new_PREFIX_upper
	}

	# wait for the moves to complete
	wait_for_devices PREFIX_upper PREFIX_lower
}


proc PREFIX_vert_set { new_PREFIX_vert } {

	# global variables
	variable PREFIX_vert_gap
	variable PREFIX_upper
	variable PREFIX_lower

	# move the two motors
	set PREFIX_upper  [PREFIX_upper_calculate $new_PREFIX_vert $PREFIX_vert_gap]
	set PREFIX_lower  [PREFIX_lower_calculate $new_PREFIX_vert $PREFIX_vert_gap]
}


proc PREFIX_vert_update {} {

	# global variables
	variable PREFIX_upper
	variable PREFIX_lower

	# calculate from real motor positions and motor parameters
	return [PREFIX_vert_calculate $PREFIX_upper $PREFIX_lower]
}


proc PREFIX_vert_calculate { supper slower } {
	
	return [expr ($supper + $slower)/ 2.0 ]
}


proc PREFIX_upper_calculate { sv svg } {

	return [expr $sv + $svg / 2.0 ]
}


proc PREFIX_lower_calculate { sv svg } {

	return [expr $sv - $svg / 2.0 ]
}

