# teststop_rota.tcl


proc teststop_rota_initialize {} {
	
	# specify children devices
	set_children teststop_horz
}


proc teststop_rota_move { new_teststop_rota } {

	# global variables
	variable teststop_horz

	# move teststop_horz
	move teststop_horz to [teststop_rota_calculate $new_teststop_rota] 

	# wait for the moves to complete
	wait_for_devices teststop_horz
}


proc teststop_rota_set { new_teststop_rota} {

	# global variables
	variable teststop_horz
        set teststop_horz [teststop_rota_calculate $new_teststop_rota]
}


proc teststop_rota_update {} {

	# global variables
	variable teststop_horz
        return [teststop_rota_calculate1 $teststop_horz]
}


proc teststop_rota_calculate { num } {

	variable teststop_horz
	if { $num == 1 } {
                        return 359.0
        } elseif { $num == 2 } {
                        return 270       
        } elseif { $num == 3 } {
                        return 309.9
        } else {

                        return $teststop_horz
        }
}

proc teststop_rota_calculate1 { teststop_horz } {
        variable teststop_rota
        
        if { [expr abs([expr $teststop_horz - 359])] < 0.2 } {
                return 1
        } elseif { [expr abs([expr $teststop_horz -270])] < 0.2 } {
                return 2
        } elseif { [expr abs([expr $teststop_horz -309.9])] < 0.2 } {
                return 3
        } else {
                return $teststop_rota
        }
}

