# slit_2_horiz.tcl


proc slit_2_horiz_initialize {} {

	# specify children devices
	set_children slit_2_ssrl slit_2_spear
	set_siblings slit_2_horiz_gap
}


proc slit_2_horiz_move { new_slit_2_horiz } {
	# global variables
	global gDevice

	# global variables
	variable slit_2_horiz_gap
	variable slit_2_horiz

	# calculate new positions of the two motors
	set new_slit_2_ssrl [slit_2_ssrl_calculate $new_slit_2_horiz $gDevice(slit_2_horiz_gap,target)]
	set new_slit_2_spear [slit_2_spear_calculate $new_slit_2_horiz $gDevice(slit_2_horiz_gap,target)]

	# move motors in order that avoids collisions
	if { $new_slit_2_horiz > $slit_2_horiz } {
		move slit_2_ssrl to $new_slit_2_ssrl
		move slit_2_spear to $new_slit_2_spear
	} else {
		move slit_2_spear to $new_slit_2_spear
		move slit_2_ssrl to $new_slit_2_ssrl
	}

	# wait for the moves to complete
	wait_for_devices slit_2_ssrl slit_2_spear
}


proc slit_2_horiz_set { new_slit_2_horiz } {

	# global variables
	variable slit_2_horiz_gap
	variable slit_2_ssrl
	variable slit_2_spear

	# move the two motors
	set slit_2_ssrl  [slit_2_ssrl_calculate $new_slit_2_horiz $slit_2_horiz_gap]
	set slit_2_spear  [slit_2_spear_calculate $new_slit_2_horiz $slit_2_horiz_gap]
}


proc slit_2_horiz_update {} {

	# global variables
	variable slit_2_ssrl
	variable slit_2_spear

	# calculate from real motor positions and motor parameters
	return [slit_2_horiz_calculate $slit_2_ssrl $slit_2_spear]
}


proc slit_2_horiz_calculate { s2ssrl s2spear } {
	
	return [expr ($s2ssrl + $s2spear)/ 2.0 ]
}


proc slit_2_ssrl_calculate { s2h s2hg } {

	return [expr $s2h + $s2hg / 2.0 ]
}


proc slit_2_spear_calculate { s2h s2hg } {

	return [expr $s2h - $s2hg / 2.0 ]
}

