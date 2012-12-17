# mono_slit_horiz_gap.tcl


proc mono_slit_horiz_gap_initialize {} {

	# specify children devices
	set_children mono_slit_ssrl mono_slit_spear
	set_siblings mono_slit_horiz
}


proc mono_slit_horiz_gap_move { new_mono_slit_horiz_gap } {
	#global namespace variables
	global gDevice

	# global variables
	variable mono_slit_horiz

	set new_mono_slit_ssrl  [mono_slit_ssrl_calculate $gDevice(mono_slit_horiz,target) $new_mono_slit_horiz_gap]
	set new_mono_slit_spear [mono_slit_spear_calculate $gDevice(mono_slit_horiz,target) $new_mono_slit_horiz_gap]

	#check to see if the move can be completed by the real motors
	assertMotorLimit mono_slit_ssrl $new_mono_slit_ssrl
    assertMotorLimit mono_slit_spear $new_mono_slit_spear

	# move the two motors
	move mono_slit_ssrl to $new_mono_slit_ssrl
	move mono_slit_spear to $new_mono_slit_spear

	# wait for the moves to complete
	wait_for_devices mono_slit_ssrl mono_slit_spear
}


proc mono_slit_horiz_gap_set { new_mono_slit_horiz_gap } {

	# global variables
	variable mono_slit_horiz
	variable mono_slit_ssrl
	variable mono_slit_spear

	# set the two motors
	set mono_slit_ssrl [mono_slit_ssrl_calculate $mono_slit_horiz $new_mono_slit_horiz_gap]
	set mono_slit_spear [mono_slit_spear_calculate $mono_slit_horiz $new_mono_slit_horiz_gap]
}


proc mono_slit_horiz_gap_update {} {

	# global variables
	variable mono_slit_ssrl
	variable mono_slit_spear

	# calculate from real motor positions and motor parameters
	return [mono_slit_horiz_gap_calculate $mono_slit_ssrl $mono_slit_spear]
}


proc mono_slit_horiz_gap_calculate { s1ssrl s1spear } {
	
	return [expr $s1ssrl - $s1spear ]
}

