package require DCSRunField

proc runsConfig_initialize {} {
    global gMAXRUN
    set gMAXRUN 17
}
proc runsConfig_start { user command args } {
    variable collect_config
    ###here is the code to hide all extras from run
    ##############################################
    if {[lindex $collect_config 0] == "1"} {
	    set op_info [get_operation_info]
        set op_name [lindex $op_info 0]
	    set operationHandle [lindex $op_info 1]
        if {$op_name == "runsConfig"} {
            set collect_config [lreplace $collect_config 0 0 0]
            #wait_for_string_contents collect_config 0 0
        }
    }
    ##############################################

        
    switch -exact -- $command {
        resetAllRuns {
            runsResetAllRuns $user
        }
        deleteRun {
            runsDeleteRun [lindex $args 0]
        }
        addNewRun {
            return [eval runsAddNewRun $args]
        }
        resetRun {
            eval runsResetRun $user $args
        }
        checkAllRuns {
            checkRunStatus [lindex $args 0]
        }
        default {
            return -code error "wrong command: $command"
        }
    }
}

proc runsDeleteRun { runNumber_ } {
    global gCurrentRunNumber
    variable runs

    puts "runsDeleteRun $runNumber_"

    if {$runNumber_ == 0} {
        log_warning cannot delete run0 snapshot
        return
    }

    set runCount [lindex $runs 0]
    if {$runCount < 1} {
        return
    }

    if {$runNumber_ < 0 || $runNumber_ > $runCount} {
        return
    }

    puts "shift up"
    ##shift run up
    for {set i $runNumber_} {$i < $runCount} {incr i} {
        set next [expr $i + 1]
        variable run$i
        variable run$next
        variable runExtra$i
        variable runExtra$next

        set run$i      [set run$next]
        set runExtra$i [set runExtra$next]
    }

    ###reduce the count
    set newCount [expr $runCount - 1]
    set currentRun $runNumber_
    if {$currentRun > $newCount} {
        incr currentRun -1
    }
    puts "set up new runs: $newCount $currentRun"
    set runs [lreplace $runs 0 1 $newCount $currentRun]
    #puts "wait for string update runs"
    #wait_for_strings runs
    puts "done delete run"

    checkRunStatus $gCurrentRunNumber
}

proc runsAddNewRun { args } {
    global gCurrentRunNumber
    global gMAXRUN
    variable runs

    set runCount [lindex $runs 0]
    set newRunNumber [expr $runCount + 1]
    if {$newRunNumber >= $gMAXRUN} {
        log_error no spare run place
        return -code error "reached max runs"
    }

    puts "addNewRun: current: $runCount new: $newRunNumber"

    ####copy the previous run and change the runLabel
    variable run$runCount
    variable run$newRunNumber
    variable runExtra$runCount
    variable runExtra$newRunNumber
    set localContents [set run$runCount]
    set dir [::DCS::RunField::getField localContents directory]

    checkUsernameInDirectory dir [get_operation_user]

    set previousRunLabel [::DCS::RunField::getField localContents run_label]
    set newRunLabel [expr $previousRunLabel + 1]

    puts "run label: previous: $previousRunLabel new: $newRunLabel"

    set newRunContents      [set run$runCount]
    set newRunExtraContents [set runExtra$runCount]
    ### adjust
    set ll [llength $args]
    if {$ll > 0} {
        set partRunDef [lindex $args 0]
        set newRunContents [list inactive 0 $newRunLabel]
        eval lappend newRunContents $partRunDef
    } else {
        ::DCS::RunField::setList newRunContents \
        status inactive \
        next_frame 0 \
        run_label $newRunLabel \
        directory $dir

        puts "adjusted new contents: $newRunContents"
    }

    if {$ll > 1} {
        set extraArg [lindex $args 1]
        set lExtraArg [llength $extraArg]
        if {$lExtraArg >= [llength $newRunExtraContents]} {
            set newRunExtraContents $extraArg
        } elseif {$lExtraArg > 0} {
            set endIndex [expr $lExtraArg - 1]
            set replaceCmd "set newRunExtraContents \
            \[lreplace \$newRunExtraContents 0 $endIndex \
            \$extraArg\]"
            eval $replaceCmd
        }
    } else {
        set newRunExtraFile [lindex $newRunExtraContents 1]
        if {[string first / $newRunExtraFile] != 0} {
            set newRunExtraContents [lreplace $newRunExtraContents 0 2 {} {} {}]
        }
    }

    ####set the strings
    puts "setting the strings"
    set run$newRunNumber      $newRunContents
    set runExtra$newRunNumber $newRunExtraContents
    set runs [lreplace $runs 0 1 $newRunNumber $newRunNumber]

    #puts "waiting for string update"
    #wait_for_strings run$newRunNumber runExtra$newRunNumber runs

    puts "done"
    if {$ll > 0} {
        log_note populated run$newRunLabel
    }
    checkRunStatus $gCurrentRunNumber
    return $newRunNumber
}

