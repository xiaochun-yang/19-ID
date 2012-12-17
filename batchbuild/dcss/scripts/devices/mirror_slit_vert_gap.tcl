# mirror_slit_vert_gap.tcl


proc mirror_slit_vert_gap_initialize {} {

	# specify children devices
	set_children mirror_slit_upper mirror_slit_lower
	set_siblings mirror_slit_vert
}


proc mirror_slit_vert_gap_move { new_mirror_slit_vert_gap } {
	#global namespace variables
	global gDevice

	# global variables
	variable mirror_slit_vert

	set new_mirror_slit_upper [mirror_slit_upper_calculate $gDevice(mirror_slit_vert,target) $new_mirror_slit_vert_gap]
	set new_mirror_slit_lower [mirror_slit_lower_calculate $gDevice(mirror_slit_vert,target) $new_mirror_slit_vert_gap]

    assertMotorLimit mirror_slit_upper $new_mirror_slit_upper
	assertMotorLimit mirror_slit_lower  $new_mirror_slit_lower

	# move the two motors
	move mirror_slit_upper to $new_mirror_slit_upper
	move mirror_slit_lower to $new_mirror_slit_lower

	# wait for the moves to complete
	wait_for_devices mirror_slit_upper mirror_slit_lower
}


proc mirror_slit_vert_gap_set { new_mirror_slit_vert_gap } {

	# global variables
	variable mirror_slit_vert
	variable mirror_slit_upper
	variable mirror_slit_lower

	# set the two motors
	set mirror_slit_upper [mirror_slit_upper_calculate $mirror_slit_vert $new_mirror_slit_vert_gap]
	set mirror_slit_lower [mirror_slit_lower_calculate $mirror_slit_vert $new_mirror_slit_vert_gap]
}


proc mirror_slit_vert_gap_update {} {

	# global variables
	variable mirror_slit_upper
	variable mirror_slit_lower

	# calculate from real motor positions and motor parameters
	return [mirror_slit_vert_gap_calculate $mirror_slit_upper $mirror_slit_lower]
}


proc mirror_slit_vert_gap_calculate { s1upper s1lower } {
	
	return [expr $s1upper - $s1lower ]
}

