# beamstop_y.tcl


proc beamstop_y_initialize {} {
	
	# specify children devices
	set_children beamstop_angle beamstop_vert
}


proc beamstop_y_move { new_beamstop_y } {

	# global variables
	variable beamstop_angle
	variable beamstop_vert

	# move beamstop_angle
	move beamstop_angle to [beamstop_y_calculate $new_beamstop_y] 

	# wait for the moves to complete
	wait_for_devices beamstop_angle
}


proc beamstop_y_set { new_beamstop_y} {

	# global variables
        set beamstop_angle [beamstop_y_calculate $new_beamstop_y]
}


proc beamstop_y_update {} {

	# global variables
	variable beamstop_angle
	variable beamstop_vert

        set l 57.93
        return [expr $beamstop_vert + ($l*sin($beamstop_angle*3.14159/180))]

}

proc beamstop_y_calculate { y } {

	variable beamstop_vert

	#l is the rotation radiu
	set l 57.93
	return [expr (acos(($y-$beamstop_vert)/$l)*180/3.14159)]
}