proc runsResetAllRuns { user_ } {
    global gMAXRUN
    variable runs
    variable collect_default

    ###move attenuation to default
    foreach { delta exposure_time attenuation_default} \
    $collect_default break

    move attenuation to $attenuation_default
    wait_for_devices attenuation

    for {set i 0} {$i < $gMAXRUN} {incr i} {
        runsResetRun $user_ $i
    }

    set runs [lreplace $runs 0 2 0 0 0]
}

proc runsResetRun { user_ args } {
    global gMotorDistance
    global gMotorBeamStop
    global gCurrentRunNumber
    global gMAXRUN

    set runNumber_ [lindex $args 0]
    set dir_       [lindex $args 1]

    if {![string is integer -strict $runNumber_] || \
    $runNumber_ < 0 || $runNumber_ > $gMAXRUN} {
        return -code error "wrong run number {$runNumber_} max $gMAXRUN"
    }
    variable run$runNumber_
    variable runExtra$runNumber_
    variable collect_default
    variable gonio_phi
    variable energy
    variable attenuation

    foreach \
    name  [list beamstop_z      detector_z] \
    motor [list $gMotorBeamStop $gMotorDistance] {
        set ${name}_setting [getMotorGoodPosition $motor]
    }

    set detectorMode [getDetectorDefaultModeIndex] 

    set delta 1.0
    set exposure_time 1.0
    #### use default delta and exposure time
    catch {
        foreach { delta exposure_time attenuation_default} \
        $collect_default break
    }
    if {![string is double -strict $delta]} {
        set delta 1.0
    }
    if {![string is double -strict $exposure_time]} {
        set exposure_time 1.0
    }
    if {![string is double -strict $attenuation_default]} {
        set attenuation_default $attenuation
    }

    set endAngle [expr $gonio_phi + $delta]

    ####default directory
    if {$dir_ != ""} {
        set defaultDir $dir_
    } else {
        set defaultDir [getDefaultDataDirectory $user_]
    }

    set localContents [set run$runNumber_]
    puts "before reset: $localContents"
    ::DCS::RunField::setList localContents \
    status  inactive \
    next_frame  0 \
    file_root   test \
    directory   $defaultDir \
    start_frame 1 \
    axis_motor  Phi \
    start_angle $gonio_phi \
    end_angle   $endAngle \
    delta       $delta \
    wedge_size  180.0 \
    exposure_time $exposure_time \
    distance $detector_z_setting \
    beam_stop $beamstop_z_setting \
    attenuation $attenuation_default \
    num_energy 1 \
    energy1 $energy \
    energy2 0.0 \
    energy3 0.0 \
    energy4 0.0 \
    energy5 0.0 \
    detector_mode $detectorMode \
    inverse_on 0

    puts "after reset: $localContents"
    set run$runNumber_ $localContents
    #wait_for_strings run$runNumber_

    puts "reset runExtra"
    set runExtra$runNumber_ "{} {} {} {} {} {} {} {}"

    puts "end of reset run"
    checkRunStatus $gCurrentRunNumber
}

proc checkRunStatus { index_to_skip } {
    global gMAXRUN
    variable runs

    set runCount [lindex $runs 0]

    for {set i 0} {$i < $gMAXRUN} {incr i} {
        if {$i == $index_to_skip} {
            continue
        }
        variable run$i
        set local_contents [set run$i]
        set runStatus [::DCS::RunField::getField local_contents status]
        if {$runStatus == "collecting"} {
            ::DCS::RunField::setField local_contents status paused
            set run$i $local_contents
            if {$i <= $runCount} {
                log_error run$i status cleared
            }
        }
    }
}

proc getDetectorDefaultModeIndex { } {
    variable detectorType
    set type [lindex $detectorType 0]
	switch -exact -- $type {
		Q4CCD   { return 0 }
		Q315CCD { return 2 }
		MAR345  { return 2 }
		MAR165  { return 0 }
		MAR325  { return 0 }
		default { return 0 }
	}
}
