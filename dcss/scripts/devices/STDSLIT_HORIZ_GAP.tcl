# PREFIX_horiz_gap.tcl


proc PREFIX_horiz_gap_initialize {} {

	# specify children devices
	set_children PREFIX_nsls PREFIX_ring
	set_siblings PREFIX_horiz
}


proc PREFIX_horiz_gap_move { new_PREFIX_horiz_gap } {
	#global namespace variables
	global gDevice

	# global variables
	variable PREFIX_horiz

	# move the two motors
	move PREFIX_nsls to [PREFIX_nsls_calculate $gDevice(PREFIX_horiz,target) $new_PREFIX_horiz_gap]
	move PREFIX_ring to [PREFIX_ring_calculate $gDevice(PREFIX_horiz,target) $new_PREFIX_horiz_gap]

	# wait for the moves to complete
	wait_for_devices PREFIX_nsls PREFIX_ring
}


proc PREFIX_horiz_gap_set { new_PREFIX_horiz_gap } {

	# global variables
	variable PREFIX_horiz
	variable PREFIX_nsls
	variable PREFIX_ring

	# set the two motors
	set PREFIX_nsls [PREFIX_nsls_calculate $PREFIX_horiz $new_PREFIX_horiz_gap]
	set PREFIX_ring [PREFIX_ring_calculate $PREFIX_horiz $new_PREFIX_horiz_gap]
}


proc PREFIX_horiz_gap_update {} {

	# global variables
	variable PREFIX_nsls
	variable PREFIX_ring

	# calculate from real motor positions and motor parameters
	return [PREFIX_horiz_gap_calculate $PREFIX_nsls $PREFIX_ring]
}


proc PREFIX_horiz_gap_calculate { s1nsls s1ring } {
	
	return [expr $s1nsls - $s1ring ]
}

