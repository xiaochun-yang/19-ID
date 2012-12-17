proc PREFIX_vert_initialize { } {
    set_children sample_x sample_y

    set_triggers PREFIXSetup
}
proc PREFIX_vert_move { newV } {
    variable cfgSampleMoveSerial
    variable PREFIXSetup

    if {[llength $PREFIXSetup] < 6} {
        log_error "no PREFIX setup yet"
        return
    }

    set currentV [PREFIX_vert_update]
    if {$currentV == -999} {
        log_error "no PREFIX setup yet"
        return
    }
    foreach {orig_x orig_y orig_z orig_angle cv ch} $PREFIXSetup break

    set dv [expr ($newV - $currentV) * $cv]
    set da [expr $orig_angle * 3.1415926 / 180.0]

    set dx [expr $dv * cos($da)]
    set dy [expr $dv * sin($da)]

    if {$cfgSampleMoveSerial} {
        move sample_x by $dx
        wait_for_devices sample_x
        move sample_y by $dy
        wait_for_devices sample_y
    } else {
        move sample_x by $dx
        move sample_y by $dy
        wait_for_devices sample_x sample_y
    }
}

proc PREFIX_vert_set { newV } {
    return -code error "PREFIX_vert_not_support_set"
}

proc PREFIX_vert_trigger { triggerDevice } {
    update_motor_position PREFIX_vert [PREFIX_vert_update] 1
}

proc PREFIX_vert_update { } {
    variable sample_x
    variable sample_y

    return [PREFIX_vert_calculate $sample_x $sample_y]
}
proc PREFIX_vert_calculate { x y } {
    variable PREFIXSetup

    if {[llength $PREFIXSetup] < 6} {
        return -999
    }

    foreach {orig_x orig_y orig_z orig_angle cv ch} $PREFIXSetup break
    set dx [expr $x - $orig_x]
    set dy [expr $y - $orig_y]
    set da [expr $orig_angle * 3.1415926 / 180.0]

    set proj_x [expr $dx * cos($da) + $dy * sin($da)]
    set proj_v [expr $proj_x / double($cv)]

    return $proj_v
}
