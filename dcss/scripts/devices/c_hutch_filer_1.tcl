#c_hutch_filter_1.tcl
#
#
c_hutch_filter_1_initialize {} {
        set_children white_beam_filter1
}

proc c_hutch_filter_1_move { new_filter_number } {
	variable whte_beam_filter_1

	set new_white_beam_filter1 [c_hutch_filter_1_calculate $new_filter_number]
	move white_beam_filter1 $new_white_beam_filter1
	wait_for_devices white_beam_filter1
}

proc c_hutch_filter_1_set {new_filter_number}

	variable white_beam_filter1
	set new_white_beam_filter1 [c_hutch_filter_1_calculate $new_fileter_number]
}

proc c_hutch_filter_1_update{} {

	variable white_beam_filter1
	return [filter_number_calculate $white_beam_filter1]
}

c_hutch_filter_1_calculate { num } {

	variable white_beam_filter1
	switch -- $num {
		
		1 {
			return 19
		}
		2 {
			return 1
		}
		3 {
			return -17.5
		}
		4 {
			return -35.5
		}
		default {
			return $white_beam_filter1
		}
	}
}

filter_number_calculate { white_beam_filter1 } {

	variable c_hutch_filter_1
	if { [expr abs([expr $whte_beam_filter1 - 19])] < 0.2 } {
		return 1
	} else if { [expr abs([expr $whte_beam_filter1 - 1])] < 0.2 } {
		return 2
	} else if { [expr abs([expr $whte_beam_filter1 + 17.5])] < 0.2 } {
                return 3
	} else if { [expr abs([expr $whte_beam_filter1 + 35.5])] < 0.2 } {
                return 4
	} else {
		return $c_hutch_filter_1
	}
}

