# table_2theta.tcl


proc table_2theta_initialize {} {
	
	# specify children devices
	set_children table_slide table_slide_z
}


proc table_2theta_move { new_table_2theta } {

	# global variables
	variable table_slide_z

	# move mono_angle
	move table_slide to \
		[table_2theta_calculate_table_slide $new_table_2theta $table_slide_z]

	# wait for the moves to complete
	wait_for_devices table_slide
}


proc table_2theta_set { new_table_2theta } {

	# global variables
	variable table_slide
	variable table_slide_z

	# move the two motors
	set table_slide \
		[table_2theta_calculate_table_slide $new_table_2theta $table_slide_z]
}


proc table_2theta_update {} {

	# global variables
	variable table_slide
	variable table_slide_z

	# calculate from real motor positions and motor parameters
	return [table_2theta_calculate $table_slide $table_slide_z]
}


proc table_2theta_calculate { ts tsz } {

	# return error if table_slide_z negative or close to zero
	if { $tsz < 0.0001} {
		error
	}

	# calculate energy from d_spacing and mono_theta
	return [deg [expr atan( $ts / $tsz ) ]]
}


proc table_2theta_calculate_table_slide { t2t tsz } {

	# calculate mono_theta from energy and d_spacing
	return [ expr $tsz * tan( [rad $t2t] ) ]
}
