#this operation is for scripted ion chamber
proc sumSpectrum_initialize {} {
}

proc sumSpectrum_start { time_in_second } {
    return [excitationScan_start 0 25000 1 "" $time_in_second]
}
