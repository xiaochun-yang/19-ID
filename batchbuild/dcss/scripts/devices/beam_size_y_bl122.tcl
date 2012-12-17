# beam_size_y.tcl

proc beam_size_y_initialize {} {

	# specify children devices
	set_children slit_2_vert_gap
}


proc beam_size_y_move { new_beam_size_y } {

    if {$new_beam_size_y < 0} {
        return -code error "beam size y must >= 0.0"
    }

	# move the two motors
	move slit_2_vert_gap to $new_beam_size_y

	# wait for the moves to complete
	wait_for_devices slit_2_vert_gap
}


proc beam_size_y_set { new_beam_size_y } {

    if {$new_beam_size_y < 0} {
        return -code error "beam size y must >= 0.0"
    }

	# global variables
	variable slit_2_vert_gap
	
	# set the two motors
	set slit_2_vert_gap $new_beam_size_y
}


proc beam_size_y_update {} {

	# global variables
	variable slit_2_vert_gap

	# calculate from real motor positions and motor parameters
	return [beam_size_y_calculate $slit_2_vert_gap]
}


proc beam_size_y_calculate { s2vg } {
    set result $s2vg

    if {$result < 0.0} {
        set result 0.0
    }
    return $result
}

