# table_nyx_roll.tcl


proc table_nyx_roll_initialize {} {
	
	# specify children devices
	set_children table_v2 table_v3
	set_siblings table__nyx_vert table_nyx_pitch
}


proc table_nyx_roll_move { new_table_nyx_roll } {
	#global 
	global gDevice

	# global variables
	variable table_nyx_vert
	variable table_nyx_pitch

	# move the two motors
	move table_v2 to [calculate_table_v2 $gDevice(table_nyx_vert,target) $gDevice(table_nyx_pitch target) $new_table_nyx_roll]
	move table_v3 to [calculate_table_v3 $gDevice(table_nyx_vert,target) $gDevice(table_nyx_pitch target) $new_table_nyx_roll]

	# wait for the moves to complete
	wait_for_devices table_v2 table_v3
}


proc table_nyx_roll_set { new_table_nyx_roll } {

	# global variables
	variable table_v2
	variable table_v3
        variable table_nyx_pitch
	variable table_nyx_vert

	# move the two motors
	set table_v2 [calculate_table_v2 $table_nyx_vert $table_nyx_pitch $new_table_nyx_roll]
	set table_v3 [calculate_table_v2 $table_nyx_vert $table_nyx_pitch $new_table_nyx_roll]
}


proc table_nyx_roll_update {} {

	# global variables
	variable table_v2
	variable table_v3

	# calculate from real motor positions and motor parameters
	return [table_nyx_roll_calculate $table_v2 $table_v3]
}


proc table_nyx_roll_calculate { tv2 tv3 } {


	return [expr ($tv2 - $tv3)*180/3.14/457]
}

