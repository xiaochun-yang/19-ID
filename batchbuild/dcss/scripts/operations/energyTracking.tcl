proc energyTracking_initialize { } {
    variable energyTrackingBUILDIN
    set energyTrackingBUILDIN [list energy mono_theta]
}
proc energyTracking_start { cmd args } {
    variable energyTrackingFileName
    variable energyTrackingMotorList
    switch -exact $cmd {
        initialize {
            eval energyTrackingSetMotorList $args
        }
        print_file_name {
            log_note file_name: $energyTrackingFileName
            send_operation_update "filename: $energyTrackingFileName"
        }
        print_motor_list {
            log_note motor_list: $energyTrackingMotorList
            send_operation_update "motor list: $energyTrackingMotorList"
        }
        print_point -
        print_points {
            energyTrackingPrintPoints
        }
        save_point {
            energyTrackingSavePoint
        }
        fit {
            energyTrackingFit [lindex $args 0]
        }
        debug_set_file {
            energyTrackingSetFile [lindex $args 0]
        }
        default {
            log_error not supported command $cmd
        }
    }
}
proc energyTrackingSetMotorList { args } {
    variable energyTrackingBUILDIN
    variable energyTrackingFileName
    variable energyTrackingMotorList

    ##### check arguments
    if {[llength $args] < 1} {
        log_error need motor name list for energy moving
        return -code error "empty children motor list"
    }

    set anyError 0
    foreach m $args {
        if {![isMotor $m]} {
            log_error $m is not a motor
            set anyError 1
        }
    }
    if {$anyError} {
        return -code error "must be all motors"
    }

    ##############################
    #### generate new data file
    ##############################
    set TS [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set energyTrackingFileName [file normalize eTracking_$TS.txt]
    set energyTrackingMotorList $args

    if {[catch {open $energyTrackingFileName w} h]} {
        log_error open file $energyTrackingFileName failed: $h
        return -code error $h
    }

    set header "TimeStamp,energy,mono_theta"
    set header [format "%17s" TimeStamp]

    foreach m $energyTrackingBUILDIN {
        set item [format ",%20s" $m]
        append header $item
    }

    foreach m $energyTrackingMotorList {
        set item [format ",%20s" $m]
        append header $item
    }
    puts $h $header
    close $h

    send_operation_update "energy tracking data file: $energyTrackingFileName"
    send_operation_update $header
}
proc energyTrackingPrintPoints { } {
}
proc energyTrackingSavePoint { } {
    variable energyTrackingBUILDIN
    variable energyTrackingFileName
    variable energyTrackingMotorList

    if {![info exists energyTrackingFileName] || \
    ![info exists energyTrackingMotorList]} {
        log_error need set motor list first
        return -code error "not initialized yet"
    }
    
    #### generate the line
    set line [clock format [clock second] -format "%D-%T"]
    foreach m $energyTrackingBUILDIN {
        set item [format ",%20.6f" [getScaledValue $m]]
        append line $item
    }

    foreach m $energyTrackingMotorList {
        set item [format ",%20.6f" [getScaledValue $m]]
        append line $item
    }

    ### append to the file
    if {[catch {open $energyTrackingFileName a} h]} {
        log_error open file $energyTrackingFileName failed: $h
        return -code error $h
    }

    puts $h $line
    close $h

    log_note $line
    send_operation_update $line
}
proc energyTrackingFit { order } {
    variable energyTrackingBUILDIN
    variable energyTrackingFileName
    variable energyTrackingMotorList

    if {$order == 3} {
        set fitCmd poly3rdFit
    } else {
        set order 5
        set fitCmd poly5thFit
    }

    ##### reading all the data
    if {[catch {open $energyTrackingFileName r} h]} {
        log_error open file $energyTrackingFileName failed: $h
        return -code error $h
    }
    set header [gets $h]
    set header [string map [list " " {}] $header]

    set headerL [split $header ,]

    set llHeader [llength $headerL]

    set motorList [lrange $headerL 2 end]

    set num 0
    while {![eof $h]} {
        incr num
        set line [gets $h]
        set line [string map [list " " {}] $line]
        set lineL [split $line ,]
        set llLine [llength $lineL]
        if {$llLine == 0} {
            continue
        }

        if {$llHeader != $llLine} {
            log_error line $num not match header
            log_error header: $llHeader contents: $header
            log_error line  : $llLine contents: $line
            break
        }
        set valueList [lrange $lineL 2 end]
        foreach m $motorList v $valueList {
            lappend data($m) $v
        }
    }
    close $h

    if {$num < $order} {
        log_error too few data points to fit
        return -code error "too few data points to fit"
    }

    ###############FIT################
    set base [lindex $motorList 0]
    set child_motorList [lrange $motorList 1 end]
    if {$child_motorList != $energyTrackingMotorList} {
        log_warning motor list from file not match with motor list from system.
        log_warning from file:   $child_motorList
        log_warning from system: $energyTrackingMotorList
    }

    foreach cm $child_motorList {
        set fit($cm) [$fitCmd $data($base) $data($cm)]
    }

    #####write out file ####
    set TS [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set outFileName "energyTracking_$TS.tcl"
    if {[catch {open $outFileName w} outh]} {
        log_error open file $outFileName failed: $outh
        return -code error $outh
    }
    if {$order == 3} {
        foreach cm $child_motorList {
            foreach {a b c d maxAbsError} $fit($cm) break
            puts $outh "proc energy_calculate_$cm { mt } {"
            puts $outh "    set a $a"
            puts $outh "    set b $b"
            puts $outh "    set c $c"
            puts $outh "    set d $d"
            puts $outh "    ### max abs error: $maxAbsError"
            puts $outh ""
            puts $outh "    return \[expr \\"
            puts $outh "    \$a + \\"
            puts $outh "    \$b * \$mt + \\"
            puts $outh "    \$c * \$mt * \$mt + \\"
            puts $outh "    \$d * \$mt * \$mt * \$mt \\"
            puts $outh "    \]"
            puts $outh "}"
        }
    } else {
        foreach cm $child_motorList {
            foreach {a b c d e f maxAbsError} $fit($cm) break
            puts $outh "proc energy_calculate_$cm { mt } {"
            puts $outh "    set a $a"
            puts $outh "    set b $b"
            puts $outh "    set c $c"
            puts $outh "    set d $d"
            puts $outh "    set e $e"
            puts $outh "    set f $f"
            puts $outh "    ### max abs error: $maxAbsError"
            puts $outh ""
            puts $outh "    return \[expr \\"
            puts $outh "    \$a + \\"
            puts $outh "    \$b * \$mt + \\"
            puts $outh "    \$c * \$mt * \$mt + \\"
            puts $outh "    \$d * \$mt * \$mt * \$mt + \\"
            puts $outh "    \$e * \$mt * \$mt * \$mt * \$mt + \\"
            puts $outh "    \$f * \$mt * \$mt * \$mt * \$mt * \$mt \\"
            puts $outh "    \]"
            puts $outh "}"
        }
    }
    close $outh
    send_operation_update energy_tracking file: [file normalize $outFileName]
}
proc energyTrackingSetFile { filename } {
    variable energyTrackingFileName
    variable energyTrackingMotorList

    set energyTrackingFileName $filename
    if {[catch {open $energyTrackingFileName r} h]} {
        log_error open file $energyTrackingFileName failed: $h
        return -code error $h
    }
    set header [gets $h]
    set header [string map [list " " {}] $header]
    close $h

    set headerL [split $header ,]

    set energyTrackingMotorList [lrange $headerL 3 end]

    send_operation_update file set to $energyTrackingFileName
    send_operation_update motor list set to $energyTrackingMotorList
}
