# detector_z_corr.tcl

#############################################
# add another offset from energy tracking
#############################################

proc detector_z_corr_initialize {} {
	# specify children devices
	set_children detector_z detector_vert detector_horz
}


proc detector_z_corr_move { new_detector_z_corr } {

	# global variables
	variable detector_z

    ### these are the user input on Hutch Tab
	variable detector_center_horz_offset
	variable detector_center_vert_offset

    #### this is set by energy move and
    #### energy will move detector_z_corr by 0
    variable detector_energy_vert_offset

    #### this is our offset
    variable detector_z_horz_offset
    
	set detector_horz_center [calculate_detector_horz_center $new_detector_z_corr]
	set detector_horz_center [expr $detector_horz_center + $detector_z_horz_offset]
	set detector_vert_center [calculate_detector_vert_center $new_detector_z_corr]

    log_warning new horz: $detector_horz_center vert: $detector_vert_center

    #check encoder for sanity
    correctDetectorZEncoder 

	# move detector_z motor
	move detector_z to $new_detector_z_corr
    #In case all detector_z and offsets moved at the same time from the gui. wait for detector_z to finish in order to avoid race conditions.
    wait_for_devices detector_z 
    wait_for_devices detector_center_horz_offset detector_center_vert_offset

    #the detector_offsets should be set by now
	set new_detector_horz [expr $detector_horz_center + $detector_center_horz_offset]
	set new_detector_vert [expr $detector_vert_center + \
    $detector_center_vert_offset]
    if {[energyGetEnabled detector_vert_move]} {
        log_warning DEBUG add detector_energy_vert_offset \
        $detector_energy_vert_offset
	    set new_detector_vert [expr $new_detector_vert + \
        $detector_energy_vert_offset]
    }

    move detector_horz to $new_detector_horz
    move detector_vert to $new_detector_vert
    wait_for_devices detector_horz detector_vert 

    #check encoder for sanity
    correctDetectorZEncoder
}


### this will also set horz.  The vert is energy not here
proc detector_z_corr_set { new_detector_z_corr } {
	variable detector_horz

    ### these are the user input on Hutch Tab
	variable detector_center_horz_offset

    #### this is our offset
    variable detector_z_horz_offset

	# global variables
	variable detector_z
	variable detector_z_offset

	get_encoder detector_z_encoder
	set detector_z_encoder_value [wait_for_encoder detector_z_encoder]

    set detector_z_offset [expr $new_detector_z_corr - $detector_z_encoder_value ]

	set detector_z $new_detector_z_corr

    ### for horz offset
	set detector_horz_center [calculate_detector_horz_center $new_detector_z_corr]

    if {$detector_center_horz_offset != 0.0} {
        log_warning Detector Horz is not 0 on Hutch Tab, but it will be ignored
    }
    set old $detector_z_horz_offset
    set detector_z_horz_offset [expr $detector_horz - $detector_horz_center]
    log_warning detector_horz offset for detector_z changed from \
    $old to $detector_z_horz_offset
}


proc detector_z_corr_update {} {
    variable detector_z

	return $detector_z
}

proc detector_z_corr_calculate { z h v } {
    return $z
}

#calculate where the center of the detector is
#it returns 0 when detector_z==230 mm
#

###04/21/10: Mike Soltis asks to change the horz to floating as all other
###pseudo motors
###
### IMPORTANT: vert is floating in energy, not here

# 11/23/11 Graeme and Mathews new formula, using POLY pin, at room temperature and starting at 300mm:
proc calculate_detector_horz_center { z } {
    set b -2.5995169161534430E-02
    set c  7.6953187562055209E-05
    set d -9.6831627035716124E-08
    set f  4.3068621585762301E-11

    set result [expr \
    $b * $z + \
    $c * $z * $z + \
    $d * $z * $z * $z + \
    $f * $z * $z * $z * $z \
    ]

    #### move opposite
    set result [expr -1 * $result]

    return $result
}




# uncomment the next three lines to disable detector_z corection.
#proc calculate_detector_horz_center { z } {
#    return 0
#}


#calculate where the center of the detector is
#### disabled because max offset is less than 0.15mm.
proc calculate_detector_vert_center { z } {
    return 0.0
}


proc correctDetectorZEncoder {} {
	variable detector_z
	variable detector_z_offset

	get_encoder detector_z_encoder
	set detector_z_encoder_value [wait_for_encoder detector_z_encoder]
	set detector_z_encoder_value \
    [expr $detector_z_encoder_value + $detector_z_offset]]
        
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

