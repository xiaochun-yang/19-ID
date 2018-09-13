proc beamstopIn_initialize {} {

}

proc beamstopIn_start {} {

	global gDevice
	variable beamstop_angle
	#puts "the beamstop_angle = $gDevice(beamstop_angle,scaled)"
#	set p [expr abs($gDevice(beamstop_angle,scaled))-110.92]
#	puts "the beamstop_angle = $p"

	if { abs([expr $gDevice(beamstop_angle,scaled)-110.92])  < 2 } {
			#rotate beamstop 90 degree
			move beamstop_angle by -90 deg
    	}
}
