# PREFIX_vert.tcl


proc PREFIX_vert_initialize {} {
	# specify children devices
	set_children PREFIX_vert_1 PREFIX_vert_2 PREFIX_v1_z PREFIX_v2_z PREFIX_pivot_z
	set_siblings PREFIX_pitch
}


proc PREFIX_vert_move { new_PREFIX_vert } {
	#global 
	global gDevice

	# global variables
	variable PREFIX_pitch

	#calculate new positions of the two motors
	set new_PREFIX_vert_1 [calculate_PREFIX_vert_1 $new_PREFIX_vert $gDevice(PREFIX_pitch,target)]
	set new_PREFIX_vert_2 [calculate_PREFIX_vert_2 $new_PREFIX_vert $gDevice(PREFIX_pitch,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit PREFIX_vert_1 $new_PREFIX_vert_1
	assertMotorLimit PREFIX_vert_2 $new_PREFIX_vert_2

	# move the two motors
	move PREFIX_vert_1 to $new_PREFIX_vert_1
	move PREFIX_vert_2 to $new_PREFIX_vert_2

	# wait for the moves to complete
	wait_for_devices PREFIX_vert_1 PREFIX_vert_2
}


proc PREFIX_vert_set { new_PREFIX_vert } {

	# global variables
	variable PREFIX_vert_1
	variable PREFIX_vert_2
	variable PREFIX_pitch

	# move the two motors
	set PREFIX_vert_1 [calculate_PREFIX_vert_1 $new_PREFIX_vert $PREFIX_pitch]
	set PREFIX_vert_2 [calculate_PREFIX_vert_2 $new_PREFIX_vert $PREFIX_pitch]
}


proc PREFIX_vert_update {} {

	# global variables
	variable PREFIX_vert_1
	variable PREFIX_vert_2
	variable PREFIX_v1_z
	variable PREFIX_v2_z
	variable PREFIX_pivot_z

	# calculate from real motor positions and motor parameters
	return [PREFIX_vert_calculate $PREFIX_vert_1 $PREFIX_vert_2 $PREFIX_v1_z $PREFIX_v2_z $PREFIX_pivot_z]
}


proc PREFIX_vert_calculate { tv1 tv2 tv1z tv2z tpvz } {

	# calculate distance between tv1 and tv2
	set tv1_tv2_distance [expr $tv1z - $tv2z ]

	if { abs($tv1_tv2_distance) > 0.0001 }  {
		set tp [expr atan(($tv2 - $tv1) / $tv1_tv2_distance) ]
		return [expr $tv1 - ($tpvz - $tv1z) * tan($tp) ]
	} else {
		return 0
	}
}


proc calculate_PREFIX_vert_1 { tv tp } {

	# global variables
	variable PREFIX_pivot
	variable PREFIX_v1_z
	variable PREFIX_pivot_z
	
	return [expr $tv + ( $PREFIX_v1_z - $PREFIX_pivot_z ) * tan([rad $tp]) ]
}


proc calculate_PREFIX_vert_2 { tv tp } {
	
	# global variables
	variable PREFIX_v2_z
	variable PREFIX_pivot_z
	
	return [expr $tv + ( $PREFIX_v2_z - $PREFIX_pivot_z ) * tan([rad $tp])]
}



