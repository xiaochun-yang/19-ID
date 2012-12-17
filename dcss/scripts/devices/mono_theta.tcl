# mono_theta.tcl


proc mono_theta_initialize {} {
	
	# specify children devices
	set_children mono_angle asymmetric_cut
}


proc mono_theta_move { new_mono_theta } {

	# global variables
	variable asymmetric_cut

	# move mono_angle
	move mono_angle to [expr $new_mono_theta + $asymmetric_cut]

	# wait for the moves to complete
	wait_for_devices mono_angle
}


proc mono_theta_set { new_mono_theta} {

	# global variables
	variable asymmetric_cut
	variable mono_angle

	# move the two motors
	set mono_angle [expr $new_mono_theta + $asymmetric_cut]
}


proc mono_theta_update {} {

	# global variables
	variable mono_angle
	variable asymmetric_cut

	# calculate from real motor positions and motor parameters
	return [mono_theta_calculate $mono_angle $asymmetric_cut]
}


proc mono_theta_calculate { ma ac } {

	return [expr $ma - $ac]
}
