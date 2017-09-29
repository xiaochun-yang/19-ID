# white_beam_filter2.tcl


proc white_beam_filter2_initialize {} {
	
	# specify children devices
	set_children white_beam_filter_2
}


proc white_beam_filter2_move { new_white_beam_filter2 } {

	# global variables
	variable whte_beam_filter_2

	# move white_beam_filter_2
	move white_beam_filter_2 to [white_beam_filter2_calculate $new_white_beam_filter2]

	# wait for the moves to complete
	wait_for_devices white_beam_filter_2
}


proc white_beam_filter2_set { new_white_beam_filter2} {

	# global variables
	variable white_beam_filter_2
        set white_beam_filter_2 [white_beam_filter2_calculate $new_white_beam_filter2]
}


proc white_beam_filter2_update {} {

	# global variables
	variable white_beam_filter_2
        return [white_beam_filter2_calculate1 $white_beam_filter_2]
}


proc white_beam_filter2_calculate { num } {

	variable white_beam_filter_2
	if { $num == 8 } {
                        return 16.23
        } elseif { $num == 7 } {
                        return -2.5
        } elseif { $num == 6 } {
                        return -20
        } elseif { $num == 5 } {
                        return -38.3
        } else {
                        return $white_beam_filter_2
        }
}

proc white_beam_filter2_calculate1 { white_beam_filter_2 } {
        variable white_beam_filter2
        
        if { [expr abs([expr $white_beam_filter_2 - 16.23])] < 0.5 } {
                return 8
        } elseif { [expr abs([expr $white_beam_filter_2 + 2.5])] < 0.5 } {
                return 7
        } elseif { [expr abs([expr $white_beam_filter_2 + 20])] < 0.5 } {
                return 6
        } elseif { [expr abs([expr $white_beam_filter_2 + 38.3])] < 0.5 } {
                return 5
        } else {
                return $white_beam_filter2
        }
}

