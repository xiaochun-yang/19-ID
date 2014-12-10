# table_pitch.tcl


proc table_nyx_pitch_initialize {} {
	
	# specify children devices
	set_children table_v1 table_v2 table_v3
	set_siblings table__nyx_vert table_nyx_roll
}


proc table_nyx_pitch_move { new_table_nyx_pitch } {
	#global 
	global gDevice

	# global variables
	variable table_nyx_vert
	variable table_nyx_roll

	# move the two motors
	move table_v1 to [calculate_table_v1 $gDevice(table_nyx_vert,target) $new_table_nyx_pitch $gDevice(table_nyx_roll,target)]
	move table_v2 to [calculate_table_v2 $gDevice(table_nyx_vert,target) $new_table_nyx_pitch $gDevice(table_nyx_roll,target)]
	move table_v3 to [calculate_table_v3 $gDevice(table_nyx_vert,target) $new_table_nyx_pitch $gDevice(table_nyx_roll,target)]

	# wait for the moves to complete
	wait_for_devices table_v1 table_v2 table_v3
}


proc table_nyx_pitch_set { new_table_nyx_pitch } {

	# global variables
	variable table_v1
	variable table_v2
	variable table_v3
        variable table_nyx_roll
	variable table_nyx_vert

	# move the two motors
	set table_v1 [calculate_table_v1 $table_nyx_vert $new_table_nyx_pitch $table_nyx_roll]
	set table_v2 [calculate_table_v2 $table_nyx_vert $new_table_nyx_pitch $table_nyx_roll]
	set table_v3 [calculate_table_v2 $table_nyx_vert $new_table_nyx_pitch $table_nyx_roll]
}


proc table_pitch_update {} {

	# global variables
	variable table_v1
	variable table_v2
	variable table_v3

	# calculate from real motor positions and motor parameters
	return [table_nyx_pitch_calculate $table_v1 $table_v2 $table_v3]
}


proc table_nyx_pitch_calculate { tv1 tv2 tv3 } {


	return [expr (0.0347*$tv1 - 0.0174*$tv2 -0.0174*$tv3)]
}

