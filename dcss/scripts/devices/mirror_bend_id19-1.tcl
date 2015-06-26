# mirror_bend_id19.tcl


proc mirror_bend_initialize {} {

	# specify children devices
	set_children mirror_bend_downstream mirror_bend_upstream
}


proc mirror_bend_move { new_mirror_bend } {

	# global variables
	variable mirror_bend_downstream
	
	# start the motor move of mirror_bend_upstream
	move mirror_bend_upstream to [expr $mirror_bend_downstream + $new_mirror_bend]

	# wait for the move to complete
	wait_for_devices mirror_bend_upstream
}


proc mirror_bend_set { new_mirror_bend } {

	# global variables
	variable mirror_bend_upstream
	variable mirror_bend_downstream
	
	# start the motor move of mirror_bend_upstream
	set mirror_bend_upstream [expr $mirror_bend_downstream + $new_mirror_bend]
}

proc mirror_bend_update {} {

	# global variables
	variable mirror_bend_downstream
	variable mirror_bend_upstream

	# calculate from real motor positions and motor parameters
	return [mirror_bend_calculate $mirror_bend_downstream $mirror_bend_upstream]
}


proc mirror_bend_calculate { mv msu } {

	# global variables
	variable mirror_bend

	return [expr $msu - $mv]
}
