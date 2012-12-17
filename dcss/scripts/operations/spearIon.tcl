#this operation is for scripted ion chamber
proc spearIon_initialize {} {
}

proc spearIon_start { time_ignored } {
    set h [start_waitable_operation getEPICSPV SPEAR:BeamCurrAvg1S]
    set result [wait_for_operation_to_finish $h 2000]
    return [lindex $result 1]
}
