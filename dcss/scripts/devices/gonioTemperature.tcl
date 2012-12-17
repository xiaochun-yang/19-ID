proc gonioTemperature_initialize { } {
    set_triggers temperatures
}
proc gonioTemperature_move { - } {
    log_error move not supported
    return -code error NOT_SUPPORTED
}
proc gonioTemperature_set { - } {
    #config need it success
    #log_error set not supported
    #return -code error NOT_SUPPORTED
}
proc gonioTemperature_update { } {
    variable temperatures

    return  [lindex $temperatures 1]
}
proc gonioTemperature_trigger { device_ } {
    update_motor_position gonioTemperature \
    [gonioTemperature_update] 1
}
