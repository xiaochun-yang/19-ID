#this operation is for scripted ion chamber
proc moveMotors_initialize {} {
}

proc moveMotors_start { serialMove args } {
    #puts "+moveMotors_start $serialMove $args"

    set client_id [get_client_id]
    #check 
    foreach motor $args {
        set motor_name [lindex $motor 0]
        if {![isMotor $motor_name]} {
            return -code error "$motor_name is not a motor"
        }
        set permit [check_device_permit $client_id $motor_name]
        if {$permit != "GRANTED"} {
            log_error cannot move $motor: $permit
            return -code error "check permit failed for $motor_name: $permit"
        }
    }

    set waitList ""
    foreach motor $args {
        set motor_name [lindex $motor 0]
        if {$motor_name != ""} {
            set command "move $motor"
            #puts "command: $command"
            eval $command
            if {$serialMove} {
                wait_for_devices $motor_name
            } else {
                lappend waitList $motor_name
            }
        }
    }
    if {$waitList != ""} {
        eval wait_for_devices $waitList
    }

    #puts "-moveMotors_start"
}
