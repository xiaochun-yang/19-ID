# bending_size.tcl


proc bending_size_initialize {} {

	# specify children devices
	set_children bend_x3 bend_x5
	set_siblings bending_center
}


proc bending_size_move { new_bending_size } {
	#global 
	global gDevice

	# global variables
	variable bending_center

	#check to see if the move can be completed by the real motors
	assertMotorLimit bend_x3 [bend_x3_calculate $gDevice(bending_center,target) $new_bending_size]
	assertMotorLimit bend_x5 [bend_x5_calculate $gDevice(bending_center,target) $new_bending_size]

	# move the two motors
	move bend_x3 to [bend_x3_calculate $gDevice(bending_center,target) $new_bending_size]
	move bend_x5 to [bend_x5_calculate $gDevice(bending_center,target) $new_bending_size]

	# wait for the moves to complete
	wait_for_devices bend_x3 bend_x5
}


proc bending_size_set { new_bending_size } {

	# global variables
	variable bending_center
	variable bend_x3
	variable bend_x5

	# move the two motors
	set bend_x3 [bend_x3_calculate $bending_center $new_bending_size]
	set bend_x5 [bend_x5_calculate $bending_center $new_bending_size]
}


proc bending_size_update {} {

	# global variables
	variable bend_x3
	variable bend_x5

	# calculate from real motor positions and motor parameters
	return [bending_size_calculate $bend_x3 $bend_x5]
}


proc bending_size_calculate { x3 x5 } {
	
	return [expr $x3 - $x5 ]
}

#proc bend_x3_calculate_s { c s } {
#        return [expr $c + $s / 2.0 ]
#}


#proc bend_x5_calculate_s { c s } {
#        return [expr $c - $s / 2.0 ]
#}
