# beamstop_location.tcl


proc beamstop_location_initialize {} {
	
	# specify children devices
	set_children beamstop_angle
}


proc beamstop_location_move { new_beamstop_location } {

	# global variables
	variable beamstop_angle

	# move beamstop_angle
	move beamstop_angle to [beamstop_location_calculate $new_beamstop_location] 

	# wait for the moves to complete
	wait_for_devices beamstop_angle
}


proc beamstop_location_set { new_beamstop_location} {

	# global variables
	variable beamstop_angle
        set beamstop_angle [beamstop_location_calculate $new_beamstop_location]
}


proc beamstop_location_update {} {

	# global variables
	variable beamstop_angle
        return [beamstop_location_calculate1 $beamstop_angle]
}


proc beamstop_location_calculate { num } {

	variable beamstop_angle
	if { $num == 1 } {
                        return 359.0
        } elseif { $num == 2 } {
                        return 270       
        } elseif { $num == 3 } {
                        return 309.9
        } else {

                        return $beamstop_angle
        }
}

proc beamstop_location_calculate1 { beamstop_angle } {
        variable beamstop_location
        
        if { [expr abs([expr $beamstop_angle - 359])] < 0.2 } {
                return 1
        } elseif { [expr abs([expr $beamstop_angle -270])] < 0.2 } {
                return 2
        } elseif { [expr abs([expr $beamstop_angle -309.9])] < 0.2 } {
                return 3
        } else {
                return $beamstop_location
        }
}

