# detector_vert.tcl


proc detector_vert_initialize {} {
	
	# specify children devices
	set_children mono_angle asymmetric_cut
}


proc detector_vert_move { new_detector_vert } {

	# global variables
	variable asymmetric_cut

	# move mono_angle
	move mono_angle to [expr $new_detector_vert + $asymmetric_cut]

	# wait for the moves to complete
	wait_for_devices mono_angle
}


proc detector_vert_set { new_detector_vert} {

	# global variables
	variable asymmetric_cut
	variable mono_angle

	# move the two motors
	set mono_angle [expr $new_detector_vert + $asymmetric_cut]
}


proc detector_vert_update {} {

	# global variables
	variable mono_angle
	variable asymmetric_cut

	# calculate from real motor positions and motor parameters
	return [detector_vert_calculate $mono_angle $asymmetric_cut]
}


proc detector_vert_calculate { ma ac } {

	return [expr $ma - $ac]
}
