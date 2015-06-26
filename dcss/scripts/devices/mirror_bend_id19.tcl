# mirror_bend.tcl


proc mirror_bend_initialize {} {

	# specify children devices
	set_children mirror_bend_upstream mirror_bend_downstream
	set_siblings mirror_bend_pos
}


proc mirror_bend_move { new_mirror_bend } {
	#global namespace variables
	global gDevice

	# global variables
	variable mirror_bend_pos

	set new_mirror_bend_upstream [mirror_bend_upstream_calculate $gDevice(mirror_bend_pos,target) $new_mirror_bend]
	set new_mirror_bend_downstream [mirror_bend_downstream_calculate $gDevice(mirror_bend_pos,target) $new_mirror_bend]

    assertMotorLimit mirror_bend_upstream $new_mirror_bend_upstream
	assertMotorLimit mirror_bend_downstream  $new_mirror_bend_downstream

	# move the two motors
	move mirror_bend_upstream to $new_mirror_bend_upstream
	move mirror_bend_downstream to $new_mirror_bend_downstream

	# wait for the moves to complete
	wait_for_devices mirror_bend_upstream mirror_bend_downstream
}


proc mirror_bend_set { new_mirror_bend } {

	# global variables
	variable mirror_bend_pos
	variable mirror_bend_upstream
	variable mirror_bend_downstream

	# set the two motors
	set mirror_bend_upstream [mirror_bend_upstream_calculate $mirror_bend_pos $new_mirror_bend]
	set mirror_bend_downstream [mirror_bend_downstream_calculate $mirror_bend_pos $new_mirror_bend]
}


proc mirror_bend_update {} {

	# global variables
	variable mirror_bend_upstream
	variable mirror_bend_downstream

	# calculate from real motor positions and motor parameters
	return [mirror_bend_calculate $mirror_bend_upstream $mirror_bend_downstream]
}


proc mirror_bend_calculate { s1upper s1lower } {
	
	return [expr $s1upper - $s1lower ]
}

