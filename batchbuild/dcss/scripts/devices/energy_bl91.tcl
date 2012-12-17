# energy.tcl

proc energy_initialize {} {
	
	# specify children devices
	set_children mono_theta mono_bend d_spacing table_slide table_yaw table_pitch table_vert table_horz_1
}

proc energy_motorlist {} {

        # specify motors which move during e-tracking for BL9-1, omitting mono_angle/mono_theta

        set result [list mono_bend table_slide table_horz_1 table_horz_2 table_vert_1 table_vert_2]

        return $result
}

proc energy_move { new_energy } {

	# global variables
	variable energy
	variable d_spacing
	variable mono_bend
	variable table_slide_offset
	variable table_horz_2_offset
	variable table_horz_1_offset
	variable table_vert_1_offset
	variable table_vert_2_offset
	variable table_pitch
	variable table_vert
    variable table_vert_1
    variable table_vert_2
    ##variable ::nScripts::system_idle

	
	# make sure energy is not already at its destination
	#if { abs($energy - $new_energy) < 0.02 } {
	#	return
	#}

	# calculate destination for mono_theta
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]
	set new_table_slide [expr [energy_calculate_table_slide $new_mono_theta] + $table_slide_offset]
	set new_table_horz_2 [expr [energy_calculate_table_horz_2 $new_mono_theta] + $table_horz_2_offset]
	set new_table_horz_1 [expr [energy_calculate_table_horz_1 $new_mono_theta] + $table_horz_1_offset]
	set new_table_vert_1 [expr [energy_calculate_table_vert_1 $new_mono_theta] + $table_vert_1_offset]
	set new_table_vert_2 [expr [energy_calculate_table_vert_2 $new_mono_theta] + $table_vert_2_offset]
	set new_mono_bend [expr [energy_calculate_mono_bend $new_mono_theta]]

	assertMotorLimit mono_theta $new_mono_theta
	assertMotorLimit table_slide $new_table_slide
	assertMotorLimit table_horz_2 $new_table_horz_2
	assertMotorLimit table_horz_1 $new_table_horz_1
	assertMotorLimit table_vert_1 $new_table_vert_1
	assertMotorLimit table_vert_2 $new_table_vert_2
	assertMotorLimit mono_bend $new_mono_bend

# Uncomment this when mono is reproducible....
	# move mono_theta
	move mono_theta to $new_mono_theta	

	# move table_slide
	move table_slide to $new_table_slide

	# move table_horz_1. Uncomment to move with energy
	move table_horz_1 to $new_table_horz_1

    # During a MAD scan skip the vert moves for very small moves.
    # The table_vert motors are the last to complete their moves
    # when the scan direction is from high energy to low energy.
    # See Bugzilla #1077
    #
    set movedTable false

    #set madScan [expr [string first madScan $system_idle] != -1]
    global gOperation
    set madScan 0
    if {$gOperation(madScan,status) != "inactive"} {
        set madScan 1
        #log_warning DEBUG madScanMovingEnergy
    }


    if {$madScan} {
        if { abs($table_vert_2 - $new_table_vert_2) > 0.01 || abs($table_vert_1 - $new_table_vert_1) > 0.01  } {
            move table_vert_1 to $new_table_vert_1
            move table_vert_2 to $new_table_vert_2
            set movedTable true
        }
    } else {
        move table_vert_1 to $new_table_vert_1
        move table_vert_2 to $new_table_vert_2
        set movedTable true
    }

   move mono_bend to $new_mono_bend

	# wait for the moves to complete
	wait_for_devices mono_theta table_slide table_horz_1 mono_bend 
	if {$movedTable} {wait_for_devices table_vert_1 table_vert_2} 

}


proc energy_set { new_energy } {

	# global variables
	variable d_spacing
	variable mono_theta
	variable mono_bend
	variable table_slide
	variable table_slide_offset
	variable table_horz_2
	variable table_horz_2_offset
	variable table_horz_1
	variable table_horz_1_offset
	variable table_vert_1
	variable table_vert_1_offset
	variable table_vert_2
	variable table_vert_2_offset

	# calculate position of mono_theta
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]	

	#Check to see if the set is actually needed. ICS hangs when a "configure mono_theta" message 
	#immediately follows a "poll ion chamber" message.
	if { abs ( $mono_theta - $new_mono_theta) > 0.001 } { 
		# set position of mono_theta	
		set mono_theta $new_mono_theta
	}

	# set table_slide_offset
   	set new_table_slide_offset [expr $table_slide - [energy_calculate_table_slide $new_mono_theta] ]

    
	if { abs($table_slide_offset - $new_table_slide_offset) > 0.05 } {
		set table_slide_offset $new_table_slide_offset
	}

	# set table_horz_2_offset
	# set table_horz_2_offset [expr $table_horz_2 - [energy_calculate_table_horz_2 $new_mono_theta] ]

	# set table_horz_1_offset
	set table_horz_1_offset [expr $table_horz_1 - [energy_calculate_table_horz_1 $new_mono_theta] ]

	# set table_vert_1_offset
	set table_vert_1_offset [expr $table_vert_1 - [energy_calculate_table_vert_1 $new_mono_theta] ]

	# set table_vert_2_offset
	set table_vert_2_offset [expr $table_vert_2 - [energy_calculate_table_vert_2 $new_mono_theta] ]
}


