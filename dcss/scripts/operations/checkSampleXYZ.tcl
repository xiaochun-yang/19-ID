proc checkSampleXYZ_initialize { } {
    variable checkSampleXYZ_TRANSITION_DISTANCE
    ##default
    set checkSampleXYZ_TRANSITION_DISTANCE 0.3

    set cfg [::config getStr homeswitch.transitionDistance]
    if {[string is double -strict $cfg] && $cfg > 0} {
        set checkSampleXYZ_TRANSITION_DISTANCE $cfg
    }

    checkSampleXYZ_resetState
}

proc checkSampleXYZ_start { {homing 1} } {
    variable sample_z
    variable sample_x
    variable sample_y

    set current_desired_sample_z $sample_z

    read_ion_chambers 1.0 i_home_sample_x i_home_sample_y e_abs_sample_z
    wait_for_devices i_home_sample_x i_home_sample_y e_abs_sample_z
    foreach {xOn1 yOn1 z_encoder} [get_ion_chamber_counts i_home_sample_x i_home_sample_y e_abs_sample_z] break

    set diffZ [expr $sample_z - $z_encoder]

    ### log first
    if {[catch {
        if {[catch {open sample_z_encoder_log a} ffff]} {
            puts "failed to open sample_z_encoder_log: $ffff"
        } else {
            set ts [clock format [clock seconds] -format "%D-%T"]
            puts $ffff  "$ts diff: $diffZ sample_z: $sample_z encoder: $z_encoder"
            close $ffff
        }
    } eM]} {
        puts "log failed: $eM"
    }
    #########################################
    if {1} {
    #########################################
    if {abs($diffZ) > 3 } {
        log_severe "sample_z $sample_z and encoder $z_encoder diff too much > 3mm"
        abort
        return -code error "sample_z_diff_too_much"
    }

    ### 03/02/11 Mike authorized to correct the motor if it is 1u off.
    if {abs($diffZ) > 0.001} {
        if {abs($diffZ) > 0.05} {
            log_severe "sample_z $sample_z and encoder $z_encoder diff too $diffZ"
        }
        log_warning reseting sample_z to $z_encoder from $sample_z
        set sample_z $z_encoder
        move sample_z to $current_desired_sample_z
        wait_for_devices sample_z
    }
    #########################################
    }
    #########################################

    ################ check xy###############
    if {0} {
        ### never homing, just record drift
        checkSampleXYZDebug
    } else {
        checkSampleXYZ_checkingXY $homing
    }
}
proc checkSampleXYZDebug { } {
    variable checkSampleXBacklash
    variable checkSampleYBacklash
    variable sample_x
    variable sample_y

    set save_x $sample_x
    set save_y $sample_y

    read_ion_chambers 1.0 i_home_sample_x i_home_sample_y
    wait_for_devices i_home_sample_x i_home_sample_y
    foreach {xOn yOn} [get_ion_chamber_counts \
    i_home_sample_x i_home_sample_y] break
    
    set SCAN_WIDTH 0.3
    set SCAN_STEP  0.005
    set SCAN_NUM_STEP 21

    checkSampleXYZ_resetState

    foreach {xPosition yPosition} \
    [checkSampleXYZ_setupScan \
    $xOn $SCAN_WIDTH $SCAN_STEP \
    $yOn $SCAN_WIDTH $SCAN_STEP] break

    if {[catch {
        checkSampleXY_doScan xPosition yPosition
    } errMsg]} {
        move sample_x to $save_x
        move sample_y to $save_y
        wait_for_devices sample_x sample_y
        log_error checkSampleXYZ DEBUG scan failed: $errMsg
        return -code error $errMsg
    }
}
proc checkSampleXYZ_XYOnlyCheck { } {
    variable checkSampleXYZ_TRANSITION_DISTANCE

    variable sample_x
    variable sample_y

    set save_x $sample_x
    set save_y $sample_y

    read_ion_chambers 1.0 i_home_sample_x i_home_sample_y
    wait_for_devices i_home_sample_x i_home_sample_y
    foreach {xOn1 yOn1} \
    [get_ion_chamber_counts i_home_sample_x i_home_sample_y] break

    if {!$xOn1} {
        set dX $checkSampleXYZ_TRANSITION_DISTANCE
    } else {
        set dX -$checkSampleXYZ_TRANSITION_DISTANCE
    }
    if {!$yOn1} {
        set dY -$checkSampleXYZ_TRANSITION_DISTANCE
    } else {
        set dY $checkSampleXYZ_TRANSITION_DISTANCE
    }

    log_warning DEBUG dX=$dX dY=$dY

    move sample_x by $dX
    wait_for_devices sample_x
    read_ion_chambers 1.0 i_home_sample_x
    wait_for_devices i_home_sample_x
    set xOn2 [get_ion_chamber_counts i_home_sample_x]

    move sample_x to $save_x
    move sample_y by $dY
    wait_for_devices sample_x sample_y
    read_ion_chambers 1.0 i_home_sample_y
    wait_for_devices i_home_sample_y
    set yOn2 [get_ion_chamber_counts i_home_sample_y]
    move sample_y to $save_y
    wait_for_devices sample_y

    if {$xOn1 == $xOn2} {
        log_warning DEBUG x not homed $xOn1 == $xOn2
    }
    if {$yOn1 == $yOn2} {
        log_warning DEBUG x not homed $yOn1 == $yOn2
    }
    if {$xOn1 == $xOn2 || $yOn1 == $yOn2} {
        return -code error "sample_xy not at home"
        log_warning homing sample_xy
    }

    return "sample_xy check ok"
}
proc checkSampleXYZ_checkingXY { homing } {
    if {$homing == 11} {
        ###DEBUG
        checkSampleXYZ_homingXY
        return
    }

    if {[catch {
        checkSampleXYZ_XYOnlyCheck
    } errMsg] == 1} {
        if {!$homing} {
            return -code error $errMsg
        }
        log_warning homing sample_xy
        checkSampleXYZ_homingXY
    }
}

