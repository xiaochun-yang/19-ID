proc peakTableVert_initialize { } {
}

proc peakTableVert_start { time } {
    variable energy
    variable table_vert

    set fileName [get_scanMotor_subLogFileName]
    puts "filename: $fileName"

    ######### this is using formula
    #set centerTV [energy_calculate_table_vert $energy]
    ######### this is use current position
    set save_TV $table_vert

    set width   0.12
    set numStep 121

    set MAX_RETRY 1
    set result failed
    for {set i 0} {$i < $MAX_RETRY} {incr i} {
        wait_for_good_beam
        if {[catch {
            ### it may shift the centerTV
            set centerTV $save_TV
            set result [peakTableVert_scan $fileName centerTV $width $numStep $time]
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

    move table_vert to $save_TV
    wait_for_devices table_vert

    if {$result == "failed"} {
        return -code error "failed_after_max_retry"
    } else {
        return $result
    }
}
proc peakTableVert_scan { fileName centerTV_ref width numStep time } {
    upvar $centerTV_ref centerTV

    variable ::scanMotor::saveUserName
    variable ::scanMotor::saveSessionID

    set startTV [expr $centerTV - $width / 2.0]
    set stepSize [expr $width / double($numStep - 1) ]

    ## endTV is only used for writing the file
    set endTV [expr $startTV + $width]

    set nameOnly [file tail $fileName]
    set dirOnly  [file dir $fileName]

    set contents ""
    append contents "# file       $nameOnly $dirOnly [file root $nameOnly] 0\n"
    append contents "# date       [time_stamp]\n"
    append contents \
    "# motor1     table_vert $numStep $startTV $endTV $stepSize mm\n"
    append contents "# motor2     \n"
    append contents "# detectors  i0\n"
    append contents "# filters    \n"
    append contents "# timing     $time 0.0 1 0.0 s\n"
    append contents "\n"
    append contents "\n"
    append contents "\n"
    impWriteFile $saveUserName $saveSessionID $fileName $contents false

    if {[catch {
        set tvList [list]
        set vList [list]
        for {set i 0} {$i < $numStep} {incr i} {
            set tv [expr $startTV + $i * $stepSize]
            move table_vert to $tv
            wait_for_devices table_vert
            if {$i == 0} {
                wait_for_time 2000
            }
            read_ion_chambers $time i0
            wait_for_devices i0
            set v [get_ion_chamber_counts i0]
            lappend tvList $tv
            lappend vList $v

            set contents "$tv $v\n"
            impAppendTextFile $saveUserName $saveSessionID $fileName $contents
        }
    } errMsg]} {
        return -code error $errMsg
    }
    foreach {max_i0 max_jump} [peakTableVert_checkIntegrity $vList] break
    #set vList [peakTableVert_smooth $vList]
    #set max_index [peakTableVert_findMax $vList]

    set vList [peakTableVert_slope $vList]

    set max_index [peakTableVert_findWeightCenter $vList]

    set max_e [expr $startTV + $max_index * $stepSize]

    puts "for $fileName: max_index=$max_index max_p=$max_e start=$startTV stepSize=$stepSize"

    variable focusing_mirror_2_vert_1
    variable focusing_mirror_2_vert_2
    return [list $max_e $max_i0 $max_jump $focusing_mirror_2_vert_1 $focusing_mirror_2_vert_2]
}
proc peakTableVert_findMax { vList } {
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
proc peakTableVert_findWeightCenter { vList } {
    ### you can find max_i0 from vList but it is available already

    set CUT_OFF_PERCENT 25.0
    set max_i0 [lindex $vList 0]
    foreach v $vList {
        if {$v > $max_i0} {
            set max_i0 $v
        }
    }


    set cut_off_v [expr double($max_i0) * $CUT_OFF_PERCENT / 100.0]

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

proc peakTableVert_checkIntegrity { vList } {
    set MIN_SIGNAL 0.01
    set MAX_JUMP 0.8

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
        log_error max i0 reading too small $maxV < $MIN_SIGNAL
        return -code error "i0_reading_too_small"
    }
    if {$maxDiff > $MAX_JUMP} {
        log_error max jump between neighbors too big $maxDiff > $MAX_JUMP
        return -code error "max_jump_too_big"
    }

    return [list $maxV $maxDiff]
}
proc peakTableVert_smooth { rawList } {
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

proc peakTableVert_slope { vList } {
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
