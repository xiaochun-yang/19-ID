# mono_slit_horiz.tcl


proc mono_slit_horiz_initialize {} {

	# specify children devices
	set_children mono_slit_ssrl mono_slit_spear
	set_siblings mono_slit_horiz_gap
}


proc mono_slit_horiz_move { new_mono_slit_horiz } {
	#global namespace variables
	global gDevice

	# global variables
	variable mono_slit_horiz_gap
	variable mono_slit_horiz

	# calculate new positions of the two motors
	set new_mono_slit_ssrl [mono_slit_ssrl_calculate $new_mono_slit_horiz $gDevice(mono_slit_horiz_gap,target)]
	set new_mono_slit_spear [mono_slit_spear_calculate $new_mono_slit_horiz $gDevice(mono_slit_horiz_gap,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit mono_slit_ssrl $new_mono_slit_ssrl
    assertMotorLimit mono_slit_spear $new_mono_slit_spear

	# move motors in order that avoids collisions
	if { $new_mono_slit_horiz > $mono_slit_horiz } {
		move mono_slit_ssrl to $new_mono_slit_ssrl
		move mono_slit_spear to $new_mono_slit_spear
	} else {
		move mono_slit_spear to $new_mono_slit_spear
		move mono_slit_ssrl to $new_mono_slit_ssrl
	}

	# wait for the moves to complete
	wait_for_devices mono_slit_ssrl mono_slit_spear
}


proc mono_slit_horiz_set { new_mono_slit_horiz } {

	# global variables
	variable mono_slit_horiz_gap
	variable mono_slit_ssrl
	variable mono_slit_spear

	# move the two motors
	set mono_slit_ssrl  [mono_slit_ssrl_calculate $new_mono_slit_horiz $mono_slit_horiz_gap]
	set mono_slit_spear  [mono_slit_spear_calculate $new_mono_slit_horiz $mono_slit_horiz_gap]
}


proc mono_slit_horiz_update {} {

	# global variables
	variable mono_slit_ssrl
	variable mono_slit_spear

	# calculate from real motor positions and motor parameters
	return [mono_slit_horiz_calculate $mono_slit_ssrl $mono_slit_spear]
}


proc mono_slit_horiz_calculate { s1ssrl s1spear } {
	
	return [expr ($s1ssrl + $s1spear)/ 2.0 ]
}


proc mono_slit_ssrl_calculate { s1h s1hg } {

	return [expr $s1h + $s1hg / 2.0 ]
}


proc mono_slit_spear_calculate { s1h s1hg } {

	return [expr $s1h - $s1hg / 2.0 ]
}

