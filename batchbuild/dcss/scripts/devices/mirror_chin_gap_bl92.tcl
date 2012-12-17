# mirror_chin_gap.tcl


proc mirror_chin_gap_initialize {} {
	global gDevice
	# specify children devices
	set_children mirror_vert mirror_slit_upper
	set_siblings mirror_vert_chin
	set gDevice(mirror_chin_gap,maxTargetError) .0065
}


proc mirror_chin_gap_move { new_mirror_chin_gap } {

	# global variables
	variable mirror_vert
	
	# start the motor move of mirror_slit_upper
	move mirror_slit_upper to [expr $mirror_vert + $new_mirror_chin_gap]

	# wait for the move to complete
	wait_for_devices mirror_slit_upper
}


proc mirror_chin_gap_set { new_mirror_chin_gap } {

	# global variables
	variable mirror_slit_upper
	variable mirror_vert
	
	# start the motor move of mirror_slit_upper
	set mirror_slit_upper [expr $mirror_vert + $new_mirror_chin_gap]
}

proc mirror_chin_gap_update {} {

	# global variables
	variable mirror_vert
	variable mirror_slit_upper

	# calculate from real motor positions and motor parameters
	return [mirror_chin_gap_calculate $mirror_vert $mirror_slit_upper]
}


proc mirror_chin_gap_calculate { mv msu } {

	# global variables
	variable mirror_chin_gap

	return [expr $msu - $mv]
}
