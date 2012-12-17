### look at reposition_phi.tcl for document
proc sampleScaleFactor_initialize { } {
    set_children camera_zoom

    set_triggers sample_camera_constant
}
proc sampleScaleFactor_move { new_scale } {
    set new_zoom [sampleScaleFactor_calculate_zoom $new_scale]

    move camera_zoom to $new_zoom
    wait_for_devices camera_zoom
}
proc sampleScaleFactor_set { new_x } {
    log_error better set camera_zoom directly.
    return -code error set_not_suppported
}
proc sampleScaleFactor_update { } {
    variable camera_zoom

    return [sampleScaleFactor_calculate $camera_zoom]
}
proc sampleScaleFactor_trigger { triggerDevice } {
    update_motor_position sampleScaleFactor [sampleScaleFactor_update] 1
}
