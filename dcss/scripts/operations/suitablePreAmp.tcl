#### wrapper for ion chamber to find suitable preamp setting for
#### energy and attenuation
#### return:
#### field 0:    vertical_preAmp
#### field 1:    horizontal_preAmp
#### field 2:    verital_dial_reading
#### field 3:    horz_dial_reading
###############################################
# Besides the scan file, there are extra 2 files will be generated in the
# format of a look-up-table which dcss can load.
# These 2 files will be in the $DCSS/$MACHINE_TYPE directory
# name pattern: preamp_h_TIMESTAMP.txt and preamp_v_TIMESTAMP.txt
###############################################

proc suitablePreAmp_initialize { } {
    namespace eval ::suitablePreAmp {
        set LUTfileNameV ""
        set LUTfileNameH ""

        set LOGfileNameV suitablePreAmpVert.log
        set LOGfileNameH suitablePreAmpHorz.log
    }
}

proc suitablePreAmp_start { time } {
    suitablePreAmp_getLogFileNames
    # get initial values
    set sens_v 1000
    set sens_h 1000
    foreach {sens_v sens_h} [suitablePreAmp_getInitialValues] break
    suitablePreAmp_setVert $sens_v
    suitablePreAmp_setHorz $sens_h

    ####### close loop to find suitable settings
    return [suitablePreAmp_closeLoop $sens_h $sens_v $time]
}

proc suitablePreAmp_getLogFileNames { } {
    variable scan_motor_status
    variable ::suitablePreAmp::LUTfileNameV
    variable ::suitablePreAmp::LUTfileNameH

    set fullPath [lindex $scan_motor_status 0]

    set file [file tail $fullPath]
    set file [file root $file]

    set LUTfileNameV ${file}_VLUT.txt
    set LUTfileNameH ${file}_HLUT.txt

    puts "set LUT filename v: $LUTfileNameV h: $LUTfileNameH"
}

proc suitablePreAmp_rawLogVert { setting reading } {
    if {[catch {
        variable ::suitablePreAmp::LOGfileNameV
        variable mono_theta
        variable attenuation

        set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]

        set line [format "%s %.5f %.2f %.0f %.1f" \
        $timestamp \
        $mono_theta \
        $attenuation \
        $setting \
        $reading \
        ]

        set fh [open $LOGfileNameV a]
        puts $fh $line
        close $fh
    } errMsg]} {
        log_error failed to save vert log: $errMsg
    }
}

proc suitablePreAmp_rawLogHorz { setting reading } {
    if {[catch {
        variable ::suitablePreAmp::LOGfileNameH
        variable mono_theta
        variable attenuation

        set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]

        set line [format "%s %.5f %.2f %.0f %.1f" \
        $timestamp \
        $mono_theta \
        $attenuation \
        $setting \
        $reading \
        ]

        set fh [open $LOGfileNameH a]
        puts $fh $line
        close $fh
    } errMsg]} {
        log_error failed to save horz log: $errMsg
    }
}

proc suitablePreAmp_saveVert { setting reading } {
    if {[catch {
        variable ::suitablePreAmp::LUTfileNameV
        variable mono_theta
        variable attenuation

        puts "suitablePreAmp saving vert to {$LUTfileNameV}"

        set line [format "%.5f %.2f %.0f %.1f" \
        $mono_theta \
        $attenuation \
        $setting \
        $reading \
        ]

        set fh [open $LUTfileNameV a]
        puts $fh $line
        close $fh
        puts "suitablePreAmp saved vert to {LUTfileNameV}"
    } errMsg]} {
        log_error failed to save vert result: $errMsg
    }
}

proc suitablePreAmp_saveHorz { setting reading } {
    if {[catch {
        variable ::suitablePreAmp::LUTfileNameH
        variable mono_theta
        variable attenuation

        puts "suitablePreAmp saving horz to {$LUTfileNameH}"

        set line [format "%.5f %.2f %.0f %.1f" \
        $mono_theta \
        $attenuation \
        $setting \
        $reading \
        ]

        set fh [open $LUTfileNameH a]
        puts $fh $line
        close $fh
        puts "suitablePreAmp saved horz to {LUTfileNameV}"
    } errMsg]} {
        log_error failed to save horz result: $errMsg
    }
}

