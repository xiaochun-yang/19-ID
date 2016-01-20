# mirror_vert_corr.tcl

proc mirror_vert_initialize {} {

	# specify children devices
	set_children mirror_v
}


proc mirror_vert_move { new_mirror_vert } {

	# global variables
	variable mirror_v
	global gDevice
    
        #before we move the motor, check encoder sanity by first comparing the encoder to the expected position
        correctMirrorVEncoder 

	# move mirror_v motor
	move mirror_v to $new_mirror_vert

	# wait for the move to complete
	if { [catch { wait_for_devices mirror_v } errorResult] } {
		#wait for mirror_v to slide a little
		after 200
	}

        correctMirrorVEncoder
}


proc mirror_vert_set { new_mirror_vert } {

	# global variables
	variable mirror_v
	variable mirror_vert_offset

	get_encoder mirror_vert_encoder
	set mirror_vert_encoder_value [wait_for_encoder mirror_vert_encoder]

        set mirror_vert_offset [expr $new_mirror_vert - $mirror_vert_encoder_value ]

        log_warning mirror_vert_encoder: $mirror_vert_encoder_value
        log_warning mirror_vert_offset:  $mirror_vert_offset

	set mirror_v $new_mirror_vert
}


proc mirror_vert_update {} {

	# global variables
	variable mirror_v

	return $mirror_v
}


proc mirror_vert_calculate { dz } {
	
	return $dz
}


proc correctMirrorVEncoder {} {
	variable mirror_v
	variable mirror_vert_offset
        
	get_encoder mirror_vert_encoder
	set mirror_vert_encoder_value [wait_for_encoder mirror_vert_encoder]
	set mirror_vert_encoder_value \
        [expr $mirror_vert_encoder_value + $mirror_vert_offset]]
	
	#calculate how far off the encoder is
	set delta [expr $mirror_vert_encoder_value - $mirror_v]

	#if the difference is greater than 3 mm
	if { abs($delta) > 3.0 } {
		#unfortunately we need human intervention at this point
		log_severe "mirror_v is at $mirror_v, encoder is at $mirror_vert_encoder_value mm"
		log_severe "mirror_v differs by too much ($delta mm)"
		return -code error "mirror_vert_encoder differs by too much"
	} elseif { abs( $delta ) > 0.1  } {
		log_note "mirror_v corrected to $mirror_vert_encoder_value mm, change of $delta mm."
		#reset the mirror_v position
		set mirror_v $mirror_vert_encoder_value
	}
}

