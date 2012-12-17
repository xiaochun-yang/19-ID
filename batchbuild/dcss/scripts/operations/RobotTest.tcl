package require Itcl

proc RobotTest_initialize {} {
}
proc RobotTest_start { what_to_wait numloop } {
    if { [catch {
	   #wait for the beamline state to be open
        log_warning "Waiting for the beamline to open."

        wait_for_string_contents beamlineOpenState $what_to_wait
    } errorResult] } {
       #continue on with epics and assume that the beamline is open
       log_error "Error talking to spear: $errorResult"
    }
        
    set tick_start [clock clicks -milliseconds]
    for {set i 0} {$i < $numloop} {incr i} {
        set tick_now [clock clicks -milliseconds]
        send_operation_update "update from Robottest $i ms: [expr $tick_now - $tick_start]"
    }
}
