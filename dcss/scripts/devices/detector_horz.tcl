# detector_horz.tcl


proc detector_horz_initialize {} {
	
	# specify children devices
	set_children table_horz 
}


proc detector_horz_move { new_detector_horz } {

	# move table_horz
	move table_horz to [expr $new_detector_horz]

	# wait for the moves to complete
	wait_for_devices table_horz
}


proc detector_horz_set { new_detector_horz} {

	# global variables
	variable table_horz

	# set motors positions
	set table_horz [expr $new_detector_horz]
}


proc detector_horz_update {} {

	# global variables
	variable table_horz

	# calculate from real motor positions and motor parameters
	return [detector_horz_calculate $table_horz]
}


proc detector_horz_calculate { ma } {

	return [expr $ma]
}
