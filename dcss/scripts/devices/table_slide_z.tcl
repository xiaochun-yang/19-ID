# table_slide_z.tcl


proc table_slide_z_initialize {} {

	# specify children devices
	set_children
}


proc table_slide_z_move { new_table_slide_z } {

	# global variables
	variable table_slide_z

	# move the two motors
	set table_slide_z $new_table_slide_z
}


proc table_slide_z_set { new_table_slide_z } {

	# global variables
	variable table_slide_z

	# move the two motors
	set table_slide_z $new_table_slide_z
}



proc table_slide_z_update {} {

	# calculate from real motor positions and motor parameters
	return [table_slide_z_calculate]
}


proc table_slide_z_calculate {} {

	# global variables
	variable table_slide_z

	return $table_slide_z
}


