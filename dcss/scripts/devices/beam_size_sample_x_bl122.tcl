# beam_size_sample_x.tcl

proc beam_size_sample_x_initialize {} {
	set_children focusing_mirror_1_bend_1 focusing_mirror_1_bend_2

    namespace eval ::beam_size_sample {
        set offsetMotorList [list \
            focusing_mirror_1_bend_1 \
            focusing_mirror_1_bend_2 \
            focusing_mirror_2_bend_1 \
            focusing_mirror_2_bend_2 \
        ]
    }
}

proc beam_size_sample_x_move { new_x } {
    variable beam_size_sample_x
    variable focusing_mirror_1_bend_1
    variable focusing_mirror_1_bend_2

    if {$new_x < 0} {
        return -code error "new beam size x must >= 0.0"
    }

    set new_b  [beam_size_sample_x_calculate_fm1bend $new_x]
    set offset1 [beam_size_sample_get_offset focusing_mirror_1_bend_1]
    set offset2 [beam_size_sample_get_offset focusing_mirror_1_bend_2]

    set new_b1 [expr $new_b + $offset1]
    set new_b2 [expr $new_b + $offset2]

    log_warning DEBUG new_b=$new_b offset1=$offset1 offset2=$offset2


    if {![limits_ok focusing_mirror_1_bend_1 $new_b1] || \
    ![limits_ok focusing_mirror_1_bend_2 $new_b2]} {
        return -code error "will exceed children motor limits"
    }

    set diff1 [expr $new_b1 - $focusing_mirror_1_bend_1]
    set diff2 [expr $new_b2 - $focusing_mirror_1_bend_2]

    set step1 0.001
    set step2 0.001
    if {[isDeviceType real_motor focusing_mirror_1_bend_1]} {
        set step1 [expr 1.0 / [getScaleFactorValue focusing_mirror_1_bend_1]]
    }
    if {[isDeviceType real_motor focusing_mirror_1_bend_2]} {
        set step2 [expr 1.0 / [getScaleFactorValue focusing_mirror_1_bend_2]]
    }

    set needHoldMirror 0
    if {abs($diff1) > $step1 || abs($diff2) > $step2} {
        set needHoldMirror 1
        #log_warning need hold mirror for beam_size_sample_x
        #log_warning diff1=$diff1 diff2=$diff2
    }

    if {$needHoldMirror && ![energyGetEnabled hold_mirror]} {
        set needHoldMirror 0
        log_warning energy config disabled holding mirror
    }

    set DEBUG 0
    if {$DEBUG} {
        log_warning skip move focusing_mirror_1_bend_1 to $new_b1
        log_warning skip move focusing_mirror_1_bend_2 to $new_b2
    } else {
        if {$needHoldMirror} {
            generic_hold_mirror beam_size_sample_x
        }
        if {[catch {
            move focusing_mirror_1_bend_1 to $new_b1
            move focusing_mirror_1_bend_2 to $new_b2
            wait_for_devices focusing_mirror_1_bend_1 focusing_mirror_1_bend_2
        } errMsg]} {
            if {$needHoldMirror} {
                generic_release_mirror beam_size_sample_x
            }
            return -code error $errMsg
        }
        if {$needHoldMirror} {
            generic_release_mirror beam_size_sample_x
        }
    }

    global gDevice
    set gDevice(beam_size_sample_x,configInProgrss) 1
    set gDevice(beam_size_sample_x,scaled) $new_x
    set gDevice(beam_size_sample_x,configInProgrss) 0
}

proc beam_size_sample_x_set { new_x } {
    variable beam_size_sample_x
    variable focusing_mirror_1_bend_1
    variable focusing_mirror_1_bend_2

    set new_b  [beam_size_sample_x_calculate_fm1bend $new_x]

    set offset1 [expr $focusing_mirror_1_bend_1 - $new_b]
    set offset2 [expr $focusing_mirror_1_bend_2 - $new_b]

    #log_warning DEBUG new_b=$new_b offset1=$offset1 offset2=$offset2
    set DEBUG 0
    if {$DEBUG} {
        set old1 [beam_size_sample_get_offset focusing_mirror_1_bend_1]
        set old2 [beam_size_sample_get_offset focusing_mirror_1_bend_2]
        log_warning SKIP setting offset for focusing_mirror_1_bend_1 to \
        $offset1 from $old1
        log_warning SKIP setting offset for focusing_mirror_1_bend_2 to \
        $offset2 from $old2
    } else {
        beam_size_sample_set_offset focusing_mirror_1_bend_1 $offset1
        beam_size_sample_set_offset focusing_mirror_1_bend_2 $offset2
    }
    set beam_size_sample_x $new_x
}

