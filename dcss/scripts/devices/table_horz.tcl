# table_horz.tcl


proc table_horz_initialize {} {

	# specify children devices
	set_children table_horz_1 table_horz_2 table_pivot_z table_h2_z
	set_siblings table_yaw
}


proc table_horz_move { new_table_horz } {

	# global variables
	variable table_horz
	variable table_horz_1

	# move the two motors
	move table_horz_1 to [expr $table_horz_1 + $new_table_horz - $table_horz ]

	# wait for the moves to complete
	wait_for_devices table_horz_1 
}


proc table_horz_set { new_table_horz } {

	# global variables
	variable table_horz	
	variable table_horz_1

	# set the two motors
	set table_horz_1 [expr $table_horz_1 + $new_table_horz - $table_horz ]
}


proc table_horz_update {} {

	# global variables
	variable table_horz_1
	variable table_horz_2
	variable table_pivot_z
	variable table_h2_z

	# calculate from real motor positions and motor parameters
	return [table_horz_calculate $table_horz_1 $table_horz_2 $table_pivot_z $table_h2_z]
}


proc table_horz_calculate { th1 th2 tpz th2z} {

	if { abs($th2z) > 0.0001 }  {
		set ty [expr [expr atan( $th2 / $th2z ) ]]
		return [expr $th1 + $tpz * tan($ty)]
	} else {
		return 0.0
	}
}
