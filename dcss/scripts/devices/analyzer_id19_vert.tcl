# analyzer_id19_vert.tcl


proc analyzer_vert_initialize {} {

	# specify children devices
	set_children analyzer_vert_1 analyzer_vert_2 analyzer_vert_3
	set_siblings analyzer_pitch analyzer_roll
}


proc analyzer_vert_move { new_analyzer_vert } {
	#global 
	global gDevice

	# global variables
	variable analyzer_pitch
	variable analyzer_roll
	variable analyzer_vert_1
	variable analyzer_vert_2
	variable analyzer_vert_3

	#calculate new positions of the two motors
	set new_analyzer_vert_1 [calculate_analyzer_vert_1 $new_analyzer_vert $gDevice(analyzer_pitch,target) $gDevice(analyzer_roll,target)]
	set new_analyzer_vert_2 [calculate_analyzer_vert_2 $new_analyzer_vert $gDevice(analyzer_pitch,target) $gDevice(analyzer_roll,target)]
        set new_analyzer_vert_3 [calculate_analyzer_vert_3 $new_analyzer_vert $gDevice(analyzer_pitch,target) $gDevice(analyzer_roll,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit analyzer_vert_1 $new_analyzer_vert_1
	assertMotorLimit analyzer_vert_2 $new_analyzer_vert_2
	assertMotorLimit analyzer_vert_3 $new_analyzer_vert_3

	# move the two motors
	move analyzer_vert_1 to $new_analyzer_vert_1
	move analyzer_vert_2 to $new_analyzer_vert_2
	move analyzer_vert_3 to $new_analyzer_vert_3

	# wait for the moves to complete
	wait_for_devices analyzer_vert_1 analyzer_vert_2 analyzer_vert_3
}

proc analyzer_vert_set { new_analyzer_vert } {

	# global variables
	variable analyzer_vert_1
	variable analyzer_vert_2
	variable analyzer_vert_3
	variable analyzer_pitch
	variable analyzer_roll

	# move the two motors
	set analyzer_vert_1 [calculate_analyzer_vert_1 $new_analyzer_vert $analyzer_pitch $analyzer_roll]
	set analyzer_vert_2 [calculate_analyzer_vert_2 $new_analyzer_vert $analyzer_pitch $analyzer_roll]
	set analyzer_vert_3 [calculate_analyzer_vert_3 $new_analyzer_vert $analyzer_pitch $analyzer_roll]
}


proc analyzer_vert_update {} {

	# global variables
	variable analyzer_vert_1
	variable analyzer_vert_2
	variable analyzer_vert_3

	# calculate from real motor positions and motor parameters
	return [analyzer_vert_calculate $analyzer_vert_1 $analyzer_vert_2 $analyzer_vert_3]
}


proc analyzer_vert_calculate { tv1 tv2 tv3 } {

	return [expr ($tv1 + $tv2 + $tv3)/3 ]
}


proc calculate_analyzer_vert_1 { tv tp tr } {
#length=400
	return [expr ($tv + 2*400*$tp*3.1415926/180/3) ]
}


proc calculate_analyzer_vert_2 { tv tp tr} {
#set width 200	
#set length 400

#	return [expr $tv - $tp*902*3.14/180 + $tr*457*3.14/360]
	return [expr ($tv + 200*$tr*3.1415926/180/2 -400*$tp*3.1415926/180/3)]
}

proc calculate_analyzer_vert_3 { tv tp tr} {

#        return [expr $tv - $tp*902*3.14/180 - $tr*457*3.14/360]
	 return [expr ($tv - 200*$tr*3.1415926/180/2 -400*$tp*3.1415926/180/3)]
}
