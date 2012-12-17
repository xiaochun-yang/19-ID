proc beam_size_sample_x_initialize { } {
	set_children beam_size_x
}
proc beam_size_sample_x_move { nx } {
    set slit_x [beam_size_sample_x_calculate_slit_x $nx]

    move beam_size_x to $slit_x
    wait_for_devices beam_size_x
}
proc beam_size_sample_x_set { nx } {
    variable beam_size_x

    set slit_x [beam_size_sample_x_calculate_slit_x $nx]
    set beam_size_x $slit_x
}
proc beam_size_sample_x_update { } {
    variable beam_size_x

    return [beam_size_sample_x_calculate $beam_size_x]
}
proc beam_size_sample_x_calculate { xx } {
    return $xx
}
proc beam_size_sample_x_calculate_slit_x { xx } {
    return $xx
}
proc beam_size_sample_x_childrenLimitsOK { xx {quiet 0}} {
    set slit_x [beam_size_sample_x_calculate_slit_x $xx]

    if {$quiet} {
        return [limits_ok_quiet beam_size_x $slit_x]
    } else {
        return [limits_ok beam_size_x $slit_x]
    }
}
