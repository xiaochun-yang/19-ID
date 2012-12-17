proc beam_size_sample_x_initialize { } {
	set_children beam_size_x
}
proc beam_size_sample_x_move { nx } {
    set slit_x [beam_size_sample_x_calculate_slit_x $nx]

    move beam_size_x to $slit_x
    wait_for_devices beam_size_x

    global gDevice
    set gDevice(beam_size_sample_x,configInProgrss) 1
    set gDevice(beam_size_sample_x,scaled) $nx
    set gDevice(beam_size_sample_x,configInProgrss) 0
}
proc beam_size_sample_x_set { nx } {
    log_error please directly set the beam_size_sample_x
    return -code error not_supported
}
proc beam_size_sample_x_update { } {
    global gDevice
    #log_warning "x update status=$gDevice(beam_size_sample_x,status)"

    if {$gDevice(beam_size_sample_x,status) == "moving"} {
        variable beam_size_sample_x
        return $beam_size_sample_x
    }

    variable beam_size_x

    return [beam_size_sample_x_calculate $beam_size_x]
}
proc beam_size_sample_x_calculate { xx } {
    if { $xx <= [lindex [getGoodLimits beam_size_x] 1] } {

	set beam_size_sample_x [expr -13.6309 * $xx * $xx * $xx * $xx + 16.6665 * $xx * $xx * $xx -9.3591 * $xx*$xx + 2.70175 *$xx -0.00642334]

	return $beam_size_sample_x
    } else {
	return [lindex [getGoodLimits beam_size_sample_x] 1]
    }
}
proc beam_size_sample_x_calculate_slit_x { xx } {

    if { $xx > 0 && $xx <= [lindex [getGoodLimits beam_size_sample_x] 1]} {
	set beam_size_sample_x_slit [expr 13.3537 * $xx*$xx*$xx - 3.8311 * $xx*$xx + 0.847541 *$xx  -0.0120408]
	 return $beam_size_sample_x_slit
     } else {
	 return [lindex [getGoodLimits beam_size_x] 1]
     }
}
proc beam_size_sample_x_childrenLimitsOK { xx {quiet 0}} {
    set slit_x [beam_size_sample_x_calculate_slit_x $xx]

    if {$quiet} {
        return [limits_ok_quiet beam_size_x $slit_x]
    } else {
        return [limits_ok beam_size_x $slit_x]
    }
}
