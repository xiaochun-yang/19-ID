# mirror_slit_vert.tcl


proc mirror_slit_vert_initialize {} {

	# specify children devices
	set_children mirror_slit_upper mirror_slit_lower
	set_siblings mirror_slit_vert_gap
}


proc mirror_slit_vert_move { new_mirror_slit_vert } {
	#global namespace variables
	global gDevice

	# global variables
	variable mirror_slit_vert_gap
	variable mirror_slit_vert

	# calculate new positions of the two motors
	set new_mirror_slit_upper [mirror_slit_upper_calculate $new_mirror_slit_vert $gDevice(mirror_slit_vert_gap,target)]
	set new_mirror_slit_lower [mirror_slit_lower_calculate $new_mirror_slit_vert $gDevice(mirror_slit_vert_gap,target)]

    assertMotorLimit mirror_slit_upper $new_mirror_slit_upper
	assertMotorLimit mirror_slit_lower  $new_mirror_slit_lower

	# move motors in order that avoids collisions
	if { $new_mirror_slit_vert > $mirror_slit_vert } {
		move mirror_slit_upper to $new_mirror_slit_upper
		move mirror_slit_lower to $new_mirror_slit_lower
	} else {
		move mirror_slit_lower to $new_mirror_slit_lower
		move mirror_slit_upper to $new_mirror_slit_upper
	}

	# wait for the moves to complete
	wait_for_devices mirror_slit_upper mirror_slit_lower
}


proc mirror_slit_vert_set { new_mirror_slit_vert } {

	# global variables
	variable mirror_slit_vert_gap
	variable mirror_slit_upper
	variable mirror_slit_lower

	# move the two motors
	set mirror_slit_upper  [mirror_slit_upper_calculate $new_mirror_slit_vert $mirror_slit_vert_gap]
	set mirror_slit_lower  [mirror_slit_lower_calculate $new_mirror_slit_vert $mirror_slit_vert_gap]
}


proc mirror_slit_vert_update {} {

	# global variables
	variable mirror_slit_upper
	variable mirror_slit_lower

	# calculate from real motor positions and motor parameters
	return [mirror_slit_vert_calculate $mirror_slit_upper $mirror_slit_lower]
}


proc mirror_slit_vert_calculate { supper slower } {
	
	return [expr ($supper + $slower)/ 2.0 ]
}


proc mirror_slit_upper_calculate { sv svg } {

	return [expr $sv + $svg / 2.0 ]
}


proc mirror_slit_lower_calculate { sv svg } {

	return [expr $sv - $svg / 2.0 ]
}

