proc MoveTableBySensor_initialize {} {
}


proc MoveTableBySensor_start { SV1 SV2 SH1 SH2 } {
    set MAX_RETRY_TIME 4

    #block_all_motors
    
    for {set i 0} {$i < $MAX_RETRY_TIME} {incr i} {
        log_note "MoveTableBySenor: step $i"
        set deltaList [MTBS_getDeltaMotorPos $SV1 $SV2 $SH1 $SH2]
        if {![eval MTBS_InitMove $deltaList]} {
            if {![eval MTBS_FineTune $deltaList]} {
                break
            }
            set deltaH2 [MTBS_getDeltaH2 $SV1 $SV2 $SH1 $SH2]
            eval MTBS_FineTuneH2Only $deltaH2
        }
    }

    set result [MTBS_getDeltaSensorPos $SV1 $SV2 $SH1 $SH2]
    log_note "MoveTableBySensor Done! $result"
}

proc MTBS_getDeltaSensorPos { SV1 SV2 SH1 SH2 } {

    #get current sensor value
    if { [catch { 
        set operationHandle [eval start_waitable_operation readAnalog 3000]
        set result [wait_for_operation_to_finish $operationHandle]
        set status [lindex $result 0]
        if {$status != "normal"} {
            return -code error $result
        }
    } e ] } {
        log_error $e
        return -code error $e
    }
    set SV1_now [lindex $result 3]
    set SV2_now [lindex $result 4]
    set SH1_now [lindex $result 5]
    set SH2_now [lindex $result 6]
    MTBS_CheckSensorReading $SV1_now $SV2_now $H1_now $H2_now

    #calculate how much each motor need to move
    set Delta_SV1 [expr $SV1 - $SV1_now]
    set Delta_SV2 [expr $SV2 - $SV2_now]
    set Delta_SH1 [expr $SH1 - $SH1_now]
    set Delta_SH2 [expr $SH2 - $SH2_now]
    set result [format {%f %f %f %f} $Delta_SV1 $Delta_SV2 $Delta_SH1 $Delta_SH2]
    return $result
}

proc MTBS_getDeltaMotorPos { SV1 SV2 SH1 SH2 } {
    variable ::nScripts::dsensor_to_motor_config
    variable ::nScripts::dsensor_to_robot_config

    set V1_SV1_rate [lindex $dsensor_to_motor_config 0]
    set V2_SV2_rate [lindex $dsensor_to_motor_config 1]
    set H1_SH1_rate [lindex $dsensor_to_motor_config 2]
    set H1_SH2_rate [lindex $dsensor_to_motor_config 3]
    set H2_SH2_rate [lindex $dsensor_to_motor_config 4]
        
    set Sensor_Ready [lindex $dsensor_to_robot_config 19]
    if {$Sensor_Ready == ""} {
        set Sensor_Ready 0
    }
    if {!$Sensor_Ready} {
        return -code error "displacement sensor not calibrationed yet"
    }

    set result [MTBS_getDeltaSensorPos $SV1 $SV2 $SH1 $SH2]

    set Delta_SV1 [lindex $result 0]
    set Delta_SV2 [lindex $result 1]
    set Delta_SH1 [lindex $result 2]
    set Delta_SH2 [lindex $result 3]

    set Delta_V1 [expr $Delta_SV1 * $V1_SV1_rate]
    set Delta_V2 [expr $Delta_SV2 * $V2_SV2_rate]
    set Delta_H1 [expr $Delta_SH1 * $H1_SH1_rate]
    #SH2 changed by both motor H1 and H2
    if {$H1_SH2_rate == 0} {
        set Delta_SH2_by_H1 0
    } else {
        set Delta_SH2_by_H1 [expr $Delta_H1 / $H1_SH2_rate]
    }
    
    set Delta_H2 [expr ($Delta_SH2 - $Delta_SH2_by_H1) * $H2_SH2_rate]
    set result [format "%f %f %f %f" $Delta_V1 $Delta_V2 $Delta_H1 $Delta_H2]

    return $result
}

