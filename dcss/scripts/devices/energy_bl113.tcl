# energy.tcl


proc energy_initialize {} {
	
	# specify children devices
	set_children mono_theta mono_bend d_spacing  table_yaw table_vert table_horz
}


proc energy_move { new_energy } {

	# global variables
	variable energy
	variable d_spacing
	variable mono_bend
	variable table_horz_1_offset       
	variable table_vert_1_offset
	variable table_vert_2_offset
	variable table_vert


	# calculate destination for mono_theta
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]

	# move mono_theta
	move mono_theta to $new_mono_theta

	# move table_vert_1
	move table_vert_1 to [expr [energy_calculate_table_vert_1 $new_mono_theta $mono_bend] + $table_vert_1_offset]

	# move table_vert_2
	move table_vert_2 to [expr [energy_calculate_table_vert_2 $new_mono_theta $mono_bend] + $table_vert_2_offset]

       # move table_horz_1
       move table_horz_1 to [expr [energy_calculate_table_horz_1 $new_mono_theta $mono_bend] + $table_horz_1_offset]

	wait_for_devices mono_theta table_vert_1 table_vert_2 table_horz_1
	
	# wait for the motors
	#if { [catch {wait_for_devices mono_theta table_vert_1 table_vert_2 table_horz_1} err] } {
        #log_error "error moving energy: $err"
        #return -code error $err
	#}
}

proc energy_set { new_energy } {

	# global variables
	variable d_spacing
	variable mono_theta
	variable mono_bend
	variable table_horz_1
	variable table_horz_1_offset
	variable table_vert_1
	variable table_vert_1_offset
	variable table_vert_2
	variable table_vert_2_offset
    
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]	

	#Check to see if the set is actually needed. ICS hangs when a "configure mono_theta" message 
	#immediately follows a "poll ion chamber" message.
	if { abs ( $mono_theta - $new_mono_theta) > 0.001 } { 
		# set position of mono_theta	
		set mono_theta $new_mono_theta
	}

	# set table_horz_1_offset
	set table_horz_1_offset [expr $table_horz_1 - [energy_calculate_table_horz_1 $new_mono_theta $mono_bend] ]

	# set table_vert_1_offset
	set table_vert_1_offset [expr $table_vert_1 - [energy_calculate_table_vert_1 $new_mono_theta $mono_bend] ]

	# set table_vert_2_offset
	set table_vert_2_offset [expr $table_vert_2 - [energy_calculate_table_vert_2 $new_mono_theta $mono_bend] ]


}


proc energy_update {} {

	# global variables
	variable mono_theta
	variable mono_bend
	variable d_spacing
	variable table_pitch 
	variable table_yaw 
	variable table_vert 
	variable table_horz

	# calculate from real motor positions and motor parameters
	return [energy_calculate $mono_theta $mono_bend $d_spacing  $table_yaw $table_vert $table_horz]
}


proc energy_calculate { mt mb ds ty tv th } {

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

proc energy_calculate_table_horz_1 { mt mb } {
#

	expr -121750.446256 * $mt*$mt*$mt*$mt + 8497283.78654 * $mt*$mt*$mt - 222391727.253 * $mt*$mt + 2586856111.36 * $mt - 11283785554.9 

 
}

proc energy_calculate_table_vert_1 { mt mb} {

expr 45.9996

}

proc energy_calculate_table_vert_2 { mt mb} {

expr 48.5265

}

