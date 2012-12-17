# mirror_vert_chin.tcl


proc mirror_vert_chin_initialize {} {

	# specify children devices
	set_children mirror_vert mirror_slit_upper
	set_siblings mirror_chin_gap
}


proc mirror_vert_chin_move { new_mirror_vert_chin } {
	# global 
	global gDevice

	# global variables
	variable mirror_vert
	variable mirror_slit_upper
	variable mirror_chin_gap

	# calculate destinations for real motors
	set new_mirror_vert $new_mirror_vert_chin
	set new_mirror_slit_upper [expr $new_mirror_vert + $gDevice(mirror_chin_gap,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit mirror_vert $new_mirror_vert
	assertMotorLimit mirror_slit_upper $new_mirror_slit_upper

    # move mirror_vert first if going up 
	if { $new_mirror_vert > $mirror_vert } {

		move mirror_vert to $new_mirror_vert
		wait_for_devices mirror_vert

		move mirror_slit_upper to $new_mirror_slit_upper
		wait_for_devices mirror_slit_upper

	} else {

		move mirror_slit_upper to $new_mirror_slit_upper
		wait_for_devices mirror_slit_upper

		move mirror_vert to $new_mirror_vert
		wait_for_devices mirror_vert
	}
}


proc mirror_vert_chin_set { new_mirror_vert_chin } {

	# global variables
	variable mirror_vert
	variable mirror_slit_upper
	variable mirror_chin_gap

	# calculate destinations for real motors
	set new_mirror_vert $new_mirror_vert_chin
	set new_mirror_slit_upper [expr $new_mirror_vert + $mirror_chin_gap]

	# set the two motors
	set mirror_vert $new_mirror_vert_chin
	set mirror_slit_upper $new_mirror_slit_upper
}


proc mirror_vert_chin_update {} {

	# global variables
	variable mirror_vert

	# calculate from real motor positions and motor parameters
	return [mirror_vert_chin_calculate $mirror_vert 0 ]
}


proc mirror_vert_chin_calculate { mv msu } {
	
	return $mv
}

