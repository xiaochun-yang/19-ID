#this operation is for scripted ion chamber
proc bw_tungsten_initialize {} {
}

proc bw_tungsten_start { time_in_second } {
    set startE 7762
    set endE   10062
    log_note "bandwidth for Tungsten: Start: $startE End: $endE"

    return [excitationScan_start $startE $endE 1 "" $time_in_second]
}
