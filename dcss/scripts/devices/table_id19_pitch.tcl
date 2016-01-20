# table_pitch.tcl


proc table_pitch_initialize {} {
	
	# specify children devices
	set_children table_vert_1 table_vert_2 table_vert_3
	set_siblings table__vert table_roll
}


proc table_pitch_move { new_table_pitch } {
	#global 
	global gDevice

	# global variables
	variable table_vert
	variable table_roll
	variable table_vert_1
	variable table_vert_2
	variable table_vert_3

	# move the two motors
	move table_vert_1 to [calculate_table_vert_1 $gDevice(table_vert,target) $new_table_pitch $gDevice(table_roll,target)]
	move table_vert_2 to [calculate_table_vert_2 $gDevice(table_vert,target) $new_table_pitch $gDevice(table_roll,target)]
	move table_vert_3 to [calculate_table_vert_3 $gDevice(table_vert,target) $new_table_pitch $gDevice(table_roll,target)]

	# wait for the moves to complete
	wait_for_devices table_vert_1 table_vert_2 table_vert_3
}


proc table_pitch_set { new_table_pitch } {

	# global variables
	variable table_vert_1
	variable table_vert_2
	variable table_vert_3
        variable table_roll
	variable table_vert

	# move the two motors
	set table_vert_1 [calculate_table_vert_1 $table_vert $new_table_pitch $table_roll]
	set table_vert_2 [calculate_table_vert_2 $table_vert $new_table_pitch $table_roll]
	set table_vert_3 [calculate_table_vert_2 $table_vert $new_table_pitch $table_roll]
}


proc table_pitch_update {} {

	# global variables
	variable table_vert_1
	variable table_vert_2
	variable table_vert_3

	# calculate from real motor positions and motor parameters
	return [table_pitch_calculate $table_vert_1 $table_vert_2 $table_vert_3]
}


proc table_pitch_calculate { tv1 tv2 tv3 } {


	return [expr (0.00096*$tv1 - 0.00048*$tv2 -0.00048*$tv3)*180/3.1415926]
}

