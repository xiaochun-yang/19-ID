# detector_vert.tcl


proc detector_vert_initialize {} {
	
	# specify children devices
	set_children table_vert 
}


proc detector_vert_move { new_detector_vert } {

	# move table_vert
	move table_vert to [expr $new_detector_vert]

	# wait for the moves to complete
	wait_for_devices table_vert
}


proc detector_vert_set { new_detector_vert} {

	# global variables
	variable table_vert

	# set motors positions
	set table_vert [expr $new_detector_vert]
}


proc detector_vert_update {} {

	# global variables
	variable table_vert

	# calculate from real motor positions and motor parameters
	return [detector_vert_calculate $table_vert]
}


proc detector_vert_calculate { ma } {

	return [expr $ma]
}
