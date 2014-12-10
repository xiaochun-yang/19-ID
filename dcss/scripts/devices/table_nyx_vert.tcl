# table_nyx_vert.tcl


proc table_nyx_vert_initialize {} {

	# specify children devices
	set_children table_v1 table_v2 table_v3
	set_siblings table_nyx_pitch table_nyx_roll
}


proc table_nyx_vert_move { new_table_nyx_vert } {
	#global 
	global gDevice

	# global variables
	variable table_nyx_pitch
	variable table_nyx_roll

	#calculate new positions of the two motors
	set new_table_v1 [calculate_table_v1 $new_table_nyx_vert $gDevice(table_nyx_pitch,target) $gDevice(table_nyx_roll,target)]
	set new_table_v2 [calculate_table_v2 $new_table_nyx_vert $gDevice(table_nyx_pitch,target) $gDevice(table_nyx_roll,target)]
        set new_table_v3 [calculate_table_v3 $new_table_nyx_vert $gDevice(table_nyx_pitch,target) $gDevice(table_nyx_roll,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit table_v1 $new_table_v1
	assertMotorLimit table_v2 $new_table_v2
	assertMotorLimit table_v3 $new_table_v3

	# move the two motors
	move table_v1 to $new_table_v1
	move table_v2 to $new_table_v2
	move table_v3 to $new_table_v3

	# wait for the moves to complete
	wait_for_devices table_v1 table_v2 table_v3
}

proc table_nyx_vert_set { new_table_nyx_vert } {

	# global variables
	variable table_v1
	variable table_v2
	variable table_v3
	variable table_nyx_pitch
	variable table_nyx_roll

	# move the two motors
	set table_v1 [calculate_table_v1 $new_table_nyx_vert $table_nyx_pitch $table_nyx_roll]
	set table_v2 [calculate_table_v2 $new_table_nyx_vert $table_nyx_pitch $table_nyx_roll]
	set table_v3 [calculate_table_v3 $new_table_nyx_vert $table_nyx_pitch $table_nyx_roll]
}


proc table_nyx_vert_update {} {

	# global variables
	variable table_v1
	variable table_v2
	variable table_v3

	# calculate from real motor positions and motor parameters
	return [table_nyx_vert_calculate $table_v1 $table_v2 $table_v3]
}


proc table_vert_calculate { tv1 tv2 tv3 } {

	return [expr ($tv1*0.546 + $tv2*0.227 + $tv3*0.227) ]
}


proc calculate_table_v1 { tv tp tr } {

	return [expr ($tv + $tp*749*3.14/180) ]
}


proc calculate_table_v2 { tv tp tr} {
	
	return [expr $tv - $tp*902*3.14/180 + $tr*457*3.14/360]
}

proc calculate_table_v3 { tv tp tr} {

        return [expr $tv - $tp*902*3.14/180 - $tr*457*3.14/360]
}
