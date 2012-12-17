proc getGapTaper_initialize { } {
}
proc getGapTaper_start { time_in_seconds } {
    set h [start_waitable_operation getEPICSPV BL12-2:Taper]
    set result [wait_for_operation_to_finish $h]
    ### remove the first field "normal"
    return [lrange $result 1 end]
}
