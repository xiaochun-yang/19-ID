#c_hutch_filter_2.tcl
#
#
c_hutch_filter_2_initialize {} {
        set_children white_beam_filter2
}

proc c_hutch_filter_2_move { new_filter_number } {
	variable whte_beam_filter_2

	set new_white_beam_filter2 [c_hutch_filter_2_calculate $new_filter_number]
	move white_beam_filter2 $new_white_beam_filter2
	wait_for_devices white_beam_filter2
}

proc c_hutch_filter_2_set {new_filter_number}

	variable white_beam_filter2
	set new_white_beam_filter2 [c_hutch_filter_2_calculate $new_fileter_number]
}

proc c_hutch_filter_2_update{} {

	variable white_beam_filter2
	return [filter_number_calculate $white_beam_filter2]
}

c_hutch_filter_2_calculate { num } {

	variable white_beam_filter2
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
			return $white_beam_filter2
		}
	}
}

filter_number_calculate { white_beam_filter2 } {

	variable c_hutch_filter_2
	if { [expr abs([expr $whte_beam_filter2 - 19])] < 0.2 } {
		return 1
	} else if { [expr abs([expr $whte_beam_filter2 - 1])] < 0.2 } {
		return 2
	} else if { [expr abs([expr $whte_beam_filter2 + 17.5])] < 0.2 } {
                return 3
	} else if { [expr abs([expr $whte_beam_filter2 + 35.5])] < 0.2 } {
                return 4
	} else {
		return $c_hutch_filter_2
	}
}

