proc stringUpdate_initialize { } {
}
proc stringUpdate_start { name } {
    if {![isString $name]} {
        log_error $name is not a dcs string
        return -code error NOT_A_STRING
    }
    variable $name

    set mm [set $name]

    log_note sending $name=$mm
    set $name $mm
    return $mm
}
