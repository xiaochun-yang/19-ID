proc laserCalibrate_initialize { } {
    loadLaserChannelConfig
}
proc laserCalibrate_start { v1s v1e v2s v2e h1s h1e h2s h2e interval } {
    global gLaserRead

    ####for easy switch
    set motorV1 table_vert_1_real
    set motorV2 table_vert_2_real
    set motorH1 table_horz_1_real
    set motorH2 table_horz_2_real
        
    variable $motorV1
    variable $motorV2
    variable $motorH1
    variable $motorH2
        
    set dv1List {}
    set dv2List {}
    set dh1List {}
    set dh2List {}
    set motorMask [list 0 0 0 0]
    set motorName [list $motorV1 $motorV2 $motorH1 $motorH2]

    laserCalibrateFillList $v1s $v1e $v2s $v2e $h1s $h1e $h2s $h2e $interval \
    dv1List dv2List dh1List dh2List motorMask

    foreach {v1Selected v2Selected h1Selected h2Selected} $motorMask break
    set total [llength $dv1List]

    log_note v1list $dv1List
    log_note v2list $dv2List
    log_note h1list $dh1List
    log_note h2list $dh2List

    ####turn on laser#####
    set h [start_waitable_operation setDigitalOutput 1 255 252]
    set result [wait_for_operation_to_finish $h]
    wait_for_time 1000


    ################init position#####
    set motorList {}
    if {$v1Selected} {
        lappend motorList $motorV1
    }
    if {$v2Selected} {
        lappend motorList $motorV2
    }
    if {$h1Selected} {
        lappend motorList $motorH1
    }
    if {$h2Selected} {
        lappend motorList $motorH2
    }

    set sv1List {}
    set sv2List {}
    set sh1List {}
    set sh2List {}
    for {set i 0} {$i < $total} {incr i} {
        set dv1 [lindex $dv1List $i]
        set dv2 [lindex $dv2List $i]
        set dh1 [lindex $dh1List $i]
        set dh2 [lindex $dh2List $i]
        set motorPos [list $dv1 $dv2 $dh1 $dh2]

        for {set mi 0} {$mi < 4} {incr mi} {
            if {[lindex $motorMask $mi]} {
                move [lindex $motorName $mi] to [lindex $motorPos $mi]
            }
        }
        eval wait_for_devices $motorList
        ###check
        for {set mi 0} {$mi < 4} {incr mi} {
            if {[lindex $motorMask $mi]} {
                set motor [lindex $motorName $mi]
                set pos   [lindex $motorPos  $mi]
                if {abs($pos - [set $motor]) > 0.01} {
                    return -code error "$motor stall"
                }
            }
        }

        ###read laser
        set h [start_waitable_operation readAnalog 1000]
        set result [wait_for_operation_to_finish $h]
        if {[string first abort $result] >= 0} {
            return -code error aborted
        }
        if {[llength $result] < 9} {
            return -code error "bad readAnalog: $result"
        }
        log_note readAnalog: $result

        set dataOnly [lrange $result 1 end]
        set sv1 [lindex $dataOnly $gLaserRead(table_vert_1,CHANNEL)]
        set sv2 [lindex $dataOnly $gLaserRead(table_vert_2,CHANNEL)]
        set sh1 [lindex $dataOnly $gLaserRead(table_horz_1,CHANNEL)]
        set sh2 [lindex $dataOnly $gLaserRead(table_horz_2,CHANNEL)]
        lappend sv1List $sv1
        lappend sv2List $sv2
        lappend sh1List $sh1
        lappend sh2List $sh2
    }

    log_note sv1: $sv1List
    log_note s21: $sv2List
    log_note sh1: $sh1List
    log_note sh2: $sh2List

    ####save results
    for {set mi 0} {$mi < 4} {incr mi} {
        if {[lindex $motorMask $mi]} {
            set motor [lindex $motorName $mi]
            switch -exact -- $mi {
                0 {
                    laserCalirateSaveRaw $motor $dv1List $sv1List
                    laserCalirateSaveLinear [expr $mi + 2] $dv1List $sv1List
                }
                1 {
                    laserCalirateSaveRaw $motor $dv1List $sv1List
                    laserCalirateSaveLinear [expr $mi + 2] $dv2List $sv2List
                }
                2 {
                    laserCalirateSaveRaw $motor $dh1List $sh1List
                    laserCalirateSaveLinear [expr $mi + 2] $dh1List $sh1List
                }
                3 {
                    laserCalirateSaveRaw $motor $dh2List $sh2List
                    laserCalirateSaveLinear [expr $mi + 2] $dh2List $sh2List
                }
            }
        }
    }
}
proc laserCalirateSaveRaw { fileName pList sList } {
    set l1 [llength $pList]
    set l2 [llength $sList]
    if {$l1 != $l2} {
        log_error "position list not match sensor reading list for $fileName"
        return
    }
    if {$l1 < 2} {
        log_error "not enough data to save $fileName"
        return
    }
        
    file mkdir laserCalibrate
    if {[catch {open laserCalibrate/$fileName w} ch]} {
        log_error open file $fileName to save raw data failed: $ch
        return
    }
    if {[catch {
        foreach p $pList s $sList {
            puts $ch [format "%11.3f %11.5f" $p $s]
        }
    } errorMsg]} {
        log_error save raw data to $fileName failed: $errorMsg
    }
    close $ch
}
proc laserCalirateSaveLinear { index pList sList } {
    variable laser_motor_scale
    variable laser_motor_offset

    set y1 [lindex $pList 0]
    set y2 [lindex $pList end]
    set x1 [lindex $sList 0]
    set x2 [lindex $sList end]
    if {abs($x2 - $x1) < 0.001} {
        log_error delta too small to do linear for index $index
        return
    }
    set a [expr ($y2 - $y1) / ($x2 - $x1)]
    set b [expr $y1 - $a * $x1]

    set laser_motor_scale  [lreplace $laser_motor_scale  $index $index $a]
    set laser_motor_offset [lreplace $laser_motor_offset $index $index $b]
}
proc laserCalibrateFillList { v1s v1e v2s v2e h1s h1e h2s h2e interval \
v1ListREF v2ListREF h1ListREF h2ListREF motorMaskREF } {
    upvar $v1ListREF dv1List
    upvar $v2ListREF dv2List
    upvar $h1ListREF dh1List
    upvar $h2ListREF dh2List
    upvar $motorMaskREF motorSelected

    if {$interval < 1} {
        return -code error "internal must >= 1"
    }
    set stepSize_v1 [expr ($v1e - $v1s) / $interval]
    set stepSize_v2 [expr ($v2e - $v2s) / $interval]
    set stepSize_h1 [expr ($h1e - $h1s) / $interval]
    set stepSize_h2 [expr ($h2e - $h2s) / $interval]

    if {abs($stepSize_v1) < 0.001 &&
    abs($stepSize_v2) < 0.001 &&
    abs($stepSize_h1) < 0.001 &&
    abs($stepSize_h2) < 0.001} {
        return -code error "non motor selected: all steps=0"
    }
    set dv1List {}
    set dv2List {}
    set dh1List {}
    set dh2List {}
    set motorSelected [list 0 0 0 0]
    for {set i 0} {$i < $interval} {incr i} {
        lappend dv1List [expr $v1s + $stepSize_v1 * $i]
        lappend dv2List [expr $v2s + $stepSize_v2 * $i]
        lappend dh1List [expr $h1s + $stepSize_h1 * $i]
        lappend dh2List [expr $h2s + $stepSize_h2 * $i]
    }
    lappend dv1List $v1e
    lappend dv2List $v2e
    lappend dh1List $h1e
    lappend dh2List $h2e

    if {abs($stepSize_v1) >= 0.001} {
        set motorSelected [lreplace $motorSelected 0 0 1]
    }
    if {abs($stepSize_v2) >= 0.001} {
        set motorSelected [lreplace $motorSelected 1 1 1]
    }
    if {abs($stepSize_h1) >= 0.001} {
        set motorSelected [lreplace $motorSelected 2 2 1]
    }
    if {abs($stepSize_h2) >= 0.001} {
        set motorSelected [lreplace $motorSelected 3 3 1]
    }
}
