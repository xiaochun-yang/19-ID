# CONSTANTS: (all stored in global string)
# string: "check_sample_const"
# num_point_check: 16 num_point_self: 16 sample_time: 0.2 threshold: 0.3 system_on: 1 save_data: 0"
#

proc CSO_get_constant { name } {
    variable ::nScripts::check_sample_const
    variable ::nScripts::sample_z
    switch -exact -- $name {
        num_point_check { return [lindex $check_sample_const 1] }
        num_point_self  { return [lindex $check_sample_const 3] }
        sample_time     { return [lindex $check_sample_const 5] }
        threshold       { return [lindex $check_sample_const 7] }
        system_on       { return [lindex $check_sample_const 9] }
        save_raw_data   { return [lindex $check_sample_const 11] }
        extra_points    { return [lindex $check_sample_const 13] }
        sampleZList     {
            set result [list $sample_z]
            set extra_points [lindex $check_sample_const 13]
            foreach point $extra_points {
                if {[string is double -strict $point]} {
                    lappend result [expr $sample_z + $point]
                }
            }
            return $result
        }
        default         { return -code error "bad name $name" }
    }
}
# 
# CALIBRATION RESULTS: (all stored in global string with history in file)
# from self_calibration:
# string: "check_sample_data:"
# "mm/dd/yy-hh:mm:ss desired_average: 2.2358"
#
proc CSO_get_cal_data { name } {
    variable ::nScripts::check_sample_data

    switch -exact -- $name {
        desired_average { return [lindex $check_sample_data 2] }
        default         { return -code error "bad name $name" }
    }
}

proc CSO_turn_on_laser { } {
    global gOldADCCardExists
    variable CSO_on_value
    variable CSO_mask
    variable CSO_laser_controlBOARD

    if {$gOldADCCardExists} {
        set operationHandle [eval start_waitable_operation setDigitalOutput \
        $CSO_laser_controlBOARD $CSO_on_value $CSO_mask]
    } else {
        set operationHandle [eval start_waitable_operation setDigOut \
        $CSO_laser_controlBOARD $CSO_on_value $CSO_mask]
    }
    set result [wait_for_operation_to_finish $operationHandle]
    wait_for_time 100
}
proc CSO_turn_off_laser { } {
    global gOldADCCardExists
    variable CSO_off_value
    variable CSO_mask
    variable CSO_laser_controlBOARD
    
    if {$gOldADCCardExists} {
        set operationHandle [eval start_waitable_operation setDigitalOutput \
        $CSO_laser_controlBOARD $CSO_off_value $CSO_mask]
    } else {
        set operationHandle [eval start_waitable_operation setDigOut \
        $CSO_laser_controlBOARD $CSO_off_value $CSO_mask]
    }
    set result [wait_for_operation_to_finish $operationHandle]
}

proc check_sample_on_initialize { } {
    global gLaserControl
    global gLaserRead
    variable CSO_on_value
    variable CSO_off_value
    variable CSO_mask
    ###assume both channels in the same board
    variable CSO_laser_controlBOARD
    
    variable CSO_laser_readBOARD
    variable CSO_laser_readCHANNEL

    ###off means both off
    set CSO_off_value 0
    
    loadLaserChannelConfig
    decideADCCard

    set CSO_laser_controlBOARD $gLaserControl(goniometer,BOARD)
    if {$CSO_laser_controlBOARD != $gLaserControl(sample,BOARD)} {
        log_severe need software change to support laser control on \
        different boards
        return
    }
    ###on means sample on goniometer off
    set CSO_on_value [expr 1 << $gLaserControl(sample,CHANNEL)]
    set CSO_mask  [expr $CSO_on_value | (1 << $gLaserControl(goniometer,CHANNEL))]

    set CSO_laser_readBOARD $gLaserRead(sample,BOARD)
    ###skip status "normal"
    set CSO_laser_readCHANNEL [expr $gLaserRead(sample,CHANNEL) + 1]

    puts "check_sample_on: laser config"
    puts "on_value:   $CSO_on_value"
    puts "off_value:  $CSO_off_value"
    puts "mask:       $CSO_mask"
    puts "read: board: $CSO_laser_readBOARD channel: $CSO_laser_readCHANNEL"
}

