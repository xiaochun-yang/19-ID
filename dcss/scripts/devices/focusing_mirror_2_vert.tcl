# focusing_mirror_2_vert.tcl


proc focusing_mirror_2_vert_initialize {} {

	# specify children devices
	set_children focusing_mirror_2_vert_1 focusing_mirror_2_vert_2 focusing_mirror_2_v1_z focusing_mirror_2_v2_z focusing_mirror_2_pivot_z
	set_siblings focusing_mirror_2_pitch
}


proc focusing_mirror_2_vert_move { new_focusing_mirror_2_vert } {
	#global 
	global gDevice

	# global variables
	variable focusing_mirror_2_pitch

	#calculate new positions of the two motors
	set new_focusing_mirror_2_vert_1 [focusing_mirror_2_vert_1_calculate $new_focusing_mirror_2_vert $gDevice(focusing_mirror_2_pitch,target)]
	set new_focusing_mirror_2_vert_2 [focusing_mirror_2_vert_2_calculate $new_focusing_mirror_2_vert $gDevice(focusing_mirror_2_pitch,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit focusing_mirror_2_vert_1 $new_focusing_mirror_2_vert_1
	assertMotorLimit focusing_mirror_2_vert_2 $new_focusing_mirror_2_vert_2

	# move the two motors
	move focusing_mirror_2_vert_1 to $new_focusing_mirror_2_vert_1
	move focusing_mirror_2_vert_2 to $new_focusing_mirror_2_vert_2

	# wait for the moves to complete
	wait_for_devices focusing_mirror_2_vert_1 focusing_mirror_2_vert_2
}


proc focusing_mirror_2_vert_set { new_focusing_mirror_2_vert } {

	# global variables
	variable focusing_mirror_2_vert_1
	variable focusing_mirror_2_vert_2
	variable focusing_mirror_2_pitch

	# move the two motors
	set focusing_mirror_2_vert_1 [focusing_mirror_2_vert_1_calculate $new_focusing_mirror_2_vert $focusing_mirror_2_pitch]
	set focusing_mirror_2_vert_2 [focusing_mirror_2_vert_2_calculate $new_focusing_mirror_2_vert $focusing_mirror_2_pitch]
}


proc focusing_mirror_2_vert_update {} {

	# global variables
	variable focusing_mirror_2_vert_1
	variable focusing_mirror_2_vert_2
	variable focusing_mirror_2_v1_z
	variable focusing_mirror_2_v2_z
	variable focusing_mirror_2_pivot_z

	# calculate from real motor positions and motor parameters
	return [focusing_mirror_2_vert_calculate $focusing_mirror_2_vert_1 $focusing_mirror_2_vert_2 $focusing_mirror_2_v1_z $focusing_mirror_2_v2_z $focusing_mirror_2_pivot_z]
}


proc focusing_mirror_2_vert_calculate { tv1 tv2 tv1z tv2z tpvz } {

	# calculate distance between tv1 and tv2
	set tv1_tv2_distance [expr $tv1z - $tv2z ]

	if { abs($tv1_tv2_distance) > 0.0001 }  {
		set tp [expr atan(($tv2 - $tv1) / $tv1_tv2_distance) ]
		return [expr $tv1 - ($tpvz - $tv1z) * tan($tp) ]
	} else {
		return 0
	}
}


proc focusing_mirror_2_vert_1_calculate { tv tp } {

	# global variables
	variable focusing_mirror_2_pivot
	variable focusing_mirror_2_v1_z
	variable focusing_mirror_2_pivot_z
	
	return [expr $tv + ( $focusing_mirror_2_v1_z - $focusing_mirror_2_pivot_z ) * tan([rad $tp]) ]
}


proc focusing_mirror_2_vert_2_calculate { tv tp } {
	
	# global variables
	variable focusing_mirror_2_v2_z
	variable focusing_mirror_2_pivot_z
	
	return [expr $tv + ( $focusing_mirror_2_v2_z - $focusing_mirror_2_pivot_z ) * tan([rad $tp])]
}



