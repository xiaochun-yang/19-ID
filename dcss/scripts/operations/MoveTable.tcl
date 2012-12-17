proc MoveTable_initialize {} {
}


proc MoveTable_start { } {
    variable ::nScripts::dsensor_to_robot_config
    variable ::nScripts::table_sensor_position

    #move table slide if exists
    set ll [length $table_sensor_position]
    if {$ll >= 9} {
        set slide_position [lindex $table_sensor_position 8]
        move table_slide to $slide_position
        wait_for_devices table_slide
    }

    #use displacement sensor information if sensor is ready
    set Sensor_Ready [lindex $dsensor_to_robot_config 19]
    if {$Sensor_Ready == ""} {
        set Sensor_Ready 0
    }
    if {$Sensor_Ready} {
        if {[llength $table_sensor_position] >= 4} {
            eval MoveTableBySensor_start [lrange $table_sensor_position 0 3]
        } else {
            return -code error "no valid sensor data saved"
        }
    } else {
        if {[llength $table_sensor_position] >= 8} {
            eval MT_MoveTableByMotor [lrange $table_sensor_position 4 7]
        } else {
            return -code error "displacement sensor not ready and no motor position saved"
        }
    }
}

#only advantage is it will try to avoid software limits.
proc MT_MoveTableByMotor { V1 V2 H1 H2 } {
    set desired_vert [table_vert_calculate $V1 $V2 $::gDevice(table_v1_z,scaled) $::gDevice(table_v2_z,scaled) $::gDevice(table_pivot_z,scaled)]
    set desired_pitch [table_pitch_calculate $V1 $V2 $::gDevice(table_v1_z,scaled) $::gDevice(table_v2_z,scaled)]

    #move
    log_note "moving table_vert"
    move table_vert to $desired_vert
    wait_for_devices table_vert

    log_note "moving table_pitch"
    move table_pitch to $desired_pitch
    wait_for_devices table_pitch

    move table_horz_1 to $H1
    move table_horz_2 to $H2
    wait_for_devices table_horz_1 table_horz_2
    return 1
}
