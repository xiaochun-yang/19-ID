#this operation is for scripted ion chamber
proc temperatureOp_initialize {} {
}

proc temperatureOp_start { time_in_second } {
    variable temperatures
    return $temperatures
}
