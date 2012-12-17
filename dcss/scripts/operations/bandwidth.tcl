#this operation is for scripted ion chamber
proc bandwidth_initialize {} {
}

proc bandwidth_start { time_in_second } {
    global gDevice
    
    set startE [expr $gDevice(energy,scaled) - 300.0]
    set endE [expr $gDevice(energy,scaled) + 300.0]

    log_note "bandwidth: E: $gDevice(energy,scaled) Start: $startE End: $endE"
    
    return [excitationScan_start $startE $endE 1 "" $time_in_second]
}
