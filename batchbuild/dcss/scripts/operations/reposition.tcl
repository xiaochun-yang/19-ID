proc reposition_initialize { } {
}
proc reposition_check_permission { } {
    set client_id [get_client_id]

    foreach name {reposition_phi reposition_x reposition_y reposition_z} {
        #check name
        if {![motor_exists $name]} {
            return -code error "bad motor name {$name}"
        }

        #check permit
        set permitCheck [check_device_permit $client_id $name]
        if {$permitCheck != "GRANTED"} {
            return -code error "permit check failed: $permitCheck"
        }
    }
}

proc reposition_start { cmd args } {
    switch -exact -- $cmd {
        reset {
            resetReposition
        }
        use_current {
            setRepositionCurrent
        }
        move {
            if {[llength $args] < 4} {
                log_error reposition phi x y z
                return -code error wrong_argument
            }
            reposition_check_permission
            foreach {phi x y z} $args break
            repositionMove $phi $x $y $z
        }
        default {
            log_error unsupported command "{$cmd}"
            log_error reposition reset|use_current|move phi x y z
            return -code error unsupported_command
        }
    }
}
