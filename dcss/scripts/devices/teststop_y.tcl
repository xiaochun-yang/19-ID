# teststop_y.tcl


proc teststop_y_initialize {} {
	
	# specify children devices
	set_children teststop_horz teststop_vert
}


proc teststop_y_move { new_teststop_y } {

	# global variables
	variable teststop_horz
	variable teststop_vert

	# move teststop_horz
	move teststop_horz to [teststop_y_calculate $new_teststop_y] 

	# wait for the moves to complete
	wait_for_devices teststop_horz
}


proc teststop_y_set { new_teststop_y} {

	# global variables
        set teststop_horz [teststop_y_calculate $new_teststop_y]
}


proc teststop_y_update {} {

	# global variables
	variable teststop_horz
	variable teststop_vert

        set l 57.93
        return [expr $teststop_vert + ($l*cos($teststop_horz*3.14159/180))]

}

proc teststop_y_calculate { y } {

	variable teststop_vert

	#l is the rotation radiu
	set l 57.93
	return [expr (acos(($y-$teststop_vert)/$l)*180/3.14159)]
}
