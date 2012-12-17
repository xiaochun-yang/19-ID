# table_vert.tcl


proc table_vert_initialize {} {

	# specify children devices
	set_children table_vert_1 table_vert_2 table_v1_z table_v2_z table_pivot_z
	set_siblings table_pitch
}


proc table_vert_move { new_table_vert } {
	#global 
	global gDevice

	# global variables
	variable table_pitch

	#calculate new positions of the two motors
	set new_table_vert_1 [calculate_table_vert_1 $new_table_vert $gDevice(table_pitch,target)]
	set new_table_vert_2 [calculate_table_vert_2 $new_table_vert $gDevice(table_pitch,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit table_vert_1 $new_table_vert_1
	assertMotorLimit table_vert_2 $new_table_vert_2

	# move the two motors
	move table_vert_1 to $new_table_vert_1
	move table_vert_2 to $new_table_vert_2

	# wait for the moves to complete
	wait_for_devices table_vert_1 table_vert_2
}


proc table_vert_set { new_table_vert } {

	# global variables
	variable table_vert_1
	variable table_vert_2
	variable table_pitch

	# move the two motors
	set table_vert_1 [calculate_table_vert_1 $new_table_vert $table_pitch]
	set table_vert_2 [calculate_table_vert_2 $new_table_vert $table_pitch]
}


proc table_vert_update {} {

	# global variables
	variable table_vert_1
	variable table_vert_2
	variable table_v1_z
	variable table_v2_z
	variable table_pivot_z

	# calculate from real motor positions and motor parameters
	return [table_vert_calculate $table_vert_1 $table_vert_2 $table_v1_z $table_v2_z $table_pivot_z]
}


proc table_vert_calculate { tv1 tv2 tv1z tv2z tpvz } {

	# calculate distance between tv1 and tv2
	set tv1_tv2_distance [expr $tv1z - $tv2z ]

	if { abs($tv1_tv2_distance) > 0.0001 }  {
		set tp [expr atan(($tv2 - $tv1) / $tv1_tv2_distance) ]
		return [expr $tv1 - ($tpvz - $tv1z) * tan($tp) ]
	} else {
		return 0
	}
}


proc calculate_table_vert_1 { tv tp } {

	# global variables
	variable table_pivot
	variable table_v1_z
	variable table_pivot_z
	
	return [expr $tv + ( $table_v1_z - $table_pivot_z ) * tan([rad $tp]) ]
}


proc calculate_table_vert_2 { tv tp } {
	
	# global variables
	variable table_v2_z
	variable table_pivot_z
	
	return [expr $tv + ( $table_v2_z - $table_pivot_z ) * tan([rad $tp])]
}



