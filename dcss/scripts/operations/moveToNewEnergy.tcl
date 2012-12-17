# moveToNewEnergy.tcl
# This script is to use the console function wraped with bluice
# to change energy at x4a bleamline at NSLS. 

proc moveToNewEnergy_initialize {} {

}

proc moveToNewEnergy_start { Enery } {
	set eHandle [start_waitable_operation move_to_new_energy $Energy]
	set eResult [wait_for_operation $eHandle]
	set statu [lindex $eResult 0]
	log_note "Yang: move energy result: $eResult")

	if { ($statu != "normal") }{
		log_error "Could not move the energy to $Energy"
        	return
	}
}

