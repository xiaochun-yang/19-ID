# PREFIX_horz.tcl


proc PREFIX_horz_initialize {} {

	# specify children devices
	set_children PREFIX_horz_1 PREFIX_horz_2 PREFIX_pivot_z PREFIX_h2_z
	set_siblings PREFIX_yaw
}


proc PREFIX_horz_move { new_PREFIX_horz } {

	# global variables
	variable PREFIX_horz
	variable PREFIX_horz_1

	# move the two motors
	move PREFIX_horz_1 to [expr $PREFIX_horz_1 + $new_PREFIX_horz - $PREFIX_horz ]

	# wait for the moves to complete
	wait_for_devices PREFIX_horz_1 
}


proc PREFIX_horz_set { new_PREFIX_horz } {

	# global variables
	variable PREFIX_horz	
	variable PREFIX_horz_1

	# set the two motors
	set PREFIX_horz_1 [expr $PREFIX_horz_1 + $new_PREFIX_horz - $PREFIX_horz ]
}


proc PREFIX_horz_update {} {

	# global variables
	variable PREFIX_horz_1
	variable PREFIX_horz_2
	variable PREFIX_pivot_z
	variable PREFIX_h2_z

	# calculate from real motor positions and motor parameters
	return [PREFIX_horz_calculate $PREFIX_horz_1 $PREFIX_horz_2 $PREFIX_pivot_z $PREFIX_h2_z]
}


proc PREFIX_horz_calculate { th1 th2 tpz th2z} {

	if { abs($th2z) > 0.0001 }  {
		set ty [expr [expr atan( $th2 / $th2z ) ]]
		return [expr $th1 + $tpz * tan($ty)]
	} else {
		return 0.0
	}
}
