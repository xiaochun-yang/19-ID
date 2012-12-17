### look at rp_gonio_phi.tcl for document
proc reposition_z_initialize { } {
    set_children sample_z
    set_triggers reposition_origin
}
proc reposition_z_move { new_z } {
    #### change here, MUST also change repositionMove
    set origin [getRepositionOrigin sample_z]
    move sample_z to [expr $new_z + $origin]
    wait_for_devices sample_z
}
proc reposition_z_set { new_z } {
    variable sample_z
    set origin [expr $sample_z - $new_z]

    setRepositionOrigin sample_z $origin
}
proc reposition_z_update { } {
    variable sample_z
    return [reposition_z_calculate $sample_z]
}
proc reposition_z_calculate { z } {
    set origin [getRepositionOrigin sample_z]
    return [expr $z - $origin]
}
proc reposition_z_trigger { triggerDevice } {
    update_motor_position reposition_z [reposition_z_update] 1
}
