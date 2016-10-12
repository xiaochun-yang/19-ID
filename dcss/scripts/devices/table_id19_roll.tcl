# table_roll.tcl


proc table_roll_initialize {} {
	
	# specify children devices
	set_children table_vert_2 table_vert_3
	set_siblings table_vert table_pitch
}


proc table_roll_move { new_table_roll } {
	#global 
	global gDevice

	# global variables
	variable table_vert
	variable table_pitch
	variable table_vert_2
	variable table_vert_3

	# move the two motors
	move table_vert_2 to [calculate_table_vert_2 $gDevice(table_vert,target) $gDevice(table_pitch,target) $new_table_roll]
	move table_vert_3 to [calculate_table_vert_3 $gDevice(table_vert,target) $gDevice(table_pitch,target) $new_table_roll]

	# wait for the moves to complete
	wait_for_devices table_vert_2 table_vert_3
}


proc table_roll_set { new_table_roll } {

	# global variables
	variable table_vert_2
	variable table_vert_3
        variable table_pitch
	variable table_vert

	# move the two motors
	set table_vert_2 [calculate_table_vert_2 $table_vert $table_pitch $new_table_roll]
	set table_vert_3 [calculate_table_vert_3 $table_vert $table_pitch $new_table_roll]
}


proc table_roll_update {} {

	# global variables
	variable table_vert_2
	variable table_vert_3

	# calculate from real motor positions and motor parameters
	return [table_roll_calculate $table_vert_2 $table_vert_3]
}


proc table_roll_calculate { tv2 tv3 } {


	return [expr ($tv2 - $tv3)*180/3.1415926/733]
}


