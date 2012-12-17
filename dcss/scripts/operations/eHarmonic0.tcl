#this operation is for scripted ion chamber
proc eHarmonic0_initialize {} {
}

proc eHarmonic0_start { time_in_second } {
    return [peakEnergy_start $time_in_second 0]
}
