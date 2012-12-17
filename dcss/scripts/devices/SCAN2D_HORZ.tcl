proc PREFIX_horz_initialize { } {
    set_children sample_z

    set_triggers PREFIXSetup
}
proc PREFIX_horz_move { newH } {
    variable cfgSampleMoveSerial
    variable PREFIXSetup

    if {[llength $PREFIXSetup] < 6} {
        log_error "no PREFIX setup yet"
        return
    }

    set currentH [PREFIX_horz_update]
    if {$currentH == -999} {
        log_error "no PREFIX setup yet"
        return
    }
    foreach {orig_x orig_y orig_z orig_angle cv ch} $PREFIXSetup break

    set dh [expr ($newH - $currentH) * $ch]
    set dz $dh

    move sample_z by $dz
    wait_for_devices sample_z
}

proc PREFIX_horz_set { newH } {
    return -code error "PREFIX_horz_not_support_set"
}

proc PREFIX_horz_trigger { triggerDevice } {
    update_motor_position PREFIX_horz [PREFIX_horz_update] 1
}

proc PREFIX_horz_update { } {
    variable sample_z

    return [PREFIX_horz_calculate $sample_z]
}
proc PREFIX_horz_calculate { z } {
    variable PREFIXSetup

    if {[llength $PREFIXSetup] < 6} {
        return -999
    }

    foreach {orig_x orig_y orig_z orig_angle cv ch} $PREFIXSetup break
    set dz [expr $z - $orig_z]
    set proj_z $dz
    set proj_h [expr $proj_z / double($ch)]
    return $proj_h
}
