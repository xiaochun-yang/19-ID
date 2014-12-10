# table_nyx_yaw.tcl


proc table_nyx_yaw_initialize {} {
	
	# specify children devices
	set_children table_h1 table_h2
	set_siblings table__nyx_horz
}


proc table_nyx_yaw_move { new_table_nyx_yaw } {
	#global 
	global gDevice

	# global variables
	variable table_nyx_horz

	# move the two motors
	move table_h1 to [calculate_table_h1 $gDevice(table_nyx_horz,target) $new_table_nyx_yaw]
	move table_h2 to [calculate_table_h2 $gDevice(table_nyx_horz,target) $new_table_nyx_yaw]

	# wait for the moves to complete
	wait_for_devices table_h1 table_h2
}


proc table_nyx_yaw_set { new_table_nyx_yaw } {

	# global variables
	variable table_h1
	variable table_h2
        variable table_nyx_horz

	# move the two motors
	set table_h1 [calculate_table_h1 $table_nyx_horz $new_table_nyx_yaw]
	set table_h2 [calculate_table_h2 $table_nyx_horz $new_table_nyx_yaw]
}


proc table_nyx_yaw_update {} {

	# global variables
	variable table_h1
	variable table_h2

	# calculate from real motor positions and motor parameters
	return [table_nyx_yaw_calculate $table_h1 $table_h2]
}


proc table_nyx_yaw_calculate { th1 th2 } {


	return [expr ($th1 - $th2)*180/3.14/1651]
}

