# beam_width.tcl
# This is for x4a crystal logic rotation slit.

proc beam_width_initialize {} {

	# specify children devices
	set_children slit_2
}


proc beam_width_move { new_beam_width } {

	# calculate new positions of the two motors
	set new_slit_2 [slit_2_calculate $new_beam_width]

	#check to see if the move can be completed by the real motors
	assertMotorLimit slit_2 $new_slit_2

	# move motors in order that avoids collisions
	move slit_2 to $new_slit_2

	# wait for the moves to complete
	wait_for_devices slit_2 
}

proc beam_width_set { new_beam_width } {

	# global variables
	variable slit_2

	# set three motors
	set slit_2 [slit_2_calculate $new_beam_width]
}


proc beam_width_update {} {

	# global variables
    variable slit_2

	# calculate from real motor positions and motor parameters
	return [beam_width_calculate $slit_2]
}


proc beam_width_calculate { f } {
	
	return [expr (4*cos($f*3.14/180) -2) ]
}

proc slit_2_calculate { w } {

    return [expr (acos(($w+2)/4))*180/3.14]
}
