# white_beam_slit_vert.tcl


proc white_beam_slit_vert_initialize {} {

	# specify children devices
	set_children white_beam_slit_upper white_beam_slit_lower
	set_siblings white_beam_slit_vert_gap
}


proc white_beam_slit_vert_move { new_white_beam_slit_vert } {
	#global namespace variables
	global gDevice

	# global variables
	variable white_beam_slit_vert_gap
	variable white_beam_slit_vert

	# calculate new positions of the two motors
	set new_white_beam_slit_upper [white_beam_slit_upper_calculate $new_white_beam_slit_vert $gDevice(white_beam_slit_vert_gap,target)]
	set new_white_beam_slit_lower [white_beam_slit_lower_calculate $new_white_beam_slit_vert $gDevice(white_beam_slit_vert_gap,target)]

    assertMotorLimit white_beam_slit_upper $new_white_beam_slit_upper
	assertMotorLimit white_beam_slit_lower  $new_white_beam_slit_lower

	# move motors in order that avoids collisions
	if { $new_white_beam_slit_vert > $white_beam_slit_vert } {
		move white_beam_slit_upper to $new_white_beam_slit_upper
		move white_beam_slit_lower to $new_white_beam_slit_lower
	} else {
		move white_beam_slit_lower to $new_white_beam_slit_lower
		move white_beam_slit_upper to $new_white_beam_slit_upper
	}

	# wait for the moves to complete
	wait_for_devices white_beam_slit_upper white_beam_slit_lower
}


proc white_beam_slit_vert_set { new_white_beam_slit_vert } {

	# global variables
	variable white_beam_slit_vert_gap
	variable white_beam_slit_upper
	variable white_beam_slit_lower

	# move the two motors
	set white_beam_slit_upper  [white_beam_slit_upper_calculate $new_white_beam_slit_vert $white_beam_slit_vert_gap]
	set white_beam_slit_lower  [white_beam_slit_lower_calculate $new_white_beam_slit_vert $white_beam_slit_vert_gap]
}


proc white_beam_slit_vert_update {} {

	# global variables
	variable white_beam_slit_upper
	variable white_beam_slit_lower

	# calculate from real motor positions and motor parameters
	return [white_beam_slit_vert_calculate $white_beam_slit_upper $white_beam_slit_lower]
}


proc white_beam_slit_vert_calculate { supper slower } {
	
	return [expr ($supper + $slower)/ 2.0 ]
}


proc white_beam_slit_upper_calculate { sv svg } {

	return [expr $sv + $svg / 2.0 ]
}


proc white_beam_slit_lower_calculate { sv svg } {

	return [expr $sv - $svg / 2.0 ]
}

