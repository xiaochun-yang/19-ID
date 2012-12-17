# slit_1_horiz.tcl


proc slit_1_horiz_initialize {} {

	# specify children devices
	set_children slit_1_ssrl slit_1_spear
	set_siblings slit_1_horiz_gap
}


proc slit_1_horiz_move { new_slit_1_horiz } {
	#global namespace variables
	global gDevice

	# global variables
	variable slit_1_horiz_gap
	variable slit_1_horiz

	# calculate new positions of the two motors
	set new_slit_1_ssrl [slit_1_ssrl_calculate $new_slit_1_horiz $gDevice(slit_1_horiz_gap,target)]
	set new_slit_1_spear [slit_1_spear_calculate $new_slit_1_horiz $gDevice(slit_1_horiz_gap,target)]

	# move motors in order that avoids collisions
	if { $new_slit_1_horiz > $slit_1_horiz } {
		move slit_1_ssrl to $new_slit_1_ssrl
		move slit_1_spear to $new_slit_1_spear
	} else {
		move slit_1_spear to $new_slit_1_spear
		move slit_1_ssrl to $new_slit_1_ssrl
	}

	# wait for the moves to complete
	wait_for_devices slit_1_ssrl slit_1_spear
}


proc slit_1_horiz_set { new_slit_1_horiz } {

	# global variables
	variable slit_1_horiz_gap
	variable slit_1_ssrl
	variable slit_1_spear

	# move the two motors
	set slit_1_ssrl  [slit_1_ssrl_calculate $new_slit_1_horiz $slit_1_horiz_gap]
	set slit_1_spear  [slit_1_spear_calculate $new_slit_1_horiz $slit_1_horiz_gap]
}


proc slit_1_horiz_update {} {

	# global variables
	variable slit_1_ssrl
	variable slit_1_spear

	# calculate from real motor positions and motor parameters
	return [slit_1_horiz_calculate $slit_1_ssrl $slit_1_spear]
}


proc slit_1_horiz_calculate { s1ssrl s1spear } {
	
	return [expr ($s1ssrl + $s1spear)/ 2.0 ]
}


proc slit_1_ssrl_calculate { s1h s1hg } {

	return [expr $s1h + $s1hg / 2.0 ]
}


proc slit_1_spear_calculate { s1h s1hg } {

	return [expr $s1h - $s1hg / 2.0 ]
}

