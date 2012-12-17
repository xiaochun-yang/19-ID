#this operation is for scripted ion chamber
proc daqDigitalIon_initialize {} {
}

proc daqDigitalIon_start { time_in_second } {
    set handle [start_waitable_operation getDig 0]
    set result [wait_for_operation_to_finish $handle]
    #log_note daqDigitalIon: $result

    set dataOnly [lrange $result 1 end]
    return $dataOnly
}
