# beamstop_vert.tcl


proc beamstop_vert_initialize {} {
	
	# specify children devices
	set_children beamstop_angle beamstop_vert_offset
}


proc beamstop_vert_move { new_beamstop_vert } {

	# global variables
	variable beamstop_angle
	variable beamstop_vert_offset

	# move beamstop_angle
	move beamstop_angle to [beamstop_vert_calculate $new_beamstop_vert] 

	# wait for the moves to complete
	wait_for_devices beamstop_angle
}


proc beamstop_vert_set { new_beamstop_vert} {

	# global variables
        set beamstop_angle [beamstop_vert_calculate $new_beamstop_vert]
}


proc beamstop_vert_update {} {

	# global variables
	variable beamstop_angle
	variable beamstop_vert_offset

        set l 57.93
        return [expr $beamstop_vert_offset + ($l*cos($beamstop_angle*3.14159/180))]

}

proc beamstop_vert_calculate { y } {

	variable beamstop_vert_offset

	#l is the rotation radiu
	set l 57.93
	return [expr (acos(($y-$beamstop_vert_offset)/$l)*180/3.14159)]
}
