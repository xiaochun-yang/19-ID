proc motorInfo_initialize { } {
}

proc motorInfo_start { motor } {
    if {![isMotor $motor]} {
        log_error $motor is not a motor
        return -code error "$motor_is_not_a_motor"
    }

    global gDevice

    set nameList [array names gDevice $motor,*]

    foreach name $nameList {
        send_operation_update $name=$gDevice($name)
    }
}
