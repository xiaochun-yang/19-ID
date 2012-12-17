proc peakGeneric_initialize { } {
}

## peak_scan_config
#"motor_name: table_vert start: 35.200 end: 35.300 points: 101 BACKGROUND_CUT_OFF_PERCENT 25"

proc peakGeneric_start { time } {
    variable peak_scan_config

    if {[llength $peak_scan_config] < 12} {
        log_error wrong peak_scan_config
        return -code error "wrong_peak_scan_config"
    }

    set fileName [get_scanMotor_subLogFileName]

    set motorName [lindex $peak_scan_config 1]
    set startP    [lindex $peak_scan_config 3]
    set endP      [lindex $peak_scan_config 5]
    set numPoint  [lindex $peak_scan_config 7]
    set CUT_OFF   [lindex $peak_scan_config 9]
    set signal    [lindex $peak_scan_config 11]
    set timeWait  [lindex $peak_scan_config 13]
    if {![isMotor $motorName]} {
        log_error $motorName is not motor
        return -code error "wrong_peak_scan_config"
    }
    if {$numPoint < 2} {
        log_error wrong numPoint: $numPoint should be > 1
        return -code error "wrong_peak_scan_config"
    }
    if {![isIonChamber $signal]} {
        log_error wrong signal: $signal is not an ion chamber
        return -code error "wrong_peak_scan_config"
    }

    variable $motorName
    set save_POS [set $motorName]

    set MAX_RETRY 2
    set result failed
    for {set i 0} {$i < $MAX_RETRY} {incr i} {
        wait_for_good_beam
        if {[catch {
            set result [peakGeneric_scan $fileName $motorName $startP $endP \
            $numPoint $time $signal $timeWait $CUT_OFF 0.001 -1]

            break
        } errMsg]} {
            puts "scan error: $errMsg"
            if {$errMsg == ""} {
                puts "errMsg==EMPTY and result=$result"
                break
            }
            if {[string first abort $errMsg] >= 0} {
                return -code error $errMsg
            }
        }
        if {![beamGood]} {
            log_warning lost beam during $motorName scan
            set result failed
            if {$i < $MAX_RETRY} {
                log_warning retrying
            }
        }
    }

    move $motorName to $save_POS
    wait_for_devices $motorName

    if {$result == "failed"} {
        return -code error "failed_after_max_retry"
    } else {
        return $result
    }
}
proc peakGeneric_scan { fileName motor start end numPoint time signal \
timeWait CUT_OFF minSignal maxJump {system 0}} {

    puts "peakGeneric_scan $fileName $motor $start $end $numPoint $time $signal"
    variable ::scanMotor::saveUserName
    variable ::scanMotor::saveSessionID

    set stepSize [expr ($end - $start) / double($numPoint - 1) ]

    set nameOnly [file tail $fileName]
    set dirOnly  [file dir $fileName]

    set contents ""
    append contents "# file       $nameOnly $dirOnly [file root $nameOnly] 0\n"
    append contents "# date       [time_stamp]\n"
    append contents \
    "# motor1     $motor $numPoint $start $end $stepSize mm\n"
    append contents "# motor2     \n"
    append contents "# detectors  $signal\n"
    append contents "# filters    \n"
    append contents "# timing     $time $timeWait 1 0.0 s\n"
    append contents "\n"
    append contents "\n"
    append contents "\n"
    if {!$system} {
        impWriteFile $saveUserName $saveSessionID $fileName $contents false
    } else {
        global gUserName
        global gSessionID
        impWriteFile $gUserName $gSessionID $fileName $contents false
    }

    if {[catch {
        set tvList [list]
        set vList [list]
        for {set i 0} {$i < $numPoint} {incr i} {
            set tv [expr $start + $i * $stepSize]
            move $motor to $tv
            wait_for_devices $motor
            if {$timeWait > 0.0} {
                wait_for_time [expr int(1000 * $timeWait)]
            }
            read_ion_chambers $time $signal
            wait_for_devices $signal
            set v [get_ion_chamber_counts $signal]
            lappend tvList $tv
            lappend vList $v

            set contents "$tv $v\n"
            if {!$system} {
                impAppendTextFile $saveUserName $saveSessionID $fileName $contents
            } else {
                global gUserName
                global gSessionID
                impAppendTextFile $gUserName $gSessionID $fileName $contents
            }
        }
    } errMsg]} {
        return -code error $errMsg
    }
    if {[catch {peakGeneric_checkIntegrity $vList $minSignal $maxJump} checkResult]} {
        log_error peak find failed: $checkResult
        return [list 0 0 0]
    }
    foreach {max_signal max_jump} $checkResult break

    set simpleVList [peakGeneric_smooth $vList]

    foreach {simpleMaxIndex hm1 hm2 } [peakGeneric_findMax $simpleVList] break

    #set vList [peakGeneric_slope $vList]

    set max_index [peakGeneric_findWeightCenter $vList $CUT_OFF]

    if {abs($simpleMaxIndex - $max_index) > 3} {
        puts "strange peak ,peak at $simpleMaxIndex but center at $max_index"
    }

    set max_e [expr $start + $max_index * $stepSize]

    set FWHM [expr abs(($hm2 - $hm1) * $stepSize)]

    puts "for $fileName: max_index=$max_index max_p=$max_e start=$start stepSize=$stepSize FWMH=$FWHM"
    puts "FWHM index: $hm1 $hm2 max index: $simpleMaxIndex"

    return [list $max_e $max_signal $FWHM]
}

