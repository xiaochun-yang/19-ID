# beam_size_sample_y.tcl

proc beam_size_sample_y_initialize {} {
	set_children focusing_mirror_2_bend_1 focusing_mirror_2_bend_2
}


proc beam_size_sample_y_move { new_y } {
    variable beam_size_sample_y
    variable focusing_mirror_2_bend_1
    variable focusing_mirror_2_bend_2

    if {$new_y < 0} {
        return -code error "new beam size y must >= 0.0"
    }

    set new_b  [beam_size_sample_y_calculate_fm2bend $new_y]
    set offset1 [beam_size_sample_get_offset focusing_mirror_2_bend_1]
    set offset2 [beam_size_sample_get_offset focusing_mirror_2_bend_2]

    set new_b1 [expr $new_b + $offset1]
    set new_b2 [expr $new_b + $offset2]

    if {![limits_ok focusing_mirror_2_bend_1 $new_b1] || \
    ![limits_ok focusing_mirror_2_bend_2 $new_b2]} {
        return -code error "will eyceed children motor limits"
    }

    set diff1 [expr $new_b1 - $focusing_mirror_2_bend_1]
    set diff2 [expr $new_b2 - $focusing_mirror_2_bend_2]
    set step1 0.001
    set step2 0.001
    if {[isDeviceType real_motor focusing_mirror_2_bend_1]} {
        set step1 [expr 1.0 / [getScaleFactorValue focusing_mirror_2_bend_1]]
    }
    if {[isDeviceType real_motor focusing_mirror_2_bend_2]} {
        set step2 [expr 1.0 / [getScaleFactorValue focusing_mirror_2_bend_2]]
    }

    set needHoldMirror 0
    if {abs($diff1) > $step1 || abs($diff2) > $step2} {
        set needHoldMirror 1
        #log_warning need hold mirror for beam_size_sample_y
        #log_warning diff1=$diff1 diff2=$diff2
    }

    if {$needHoldMirror && ![energyGetEnabled hold_mirror]} {
        set needHoldMirror 0
        log_warning energy config disabled holding mirror
    }

    set DEBUG 0
    if {$DEBUG} {
        log_warning skip move focusing_mirror_2_bend_1 to $new_b1
        log_warning skip move focusing_mirror_2_bend_2 to $new_b2
    } else {
        #log_warning move focusing_mirror_2_bend_1 to $new_b1
        #log_warning move focusing_mirror_2_bend_2 to $new_b2
        if {$needHoldMirror} {
            generic_hold_mirror beam_size_sample_y
        }
        if {[catch {
            move focusing_mirror_2_bend_1 to $new_b1
            move focusing_mirror_2_bend_2 to $new_b2
            wait_for_devices focusing_mirror_2_bend_1 focusing_mirror_2_bend_2
        } errMsg]} {
            if {$needHoldMirror} {
                generic_release_mirror beam_size_sample_y
            }
            return -code error $errMsg
        }
        if {$needHoldMirror} {
            generic_release_mirror beam_size_sample_y
        }
    }

    global gDevice
    set gDevice(beam_size_sample_y,configInProgrss) 1
    set gDevice(beam_size_sample_y,scaled) $new_y
    set gDevice(beam_size_sample_y,configInProgrss) 0
}

### calculations are in beam_size_sample_x, 

proc beam_size_sample_y_set { new_y } {
    variable beam_size_sample_y
    variable focusing_mirror_2_bend_1
    variable focusing_mirror_2_bend_2

    set new_b  [beam_size_sample_y_calculate_fm2bend $new_y]

    set offset1 [expr $focusing_mirror_2_bend_1 - $new_b]
    set offset2 [expr $focusing_mirror_2_bend_2 - $new_b]

    set DEBUG 0
    if {$DEBUG} {
        set old1 [beam_size_sample_get_offset focusing_mirror_2_bend_1]
        set old2 [beam_size_sample_get_offset focusing_mirror_2_bend_2]
        log_warning SKIP setting offset for focusing_mirror_2_bend_1 to \
        $offset1 from $old1
        log_warning SKIP setting offset for focusing_mirror_2_bend_2 to \
        $offset2 from $old2
    } else {
        beam_size_sample_set_offset focusing_mirror_2_bend_1 $offset1
        beam_size_sample_set_offset focusing_mirror_2_bend_2 $offset2
    }

    set beam_size_sample_y $new_y
}


proc beam_size_sample_y_update {} {
    variable focusing_mirror_2_bend_1
    variable focusing_mirror_2_bend_2

	# calculate from real motor positions and motor parameters
	return [beam_size_sample_y_calculate \
    $focusing_mirror_2_bend_1 \
    $focusing_mirror_2_bend_2]
}


proc beam_size_sample_y_calculate { b1 b2 } {
    variable beam_size_sample_y

    return $beam_size_sample_y
}

