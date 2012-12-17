#this operation is for scripted ion chamber
proc daqIon2_initialize {} {
}

proc daqIon2_start { time_in_second } {
    set time_in_ms [expr 1000.0 * $time_in_second]

    set handle [start_waitable_operation readDaq 2 $time_in_ms]

    set result [wait_for_operation_to_finish $handle]
    #log_note daq_ion: $result

    set dataOnly [lrange $result 1 end]
    return $dataOnly
}
