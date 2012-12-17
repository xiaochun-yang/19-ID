# toroid_vert.tcl


proc toroid_vert_initialize {} {

	# specify children devices
	set_children toroid_vert_1 toroid_vert_2 toroid_v1_z toroid_v2_z toroid_pivot_z
	set_siblings toroid_pitch
}


proc toroid_vert_move { new_toroid_vert } {
	#global 
	global gDevice

	# global variables
	variable toroid_pitch

	#calculate new positions of the two motors
	set new_toroid_vert_1 [calculate_toroid_vert_1 $new_toroid_vert $gDevice(toroid_pitch,target)]
	set new_toroid_vert_2 [calculate_toroid_vert_2 $new_toroid_vert $gDevice(toroid_pitch,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit toroid_vert_1 $new_toroid_vert_1
	assertMotorLimit toroid_vert_2 $new_toroid_vert_2

	# move the two motors
	move toroid_vert_1 to $new_toroid_vert_1
	move toroid_vert_2 to $new_toroid_vert_2

	# wait for the moves to complete
	wait_for_devices toroid_vert_1 toroid_vert_2
}


proc toroid_vert_set { new_toroid_vert } {

	# global variables
	variable toroid_vert_1
	variable toroid_vert_2
	variable toroid_pitch

	# move the two motors
	set toroid_vert_1 [calculate_toroid_vert_1 $new_toroid_vert $toroid_pitch]
	set toroid_vert_2 [calculate_toroid_vert_2 $new_toroid_vert $toroid_pitch]
}


proc toroid_vert_update {} {

	# global variables
	variable toroid_vert_1
	variable toroid_vert_2
	variable toroid_v1_z
	variable toroid_v2_z
	variable toroid_pivot_z

	# calculate from real motor positions and motor parameters
	return [toroid_vert_calculate $toroid_vert_1 $toroid_vert_2 $toroid_v1_z $toroid_v2_z $toroid_pivot_z]
}


proc toroid_vert_calculate { tv1 tv2 tv1z tv2z tpvz } {

	# calculate distance between tv1 and tv2
	set tv1_tv2_distance [expr $tv1z - $tv2z ]

	if { abs($tv1_tv2_distance) > 0.0001 }  {
		set tp [expr atan(($tv2 - $tv1) / $tv1_tv2_distance) ]
		return [expr $tv1 - ($tpvz - $tv1z) * tan($tp) ]
	} else {
		return 0
	}
}


proc calculate_toroid_vert_1 { tv tp } {

	# global variables
	variable toroid_pivot
	variable toroid_v1_z
	variable toroid_pivot_z
	
	return [expr $tv + ( $toroid_v1_z - $toroid_pivot_z ) * tan([rad $tp]) ]
}


proc calculate_toroid_vert_2 { tv tp } {
	
	# global variables
	variable toroid_v2_z
	variable toroid_pivot_z
	
	return [expr $tv + ( $toroid_v2_z - $toroid_pivot_z ) * tan([rad $tp])]
}



