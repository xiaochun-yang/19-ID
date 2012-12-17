# energy.tcl


proc energy_initialize {} {
	
	# specify children devices
	set_children mono_theta mono_bend d_spacing table_slide table_yaw table_pitch table_vert 

    variable mirrorHold

    set mirrorHold(BOARD) -1
    set mirrorHold(CHANNEL) -1
    set cfg [::config getStr mirror.hold.control]
    if {[llength $cfg] >= 2} {
        set mirrorHold(BOARD)   [lindex $cfg 0]
        set mirrorHold(CHANNEL) [lindex $cfg 1]
        puts "for mirrorHold: $cfg"
    }
    
    ##### uncomment this will trigger beamGood to check happy too.
    variable beam_happy_cfg
    set beam_happy_cfg(BOARD) -1
    set beam_happy_cfg(CHANNEL) -1
    set beam_happy_cfg(VALUE) 1
    set cfg [::config getStr beam_happy]
    if {[llength $cfg] >= 2} {
        set beam_happy_cfg(BOARD)   [lindex $cfg 0]
        set beam_happy_cfg(CHANNEL) [lindex $cfg 1]
        puts "for beam_happy_cfg: $cfg"
    }

    namespace eval ::energy { 
        set delta_energy 0
    }
}

proc energy_motorlist {} {

        # specify motors which move during e-tracking for BL11-1, omitting mono_angle/mono_theta

        set result [list table_slide table_vert_1 table_vert_2]

        return $result
}

proc energy_move { new_energy } {

	# global variables
    global gOperation
	variable energy
	variable d_spacing
	variable mono_theta
	variable table_slide
	variable table_slide_offset
	variable table_horz_2_offset
	variable table_vert_1_offset
	variable table_vert_2_offset
	variable table_pitch
	
	# make sure energy is not already at its destination
	#if { abs($energy - $new_energy) < 0.02 } {
	#	return
	#}

    variable ::energy::delta_energy
    variable energy_moving_msg

    set energy_moving_msg ""

    set delta_energy [expr $new_energy - $energy]

    #################################
    ## detector threshold
    #################################
    set isCollecting 0
    if {$gOperation(collectRuns,status) != "inactive" \
      || $gOperation(collectRun,status) != "inactive" \
      || $gOperation(collectFrame,status) != "inactive" } {
          set isCollecting 1
          log_warning "moving energy in collecting"
    }

    if { $isCollecting } {
        log_warning setting detector threshold
        set h [start_waitable_operation detectorSetThreshold midg 5300]
        wait_for_operation_to_finish $h
    }

	# calculate destination for mono_theta
	set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]
	set new_table_slide [expr [energy_calculate_table_slide $new_mono_theta ] + $table_slide_offset]

    set needHoldMirror 0
    if {abs($new_mono_theta - $mono_theta) > 0.001} {
        set needHoldMirror 1
    }
    if {abs($new_table_slide - $table_slide) > 0.001} {
        set needHoldMirror 1
    }
    if {$needHoldMirror} {
        generic_hold_mirror energy
    }

    if {[catch {
	    # move mono_theta
	    move mono_theta to $new_mono_theta
	
	    # move table_slide
	    move table_slide to $new_table_slide

	    # move table_horz_1
        # move table_horz_1 to [expr [energy_calculate_table_horz_1 $new_mono_theta ] ]

	    # move table_vert_1
    	move table_vert_1 to [expr [energy_calculate_table_vert_1 $new_mono_theta ] + $table_vert_1_offset]

	    # move table_vert_2
        move table_vert_2 to [expr [energy_calculate_table_vert_2 $new_mono_theta ] + $table_vert_2_offset]

	    # move table_horz_2
	    # move table_horz_2 to [expr [energy_calculate_table_horz_2 $new_mono_theta ] + $table_horz_2_offset]

	    # wait for the moves to complete
	    # wait_for_devices mono_theta table_slide table_vert
        # edit this list to match the motors which move each run
	    if { [catch {wait_for_devices table_slide} err] } {
            set slideErr $err
            #wait for the rest of the motors
	        if { [catch {wait_for_devices mono_theta table_vert_1 table_vert_2} err] } {
                log_error "error moving energy: $err"
            }
        
            log_error "*****PLEASE CHECK THAT STEP IS UP OR PRESS GREEN BUTTON*********"
            return -code error $slideErr
        }
    
        #no error on slide, wait for the rest of the motors
	    if { [catch {wait_for_devices mono_theta table_vert_1 table_vert_2} err] } {
            log_error "error moving energy: $err"
	    return -code error $err
        }

    
	    # save the current table vert
	    # set current_table_vert $table_vert

	    # move table_pitch
	    # move table_pitch to $table_pitch

	    # wait for the moves to complete
	    # wait_for_devices table_pitch

	    # move table_vert
	    # move table_vert to $current_table_vert

	    # wait for the moves to complete
	    # wait_for_devices table_vert
          
        # wait_for_time 2000
        # this is the wait time estimated for mono_theta to settle. Remove if mono_theta repaired.
    } errMsg]} {
        if {$needHoldMirror} {
            #log_warning DEBUG release mirror
            generic_release_mirror energy
        }
        return -code error $errMsg
    }
    if {$needHoldMirror} {
        generic_release_mirror energy
    }
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
	set table_slide_offset [expr $table_slide - [energy_calculate_table_slide $new_mono_theta ] ]

	# set table_vert_1 offset
	set table_vert_1_offset [expr $table_vert_1 - [energy_calculate_table_vert_1 $new_mono_theta ] ]

	# set table_horz_2_offset
	# set table_horz_2_offset [expr $table_horz_2 - [energy_calculate_table_horz_2 $new_mono_theta ] ]

	# set table_vert_2_offset
	set table_vert_2_offset [expr $table_vert_2 - [energy_calculate_table_vert_2 $new_mono_theta ] ]

}