proc checkSampleXYZ_homingXY { } {
    variable sample_x
    variable sample_y

    set save_x $sample_x
    set save_y $sample_y

    read_ion_chambers 1.0 i_home_sample_x i_home_sample_y
    wait_for_devices i_home_sample_x i_home_sample_y
    foreach {xOn1 yOn1} \
    [get_ion_chamber_counts i_home_sample_x i_home_sample_y] break

    set range [::config getStr homeswitch.safeScanWidth]
    set step  [::config getStr homeswitch.safeScanStep]

    checkSampleXYZ_resetState

    foreach {xPosition yPosition} \
    [checkSampleXYZ_setupScan \
    $xOn1 $range $step \
    $yOn1 $range $step] break

    if {[catch {
        foreach {xCenter yCenter} \
        [checkSampleXY_doScan xPosition yPosition] break
        move sample_x to $xCenter
        move sample_y to $yCenter
        wait_for_devices sample_x sample_y

        set sample_x 0
        set sample_y 0

    } errMsg]} {
        move sample_x to $save_x
        move sample_y to $save_y
        wait_for_devices sample_x sample_y
        log_error homing sample_xy failed: $errMsg
        return -code error $errMsg
    }
}

#### 12/08/10:
##### Jinhu changed way to calculate center position.
##### Instead of using middle position between transition,
##### now we use the position before transition.
##### This way, next time it will be much faster to find it.
##### It should be found in just one step.
##### The old way may cause next time scanning whole range and
##### found it at the end.