proc MTBS_getDeltaH2 { SV1 SV2 SH1 SH2 } {
    variable ::nScripts::dsensor_to_motor_config
    variable ::nScripts::dsensor_to_robot_config
    set H2_SH2_rate [lindex $dsensor_to_motor_config 4]
        
    set Sensor_Ready [lindex $dsensor_to_robot_config 19]
    if {$Sensor_Ready == ""} {
        set Sensor_Ready 0
    }
    if {!$Sensor_Ready} {
        return -code error "displacement sensor not calibrationed yet"
    }

    set result [MTBS_getDeltaSensorPos $SV1 $SV2 $SH1 $SH2]

    set Delta_SH2 [lindex $result 3]
    set Delta_H2 [expr $Delta_SH2 * $H2_SH2_rate]
    set result [format "%f" $Delta_H2]

    return $result
}
#init move, we will move table_vert then table_pitch
#not directly real motor, to avoid exceeding software limit
proc MTBS_InitMove { delta_V1 delta_V2 delta_H1 delta_H2 } {

    if {abs($delta_V1) < 2 && abs($delta_V2) < 2} {
        return 0
    }
    
    log_note "init move: $delta_V1 $delta_V2 $delta_H1 $delta_H2"

    set V1_now $::gDevice(table_vert_1,scaled)
    set V2_now $::gDevice(table_vert_2,scaled)
    set H1_now $::gDevice(table_horz_1,scaled)
    set H2_now $::gDevice(table_horz_2,scaled)

    set desired_V1 [expr $V1_now + $delta_V1]
    set desired_V2 [expr $V2_now + $delta_V2]
    set desired_H1 [expr $H1_now + $delta_H1]
    set desired_H2 [expr $H2_now + $delta_H2]

    set desired_vert [table_vert_calculate $desired_V1 $desired_V2 $::gDevice(table_v1_z,scaled) $::gDevice(table_v2_z,scaled) $::gDevice(table_pivot_z,scaled)]
    set desired_pitch [table_pitch_calculate $desired_V1 $desired_V2 $::gDevice(table_v1_z,scaled) $::gDevice(table_v2_z,scaled)]


    #move
    log_note "moving table_vert"
    move table_vert to $desired_vert
    wait_for_devices table_vert

    log_note "moving table_pitch"
    move table_pitch to $desired_pitch
    wait_for_devices table_pitch

    move table_horz_1 to $desired_H1
    move table_horz_2 to $desired_H2
    wait_for_devices table_horz_1 table_horz_2

    return 1
}

proc MTBS_FineTune { delta_V1 delta_V2 delta_H1 delta_H2 } {
    #move all 4 motors
    #threshold 20micron
    set delta_Threshold 0.02

    set motorList {}
    if {abs($delta_V1) > $delta_Threshold } {
        lappend motorList table_vert_1 $delta_V1
    }
    if {abs($delta_V2) > $delta_Threshold} {
        lappend motorList table_vert_2 $delta_V2
    }
    if {abs($delta_H1) > $delta_Threshold} {
        lappend motorList table_horz_1 $delta_H1
    }
    if {abs($delta_H2) > $delta_Threshold} {
        lappend motorList table_horz_2 $delta_H2
    }
    
    set ll [llength $motorList]
    if {$ll <= 0} {
        #no need to move
        return 0
    }
    array set motorArray $motorList
    foreach device [array names motorArray] {
        move $device by $motorArray($device)
        log_note "in fine tune moving $device by $motorArray($device)"
    }
    eval wait_for_devices [array names motorArray]
    return 1
}
proc MTBS_FineTuneH2Only { delta_H2 } {
    set delta_Threshold 0.02

    if {abs($delta_H2) > $delta_Threshold} {
        log_note "fine tune H2 only"
        move table_horz_2 by $delta_H2
        wait_for_devices table_horz_2
    }
}
proc MTBS_CheckSensorReading { V1 V2 H1 H2 } {
    set vList [list $V1 $V2 $H1 $H2]
    set nList [list vert1 vert2 horz1 horz2]
    for {set i 0} {$i < 4} {incr i} {
        set value [lindex $vList $i]
        if {$value < -4.0 || $value > 4.0} {
            set name [lindex $nList $i]
            log_error laser sensor $name out of range
            return -code error "laser sensor $name out of range"
        }
    }
}
