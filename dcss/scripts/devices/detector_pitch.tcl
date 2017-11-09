# detector_pitch.tcl


proc detector_pitch_initialize {} {
	
	# specify children devices
	set_children table_pitch 
}


proc detector_pitch_move { new_detector_pitch } {

	# move table_pitch
	move table_pitch to [expr $new_detector_pitch]

	# wait for the moves to complete
	wait_for_devices table_pitch
}


proc detector_pitch_set { new_detector_pitch} {

	# global variables
	variable table_pitch

	# set motors positions
	set table_pitch [expr $new_detector_pitch]
}


proc detector_pitch_update {} {

	# global variables
	variable table_pitch

	# calculate from real motor positions and motor parameters
	return [detector_pitch_calculate $table_pitch]
}


proc detector_pitch_calculate { ma } {

	return [expr $ma]
}
