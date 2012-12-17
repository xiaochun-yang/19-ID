# table_yaw.tcl


proc table_yaw_initialize {} {

	# specify children devices
	set_children table_horz_1 table_horz_2 table_pivot_z table_h2_z
	set_siblings table_horz
}


proc table_yaw_move { new_table_yaw } {

	# move the two motors
	move table_horz_1 to [calculate_table_horz_1 $new_table_yaw]
	move table_horz_2 to [calculate_table_horz_2 $new_table_yaw]

	# wait for the moves to complete
	wait_for_devices table_horz_1 table_horz_2
}


proc table_yaw_set { new_table_yaw } {

	# global variables
	variable table_horz_1
	variable table_horz_2

	# set the two motors
	set table_horz_1 [calculate_table_horz_1 $new_table_yaw]
	set table_horz_2 [calculate_table_horz_2 $new_table_yaw]
}


proc table_yaw_update {} {

	# global variables
	variable table_horz_2
	variable table_h2_z

	# calculate from real motor positions and motor parameters
	return [table_yaw_calculate 0 $table_horz_2 0 $table_h2_z]
}


proc table_yaw_calculate { th1 th2 tpz th2z} {

	if { abs($th2z) > 0.0001 }  {
		return [expr [deg [expr atan( $th2 / $th2z ) ]]]
	} else {
		return 0.0
	}
}


proc calculate_table_horz_1 { ty } {

	# global variables
	variable table_pivot_z
	variable table_horz

	print "Requested yaw = $ty"
	print "Current table_pivot_z = $table_pivot_z"

	return [expr $table_horz - $table_pivot_z * tan( [rad $ty] ) ]
}


proc calculate_table_horz_2 { ty } {

	# global variables
	variable table_h2_z

	return [expr $table_h2_z * tan( [rad $ty] ) ]
}
