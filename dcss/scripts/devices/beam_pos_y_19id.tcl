# beam_pos_y.tcl
# This is for id-19 crystal logic rotation slits.

proc beam_pos_y_initialize {} {

	# specify children devices
	set_children slit_0_upper slit_0_lower
	set_siblings beam_size_y
}


proc beam_pos_y_move { new_beam_pos_y } {

	global gDevice
	variable beam_size_y
  
	# calculate new positions of the two motors
	set new_slit_0_upper [slit_0_upper_calculate_p $new_beam_pos_y $gDevice(beam_size_y,target)]
	set new_slit_0_lower [slit_0_lower_calculate_p $new_beam_pos_y $gDevice(beam_size_y,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit slit_0_upper $new_slit_0_upper
	assertMotorLimit slit_0_lower $new_slit_0_lower

	# move motors in order that avoids collisions
	move slit_0_upper to $new_slit_0_upper
	move slit_0_lower to $new_slit_0_lower

	# wait for the moves to complete
	wait_for_devices slit_0_upper slit_0_lower 
}

proc beam_pos_y_set { new_beam_pos_y } {

	# global variables
	variable slit_0_upper
	variable slit_0_lower
	variable beam_pos_y
	variable beam_size_y

	# set three motors
	set slit_0_upper [slit_0_upper_calculate_p $new_beam_pos_y $beam_size_y]
	set slit_0_lower [slit_0_lower_calculate_p $new_beam_pos_y $beam_size_y]
}


proc beam_pos_y_update {} {

	# global variables
    	variable slit_0_upper
	variable slit_0_lower

	# calculate from real motor positions and motor parameters
	return [beam_pos_y_calculate $slit_0_upper $slit_0_lower]
}


proc beam_pos_y_calculate { upper lower } {
	
	return [expr (cos($upper*3.1415926/180)-cos($lower*3.1415926/180))]
}

proc slit_0_upper_calculate_p { pos size } {

    return [expr (acos($size/4+0.5+$pos/2)*180/3.1415926)]
}

proc slit_0_lower_calculate_p { pos size } {

    return [expr (acos($size/4+0.5-$pos/2)*180/3.1415926)]
}
