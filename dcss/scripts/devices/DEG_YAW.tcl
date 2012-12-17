# PREFIX_yaw.tcl


proc PREFIX_yaw_initialize {} {

	# specify children devices
	set_children PREFIX_horz_1 PREFIX_horz_2 PREFIX_pivot_z PREFIX_h2_z
	set_siblings PREFIX_horz
}


proc PREFIX_yaw_move { new_PREFIX_yaw } {
	set new_PREFIX_horz_1 [calculate_PREFIX_horz_1 $new_PREFIX_yaw]
	set new_PREFIX_horz_2 [calculate_PREFIX_horz_2 $new_PREFIX_yaw]

	assertMotorLimit PREFIX_horz_1 $new_PREFIX_horz_1
	assertMotorLimit PREFIX_horz_2 $new_PREFIX_horz_2

	# move the two motors
	move PREFIX_horz_1 to $new_PREFIX_horz_1
	move PREFIX_horz_2 to $new_PREFIX_horz_2

	# wait for the moves to complete
	wait_for_devices PREFIX_horz_1 PREFIX_horz_2
}


proc PREFIX_yaw_set { new_PREFIX_yaw } {

	# global variables
	variable PREFIX_horz_1
	variable PREFIX_horz_2

	# set the two motors
	set PREFIX_horz_1 [calculate_PREFIX_horz_1 $new_PREFIX_yaw]
	set PREFIX_horz_2 [calculate_PREFIX_horz_2 $new_PREFIX_yaw]
}


proc PREFIX_yaw_update {} {

	# global variables
	variable PREFIX_horz_2
	variable PREFIX_h2_z

	# calculate from real motor positions and motor parameters
	return [PREFIX_yaw_calculate 0 $PREFIX_horz_2 0 $PREFIX_h2_z]
}


proc PREFIX_yaw_calculate { th1 th2 tpz th2z} {

	if { abs($th2z) > 0.0001 }  {
		return [expr [deg [expr atan( $th2 / $th2z ) ]]]
	} else {
		return 0.0
	}
}


proc calculate_PREFIX_horz_1 { ty } {

	# global variables
	variable PREFIX_pivot_z
	variable PREFIX_horz

	print "Requested yaw = $ty"
	print "Current PREFIX_pivot_z = $PREFIX_pivot_z"

	return [expr $PREFIX_horz - $PREFIX_pivot_z * tan( [rad $ty] ) ]
}


proc calculate_PREFIX_horz_2 { ty } {

	# global variables
	variable PREFIX_h2_z

	return [expr $PREFIX_h2_z * tan( [rad $ty] ) ]
}
