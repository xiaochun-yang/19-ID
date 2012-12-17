# mirror_slit_horiz_gap.tcl


proc mirror_slit_horiz_gap_initialize {} {

	# specify children devices
	set_children mirror_slit_ssrl mirror_slit_spear
	set_siblings mirror_slit_horiz
}


proc mirror_slit_horiz_gap_move { new_mirror_slit_horiz_gap } {
	#global namespace variables
	global gDevice

	# global variables
	variable mirror_slit_horiz

	# move the two motors
	move mirror_slit_ssrl to [mirror_slit_ssrl_calculate $gDevice(mirror_slit_horiz,target) $new_mirror_slit_horiz_gap]
	move mirror_slit_spear to [mirror_slit_spear_calculate $gDevice(mirror_slit_horiz,target) $new_mirror_slit_horiz_gap]

	# wait for the moves to complete
	wait_for_devices mirror_slit_ssrl mirror_slit_spear
}


proc mirror_slit_horiz_gap_set { new_mirror_slit_horiz_gap } {

	# global variables
	variable mirror_slit_horiz
	variable mirror_slit_ssrl
	variable mirror_slit_spear

	# set the two motors
	set mirror_slit_ssrl [mirror_slit_ssrl_calculate $mirror_slit_horiz $new_mirror_slit_horiz_gap]
	set mirror_slit_spear [mirror_slit_spear_calculate $mirror_slit_horiz $new_mirror_slit_horiz_gap]
}


proc mirror_slit_horiz_gap_update {} {

	# global variables
	variable mirror_slit_ssrl
	variable mirror_slit_spear

	# calculate from real motor positions and motor parameters
	return [mirror_slit_horiz_gap_calculate $mirror_slit_ssrl $mirror_slit_spear]
}


proc mirror_slit_horiz_gap_calculate { s1ssrl s1spear } {
	
	return [expr $s1ssrl - $s1spear ]
}

