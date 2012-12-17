proc beam_size_sample_y_initialize { } {
	set_children beam_size_y
}
proc beam_size_sample_y_move { ny } {
    set slit_y [beam_size_sample_y_calculate_slit_y $ny]

    move beam_size_y to $slit_y
    wait_for_devices beam_size_y

    global gDevice
    set gDevice(beam_size_sample_y,configInProgrss) 1
    set gDevice(beam_size_sample_y,scaled) $ny
    set gDevice(beam_size_sample_y,configInProgrss) 0
}
proc beam_size_sample_y_set { ny } {
    log_error please directly set the beam_size_sample_y
    return -code error not_supported
}
proc beam_size_sample_y_update { } {
    variable beam_size_y

    return [beam_size_sample_y_calculate $beam_size_y]
}
proc beam_size_sample_y_calculate { yy } {
    variable beam_size_sample_y

    return $beam_size_sample_y

    ########################## NOT USED below here
    if { $yy <= [lindex [getGoodLimits beam_size_y] 1] } {

	set beam_size_sample_y [expr -300.208 * $yy * $yy * $yy * $yy + 170.633 * $yy * $yy * $yy -34.9034 * $yy*$yy + 3.1609 *$yy -0.025925]

	return $beam_size_sample_y
    } else {
	return [lindex [getGoodLimits beam_size_sample_y] 1]
    }
}
proc beam_size_sample_y_calculate_slit_y { yy } {
        if { $yy > 0 && $yy <= [lindex [getGoodLimits beam_size_sample_y] 1]} {
	 set beam_size_sample_y_slit [expr 1297.58* $yy*$yy*$yy -175.805* $yy*$yy +8.16428*$yy -0.0957385]	 
	 return $beam_size_sample_y_slit
     } else {
	 return [lindex [getGoodLimits beam_size_y] 1]
     }
}

proc beam_size_sample_y_childrenLimitsOK { yy {quiet 0}} {
    set slit_y [beam_size_sample_y_calculate_slit_y $yy]

    if {$quiet} {
        return [limits_ok_quiet beam_size_y $slit_y]
    } else {
        return [limits_ok beam_size_y $slit_y]
    }
}
