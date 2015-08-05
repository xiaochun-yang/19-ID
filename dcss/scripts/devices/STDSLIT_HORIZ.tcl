# PREFIX_horiz.tcl


proc PREFIX_horiz_initialize {} {

	# specify children devices
	set_children PREFIX_nsls PREFIX_ring
	set_siblings PREFIX_horiz_gap
}


proc PREFIX_horiz_move { new_PREFIX_horiz } {
	#global namespace variables
	global gDevice

	# global variables
	variable PREFIX_horiz_gap
	variable PREFIX_horiz

	# calculate new positions of the two motors
	set new_PREFIX_nsls [PREFIX_nsls_calculate $new_PREFIX_horiz $gDevice(PREFIX_horiz_gap,target)]
	set new_PREFIX_ring [PREFIX_ring_calculate $new_PREFIX_horiz $gDevice(PREFIX_horiz_gap,target)]

	# move motors in order that avoids collisions
	if { $new_PREFIX_horiz > $PREFIX_horiz } {
		move PREFIX_nsls to $new_PREFIX_nsls
		move PREFIX_ring to $new_PREFIX_ring
	} else {
		move PREFIX_ring to $new_PREFIX_ring
		move PREFIX_nsls to $new_PREFIX_nsls
	}

	# wait for the moves to complete
	wait_for_devices PREFIX_nsls PREFIX_ring
}


proc PREFIX_horiz_set { new_PREFIX_horiz } {

	# global variables
	variable PREFIX_horiz_gap
	variable PREFIX_nsls
	variable PREFIX_ring

	# move the two motors
	set PREFIX_nsls  [PREFIX_nsls_calculate $new_PREFIX_horiz $PREFIX_horiz_gap]
	set PREFIX_ring  [PREFIX_ring_calculate $new_PREFIX_horiz $PREFIX_horiz_gap]
}


proc PREFIX_horiz_update {} {

	# global variables
	variable PREFIX_nsls
	variable PREFIX_ring

	# calculate from real motor positions and motor parameters
	return [PREFIX_horiz_calculate $PREFIX_nsls $PREFIX_ring]
}


proc PREFIX_horiz_calculate { s1nsls s1ring } {
	
	return [expr ($s1nsls + $s1ring)/ 2.0 ]
}


proc PREFIX_nsls_calculate { s1h s1hg } {

	return [expr $s1h + $s1hg / 2.0 ]
}


proc PREFIX_ring_calculate { s1h s1hg } {

	return [expr $s1h - $s1hg / 2.0 ]
}

