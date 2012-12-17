# toroid_horz.tcl


proc toroid_horz_initialize {} {

	# specify children devices
	set_children toroid_horz_1 toroid_horz_2 toroid_pivot_z toroid_h2_z
	set_siblings toroid_yaw
}


proc toroid_horz_move { new_toroid_horz } {

	# global variables
	variable toroid_horz
	variable toroid_horz_1

	# move the two motors
	move toroid_horz_1 to [expr $toroid_horz_1 + $new_toroid_horz - $toroid_horz ]

	# wait for the moves to complete
	wait_for_devices toroid_horz_1 
}


proc toroid_horz_set { new_toroid_horz } {

	# global variables
	variable toroid_horz	
	variable toroid_horz_1

	# set the two motors
	set toroid_horz_1 [expr $toroid_horz_1 + $new_toroid_horz - $toroid_horz ]
}


proc toroid_horz_update {} {

	# global variables
	variable toroid_horz_1
	variable toroid_horz_2
	variable toroid_pivot_z
	variable toroid_h2_z

	# calculate from real motor positions and motor parameters
	return [toroid_horz_calculate $toroid_horz_1 $toroid_horz_2 $toroid_pivot_z $toroid_h2_z]
}


proc toroid_horz_calculate { th1 th2 tpz th2z} {

	if { abs($th2z) > 0.0001 }  {
		set ty [expr [expr atan( $th2 / $th2z ) ]]
		return [expr $th1 + $tpz * tan($ty)]
	} else {
		return 0.0
	}
}
