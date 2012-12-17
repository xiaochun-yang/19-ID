proc optimizeMotor_initialize {} {
    variable optimizeMotorFileHandle
    set optimizeMotorFileHandle ""
}

####will be called at the end of operation (both success or failure)
proc optimizeMotor_cleanup { } {
    variable optimizeMotorFileHandle
    if {$optimizeMotorFileHandle != ""} {
        if {[catch {close $optimizeMotorFileHandle} errMsg]} {
            puts "failed to close optimizeMotorFileHandle: $optimizeMotorFileHandle: $errMsg"
        }
        set optimizeMotorFileHandle ""
        log_warning closed optimizeMotor log file.
    }
}

proc optimizeMotor_start { motor centerPosition detector points step time flux wmin wmax glc grc } {
    variable optimizeMotorFileHandle
    variable $motor

    optimizeMotor_cleanup

    #########################
    # initialize arrays
    set positions {}
    set counts {}

    # calculate starting position
    set start [expr $centerPosition - $step * ($points - 1) / 2.0]
    set end   [expr $centerPosition + $step * ($points - 1) / 2.0]

    log_warning DEBUG step=$step points=$points center=$centerPosition start=$start

    set saveScan [expr [file exists ../tmp/SAVE_ALL] || \
    [file exists ../tmp/SAVE_$motor]]

    if {$saveScan} {
        set ts [clock format [clock seconds] -format "%d%b%y%H%M%S"]
        set fileName ../tmp/scan${motor}_${ts}.scan
        if {[catch {open $fileName w} optimizeMotorFileHandle]} {
            puts "open scan log $fileName failed: $optimizeMotorFileHandle"
            set optimizeMotorFileHandle ""
        } else {
            global gDevice
            set units $gDevice($motor,scaledUnits)
            set contents ""
            append contents \
            "# file       $fileName [pwd] [file root $fileName] 0\n"
            append contents "# date       [time_stamp]\n"
            append contents \
            "# motor1     $motor $points $start $end $step $units\n"
            append contents "# motor2     \n"
            append contents "# detectors  i2\n"
            append contents "# filters    \n"
            append contents "# timing     $time 0.0 1 0.0 s\n"
            append contents "\n"
            append contents "\n"
            append contents "\n"

            puts $optimizeMotorFileHandle $contents
            flush $optimizeMotorFileHandle
        }
    }

    # move motor to starting position
    move $motor to $start 
    # wait for ion chamber to become inactive and motor to reach start position
    wait_for_devices $motor $detector

    # loop over points
    for { set point 0 } { $point < $points } { incr point } {
        send_operation_update "doing [expr $point + 1] of $points"

	    # move motor to next position
	    set position  [expr $start + $point * $step]
	    move $motor to $position 
	    wait_for_devices $motor

	    # count on the ion chamber
	    read_ion_chambers $time $detector
	    wait_for_devices $detector
	    set count [get_ion_chamber_counts $detector ]

        if {$optimizeMotorFileHandle != ""} {
            puts $optimizeMotorFileHandle "$position $count"
            flush $optimizeMotorFileHandle
        }
	
	    # store position and ion chamber reading in arrays
        if {$step >= 0.0} {
	        lappend positions $position
	        lappend counts $count
        } else {
            set positions [linsert $positions 0 $position]
            set counts    [linsert $counts 0 $count]
        }
    }
    if {$optimizeMotorFileHandle != ""} {
        close $optimizeMotorFileHandle
        set optimizeMotorFileHandle ""
    }
    
    # try to open file for append 	
    if {[catch {open ../tmp/optimize$motor.log a} optimizeMotorFileHandle]} {
        set optimizeMotorFileHandle ""
	    log_error "Error opening optimize$motor.log: $optimizeMotorFileHandle"
        set optimizeMotorFileHandle ""
    } else {
        puts $optimizeMotorFileHandle "[time_stamp] Maximizing: $motor"
        puts $optimizeMotorFileHandle [concat $positions]
        puts $optimizeMotorFileHandle [concat $counts]
    }

    send_operation_update \
    "analyzePeak $positions $counts $flux $wmin $wmax .15 $glc $grc 1"
    if { [catch {set result [analyzePeak $positions $counts $flux $wmin $wmax .15 $glc $grc 1]} errorResult] } {

        if {$optimizeMotorFileHandle != ""} {
	        puts $optimizeMotorFileHandle \
            "[time_stamp] Error Maximizing: $errorResult"
	        puts $optimizeMotorFileHandle ""
            close $optimizeMotorFileHandle
            set optimizeMotorFileHandle ""
        }
	
	    return -code error $errorResult
    }
    send_operation_update "analyzePeakResult: $result"

    # write optimized position to log	
    set optimalValue [lindex $result 0]
    if {$motor == "sample_x" || $motor == "sample_y" || $motor == "sample_z" || $motor == "table_slide" || $motor == "slit_1_horiz" || $motor == "table_horz"} {
	set optimalValue [expr ([lindex $result 2] + [lindex $result 3])/2]
    }	
    if {$optimizeMotorFileHandle != ""} {
        puts $optimizeMotorFileHandle \
        "[time_stamp] Optimal Value = $optimalValue"
        puts $optimizeMotorFileHandle ""
        close $optimizeMotorFileHandle
        set optimizeMotorFileHandle ""
    }
    return $optimalValue
}
