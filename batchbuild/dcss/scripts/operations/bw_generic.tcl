#this operation is for scripted ion chamber
proc bw_generic_initialize {} {
}

proc bw_generic_start { time_in_second } {
    variable bw_generic_const

    set startE [lindex $bw_generic_const 0]
    set endE   [lindex $bw_generic_const 1]
    if {![string is double -strict $startE]} {
        log_error wrong startE in bw_generic_const
        return -code error "wrong_startE_in_bw_generic_const"
    }
    if {![string is double -strict $endE]} {
        log_error wrong endE in bw_generic_const
        return -code error "wrong_endE_in_bw_generic_const"
    }
    if {$startE > $endE} {
        set tmp $startE
        set startE $endE
        set endE $tmp
    }

    log_note "bandwidth for generic: Start: $startE End: $endE"

    return [excitationScan_start $startE $endE 1 "" $time_in_second]
}