#sub_command: self_calibration
#             check_sample
proc check_sample_on_start { sub_command args } {
    global gLaserControl
    global gLaserRead

    ###check config
    if {$gLaserControl(goniometer,BOARD) < 0 || \
    $gLaserControl(goniometer,CHANNEL) < 0 || \
    $gLaserControl(sample,BOARD) < 0 || \
    $gLaserControl(sample,CHANNEL) < 0 || \
    $gLaserRead(sample,BOARD) < 0 || \
    $gLaserRead(sample,CHANNEL) < 0} {
        return -code error "laser channel config not found"
    }

    switch -exact -- $sub_command {
        self_calibration {
            CSO_self_calibration
        }
        sample_on {
            CSO_check_sample 1
        }
        sample_off {
            CSO_check_sample 0
        }
        default {
            return -code error "unsuppored command"
        }
    }
}

#check setup to run
#
proc CSO_check_condition { } {
    #turn on laser
    CSO_turn_on_laser
    return 1
}


proc CSO_scan_magnet { num_point } {
    variable gonio_phi

    ##retrieve saved info
    set average_time [CSO_get_constant sample_time]
    if {$average_time == ""} {
        set average_time 0
    }

    #caller will make sure num_point is in good range
    if {$num_point <= 0} {
        return ""
    }
    set phi0 $gonio_phi
    set phi_stepsize [expr 360.0 / $num_point]

    set restore_lights 1
    if {[catch centerSaveAndSetLights errMsg]} {
        log_warning lights control failed $errMsg
        set restore_lights 0
    }
    CSO_turn_on_laser
    set resultList {}
    for {set i 0} {$i < $num_point} {incr i} {
        set phi [expr $phi0 + $i * $phi_stepsize]
        lappend resultList [CSO_get_displacement $phi $average_time] 
    }
    CSO_turn_off_laser
    if {$restore_lights} {
        centerRestoreLights
    }
    #move back to origianl position
    move gonio_phi to $phi0
    wait_for_motors [list gonio_phi]
    
    #DEBUG
    if {[CSO_get_constant save_raw_data] == "1"} {
        set filename check_sample_self[clock format [clock seconds] -format "%d%b%y%H%M%S"].scan
        if ![catch {open $filename w} fileHandle] {
            for {set i 0} {$i < $num_point} {incr i} {
                puts $fileHandle [lindex $resultList $i]
            }
            close $fileHandle
        }
    }
    return $resultList
}
proc CSO_get_displacement {phi average_time} {
    global gOldADCCardExists
    variable CSO_laser_readBOARD
    variable CSO_laser_readCHANNEL

    move gonio_phi to $phi
    wait_for_devices gonio_phi

    set timeInMs [expr 1000.0 * $average_time]
    if {$gOldADCCardExists} {
        set h [start_waitable_operation readAnalog $timeInMs]
    } else {
        set h [start_waitable_operation readDaq $CSO_laser_readBOARD $timeInMs median]
    }
    set result [wait_for_operation_to_finish $h]
    if {[string first abort $result] >= 0} {
        return -code error "aborted"
    }
    return [lindex $result $CSO_laser_readCHANNEL]
}

proc CSO_self_calibration { } {
    variable ::nScripts::check_sample_data
    variable ::nScripts::sample_z

    set PI 3.14159265359

    set timeStamp [clock format [clock seconds] -format "%D-%T"]
    
    set num_point [CSO_get_constant num_point_self]
    if {$num_point == "" || $num_point < 1} {
        log_warning bad num_point_self in string check_sample_const
        set num_point 1
    }
    set sampleZList [CSO_get_constant sampleZList]
    
    set save_sample_z $sample_z

    set avgList [list]
    if {[catch {
        foreach position $sampleZList {
            move sample_z to $position
            wait_for_devices sample_z
            set result [CSO_scan_magnet $num_point]
            foreach {ll avg max min} [CSO_process_data $result] break
            send_operation_update "num points: $ll average: $avg max: $max min: $min"
            lappend avgList $avg
        }
        set check_sample_data [list $timeStamp desired_average: $avgList]
    } errMsg]} {
        log_error failed to get desired_average at new sample_z location: $errMsg
    }
    move sample_z to $save_sample_z
    wait_for_devices sample_z

    #save to history file
    if [catch {open check_sample_cal.log a} fileHandle] {
        log_error "open history file for auto sample cal failed"
    } else {
        puts $fileHandle $check_sample_data
        close $fileHandle
    }
}