proc checkSampleXY_doScan { xPositionREF yPositionREF } {
    upvar $xPositionREF xList
    upvar $yPositionREF yList

    variable sample_x
    variable sample_y

    set save_x $sample_x
    set save_y $sample_y

    set xHome [list]
    set yHome [list]

    set xFound 0
    set yFound 0

    set xOnFirst -1
    set yOnFirst -1

    foreach {x0 x1} $xList break
    foreach {y0 y1} $yList break

    set xStep [expr $x1 -$x0]
    set yStep [expr $y1 -$y0]

    foreach x $xList {
        move sample_x to $x
        wait_for_devices sample_x
        read_ion_chambers 1.0 i_home_sample_x
        wait_for_devices i_home_sample_x
        set xOn [get_ion_chamber_counts i_home_sample_x]

        if {$xOnFirst < 0} {
            set xOnFirst $xOn
        }
        lappend xHome $xOn
        send_operation_update x: $x h: $xOn
        if {$xOn != $xOnFirst} {
            variable sample_x
            set xFound 1
            #set xCenter [expr $sample_x - 0.5 * $xStep]
            set xCenter [expr $sample_x - $xStep]
            send_operation_update FOUND xCenter=$xCenter
            if {![catch {open checkSampleXYDEBUG.log a} fileHandle]} {
                set ts [clock format [clock seconds] -format "%D-%T"]
                puts $fileHandle [format "%s new centerX=%14.3f" $ts $xCenter]
                close $fileHandle
            }
            break
        }
    }
    move sample_x to $save_x
    wait_for_devices sample_x


    foreach y $yList {
        move sample_y to $y
        wait_for_devices sample_y
        read_ion_chambers 1.0 i_home_sample_y
        wait_for_devices i_home_sample_y
        set yOn [get_ion_chamber_counts i_home_sample_y]

        if {$yOnFirst < 0} {
            set yOnFirst $yOn
        }
        lappend yHome $yOn
        send_operation_update y: $y h: $yOn
        if {$yOn != $yOnFirst} {
            variable sample_y
            set yFound 1
            #set yCenter [expr $sample_y - 0.5 * $yStep]
            set yCenter [expr $sample_y - $yStep]
            send_operation_update FOUND yCenter=$yCenter
            if {![catch {open checkSampleXYDEBUG.log a} fileHandle]} {
                set ts [clock format [clock seconds] -format "%D-%T"]
                puts $fileHandle [format "%s new centerY=%14.3f" $ts $yCenter]
                close $fileHandle
            }
            break
        }
    }
    move sample_y to $save_y
    wait_for_devices sample_y

    if {!$xFound || !$yFound} {
        return -code error check_xy_failed
    }
    return [list $xCenter $yCenter]
}
proc checkSampleXYZ_resetState { } {
    variable checkSampleXBacklash
    variable checkSampleYBacklash

    if {[isDeviceType real_motor sample_x] && \
    [getBacklashEnableValue sample_x] && \
    [getBacklashScaledValue sample_x] < 0} {
        set checkSampleXBacklash 1
    } else {
        set checkSampleXBacklash 0
    }

    if {[isDeviceType real_motor sample_y] && \
    [getBacklashEnableValue sample_y] && \
    [getBacklashScaledValue sample_y] < 0} {
        set checkSampleYBacklash 1
    } else {
        set checkSampleYBacklash 0
    }
}
proc checkSampleXYZ_setupScan { xOn range_x step_x yOn range_y step_y } {
    variable checkSampleXBacklash
    variable checkSampleYBacklash
    variable sample_x
    variable sample_y

    if {$xOn} {
        set x1 [expr $sample_x - $range_x];
        set x2 [expr $sample_x + $step_x]
    } else {
        set x1 [expr $sample_x - $step_x]
        set x2 [expr $sample_x + $range_x];
    }
    if {$yOn} {
        set y1 [expr $sample_y - $step_y]
        set y2 [expr $sample_y + $range_y];
    } else {
        set y1 [expr $sample_y - $range_y];
        set y2 [expr $sample_y + $step_y]
    }

    if {$checkSampleXBacklash} {
        set xStart $x2
        set xEnd   $x1
    } else {
        set xStart $x1
        set xEnd   $x2
    }

    if {$checkSampleYBacklash} {
        set yStart $y2
        set yEnd   $y1
    } else {
        set yStart $y1
        set yEnd   $y2
    }

    adjustPositionToLimit sample_x xStart
    adjustPositionToLimit sample_x xEnd
    adjustPositionToLimit sample_y yStart
    adjustPositionToLimit sample_y yEnd

    set xPosition [list]
    set yPosition [list]

    if {$step_x != 0} {
        set xNumStep [expr (double($xEnd) - $xStart) / $step_x]
        set xNumStep [expr int(ceil(abs($xNumStep)))]
        set xStep    [expr (double($xEnd) - $xStart) / $xNumStep]
        for {set i 0} {$i < $xNumStep} {incr i} {
            lappend xPosition [expr $xStart + $i * $xStep]
        }
        lappend xPosition $xEnd
    }
    if {$step_y != 0} {
        set yNumStep [expr (double($yEnd) - $yStart) / $step_y]
        set yNumStep [expr int(ceil(abs($yNumStep)))]
        set yStep    [expr (double($yEnd) - $yStart) / $yNumStep]
        for {set i 0} {$i < $yNumStep} {incr i} {
            lappend yPosition [expr $yStart + $i * $yStep]
        }
        lappend yPosition $yEnd
    }
    return [list $xPosition $yPosition]
}
