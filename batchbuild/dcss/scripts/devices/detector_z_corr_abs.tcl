# detector_z_corr.tcl

proc detector_z_corr_initialize {} {

	# specify children devices
	set_children detector_z
}


proc detector_z_corr_move { new_detector_z_corr } {

	# global variables
	variable detector_z
	global gDevice
    
    #before we move the motor, check encoder sanity by first comparing the encoder to the expected position
    correctDetectorZEncoder 

	# move detector_z motor
	move detector_z to $new_detector_z_corr

	# wait for the move to complete
	if { [catch { wait_for_devices detector_z } errorResult] } {
		#wait for detector_z to slide a little
		after 200
	}

    correctDetectorZEncoder
}


proc detector_z_corr_set { new_detector_z_corr } {

	# global variables
	variable detector_z
	variable detector_z_offset

	get_encoder detector_z_encoder
	set detector_z_encoder_value [wait_for_encoder detector_z_encoder]

    set detector_z_offset [expr $new_detector_z_corr - $detector_z_encoder_value ]

	set detector_z $new_detector_z_corr
}


proc detector_z_corr_update {} {

	# global variables
	variable detector_z

	return $detector_z
}


proc detector_z_corr_calculate { dz } {
	
	return $dz
}


proc correctDetectorZEncoder {} {
	variable detector_z
	variable detector_z_offset

	get_encoder detector_z_encoder
	set detector_z_encoder_value [wait_for_encoder detector_z_encoder]
	set detector_z_encoder_value \
    [expr $detector_z_encoder_value + $detector_z_offset]
        
	#calculate how far off the encoder is
	set delta [expr $detector_z_encoder_value - $detector_z]

	#if the difference is greater than 2 cm
	if { abs($delta) > 20.0 } {
		#unfortunately we need human intervention at this point
		log_severe "detector_z is at $detector_z, encoder is at $detector_z_encoder_value mm"
		log_severe "detector_z differs by too much ($delta mm)"
		return -code error "detector_z_encoder differs by too much"
	} elseif { abs( $delta ) > 0.1  } {
		log_note "detector_z corrected to $detector_z_encoder_value mm, change of $delta mm."
		#reset the detector_z position
		set detector_z $detector_z_encoder_value
	}
}

