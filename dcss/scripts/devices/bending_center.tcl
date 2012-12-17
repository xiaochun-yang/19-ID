# bending_center.tcl


proc bending_center_initialize {} {

	# specify children devices
	set_children bend_x3 bend_x5
	set_siblings bending_size
}


proc bending_center_move { new_bending_center } {
	#global 
	global gDevice

	# global variables
	variable bending_size
	variable bending_center

	# calculate new positions of the two motors
	set new_bend_x3 [bend_x3_calculate $new_bending_center $gDevice(bending_size,target)]
	set new_bend_x5 [bend_x5_calculate $new_bending_center $gDevice(bending_size,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit bend_x3 $new_bend_x3
	assertMotorLimit bend_x5 $new_bend_x5

	# move motors in order that avoids collisions
	if { $new_bending_center > $bending_center} { 
		move bend_x3 to $new_bend_x3
		move bend_x5 to $new_bend_x5
	} else {
		move bend_x5 to $new_bend_x5
		move bend_x3 to $new_bend_x3
	}

	# wait for the moves to complete
	wait_for_devices bend_x3 bend_x5
}


proc bending_center_set { new_bending_center } {

	# global variables
	variable bending_size
	variable bend_x3
	variable bend_x5

	# move the two motors
	set bend_x3 [bend_x3_calculate $new_bending_center $bending_size]
	set bend_x5 [bend_x5_calculate $new_bending_center $bending_size]
}


proc bending_center_update {} {

	# global variables
	variable bend_x3
	variable bend_x5

	# calculate from real motor positions and motor parameters
	return [bending_center_calculate $bend_x3 $bend_x5]
}


proc bending_center_calculate { c s } {
	
	return [expr ($c + $s)/ 2.0 ]
}


proc bend_x3_calculate { c s } {

	return [expr $c  + $s / 2.0 ]
}


proc bend_x5_calculate { c s } {

	return [expr $c - $s / 2.0 ]
}

