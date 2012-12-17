#this operation is for scripted ion chamber
proc moveEncoders_initialize {} {
}

proc moveEncoders_start { serialMove args } {
    #puts "+moveEncoders_start $serialMove $args"

    set client_id [get_client_id]
    set fullList  [eval moveEncoders_expandList $args]
    moveEncoders_checkInput $client_id $fullList

    set timeToTry 4
    if {[llength $serialMove] > 1} {
        set retry [lindex $serialMove 1]
        set serialMove [lindex $serialMove 0]

        if {$retry >= 0} {
            set timeToTry [expr $retry + 1]
        }
        puts "set timetoTry to $timeToTry"
        puts "serialMove=$serialMove"
    }

    for {set i 0} {$i < $timeToTry} {incr i} {
        set moveCmdList [moveEncoders_generateMoveCmd $fullList]
        if {[llength $moveCmdList] <= 0} {
            ### done
            return
        }
        eval moveMotors_start $serialMove $moveCmdList
    }
    log_warning some encoders not reach desired position
    ### warning only
    moveEncoders_generateMoveCmd $fullList 1
    
    #puts "-moveEncoders_start"
}
proc moveEncoders_expandList { args } {
    set result ""
    foreach cmd $args {
        foreach {e_m position} $cmd break
        set ll [llength $e_m]
        if {$ll > 1} {
            set encoder [lindex $e_m 0]
            set motor   [lindex $e_m 1]
        } elseif {$ll == 1} {
            ## e_m === "sample_z_encoder"
            ## motor=  "sample_z"
            set encoder $e_m
            set motor [string range $e_m 0 end-8]
        } else {
            ### skip empty
            continue
        }
        set nCmd [list $encoder $motor $position]
        lappend result $nCmd
    }
    #send_operation_update "full list: $result"
    return $result
}
proc moveEncoders_checkInput { client_id expandedList } {
    foreach cmd $expandedList {
        foreach {e m p} $cmd break
        if {![isEncoder $e]} {
            log_error $e is not an encoder
            return -code error "$e is not an encoder"
        }
        if {![isMotor $m]} {
            log_error $m is not a motor
            return -code error "$m is not a motor"
        }
        set permit [check_device_permit $client_id $m]
        if {$permit != "GRANTED"} {
            log_error cannot move $m: $permit
            return -code error "check permit failed for $m: $permit"
        }
        ### we will check p while we generate move commands.
    }
}
proc moveEncoders_generateMoveCmd { expandedList {warning_only 0}} {
    global gDevice

    set result ""
    foreach cmd $expandedList {
        foreach {e m p} $cmd break
        get_encoder $e
    }
    foreach cmd $expandedList {
        foreach {e m p} $cmd break
        set eCur [wait_for_encoder $e]
        set diff [expr $p - $eCur]
        if {[isDeviceType real_motor $m]} {
            #set stepSize [expr 1.0 / $gDevice($m,scaleFactor)]
            set stepSize [expr 0.5 / $gDevice($m,scaleFactor)]
        } else {
            set stepSize 0.001
        }
        if {abs($diff) >= $stepSize} {
            if {$warning_only} {
                log_warning encoder $e at $eCur diff $diff
            } else {
                variable $m
                set mCur [set $m]
                set mDest [expr $mCur + $diff]
                assertMotorLimit $m $mDest
                set mCmd [list $m to $mDest]
                lappend result $mCmd
            }
        }
    }
    #send_operation_update "moveCmd: $result"
    return $result
}
