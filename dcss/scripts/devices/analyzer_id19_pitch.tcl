# analyzer_pitch.tcl


proc analyzer_pitch_initialize {} {
	
	# specify children devices
	set_children analyzer_vert_1 analyzer_vert_2 analyzer_vert_3
	set_siblings analyzer_vert analyzer_roll
}


proc analyzer_pitch_move { new_analyzer_pitch } {
	#global 
	global gDevice

	# global variables
	variable analyzer_vert
	variable analyzer_roll
	variable analyzer_vert_1
	variable analyzer_vert_2
	variable analyzer_vert_3

	# move the two motors
	move analyzer_vert_1 to [calculate_analyzer_vert_1 $gDevice(analyzer_vert,target) $new_analyzer_pitch $gDevice(analyzer_roll,target)]
	move analyzer_vert_2 to [calculate_analyzer_vert_2 $gDevice(analyzer_vert,target) $new_analyzer_pitch $gDevice(analyzer_roll,target)]
	move analyzer_vert_3 to [calculate_analyzer_vert_3 $gDevice(analyzer_vert,target) $new_analyzer_pitch $gDevice(analyzer_roll,target)]

	# wait for the moves to complete
	wait_for_devices analyzer_vert_1 analyzer_vert_2 analyzer_vert_3
}


proc analyzer_pitch_set { new_analyzer_pitch } {

	# global variables
	variable analyzer_vert_1
	variable analyzer_vert_2
	variable analyzer_vert_3
        variable analyzer_roll
	variable analyzer_vert

	# move the two motors
	set analyzer_vert_1 [calculate_analyzer_vert_1 $analyzer_vert $new_analyzer_pitch $analyzer_roll]
	set analyzer_vert_2 [calculate_analyzer_vert_2 $analyzer_vert $new_analyzer_pitch $analyzer_roll]
	set analyzer_vert_3 [calculate_analyzer_vert_2 $analyzer_vert $new_analyzer_pitch $analyzer_roll]
}


proc analyzer_pitch_update {} {

	# global variables
	variable analyzer_vert_1
	variable analyzer_vert_2
	variable analyzer_vert_3

	# calculate from real motor positions and motor parameters
	return [analyzer_pitch_calculate $analyzer_vert_1 $analyzer_vert_2 $analyzer_vert_3]
}


proc analyzer_pitch_calculate { tv1 tv2 tv3 } {
#lenght=400

	return [expr ($tv1/400 - $tv2/800 -$tv3/800)*180/3.1415926]
}

#proc calculate_analyzer_vert_1 { tv tp tr } {
#	return [expr ($tv + 694*$tp*3.14159/180)]
#}
#proc calculate_analyzer_vert_2 { tv tp tr } {
#	return [expr ($tv + (366.5*$tr - 347*$tp)*3.14159/180)]
#}
#proc calculate_analyzer_vert_3 { tv tp tr } {
#        return [expr ($tv - (366.5*$tr - 347*$tp)*3.14159/180) ]
#}

