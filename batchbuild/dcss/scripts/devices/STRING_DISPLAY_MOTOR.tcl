proc PREFIXMotor_initialize { } {
    set_triggers PREFIX 
}
proc PREFIXMotor_move { - } {
    log_error PREFIXMotor is for display only, no move
    return -code error not_supported
}
proc PREFIXMotor_set { - } {
    log_error PREFIXMotor is for display only, no set
    return -code error not_supported
}
proc PREFIXMotor_update { } {
    variable PREFIX
    return $PREFIX
}
proc PREFIXMotor_trigger { triggerDevice_ } {
    variable PREFIX
    update_motor_position PREFIXMotor $PREFIX
}
