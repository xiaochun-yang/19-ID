### look at reposition_phi.tcl for document
proc reposition_y_initialize { } {
    set_children sample_x sample_y
    ### gonio_phi will NOT affect reposition_y

    set_triggers reposition_origin
    set_siblings reposition_x
}
proc reposition_y_move { new_y } {
    global gDevice

    #### change here, MUST also change repositionMove
    set new_sample_x \
    [reposition_calculate_sample_x $gDevice(reposition_x,target) $new_y]
    set new_sample_y \
    [reposition_calculate_sample_y $gDevice(reposition_x,target) $new_y]

    set xOrigin [getRepositionOrigin sample_x]
    set yOrigin [getRepositionOrigin sample_y]
    set newSx [expr $new_sample_x + $xOrigin]
    set newSy [expr $new_sample_y + $yOrigin]

    if {![limits_ok sample_x $newSx] || \
    ![limits_ok sample_y $newSy]} {
        return -code error "will exceed children motor limits"
    }

    move sample_x to $newSx
    move sample_y to $newSy
    wait_for_devices sample_x sample_y
}
proc reposition_y_set { new_y } {
    global gDevice
    variable sample_x
    variable sample_y

    set new_sample_x \
    [reposition_calculate_sample_x $gDevice(reposition_x,target) $new_y]
    set new_sample_y \
    [reposition_calculate_sample_y $gDevice(reposition_x,target) $new_y]

    set xOrigin [expr $sample_x - $new_sample_x]
    set yOrigin [expr $sample_y - $new_sample_y]

    setRepositionOrigin sample_x $xOrigin
    setRepositionOrigin sample_y $yOrigin
}
proc reposition_y_update { } {
    variable sample_x
    variable sample_y

    return [reposition_y_calculate $sample_x $sample_y]
}
proc reposition_y_calculate { x y } {
    variable sample_x
    variable sample_y

    set angle   [getRepositionAngle]
    set xOrigin [getRepositionOrigin sample_x]
    set yOrigin [getRepositionOrigin sample_y]

    set x [expr $sample_x - $xOrigin]
    set y [expr $sample_y - $yOrigin]

    set result [expr  - $x * sin($angle) + $y * cos($angle)]
    return $result
}
proc reposition_y_trigger { triggerDevice } {
    update_motor_position reposition_y [reposition_y_update] 1
}
