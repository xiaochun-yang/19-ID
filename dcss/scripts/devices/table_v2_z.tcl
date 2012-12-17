# table_v2_z.tcl

proc table_v2_z_initialize {} {

	# specify children devices
	set_children
}


proc table_v2_z_move { new_table_v2_z } {

	# global variables
	variable table_v2_z

	# move the two motors
	set table_v2_z $new_table_v2_z
}


proc table_v2_z_set { new_table_v2_z } {

	# global variables
	variable table_v2_z

	# move the two motors
	set table_v2_z $new_table_v2_z
}


proc table_v2_z_update {} {

	# calculate from real motor positions and motor parameters
	return [table_v2_z_calculate]
}


proc table_v2_z_calculate {} {

	# global variables
	variable table_v2_z

	return $table_v2_z
}


