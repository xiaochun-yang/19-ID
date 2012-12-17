# PREFIX_horiz.tcl


proc PREFIX_horiz_initialize {} {

	# specify children devices
	set_children PREFIX_ssrl PREFIX_spear
	set_siblings PREFIX_horiz_gap
}


proc PREFIX_horiz_move { new_PREFIX_horiz } {
	#global namespace variables
	global gDevice

	# global variables
	variable PREFIX_horiz_gap
	variable PREFIX_horiz

	# calculate new positions of the two motors
	set new_PREFIX_ssrl [PREFIX_ssrl_calculate $new_PREFIX_horiz $gDevice(PREFIX_horiz_gap,target)]
	set new_PREFIX_spear [PREFIX_spear_calculate $new_PREFIX_horiz $gDevice(PREFIX_horiz_gap,target)]

	# move motors in order that avoids collisions
	if { $new_PREFIX_horiz > $PREFIX_horiz } {
		move PREFIX_ssrl to $new_PREFIX_ssrl
		move PREFIX_spear to $new_PREFIX_spear
	} else {
		move PREFIX_spear to $new_PREFIX_spear
		move PREFIX_ssrl to $new_PREFIX_ssrl
	}

	# wait for the moves to complete
	wait_for_devices PREFIX_ssrl PREFIX_spear
}


proc PREFIX_horiz_set { new_PREFIX_horiz } {

	# global variables
	variable PREFIX_horiz_gap
	variable PREFIX_ssrl
	variable PREFIX_spear

	# move the two motors
	set PREFIX_ssrl  [PREFIX_ssrl_calculate $new_PREFIX_horiz $PREFIX_horiz_gap]
	set PREFIX_spear  [PREFIX_spear_calculate $new_PREFIX_horiz $PREFIX_horiz_gap]
}


proc PREFIX_horiz_update {} {

	# global variables
	variable PREFIX_ssrl
	variable PREFIX_spear

	# calculate from real motor positions and motor parameters
	return [PREFIX_horiz_calculate $PREFIX_ssrl $PREFIX_spear]
}


proc PREFIX_horiz_calculate { s1ssrl s1spear } {
	
	return [expr ($s1ssrl + $s1spear)/ 2.0 ]
}


proc PREFIX_ssrl_calculate { s1h s1hg } {

	return [expr $s1h + $s1hg / 2.0 ]
}


proc PREFIX_spear_calculate { s1h s1hg } {

	return [expr $s1h - $s1hg / 2.0 ]
}

