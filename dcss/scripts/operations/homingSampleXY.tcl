proc homingSampleXY_initialize { } {
    variable homingSampleXY_HOME_WIDTH_MIN
    variable homingSampleXY_HOME_WIDTH_MAX

    set homingSampleXY_HOME_WIDTH_MIN -1
    set homingSampleXY_HOME_WIDTH_MAX -1
    set cfgVHR [::config getStr homeswitch.validHomeRange]
    foreach {onMin onMax} $cfgVHR break

    if {[string is double -strict $onMin] && \
    [string is double -strict $onMax]} {
        if {$onMin < $onMax} {
            set homingSampleXY_HOME_WIDTH_MIN $onMin
            set homingSampleXY_HOME_WIDTH_MAX $onMax
        } else {
            set homingSampleXY_HOME_WIDTH_MIN $onMax
            set homingSampleXY_HOME_WIDTH_MAX $onMin
        }
    }

    homingSampleXY_resetState
}
### center it
####################################
### the scan normally go from low to high unless it causes backlash
###
### it will treat the limit as edge if home found but the edge is out of range
###
### it will restore the positions if home not found OR home range is too big

proc homingSampleXY_start { xOn range_x step_x yOn range_y step_y {save_data 0}} {
    variable sample_x
    variable sample_y
    variable homingSampleXY_saveData

    set homingSampleXY_saveData $save_data

    set save_x $sample_x
    set save_y $sample_y

    homingSampleXY_resetState

    foreach {xPosition yPosition} \
    [homingSampleXY_setupScan $xOn $range_x $step_x $yOn $range_y $step_y] break

    puts "xPosition: $xPosition"
    puts "yPosition: $yPosition"

    if {[catch {
        foreach {xHome yHome xCenter yCenter} [homingSampleXY_doScan xPosition yPosition] break
    } errMsg]} {
        move sample_x to $save_x
        move sample_y to $save_y
        wait_for_devices sample_x sample_y
        log_error homing sample xyz failed: $errMsg
        return -code error $errMsg
    }

    move sample_x to $xCenter
    move sample_y to $yCenter
    wait_for_devices sample_x sample_y

    set xOffset [expr $xCenter - $save_x]
    set yOffset [expr $yCenter - $save_y]
    send_operation_update offset: x: $xOffset y: $yOffset

    if {$sample_x != 0} {
        set sample_x 0
    }
    if {$sample_y != 0} {
        set sample_y 0
    }

    if {[catch {open homingSampleXY_reset.log a} fileHandle]} {
        log_error "failed to open log file for homingSampleXY"
    } else {
        set timeStamp [clock format [clock seconds] -format "%D-%T"]
        puts $fileHandle [list $timeStamp $xOffset $yOffset]
        close $fileHandle
    }
}
proc homingSampleXY_resetState { } {
    variable homingSampleXBacklash
    variable homingSampleYBacklash

    if {[isDeviceType real_motor sample_x] && \
    [getBacklashEnableValue sample_x] && \
    [getBacklashScaledValue sample_x] < 0} {
        set homingSampleXBacklash 1
    } else {
        set homingSampleXBacklash 0
    }

    if {[isDeviceType real_motor sample_y] && \
    [getBacklashEnableValue sample_y] && \
    [getBacklashScaledValue sample_y] < 0} {
        set homingSampleYBacklash 1
    } else {
        set homingSampleYBacklash 0
    }
}
proc homingSampleXY_setupScan { xOn range_x step_x yOn range_y step_y } {
    variable homingSampleXBacklash
    variable homingSampleYBacklash
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

    if {$homingSampleXBacklash} {
        set xStart $x2
        set xEnd   $x1
    } else {
        set xStart $x1
        set xEnd   $x2
    }

    if {$homingSampleYBacklash} {
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
proc homingSampleXY_doScan { xPositionREF yPositionREF } {
    upvar $xPositionREF xList
    upvar $yPositionREF yList

    variable homingSampleXY_saveData

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


    foreach x $xList y $yList {
        if {$xFound && $yFound} {
            break
        }
        set mList ""

        if {$x != ""} {
            move sample_x to $x
            lappend mList sample_x
        }
        if {$y != ""} {
            move sample_y to $y
            lappend mList sample_y
        }
        eval wait_for_devices $mList
        read_ion_chambers 1.0 i_home_sample_x i_home_sample_y
        wait_for_devices i_home_sample_x i_home_sample_y
        foreach {xOn yOn} [get_ion_chamber_counts i_home_sample_x i_home_sample_y] break

        if {$xOnFirst < 0} {
            set xOnFirst $xOn
        }
        if {$yOnFirst < 0} {
            set yOnFirst $yOn
        }

        if {$x != ""} {
            lappend xHome $xOn
            send_operation_update x: $x h: $xOn
        }
        if {$y != ""} {
            lappend yHome $yOn
            send_operation_update y: $y h: $yOn
        }
        if {$xOn != $xOnFirst && !$xFound} {
            variable sample_x
            set xFound 1
            set xCenter [expr $sample_x - 0.5 * $xStep]
            send_operation_update FOUND xCenter=$xCenter
        }
        if {$yOn != $yOnFirst && !$yFound} {
            variable sample_y
            set yFound 1
            set yCenter [expr $sample_y - 0.5 * $yStep]
            send_operation_update FOUND yCenter=$yCenter
        }
    }
    if {$homingSampleXY_saveData} {
        set filename homingSampleXY[clock format [clock seconds] \
        -format "%d%b%y%H%M%S"].scan

        if {![catch {open $filename w} fileHandle]} {
            foreach x $xList xh $xHome {
                if {$x == "" || $xh == ""} {
                    break
                }
                puts $fileHandle [format "X %14.3f %.0f" $x $xh]
            }
            foreach y $yList yh $yHome {
                if {$y == "" || $yh == ""} {
                    break
                }
                puts $fileHandle [format "Y %14.3f %.0f" $y $yh]
            }
            close $fileHandle
        }
    }
    if {!$xFound || !$yFound} {
        return -code error homing_xy_failed
    }
    return [list $xHome $yHome $xCenter $yCenter]
}
