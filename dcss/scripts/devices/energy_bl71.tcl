# energy.tcl


proc energy_initialize {} {
	
	# specify children devices
	set_children mono_theta mono_bend d_spacing table_slide table_yaw table_pitch table_vert table_horz mirror_feedback_detector_vert 
}

proc energy_motorlist {} {

        # specify motors which move during e-tracking for BL7-1, omitting mono_angle/mono_theta

        set result [list table_slide table_horz_1 table_horz_2 table_vert_1 table_vert_2 mirror_feedback_detector_vert]

        return $result
}

proc energy_move { new_energy } {

	# global variables
	variable energy
	variable d_spacing
	variable mono_bend
	variable table_slide_offset
	variable table_vert_1_offset
	variable table_vert_2_offset
    variable table_horz_1_offset
    variable table_horz_2_offset
 	variable table_vert_offset
    variable detector_z
    variable energy_mfd_vert_offset
   
	# calculate destination for mono_theta
	set new_mono_theta \
    [energy_calculate_mono_theta $new_energy $d_spacing]

	set new_table_slide [expr \
    [energy_calculate_table_slide $new_mono_theta ] + $table_slide_offset \
    ]

	set new_table_vert_1 [expr \
    [energy_calculate_table_vert_1 $new_mono_theta ] + \
    $table_vert_1_offset \
    ]

    set new_table_vert_2 [expr \
    [energy_calculate_table_vert_2 $new_mono_theta ] + $table_vert_2_offset \
    ]

    set new_table_horz_1 [expr \
    [energy_calculate_table_horz_1 $new_mono_theta ] + $table_horz_1_offset \
    ]

    set new_table_horz_2 [expr \
    [energy_calculate_table_horz_2 $new_mono_theta ] + $table_horz_2_offset \
    ]
 
    set new_mono_bend [energy_calculate_mono_bend $new_mono_theta]

    set new_mirror_feedback_detector_vert [expr \
    [energy_calculate_mirror_feedback_detector_vert $new_mono_theta ] \
    + $energy_mfd_vert_offset]
#   you need to modify the line above to add the mfd_vert_offset variable

    #### check motor limits
	assertMotorLimit mono_theta $new_mono_theta
	assertMotorLimit table_slide $new_table_slide
	assertMotorLimit table_vert_1 $new_table_vert_1
	assertMotorLimit table_vert_2 $new_table_vert_2
	assertMotorLimit table_horz_1 $new_table_horz_1
	assertMotorLimit table_horz_2 $new_table_horz_2
	assertMotorLimit mono_bend $new_mono_bend
    assertMotorLimit mirror_feedback_detector_vert $new_mirror_feedback_detector_vert
	# move 
	move mono_theta to $new_mono_theta
	move table_slide to $new_table_slide
	move table_vert_1 to $new_table_vert_1
	move table_vert_2 to $new_table_vert_2
	move table_horz_1 to $new_table_horz_1
	move table_horz_2 to $new_table_horz_2
    move mono_bend to $new_mono_bend
    move mirror_feedback_detector_vert to $new_mirror_feedback_detector_vert
	if {[catch {
        wait_for_devices \
        mono_theta \
        table_slide \
        table_vert_1 table_vert_2 \
        table_horz_1 table_horz_2 \
        mono_bend \
        mirror_feedback_detector_vert
    } err]} {
        log_error "error moving energy: $err"
        return -code error $err
    }
}

