### SPEAR now uses gapReady to indicate gap is ready and we have the ownership.

proc 19id_gap_initialize {} {
    variable gapStartedByUs
    variable gapWaitingState
    global   gGapMoveDoneFlag

    set gapStartedByUs 0
    set gapWaitingState none
    set gGapMoveDoneFlag 0

	#set_triggers gap gapRequestDrvH gapRequestDrvL gapReady gapStatus gapOwner
    ### hook to itself and energy to check sync
	set_triggers gap gapStatus

    registerAbortCallback 19id_gap_abort
}

proc 19id_gap_move { pos } {
    variable gapRequest
    variable gapStatus
    variable gapStartedByUs
    variable gapWaitingState
    variable gap
    global   gGapMoveDoneFlag
    ### this is a workaround in case spear will not cycle gapStatus when there is no real move.
    if {abs($gap - $pos) < 0.001} {
        return
    }


    set gapStartedByUs 1

#    undltrCheckReady 1

    set gGapMoveDoneFlag 0
    set gapWaitingState wait_for_0
    set gapRequest $pos
    vwait gGapMoveDoneFlag

puts "yangx 3"
    ### change to yours.
    #if {$gapStatus != "Stopped" && $gapStatus != "Move too small"} {
    #    regsub -all {[[:space:]]} $gapStatus _ oneWord
    #    return -code error $oneWord
    #}

    set diffFromDesired [expr abs($gap - $pos)]
    if {$diffFromDesired > 0.002} {
        wait_for_time 1000
        set newDiff [expr abs($gap - $pos)]
        if {$newDiff < $diffFromDesired} {
            log_severe after extra waiting for 1 second, undulator diff reduced to $newDiff from $diffFromDesired
            set diffFromDesired $newDiff
        }
    }
    #original 0.020
    if {$diffFromDesired > 0.52} {
        log_severe gap $gap not reach the desired position $pos
        return -code error move_gap_failed
    }
    if {$diffFromDesired > 0.52} {
        log_warning gap $gap not reach the desired position $pos
    }
}

##this is the proc called in config
#we will use this to inform user that config is not supported
proc 19id_gap_set { new_19id_gap } {
    log_error Cannot config 19id_gap.  Please do it through EPICS

    undltrUpdateConfig

    return -code error "config not supported"
}

proc 19id_gap_update {} {
    variable gap
    return $gap
}
###this is update and config messages
### we want to check gap with energy at the end of
### energy moving or gap moving
### we will try to avoid checking while gap or energy is moving
proc 19id_gap_trigger { triggerDevice } {
    global gDevice
    variable gap
    variable gapStartedByUs
    variable gapStatus
    variable gapWaitingState
    variable gapRequest
    global   gGapMoveDoneFlag

puts "yangx 4"
    switch -exact -- $triggerDevice {
        "gap" {
            if {!$gapStatus} {
                set oneLine "[time_stamp] gap=$gap request=$gapRequest"
                #if {abs($gap - $gapRequest) > 0.001} {
                #    append oneLine " EXCEED tolerance"
                #}
                #undltrUpdateConfig
            } else {
                #dcss2 sendMessage \
                #"htos_update_motor_position 19id_gap $gap normal"
                update_motor_position 19id_gap $gap 1
            }
        }
        "gapStatus" {
            if {$gapStatus != 1} {
puts "yangx 8"
                if {$gapWaitingState == "wait_for_1"} {
                    set gapWaitingState wait_done
                    set gGapMoveDoneFlag 1
                    #log_warning DEBUG flag move done
                }
                if {!$gapStartedByUs} {
                    handle_move_complete 19id_gap
                    dcss2 sendMessage \
                    "htos_motor_move_completed 19id_gap $gap normal"
                } else {
                    set gapStartedByUs 0
                }
            } else {
                if {$gapWaitingState == "wait_for_0"} {
                    set gapWaitingState wait_for_1
                    #log_warning DEBUG flag move started
                }
                if {$gDevice(19id_gap,status) == "inactive"} {
                    set gapStartedByUs 0
                    log_warning spear moving 19id_gap
                }
            }
            
        }
    }
}

proc undltrCheckReady { waitForReady } {
    variable gapReady
    variable gapStatus

    if {!$gapReady} {
        if {$waitForReady} {
            log_error 19id_gap not ready, waiting it to become ready
            log_error 19id_gap not ready, waiting it to become ready
            wait_for_string_contents gapReady 1
        } else {
            log_error 19id_gap not ready
            log_error 19id_gap not ready
            return -code error "not ready"
        }
    }
    if {$gapStatus == 1} {
        if {$waitForReady} {
            log_error 19id_gap not ready, waiting it to become Stopped
            log_error 19id_gap not ready, waiting it to become Stopped
            wait_for_string_contents gapStatus "Stopped"
        } else {
            log_error 19id_gap not ready
            log_error 19id_gap not ready
            return -code error "not ready"
        }
    }
    
}
proc undltrUpdateConfig { } {
    variable gap
    variable gapRequestDrvH
    variable gapRequestDrvL

    setUpperLimitFromScaledValue 19id_gap $gapRequestDrvH
    setLowerLimitFromScaledValue 19id_gap $gapRequestDrvL

    dcss2 sendMessage "htos_configure_device 19id_gap $gap $gapRequestDrvH $gapRequestDrvL 1 1 0"
}
proc 19id_gap_abort { } {
    variable gapAbort
    variable gapWaitingState
    global   gGapMoveDoneFlag

    set gapWaitingState wait_abort
    set gGapMoveDoneFlag 1

    if {$gapOwner == $myOwnerID} {
        log_warning aborted undulator gap too
        set gapAbort 1
    }
}
