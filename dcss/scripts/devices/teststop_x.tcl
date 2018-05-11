# teststop_x.tcl


proc teststop_x_initialize {} {
	
	# specify children devices
	set_children teststop_horz
}


proc teststop_x_move { new_teststop_x } {

	# global variables
	variable teststop_horz

	# move teststop_horz
	move teststop_horz to [teststop_x_calculate $new_teststop_x] 

	# wait for the moves to complete
	wait_for_devices teststop_horz
}


proc teststop_x_set { new_teststop_x} {

	# global variables
	variable teststop_horz
        set teststop_horz [teststop_x_calculate $new_teststop_x]
}


proc teststop_x_update {} {

	# global variables
	variable teststop_horz
        return [teststop_x_calculate1 $teststop_horz]
}


proc teststop_x_calculate { x } {

	#l is the rotation radiu
	set l 57.93
	return [expr (asin($x/$l)*180/3.14159)]
}

proc teststop_x_calculate1 { teststop_horz } {
        
	set l 57.93
        return [expr ($l*sin($teststop_horz*3.14159/180))]
}

