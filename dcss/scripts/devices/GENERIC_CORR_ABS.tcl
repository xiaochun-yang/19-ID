proc PREFIX_corr_initialize {} {
	set_children PREFIX
}

proc PREFIX_corr_move { new_PREFIX_corr } {
	variable PREFIX
	global gDevice
    
    #before we move the motor, check encoder sanity by first comparing the encoder to the expected position
    correctPREFIXEncoder 

	# move PREFIX motor
	move PREFIX to $new_PREFIX_corr

	# wait for the move to complete
	if { [catch { wait_for_devices PREFIX } errorResult] } {
		#wait for PREFIX to slide a little
		after 200
	}

    correctPREFIXEncoder
}


proc PREFIX_corr_set { new_PREFIX_corr } {

	# global variables
	variable PREFIX
	variable PREFIX_offset

	get_encoder PREFIX_encoder
	set PREFIX_encoder_value [wait_for_encoder PREFIX_encoder]

    set PREFIX_offset [expr $new_PREFIX_corr - $PREFIX_encoder_value ]

    log_warning PREFIX_encoder: $PREFIX_encoder_value
    log_warning PREFIX_offset:  $PREFIX_offset

	set PREFIX $new_PREFIX_corr
}


proc PREFIX_corr_update {} {

	# global variables
	variable PREFIX

	return $PREFIX
}


proc PREFIX_corr_calculate { dz } {
	
	return $dz
}


proc correctPREFIXEncoder {} {
	variable PREFIX
	variable PREFIX_offset

	get_encoder PREFIX_encoder
	set PREFIX_encoder_value [wait_for_encoder PREFIX_encoder]
	set PREFIX_encoder_value [expr $PREFIX_encoder_value + $PREFIX_offset]]

	set delta [expr $PREFIX_encoder_value - $PREFIX]

	if { abs($delta) > 1.0 } {
		#unfortunately we need human intervention at this point
		log_severe "PREFIX is at $PREFIX, encoder is at $PREFIX_encoder_value mm"
		log_severe "PREFIX differs by too much ($delta mm)"
		return -code error "PREFIX_encoder differs by too much"
	} elseif { abs( $delta ) > 0.001  } {
		log_note "PREFIX corrected to $PREFIX_encoder_value mm, change of $delta mm."
		#reset the PREFIX position
		set PREFIX $PREFIX_encoder_value
	}
}

