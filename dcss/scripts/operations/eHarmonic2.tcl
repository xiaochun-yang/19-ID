#this operation is for scripted ion chamber
proc eHarmonic2_initialize {} {
}

proc eHarmonic2_start { time_in_second } {
    return [peakEnergy_start $time_in_second 2]
}
