proc correctTableSlide_initialize { } {
}
proc correctTableSlide_start { } {
    global gDevice
    variable detector_z_accumulate
    variable slide_correct_data
    variable slide_correct_constant
    variable table_slide

    if {![isDevice table_slide]} {
        ##DEBUG
        log_warning table_slide not exists
        return
    }

    if {$gDevice(table_slide,status) != "inactive"} {
        ##DEBUG
        log_warning table_slide moving
        return
    }

    ### it may be string or motor
    if {![isDevice detector_z_accumulate]} {
        ##DEBUG
        log_warning detector_z_accumulate not exists
        return
    }

    if {![isString slide_correct_data]} {
        ##DEBUG
        log_warning slide_correct_data not exists
        return
    }
    if {![isString slide_correct_constant]} {
        ##DEBUG
        log_warning slide_correct_constant not exists
        return
    }

    set lastTime [lindex $slide_correct_data 0]

    set distance_threshold [lindex $slide_correct_constant 0]
    set time_threshold [lindex $slide_correct_constant 1]
    set correct_distance [lindex $slide_correct_constant 2]

    if {![string is double -strict $lastTime] || \
    ![string is double -strict $distance_threshold] || \
    ![string is double -strict $time_threshold] || \
    ![string is double -strict $correct_distance]} {
        ##DEBUG
        log_warning not all of them are double
        return
    }

    if {$correct_distance == 0} {
        ##DEBUG
        log_warning correct_distance == 0
        return
    }

    set need_correct 0
    if {$distance_threshold > 0 && \
    $detector_z_accumulate >= $distance_threshold} {
        set need_correct 1
    }
    set now [clock seconds]
    if {$time_threshold > 0 && \
    $now >= ($lastTime + $time_threshold)} {
        set need_correct 1
    }

    if {!$need_correct} {
        #DEBUG
        log_warning no need to correct
        return
    }
    
    log_note correct table_slide

    set old_position $table_slide

    move table_slide by $correct_distance
    wait_for_devices table_slide

    move table_slide to $old_position
    wait_for_devices table_slide

    set now [clock seconds]
    set detector_z_accumulate 0
    set slide_correct_data [list $now [time_stamp]]
}
