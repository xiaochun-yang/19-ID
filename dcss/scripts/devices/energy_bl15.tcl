# energy.tcl


proc energy_initialize {} {
	
	# specify children devices
set_children mono_theta d_spacing table_pitch table_vert table_yaw table_horz
}

proc energy_motorlist {} {

        # specify motors which move during e-tracking for BL1-5, omitting mono_angle/mono_theta

        set result [list table_vert_1 table_vert_2]

        return $result
}

proc energy_move { new_energy } {

	# global variables
	variable energy
	variable d_spacing
#	variable table_horz_1_offset
#	variable table_horz_2_offset
	variable table_vert_1_offset
	variable table_vert_2_offset	

	# calculate destination
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]

	set new_table_vert_1 [expr \
    [energy_calculate_table_vert_1 $new_mono_theta] + $table_vert_1_offset \
    ]

	set new_table_vert_2 [expr \
    [energy_calculate_table_vert_2 $new_mono_theta] + $table_vert_2_offset \
    ]

	assertMotorLimit mono_theta $new_mono_theta
	assertMotorLimit table_vert_1 $new_table_vert_1
	assertMotorLimit table_vert_2 $new_table_vert_2

	# move 
	move mono_theta to $new_mono_theta
	move table_vert_1 to $new_table_vert_1
	move table_vert_2 to $new_table_vert_2

    wait_for_devices table_vert_1 table_vert_2 mono_theta
}


proc energy_set { new_energy } {

	# global variables
	variable d_spacing
	variable mono_theta
#	variable table_horz_1
#	variable table_horz_1_offset
#	variable table_horz_2
#	variable table_horz_2_offset
	variable table_vert_1
	variable table_vert_1_offset
	variable table_vert_2
	variable table_vert_2_offset

	# calculate position of mono_theta
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]	

	# set position of mono_theta	
	set mono_theta $new_mono_theta

	# set table_horz_1_offset
#	set table_horz_1_offset [expr $table_horz_1 - [energy_calculate_table_horz_1 $new_mono_theta] ]

	# set table_horz_2_offset
#	set table_horz_2_offset [expr $table_horz_2 - [energy_calculate_table_horz_2 $new_mono_theta] ]

	# set table_vert_1_offset
	set table_vert_1_offset [expr $table_vert_1 - [energy_calculate_table_vert_1 $new_mono_theta] ]

	# set table_vert_2_offset
	set table_vert_2_offset [expr $table_vert_2 - [energy_calculate_table_vert_2 $new_mono_theta] ]
}


proc energy_update {} {

	# global variables
	variable mono_theta
	variable d_spacing

	# calculate from real motor positions and motor parameters
	return [energy_calculate $mono_theta $d_spacing 0 0 0 0]
}

proc energy_calculate { mt ds tp ty tv th } {

	# return obviously bad value for energy if d_spacing or mono_theta close to zero
	if { $ds < 0.0001 || $mt < 0.0001 } {
		return 0.01
	}

	# calculate energy from d_spacing and mono_theta
	return [expr 12398.4244 / (2.0 * $ds * sin([rad $mt]) ) ]
}


proc energy_calculate_mono_theta { e ds } {

	# return error if d_spacing or energy close to zero
	if { $ds < 0.0001 || $e < 0.0001 } {
		error
	}

	# calculate mono_theta from energy and d_spacing
	return [deg [expr asin(  12398.4244 / ( 2.0 * $ds * $e ) ) ]]
}

proc energy_calculate_table_vert_1 { mt } {
    set a 1.8382772174250103e+01
    set b 1.1103005873734181e-02
    set c 2.3239771240841918e-03
    set d -5.3869039094578603e-05
    ### max abs error: 9.5309627085653926e-03

    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt + \
    $d * $mt * $mt * $mt \
    ]
}
proc energy_calculate_table_vert_2 { mt } {
    set a 3.7537070930775741e+01
    set b 1.4363069847326056e-02
    set c 2.1870876367425149e-03
    set d -5.4188993461949394e-05
    ### max abs error: 9.4174560933547938e-03

    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt + \
    $d * $mt * $mt * $mt \
    ]
}

