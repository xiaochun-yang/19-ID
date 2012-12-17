# box_size.tcl


proc box_size_initialize {} {

	# specify children devices
	set_children camera_zoom box_size_0 box_size_1
}


proc box_size_move { new_box_size } {

	# global variables
	variable camera_zoom

	# move the two motors
	move camera_zoom to [camera_zoom_calculate $new_box_size]

	# wait for the moves to complete
	wait_for_devices camera_zoom
}


proc box_size_set { new_box_size } {

	# global variables
	variable camera_zoom

	# move the two motors
	set camera_zoom [camera_zoom_calculate $new_box_size]
}


proc box_size_update {} {

	# global variables
	variable box_size_0
	variable box_size_1
	variable camera_zoom

	# calculate from real motor positions and motor parameters
	return [box_size_calculate $camera_zoom $box_size_0 $box_size_1]
}


proc box_size_calculate { cz bs0 bs1 } {

	
	if { $bs0 == 0 }  {
		return 1
	}
	if { $bs1 == 0 }  {
		return 1
	}

	# calculate box_size from camera zoom
	return [expr $bs0 * exp(log($bs1/$bs0) * $cz)]
	
}


proc camera_zoom_calculate { bs } {

	# global variables
	variable box_size_0
	variable box_size_1

	# return camera zoom corresponding to passed box size
	return [expr log($bs/$box_size_0) / log($box_size_1/$box_size_0)]
}