proc energy_update {} {

	# global variables
	variable mono_theta
	variable mono_bend
	variable d_spacing

	# calculate from real motor positions and motor parameters
	return [energy_calculate $mono_theta $mono_bend $d_spacing 0 0 0 0 0 ]
}

proc energy_calculate { mt dummy_mb ds dummy1 dummy2 dummy3 dummy4 dummy5 } {

	# return obviously bad value for energy if d_spacing or mono_theta close to zero
	if { $ds < 0.0001 || $mt < 0.0001 } {
		return 0.01
	}

	# calculate energy from d_spacing and mono_theta
	return [expr 12398.4244 / (2.0 * $ds * sin([rad $mt]) ) ]
}


proc energy_calculate_mono_theta { e ds } {

	# return error if d_spacing or mono_theta close to zero
	if { $ds < 0.0001 || $e < 0.0001 } {
		error
	}

	# calculate mono_theta from energy and d_spacing
	return [deg [expr asin(  12398.4244 / ( 2.0 * $ds * $e ) ) ]]
}

proc energy_calculate_mono_bend { mt } {
    set a 7.6989557000000005e+01
    set b 0.0000000000000000e+00
    set c 0.0000000000000000e+00
    set d 0.0000000000000000e+00
    set e 0.0000000000000000e+00
    set f 0.0000000000000000e+00
    ### max abs error: 0.0000000000000000e+00

    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt + \
    $d * $mt * $mt * $mt + \
    $e * $mt * $mt * $mt * $mt + \
    $f * $mt * $mt * $mt * $mt * $mt \
    ]
}

proc energy_calculate_table_slide { mt } {
    set a -1.0421898383056183e+04
    set b 2.6978526191609758e+03
    set c -3.0488947233534299e+02
    set d 1.8246476148087535e+01
    set e -5.4393869038113352e-01
    set f 6.4551346910605477e-03
    ### max abs error: 3.1471924696224379e-01

    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt + \
    $d * $mt * $mt * $mt + \
    $e * $mt * $mt * $mt * $mt + \
    $f * $mt * $mt * $mt * $mt * $mt \
    ]
}

proc energy_calculate_table_horz_2 { mt } {
    set a 3.1498290000000000e+00
    set b 0.0000000000000000e+00
    set c 0.0000000000000000e+00
    set d 0.0000000000000000e+00
    set e 0.0000000000000000e+00
    set f 0.0000000000000000e+00
    ### max abs error: 0.0000000000000000e+00

    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt + \
    $d * $mt * $mt * $mt + \
    $e * $mt * $mt * $mt * $mt + \
    $f * $mt * $mt * $mt * $mt * $mt \
    ]
}

proc energy_calculate_table_horz_1 { mt } {
    set a 7.6700309999999998e+00
    set b 0.0000000000000000e+00
    set c 0.0000000000000000e+00
    set d 0.0000000000000000e+00
    set e 0.0000000000000000e+00
    set f 0.0000000000000000e+00
    ### max abs error: 0.0000000000000000e+00

    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt + \
    $d * $mt * $mt * $mt + \
    $e * $mt * $mt * $mt * $mt + \
    $f * $mt * $mt * $mt * $mt * $mt \
    ]
}

# 350 mA beam equation bellow:
#proc energy_calculate_table_vert_1 { mt } {
#    set a -3.3328064423631599e+02
#    set b 1.1873132239846304e+02
#    set c -1.5338641593222675e+01
#    set d 9.7976486756640990e-01
#    set e -3.1221090141033019e-02
#    set f 3.9756469025403177e-04
#    ### max abs error: 7.5657524940756365e-02
###################################################
# 300 mA beam equation bellow; 
# difference from 350 mA = -0.05867 table_vert
###################################################
proc energy_calculate_table_vert_1 { mt } {
    set a -3.0999588965364806e+03
    set b 1.0236218054331913e+03
    set c -1.3344058229754168e+02
    set d 8.6681663334332004e+00
    set e -2.8086640052404205e-01
    set f 3.6319785012483125e-03
    ### max abs error: 1.5931411223960423e-02


    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt + \
    $d * $mt * $mt * $mt + \
    $e * $mt * $mt * $mt * $mt + \
    $f * $mt * $mt * $mt * $mt * $mt \
    ]
}
# 350 mA beam equation bellow:
#proc energy_calculate_table_vert_2 { mt } {
#    set a 7.0746616253977427e+03
#    set b -2.2762409406503198e+03
#    set c 2.9385368629002340e+02
#    set d -1.8923344052553237e+01
#    set e 6.0744621238074847e-01
#    set f -7.7758506854960384e-03
#    ### max abs error: 9.3024614616169135e-02
###################################################
# 300 mA beam equation bellow; 
# difference from 350 mA = -0.05867 table_vert
###################################################
proc energy_calculate_table_vert_2 { mt } {
    set a 4.3439876521383167e+03
    set b -1.3831970048271385e+03
    set c 1.7730816807295284e+02
    set d -1.1337005940650403e+01
    set e 3.6114145590047791e-01
    set f -4.5850949153780846e-03
    ### max abs error: 1.5710110117384202e-02

    return [expr \
    $a + \
    $b * $mt + \
    $c * $mt * $mt + \
    $d * $mt * $mt * $mt + \
    $e * $mt * $mt * $mt * $mt + \
    $f * $mt * $mt * $mt * $mt * $mt \
    ]
}
