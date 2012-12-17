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
    global gDevice
    #log_warning "x update status=$gDevice(beam_size_sample_x,status)"

    if {$gDevice(beam_size_sample_y,status) == "moving"} {
        variable beam_size_sample_y
        return $beam_size_sample_y
    }

    variable beam_size_y

    return [beam_size_sample_y_calculate $beam_size_y]
}
proc beam_size_sample_y_calculate { yy } {
    if { $yy <= [lindex [getGoodLimits beam_size_y] 1] } {

	set beam_size_sample_y [expr -116.257 * $yy * $yy * $yy * $yy + 51.5619 * $yy * $yy * $yy -7.14103 * $yy*$yy + 0.985905 *$yy -0.000331521]

	return $beam_size_sample_y
    } else {
	return [lindex [getGoodLimits beam_size_sample_y] 1]
    }
}
proc beam_size_sample_y_calculate_slit_y { yy } {
        if { $yy > 0 && $yy <= [lindex [getGoodLimits beam_size_sample_y] 1]} {
	 set beam_size_sample_y_slit [expr 69.9541* $yy*$yy*$yy -16.1819* $yy*$yy +2.59914*$yy -0.0238561]	 
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
