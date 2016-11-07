# analyzer_roll.tcl


proc analyzer_roll_initialize {} {
	
	# specify children devices
	set_children analyzer_vert_2 analyzer_vert_3
	set_siblings analyzer_vert analyzer_pitch
}


proc analyzer_roll_move { new_analyzer_roll } {
	#global 
	global gDevice

	# global variables
	variable analyzer_vert
	variable analyzer_pitch
	variable analyzer_vert_2
	variable analyzer_vert_3

	# move the two motors
	move analyzer_vert_2 to [calculate_analyzer_vert_2 $gDevice(analyzer_vert,target) $gDevice(analyzer_pitch,target) $new_analyzer_roll]
	move analyzer_vert_3 to [calculate_analyzer_vert_3 $gDevice(analyzer_vert,target) $gDevice(analyzer_pitch,target) $new_analyzer_roll]

	# wait for the moves to complete
	wait_for_devices analyzer_vert_2 analyzer_vert_3
}


proc analyzer_roll_set { new_analyzer_roll } {

	# global variables
	variable analyzer_vert_2
	variable analyzer_vert_3
        variable analyzer_pitch
	variable analyzer_vert

	# move the two motors
	set analyzer_vert_2 [calculate_analyzer_vert_2 $analyzer_vert $analyzer_pitch $new_analyzer_roll]
	set analyzer_vert_3 [calculate_analyzer_vert_3 $analyzer_vert $analyzer_pitch $new_analyzer_roll]
}


proc analyzer_roll_update {} {

	# global variables
	variable analyzer_vert_2
	variable analyzer_vert_3

	# calculate from real motor positions and motor parameters
	return [analyzer_roll_calculate $analyzer_vert_2 $analyzer_vert_3]
}


proc analyzer_roll_calculate { tv2 tv3 } {


	return [expr ($tv2 - $tv3)*180/3.1415926/733]
}


