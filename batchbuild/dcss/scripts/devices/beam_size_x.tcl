# beam_size_x.tcl

proc beam_size_x_initialize {} {

	# specify children devices
	set_children slit_1_horiz_gap slit_2_horiz_gap
}


proc beam_size_x_move { new_beam_size_x } {
    if {$new_beam_size_x < 0} {
        return -code error "new beam size x must >= 0.0"
    }

	# move the two motors
	move slit_1_horiz_gap to $new_beam_size_x
	move slit_2_horiz_gap to $new_beam_size_x

	# wait for the moves to complete
	wait_for_devices slit_1_horiz_gap slit_2_horiz_gap
}


proc beam_size_x_set { new_beam_size_x } {

    if {$new_beam_size_x < 0} {
        return -code error "new beam size x must >= 0.0"
    }

	# global variables
	variable slit_1_horiz_gap
	variable slit_2_horiz_gap

	# set the two motors
	set slit_1_horiz_gap $new_beam_size_x
	set slit_2_horiz_gap $new_beam_size_x
}


proc beam_size_x_update {} {

	# global variables
	variable slit_1_horiz_gap
	variable slit_2_horiz_gap

	# calculate from real motor positions and motor parameters
	return [beam_size_x_calculate $slit_1_horiz_gap $slit_2_horiz_gap]
}


proc beam_size_x_calculate { s1hg s2hg } {
    set result [expr ($s1hg > $s2hg) ? $s2hg : $s1hg]

    if {$result < 0.0} {
        set result 0.0
    }
    return $result
}

