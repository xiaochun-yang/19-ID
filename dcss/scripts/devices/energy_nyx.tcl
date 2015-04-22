# energy_nyx.tcl for nyx at nsls2. The mono_theta is servo motor with dual encoder.
# main encoder --- position; dual encoder --- attached with motor.


proc energy_initialize {} {
	set_children mono_theta mono_perp mono_para d_spacing
}


proc energy_move { new_energy } {
	# global variables
	variable d_spacing
	variable energy
	variable mono_perp
	variable mono_para

	variable mono_perp_offset
	variable mono_para_offset
 
	# calculate destination
	set new_mono_theta \
    [energy_calculate_mono_theta $new_energy $d_spacing]

	set new_mono_perp [expr \
    [energy_calculate_mono_perp $new_mono_theta] + $mono_perp_offset]

	set new_mono_para [expr \
    [energy_calculate_mono_para $new_mono_theta] + $mono_para_offset]

	assertMotorLimit mono_theta $new_mono_theta
	assertMotorLimit mono_para  $new_mono_para
	assertMotorLimit mono_perp  $new_mono_perp

	# move destination
	move mono_theta to $new_mono_theta
	move mono_perp to $new_mono_perp
	move mono_para to $new_mono_para

	# wait for the move to complete
	wait_for_devices mono_theta mono_perp mono_para 
}


proc energy_set { new_energy } {

	# global variables
	variable d_spacing
	variable mono_theta
	variable mono_perp_offset
	veriable mono_para_offset
	variable mono_para
	variable mono_perp
   
	# calculate position of mono_theta
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]	
	# set position of mono_theta	
	set mono_theta $new_mono_theta


    set mono_perp_offset [expr $mono_perp - [energy_calculate_mono_perp $new_mono_theta]]
    set mono_para_offset [expr $mono_para - [energy_calculate_mono_para $new_mono_theta]]

#	log_warning "set mono_perp_offset to $mono_perp_offset and mono_para offset to $mono_para_offset" 
	if { [catch {
            set handle ""
            set handle [open /usr/local/dcs/dcss/tmp/optimizedEnergy.log a ]
            puts $handle "[time_stamp] Set mono_perp_offset to $mono_perp_offset and mono_para_offset to $mono_para_offset"
	        puts $handle ""
	        close $handle
        } ] } {
		log_error "Error opening ../optimizedEnergy.log"
        close $handle
	}

}


proc energy_update {} {

	# global variables
	variable mono_theta
	variable d_spacing

	# calculate from real motor positions and motor parameters
	return [energy_calculate $mono_theta $d_spacing]
}


proc energy_calculate { mt ds } {

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

#Add energy_calculate_table_vert_1 and energy_calculate_table_vert_2
#to make energy reset standard
#uncomment next procedure to roll back

#proc energy_calculate_table_vert { mt} {
#
#	return 14.5121
#}


proc energy_calculate_mono_perp { mt} {
	variable h_beamexit
#	h_beamexit is the distance between the centers of two crystals. It's a constant value.
	return [expr ($h_beamexit/2/sin([rad $mt])) ]
}
proc energy_calculate_mono_para { mt} {

	return [expr (h_beamexit/2/cos([rad $mt])) ] 
}
