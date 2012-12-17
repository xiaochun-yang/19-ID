#this operation is for scripted ion chamber
proc bw_nickel_initialize {} {
}

proc bw_nickel_start { time_in_second } {
    set startE 7100 
    set endE 7700
    log_note "bandwidth for Nickel: Start: $startE End: $endE"

    return [excitationScan_start $startE $endE 1 "" $time_in_second]
}