#check whether deltas exceed thresholds.
proc CSO_check_sample { sample_should_on } {
    variable ::nScripts::sample_z
    set save_sample_z $sample_z

    set timeStamp [clock format [clock seconds] -format "%D-%T"]

    ###############get and check constants##################
    set num_point [CSO_get_constant num_point_check]
    if {$num_point == "" || $num_point < 1} {
        log_warning bad num_point_check in string check_sample_const
        set num_point 1
    }
    set threshold      [CSO_get_constant threshold]
    #DEBUG
    send_operation_update "check points: $num_point threshold: $threshold"

    set offAverageList [CSO_get_cal_data desired_average]
    set sampleZList [CSO_get_constant sampleZList]
    if {[llength $offAverageList] != [llength $sampleZList]} {
        log_warning sample laser calibration out of date
        set offAverageList [lindex $offAverageList 0]
        set sampleZList [lindex $sampleZList 0]
    }

    ###only check extra for sample_should_on
    if {!$sample_should_on} {
        set offAverageList [lindex $offAverageList 0]
        set sampleZList [lindex $sampleZList 0]
    }
    set exceedThreshold 0
    set maxDelta 0

    ###disable retry because the spot now is off center
    ###Retrying with more points at different phi position
    ###does not make sense anymore
    #### 03/09/11: maybe retry is OK.
    for {set loop 0} {$loop < 2} {incr loop} {
        if {$loop != 0} {
            log_warning laser sample check failed, trying more points
        }

        ###it will stop at any exceed threshold
        set pIndex 0
        foreach position $sampleZList off_average $offAverageList {
            if {$pIndex == 1 && $loop == 0} {
                variable ::nScripts::auto_sample_msg
                set auto_sample_msg "Cannot locate pin...searching"
            }
            ###log_warning checking at sample_z=$position
            move sample_z to $position
            wait_for_devices sample_z
            #do the data collection
            set result [CSO_scan_magnet $num_point]
            foreach {ll avg max min} [CSO_process_data $result] break

            #check thresholds
            set delta1 [expr abs($avg - $off_average)]
            set delta2 [expr abs($max - $off_average)]
            set delta3 [expr abs($min - $off_average)]
            set delta_list [list $delta1 $delta2 $delta3]
            foreach {dummy delta_avg delta_max delta_min} [CSO_process_data $delta_list] break

            set delta $delta_max
            ####log_warning delta=$delta

            ####log_warning DEBUG at pos=$position average=$off_average delta=$delta
            ####log_warning DEBUG signal avg $avg max $max min $min

            if {$delta > $maxDelta} {
                set maxDelta $delta
            }
            if {$delta >= $threshold} {
                set exceedThreshold 1
                ##log_note exceedThreshold at $position
                break
            }
            incr pIndex
        }
        ##only retry if not success
        if {$sample_should_on && $exceedThreshold} {
            break
        }
        if {!$sample_should_on && !$exceedThreshold} {
            break
        }
        set num_point [expr $num_point * 4]
    }
    move sample_z to $save_sample_z
    wait_for_devices sample_z
    if {$sample_should_on && $exceedThreshold} {
        if [catch {open check_sample_chk.log a} fileHandle] {
            log_error "open history file for sample check failed"
        } else {
            if {$num_point == 1} {
                puts $fileHandle "$timeStamp $maxDelta ON PASSED at $position"
            } else {
                puts $fileHandle "$timeStamp $maxDelta ON PASSED at $position with $num_point points"
            }
            close $fileHandle
        }
        send_operation_update "sample on delta=$maxDelta"
        return "OK sample on goniometer"
    }
    if {!$sample_should_on && !$exceedThreshold} {
        if [catch {open check_sample_chk.log a} fileHandle] {
            log_error "open history file for sample check failed"
        } else {
            puts $fileHandle "$timeStamp $maxDelta OFF PASSED"
            close $fileHandle
        }
        send_operation_update "sample off delta=$maxDelta"
        return "OK sample not on goniometer"
    }

    #####failed#######
    #log
    if [catch {open check_sample_chk.log a} fileHandle] {
        log_error "open history file for auto sample check failed"
    } else {
        if {$sample_should_on} {
            puts $fileHandle "$timeStamp $maxDelta ON FAILED"
        } else {
            puts $fileHandle "$timeStamp $maxDelta OFF FAILED at $position"
        }
        close $fileHandle
    }
    ##### it must return exactly following text
    if {$sample_should_on} {
        return -code error "no_sample_on_goniometer"
    } else {
        return -code error "sample_still_on_goniometer"
    }
}

###return num points, average, max and min
proc CSO_process_data { data } {
    ### get average, max, min
    set ll [llength $data]
    if {$ll <= 0} {
        return -code error "empty data"
    }
    set min [lindex $data 0]
    set max $min
    set avg $min
    for {set i 1} {$i < $ll} {incr i} {
        set value [lindex $data $i]
        set avg [expr $avg + $value]
        if {$value > $max} {
            set max $value
        }
        if {$value < $min} {
            set min $value
        }
    }
    set avg [expr $avg / double($ll)]

    return [list $ll $avg $max $min]
}
