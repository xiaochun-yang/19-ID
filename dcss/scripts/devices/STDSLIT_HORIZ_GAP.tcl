# PREFIX_horiz_gap.tcl


proc PREFIX_horiz_gap_initialize {} {

	# specify children devices
	set_children PREFIX_ssrl PREFIX_spear
	set_siblings PREFIX_horiz
}


proc PREFIX_horiz_gap_move { new_PREFIX_horiz_gap } {
	#global namespace variables
	global gDevice

	# global variables
	variable PREFIX_horiz

	# move the two motors
	move PREFIX_ssrl to [PREFIX_ssrl_calculate $gDevice(PREFIX_horiz,target) $new_PREFIX_horiz_gap]
	move PREFIX_spear to [PREFIX_spear_calculate $gDevice(PREFIX_horiz,target) $new_PREFIX_horiz_gap]

	# wait for the moves to complete
	wait_for_devices PREFIX_ssrl PREFIX_spear
}


proc PREFIX_horiz_gap_set { new_PREFIX_horiz_gap } {

	# global variables
	variable PREFIX_horiz
	variable PREFIX_ssrl
	variable PREFIX_spear

	# set the two motors
	set PREFIX_ssrl [PREFIX_ssrl_calculate $PREFIX_horiz $new_PREFIX_horiz_gap]
	set PREFIX_spear [PREFIX_spear_calculate $PREFIX_horiz $new_PREFIX_horiz_gap]
}


proc PREFIX_horiz_gap_update {} {

	# global variables
	variable PREFIX_ssrl
	variable PREFIX_spear

	# calculate from real motor positions and motor parameters
	return [PREFIX_horiz_gap_calculate $PREFIX_ssrl $PREFIX_spear]
}


proc PREFIX_horiz_gap_calculate { s1ssrl s1spear } {
	
	return [expr $s1ssrl - $s1spear ]
}

