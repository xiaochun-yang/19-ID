proc beam_size_sample_y_initialize { } {
	set_children beam_size_y
}
proc beam_size_sample_y_move { ny } {
    set slit_y [beam_size_sample_y_calculate_slit_y $ny]

    move beam_size_y to $slit_y
    wait_for_devices beam_size_y
}
proc beam_size_sample_y_set { ny } {
    variable beam_size_y

    set slit_y [beam_size_sample_y_calculate_slit_y $ny]
    set beam_size_y $slit_y
}
proc beam_size_sample_y_update { } {
    variable beam_size_y

    return [beam_size_sample_y_calculate $beam_size_y]
}
proc beam_size_sample_y_calculate { yy } {
    return $yy
}
proc beam_size_sample_y_calculate_slit_y { yy } {
    return $yy
}
proc beam_size_sample_y_childrenLimitsOK { yy {quiet 0}} {
    set slit_y [beam_size_sample_y_calculate_slit_y $yy]

    if {$quiet} {
        return [limits_ok_quiet beam_size_y $slit_y]
    } else {
        return [limits_ok beam_size_y $slit_y]
    }
}
