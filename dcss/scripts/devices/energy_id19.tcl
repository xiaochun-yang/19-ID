# energy_nyx.tcl for nyx 19id beamline at nsls2. The mono_theta is servo motor with dual encoder.
# main encoder --- position; dual encoder --- attached with motor.


proc energy_initialize {} {
	set_children mono_theta d_spacing
}

proc energy_motorlist {} {
        # specify motors which move during e-tracking for BL9-2, omitting mono_angle/mono_theta
        set result [list mono_c2_perp mono_c2_para]
        return $result
}

proc energy_move { new_energy } {
	# global variables
	variable d_spacing
	variable energy
        variable mono_theta
	variable mono_c2_perp
	variable mono_c2_para
puts "yangx energy move energy=$energy new energy=$new_energy"
	if { abs($energy - $new_energy) < 1 } {
	   puts "less than a half ev don't need to move"
	   return
 	}
	# calculate destination
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]
	set new_mono_c2_perp  [energy_calculate_mono_c2_perp $new_mono_theta]
        set new_mono_c2_para  [energy_calculate_mono_c2_para $new_mono_theta]


#	assertMotorLimit mono_theta $new_mono_theta
#	assertMotorLimit mono_c2_para  $new_mono_c2_para
#	assertMotorLimit mono_c2_perp  $new_mono_c2_perp

	# move destination
        move mono_theta to $new_mono_theta
	move mono_c2_perp to $new_mono_c2_perp 
	move mono_c2_para to $new_mono_c2_para

	# wait for the move to complete
	wait_for_devices mono_theta mono_c2_perp mono_c2_para 
}


proc energy_set { new_energy } {

	# global variables
	variable d_spacing
	variable mono_theta
	variable mono_c2_para
	variable mono_c2_perp
        variable mono_theta_offset
        variable mono_c2_perp_offset
        variable mono_c2_para_offset
   
	# calculate position of mono_theta
	set  new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]
        set  new_mono_c2_perp [energy_calculate_mono_c2_perp $new_mono_theta]
        set  new_mono_c2_para [energy_calculate_mono_c2_para $new_mono_theta]

#	set  mono_theta_offset [expr $mono_theta - $new_mono_theta + $mono_theta_offset]
	set  mono_c2_perp_offset [expr $mono_c2_perp - $new_mono_c2_perp + $mono_c2_perp_offset]
	set  mono_c2_para_offset [expr $mono_c2_para - $new_mono_c2_para + $mono_c2_para_offset]

	# set position of mono_theta	
	set mono_theta $new_mono_theta
        set mono_c2_perp $new_mono_c2_perp
	set mono_c2_para $new_mono_c2_para

#	log_warning "set mono_c2_perp_offset to $mono_c2_perp_offset and mono_c2_para offset to $mono_c2_para_offset" 
	if { [catch {
            set handle ""
            set handle [open /usr/local/dcs/dcss/tmp/optimizedEnergy.log a ]
            puts $handle "[time_stamp] Set mono_c2_perp_offset to $mono_c2_perp_offset and mono_c2_para_offset to $mono_c2_para_offset"
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
	return [expr 12398.4244 / (2.0 * $ds * sin([expr $mt/57.29578]) ) ]
}


proc energy_calculate_mono_theta { e ds } {

	# return error if d_spacing close to zero and energy less than 4k?
	if { $ds < 0.0001 || $e < 4000 } {
		error
	}

	# calculate mono_theta from energy and d_spacing
	return [deg [expr asin(  12398.4244 / ( 2.0 * $ds * $e ) ) ]]

}

proc energy_calculate_mono_c2_perp { mt} {
	variable h_beamexit
	variable asymmetric_cut

#	h_beamexit is the distance between the centers of two crystals. It's a constant value.
#	return [expr $h_beamexit/2/cos([rad $mt]) ]
	set r [expr $h_beamexit/sin(2*$mt/57.29578)]
	return [expr $r*sin( ($mt-$asymmetric_cut)/57.29578) ]
}

proc energy_calculate_mono_c2_para { mt} {

	variable h_beamexit
	variable asymmetric_cut

#	return [expr h_beamexit/2/sin([rad $mt]) ] 
#	return [expr (h_beamexit/2/sin([expr $mt/57.29578])) ]
#	return [expr $h_beamexit/2/sin([expr $mt/57.29578])]

	set r [expr $h_beamexit/sin(2*$mt/57.29578)]
	return [expr $r*cos(($mt-$asymmetric_cut)/57.29578)]
}

