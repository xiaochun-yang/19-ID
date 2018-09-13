proc beamstopInOut_initialize {} {

}

proc beamstopInOut_start {bs_in} {

	global gDevice
	variable beamstop_angle
	#puts "the beamstop_angle = $gDevice(beamstop_angle,scaled)"
	set p [expr abs($gDevice(beamstop_angle,scaled))-90]
	puts "the beamstop_angle = $p"

	if {bs_in} {
		if { abs([expr $gDevice(beamstop_angle,scaled)-90])  < 2 } {
			#rotate beamstop 90 degree
			puts "move by -90"
			move beamstop_angle by -90 deg
	       		# 	log_error kappa must be zero to run auto_sample_data
        		#	return 0
    		}
	 else {
		if { abs([expr $gDevice(beamstop_angle,scaled)-0])  < 2 } {
			puts "move by 90"
			move beamstop_angle by 90 deg
		}
	}
}
