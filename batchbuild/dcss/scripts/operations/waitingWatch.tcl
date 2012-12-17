proc waitingWatch_initialize {} {
}

proc waitingWatch_start { } {
    global gVWaitStack

    if {![info exists gVWaitStack]} {
        return not_implmented_on_this_beamline
    }

    set num [llength $gVWaitStack]
    if {$num <= 0} {
        return "no waiting"
    }

    foreach item $gVWaitStack {
        send_operation_update $item
    }
    return "total: $num"
}