proc peakGeneric_findMax { vList } {
    ##find max reading
    set max_index 0
    set min_index 0
    set max_v [lindex $vList 0]
    set min_v [lindex $vList 0]
    set ll [llength $vList]

    for {set i 1} {$i < $ll} {incr i} {
        set v [lindex $vList $i]
        if  {$v > $max_v} {
            set max_v $v
            set max_index $i
        }
        if {$v < $min_v} {
            set min_v $v
            set min_index $i
        }
    }

    if {$max_v == $min_v} {
        return [list 0 0 0]
    }

    #### find FWHM ####
    set hm [expr ($min_v + $max_v) / 2.0]
    #puts "max=$max_v min=$min_v hm=$hm"

    ## widest
    set first_cut 1
    for {set i 1} {$i <= $max_index} {incr i} {
        set v [lindex $vList $i]
        if {$v >= $hm} {
            set x2 $v
            set x1 [lindex $vList [expr $i - 1]]
            if {$x1 == $x2} {
                set first_cut [expr $i - 0.5]
            } else {
                set first_cut [expr $i -1 + ($hm - $x1) /( $x2 - $x1)]
                #puts "first cut: $first_cut x1=$x1 x2=$x2 i=$i"
            }
            break
        }
    }
    set ll [llength $vList]
    set second_cut [expr $ll -1]
    for {set i $second_cut} {$i >= $max_index} {incr i -1} {
        set v [lindex $vList $i]
        if {$v >= $hm} {
            set x1 $v
            set x2 [lindex $vList [expr $i + 1]]
            if {$x1 == $x2} {
                set second_cut [expr $i + 0.5]
            } else {
                set second_cut [expr $i + ($hm - $x1) /( $x2 - $x1)]
                #puts "second cut: $second_cut x1=$x1 x2=$x2 i=$i"
            }
            break
        }
    }

    return [list $max_index $first_cut $second_cut]
}

proc peakGeneric_findWeightCenter { vList CUT_OFF_PERCENT } {
    if {$CUT_OFF_PERCENT < 0} {
        log_warning bad BACKGROUND_CUT_OFF_PERCENT: $CUT_OFF_PERCENT
        set CUT_OFF_PERCENT 0
    }

    set max_signal [lindex $vList 0]
    set min_signal [lindex $vList 0]
    foreach v $vList {
        if {$v > $max_signal} {
            set max_signal $v
        }
        if {$v < $min_signal} {
            set min_signal $v
        }
    }
    set cut_off_v [expr $min_signal + \
    double($max_signal - $min_signal) * $CUT_OFF_PERCENT / 100.0]

    set index 0
    set sum 0
    set center 0
    foreach v $vList {
        if {$v >= $cut_off_v} {
            set weight [expr $v - $cut_off_v]
        } else {
            set weight 0
        }

        set center [expr $center + $index * $weight]
        set sum    [expr $sum    + $weight]
        incr index
    }
    if {$sum > 0} {
        set center [expr double($center) / $sum]
    }
    return $center
}

proc peakGeneric_checkIntegrity { vList MIN_SIGNAL MAX_JUMP } {
    set vPre [lindex $vList 0]

    set i 0
    set maxDiff 0.0
    set maxV $vPre
    set max_index 0
    foreach v $vList {
        set diff [expr abs(double($v) - $vPre)]
        if {$diff != 0.0} {
            set absVPre [expr abs($vPre)]
            set absV [expr abs($v)]
            if {$absV > $absVPre} {
                set diff [expr $diff / $absV]
            } else {
                set diff [expr $diff / $absVPre]
            }
        }
        if {$MAX_JUMP > 0 && $diff > $MAX_JUMP} {
            puts "failed at $i $vPre->$v"
        }
        if {$diff > $maxDiff} {
            set maxDiff $diff
        }
        if {$v > $maxV} {
            set maxV $v
            set max_index $i
        }

        set vPre $v
        incr i
    }
    puts "MAXV=$maxV MAXDIFF=$maxDiff"

    if {$maxV < $MIN_SIGNAL} {
        log_error max signal reading too small $maxV < $MIN_SIGNAL
        return -code error "signal_reading_too_small"
    }
    if {$MAX_JUMP > 0 && $maxDiff > $MAX_JUMP} {
        log_error max jump between neighbors too big $maxDiff > $MAX_JUMP
        return -code error "max_jump_too_big"
    }

    set ll [llength $vList]
    if {$max_index == 0 || $max_index == $ll - 1} {
        log_error max on the edge
        return -code error "max_on_the_edge"
    }

    return [list $maxV $maxDiff]
}
proc peakGeneric_smooth { rawList } {
    set ll [llength $rawList]

    set first [lindex $rawList 0]
    set last [lindex $rawList end]

    set extList $first
    eval lappend extList $rawList $last

    set result [list]
    for {set i 0} {$i < $ll} {incr i} {
        set index $i
        set v1 [lindex $extList $index]
        incr index
        set v2 [lindex $extList $index]
        incr index
        set v3 [lindex $extList $index]
        set newV [expr 0.25 * $v1 + 0.5 * $v2 + 0.25 * $v3]
        lappend result $newV
    }
    return $result
}

proc peakGeneric_slope { vList } {
    ###find slope
    set v1 [lindex $vList 0]
    set v2 [lindex $vList end]
    set ll [llength $vList]

    set length [expr double($ll - 1)]
    set slope [expr ($v2 - $v1) / $length]

    set newVList [list]

    set i 0
    foreach v $vList {
        set dd [expr $v - $slope * $i]
        lappend newVList $dd
        incr i
    }
    return $newVList
}
