# focusing_mirror_2_pitch.tcl


proc focusing_mirror_2_pitch_initialize {} {
	
	# specify children devices
	set_children focusing_mirror_2_vert_1 focusing_mirror_2_vert_2 focusing_mirror_2_v1_z focusing_mirror_2_v2_z
	set_siblings focusing_mirror_2_vert
}


proc focusing_mirror_2_pitch_move { new_focusing_mirror_2_pitch } {
	#global 
	global gDevice

	# global variables
	variable focusing_mirror_2_vert

	# move the two motors
	move focusing_mirror_2_vert_1 to [focusing_mirror_2_vert_1_calculate $gDevice(focusing_mirror_2_vert,target) $new_focusing_mirror_2_pitch]
	move focusing_mirror_2_vert_2 to [focusing_mirror_2_vert_2_calculate $gDevice(focusing_mirror_2_vert,target) $new_focusing_mirror_2_pitch]

	# wait for the moves to complete
	wait_for_devices focusing_mirror_2_vert_1 focusing_mirror_2_vert_2
}


proc focusing_mirror_2_pitch_set { new_focusing_mirror_2_pitch } {

	# global variables
	variable focusing_mirror_2_vert_1
	variable focusing_mirror_2_vert_2
	variable focusing_mirror_2_vert

	# move the two motors
	set focusing_mirror_2_vert_1 [focusing_mirror_2_vert_1_calculate $focusing_mirror_2_vert $new_focusing_mirror_2_pitch]
	set focusing_mirror_2_vert_2 [focusing_mirror_2_vert_2_calculate $focusing_mirror_2_vert $new_focusing_mirror_2_pitch]
}


proc focusing_mirror_2_pitch_update {} {

	# global variables
	variable focusing_mirror_2_vert_1
	variable focusing_mirror_2_vert_2
	variable focusing_mirror_2_v1_z
	variable focusing_mirror_2_v2_z

	# calculate from real motor positions and motor parameters
	return [focusing_mirror_2_pitch_calculate $focusing_mirror_2_vert_1 $focusing_mirror_2_vert_2 $focusing_mirror_2_v1_z $focusing_mirror_2_v2_z]
}


proc focusing_mirror_2_pitch_calculate { tv1 tv2 tv1z tv2z } {

	set v1_v2_distance [expr $tv2z - $tv1z ]

	if { abs($v1_v2_distance) > 0.0001 }  {
		return [expr [deg [ expr atan( ($tv2 - $tv1) / $v1_v2_distance) ]]]
	} else {
		return 0.0
	}
}

