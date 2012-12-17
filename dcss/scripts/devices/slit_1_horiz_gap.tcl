# slit_1_horiz_gap.tcl


proc slit_1_horiz_gap_initialize {} {

	# specify children devices
	set_children slit_1_ssrl slit_1_spear
	set_siblings slit_1_horiz
}


proc slit_1_horiz_gap_move { new_slit_1_horiz_gap } {
	#global namespace variables
	global gDevice

	# global variables
	variable slit_1_horiz

	# move the two motors
	move slit_1_ssrl to [slit_1_ssrl_calculate $gDevice(slit_1_horiz,target) $new_slit_1_horiz_gap]
	move slit_1_spear to [slit_1_spear_calculate $gDevice(slit_1_horiz,target) $new_slit_1_horiz_gap]

	# wait for the moves to complete
	wait_for_devices slit_1_ssrl slit_1_spear
}


proc slit_1_horiz_gap_set { new_slit_1_horiz_gap } {

	# global variables
	variable slit_1_horiz
	variable slit_1_ssrl
	variable slit_1_spear

	# set the two motors
	set slit_1_ssrl [slit_1_ssrl_calculate $slit_1_horiz $new_slit_1_horiz_gap]
	set slit_1_spear [slit_1_spear_calculate $slit_1_horiz $new_slit_1_horiz_gap]
}


proc slit_1_horiz_gap_update {} {

	# global variables
	variable slit_1_ssrl
	variable slit_1_spear

	# calculate from real motor positions and motor parameters
	return [slit_1_horiz_gap_calculate $slit_1_ssrl $slit_1_spear]
}


proc slit_1_horiz_gap_calculate { s1ssrl s1spear } {
	
	return [expr $s1ssrl - $s1spear ]
}

