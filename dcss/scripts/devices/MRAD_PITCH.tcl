# PREFIX_pitch.tcl

#######################
# UNITS: mrad
#######################

proc PREFIX_pitch_initialize {} {
	
	# specify children devices
	set_children PREFIX_vert_1 PREFIX_vert_2 PREFIX_v1_z PREFIX_v2_z
	set_siblings PREFIX_vert
}


proc PREFIX_pitch_move { new_PREFIX_pitch } {
	#global 
	global gDevice

	# global variables
	variable PREFIX_vert

	# move the two motors
	move PREFIX_vert_1 to [calculate_PREFIX_vert_1 $gDevice(PREFIX_vert,target) $new_PREFIX_pitch]
	move PREFIX_vert_2 to [calculate_PREFIX_vert_2 $gDevice(PREFIX_vert,target) $new_PREFIX_pitch]

	# wait for the moves to complete
	wait_for_devices PREFIX_vert_1 PREFIX_vert_2
}


proc PREFIX_pitch_set { new_PREFIX_pitch } {

	# global variables
	variable PREFIX_vert_1
	variable PREFIX_vert_2
	variable PREFIX_vert

	# move the two motors
	set PREFIX_vert_1 [calculate_PREFIX_vert_1 $PREFIX_vert $new_PREFIX_pitch]
	set PREFIX_vert_2 [calculate_PREFIX_vert_2 $PREFIX_vert $new_PREFIX_pitch]
}


proc PREFIX_pitch_update {} {

	# global variables
	variable PREFIX_vert_1
	variable PREFIX_vert_2
	variable PREFIX_v1_z
	variable PREFIX_v2_z

	# calculate from real motor positions and motor parameters
	return [PREFIX_pitch_calculate $PREFIX_vert_1 $PREFIX_vert_2 $PREFIX_v1_z $PREFIX_v2_z]
}


proc PREFIX_pitch_calculate { tv1 tv2 tv1z tv2z } {

	set v1_v2_distance [expr $tv2z - $tv1z ]

	if { abs($v1_v2_distance) > 0.0001 }  {
		return [expr 1000.0 * atan( ($tv2 - $tv1) / $v1_v2_distance) ]
	} else {
		return 0.0
	}
}

