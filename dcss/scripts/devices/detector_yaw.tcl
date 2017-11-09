# detector_yaw.tcl


proc detector_yaw_initialize {} {
	
	# specify children devices
	set_children table_yaw 
}


proc detector_yaw_move { new_detector_yaw } {

	# move table_yaw
	move table_yaw to [expr $new_detector_yaw]

	# wait for the moves to complete
	wait_for_devices table_yaw
}


proc detector_yaw_set { new_detector_yaw} {

	# global variables
	variable table_yaw

	# set motors positions
	set table_yaw [expr $new_detector_yaw]
}


proc detector_yaw_update {} {

	# global variables
	variable table_yaw

	# calculate from real motor positions and motor parameters
	return [detector_yaw_calculate $table_yaw]
}


proc detector_yaw_calculate { ma } {

	return [expr $ma]
}
