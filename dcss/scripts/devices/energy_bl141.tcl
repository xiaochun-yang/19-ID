# energy.tcl

proc energy_initialize {} {
	set_children mono_theta_corr d_spacing table_vert
}

proc energy_motorlist {} {

        # specify motors which move during e-tracking for omitting mono_angle/mono_theta/mono_theta_corr

        set result [list table_vert_1 table_vert_2]

        return $result
}

proc energy_move { new_energy } {
	# global variables
	variable d_spacing
	variable energy
	variable table_vert_1
	variable table_vert_2

	variable table_vert_2_offset
	variable table_vert_1_offset
 
	# calculate destination
	set new_mono_theta \
    [energy_calculate_mono_theta $new_energy $d_spacing]

	set new_table_vert_1 [expr \
    [energy_calculate_table_vert_1 $new_mono_theta] + \
    $table_vert_1_offset \
    ]

	set new_table_vert_2 [expr \
    [energy_calculate_table_vert_2 $new_mono_theta ] + \
    $table_vert_2_offset  \
    ]

	assertMotorLimit mono_theta $new_mono_theta 
	assertMotorLimit table_vert_1 $new_table_vert_1
	assertMotorLimit table_vert_2 $new_table_vert_2

	# move destination
	move mono_theta_corr to $new_mono_theta 
	move table_vert_1 to $new_table_vert_1
	move table_vert_2 to $new_table_vert_2

	# wait for the move to complete
	wait_for_devices mono_theta_corr  table_vert_1 table_vert_2 
}


proc energy_set { new_energy } {

	# global variables
	variable d_spacing
	variable mono_theta_corr
	variable table_vert_1_offset
	variable table_vert_2_offset
	variable table_vert_1
	variable table_vert_2
   
	# calculate position of mono_theta
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]	
	# set position of mono_theta	
	set mono_theta_corr $new_mono_theta



    set table_vert_1_offset [expr $table_vert_1 - [energy_calculate_table_vert_1 $new_mono_theta]]
    set table_vert_2_offset [expr $table_vert_2 - [energy_calculate_table_vert_2 $new_mono_theta]]

#	log_warning "set table 1 offset to $table_vert_1_offset and table 2 offset to $table_vert_2_offset" 
	if { [catch {
            set handle ""
            set handle [open /usr/local/dcs/dcss/tmp/optimizedEnergy.log a ]
            puts $handle "[time_stamp] Set table 1 offset to $table_vert_1_offset and table 2 offset to $table_vert_2_offset"
	        puts $handle ""
	        close $handle
        } ] } {
		log_error "Error opening ../optimizedEnergy.log"
        close $handle
	}

}


proc energy_update {} {

	# global variables
	variable mono_theta_corr
	variable d_spacing

	# calculate from real motor positions and motor parameters
	return [energy_calculate $mono_theta_corr $d_spacing]
}


proc energy_calculate { mtc ds } {

	# return obviously bad value for energy if d_spacing or mono_theta close to zero
	if { $ds < 0.0001 || $mtc < 0.0001 } {
		return 0.01
	}

	# calculate energy from d_spacing and mono_theta
	return [expr 12398.4244 / (2.0 * $ds * sin([rad $mtc]) ) ]
}


proc energy_calculate_mono_theta { e ds } {

	# return error if d_spacing or mono_theta close to zero
	if { $ds < 0.0001 || $e < 0.0001 } {
		error
	}

	# calculate mono_theta from energy and d_spacing
	return [deg [expr asin(  12398.4244 / ( 2.0 * $ds * $e ) ) ]]

}

#Add energy_calculate_table_vert_1 and energy_calculate_table_vert_2
#to make energy reset standard
#uncomment next procedure to roll back

proc energy_calculate_table_vert { mtc} {

	return 20.7827
}


proc energy_calculate_table_vert_1 { mtc} {

	return 20.6367
}
proc energy_calculate_table_vert_2 { mtc} {

	return 21.1074 
}

