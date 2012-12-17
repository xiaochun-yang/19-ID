# mono_slit_vert_gap.tcl


proc mono_slit_vert_gap_initialize {} {

	# specify children devices
	set_children mono_slit_upper mono_slit_lower
	set_siblings mono_slit_vert
}


proc mono_slit_vert_gap_move { new_mono_slit_vert_gap } {
	#global 
	global gDevice

	# global variables
	variable mono_slit_vert

	# calculate new positions of the two motors
	set new_mono_slit_upper [mono_slit_upper_calculate $gDevice(mono_slit_vert,target) $new_mono_slit_vert_gap]
	set new_mono_slit_lower [mono_slit_lower_calculate $gDevice(mono_slit_vert,target) $new_mono_slit_vert_gap]

	
	#check to see if the move can be completed by the real motors
	assertMotorLimit mono_slit_upper $new_mono_slit_upper
	assertMotorLimit mono_slit_lower $new_mono_slit_lower

	# move the two motors
	move mono_slit_upper to $new_mono_slit_upper
	move mono_slit_lower to $new_mono_slit_lower
	
	# wait for the moves to complete
	wait_for_devices mono_slit_upper mono_slit_lower
}


proc mono_slit_vert_gap_set { new_mono_slit_vert_gap } {

	# global variables
	variable mono_slit_vert
	variable mono_slit_upper
	variable mono_slit_lower

	# set the two motors
	set mono_slit_upper [mono_slit_upper_calculate $mono_slit_vert $new_mono_slit_vert_gap]
	set mono_slit_lower [mono_slit_lower_calculate $mono_slit_vert $new_mono_slit_vert_gap]
}


proc mono_slit_vert_gap_update {} {

	# global variables
	variable mono_slit_upper
	variable mono_slit_lower

	# calculate from real motor positions and motor parameters
	return [mono_slit_vert_gap_calculate $mono_slit_upper $mono_slit_lower]
}


proc mono_slit_vert_gap_calculate { s1u s1l } {
	
	return [expr $s1u - $s1l ]
}

