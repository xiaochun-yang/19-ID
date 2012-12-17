# toroid_pitch.tcl


proc toroid_pitch_initialize {} {
	
	# specify children devices
	set_children toroid_vert_1 toroid_vert_2 toroid_v1_z toroid_v2_z
	set_siblings toroid_vert
}


proc toroid_pitch_move { new_toroid_pitch } {
	#global 
	global gDevice

	# global variables
	variable toroid_vert

	# move the two motors
	move toroid_vert_1 to [calculate_toroid_vert_1 $gDevice(toroid_vert,target) $new_toroid_pitch]
	move toroid_vert_2 to [calculate_toroid_vert_2 $gDevice(toroid_vert,target) $new_toroid_pitch]

	# wait for the moves to complete
	wait_for_devices toroid_vert_1 toroid_vert_2
}


proc toroid_pitch_set { new_toroid_pitch } {

	# global variables
	variable toroid_vert_1
	variable toroid_vert_2
	variable toroid_vert

	# move the two motors
	set toroid_vert_1 [calculate_toroid_vert_1 $toroid_vert $new_toroid_pitch]
	set toroid_vert_2 [calculate_toroid_vert_2 $toroid_vert $new_toroid_pitch]
}


proc toroid_pitch_update {} {

	# global variables
	variable toroid_vert_1
	variable toroid_vert_2
	variable toroid_v1_z
	variable toroid_v2_z

	# calculate from real motor positions and motor parameters
	return [toroid_pitch_calculate $toroid_vert_1 $toroid_vert_2 $toroid_v1_z $toroid_v2_z]
}


proc toroid_pitch_calculate { tv1 tv2 tv1z tv2z } {

	set v1_v2_distance [expr $tv2z - $tv1z ]

	if { abs($v1_v2_distance) > 0.0001 }  {
		return [expr [deg [ expr atan( ($tv2 - $tv1) / $v1_v2_distance) ]]]
	} else {
		return 0.0
	}
}

