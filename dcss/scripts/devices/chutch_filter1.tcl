# chutch_filter1.tcl


proc chutch_filter1_initialize {} {
	
	# specify children devices
	set_children white_beam_filter1
}


proc chutch_filter1_move { new_chutch_filter1 } {

	# global variables
	variable whte_beam_filter_1

	# move white_beam_filter1
	set new_position [chutch_filter1_calculate $new_chutch_filter1]
	move white_beam_filter1 to $new_position

	# wait for the moves to complete
	wait_for_devices white_beam_filter1
}


proc chutch_filter1_set { new_chutch_filter1} {

	# global variables
	variable white_beam_filter1
        set white_beam_filter1 [chutch_filter1_calculate $new_chutch_filter1]
}


proc chutch_filter1_update {} {

	# global variables
	variable white_beam_filter1
        return [chutch_filter1_calculate1 $white_beam_filter1]
}


proc chutch_filter1_calculate { num } {

	variable white_beam_filter1
	if { $num == 1 } {
                        return 19.2
        } elseif { $num == 2 } {
                        return 1
        } elseif { $num == 3 } {
                        return -17.5
        } elseif { $num == 4 } {
                        return -35.5
        } else {
                        return $white_beam_filter1
        }
}

proc chutch_filter1_calculate1 { white_beam_filter1 } {
        variable chutch_filter1
        
        if { [expr abs([expr $white_beam_filter1 - 19.2])] < 0.2 } {
                return 1
        } elseif { [expr abs([expr $white_beam_filter1 - 1])] < 0.2 } {
                return 2
        } elseif { [expr abs([expr $white_beam_filter1 + 17.5])] < 0.2 } {
                return 3
        } elseif { [expr abs([expr $white_beam_filter1 + 35.5])] < 0.2 } {
                return 4
        } else {
                return $chutch_filter1
        }
}

