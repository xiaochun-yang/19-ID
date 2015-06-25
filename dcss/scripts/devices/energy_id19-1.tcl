# energy_nyx.tcl for nyx 19id beamline at nsls2. The mono_theta is servo motor with dual encoder.
# main encoder --- position; dual encoder --- attached with motor.


proc energy_initialize {} {
	set_children mono_theta mono_crystal2_perp mono_crystal2_para d_spacing
}


proc energy_move { new_energy } {
	# global variables
	variable d_spacing
	variable energy
	variable mono_crystal2_perp
	variable mono_crystal2_para

	#variable mono_crystal2_perp_offset
	#variable mono_crystal2_para_offset
 
	# calculate destination
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]

	#set new_mono_crystal2_perp [expr [energy_calculate_mono_crystal2_perp $new_mono_theta] + $mono_crystal2_perp_offset]
	#set new_mono_crystal2_para [expr [energy_calculate_mono_crystal2_para $new_mono_theta] + $mono_crystal2_para_offset]
	
	set new_mono_crystal2_perp [expr [energy_calculate_mono_crystal2_perp $new_mono_theta]]
        set new_mono_crystal2_para [expr [energy_calculate_mono_crystal2_para $new_mono_theta]]

	assertMotorLimit mono_theta $new_mono_theta
	assertMotorLimit mono_crystal2_para  $new_mono_crystal2_para
	assertMotorLimit mono_crystal2_perp  $new_mono_crystal2_perp

	# move destination
	move mono_theta to $new_mono_theta
	move mono_crystal2_perp to $new_mono_crystal2_perp
	move mono_crystal2_para to $new_mono_crystal2_para

	# wait for the move to complete
	wait_for_devices mono_theta mono_crystal2_perp mono_crystal2_para 
}


proc energy_set { new_energy } {

	# global variables
	variable d_spacing
	variable mono_theta
#	variable mono_crystal2_perp_offset
#	veriable mono_crystal2_para_offset
	variable mono_crystal2_para
	variable mono_crystal2_perp
   
	# calculate position of mono_theta
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]	

	# set position of mono_theta	
	set mono_theta $new_mono_theta


        set mono_crystal2_perp [energy_calculate_mono_crystal2_perp $new_mono_theta]
        set mono_crystal2_para [energy_calculate_mono_crystal2_para $new_mono_theta]

#	log_warning "set mono_crystal2_perp_offset to $mono_crystal2_perp_offset and mono_crystal2_para offset to $mono_crystal2_para_offset" 
#	if { [catch {
#            set handle ""
#            set handle [open /usr/local/dcs/dcss/tmp/optimizedEnergy.log a ]
#            puts $handle "[time_stamp] Set mono_crystal2_perp_offset to $mono_crystal2_perp_offset and mono_crystal2_para_offset to $mono_crystal2_para_offset"
#	        puts $handle ""
#	        close $handle
#        } ] } {
#		log_error "Error opening ../optimizedEnergy.log"
#        close $handle
#	}

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

	# return error if d_spacing close to zero and energy less than 4k?
	if { $ds < 0.0001 || $e < 4000 } {
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


proc energy_calculate_mono_crystal2_perp { mt} {
	variable h_beamexit
#	h_beamexit is the distance between the centers of two crystals. It's a constant value.
	return [expr ($h_beamexit/2/cos([rad $mt])) ]
}
proc energy_calculate_mono_crystal2_para { mt} {

	return [expr (h_beamexit/2/sin([rad $mt])) ] 
}

