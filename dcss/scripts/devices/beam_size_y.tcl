# beam_size_y.tcl
# This is for x4a crystal logic rotation slit.

proc beam_size_y_initialize {} {

	# specify children devices
	set_children slit_1
}


proc beam_size_y_move { new_beam_size_y } {

	# calculate new positions of the two motors
	set new_slit_1 [slit_1_calculate $new_beam_size_y]

	#check to see if the move can be completed by the real motors
	assertMotorLimit slit_1 $new_slit_1

	# move motors in order that avoids collisions
	move slit_1 to $new_slit_1

	# wait for the moves to complete
	wait_for_devices slit_1 
}

proc beam_size_y_set { new_beam_size_y } {

	# global variables
	variable slit_1

	# set three motors
	set slit_1 [slit_1_calculate $new_beam_size_y]
}


proc beam_size_y_update {} {

	# global variables
    variable slit_1

	# calculate from real motor positions and motor parameters
	return [beam_size_y_calculate $slit_1]
}


proc beam_size_y_calculate { f } {
	
	return [expr (4*cos($f*3.14159/180) -2) ]
}

proc slit_1_calculate { w } {

    return [expr (acos(($w+2)/4))*180/3.14159]
}
