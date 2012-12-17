#
# This is configurable energy.
# The energy is only related to mono theta.
# Other parts are configurable to move or ignore.
#
# it will read config from a string named "energy_config"
#
# The fields are:
#
# 0:         allow gap move
#
# 1:         allow harmonic jump
#
# 2:         allow table_vert move
#
# 3:         allow focussing_miror_2_vert move
#
# 4:         allow detector_vert adjust
#
# 5:         allow preamplifier change
#
###############################################################
# offset
###############################################################
# 01/20/09
# offset now changed to offset for each harmonic
# so it will be a set of offsets for each harmonic
# For each set, the name for devices are in the string "energy_offset_namelist"
#
# offsets are in string "energy_offset"
#
# for BL12-2, the name list is
# undulator_gap
# table_vert_1
# table_vert_2
# focusing_mirror_2_vert
# detector_energy_vert_offset
#

### we use this to select harmonic for madScan
proc energy_rangeCheck_callback { first last } {
    variable harmonicHL
    variable harmonicLL
    variable harmonicName
    variable currentHarmonic
    variable currentHarmonicName

    variable d_spacing

    #log_warning DEBUG calling energy_rangeCheck_callback $first $last

    if {$first > $last} {
        set min [expr $last - 100.0]
        set max [expr $first + 100.0]
    } else {
        set min [expr $first - 100.0]
        set max [expr $last + 100.0]
    }

    set ll [llength $harmonicHL]
    for {set i 0} {$i < $ll} {incr i} {
        if {$min >= [lindex $harmonicLL $i] && \
        $max <= [lindex $harmonicHL $i]} {
            break
        }
    }
    if {$i >= $ll} {
        log_error DEBUG the required energy min=$min max=$max
        return -code error "energy out of all harmomic range"
    }

    if {[energyGetEnabled harmonic_jump]} {
        if {$currentHarmonic != $i} {
            set currentHarmonic $i
            set currentHarmonicName [lindex $harmonicName $currentHarmonic]
            puts "DEBUG set harmonic to $currentHarmonicName for madScan"
        }
    } else {
        if {$currentHarmonic != $i} {
            if {[energyGetEnabled gap_move] && \
            ($min < [lindex $harmonicLL $currentHarmonic] || \
            $max > [lindex $harmonicHL $currentHarmonic])} {
                return -code error "madScan range exceeds valid gap range"
            }
            log_warning skip set harmonic for madScan
            puts "skip harmonic set from $currentHarmonic to $i for madScan"
        }
    }

}

