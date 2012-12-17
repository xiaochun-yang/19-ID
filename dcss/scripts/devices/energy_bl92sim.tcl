# energy.tcl


proc energy_initialize {} {
	
	# specify children devices
	set_children mono_theta d_spacing
}


proc energy_move { new_energy } {

	# global variables
	variable d_spacing

	# calculate destination for mono_theta
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]

	# move mono_theta to destination
	move mono_theta to $new_mono_theta
	
	# wait for the move to complete
	wait_for_devices mono_theta
}


proc energy_set { new_energy } {

	# global variables
	variable d_spacing
	variable mono_theta

	# calculate position of mono_theta
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]	

	# set position of mono_theta	
	set mono_theta $new_mono_theta
}


proc energy_update {} {

	# global variables
	variable mono_theta
	variable d_spacing

	# calculate from real motor positions and motor parameters
	return [energy_calculate $mono_theta $d_spacing]
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
		return -code error "d_spacing or mono_theta close to zero"
	}

	# calculate mono_theta from energy and d_spacing
	return [deg [expr asin(  12398.4244 / ( 2.0 * $ds * $e ) ) ]]
}
