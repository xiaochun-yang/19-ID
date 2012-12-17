#this operation is for scripted ion chamber
proc gapHarmonic_initialize {} {
}

proc gapHarmonic_start { time_in_second } {
    return [peakGap_start $time_in_second]
}
