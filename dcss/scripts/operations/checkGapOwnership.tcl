#this operation is for scripted ion chamber
proc checkGapOwnership_initialize {} {
}

proc checkGapOwnership_start { } {
    if {![motor_exists undulator_gap]} {
        log_error motor undulator_gap not exists
        return -code error "no gap motor"
    }
    undltrRequestOwner
}