proc energy_update {} {

	# global variables
	variable mono_theta
	variable mono_bend
	variable d_spacing

	# calculate from real motor positions and motor parameters
	return [energy_calculate $mono_theta $mono_bend $d_spacing 0 0 0 0]
}


proc energy_calculate { mt mb ds ts th2 tv1 tv2 } {

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

proc energy_calculate_table_slide { mt } {
    set a -1013.3
    set b 136.52
    ### max abs error: R2=1

    return [expr \
    $a + \
    $b * $mt 
    ]
}

proc energy_calculate_table_vert_1 { mt } {

    set a  7.92945       
    set b  0.0200897    

    return [expr \
    $a + \
    $b * $mt \
    ]

}

proc energy_calculate_table_vert_2 { mt } {
 
    set a  -4.00267 
    set b   0.0200824

    return [expr \
    $a + \
    $b * $mt \
    ]

}

##########################
### copiee from 12-2
##########################
proc energy_hold_mirror { } {
    variable mirrorHold

    if {$mirrorHold(BOARD) < 0 || $mirrorHold(CHANNEL) < 0} {
        log_error mirror.hold.control not defined in config file
        return -code error "mirror hold not defined"
    }

    set h [start_waitable_operation setDigOutBit \
    $mirrorHold(BOARD) $mirrorHold(CHANNEL) 0]

    wait_for_operation_to_finish $h
    puts "holding mirror"
}
proc energy_release_mirror { } {
    variable ::energy::delta_energy
    variable mirrorHold
    variable beam_happy_cfg
    variable energy_moving_msg

    if {$mirrorHold(BOARD) < 0 || $mirrorHold(CHANNEL) < 0} {
        log_error mirror.hold.control not defined in config file
        return -code error "mirror hold not defined"
    }
    ###03/05/10
    ### Mike Soltis wants a configurable time to wait here.
    set enabled 0
    set extra 0
    set base 0
    set scale 0
    if {[isString mirror_release_delay]} {
        variable mirror_release_delay
        set cfgEnabled [lindex $mirror_release_delay 0]
        set cfgExtra   [lindex $mirror_release_delay 1]
        set cfgBase    [lindex $mirror_release_delay 2]
        set cfgScale   [lindex $mirror_release_delay 3]

        if {[string is integer -strict $cfgEnabled]} {
            set enabled $cfgEnabled
        }
        if {[string is double -strict $cfgExtra]} {
            set extra $cfgExtra
        }
        if {[string is double -strict $cfgBase]} {
            set base $cfgBase
        }
        if {[string is double -strict $cfgScale]} {
            set scale $cfgScale
        }
    }
    if {$enabled && $extra > 0} {
        log_note extra holding time $extra
        wait_for_time $extra
    }
    set h [start_waitable_recovery_operation setDigOutBit \
    $mirrorHold(BOARD) $mirrorHold(CHANNEL) 1]

    wait_for_operation_to_finish $h
    puts "released mirror"

    set timeForBeamHappy [expr $base + $scale * abs($delta_energy)]
    if {$enabled  \
    && $timeForBeamHappy > 0 \
    && $beam_happy_cfg(BOARD) >= 0 \
    && $beam_happy_cfg(CHANNEL) >= 0} {
        set timeInSeconds [expr $timeForBeamHappy / 1000.0]

        #### wait for it and give severe message upon timeInSeconds and 
        #### contniue wait
        global gWaitForGoodBeamMsg
        if {![info exists gWaitForGoodBeamMsg] || $gWaitForGoodBeamMsg == ""} {
            set gWaitForGoodBeamMsg energy_moving_msg
        }
        beamGoodCheckBeamHappy 1 $timeInSeconds 1
        set energy_moving_msg ""
        if {$gWaitForGoodBeamMsg == "energy_moving_msg"} {
            set gWaitForGoodBeamMsg ""
        }
    }
}
proc generic_hold_mirror { device } {
    variable mirror_hold_device

    if {$mirror_hold_device == ""} {
        set mirror_hold_device $device
        energy_hold_mirror
    } else {
        if {[lsearch -exact $mirror_hold_device $device] >= 0} {
            log_warning $device already in \
            mirror_hold_device $mirror_hold_device
        } else {
            lappend mirror_hold_device $device
        }
    }
}
proc generic_release_mirror { device } {
    variable mirror_hold_device

    set index [lsearch -exact $mirror_hold_device $device]
    if {$index < 0} {
        log_warning $device not holding mirror
    }
    while {$index >= 0} {
        set mirror_hold_device [lreplace $mirror_hold_device $index $index]
        set index [lsearch -exact $mirror_hold_device $device]
    }

    if {$mirror_hold_device == ""} {
        energy_release_mirror
    } else {
        log_warning $mirror_hold_device still holding the mirror
    }
}

