proc ceilingTemperature_initialize { } {
    set_triggers temperatures
}
proc ceilingTemperature_move { - } {
    log_error move not supported
    return -code error NOT_SUPPORTED
}
proc ceilingTemperature_set { - } {
    #config need it success
    #log_error set not supported
    #return -code error NOT_SUPPORTED
}
proc ceilingTemperature_update { } {
    variable temperatures

    return  [lindex $temperatures 2]
}
proc ceilingTemperature_trigger { device_ } {
    update_motor_position ceilingTemperature \
    [ceilingTemperature_update] 1
}