proc suitablePreAmp_getInitialValues { } {
    variable ::preampLUT::lut_horz
    variable ::preampLUT::lut_vert

    variable mono_theta
    variable attenuation
    
    set sens_v [PAS_interpolateLUT_raw lut_vert $mono_theta $attenuation]
    set sens_h [PAS_interpolateLUT_raw lut_horz $mono_theta $attenuation]

    return [list $sens_v $sens_h]
    #return [list 100000 100000]
}

proc suitablePreAmp_getCurrentSettings { } {
    variable amp_i_mirror_feedback_upper
    variable amp_i_mirror_feedback_spear

    set v_setting [lindex $amp_i_mirror_feedback_upper 1]
    set h_setting [lindex $amp_i_mirror_feedback_spear 1]

    set v_setting [PAS_convertToNumber $v_setting]
    set h_setting [PAS_convertToNumber $h_setting]

    return [list $v_setting $h_setting]
}

proc suitablePreAmp_setVert { sens_v } {
    variable amp_i_mirror_feedback_upper
    variable amp_i_mirror_feedback_lower

    set sens_v_setting [PAS_autoScale $sens_v]
    ### no twick
    set sens_v_setting [lindex $sens_v_setting 0]
    send_operation_update DEBUG: set v to $sens_v_setting

    set amp_i_mirror_feedback_upper "SENS $sens_v_setting"
    set amp_i_mirror_feedback_lower "SENS $sens_v_setting"
    wait_for_strings \
    amp_i_mirror_feedback_upper \
    amp_i_mirror_feedback_lower \
    10000
}
proc suitablePreAmp_setHorz { sens_h } {
    variable amp_i_mirror_feedback_spear
    variable amp_i_mirror_feedback_ssrl

    set sens_h_setting [PAS_autoScale $sens_h]
    ### no twick
    set sens_h_setting [lindex $sens_h_setting 0]
    send_operation_update DEBUG set h to $sens_h_setting


    set amp_i_mirror_feedback_spear "SENS $sens_h_setting"
    set amp_i_mirror_feedback_ssrl "SENS $sens_h_setting"
    wait_for_strings \
    amp_i_mirror_feedback_spear \
    amp_i_mirror_feedback_ssrl 10000
}
proc suitablePreAmp_getReadings { time } {
    set detectors [list \
    i_mirror_feedback_upper \
    i_mirror_feedback_lower \
    i_mirror_feedback_spear \
    i_mirror_feedback_ssrl \
    ]

    eval read_ion_chambers $time $detectors

    eval wait_for_devices $detectors

    foreach {dial_upper dial_lower dial_spear dial_ssrl} \
    [eval get_ion_chamber_counts $detectors] break

    set dial_horz [expr 0.5 * ($dial_spear + $dial_ssrl)]

    set dial_vert [expr 0.5 * ($dial_upper + $dial_lower)]

    send_operation_update DEBUG: dial readings: v: $dial_vert h: $dial_horz

    return [list $dial_vert $dial_horz]
}
proc suitablePreAmp_closeLoop { sens_h sens_v time } {

    puts "suitablePreAmp_closeLoop init: h $sens_h v $sens_v"

    set dir_horz -1
    set dir_vert -1
    set pre_dir_horz 0
    set pre_dir_vert 0

    set MAX_TRY 20

    for {set i 0} {$i < $MAX_TRY} {incr i} {
        foreach {dial_vert dial_horz} [suitablePreAmp_getReadings $time] break
        foreach {cset_vert cset_horz} [suitablePreAmp_getCurrentSettings] break
        suitablePreAmp_rawLogVert $cset_vert $dial_vert
        suitablePreAmp_rawLogHorz $cset_horz $dial_horz

        if {$dir_horz} {
            set dir_horz [PAS_getPreferedSensitivity sens_h $dial_horz]
        }
        if {$dir_horz} {
            log_warning DEBUG new horz: $sens_h
            suitablePreAmp_setHorz $sens_h

            #######to prevent flip-flop
            if {$pre_dir_horz > 0 && $dir_horz < 0} {
                #log_warning non-linear in horz
                set dir_horz 0
            }
            set pre_dir_horz $dir_horz
        }
        if {$dir_vert} {
            set dir_vert [PAS_getPreferedSensitivity sens_v $dial_vert]
        }
        if {$dir_vert} {
            suitablePreAmp_setVert $sens_v

            #######to prevent flip-flop
            if {$pre_dir_vert > 0 && $dir_vert < 0} {
                #log_warning non-linear in vert
                set dir_vert 0
            }
            set pre_dir_vert $dir_vert
        }

        if {!$dir_horz && !$dir_vert} {
            #log_warning DEBUG loopback finished at $i
            break
        }
        #### settle down before next check
        wait_for_time 5000
    }
    if {$dir_horz} {
        log_warning DEBUG horz loopback failed after max retry.
    }
    if {$dir_vert} {
        log_warning DEBUG vert loopback failed after max retry.
    }

    foreach {dial_vert dial_horz} [suitablePreAmp_getReadings $time] break
    foreach {cset_vert cset_horz} [suitablePreAmp_getCurrentSettings] break
    suitablePreAmp_rawLogVert $cset_vert $dial_vert
    suitablePreAmp_rawLogHorz $cset_horz $dial_horz

    suitablePreAmp_saveVert $cset_vert $dial_vert
    suitablePreAmp_saveHorz $cset_horz $dial_horz

    return [list $cset_vert $cset_horz $dial_vert $dial_horz]
}
proc PAS_getNextHighSensitivity { sens_ref } {
    upvar $sens_ref sens
    set digit [string index $sens 0]

    if {$sens <= 1} {
        set sens 1
        return 0
    }

    switch -exact -- $digit {
        5 {
            set sens [expr $sens * 2 / 5]
        }
        default {
            set sens [expr $sens / 2]
        }
    }
    return 1
}
proc PAS_getNextLowSensitivity { sens_ref } {
    upvar $sens_ref sens
    set digit [string index $sens 0]

    if {$sens >= 1000000000} {
        set sens 1000000000
        return 0
    }
    switch -exact -- $digit {
        2 {
            set sens [expr $sens * 5 / 2]
        }
        default {
            set sens [expr $sens * 2]
        }
    }
    return 1
}
proc PAS_getPreferedSensitivity { sens_ref dial_reading } {
    upvar $sens_ref sens
    #### the sensitivity change 2 or 2.5
    #### so the valid range must be bigger than 2.5
    #### limit 1.5-5 is factor of 3.33 > 2.5, should be OK.
    #### so we increase sensitivity if reading is < 1.5
    #### so we decrease sensitivity if reading is > 5
    #### we will not change if reading is between [1.5, 5]

    ###################
    #### to prevent flip-flop,
    #### the upper limit 5.0 is hard limit.
    #### the lower limit 1.5 is soft limit.
    #### means: ##############
    # if reading is 0.5 or even 0.1,
    # but next setting the reading jumps to 6, then
    # we will rollback the setting and accept the 0.5 or 0.1 reading
    # though it is below the lower limit.

    set LOW_LIMIT  1.5
    set HIGH_LIMIT 4.0
    
    if {$dial_reading < $LOW_LIMIT} {
        set i -1
        set new_reading $dial_reading
        set new_sens $sens
        set ratio [expr double($dial_reading) * $sens]
        puts "old_sens=$sens readin=$dial_reading"
        while {$new_reading <= $HIGH_LIMIT} {
            set sens $new_sens
            if {[PAS_getNextHighSensitivity new_sens] == 0} {
                break
            }
            set new_reading [expr $ratio / $new_sens]
            incr i
            puts "i=$i: new_sens=$new_sens new_readin=$new_reading"
        }
        puts "result: $sens new reading [expr $ratio / $sens], i=$i"
        return $i
    }
    if {$dial_reading > $HIGH_LIMIT} {
        set i 1
        set new_reading $dial_reading
        set new_sens $sens
        set ratio [expr double($dial_reading) * $sens]
        while {$new_reading >= $LOW_LIMIT} {
            set sens $new_sens
            if {[PAS_getNextLowSensitivity new_sens] == 0} {
                break
            }
            set new_reading [expr $ratio / $new_sens]
            incr i -1
            puts "i=$i: new_sens=$new_sens new_readin=$new_reading"
        }
        puts "result: $sens new reading [expr $ratio / $sens], i=$i"
        return $i
    }
    ###no need to change
    return 0
}
