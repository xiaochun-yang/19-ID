# mirror_slit_horiz.tcl


proc mirror_slit_horiz_initialize {} {

	# specify children devices
	set_children mirror_slit_ssrl mirror_slit_spear
	set_siblings mirror_slit_horiz_gap
}


proc mirror_slit_horiz_move { new_mirror_slit_horiz } {
	#global namespace variables
	global gDevice

	# global variables
	variable mirror_slit_horiz_gap
	variable mirror_slit_horiz

	# calculate new positions of the two motors
	set new_mirror_slit_ssrl [mirror_slit_ssrl_calculate $new_mirror_slit_horiz $gDevice(mirror_slit_horiz_gap,target)]
	set new_mirror_slit_spear [mirror_slit_spear_calculate $new_mirror_slit_horiz $gDevice(mirror_slit_horiz_gap,target)]

    assertMotorLimit mirror_slit_ssrl $new_mirror_slit_ssrl
	assertMotorLimit mirror_slit_spear  $new_mirror_slit_spear

	# move motors in order that avoids collisions
	if { $new_mirror_slit_horiz > $mirror_slit_horiz } {
		move mirror_slit_ssrl to $new_mirror_slit_ssrl
		move mirror_slit_spear to $new_mirror_slit_spear
	} else {
		move mirror_slit_spear to $new_mirror_slit_spear
		move mirror_slit_ssrl to $new_mirror_slit_ssrl
	}

	# wait for the moves to complete
	wait_for_devices mirror_slit_ssrl mirror_slit_spear
}


proc mirror_slit_horiz_set { new_mirror_slit_horiz } {

	# global variables
	variable mirror_slit_horiz_gap
	variable mirror_slit_ssrl
	variable mirror_slit_spear

	# move the two motors
	set mirror_slit_ssrl  [mirror_slit_ssrl_calculate $new_mirror_slit_horiz $mirror_slit_horiz_gap]
	set mirror_slit_spear  [mirror_slit_spear_calculate $new_mirror_slit_horiz $mirror_slit_horiz_gap]
}


proc mirror_slit_horiz_update {} {

	# global variables
	variable mirror_slit_ssrl
	variable mirror_slit_spear

	# calculate from real motor positions and motor parameters
	return [mirror_slit_horiz_calculate $mirror_slit_ssrl $mirror_slit_spear]
}


proc mirror_slit_horiz_calculate { s1ssrl s1spear } {
	
	return [expr ($s1ssrl + $s1spear)/ 2.0 ]
}


proc mirror_slit_ssrl_calculate { s1h s1hg } {

	return [expr $s1h + $s1hg / 2.0 ]
}


proc mirror_slit_spear_calculate { s1h s1hg } {

	return [expr $s1h - $s1hg / 2.0 ]
}

