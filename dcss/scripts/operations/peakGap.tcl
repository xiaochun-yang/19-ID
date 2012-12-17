proc peakGap_initialize { } {
}

proc peakGap_start { time } {
    variable energy

    set fileName [get_scanMotor_subLogFileName]
    set centerG [energy_calculate_undulator_gap $energy]

    set width   0.06
    set numStep 61

    set MAX_RETRY 2
    set result failed
    for {set i 0} {$i < $MAX_RETRY} {incr i} {
        wait_for_good_beam
        if {[catch {
            ### it may shift the centerG
            set result [peakGap_scan $fileName centerG $width $numStep $time]
            break
        } errMsg]} {
            if {$errMsg == ""} {
                puts "errMsg==EMPTY and result=$result"
                break
            }
            if {[string first abort $errMsg] >= 0} {
                return -code error $errMsg
            }
            log_warning retry $i for $errMsg
        }
    }
    if {$result == "failed"} {
        return -code error "failed_after_max_retry"
    } else {
        return $result
    }
}
proc peakGap_scan { fileName centerG_ref width numStep time } {
    upvar $centerG_ref centerG
    variable ::scanMotor::saveUserName
    variable ::scanMotor::saveSessionID

    set startG [expr $centerG - $width / 2.0]
    set stepSize [expr $width / double($numStep - 1) ]

    ## endG is only used for writing the file
    set endG [expr $startG + $width]

    set nameOnly [file tail $fileName]
    set dirOnly  [file dir $fileName]

    set contents ""
    append contents "# file       $nameOnly $dirOnly [file root $nameOnly] 0\n"
    append contents "# date       [time_stamp]\n"
    append contents \
    "# motor1     undulator_gap $numStep $startG $endG $stepSize ev\n"
    append contents "# motor2     \n"
    append contents "# detectors  i0\n"
    append contents "# filters    \n"
    append contents "# timing     $time 0.0 1 0.0 s\n"
    append contents "\n"
    append contents "\n"
    append contents "\n"
    impWriteFile $saveUserName $saveSessionID $fileName $contents false

    if {[catch {
        set gList [list]
        set vList [list]
        for {set i 0} {$i < $numStep} {incr i} {
            set g [expr $startG + $i * $stepSize]
            move undulator_gap to $g
            wait_for_devices undulator_gap
            if {$i == 0} {
                wait_for_time 2000
            }
            read_ion_chambers $time i0
            wait_for_devices i0
            set v [get_ion_chamber_counts i0]
            lappend gList $g
            lappend vList $v

            set contents "$g $v\n"
            impAppendTextFile $saveUserName $saveSessionID $fileName $contents

            #set max_index [peakGap_findMax $v]
            #if {$max_index < $i - 3} {
            #    set max_e [lindex $gList $max_index]
            #    return $max_e
            #}
        }
    } errMsg]} {
        log_error peakGap failed: $errMsg
        return -code error $errMsg
    }
    foreach {max_i0 max_jump} [peakGap_checkIntegrity $vList] break
    set vList [peakGap_smooth $vList]
    set max_index [peakGap_findMax $vList]

    ### check if max is too close to edges
    set ll [llength $vList]
    if {$max_index < 5} {
        log_warning slope adjust for starting edge
        set vOnSlopeList [peakGap_slope $vList]
        set max_index [peakGap_findMax $vOnSlopeList]
    }
    if {$max_index < 5} {
        log_warning max too close to the starting edge
        log_warning shift undulator_gap and redo
        set centerG [expr $centerG - $width / 2.0]
        return -code error "peak_too_close_to_starting_edge"
    }
    if {$max_index > ($ll - 1 - 5)} {
        log_warning slope adjust for ending edge
        set vOnSlopeList [peakGap_slope $vList]
        set max_index [peakGap_findMax $vOnSlopeList]
    }
    if {$max_index > ($ll - 1 - 5)} {
        log_warning max too close to the ending edge
        log_warning shift undulator_gap and redo
        set centerG [expr $centerG + $width / 2.0]
        return -code error "peak_too_close_to_ending_edge"
    }

    set max_e [lindex $gList $max_index]
    return [list $max_e $max_i0 $max_jump]
}
proc peakGap_findMax { vList } {
    ##find max reading
    set max_index 0
    set max_v [lindex $vList 0]
    set ll [llength $vList]

    for {set i 1} {$i < $ll} {incr i} {
        set v [lindex $vList $i]
        if  {$v > $max_v} {
            set max_v $v
            set max_index $i
        }
    }
    return $max_index
}

proc peakGap_checkIntegrity { vList } {
    set MIN_SIGNAL 0.01
    set MAX_JUMP 0.5

    set vPre [lindex $vList 0]

    set i 0
    set maxDiff 0.0
    set maxV $vPre
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
        if {$diff > $MAX_JUMP} {
            puts "failed at $i $vPre->$v"
        }
        if {$diff > $maxDiff} {
            set maxDiff $diff
        }
        if {$v > $maxV} {
            set maxV $v
        }

        set vPre $v
        incr i
    }
    puts "MAXV=$maxV MAXDIFF=$maxDiff"

    if {$maxV < $MIN_SIGNAL} {
        log_error max i2 reading too small $maxV < $MIN_SIGNAL
        return -code error "i2_reading_too_small"
    }
    if {$maxDiff > $MAX_JUMP} {
        log_error max jump between neighbors too big $maxDiff > $MAX_JUMP
        return -code error "max_jump_too_big"
    }

    return [list $maxV $maxDiff]
}
proc peakGap_smooth { rawList } {
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

proc peakGap_slope { vList } {
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
