# white_beam_slit_vert_gap.tcl


proc white_beam_slit_vert_gap_initialize {} {

	# specify children devices
	set_children white_beam_slit_upper white_beam_slit_lower
	set_siblings white_beam_slit_vert
}


proc white_beam_slit_vert_gap_move { new_white_beam_slit_vert_gap } {
	#global namespace variables
	global gDevice

	# global variables
	variable white_beam_slit_vert

	set new_white_beam_slit_upper [white_beam_slit_upper_calculate $gDevice(white_beam_slit_vert,target) $new_white_beam_slit_vert_gap]
	set new_white_beam_slit_lower [white_beam_slit_lower_calculate $gDevice(white_beam_slit_vert,target) $new_white_beam_slit_vert_gap]

    assertMotorLimit white_beam_slit_upper $new_white_beam_slit_upper
	assertMotorLimit white_beam_slit_lower  $new_white_beam_slit_lower

	# move the two motors
	move white_beam_slit_upper to $new_white_beam_slit_upper
	move white_beam_slit_lower to $new_white_beam_slit_lower

	# wait for the moves to complete
	wait_for_devices white_beam_slit_upper white_beam_slit_lower
}


proc white_beam_slit_vert_gap_set { new_white_beam_slit_vert_gap } {

	# global variables
	variable white_beam_slit_vert
	variable white_beam_slit_upper
	variable white_beam_slit_lower

	# set the two motors
	set white_beam_slit_upper [white_beam_slit_upper_calculate $white_beam_slit_vert $new_white_beam_slit_vert_gap]
	set white_beam_slit_lower [white_beam_slit_lower_calculate $white_beam_slit_vert $new_white_beam_slit_vert_gap]
}


proc white_beam_slit_vert_gap_update {} {

	# global variables
	variable white_beam_slit_upper
	variable white_beam_slit_lower

	# calculate from real motor positions and motor parameters
	return [white_beam_slit_vert_gap_calculate $white_beam_slit_upper $white_beam_slit_lower]
}


proc white_beam_slit_vert_gap_calculate { s1upper s1lower } {
	
	return [expr $s1upper - $s1lower ]
}

