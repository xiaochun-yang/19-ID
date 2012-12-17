proc peakEnergy_initialize { } {
}

proc peakEnergy_getLogFileName { } {
    variable scan_motor_status
    variable undulator_gap

    set fullPath [lindex $scan_motor_status 0]

    set file [file tail $fullPath]
    set file [file root $file]

    set addOn [expr int($undulator_gap * 1000)]

    set fileName ${file}_${addOn}.scan


    return $fileName
}

proc peakEnergy_start { time harmonic } {
    variable undulator_gap

    if {[energyGetEnabled gap_move]} {
        log_error please disable gap move on energy config
        return -code error NEED_TO_DISABLE_GAP_MOVE
    }
    set fileName [peakEnergy_getLogFileName]
    set centerE [peakEnergy_calculate_energy $undulator_gap $harmonic]

    if {$harmonic == 0} {
        set width 300.00
        set numStep 301
    } else {
        set width 100.00
        set numStep 101
    }

    set MAX_RETRY 2
    set result failed
    for {set i 0} {$i < $MAX_RETRY} {incr i} {
        wait_for_good_beam
        if {[catch {
            ### it may shift the centerE
            set result [peakEnergy_scan $fileName centerE $width $numStep $time]
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
proc peakEnergy_scan { fileName centerE_ref width numStep time } {
    upvar $centerE_ref centerE

    set startE [expr $centerE - $width / 2.0]
    set stepSize [expr $width / double($numStep - 1) ]

    ## endE is only used for writing the file
    set endE [expr $startE + $width]

    if {[catch {open $fileName w} fh]} {
        log_error DEBUG open $fileName failed, no log
        log_error DEBUG $fh
        set fh ""
    } else {
        set contents ""
        append contents "# file       $fileName [pwd] [file root $fileName] 0\n"
        append contents "# date       [time_stamp]\n"
        append contents \
        "# motor1     energy $numStep $startE $endE $stepSize ev\n"
        append contents "# motor2     \n"
        append contents "# detectors  i2\n"
        append contents "# filters    \n"
        append contents "# timing     $time 0.0 1 0.0 s\n"
        append contents "\n"
        append contents "\n"
        append contents "\n"

        puts $fh $contents
    }
    if {[catch {
        set eList [list]
        set vList [list]
        for {set i 0} {$i < $numStep} {incr i} {
            set e [expr $startE + $i * $stepSize]
            move energy to $e
            wait_for_devices energy
            if {$i == 0} {
                wait_for_time 2000
            }
            read_ion_chambers $time i2
            wait_for_devices i2
            set v [get_ion_chamber_counts i2]
            lappend eList $e
            lappend vList $v

            if {$fh != ""} {
                puts $fh "$e $v"
                flush $fh
            }

            #set max_index [peakEnergy_findMax $v]
            #if {$max_index < $i - 3} {
            #    set max_e [lindex $eList $max_index]
            #    return $max_e
            #}
        }
    } errMsg]} {
        if {$fh != ""} {
            close $fh
        }
        return -code error $errMsg
    }
    if {$fh != ""} {
        close $fh
    }
    foreach {max_i2 max_jump} [peakEnergy_checkIntegrity $vList] break
    set vList [peakEnergy_smooth $vList]
    set max_index [peakEnergy_findMax $vList]

    ### check if max is too close to edges
    set ll [llength $vList]
    if {$max_index < 5} {
        log_warning slope adjust for starting edge
        set vOnSlopeList [peakEnergy_slope $vList]
        set max_index [peakEnergy_findMax $vOnSlopeList]
    }
    if {$max_index < 5} {
        log_warning max too close to the starting edge
        log_warning shift energy and redo
        set centerE [expr $centerE - $width / 2.0]
        return -code error "peak_too_close_to_starting_edge"
    }
    if {$max_index > ($ll - 1 - 5)} {
        log_warning slope adjust for ending edge
        set vOnSlopeList [peakEnergy_slope $vList]
        set max_index [peakEnergy_findMax $vOnSlopeList]
    }
    if {$max_index > ($ll - 1 - 5)} {
        log_warning max too close to the ending edge
        log_warning shift energy and redo
        set centerE [expr $centerE + $width / 2.0]
        return -code error "peak_too_close_to_ending_edge"
    }

    set max_e [lindex $eList $max_index]
    return [list $max_e $max_i2 $max_jump]
}
proc peakEnergy_findMax { vList } {
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

proc peakEnergy_calculate_energy {  gap harmonic } {
    set aList [list -55586    -43395.22     -31949.38]
    set bList [list 24126     18550.418     13502.192]
    set cList [list -2991.37   -2254.4466    -1625.967]
    set dList [list 140.927    104.14398     74.24286]

    set a [lindex $aList $harmonic]
    set b [lindex $bList $harmonic]
    set c [lindex $cList $harmonic]
    set d [lindex $dList $harmonic]

    puts "har=$harmonic a=$a b=$b c=$c d=$c"

    return [expr $a + \
    $b * $gap + \
    $c * $gap * $gap + \
    $d * $gap * $gap * $gap]
}
proc peakEnergy_checkIntegrity { vList } {
    set MIN_SIGNAL 0.01
    ### this is 20%
    set MAX_JUMP 0.2

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
proc peakEnergy_smooth { rawList } {
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

proc peakEnergy_slope { vList } {
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
