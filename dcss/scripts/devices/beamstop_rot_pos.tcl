# beamstop_rot_pos.tcl


proc beamstop_rot_pos_initialize {} {
	
	# specify children devices
	set_children beamstop_horz
}


proc beamstop_rot_pos_move { new_beamstop_rot_pos } {

	# global variables
	variable beamstop_horz

	# move beamstop_horz
	move beamstop_horz to [beamstop_rot_pos_calculate $new_beamstop_rot_pos] 

	# wait for the moves to complete
	wait_for_devices beamstop_horz
}


proc beamstop_rot_pos_set { new_beamstop_rot_pos} {

	# global variables
	variable beamstop_horz
        set beamstop_horz [beamstop_rot_pos_calculate $new_beamstop_rot_pos]
}


proc beamstop_rot_pos_update {} {

	# global variables
	variable beamstop_horz
        return [beamstop_rot_pos_calculate1 $beamstop_horz]
}


proc beamstop_rot_pos_calculate { num } {

	variable beamstop_horz
	if { $num == 1 } {
                        return 359.0
        } elseif { $num == 2 } {
                        return 309.9
        } else {
                        return $beamstop_horz
        }
}

proc beamstop_rot_pos_calculate1 { beamstop_horz } {
        variable beamstop_rot_pos
        
        if { [expr abs([expr $beamstop_horz - 359])] < 0.2 } {
                return 1
        } elseif { [expr abs([expr $beamstop_horz -309.9])] < 0.2 } {
                return 2
        } else {
                return $beamstop_rot_pos
        }
}

