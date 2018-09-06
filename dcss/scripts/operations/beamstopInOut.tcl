beamstopInOut_initialize {} {

}

beamstopInOut_start {} {

	global gDevice
	variable beamstop_horz
	set p [abs($gDevice(beamstop_horz,scaled)]
	puts "the beamstop_horz = $p"

	if { abs($gDevice(beamstop_horz,scaled)  < 2 } {
		#move horz beamstop to 57.93 mm
		move beamstop_horz to 57.93 mm
	       	# 	log_error kappa must be zero to run auto_sample_data
        	#	return 0
    	} else {
		move beamstop_horz to 0 mm
	}
}
