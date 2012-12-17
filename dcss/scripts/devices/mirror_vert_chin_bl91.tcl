# mirror_vert_chin.tcl


proc mirror_vert_chin_initialize {} {

	# specify children devices
	set_children mirror_vert mirror_slit_lower mirror_chin_gap
	set_siblings mirror_chin_gap
}


proc mirror_vert_chin_move { new_mirror_vert_chin } {
	# global namespace variables
	global gDevice

	# global variables
	variable mirror_vert
	variable mirror_slit_lower
	variable mirror_chin_gap

	# calculate destinations for real motors
	set new_mirror_vert $new_mirror_vert_chin
	set new_mirror_slit_lower [expr $new_mirror_vert + $gDevice(mirror_chin_gap,target)]

	# move mirror_vert first if going down
	if { $new_mirror_vert < $mirror_vert } {

		move mirror_vert to $new_mirror_vert
		wait_for_devices mirror_vert

		move mirror_slit_lower to $new_mirror_slit_lower
		wait_for_devices mirror_slit_lower

	} else {

		move mirror_slit_lower to $new_mirror_slit_lower
		wait_for_devices mirror_slit_lower

		move mirror_vert to $new_mirror_vert
		wait_for_devices mirror_vert
	}
}


proc mirror_vert_chin_set { new_mirror_vert_chin } {

	# global variables
	variable mirror_vert
	variable mirror_slit_lower
	variable mirror_chin_gap

	# calculate destinations for real motors
	set new_mirror_vert $new_mirror_vert_chin
	set new_mirror_slit_lower [expr $new_mirror_vert + $mirror_chin_gap]

	# set the two motors
	set mirror_vert $new_mirror_vert_chin
	set mirror_slit_lower $new_mirror_slit_lower
}


proc mirror_vert_chin_update {} {

	# global variables
	variable mirror_vert

	# calculate from real motor positions and motor parameters
	return [mirror_vert_chin_calculate $mirror_vert 0 0]
}


proc mirror_vert_chin_calculate { mv msu mcg } {
	
	return $mv
}