proc energy_set { new_energy } {

	# global variables
	variable d_spacing
	variable mono_theta
	variable mono_bend
	variable table_slide
	variable table_slide_offset
	variable table_vert_1
	variable table_vert_1_offset
	variable table_vert_2
	variable table_vert_2_offset
    variable table_horz_1
    variable table_horz_1_offset
    variable table_horz_2
    variable table_horz_2_offset
    variable mirror_feedback_detector_vert
    variable energy_mfd_vert_offset

	# calculate position of mono_theta (from 7-1 file)
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]	

    ###this is the line to really save the energy offset
	if { abs ( $mono_theta - $new_mono_theta) > 0.001 } { 
		# set position of mono_theta	
		set mono_theta $new_mono_theta
	}

        # Comment for fixed energy
	# set table_slide_offset
	 set table_slide_offset [expr $table_slide - [energy_calculate_table_slide $new_mono_theta ] ]

	# set table_vert_1 offset
	set table_vert_1_offset [expr $table_vert_1 - [energy_calculate_table_vert_1 $new_mono_theta ] ]

	# set table_vert_2_offset
	set table_vert_2_offset [expr $table_vert_2 - [energy_calculate_table_vert_2 $new_mono_theta ] ]

    # set table_horz_1_offset
    set table_horz_1_offset [expr $table_horz_1 - [energy_calculate_table_horz_1 $new_mono_theta]] 

   # set table_horz_2_offset
   set table_horz_2_offset [expr $table_horz_2 - [energy_calculate_table_horz_2 $new_mono_theta]]

   # set mfd_vert_offset
   set energy_mfd_vert_offset [expr \
   $mirror_feedback_detector_vert - [energy_calculate_mirror_feedback_detector_vert $new_mono_theta ]]

}

proc energy_update {} {

	# global variables
	variable mono_theta
	variable mono_bend
	variable d_spacing
	variable table_slide
	variable table_yaw 
	variable table_pitch 
	variable table_vert 
	variable table_horz
    variable mirror_feedback_detector_vert

	# calculate from real motor positions and motor parameters
	return [energy_calculate $mono_theta $mono_bend $d_spacing $table_slide $table_yaw $table_pitch $table_vert $table_horz $mirror_feedback_detector_vert]
}

#set_children mono_theta mono_bend d_spacing table_slide table_yaw table_pitch table_vert table_horz mirror_feedback_detector_vert 
proc energy_calculate { mt mb ds ts ty tp tv th mfdv } {

	# return obviously bad value for energy if d_spacing or mono_theta close to zero
	if { $ds < 0.0001 || $mt < 0.0001 } {
		return 0.01
	}

	# calculate energy from d_spacing and mono_theta
	return [expr 12398.4244 / (2.0 * $ds * sin([rad $mt]) ) ]
}


proc energy_calculate_mono_theta { e ds } {

	# return error if d_spacing or mono_theta close to zero
	if { $ds < 0.0001 || $e < 0.0001 } {
		error
	}

	# calculate mono_theta from energy and d_spacing
	return [deg [expr asin(  12398.4244 / ( 2.0 * $ds * $e ) ) ]]
}

proc energy_calculate_table_slide { mt } {

    set a  -1065.82 
    set b    102.564 
    set c      2.74546 
    set d     -0.160341 
    set e      0.00341393 

    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt + \
    $d * $mt * $mt * $mt + \
    $e * $mt * $mt * $mt * $mt \
    ]
}


proc energy_calculate_table_vert_2 { mt } {

    set a  34.436724  
    set b  -0.889741445 
    set c  0.021563
    set d  -0.001106056 

    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt + \
    $d * $mt * $mt * $mt \
    ]
}

proc energy_calculate_table_vert_1 { mt } {

    set a  18.36628       
    set b  -0.2244941    
    set c  -0.01398182

    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt  \
    ]
} 

proc energy_calculate_table_horz_1 { mt} {

 if { $mt >= 12.689 } {
    return [expr 18.83]
 } else {
    return [expr 19.23]
 }

}

proc energy_calculate_table_horz_2 { mt } {

    set a  35.4837
    set b  -8.11784
    set c   1.00201
    set d  -0.0532989
    set e   0.00105722

    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt + \
    $d * $mt * $mt * $mt + \
    $e * $mt * $mt * $mt * $mt \
    ]
}

proc energy_calculate_mono_bend { mt } {

expr 3535
 
}

proc energy_calculate_mirror_feedback_detector_vert { mt } {

     set a -0.0145515
     set b -0.09149
     set c 4.3824
     set d -0.07712
     set e 0.9895
     set f 3.12503

     if { $mt >= 16.05 } {
     return [expr \
     $f + \
     $e * $mt + \
     $d * $mt * $mt \
     ]
     } else {
     return [expr \
     $c + \
     $b * $mt + \
     $a * $mt * $mt \
     ]
     }
}
