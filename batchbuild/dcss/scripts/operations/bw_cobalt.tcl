#this operation is for scripted ion chamber
proc bw_cobalt_initialize {} {
}

proc bw_cobalt_start { time_in_second } {
    set startE 6630
    set endE 7230
    log_note "bandwidth for Cobalt: Start: $startE End: $endE"

    return [excitationScan_start $startE $endE 1 "" $time_in_second]
}
