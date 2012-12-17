#this operation is for scripted ion chamber
proc eHarmonic1_initialize {} {
}

proc eHarmonic1_start { time_in_second } {
    return [peakEnergy_start $time_in_second 1]
}
