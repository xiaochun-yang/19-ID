# beamstop_rota.tcl


proc beamstop_rota_initialize {} {
	
	# specify children devices
	set_children beamstop_horz
}


proc beamstop_rota_move { new_beamstop_rota } {

	# global variables
	variable beamstop_horz

	# move beamstop_horz
	move beamstop_horz to [beamstop_rota_calculate $new_beamstop_rota] 

	# wait for the moves to complete
	wait_for_devices beamstop_horz
}


proc beamstop_rota_set { new_beamstop_rota} {

	# global variables
	variable beamstop_horz
        set beamstop_horz [beamstop_rota_calculate $new_beamstop_rota]
}


proc beamstop_rota_update {} {

	# global variables
	variable beamstop_horz
        return [beamstop_rota_calculate1 $beamstop_horz]
}


proc beamstop_rota_calculate { num } {

	variable beamstop_horz
	if { $num == 1 } {
                        return 359.0
        } elseif { $num == 2 } {
                        return 270       
        } elseif { $num == 3 } {
                        return 309.9
        } else {

                        return $beamstop_horz
        }
}

proc beamstop_rota_calculate1 { beamstop_horz } {
        variable beamstop_rota
        
        if { [expr abs([expr $beamstop_horz - 359])] < 0.2 } {
                return 1
        } elseif { [expr abs([expr $beamstop_horz -270])] < 0.2 } {
                return 2
        } elseif { [expr abs([expr $beamstop_horz -309.9])] < 0.2 } {
                return 3
        } else {
                return $beamstop_rota
        }
}

