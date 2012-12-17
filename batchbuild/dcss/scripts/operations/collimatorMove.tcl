proc collimatorMove_initialize { } {
    variable cfgCollimatorPresetNameToIndexMap
    variable cfgCollimatorNameOut
    variable cfgCollimatorNameNormalBeam
    variable cfgCollimatorNameDefaultMicro

    set nameList [::config getStr collimatorPresetNameList]

    set index 0
    foreach name $nameList {
        set cfgCollimatorPresetNameToIndexMap($name) $index
        incr index
    }

    set cfgCollimatorNameOut [::config getStr collimatorPresetOutName]
    if {$cfgCollimatorNameOut == ""} {
        set cfgCollimatorNameOut Out
        puts "not found collimatorPresetOutName"
    }

    set cfgCollimatorNameNormalBeam [::config getStr collimatorPresetNormalBeamName]
    if {$cfgCollimatorNameNormalBeam == ""} {
        set cfgCollimatorNameNormalBeam "Guard Shield"
        puts "not found collimatorPresetNormalBeamName"
    }

    set cfgCollimatorNameDefaultMicro [::config getStr collimatorPresetDefaultMicroName]
    if {$cfgCollimatorNameDefaultMicro == ""} {
        set cfgCollimatorNameDefaultMicro "Micro-collimator"
        puts "not found collimatorPresetDefaultMicroName"
    }

    namespace eval ::collimatorMove {
        set MOVE_ENCODER 1
        set MATCH_ENCODER 1
    }
    registerEventListener collimator_horz \
    ::nScripts::collimatorMoveMatch

    registerEventListener collimator_vert \
    ::nScripts::collimatorMoveMatch

    registerEventListener collimator_horz_encoder_motor \
    ::nScripts::collimatorMoveMatch

    registerEventListener collimator_vert_encoder_motor \
    ::nScripts::collimatorMoveMatch

    registerEventListener collimator_preset ::nScripts::collimatorMoveMatch
}
proc collimatorMove_start { index args } {
    variable ::collimatorMove::MOVE_ENCODER
    variable ::collimatorMove::MATCH_ENCODER
    variable collimator_preset
    variable cfgCollimatorPresetNameToIndexMap

    if {$index == "USE_ENCODER" && [llength $args] > 1} {
        send_operation_update "previous encoder move=$MOVE_ENCODER match=$MATCH_ENCODER"
        set MOVE_ENCODER [lindex $args 0]
        set MATCH_ENCODER [lindex $args 1]
        send_operation_update "new encoder move=$MOVE_ENCODER match=$MATCH_ENCODER"
        return OK
    }

    if {$index == "SET_ALL_ADJUST" && [llength $args] > 0} {
        set new_adj [lindex $args 0]
        set ajIndex $cfgCollimatorPresetNameToIndexMap(adjust)

        set new_preset ""
        foreach preset $collimator_preset {
            set nn [setStringFieldWithPadding $preset $ajIndex $new_adj]
            lappend new_preset $nn
        }
        set collimator_preset $new_preset
        return OK
    }
    if {$index == "SET_ALL_FLUX" && [llength $args] > 0} {
        set new_flux [lindex $args 0]
        set ftIndex $cfgCollimatorPresetNameToIndexMap(flux_table)

        set new_preset ""
        foreach preset $collimator_preset {
            set nn [setStringFieldWithPadding $preset $ftIndex $new_flux]
            lappend new_preset $nn
        }
        set collimator_preset $new_preset
        return OK
    }


    #### DEBUG
    if {$index == "Out"} {
        return [collimatorMoveOut]
    }
    if {$index == "Normal"} {
        return [collimatorNormalIn]
    }
    if {$index == "micro"} {
        return [collimatorMoveFirstMicron]
    }

    if {![string is integer $index]} {
        log_error bad collimator preset index
        return -code error BAD_INDEX
    }

    set ll [llength $collimator_preset]

    if {$index < 0 || $index >= $ll} {
        log_error collimator index $index out of range
        return -code error "index out of range"
    }

    set preset [lindex $collimator_preset $index]
    
    set lp [llength $preset]
    if {$lp < 3} {
        log_error bad preset: $preset
        log_error should be {name horz vert}
        return -code error "bad preset"
    }

    #foreach {name h v} $preset break
    set nIndex  $cfgCollimatorPresetNameToIndexMap(name)
    set hIndex  $cfgCollimatorPresetNameToIndexMap(horz)
    set vIndex  $cfgCollimatorPresetNameToIndexMap(vert)
    set eHIndex $cfgCollimatorPresetNameToIndexMap(horz_encoder)
    set eVIndex $cfgCollimatorPresetNameToIndexMap(vert_encoder)
    set fhIndex $cfgCollimatorPresetNameToIndexMap(focus_beam_width)
    set fvIndex $cfgCollimatorPresetNameToIndexMap(focus_beam_height)
    set wdIndex $cfgCollimatorPresetNameToIndexMap(width)
    set htIndex $cfgCollimatorPresetNameToIndexMap(height)
    set shIndex $cfgCollimatorPresetNameToIndexMap(display)
    set mIndex  $cfgCollimatorPresetNameToIndexMap(is_micron_beam)
    set name [lindex $preset $nIndex]
    set h    [lindex $preset $hIndex]
    set v    [lindex $preset $vIndex]
    set eh   [lindex $preset $eHIndex]
    set ev   [lindex $preset $eVIndex]
    set fh   [lindex $preset $fhIndex]
    set fv   [lindex $preset $fvIndex]
    set show [lindex $preset $shIndex]
    set micr [lindex $preset $mIndex]
    set width   [lindex $preset $wdIndex]
    set height  [lindex $preset $htIndex]

    if {$MOVE_ENCODER \
    && [string is double -strict $eh] \
    && [string is double -strict $ev]} {
        set hMotor collimator_horz_encoder_motor
        set vMotor collimator_vert_encoder_motor

        set hPosition $eh
        set vPosition $ev
    } else {
        set hMotor collimator_horz
        set vMotor collimator_vert

        set hPosition $h
        set vPosition $v
    }

    if {![limits_ok $hMotor $hPosition] \
    ||  ![limits_ok $vMotor $vPosition]} {
        log_error motor exceed software limits.
        return -code error "will exceed motor limits"
    }

    log_note moving collimator to $name

    move $hMotor to $hPosition
    move $vMotor to $vPosition
    set waitList [list $hMotor $vMotor]
    if {$fh > 0} {
        move beam_size_sample_x to $fh
        lappend waitList beam_size_sample_x
    }
    if {$fv > 0} {
        move beam_size_sample_y to $fv
        lappend waitList beam_size_sample_y
    }

    eval wait_for_devices $waitList

    ## force to check match
    collimatorMoveMatch 1
    return [list $index $show $micr $width $height]
}
proc collimatorMove_cleanup { } {
}
proc collimatorMoveMatch { {forced 0} } {
    global gDevice

    variable ::collimatorMove::MATCH_ENCODER
    variable cfgCollimatorPresetNameToIndexMap
    variable collimator_preset
    variable collimator_status
    variable collimator_horz
    variable collimator_vert
    variable collimator_horz_encoder_motor
    variable collimator_vert_encoder_motor

    ### we may be moving motors or encoders
    if {!$forced} {
        if {$gDevice(collimator_horz_encoder_motor,status) != "inactive" \
        ||  $gDevice(collimator_vert_encoder_motor,status) != "inactive" \
        ||  $gDevice(collimator_horz,status) != "inactive" \
        ||  $gDevice(collimator_vert,status) != "inactive" \
        } {
            return
        }
    }

    set nIndex $cfgCollimatorPresetNameToIndexMap(name)
    set hIndex $cfgCollimatorPresetNameToIndexMap(horz)
    set vIndex $cfgCollimatorPresetNameToIndexMap(vert)
    set eHIndex $cfgCollimatorPresetNameToIndexMap(horz_encoder)
    set eVIndex $cfgCollimatorPresetNameToIndexMap(vert_encoder)
    set thIndex $cfgCollimatorPresetNameToIndexMap(tolerance_horz)
    set tvIndex $cfgCollimatorPresetNameToIndexMap(tolerance_vert)

    set indexMatched -1
    set index 0
    foreach preset $collimator_preset {
        #foreach {name horz vert t_h t_v} $preset break
        set name [lindex $preset $nIndex]
        set horz [lindex $preset $hIndex]
        set vert [lindex $preset $vIndex]
        set eH   [lindex $preset $eHIndex]
        set eV   [lindex $preset $eVIndex]
        set t_h  [lindex $preset $thIndex]
        set t_v  [lindex $preset $tvIndex]

        if {$MATCH_ENCODER \
        && [string is double -strict $eH] \
        && [string is double -strict $eV]} {
            #puts "checking $name with encoders eH=$eH eV=$eV"
            if {abs($collimator_horz_encoder_motor - $eH) <= $t_h \
            &&  abs($collimator_vert_encoder_motor - $eV) <= $t_v} {
                set diffMH [expr abs($collimator_horz - $horz)]
                set diffMV [expr abs($collimator_vert - $vert)]
                #### encoder may be close to one end but motor close to the
                #### other end.
                if {$diffMH > 2.0 * $t_h} {
                    #log_severe WARNING collimator $name \
                    #horz motor=$collimator_horz \
                    #not match preset=$horz \
                    #diff=$diffMH > $t_h \
                    #when encoder matches.
                }
                if {$diffMV > 2.0 * $t_v} {
                    #log_severe WARNING collimator $name \
                    #vert motor=$collimator_vert \
                    #not match preset=$vert \
                    #diff=$diffMV > $t_v \
                    #when encoder matches.
                }
                set indexMatched $index
                break
            } else {
                #puts "not match: $collimator_horz_encoder_motor $collimator_vert_encoder_motor"
                #puts "diff [expr abs($collimator_horz_encoder_motor - $eH)]"
                #puts "diff [expr abs($collimator_vert_encoder_motor - $eV)]"
            }
        } else {
            if {abs($collimator_horz - $horz) <= $t_h && \
            abs($collimator_vert - $vert) <= $t_v} {
                if {[string is double -strict $eH] \
                &&  [string is double -strict $eV]} {
                    if {$collimator_horz_encoder_motor != 0 \
                    &&  $collimator_vert_encoder_motor != 0 \
                    } {
                        set diffEH \
                        [expr abs($collimator_horz_encoder_motor - $eH)]

                        set diffEV \
                        [expr abs($collimator_vert_encoder_motor - $eV)]
                        if {$diffEH > 2.0 * $t_h} {
                            log_severe WARNING collimator $name \
                            horz encoder=$collimator_horz_encoder_motor \
                            not match preset=$eH \
                            diff=$diffEH > $t_h \
                            when motor matches.
                        }
                        if {$diffEV > 2.0 * $t_v} {
                            log_severe WARNING collimator $name \
                            vert encoder=$collimator_vert_encoder_motor \
                            not match preset=$eV \
                            diff=$diffEV > $t_v \
                            when motor matches.
                        }
                    }
                }

                set indexMatched $index
                break
            }
        }

        incr index
    }
    if {$indexMatched < 0} {
        set isMicro 0
        set width 2.0
        set height 2.0
    } else {
        set item [lindex $collimator_preset $indexMatched]

        set mIndex $cfgCollimatorPresetNameToIndexMap(is_micron_beam)
        set wIndex $cfgCollimatorPresetNameToIndexMap(width)
        set hIndex $cfgCollimatorPresetNameToIndexMap(height)

        set isMicro [lindex $item $mIndex]
        set width   [lindex $item $wIndex]
        set height  [lindex $item $hIndex]
    }

    set collimator_status "$isMicro $indexMatched $width $height"
}
proc collimatorMove_getIndexFromIndex { index } {
    variable cfgCollimatorPresetNameToIndexMap
    variable collimator_preset

    set nIndex $cfgCollimatorPresetNameToIndexMap(name)
    set shIndex $cfgCollimatorPresetNameToIndexMap(display)
    set mIndex  $cfgCollimatorPresetNameToIndexMap(is_micron_beam)
    set wIndex $cfgCollimatorPresetNameToIndexMap(width)
    set hIndex $cfgCollimatorPresetNameToIndexMap(height)

    set preset [lindex $collimator_preset $index]
    set name [lindex $preset $nIndex]
    set show [lindex $preset $shIndex]
    set micr [lindex $preset $mIndex]

    set width   [lindex $preset $wIndex]
    set height  [lindex $preset $hIndex]
    return [list $index $show $micr $width $height]
}
proc collimatorMove_getIndexFromName { name_ } {
    variable cfgCollimatorPresetNameToIndexMap
    variable collimator_preset

    set nIndex $cfgCollimatorPresetNameToIndexMap(name)
    set shIndex $cfgCollimatorPresetNameToIndexMap(display)
    set mIndex  $cfgCollimatorPresetNameToIndexMap(is_micron_beam)
    set wIndex $cfgCollimatorPresetNameToIndexMap(width)
    set hIndex $cfgCollimatorPresetNameToIndexMap(height)

    set index 0
    foreach preset $collimator_preset {
        set name [lindex $preset $nIndex]
        set show [lindex $preset $shIndex]
        set micr [lindex $preset $mIndex]

        if {$name == $name_} {
            set width   [lindex $preset $wIndex]
            set height  [lindex $preset $hIndex]
            return [list $index $show $micr $width $height]
        }
        incr index
    }
    return [list -1 0 0 2 2]
}
proc collimatorMove_getOutIndex { } {
    variable cfgCollimatorNameOut

    set result [collimatorMove_getIndexFromName $cfgCollimatorNameOut]

    ### double check
    foreach {index show micr width height} $result break
    if {$index < 0} {
        log_severe $cfgCollimatorNameOut collimator preset not found
        return -code error NOT_FOUND
    }
    if {$micr} {
        log_severe $cfgCollimatorNameOut collimator is marked as micro
        return -code error NOT_FOUND
    }
    return $result
}
proc collimatorMove_getNormalBeamIndex { } {
    variable cfgCollimatorNameNormalBeam

    set result [collimatorMove_getIndexFromName $cfgCollimatorNameNormalBeam]

    ### double check
    foreach {index show micr width height} $result break
    if {$index < 0} {
        log_severe $cfgCollimatorNameNormalBeam collimator not found
        return -code error NOT_FOUND
    }
    if {!$show} {
        log_severe $cfgCollimatorNameNormalBeam collimator is hidden from user
        return -code error NOT_FOUND
    }
    if {$micr} {
        log_severe $cfgCollimatorNameNormalBeam collimator is marked as micro
        return -code error NOT_FOUND
    }
    return $result
}
proc collimatorMove_getDefaultMicroIndex { } {
    variable cfgCollimatorNameDefaultMicro

    set result [collimatorMove_getIndexFromName $cfgCollimatorNameDefaultMicro]

    ### double check
    foreach {index show micr width height} $result break
    if {$index < 0} {
        log_severe $cfgCollimatorNameDefaultMicro collimator not found
        return -code error NOT_FOUND
    }
    if {!$show} {
        log_severe $cfgCollimatorNameDefaultMicro collimator is hidden from user
        return -code error NOT_FOUND
    }
    if {!$micr} {
        log_severe $cfgCollimatorNameDefaultMicro collimator is NOT marked as micro
        return -code error NOT_FOUND
    }
    return $result
}
##### utility for other devices
proc collimatorGetFirstMicron { } {
    variable cfgCollimatorPresetNameToIndexMap

    variable collimator_preset

    set shIndex $cfgCollimatorPresetNameToIndexMap(display)
    set mIndex  $cfgCollimatorPresetNameToIndexMap(is_micron_beam)
    set wIndex $cfgCollimatorPresetNameToIndexMap(width)
    set hIndex $cfgCollimatorPresetNameToIndexMap(height)

    set index 0
    foreach preset $collimator_preset {
        set show [lindex $preset $shIndex]
        set micr [lindex $preset $mIndex]

        if {$show && $micr} {
            set width   [lindex $preset $wIndex]
            set height  [lindex $preset $hIndex]
            return [list $index $width $height]
        }
        incr index
    }
    return [list -1 2 2]
}
proc collimatorMoveFirstMicron { } {
    variable collimator_status

    set microIn [lindex $collimator_status 0]
    if {$microIn} {
        set width  [lindex $collimator_status 2]
        set height [lindex $collimator_status 3]
        return [list $width $height]
    }

    set first [collimatorGetFirstMicron]
    foreach {index width height} $first break
    if {$index < 0} {
        log_error no micro collimator found in the preset
        return -code error no_micro_colliator
    }
    collimatorMove_start $index
    return [list $width $height]
}
proc collimatorMoveOut { } {
    variable collimator_status

    log_warning move collimator out

    set current_index [lindex $collimator_status 1]
    set info [collimatorMove_getOutIndex]
    foreach {index show micr width height} $info break

    set need_move 1
    if {$current_index == $index} {
        set need_move 0
    }
    collimatorMove_start $index
    return $need_move
}
proc collimatorNormalIn { } {
    set info [collimatorMove_getNormalBeamIndex]
    foreach {index show micr width height} $info break
    collimatorMove_start $index
}
proc collimatorMove_getFluxLUTFromIndex { index } {
    variable cfgCollimatorPresetNameToIndexMap
    variable collimator_preset

    set ftIndex $cfgCollimatorPresetNameToIndexMap(flux_table)

    set preset [lindex $collimator_preset $index]
    set ftName [lindex $preset $ftIndex]
    return $ftName
}
proc collimatorMove_getUserCollimatorList { } {
    variable collimator_preset
    variable cfgCollimatorPresetNameToIndexMap

    set shIndex $cfgCollimatorPresetNameToIndexMap(display)
    set mIndex  $cfgCollimatorPresetNameToIndexMap(is_micron_beam)
    set wIndex  $cfgCollimatorPresetNameToIndexMap(width)
    set hIndex  $cfgCollimatorPresetNameToIndexMap(height)
    set ftIndex $cfgCollimatorPresetNameToIndexMap(flux_table)

    set result ""
    set index -1
    foreach preset $collimator_preset {
        incr index
        set show [lindex $preset $shIndex]
        if {!$show} {
            continue
        }
        set micro  [lindex $preset $mIndex]
        set width  [lindex $preset $wIndex]
        set height [lindex $preset $hIndex]
        set ftName [lindex $preset $ftIndex]
        lappend result [list $index $micro $width $height $ftName]
    }
    return $result
}
proc collimatorMove_setFluxLUTByIndex { index ftName } {
    variable cfgCollimatorPresetNameToIndexMap
    variable collimator_preset

    set nIndex  $cfgCollimatorPresetNameToIndexMap(name)
    set ftIndex $cfgCollimatorPresetNameToIndexMap(flux_table)

    set preset [lindex $collimator_preset $index]

    set name   [lindex $preset $nIndex]

    set newPreset [setStringFieldWithPadding $preset $ftIndex $ftName]
    set collimator_preset [lreplace $collimator_preset $index $index $newPreset]
    log_warning collimator $name flux_table changed to $ftName
}
