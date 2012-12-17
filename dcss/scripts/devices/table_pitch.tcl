# table_pitch.tcl


proc table_pitch_initialize {} {
	
	# specify children devices
	set_children table_vert_1 table_vert_2 table_v1_z table_v2_z
	set_siblings table_vert
}


proc table_pitch_move { new_table_pitch } {
	#global 
	global gDevice

	# global variables
	variable table_vert

	# move the two motors
	move table_vert_1 to [calculate_table_vert_1 $gDevice(table_vert,target) $new_table_pitch]
	move table_vert_2 to [calculate_table_vert_2 $gDevice(table_vert,target) $new_table_pitch]

	# wait for the moves to complete
	wait_for_devices table_vert_1 table_vert_2
}


proc table_pitch_set { new_table_pitch } {

	# global variables
	variable table_vert_1
	variable table_vert_2
	variable table_vert

	# move the two motors
	set table_vert_1 [calculate_table_vert_1 $table_vert $new_table_pitch]
	set table_vert_2 [calculate_table_vert_2 $table_vert $new_table_pitch]
}


proc table_pitch_update {} {

	# global variables
	variable table_vert_1
	variable table_vert_2
	variable table_v1_z
	variable table_v2_z

	# calculate from real motor positions and motor parameters
	return [table_pitch_calculate $table_vert_1 $table_vert_2 $table_v1_z $table_v2_z]
}


proc table_pitch_calculate { tv1 tv2 tv1z tv2z } {

	set v1_v2_distance [expr $tv2z - $tv1z ]

	if { abs($v1_v2_distance) > 0.0001 }  {
		return [expr [deg [ expr atan( ($tv2 - $tv1) / $v1_v2_distance) ]]]
	} else {
		return 0.0
	}
}

