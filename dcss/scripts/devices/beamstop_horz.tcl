# beamstop_horz.tcl
# beamstop_horz = l x sin(beamstop_angle)
# beamstop_angle = 20.92, beamstop is on the sample position.
# beamstop_angle = 20.92 - 49.09 = -19.02 is the yag position
# beamstop_angle = 20.92 - 90 = -69.08 is 90 degree from the sample

proc beamstop_horz_initialize {} {
	
	# specify children devices
	set_children beamstop_angle
}


proc beamstop_horz_move { new_beamstop_horz } {

	# global variables
	variable beamstop_angle

	# move beamstop_angle
	move beamstop_angle to [beamstop_horz_calculate $new_beamstop_horz] 

	# wait for the moves to complete
	wait_for_devices beamstop_angle
}


proc beamstop_horz_set { new_beamstop_horz} {

	# global variables
	variable beamstop_angle
        set beamstop_angle [beamstop_horz_calculate $new_beamstop_horz]
}


proc beamstop_horz_update {} {

	# global variables
	variable beamstop_angle
	set l 57.93
        return [expr ($l*sin($beamstop_angle*3.14159/180))]
}


proc beamstop_horz_calculate { x } {

	#l is the rotation radiu
	set l 57.93
	return [expr (asin($x/$l)*180/3.14159)]
}