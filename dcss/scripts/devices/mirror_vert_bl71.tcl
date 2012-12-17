# mirror_vert.tcl

############################################################
# special requirements:
#
# move vert will move both vert1 and vert2
# move pitch will only move vert2
# (this means pivot is at vert1: mirror_v1_z = mirror_pivot_z = 0)
#
# set vert or pitch will not set vert1 nor vert2
# (we save the offset of vert and pitch to implement this)
#
# pitch units is mrad not degree
############################################################

proc mirror_vert_initialize {} {

	# specify children devices
    ###### must match arguments for MOTORNAME_calculate
	set_children mirror_vert_1 mirror_vert_2 \
    mirror_v1_z mirror_v2_z mirror_pivot_z \
    mirror_v_offset

	set_siblings mirror_pitch
}


proc mirror_vert_move { new_mirror_vert } {
	#global 
	global gDevice

	# global variables
	variable mirror_pitch

	#calculate new positions of the two motors
	set new_mirror_vert_1 [mirror_vert_1_calculate $new_mirror_vert $gDevice(mirror_pitch,target)]
	set new_mirror_vert_2 [mirror_vert_2_calculate $new_mirror_vert $gDevice(mirror_pitch,target)]

	#check to see if the move can be completed by the real motors
	assertMotorLimit mirror_vert_1 $new_mirror_vert_1
	assertMotorLimit mirror_vert_2 $new_mirror_vert_2

	# move the two motors
	move mirror_vert_1 to $new_mirror_vert_1
	move mirror_vert_2 to $new_mirror_vert_2

	# wait for the moves to complete
	wait_for_devices mirror_vert_1 mirror_vert_2
}


proc mirror_vert_set { new_mirror_vert } {
	# global variables
    variable mirror_v_offset

    set mirror_v_offset 0
    set real_v [mirror_vert_update]

    set mirror_v_offset [expr $new_mirror_vert - $real_v]
}
proc mirror_vert_update {} {

	# global variables
	variable mirror_vert_1
	variable mirror_vert_2
	variable mirror_v1_z
	variable mirror_v2_z
	variable mirror_pivot_z
    variable mirror_v_offset
    variable mirror_p_offset

	# calculate from real motor positions and motor parameters
	return [mirror_vert_calculate $mirror_vert_1 $mirror_vert_2 \
    $mirror_v1_z $mirror_v2_z $mirror_pivot_z \
    $mirror_v_offset]
}


proc mirror_vert_calculate { v1 v2 v1z v2z pvz voffset } {

	# calculate distance between v1 and v2
	set v1_v2_distance [expr $v1z - $v2z ]

	if { abs($v1_v2_distance) > 0.0001 }  {
		set p  [expr atan(($v2 - $v1) / $v1_v2_distance) ]
		return [expr $v1 - ($pvz - $v1z) * tan($p) + $voffset]
	} else {
		return 0
	}
}


proc mirror_vert_1_calculate { v p } {

	# global variables
	variable mirror_v1_z
	variable mirror_pivot_z
    variable mirror_v_offset
    variable mirror_p_offset

    set v [expr $v - $mirror_v_offset]
    set p [expr $p - $mirror_p_offset]
	
	return [expr $v \ + ( $mirror_v1_z - $mirror_pivot_z ) * tan($p / 1000.0)]
}


proc mirror_vert_2_calculate { v p } {
	# global variables
	variable mirror_v2_z
	variable mirror_pivot_z
    variable mirror_v_offset
    variable mirror_p_offset
	
    set v [expr $v - $mirror_v_offset]
    set p [expr $p - $mirror_p_offset]

	return [expr $v \ + ( $mirror_v2_z - $mirror_pivot_z ) * tan($p / 1000.0)]
}
