# detector_roll.tcl


proc detector_roll_initialize {} {
	
	# specify children devices
	set_children table_roll 
}


proc detector_roll_move { new_detector_roll } {

	# move table_roll
	move table_roll to [expr $new_detector_roll]

	# wait for the moves to complete
	wait_for_devices table_roll
}


proc detector_roll_set { new_detector_roll} {

	# global variables
	variable table_roll

	# set motors positions
	set table_roll [expr $new_detector_roll]
}


proc detector_roll_update {} {

	# global variables
	variable table_roll

	# calculate from real motor positions and motor parameters
	return [detector_roll_calculate $table_roll]
}


proc detector_roll_calculate { ma } {

	return [expr $ma]
}
