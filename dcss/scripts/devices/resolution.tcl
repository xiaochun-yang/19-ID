proc resolution_initialize {} {
    set_children detector_z
    set_triggers energy detector_horz detector_vert detectorMode \
    detector_center_horz_offset detector_center_vert_offset
}

proc resolution_move { new_resolution } {
    set new_dz [resolution_distance_calculate $new_resolution]

    if {[isMotor detector_z_corr]} {
        set motor detector_z_corr
    } else {
        set motor detector_z
    }
    move $motor to $new_dz
    wait_for_devices $motor
}


proc resolution_set { new_resolution } {
    variable detector_z

    set new_dz [resolution_distance_calculate $new_resolution]

    if {[isMotor detector_z_corr]} {
        set motor detector_z_corr
    } else {
        set motor detector_z
    }
    #set $motor $new_dz
    log_warning skipped set $motor to $new_dz
    log_warning It is better to set $motor directly.
}

proc resolution_update {} {
    variable detector_z
	return [resolution_calculate $detector_z]
}

proc resolution_trigger { triggerDevice } {
	update_motor_position resolution [resolution_update] 1
}

proc resolution_calculate { dz } {
    variable energy
    variable detectorMode

    foreach {offsetH offsetV} [resolution_get_detector_offsets] break

    return [::gDetector calculateResolution \
    $dz $energy $detectorMode $offsetH $offsetV \
    ]
}

proc resolution_distance_calculate { rn } {
    variable energy
    variable detectorMode

    foreach {offsetH offsetV} [resolution_get_detector_offsets] break

    return [::gDetector calculateDistance \
    $rn $energy $detectorMode $offsetH $offsetV \
    ]
}
proc resolution_get_detector_offsets { } {
    global gMotorHorz
    global gMotorVert

    variable $gMotorHorz
    variable $gMotorVert

    set offsetH [set $gMotorHorz]
    set offsetV [set $gMotorVert]

    return [list $offsetH $offsetV]
}
