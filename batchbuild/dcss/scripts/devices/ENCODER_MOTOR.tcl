proc PREFIX_encoder_motor_initialize {} {
    set_children PREFIX
}

proc PREFIX_encoder_motor_move { eNew } {
    variable PREFIX
    global gDevice

    set maxTry 1
    set stepSize 1.0
    if {[isDeviceType real_motor PREFIX]} {
        set stepSize [expr 0.5 / $gDevice(PREFIX,scaleFactor)] 
        set maxTry 3
    }

    for {set i 0} {$i < $maxTry} {incr i} {
        get_encoder PREFIX_encoder
        set eCur [wait_for_encoder PREFIX_encoder]
        set diff [expr $eNew - $eCur]
        if {$i > 0} {
            if {abs($diff) < abs($stepSize)} {
                break
            } else {
                log_warning trying to get more accuracy.
            }
        }
        if {[catch {
            move PREFIX by $diff
            wait_for_devices PREFIX
        } errMsg]} {
            after 200
        }
    }
    puts "end of move encoder_motor PREFIX"
}

proc PREFIX_encoder_motor_set { eNew } {
    log_error cannot set encoder motor.
    return -code error CANNOT_SET
}

proc PREFIX_encoder_motor_update {} {
    global gDevice
    if {$gDevice(PREFIX_encoder,status) == "inactive"} {
        ### ignore abort
        get_encoder PREFIX_encoder 1
    }
    set eCur [wait_for_encoder PREFIX_encoder]

    return $eCur
}

proc PREFIX_encoder_motor_calculate { dz } {
    return [PREFIX_encoder_motor_update]
}

##### mew feature, will be populated to all scripted motors
proc PREFIX_encoder_motor_childrenLimitsOK { eNew {quiet 0}} {
    variable PREFIX
    global gDevice

    get_encoder PREFIX_encoder
    set eCur [wait_for_encoder PREFIX_encoder]
    set diff [expr $eNew - $eCur]

    set mNew [expr $PREFIX + $diff]
    if {$quiet} {
        return [limits_ok_quiet PREFIX $mNew]
    } else {
        return [limits_ok PREFIX $mNew]
    }
}
