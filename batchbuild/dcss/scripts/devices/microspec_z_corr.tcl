### This cannot use template.
### It will only check after move.  It will not check before move.

proc microspec_z_corr_initialize {} {
	set_children microspec_z
}

proc microspec_z_corr_move { new_microspec_z_corr } {
	variable microspec_z
	global gDevice

    set stepSize [expr 1.0 / $gDevice(microspec_z,scaleFactor)] 
    
    set timesRetry 0
    set dd   [expr $new_microspec_z_corr - $microspec_z]
    while {1} {
	    move microspec_z by $dd
	    if { [catch { wait_for_devices microspec_z } errorResult] } {
		    after 200
            return -code error $errorResult
	    }
        set real [correctmicrospec_zEncoder]
        set dd   [expr $new_microspec_z_corr - $real]
        if {abs($dd) <= $stepSize} {
            break
        }
        incr timesRetry
        if {$timesRetry > 3} {
            log_severe motor microspec_z_corr after 3 times retry, \
            still have delta=$dd > stepSize=$stepSize
            break
        }
        log_warning get more accurate to $new_microspec_z_corr
    }
}

proc microspec_z_corr_set { new_microspec_z_corr } {

	# global variables
	variable microspec_z
	variable microspec_z_offset

	get_encoder microspec_z_encoder
	set microspec_z_encoder_value [wait_for_encoder microspec_z_encoder]

    set microspec_z_offset [expr $new_microspec_z_corr - $microspec_z_encoder_value ]

    log_warning microspec_z_encoder: $microspec_z_encoder_value
    log_warning microspec_z_offset:  $microspec_z_offset

	set microspec_z $new_microspec_z_corr
}


proc microspec_z_corr_update {} {

	# global variables
	variable microspec_z

	return $microspec_z
}


proc microspec_z_corr_calculate { dz } {
	
	return $dz
}


proc correctmicrospec_zEncoder {} {
	variable microspec_z
    variable microspec_z_offset

    get_encoder microspec_z_encoder
    set encoder_position [wait_for_encoder microspec_z_encoder]
    set real_position [expr $encoder_position + $microspec_z_offset]

	set delta [expr $real_position - $microspec_z]

	if { abs($delta) > 0.1 } {
		#unfortunately we need human intervention at this point
		log_severe "microspec_z is at $microspec_z, it in fact is at $real_position mm"
		log_severe "microspec_z differs by too much ($delta mm)"
        log_severe "microspec_z abs_encoder is at $encoder_position"
		return -code error "microspec_z_encoder differs by too much"
	} elseif { abs( $delta ) > 0.004  } {
		log_severe "microspec_z corrected to $real_position mm, change of $delta mm."
		#reset the microspec_z position
		set microspec_z $real_position
	}
    return $real_position
}

