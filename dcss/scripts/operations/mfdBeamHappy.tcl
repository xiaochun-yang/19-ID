proc mfdBeamHappy_initialize { } {
    namespace eval ::mfdBeamHappy {
        set BOARD -1
        set CHANNEL -1

        set cfg [::config getStr beam_happy]
        foreach {BOARD CHANNEL} $cfg break
    }
}
proc mfdBeamHappy_start { time_in_second } {
    variable ::mfdBeamHappy::BOARD
    variable ::mfdBeamHappy::CHANNEL

    if {$BOARD < 0 || $CHANNEL <0} {
        return -code error "beam_happy not define in config file"
    }

    set h [start_waitable_operation waitDigInBit \
    $BOARD $CHANNEL 1 $time_in_second]

    set r [wait_for_operation_to_finish $h]

    return $r
}
