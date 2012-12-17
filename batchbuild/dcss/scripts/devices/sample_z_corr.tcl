# sample_z_corr.tcl

proc sample_z_corr_initialize {} {

	# specify children devices
	set_children sample_z
}


proc sample_z_corr_move { new_sample_z_corr } {

	# global variables
	variable sample_z
	global gDevice
    
    #before we move the motor, check encoder sanity by first comparing the encoder to the expected position
    correctSampleZEncoder 

	# move sample_z motor
	move sample_z to $new_sample_z_corr

	# wait for the move to complete
	if { [catch { wait_for_devices sample_z } errorResult] } {
		#wait for sample_z to slide a little
		after 200
	}

    correctSampleZEncoder
}


proc sample_z_corr_set { new_sample_z_corr } {

	# global variables
	variable sample_z
	variable sample_z_offset

	get_encoder sample_z_encoder
	set sample_z_encoder_value [wait_for_encoder sample_z_encoder]

    set sample_z_offset [expr $new_sample_z_corr - $sample_z_encoder_value ]

    log_warning sample_z_encoder: $sample_z_encoder_value
    log_warning sample_z_offset:  $sample_z_offset

	set sample_z $new_sample_z_corr
}


proc sample_z_corr_update {} {

	# global variables
	variable sample_z

	return $sample_z
}


proc sample_z_corr_calculate { dz } {
	
	return $dz
}


proc correctSampleZEncoder {} {
	variable sample_z
	variable sample_z_offset
        
	get_encoder sample_z_encoder
	set sample_z_encoder_value [wait_for_encoder sample_z_encoder]
	set sample_z_encoder_value \
    [expr $sample_z_encoder_value + $sample_z_offset]]
	
	#calculate how far off the encoder is
	set delta [expr $sample_z_encoder_value - $sample_z]

	#if the difference is greater than 3 mm
	if { abs($delta) > 3.0 } {
		#unfortunately we need human intervention at this point
		log_severe "sample_z is at $sample_z, encoder is at $sample_z_encoder_value mm"
		log_severe "sample_z differs by too much ($delta mm)"
		return -code error "sample_z_encoder differs by too much"
	} elseif { abs( $delta ) > 0.1  } {
		log_note "sample_z corrected to $sample_z_encoder_value mm, change of $delta mm."
		#reset the sample_z position
		set sample_z $sample_z_encoder_value
	}
}

