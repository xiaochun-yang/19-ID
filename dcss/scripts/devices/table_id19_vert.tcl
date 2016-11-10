# table_id19_vert.tcl


proc table_vert_initialize {} {

	# specify children devices
	set_children table_vert_1 table_vert_2 table_vert_3
	set_siblings table_pitch table_roll
}


proc table_vert_move { new_table_vert } {
	#global 
	global gDevice

	# global variables
	variable table_pitch
	variable table_roll
	variable table_vert_1
	variable table_vert_2
	variable table_vert_3

	#calculate new positions of the two motors
	set new_table_vert_1 [calculate_table_vert_1 $new_table_vert $gDevice(table_pitch,target) $gDevice(table_roll,target)]
	set new_table_vert_2 [calculate_table_vert_2 $new_table_vert $gDevice(table_pitch,target) $gDevice(table_roll,target)]
        set new_table_vert_3 [calculate_table_vert_3 $new_table_vert $gDevice(table_pitch,target) $gDevice(table_roll,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit table_vert_1 $new_table_vert_1
	assertMotorLimit table_vert_2 $new_table_vert_2
	assertMotorLimit table_vert_3 $new_table_vert_3

	# move the two motors
	move table_vert_1 to $new_table_vert_1
	move table_vert_2 to $new_table_vert_2
	move table_vert_3 to $new_table_vert_3

	# wait for the moves to complete
	wait_for_devices table_vert_1 table_vert_2 table_vert_3
}

proc table_vert_set { new_table_vert } {

	# global variables
	variable table_vert_1
	variable table_vert_2
	variable table_vert_3
	variable table_pitch
	variable table_roll

	# move the two motors
	set table_vert_1 [calculate_table_vert_1 $new_table_vert $table_pitch $table_roll]
	set table_vert_2 [calculate_table_vert_2 $new_table_vert $table_pitch $table_roll]
	set table_vert_3 [calculate_table_vert_3 $new_table_vert $table_pitch $table_roll]
}


proc table_vert_update {} {

	# global variables
	variable table_vert_1
	variable table_vert_2
	variable table_vert_3

	# calculate from real motor positions and motor parameters
	return [table_vert_calculate $table_vert_1 $table_vert_2 $table_vert_3]
}


proc table_vert_calculate { tv1 tv2 tv3 } {

	return [expr ($tv1 + $tv2 + $tv3)/3 ]
}


proc calculate_table_vert_1 { tv tp tr } {
#length= 1041.67 mm
#width= 733 mm
	return [expr ($tv + 1041.67*2/3*$tp*3.1415926/180) ]
}


proc calculate_table_vert_2 { tv tp tr} {
	
#	return [expr $tv - $tp*902*3.14/180 + $tr*457*3.14/360]
	return [expr $tv + $tr*366.5*3.1415926/180 -$tp*347*3.1415926/180]
}

proc calculate_table_vert_3 { tv tp tr} {

#        return [expr $tv - $tp*902*3.14/180 - $tr*457*3.14/360]
	 return [expr $tv - $tr*366.5*3.1415926/180 -$tp*347*3.1415926/180]
}
