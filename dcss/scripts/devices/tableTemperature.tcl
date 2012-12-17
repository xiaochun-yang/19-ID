proc tableTemperature_initialize { } {
    set_triggers temperatures
}
proc tableTemperature_move { - } {
    log_error move not supported
    return -code error NOT_SUPPORTED
}
proc tableTemperature_set { - } {
    #config need it success
    #log_error set not supported
    #return -code error NOT_SUPPORTED
}
proc tableTemperature_update { } {
    variable temperatures

    return  [lindex $temperatures 0]
}
proc tableTemperature_trigger { device_ } {
    update_motor_position tableTemperature \
    [tableTemperature_update] 1
}
