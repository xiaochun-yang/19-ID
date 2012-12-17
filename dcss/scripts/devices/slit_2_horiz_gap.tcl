# slit_2_horiz_gap.tcl


proc slit_2_horiz_gap_initialize {} {

	# specify children devices
	set_children slit_2_ssrl slit_2_spear
	set_siblings slit_2_horiz
}


proc slit_2_horiz_gap_move { new_slit_2_horiz_gap } {
	#global variables
	global gDevice

	# global variables
	variable slit_2_horiz

	# move the two motors
	move slit_2_ssrl to [slit_2_ssrl_calculate $gDevice(slit_2_horiz,target) $new_slit_2_horiz_gap]
	move slit_2_spear to [slit_2_spear_calculate $gDevice(slit_2_horiz,target) $new_slit_2_horiz_gap]

	# wait for the moves to complete
	wait_for_devices slit_2_ssrl slit_2_spear
}


proc slit_2_horiz_gap_set { new_slit_2_horiz_gap } {

	# global variables
	variable slit_2_horiz
	variable slit_2_ssrl
	variable slit_2_spear

	# set the two motors
	set slit_2_ssrl [slit_2_ssrl_calculate $slit_2_horiz $new_slit_2_horiz_gap]
	set slit_2_spear [slit_2_spear_calculate $slit_2_horiz $new_slit_2_horiz_gap]
}


proc slit_2_horiz_gap_update {} {

	# global variables
	variable slit_2_ssrl
	variable slit_2_spear

	# calculate from real motor positions and motor parameters
	return [slit_2_horiz_gap_calculate $slit_2_ssrl $slit_2_spear]
}


proc slit_2_horiz_gap_calculate { s2ssrl s2spear } {
	
	return [expr $s2ssrl - $s2spear ]
}

