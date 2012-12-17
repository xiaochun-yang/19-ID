# sample_x.tcl
# This is for x4a crystal logic goniometer z combo motion.
# tripot_1, tripot_2 and tripot_3 are equal distance to the
# It is 22.225mm. The center of tripot support surface to the
# sample is 97 mm (alone z direction).
# The X aixs will be the line going through tripot_3 and the 
# middle point of tripot_1 and tripot_2 (pass the center as well).
# The y direction will be going through center and parallel to 
# tripot_1 and tripot_2. z direction will be perpendicular to
# x-y sourface.

proc sample_x_initialize {} {

	# specify children devices
	set_children tripot_1 tripot_2 
	set_siblings sample_z sample_y
}


proc sample_x_move { new_sample_x } {
	#global 
	global gDevice

	# global variables
    variable sample_z
    variable sample_y

	# calculate new positions of the two motors
	set new_tripot_1 [tripot_1_calculate_x $new_sample_x $gDevice(sample_z,target) $gDevice(sample_y,target)]
	set new_tripot_2 [tripot_2_calculate_x $new_sample_x $gDevice(sample_z,target) $gDevice(sample_y,target)]
    	#set new_tripot_3 [tripot_3_calculate_x $new_sample_x $gDevice(sample_z,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit tripot_1 $new_tripot_1
	assertMotorLimit tripot_2 $new_tripot_2
    	#assertMotorLimit tripot_3 $new_tripot_3

	# move motors in order that avoids collisions
	move tripot_1 to $new_tripot_1
	move tripot_2 to $new_tripot_2
	#move tripot_3 to $new_tripot_3

	# wait for the moves to complete
	wait_for_devices tripot_1 tripot_2 
}

proc sample_x_set { new_sample_x } {

	# global variables
	variable tripot_1
	variable tripot_2
   	#variable tripot_3
	variable sample_z
	variable sample_y

	# set three motors
	set tripot_1 [tripot_1_calculate_x $new_sample_x $sample_z $sample_y]
	set tripot_2 [tripot_2_calculate_x $new_sample_x $sample_z $sample_y]
	#set tripot_3 [tripot_3_calculate_x $new_sample_x $sample_z]
}


proc sample_x_update {} {

	# global variables
    variable tripot_1
    variable tripot_2
    #variable tripot_3

	# calculate from real motor positions and motor parameters
	return [sample_x_calculate $tripot_1 $tripot_2]
}


proc sample_x_calculate { t1 t2 } {
	
	return [expr 97*($t2-$t1)/2/19.225]
	#return [expr (2*$t3-$t1-$t2)*97/3/22.225 ]
}

proc tripot_1_calculate_x { x z y } {

    return [expr ($z - $y*11.1125/97 - $x*19.225/97)]
}


proc tripot_2_calculate_x { x z y } {

    return [expr ($z - $y*11.1125/97 + $x*19.225/97)]
}

#proc tripot_3_calculate_x { x z } {
#
#	return [expr ($z + $x*22.225/97.0)  ]
#}

