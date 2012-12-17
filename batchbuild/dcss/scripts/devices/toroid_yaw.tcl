# toroid_yaw.tcl


proc toroid_yaw_initialize {} {

	# specify children devices
	set_children toroid_horz_1 toroid_horz_2 toroid_pivot_z toroid_h2_z
	set_siblings toroid_horz
}


proc toroid_yaw_move { new_toroid_yaw } {

	# move the two motors
	move toroid_horz_1 to [calculate_toroid_horz_1 $new_toroid_yaw]
	move toroid_horz_2 to [calculate_toroid_horz_2 $new_toroid_yaw]

	# wait for the moves to complete
	wait_for_devices toroid_horz_1 toroid_horz_2
}


proc toroid_yaw_set { new_toroid_yaw } {

	# global variables
	variable toroid_horz_1
	variable toroid_horz_2

	# set the two motors
	set toroid_horz_1 [calculate_toroid_horz_1 $new_toroid_yaw]
	set toroid_horz_2 [calculate_toroid_horz_2 $new_toroid_yaw]
}


proc toroid_yaw_update {} {

	# global variables
	variable toroid_horz_2
	variable toroid_h2_z

	# calculate from real motor positions and motor parameters
	return [toroid_yaw_calculate 0 $toroid_horz_2 0 $toroid_h2_z]
}


proc toroid_yaw_calculate { th1 th2 tpz th2z} {

	if { abs($th2z) > 0.0001 }  {
		return [expr [deg [expr atan( $th2 / $th2z ) ]]]
	} else {
		return 0.0
	}
}


proc calculate_toroid_horz_1 { ty } {

	# global variables
	variable toroid_pivot_z
	variable toroid_horz

	print "Requested yaw = $ty"
	print "Current toroid_pivot_z = $toroid_pivot_z"

	return [expr $toroid_horz - $toroid_pivot_z * tan( [rad $ty] ) ]
}


proc calculate_toroid_horz_2 { ty } {

	# global variables
	variable toroid_h2_z

	return [expr $toroid_h2_z * tan( [rad $ty] ) ]
}
