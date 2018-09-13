proc beamstopOut_initialize {} {

}

proc beamstopOut_start {} {

	global gDevice
	variable beamstop_angle
	#puts "the beamstop_angle = $gDevice(beamstop_angle,scaled)"
#	set p [expr abs($gDevice(beamstop_angle,scaled))-20.92]
#	puts "beamstop p=$p"

        if { abs([expr $gDevice(beamstop_angle,scaled)-20.92])  < 2 } {
			#rotate beamstop 90 degree
			move beamstop_angle by 90 deg
    	}
}
