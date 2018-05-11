# beamstop_x.tcl


proc beamstop_x_initialize {} {
	
	# specify children devices
	set_children beamstop_angle
}


proc beamstop_x_move { new_beamstop_x } {

	# global variables
	variable beamstop_angle

	# move beamstop_angle
	move beamstop_angle to [beamstop_x_calculate $new_beamstop_x] 

	# wait for the moves to complete
	wait_for_devices beamstop_angle
}


proc beamstop_x_set { new_beamstop_x} {

	# global variables
	variable beamstop_angle
        set beamstop_angle [beamstop_x_calculate $new_beamstop_x]
}


proc beamstop_x_update {} {

	# global variables
	variable beamstop_angle
        return [beamstop_x_calculate1 $beamstop_angle]
}


proc beamstop_x_calculate { x } {

	#l is the rotation radiu
	set l 57.93
	return [expr (asin($x/$l)*180/3.14159)]
}

proc beamstop_x_calculate1 { beamstop_angle } {
        
	set l 57.93
        return [expr ($l*sin($beamstop_angle*3.14159/180))]
}

