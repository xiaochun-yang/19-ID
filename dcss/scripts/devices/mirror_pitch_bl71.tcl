# mirror_pitch.tcl

############################################################
# special requirements:
#
# move vert will move both vert1 and vert2
# move pitch will only move vert2
# (this means pivot is at vert1: mirror_v1_z = mirror_pivot_z = 0)
#
# set vert or pitch will not set vert1 nor vert2
# (we save the offset of vert and pitch to implement this)
############################################################


proc mirror_pitch_initialize {} {
	
	# specify children devices
    ###### must match arguments for MOTORNAME_calculate
	set_children mirror_vert_1 mirror_vert_2 mirror_v1_z mirror_v2_z \
    mirror_p_offset

	set_siblings mirror_vert
}


proc mirror_pitch_move { new_mirror_pitch } {
	#global 
	global gDevice

	# global variables
	variable mirror_vert

	# move the two motors
	move mirror_vert_1 to [mirror_vert_1_calculate $gDevice(mirror_vert,target) $new_mirror_pitch]
	move mirror_vert_2 to [mirror_vert_2_calculate $gDevice(mirror_vert,target) $new_mirror_pitch]

	# wait for the moves to complete
	wait_for_devices mirror_vert_1 mirror_vert_2
}


proc mirror_pitch_set { new_mirror_pitch } {
	# global variables
    variable mirror_p_offset

    set mirror_p_offset 0
    set real_p [mirror_pitch_update]

    set mirror_p_offset [expr $new_mirror_pitch - $real_p]
}


proc mirror_pitch_update {} {
	# global variables
	variable mirror_vert_1
	variable mirror_vert_2
	variable mirror_v1_z
	variable mirror_v2_z
    variable mirror_p_offset

	# calculate from real motor positions and motor parameters
	return [mirror_pitch_calculate $mirror_vert_1 $mirror_vert_2 \
    $mirror_v1_z $mirror_v2_z \
    $mirror_p_offset]
}


proc mirror_pitch_calculate { v1 v2 v1z v2z poffset } {
	set v1_v2_distance [expr $v2z - $v1z ]

	if { abs($v1_v2_distance) > 0.0001 }  {
		return [expr 1000.0 * atan(($v2 - $v1) / $v1_v2_distance) + $poffset]
	} else {
		return 0.0
	}
}