proc energy_initialize { } {
    variable energy_component_list
    variable harmonicLL
    variable harmonicHL
    variable harmonicName
    variable harmonicA
    variable harmonicB
    variable harmonicC
    variable harmonicD
    variable harmonicE

    variable mirrorHold

    variable energy_offset_namelist

    set mirrorHold(BOARD) -1
    set mirrorHold(CHANNEL) -1
    set cfg [::config getStr mirror.hold.control]
    if {[llength $cfg] >= 2} {
        set mirrorHold(BOARD)   [lindex $cfg 0]
        set mirrorHold(CHANNEL) [lindex $cfg 1]
        puts "for mirrorHold: $cfg"
    }
    
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


    ###these are  energy value
    #### THEY MUST BE OVERLAP
    #### jump at 13000 and 10000
    #set harmonicLL   [list 12999.99      10000      6600]
    #set harmonicHL   [list 17000         14000     10600]

    #set harmonicLL   [list 15449.99      12999.99      10000      6600]
    #set harmonicHL   [list 17010         16000         14000     10600]
    ### here the range should be a little bit more than the energy limits
    set harmonicLL   [list 15449.99      12999.99      10000      6689]
    set harmonicHL   [list 17001         16000         14000     11000]

    set harmonicName [list 11th                      9th                     7th                     5th]
    set harmonicA    [list  6.7867400512153101E-04   3.6837022183192189E-04   1.0694288376344890E-03  1.5252539495651564E-03]
    set harmonicB    [list  5.6539724966786494E+01   3.7291472222998010E+00   5.8640977876580820E+01  5.7762908492288773E+01]
    set harmonicC    [list -3.2588410710792530E+00  -2.2407358447015291E-01  -3.5329096184687216E+00 -3.6287372026669402E+00]
    set harmonicD    [list -1.7336954530822180E-05  -2.2881181643562087E-04  -3.6970532895891361E-05  6.0747270294037037E-05]
    set harmonicE    [list -2.4645516392209950E+02  -1.3691497418555402E+01  -2.4483012055833964E+02 -2.3145477561004094E+02]

    ### must match with config "energy.config"
    ### which is used for the GUI to display names
    set energy_component_list [list \
    hold_mirror \
    gap_move \
    harmonic_jump \
    table_vert_move \
    focusing_mirror_2_vert_move \
    detector_vert_move \
    preamplifier_change \
    set_threshold \
    table_horz_move \
    mfd_vert_move \
    mfd_horz_move \
    ]

    set offsetNameList [list \
    undulator_gap \
    table_vert_1 \
    table_vert_2 \
    focusing_mirror_2_vert_1 \
    focusing_mirror_2_vert_2 \
    detector_energy_vert_offset \
    table_horz \
    mfd_vert \
    mfd_horz \
    ]
    if {$energy_offset_namelist != $offsetNameList} {
        set energy_offset_namelist $offsetNameList
        log_warning reset energy_offset_namelist to $energy_offset_namelist
    }

    set_children mono_theta d_spacing undulator_gap

    ###register callbak
    global gEnergyRangeCheck
    lappend gEnergyRangeCheck energy_rangeCheck_callback

    namespace eval ::energy { 
        set current_energy 0
        set delta_energy 0
        set inMadScan 0
        set inAlignTungsten 0
    }
}
proc energyGetEnabled { component } {
    variable energy_config
    variable energy_component_list

    set index [lsearch -exact $energy_component_list $component]

    if {$index < 0} {
        log_error component $component not found in \
        list $energy_component_list
        return 1
    }
    set ll [llength $energy_config]
    if {$index >= $ll} {
        log_error energy_config too short
        return 1
    }

    set enabled [lindex $energy_config $index]

    if {$enabled == 0 || $enabled == 1} {
        return $enabled
    }

    log_error wrong value "{$enabled}" should be 1 or 0

    return 1
}
proc energySetEnabled { component value } {
    variable energy_config
    variable energy_component_list

    set index [lsearch -exact $energy_component_list $component]

    if {$index < 0} {
        log_error component $component not found in \
        list $energy_component_list

        return -code error component_not_found
    }
    set ll [llength $energy_config]
    if {$index >= $ll} {
        log_error energy_config too short
        return -code error energy_config_too_short
    }

    if {$value} {
        set value 1
    } else {
        set value 0
    }
    set energy_config [lreplace $energy_config $index $index $value]
    
    if {$value} {
        log_warning $component enabled
    } else {
        log_warning $component disabled
    }
}
proc energy_move { new_energy } {
    global gOperation

    variable d_spacing
    variable detector_energy_vert_offset
    variable mfd_vert_energy_offset
    variable mfd_horz_energy_offset
    ####following are for check need to hold mirror
    variable mono_theta
    variable undulator_gap
    variable table_vert_1
    variable table_vert_2
    variable table_horz
    variable focusing_mirror_2_vert_1
    variable focusing_mirror_2_vert_2
    variable focusing_mirror_2_mfd_vert
    variable mirror_mfd_horz

    variable ::energy::current_energy
    variable ::energy::delta_energy
    variable ::energy::inMadScan
    variable ::energy::inAlignTungsten
    variable energy
    variable energy_moving_msg

    set inMadScan 0
    ### it will return error if madScan is not
    ### in script engine anymore.
    ### it will force us to change here.
    if {$gOperation(madScan,status) != "inactive" && \
    $gOperation(recoverFromScan,status) == "inactive"} {
        set inMadScan 1
        #log_warning DEBUG madScanMovingEnergy
    }

    set inAlignTungsten 0
    if {$gOperation(alignTungsten,status) != "inactive" \
    ||  $gOperation(userAlignBeam,status) != "inactive" \
    } {
        set inAlignTungsten 1
        #log_warning DEBUG alignTungstenMovingEnergy
    }





    set energy_moving_msg ""

    set current_energy $energy
    set delta_energy [expr $new_energy - $energy]

    ###################################
    ## hold mirror
    ###################################
    # decide whether need to hold mirror
    #
    # if no move in mono_theta and table_vert, skip the hold mirror
    # detector_vert no need to hold mirror
    ###################################################
    set new_mono_theta [energy_calculate_mono_theta $new_energy $d_spacing]

    set new_gap [energy_calculate_undulator_gap $new_energy]
    set gap_offset [energy_get_offset undulator_gap]
    set new_gap [expr $new_gap + $gap_offset]

    set new_vert1 [energy_calculate_table_vert1 $new_mono_theta]
    set new_vert2 [energy_calculate_table_vert2 $new_mono_theta]
    set offset1 [energy_get_offset table_vert_1]
    set offset2 [energy_get_offset table_vert_2]
    set new_vert_1 [expr $new_vert1 + $offset1]
    set new_vert_2 [expr $new_vert2 + $offset2]
    
    #log_warning DEBUG new_vert=$new_vert
    #log_warning DEBUG offset1=$offset1 offset2=$offset2
    #log_warning DEBUG new_vert_1=$new_vert_1 2=$new_vert_2

    set new_FM2_vert [energy_calculate_FM2 $new_mono_theta]
    set offset1 [energy_get_offset focusing_mirror_2_vert_1]
    set offset2 [energy_get_offset focusing_mirror_2_vert_2]
    set new_FM2_vert_1 [expr $new_FM2_vert + $offset1]
    set new_FM2_vert_2 [expr $new_FM2_vert + $offset2]

    #log_warning DEBUG new_FM2_vert $new_FM2_vert
    #log_warning DEBUG offset1=$offset1 offset2=$offset2
    #log_warning DEBUG new_FM2_vert_1=$new_FM2_vert_1 2=$new_FM2_vert_2

    set new_horz [energy_calculate_table_horz $new_mono_theta]
    set offset   [energy_get_offset table_horz]
    set new_horz [expr $new_horz + $offset]
    log_warning DEBUG new_horz $new_horz

    set new_mfd_vert [energy_calculate_mfd_vert $new_mono_theta]
    set offset       [energy_get_offset mfd_vert]
    set new_mfd_vert [expr $new_mfd_vert + $offset]
    log_warning DEBUG new_mfd_vert $new_mfd_vert

    set new_mfd_horz [energy_calculate_mfd_horz $new_mono_theta]
    set offset       [energy_get_offset mfd_horz]
    set new_mfd_horz [expr $new_mfd_horz + $offset]
    log_warning DEBUG new_mfd_horz $new_mfd_horz


    ########## LIMIT CHECKING ###################
	assertMotorLimit mono_theta $new_mono_theta
    if {[energyGetEnabled gap_move]} {
	    assertMotorLimit undulator_gap $new_gap
    }

    if {[energyGetEnabled focusing_mirror_2_vert_move]} {
        assertMotorLimit focusing_mirror_2_vert_1 $new_FM2_vert_1
        assertMotorLimit focusing_mirror_2_vert_2 $new_FM2_vert_2
    }
    ###still, we cannot check detector_vert for this

    set needToHoldMirror 0
    if {!$needToHoldMirror && \
    abs($new_mono_theta - $mono_theta) > 0.001} {
        set needToHoldMirror 1
        #log_warning DEBUG need hold mirror by mono_theta
    }
    if {!$needToHoldMirror && \
    [energyGetEnabled gap_move] && \
    abs($new_gap - $undulator_gap) > 0.001} {
        set needToHoldMirror 1
        #log_warning DEBUG need hold mirror by undulator_gap 
    }
    if {!$needToHoldMirror && [energyGetEnabled table_vert_move]} {
	        get_encoder table_vert_1_encoder
	        get_encoder table_vert_2_encoder

	        set table_vert_1_encoder_value \
            [wait_for_encoder table_vert_1_encoder]

	        set table_vert_2_encoder_value \
            [wait_for_encoder table_vert_2_encoder]

            if {abs($new_vert_1 - $table_vert_1_encoder_value) > 0.001 \
            ||  abs($new_vert_2 - $table_vert_2_encoder_value) > 0.001 \
            } {
                set needToHoldMirror 1
                #log_warning DEBUG need hold mirror by table_vert
            }
    }

    if {!$needToHoldMirror && \
    [energyGetEnabled focusing_mirror_2_vert_move] &&
    (abs($new_FM2_vert_1 - $focusing_mirror_2_vert_1) > 0.001 || \
     abs($new_FM2_vert_2 - $focusing_mirror_2_vert_2) > 0.001 \
    )} {
        set needToHoldMirror 1
        #log_warning DEBUG need hold mirror by focusing_mirror_2_vert
    }

    if {!$needToHoldMirror && [energyGetEnabled table_horz_move]} {
	        get_encoder table_horz_encoder
	        set table_horz_encoder_value [wait_for_encoder table_horz_encoder]
            if {abs($new_horz - $table_horz_encoder_value) > 0.001 } {
                set needToHoldMirror 1
                #log_warning DEBUG need hold mirror by table_horz
            }
    }

    if {$needToHoldMirror} {
        if {[energyGetEnabled hold_mirror]} {
            generic_hold_mirror energy
        } else {
            log_warning skip hold mirror
        }
    } else {
        #log_warning DEBUG no need to hold mirror
    }

    ############## catch to make sure release mirror ###########
    if {[catch {
        set waitingList {}
        set encoderArgs {}

        #######################
        # mono theta
        #######################
        #move mono_theta to $new_mono_theta
        #lappend waitingList mono_theta
        move mono_theta_corr to $new_mono_theta
        lappend waitingList mono_theta_corr

        #######################
        # undulator gap
        #######################
        if {[energyGetEnabled gap_move]} {
            move undulator_gap to $new_gap
            lappend waitingList undulator_gap
        } else {
            log_warning skip move undulator_gap to $new_gap
        }

        ######################
        # table vert
        ######################
        if {[energyGetEnabled table_vert_move]} {
                lappend encoderArgs \
                [list table_vert_1_encoder $new_vert_1] \
                [list table_vert_2_encoder $new_vert_2] \
        } else {
                log_warning skip move table_vert_1_encoder to $new_vert_1
                log_warning skip move table_vert_2_encoder to $new_vert_2
        }

        if {[energyGetEnabled table_horz_move]} {
                lappend encoderArgs \
                [list table_horz_encoder $new_horz] \
        } else {
                log_warning skip move table_horz_encoder to $new_horz
        }

        ###################################
        # focusing_mirror_2_vert
        ###############################
        if {[energyGetEnabled focusing_mirror_2_vert_move]} {
            move focusing_mirror_2_vert_1 to $new_FM2_vert_1
            move focusing_mirror_2_vert_2 to $new_FM2_vert_2
            lappend waitingList \
            focusing_mirror_2_vert_1 focusing_mirror_2_vert_2
        } else {
            log_warning skip move focusing_mirror_2_vert_1 to $new_FM2_vert_1
            log_warning skip move focusing_mirror_2_vert_2 to $new_FM2_vert_2
        }

        ##################################
        # detector_energy_vert_offset
        ##################################
        set new_detector_vert_offset \
        [energy_calculate_detector_vert_offset $new_mono_theta]

        set offset [energy_get_offset detector_energy_vert_offset]
        set new_detector_vert_offset [expr $new_detector_vert_offset + $offset]
        if {[energyGetEnabled detector_vert_move]} {
            set detector_energy_vert_offset $new_detector_vert_offset
            move detector_z_corr by 0
            lappend waitingList detector_z_corr
        } else {
            log_warning skip set detector_energy_vert_offset to \
            $new_detector_vert_offset
            log_warning and skip adjust the detector position
        }

        if {[energyGetEnabled mfd_vert_move]} {
            set mfd_vert_energy_offset $new_mfd_vert
            move beam_size_sample_y by 0
            wait_for_devices beam_size_sample_y
        } else {
            log_warning skip set mfd_vert_energy_offset $new_mfd_vert
        }

        if {[energyGetEnabled mfd_horz_move]} {
            set mfd_horz_energy_offset $new_mfd_horz
            move beam_size_sample_x by 0
            wait_for_devices beam_size_sample_x
        } else {
            log_warning skip set mfd_horz_energy_offset $new_mfd_horz
        }
        if {$encoderArgs != ""} {
            ### 0 means not serial move
            set firstArg 0
            if {$inMadScan} {
                ### max retry 1 time
                set firstArg [list 0 1]
            }

            set encoderHandle [start_waitable_operation moveEncoders \
            $firstArg $encoderArgs]

            wait_for_operation_to_finish $encoderHandle
        }

        if {$waitingList != ""} {
            eval wait_for_devices $waitingList
        }

        #################################
        ## preamplifier settings
        #################################
        energy_preamplifiers $new_mono_theta

        
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
        foreach {g t} [energy_calculate_threshold $new_energy] break
        if {[energyGetEnabled set_threshold] && $isCollecting} {
            log_warning setting detector threshold
            set h [start_waitable_operation detectorSetThreshold $g $t]
            wait_for_operation_to_finish $h
        } else {
            log_warning skip setting detector threshold to $g $t
        }
    } errMsg]} {
        if {$needToHoldMirror && \
        [energyGetEnabled hold_mirror]} {
            #log_warning DEBUG release mirror
            generic_release_mirror energy
        }
        return -code error $errMsg
    }

    if {$needToHoldMirror && \
    [energyGetEnabled hold_mirror]} {
        generic_release_mirror energy
    }
}
proc energy_set { new_energy } {
    variable d_spacing
    variable detector_energy_vert_offset
    variable mfd_vert_energy_offset
    variable mfd_horz_energy_offset

    variable mono_theta
    variable undulator_gap
    variable table_vert_1
    variable table_vert_2
    variable table_horz
    variable focusing_mirror_2_vert_1
    variable focusing_mirror_2_vert_2
    variable focusing_mirror_2_mfd_vert
    variable mirror_mfd_horz
    variable detector_vert
    variable detector_z
    variable beam_size_sample_x
    variable beam_size_sample_y
    variable ::energy::inMadScan
    variable ::energy::inAlignTungsten

    set inMadScan 0
    ### it will return error if madScan is not
    ### in script engine anymore.
    ### it will force us to change here.
    if {$gOperation(madScan,status) != "inactive" && \
    $gOperation(recoverFromScan,status) == "inactive"} {
        set inMadScan 1
        #log_warning DEBUG madScanMovingEnergy
    }

    set inAlignTungsten 0
    if {$gOperation(alignTungsten,status) != "inactive" \
    ||  $gOperation(userAlignBeam,status) != "inactive" \
    } {
        set inAlignTungsten 1
        #log_warning DEBUG alignTungstenMovingEnergy
    }

    #######################
    # mono theta
    #######################
    set new_mono_theta [energy_calculate_mono_theta \
    $new_energy $d_spacing]

    set mono_theta_stepSize 0.001
    
    if {[isDeviceType real_motor mono_theta]} {
        global gDevice
        set mono_theta_stepSize [expr 1.0 / $gDevice(mono_theta,scaleFactor)]
    }

    if {abs($mono_theta - $new_mono_theta) >= $mono_theta_stepSize} {
        set mono_theta $new_mono_theta
    } else {
        log_warning skip setting mono_theta to $new_mono_theta, change too small
    }

    #######################
    # undulator gap
    #######################
    undltrCheckOwner 0
    undltrCheckReady 0
    set gap_offset [expr $undulator_gap - \
        [energy_calculate_undulator_gap $new_energy] \
    ]
    
    if {[energyGetEnabled gap_move]} {
        energy_set_offset undulator_gap $gap_offset
    } else {
        log_error SKIP SET UNDULATOR_GAP_OFFSET to $gap_offset
        log_error CURRENT GAP_OFFSET [energy_get_offset undulator_gap]
    }

    ######################
    # table_vert_1
    # table_vert_2
    # table_horz
    ######################
    set new_vert1 [energy_calculate_table_vert1 $new_mono_theta]
    set new_vert2 [energy_calculate_table_vert2 $new_mono_theta]
    set new_horz [energy_calculate_table_horz $new_mono_theta]
	    get_encoder table_vert_1_encoder
	    get_encoder table_vert_2_encoder
	    get_encoder table_horz_encoder
	    set table_vert_1_encoder_value [wait_for_encoder table_vert_1_encoder]
        set table_vert_2_encoder_value [wait_for_encoder table_vert_2_encoder]
        set table_horz_encoder_value   [wait_for_encoder table_horz_encoder]

        set offset1 [expr $table_vert_1_encoder_value - $new_vert1]
        set offset2 [expr $table_vert_2_encoder_value - $new_vert2]
        set offset  [expr $table_horz_encoder_value   - $new_horz]

        if {[energyGetEnabled table_vert_move]} {
            energy_set_offset table_vert_1 $offset1
            energy_set_offset table_vert_2 $offset2
        } else {
            log_error SKIP SET TABLE_VERT_1 encoder OFFSET to $offset1
            log_error SKIP SET TABLE_VERT_2 encoder OFFSET to $offset2
        }
        if {[energyGetEnabled table_horz_move]} {
            energy_set_offset table_horz $offset
        } else {
            log_error SKIP SET TABLE_HORZ encoder OFFSET to $offset
        }

    ######################
    ######################

    ###################################
    # focusing_mirror_2_vert_1
    # focusing_mirror_2_vert_2
    ###############################
    set new_FM2_vert [energy_calculate_FM2 $new_mono_theta]
    set offset1 [expr $focusing_mirror_2_vert_1 - $new_FM2_vert]
    set offset2 [expr $focusing_mirror_2_vert_2 - $new_FM2_vert]
    if {[energyGetEnabled focusing_mirror_2_vert_move]} {
        energy_set_offset focusing_mirror_2_vert_1 $offset1
        energy_set_offset focusing_mirror_2_vert_2 $offset2
    } else {
        log_error SKIP SET FOCUSING_MIRROR_2_VERT_1 OFFSET $offset1
        log_error SKIP SET FOCUSING_MIRROR_2_VERT_2 OFFSET $offset2
    }

    ##################################
    # detector_energy_vert_offset
    ##################################
    # in moving,
    # we move detector_vert to:
    # vFromZ + vFromUser + vFromEnergy + offset.
    # 
    # in setting, we want vFromUser = 0.
    # so offset = v - vFromZ - vFromEnergy

    set vFromZ [calculate_detector_vert_center $detector_z]
    set vFromE [energy_calculate_detector_vert_offset $new_mono_theta]

    set offset [expr $detector_vert - $vFromZ - $vFromE]

    if {[energyGetEnabled detector_vert_move]} {
        energy_set_offset detector_energy_vert_offset $offset
    } else {
        log_error SKIP SET DETECTOR_ENERGY_VERT_OFFSET ADJUST to $offset
    }

    ######################
    # mfd: we saved 2 offsets: one in energy, one in beam size.
    ## may be able to just use one: set the beam size here, instead of
    ## save another offset in energy
    ######################
    get_encoder mirror_mfd_horz_encoder
    get_encoder focusing_mirror_2_mfd_vert_encoder
    set mfd_horz_encoder_value [wait_for_encoder mirror_mfd_horz_encoder]
    set mfd_vert_encoder_value \
    [wait_for_encoder focusing_mirror_2_mfd_vert_encoder]

    set mfdVFromE    [energy_calculate_mfd_vert $new_mono_theta]
    set mfdHFromE    [energy_calculate_mfd_horz $new_mono_theta]
    set mfdVFromSize [beam_size_sample_y_calculate_mfd_vert $beam_size_sample_y]
    set mfdHFromSize [beam_size_sample_x_calculate_mfd_horz $beam_size_sample_x]
    set mfdVOFromSize [beam_size_sample_get_offset focusing_mirror_2_mfd_vert]
    set mfdHOFromSize [beam_size_sample_get_offset mirror_mfd_horz]

    set offsetV [expr $mfd_vert_encoder_value \
    - $mfdVFromE - $mfdVFromSize - $mfdVOFromSize]

    set offsetH [expr $mfd_horz_encoder_value \
    - $mfdHFromE - $mfdHFromSize - $mfdHOFromSize]

    if {[energyGetEnabled mfd_vert_move]} {
        set old [energy_get_offset mfd_vert]
        energy_set_offset mfd_vert $offsetV
        set mfd_vert_energy_offset [expr $mfdVFromE + $offsetV]
        log_warning \
        focusing_mirror_2_mfd_vert offset set to $offsetV from $old
    } else {
        log_error SKIP SET mfd_vert_encoder OFFSET to $offsetV
    }

    if {[energyGetEnabled mfd_horz_move]} {
        set old [energy_get_offset mfd_horz]
        energy_set_offset mfd_horz $offsetH
        set mfd_horz_energy_offset [expr $mfdHFromE + $offsetH]
        log_warning \
        mirror_mfd_horz offset set to $offsetH from $old
    } else {
        log_error SKIP SET mfd_horz_encoder OFFSET to $offsetH
    }
}
proc energy_calculate_undulator_gap { e } {
    global gOperation

    variable harmonicHL
    variable harmonicLL
    variable harmonicName
    variable currentHarmonic
    variable currentHarmonicName

    variable ::energy::inMadScan
    variable ::energy::inAlignTungsten

    set ll [llength $harmonicHL]
    for {set i 0} {$i < $ll} {incr i} {
        if {$e >= [lindex $harmonicLL $i] && \
        $e <= [lindex $harmonicHL $i]} {
            break
        }
    }
    if {$i >= $ll} {
        log_error DEBUG required energy: $e
        return -code error "energy out of all harmomic range"
    }

    set inMadScan 0
    ### it will return error if madScan is not
    ### in script engine anymore.
    ### it will force us to change here.
    if {$gOperation(madScan,status) != "inactive" && \
    $gOperation(recoverFromScan,status) == "inactive"} {
        set inMadScan 1
        #log_warning DEBUG madScanMovingEnergy
    }

    ### case for normal energy moving
    if {[energyGetEnabled harmonic_jump] && !$inMadScan && !$inAlignTungsten} {
        set currentHarmonic $i
        set currentHarmonicName [lindex $harmonicName $currentHarmonic]
    } else {
        if {$currentHarmonic != $i} {
            ##log_warning skip harmonic jump
            log_warning skip harmonic jump from $currentHarmonic to $i
            puts "skip harmonic jump from $currentHarmonic to $i"
        }
    }

    return [energy_calculate_undulator_gap_in_current_harmonic $e]
}
proc energy_calculate_undulator_gap_in_current_harmonic { e } {
    variable harmonicA
    variable harmonicB
    variable harmonicC
    variable harmonicD
    variable harmonicE
    variable currentHarmonic

    set A [lindex $harmonicA $currentHarmonic]
    set B [lindex $harmonicB $currentHarmonic]
    set C [lindex $harmonicC $currentHarmonic]
    set D [lindex $harmonicD $currentHarmonic]
    set E [lindex $harmonicE $currentHarmonic]

    #y=a*x + b * ln(x) + c * ln(x) * ln(x) + d * cos(x) + e
    set x [expr double($e)]
    set lnx  [expr log($x)]
    set cosx [expr cos($x)]

    set result [expr \
    $A * $x + \
    $B * $lnx + \
    $C * $lnx * $lnx + \
    $D * $cosx + \
    $E]
    return $result
}
proc energy_get_offset { motor } {
    variable harmonicName
    variable currentHarmonic
    variable energy_offset_namelist
    variable energy_offset

    set index [lsearch -exact $energy_offset_namelist $motor]
    if {$index < 0} {
        return -code error \
        "{$motor} not in energy_offset_namelist: $energy_offset_namelist" 
    }

    set ll1 [llength $energy_offset]
    set ll2 [llength $harmonicName]
    if {$ll1 != $ll2} {
        return -code error "length of energy_offset not match with harmonicName"
    }

    set offset_set [lindex $energy_offset $currentHarmonic]
    set ll1 [llength $offset_set]
    set ll2 [llength $energy_offset_namelist]
    if {$ll1 != $ll2} {
        return -code error "length of offset not match with namelist"
    }

    set result [lindex $offset_set $index]
    if {![string is double -strict $result]} {
        log_error wrong offset "{$result}" for $motor
        puts "energy_offset: $energy_offset"
        puts "currentHarmonic: $currentHarmonic"
        puts "offset_set: $offset_set"
        puts "index: $index"
        return -code error "wrong offset"
    }
    return $result
}
proc energy_set_offset { motor offset } {
    variable currentHarmonic
    variable harmonicName
    variable energy_offset_namelist
    variable energy_offset

    variable collect_config

    set setAll [lindex $collect_config 10]
    if {$setAll == ""} {
        set setAll 0
    }

    set index [lsearch -exact $energy_offset_namelist $motor]
    if {$index < 0} {
        return -code error \
        "{$motor} not in energy_offset_namelist: $energy_offset_namelist" 
    }
    if {![string is double -strict $offset]} {
        log_error wrong offset "{$offset}" for $motor
        return -code error "wrong offset $offset for $motor"
    }

    set ll1 [llength $energy_offset]
    set ll2 [llength $harmonicName]
    if {$ll1 != $ll2} {
        return -code error "length of energy_offset not match with harmonicName"
    }

    set numHarm $ll2

    if {$currentHarmonic >= $ll1} {
        log_error energy_offset not match with the harmonic list
        return -code error "not_enough_data_in_offset"
    }

    if {!$setAll || $motor == "undulator_gap"} {
        set offset_set [lindex $energy_offset $currentHarmonic]
        set ll1 [llength $offset_set]
        set ll2 [llength $energy_offset_namelist]
        if {$ll1 != $ll2} {
            return -code error "length of offset not match with namelist"
        }
        set old [lindex $offset_set $index]
        set offset_set [lreplace $offset_set $index $index $offset]
        set energy_offset \
        [lreplace $energy_offset $currentHarmonic $currentHarmonic $offset_set]
        log_warning offset for $motor set to $offset from $old \
        for harmonic [lindex $harmonicName $currentHarmonic]
    } else {
        set new_contents $energy_offset
        for {set hhh 0} {$hhh < $numHarm} {incr hhh} {
            set offset_set [lindex $new_contents $hhh]
            set ll1 [llength $offset_set]
            set ll2 [llength $energy_offset_namelist]
            if {$ll1 != $ll2} {
                return -code error "length of offset not match with namelist"
            }
            set old [lindex $offset_set $index]
            set offset_set [lreplace $offset_set $index $index $offset]
            set new_contents \
            [lreplace $new_contents $hhh $hhh $offset_set]
            log_warning offset for $motor set to $offset from $old \
            for harmonic [lindex $harmonicName $hhh]
        }
        set energy_offset $new_contents
    }
}
proc energy_hold_mirror { } {
    variable mirrorHold

    if {$mirrorHold(BOARD) < 0 || $mirrorHold(CHANNEL) < 0} {
        log_error mirror.hold.control not defined in config file
        return -code error "mirror hold not defined"
    }

    set h [start_waitable_operation setDigOutBit \
    $mirrorHold(BOARD) $mirrorHold(CHANNEL) 0]

    wait_for_operation_to_finish $h
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

proc energy_preamplifiers { mt } {
    variable currentHarmonic
    variable ::preampLUT::lut_loaded
    variable attenuation

    set enabled [energyGetEnabled preamplifier_change]

    if {!$lut_loaded} {
        loadPreAmpLUT_start \
        /usr/local/dcs/BL12-2/preamp_h.txt \
        /usr/local/dcs/BL12-2/preamp_v.txt
    }

    if {!$lut_loaded && $enabled} {
        log_error preamp LUT load failed
        return -code error "cannot set preamp"
    }

    adjustPreAmp_start $mt $attenuation $enabled
}
################################
# following are just copied from energy_bl122.
################################
proc energy_update {} {
	variable mono_theta
	variable d_spacing
	variable undulator_gap

	# calculate from real motor positions and motor parameters
	return [energy_calculate $mono_theta $d_spacing $undulator_gap]
}


### must match children motors
proc energy_calculate { mt ds - } {
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

proc energy_motorlist {} {

    # specify motors which move during e-tracking, omitting mono_angle/mono_theta
    return
}

###guess: this is the height changed by energy
proc energyCalculateVertAdjust {mt} {
    set ASE 12.84044
    expr 13.0 * cos([rad $mt]) - $ASE
}

#############################################
### 11/18/10 according to email from Graeme and Mike:
# y=a + bx + cxx + dxxx

#############################################
proc energy_fitVert1 { mt } {
    variable currentHarmonic

    switch -exact -- $currentHarmonic {
        0 -
        1 {
            #return 32.3241
            return -39.6705
        }
        2 {
            #return 32.3152
            return -39.6794
        }
        3 {
            #return 32.3095
            return -39.6851
        }
    }
    return -code error wrong
}
proc energy_fitVert2 { mt } {
    variable currentHarmonic

    switch -exact -- $currentHarmonic {
        0 -
        1 {
            #return 34.5005
            return -37.1478
        }
        2 {
            return -37.1582
        }
        3 {
            #return 34.4854
            return -37.1629
        }
    }
    return -code error wrong
}

proc energy_calculate_table_vert1 { mt } {
    return [energy_fitVert1 $mt]
}
proc energy_calculate_table_vert2 { mt } {
    return [energy_fitVert2 $mt]
}

proc energy_calculate_table_horz { mt } {
    ### this way, each hormanic can has an offset only.
    return -44.0308
}
proc energy_calculate_mfd_vert { mt } {
    variable currentHarmonic

    switch -exact -- $currentHarmonic {
        0 {
            return -5.7256
         }
        1 {
           set A 0.0005364668
           set B -0.00463334
           set C -5.723

         if {$mt > 7.84} {
            return -5.7256
        } else {
            return [expr $A * $mt * $mt + $B * $mt + $C]
        }}

        2 {
            set A 0.00027998
            set B -0.0030593
            set C -5.7258

            return [expr $A * $mt * $mt + $B * $mt + $C]
        }
        3 {
            set A  0.000824155
            set B -0.017634684
            set C -5.623554572

            return [expr $A * $mt * $mt + $B * $mt + $C]
        }
    }
    return 0

}
proc energy_calculate_mfd_horz { mt } {
     variable currentHarmonic
      
     switch -exact -- $currentHarmonic {
        0  { return -61.5488 } 
        1  { return -61.5542 }
        2  { return -61.552 } 
        3  { return -61.567 } 
     } 
     return -61.552         
}

proc energy_calculate_FM2 { mt } {
    return [energy_fitVert1 $mt]
}

proc energy_calculate_detector_vert_offset { mt } {
    variable currentHarmonic

    if {$currentHarmonic != 3} {
        return 0
    }

    set b 4.8251590048015623E-2

    return [expr $b * $mt ]
}

proc energy_calculate_threshold { e } {
    if {$e >= 9500.0} {
        return [list lowg 6000]
    } else {
        return [list midg 3500]
    }
}
####################################################################
### This will give estimated offset for other harmonics from
### current harmonic and current offset.
### It is based on that motor positions should be no jump at the
### harmonic jump.
###
### It will be called from a separate operation.
### It is here because it is strongly coupled with energy implementatino
####################################################################
proc energy_suggest_offset { save } {
    variable currentHarmonic
    variable harmonicLL

    ### save for restore
    set saveCurrentHarmonic $currentHarmonic

    for {set i $saveCurrentHarmonic} {$i < 3} {incr i} {
        ### pretend moving to the low limit
        set currentHarmonic $i
        set e [lindex $harmonicLL $currentHarmonic]
        set pList [energy_get_motor_new_positions $e]
        ### force harmonic change to next harmonic
        set currentHarmonic [expr $i + 1]
        set cList [energy_get_motor_new_calculations $e]
        energy_suggest_offset_output $save $pList $cList
    }

    for {set i $saveCurrentHarmonic} {$i > 0} {incr i -1} {
        ### pretend moving to the high limit
        set currentHarmonic $i
        set e [lindex $harmonicLL [expr $i -1]]
        set pList [energy_get_motor_new_positions $e]
        ### force harmonic change to next harmonic
        set currentHarmonic [expr $i - 1]
        set cList [energy_get_motor_new_calculations $e]
        energy_suggest_offset_output $save $pList $cList
    }

    set currentHarmonic $saveCurrentHarmonic
}
proc energy_suggest_offset_output { save pList cList } {
    variable currentHarmonic
    variable harmonicName

    set hName [lindex $harmonicName $currentHarmonic]

    set check_offset_list [list \
    table_vert_1 \
    table_vert_2 \
    focusing_mirror_2_vert_1 \
    focusing_mirror_2_vert_2 \
    detector_energy_vert_offset \
    table_horz \
    mfd_vert \
    mfd_horz \
    ]

    if {!$save} {
        log_warning ================================================
        log_warning for $hName harmonic
        foreach \
        name $check_offset_list \
        p    $pList \
        c    $cList {
            set offset [expr $p - $c]
            log_warning offset $name = $offset
        }
        return
    }

    ### These are from energy_component_list and
    ### offsetNameList [list.
    ### It is a intersection of the two.
    set check_component_list [list \
    table_vert_move \
    focusing_mirror_2_vert_move \
    detector_vert_move \
    table_horz_move \
    mfd_vert_move \
    mfd_horz_move \
    ]

    set offsetEnabled [list 0 0 0 0 0 0 0 0]

    set component2offsetMap [list \
    [list 0 1 ] \
    [list 2 3 ] \
    4 \
    5 \
    6 \
    7 \
    ]

    foreach \
    com $check_component_list \
    mm $component2offsetMap {
        if {[energyGetEnabled $com]} {
            foreach index $mm {
                set offsetEnabled [lreplace $offsetEnabled $index $index 1]
            }
        }
    }
    log_warning ================================================
    log_warning for $hName harmonic
    foreach \
    name    $check_offset_list \
    enabled $offsetEnabled \
    p       $pList \
    c       $cList {
        set offset [expr $p - $c]
        if {!$enabled} {
            log_error skip setting offset $name = $offset
        } else {
            set oldV [energy_get_offset $name]
            energy_set_offset $name $offset
            log_warning set offset $name = $offset from $oldV
        }
    }

}
proc energy_get_motor_new_positions { e } {
    variable d_spacing

    set new_mono_theta [energy_calculate_mono_theta $e $d_spacing]

    set new_vert1 [energy_calculate_table_vert1 $new_mono_theta]
    set new_vert2 [energy_calculate_table_vert2 $new_mono_theta]
    set offset1   [energy_get_offset table_vert_1]
    set offset2   [energy_get_offset table_vert_2]
    set new_vert_1 [expr $new_vert1 + $offset1]
    set new_vert_2 [expr $new_vert2 + $offset2]

    set new_FM2_vert [energy_calculate_FM2 $new_mono_theta]
    set offset1 [energy_get_offset focusing_mirror_2_vert_1]
    set offset2 [energy_get_offset focusing_mirror_2_vert_2]
    set new_FM2_vert_1 [expr $new_FM2_vert + $offset1]
    set new_FM2_vert_2 [expr $new_FM2_vert + $offset2]

    set new_detector_vert_offset \
    [energy_calculate_detector_vert_offset $new_mono_theta]
    set offset [energy_get_offset detector_energy_vert_offset]
    set new_detector_vert_offset [expr $new_detector_vert_offset + $offset]

    set new_horz [energy_calculate_table_horz $new_mono_theta]
    set offset   [energy_get_offset table_horz]
    set new_horz [expr $new_horz + $offset]

    set new_mfd_vert [energy_calculate_mfd_vert $new_mono_theta]

    set new_mfd_horz [energy_calculate_mfd_horz $new_mono_theta]

    return [list \
    $new_vert_1 $new_vert_2 \
    $new_FM2_vert_1 $new_FM2_vert_2 \
    $new_detector_vert_offset \
    $new_horz \
    $new_mfd_vert \
    $new_mfd_horz \
    ]
}
proc energy_get_motor_new_calculations { e } {
    variable d_spacing

    set new_mono_theta [energy_calculate_mono_theta $e $d_spacing]

    set new_vert_1 [energy_calculate_table_vert1 $new_mono_theta]
    set new_vert_2 [energy_calculate_table_vert2 $new_mono_theta]

    set new_FM2_vert [energy_calculate_FM2 $new_mono_theta]
    set new_FM2_vert_1 $new_FM2_vert
    set new_FM2_vert_2 $new_FM2_vert

    set new_detector_vert_offset \
    [energy_calculate_detector_vert_offset $new_mono_theta]

    set new_horz [energy_calculate_table_horz $new_mono_theta]

    set new_mfd_vert [energy_calculate_mfd_vert $new_mono_theta]

    set new_mfd_horz [energy_calculate_mfd_horz $new_mono_theta]

    return [list \
    $new_vert_1 $new_vert_2 \
    $new_FM2_vert_1 $new_FM2_vert_2 \
    $new_detector_vert_offset \
    $new_horz \
    $new_mfd_vert \
    $new_mfd_horz \
    ]
}
####################################################################

