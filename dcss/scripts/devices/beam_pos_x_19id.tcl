# beam_pos_x.tcl
# This is for id-19 crystal logic rotation slits.

proc beam_pos_x_initialize {} {

	# specify children devices
	set_children slit_0_ring slit_0_lobs
	set_siblings beam_size_x
}


proc beam_pos_x_move { new_beam_pos_x } {

	global gDevice
	variable beam_size_x
  
	# calculate new positions of the two motors
	set new_slit_0_ring [slit_0_ring_calculate_p $new_beam_pos_x $gDevice(beam_size_x,target)]
	set new_slit_0_lobs [slit_0_lobs_calculate_p $new_beam_pos_x $gDevice(beam_size_x,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit slit_0_ring $new_slit_0_ring
	assertMotorLimit slit_0_lobs $new_slit_0_lobs

	# move motors in order that avoids collisions
	move slit_0_ring to $new_slit_0_ring
	move slit_0_lobs to $new_slit_0_lobs

	# wait for the moves to complete
	wait_for_devices slit_0_ring slit_0_lobs 
}

proc beam_pos_x_set { new_beam_pos_x } {

	# global variables
	variable slit_0_ring
	variable slit_0_lobs
	variable beam_size_x

	# set three motors
	set slit_0_ring [slit_0_ring_calculate_p $new_beam_pos_x $beam_size_x]
	set slit_0_lobs [slit_0_lobs_calculate_p $new_beam_pos_x $beam_size_x]
}


proc beam_pos_x_update {} {

	# global variables
    	variable slit_0_ring
	variable slit_0_lobs

	# calculate from real motor positions and motor parameters
	return [beam_pos_x_calculate $slit_0_ring $slit_0_lobs]
}


proc beam_pos_x_calculate { ring lobs } {
	
	return [expr (cos($ring*3.1415926/180)-cos($lobs*3.1415926/180))]
}

proc slit_0_ring_calculate_p { pos size } {

    return [expr (acos($size/4+0.5+$pos/2)*180/3.1415926)]
}

proc slit_0_lobs_calculate_p { pos size } {

    return [expr (acos($size/4+0.5-$pos/2)*180/3.1415926)]
}
