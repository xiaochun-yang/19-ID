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
    variable beam_size_x

    return [beam_size_sample_x_calculate $beam_size_x]
}
proc beam_size_sample_x_calculate { xx } {
    variable beam_size_sample_x


    return $beam_size_sample_x
    ### only do the reverse calculation if it can get exact the same value.
    ### otherwise it cause round error like our attenuation.
    ### We have not put beamsize into run definition yet.
    ############# NOT USED below this


    if { $xx <= [lindex [getGoodLimits beam_size_x] 1] } {

	set beam_size_sample_x [expr -108.81 * $xx * $xx * $xx * $xx + 96.8009 * $xx * $xx * $xx -26.9469 * $xx*$xx + 3.09233 *$xx -0.0064167]

	return $beam_size_sample_x
    } else {
	return [lindex [getGoodLimits beam_size_sample_x] 1]
    }
}
proc beam_size_sample_x_calculate_slit_x { xx } {

    if { $xx > 0 && $xx <= [lindex [getGoodLimits beam_size_sample_x] 1]} {
	set beam_size_sample_x_slit [expr 570.177 * $xx*$xx*$xx -122.298 * $xx*$xx + 9.09233 *$xx -0.197205]
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