proc beam_size_sample_x_update {} {
    variable focusing_mirror_1_bend_1
    variable focusing_mirror_1_bend_2

	# calculate from real motor positions and motor parameters
	return [beam_size_sample_x_calculate \
    $focusing_mirror_1_bend_1 \
    $focusing_mirror_1_bend_2]
}


proc beam_size_sample_x_calculate { b1 b2 } {
    variable ::beam_size_sample::xPos
    variable beam_size_sample_x

    set xPos $beam_size_sample_x
    return $beam_size_sample_x
}

##### /11/20/11 and 11/23/2011 Graeme's new formula
#x = beam_size_sample_y (mm)
#
#y = focusing_mirror_2_bend (bend_1 and bend_2) (mm)
#
#y = a + bx + cx^2 + dx^3 + fx^4
#
#a =  7.9751512804152469E+00
#b = -3.7855883001410362E+01
#c =  6.4507500150765350E+02
#d = -6.1035990885022511E+03
#f =  2.0985777480057910E+04
#
#******************************
#Horizontal
#x = beam_size_sample_x (mm)
#
#y = focusing_mirror_1_bend (bend_1 and bend_2) (mm)
#
#y = a + bx + cx^2 + dx^3 + fx^4
#
#a =  1.6112968312650175E+01
#b = -6.4142606185192520E+01
#c =  4.3928428472667503E+02
#d = -1.6552571491523292E+03
#f =  2.4659940613000881E+03






proc beam_size_sample_x_calculate_fm1bend { x } {
    
    #set a 
    set b -6.4142606185192520E+01
    set c  4.3928428472667503E+02
    set d -1.6552571491523292E+03
    set f  2.4659940613000881E+03

    return [expr \
    $b * $x + \
    $c * $x * $x + \
    $d * $x * $x * $x + \
    $f * $x * $x * $x * $x \
    ]
}
proc beam_size_sample_y_calculate_fm2bend { y } {
    #set a 7.9751512804152469E+00
    set b -3.7855883001410362E+01
    set c  6.4507500150765350E+02
    set d -6.1035990885022511E+03
    set f  2.0985777480057910E+04

    return [expr \
    $b * $y + \
    $c * $y * $y + \
    $d * $y * $y * $y + \
    $f * $y * $y * $y * $y \
    ]
}

proc beam_size_sample_get_offset_index { motor } {
    variable ::beam_size_sample::offsetMotorList

    set result [lsearch -exact $offsetMotorList $motor]

    if {$result < 0} {
        log_error $motor is not in the offset list: $offsetMotorList
        return -code error \
        "$motor is not in the offset list: {$offsetMotorList}"
    }

    return $result
}

proc beam_size_sample_get_offset { motor } {
    variable beam_size_sample_offset
    variable ::beam_size_sample::offsetMotorList

    if {[llength $beam_size_sample_offset] != [llength $offsetMotorList]} {
        log_error beam_size_sample_offset not match with motor list
        return -code error "list_not_match"
    }

    set index [beam_size_sample_get_offset_index $motor]

    return [lindex $beam_size_sample_offset $index]
}
proc beam_size_sample_set_offset { motor offset } {
    variable beam_size_sample_offset
    variable ::beam_size_sample::offsetMotorList

    if {[llength $beam_size_sample_offset] != [llength $offsetMotorList]} {
        log_error beam_size_sample_offset not match with motor list
        return -code error "list_not_match"
    }

    set index [beam_size_sample_get_offset_index $motor]

    set old [lindex $beam_size_sample_offset $index]
    set beam_size_sample_offset [lreplace $beam_size_sample_offset \
    $index $index $offset]

    log_warning beam_size_sample_offset for $motor changed from $old to $offset
}
