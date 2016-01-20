# table_yaw.tcl


proc table_yaw_initialize {} {
	
	# specify children devices
	set_children table_horz_1 table_horz_2
	set_siblings table__horz
}


proc table_yaw_move { new_table_yaw } {
	#global 
	global gDevice

	# global variables
	variable table_horz
	variable table_horz_1
	variable table_horz_2

	# move the two motors
	move table_horz_1 to [calculate_table_horz_1 $gDevice(table_horz,target) $new_table_yaw]
	move table_horz_2 to [calculate_table_horz_2 $gDevice(table_horz,target) $new_table_yaw]

	# wait for the moves to complete
	wait_for_devices table_horz_1 table_horz_2
}


proc table_yaw_set { new_table_yaw } {

	# global variables
	variable table_horz_1
	variable table_horz_2
        variable table_horz

	# move the two motors
	set table_horz_1 [calculate_table_horz_1 $table_horz $new_table_yaw]
	set table_horz_2 [calculate_table_horz_2 $table_horz $new_table_yaw]
}


proc table_yaw_update {} {

	# global variables
	variable table_horz_1
	variable table_horz_2

	# calculate from real motor positions and motor parameters
	return [table_yaw_calculate $table_horz_1 $table_horz_2]
}


proc table_yaw_calculate { th1 th2 } {


	return [expr ($th1 - $th2)*180/3.14/804]
}

