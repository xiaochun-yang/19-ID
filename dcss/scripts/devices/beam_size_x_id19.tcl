# beam_size_x.tcl
# This is for id-19 crystal logic rotation slits.

proc beam_size_x_initialize {} {

	# specify children devices
	set_children slit_0_ring slit_0_lobs
	set_siblings slit_pos_x
}


proc beam_size_x_move { new_beam_size_x } {

	global gDevice
	variable slit_pos_x
  
	# calculate new positions of the two motors
	set new_slit_0_ring [slit_0_ring_calculate_s $new_beam_size_x $gDevice(slit_pos_x,target)]
	set new_slit_0_lobs [slit_0_lobs_calculate_s $new_beam_size_x $gDevice(slit_pos_x,target)]
#	set new_slit_0_ring [slit_0_ring_calculate_s  $new_beam_size_x $slit_pos_x]
#       set new_slit_0_lobs [slit_0_lobs_calculate_s  $new_beam_size_x $slit_pos_x]

	#check to see if the move can be completed by the real motors
	assertMotorLimit slit_0_ring $new_slit_0_ring
	assertMotorLimit slit_0_lobs $new_slit_0_lobs

	# move motors in order that avoids collisions
	move slit_0_ring to $new_slit_0_ring
	move slit_0_lobs to $new_slit_0_lobs

	# wait for the moves to complete
	wait_for_devices slit_0_ring slit_0_lobs 
}

proc beam_size_x_set { new_beam_size_x } {

	# global variables
	variable slit_0_ring
	variable slit_0_lobs
	variable slit_pos_x

	# set two motors
	set slit_0_ring [slit_0_ring_calculate_s $new_beam_size_x $slit_pos_x]
	set slit_0_lobs [slit_0_lobs_calculate_s $new_beam_size_x $slit_pos_x]
}


proc beam_size_x_update {} {

	# global variables
    	variable slit_0_ring
	variable slit_0_lobs

	# calculate from real motor positions and motor parameters
	return [beam_size_x_calculate $slit_0_ring $slit_0_lobs]
}


proc beam_size_x_calculate { ring lobs } {
	
	return [expr (2*cos($ring*3.1415926/180)+2*cos($lobs*3.1415926/180)-2)]
}

proc slit_0_ring_calculate_s { size pos } {

    return [expr (acos($size/4+0.5+$pos/2)*180/3.1415926)]
}

proc slit_0_lobs_calculate_s { size pos } {

    return [expr (acos($size/4+0.5-$pos/2)*180/3.1415926)]
}
