# mirror_chin_gap.tcl


proc mirror_chin_gap_initialize {} {

	# specify children devices
	set_children mirror_vert mirror_slit_lower 
	set_siblings mirror_vert_chin
}


proc mirror_chin_gap_move { new_mirror_chin_gap } {

	# global variables
	variable mirror_vert
	
	# start the motor move of mirror_slit_lower
	move mirror_slit_lower to [expr $mirror_vert + $new_mirror_chin_gap]

	# wait for the move to complete
	wait_for_devices mirror_slit_lower
}


proc mirror_chin_gap_set { new_mirror_chin_gap } {

	# global variables
	variable mirror_slit_lower
	variable mirror_vert
	
	# start the motor move of mirror_slit_lower
	set mirror_slit_lower [expr $mirror_vert + $new_mirror_chin_gap]
}

proc mirror_chin_gap_update {} {

	# global variables
	variable mirror_vert
	variable mirror_slit_lower

	# calculate from real motor positions and motor parameters
	return [mirror_chin_gap_calculate $mirror_vert $mirror_slit_lower]
}


proc mirror_chin_gap_calculate { mv msl } {

	# global variables
	variable mirror_chin_gap

	return [expr $msl - $mv]
}
