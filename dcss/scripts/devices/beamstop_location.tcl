# beamstop_location.tcl


proc beamstop_location_initialize {} {
	
	# specify children devices
	set_children beamstop_horz
}


proc beamstop_location_move { new_beamstop_location } {

	# global variables
	variable beamstop_horz

	# move beamstop_horz
	move beamstop_horz to [beamstop_location_calculate $new_beamstop_location] 

	# wait for the moves to complete
	wait_for_devices beamstop_horz
}


proc beamstop_location_set { new_beamstop_location} {

	# global variables
	variable beamstop_horz
        set beamstop_horz [beamstop_location_calculate $new_beamstop_location]
}


proc beamstop_location_update {} {

	# global variables
	variable beamstop_horz
        return [beamstop_location_calculate1 $beamstop_horz]
}


proc beamstop_location_calculate { num } {

	variable beamstop_horz
	if { $num == 1 } {
                        return 0
        } elseif { $num == 2 } {
                        return 57.93       
        } elseif { $num == 3 } {
                        return 29
        } else {

                        return $beamstop_horz
        }
}

proc beamstop_location_calculate1 { beamstop_horz } {
        variable beamstop_location
        
        if { [expr abs([expr $beamstop_horz - 0])] < 0.01 } {
                return 1
        } elseif { [expr abs([expr $beamstop_horz -57.93])] < 0.01 } {
                return 2
        } elseif { [expr abs([expr $beamstop_horz -29])] < 0.01 } {
                return 3
        } else {
                return $beamstop_location
        }
}

