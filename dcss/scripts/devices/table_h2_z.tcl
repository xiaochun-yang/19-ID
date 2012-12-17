# table_h2_z.tcl

proc table_h2_z_initialize {} {

	# specify children devices
	set_children
}


proc table_h2_z_move { new_table_h2_z } {

	# global variables
	variable table_h2_z

	# move the two motors
	set table_h2_z $new_table_h2_z
}


proc table_h2_z_set { new_table_h2_z } {

	# global variables
	variable table_h2_z

	# move the two motors
	set table_h2_z $new_table_h2_z
}


proc table_h2_z_update {} {

	# calculate from real motor positions and motor parameters
	return [table_h2_z_calculate]
}


proc table_h2_z_calculate {} {

	# global variables
	variable table_h2_z

	return $table_h2_z
}


