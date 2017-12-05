# sample_optic_vert.tcl


proc sample_optic_vert_initialize {} {
	
	# specify children devices
	set_children optic_vert sample_vert
}


proc sample_optic_vert_move { new_sample_optic_vert } {

	# global variables
	variable optic_vert
	variable sample_vert

	# move optic_vert
	set new_sample_vert [expr $new_sample_optic_vert - $optic_vert + $sample_vert ]
	move optic_vert to [sample_optic_vert_calculate $new_sample_optic_vert] 
	move sample_vert to $new_sample_vert

	# wait for the moves to complete
	wait_for_devices optic_vert sample_vert
}


proc sample_optic_vert_set { new_sample_optic_vert} {

	# global variables
	variable optic_vert
        set optic_vert [sample_optic_vert_calculate $new_sample_optic_vert]
}


proc sample_optic_vert_update {} {

	# global variables
	variable optic_vert
        return [sample_optic_vert_calculate1 $optic_vert]
}


proc sample_optic_vert_calculate { num } {

          return $num
}

proc sample_optic_vert_calculate1 { optic_vert } {

                return $optic_vert
}

