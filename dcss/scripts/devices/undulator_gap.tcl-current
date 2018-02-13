### SPEAR now uses gapReady to indicate gap is ready and we have the ownership.

proc undulator_gap_initialize {} {
    global myOwnerID
    variable gapStartedByUs
    variable previousGapOwner
    variable gapWaitingState
    global   gGapMoveDoneFlag

    set gapStartedByUs 0
    set previousGapOwner ""
    set gapWaitingState none
    set gGapMoveDoneFlag 0

    set myOwnerID [undltrGetIpNum]
        
	set_children
	set_siblings

	#set_triggers gap gapRequestDrvH gapRequestDrvL gapReady gapStatus gapOwner
    ### hook to itself and energy to check sync
	set_triggers gap gapTaper gapRequestDrvH gapRequestDrvL gapReady energy gapStatus

    registerAbortCallback undulator_gap_abort

    ###for log message
    registerEventListener beamlineOpenState ::nScripts::handleBeamLineOpenStateChange
    registerEventListener gapOwner ::nScripts::handleGapOwnerChange
}

proc undulator_gap_move { pos } {
    variable gapRequest
    variable gapStatus
    variable gapStartedByUs
    variable gapWaitingState
    global   gGapMoveDoneFlag

    set gapStartedByUs 1

    #####check preconditions
    undltrCheckOwner 0
    undltrCheckReady 0

    set gGapMoveDoneFlag 0
    set gapWaitingState wait_for_0
    set gapRequest $pos
    vwait gGapMoveDoneFlag

    if {$gapStatus != "Stopped" && $gapStatus != "Move too small"} {
        regsub -all {[[:space:]]} $gapStatus _ oneWord
        return -code error $oneWord
    }

    variable gap
    variable gapTaper
    set diffFromDesired [expr abs($gap - $pos)]
    if {$diffFromDesired > 0.010} {
        wait_for_time 1000
        set newDiff [expr abs($gap - $pos)]
        if {$newDiff < $diffFromDesired} {
            log_severe after extra waiting for 1 second, undulator diff reduced to $newDiff from $diffFromDesired
            set diffFromDesired $newDiff
        }
    }

    if {$diffFromDesired > 0.020} {
        log_severe gap $gap not reach the desired position $pos
        return -code error move_gap_failed
    }
    if {$diffFromDesired > 0.002} {
        log_warning gap $gap not reach the desired position $pos
    }

    ###log taper
    set fh ""
    if {[catch {
        set fh [open gapTaper.log a]
        puts $fh "[time_stamp] $gap $gapTaper"
        close $fh
        set fh ""
    } errMsg]} {
        log_warning failed to save taper log: $errMsg
        if {$fh != ""} {
            close $fh
        }
    }
}

##this is the proc called in config
#we will use this to inform user that config is not supported
proc undulator_gap_set { new_undulator_gap } {
    log_error Cannot config undulator_gap.  Please do it through EPICS

    undltrUpdateConfig

    return -code error "config not supported"
}

proc undulator_gap_update {} {
    variable gap
    return $gap
}
###this is update and config messages
### we want to check gap with energy at the end of
### energy moving or gap moving
### we will try to avoid checking while gap or energy is moving
proc undulator_gap_trigger { triggerDevice } {
    global gDevice
    variable gap
    variable gapTaper
    variable gapReady
    variable gapStartedByUs
    variable gapStatus
    variable gapWaitingState
    global   gGapMoveDoneFlag

    switch -exact -- $triggerDevice {
        "gapRequestDrvH" -
        "gapRequestDrvL" {
            undltrUpdateConfig
        }
        "gap" {
            if {$gapReady} {
                set oneLine "[time_stamp] gap=$gap"
                safeAppendFile gapDrift.log $oneLine 
                undltrUpdateConfig
            } else {
                #dcss2 sendMessage \
                #"htos_update_motor_position undulator_gap $gap normal"
                update_motor_position undulator_gap $gap 1
            }
        }
        "gapTaper" {
            if {$gapReady} {
                set oneLine "[time_stamp] gapTaper=$gapTaper"
                safeAppendFile TaperDrift.log $oneLine 
            }
        }
        "gapReady" {
            if {$gapReady && $gDevice(energy,status) == "inactive"} {
                undltrCheckSyncWithEnergy
            }
            if {$gapReady} {
                if {$gapWaitingState == "wait_for_1"} {
                    set gapWaitingState wait_done
                    set gGapMoveDoneFlag 1
                    #log_warning DEBUG flag move done
                }
                if {!$gapStartedByUs} {
                    handle_move_complete undulator_gap
                    dcss2 sendMessage \
                    "htos_motor_move_completed undulator_gap $gap normal"
                } else {
                    set gapStartedByUs 0
                }
            } else {
                if {$gapWaitingState == "wait_for_0"} {
                    set gapWaitingState wait_for_1
                    #log_warning DEBUG flag move started
                }
            }
            ####hook for wait_for_move_done
            
        }
        "energy" {
            if {$gapReady && $gDevice(energy,status) == "inactive"} {
                undltrCheckSyncWithEnergy
            }
        }
        "gapStatus" {
            if {$gDevice(undulator_gap,status) == "inactive" && \
            $gapStatus == "Moving"} {
                set gapStartedByUs 0
                log_warning spear moving undulator_gap
            }
            if {$gapStatus != "Moving" \
            &&  $gDevice(energy,status) == "inactive"} {
                undltrCheckSyncWithEnergy
            }
        }
    }
}

proc undltrCheckSyncWithEnergy { } {
    variable gap
    variable gapRequest
    variable energy
    variable gap_energy_sync


    if {[catch {
        set gapFromE [expr \
        [energy_calculate_undulator_gap_in_current_harmonic $energy] \
        + [energy_get_offset undulator_gap]]
    } errMsg]} {
        log_error $errMsg
        set gap_energy_sync 0
        if {$errMsg == "not_valid_energy"} {
            return
        } else {
            log_severe energy script changed, please update \
            undltrCheckSyncWithEnergy in file undulator_gap.tcl
            return
        }
    }

    if {abs($gapFromE - $gapRequest) > 0.001} {
        #log_warning DEBUG e=$energy gapFromE($gapFromE) != gapRequest($gapRequest)
    }

    set diff [expr $gapFromE - $gap]

    ####DEBUG
    #log_note energy_gap_check
    #log_note energy:     $energy
    #log_note gap:        $gap
    #log_note gapFromE:   $gapFromE

    if {abs($diff) > 0.001} {
        log_error gap energy not synced gap:$gap != $gapFromE
        log_error gap diff : $diff
        set gap_energy_sync 0
    } else {
        #log_note gap energy synced
        set gap_energy_sync 1
    }

    #### current logical:
    # notify staff if gap energy not sync and blct122 does not own the gap
    if {!$gap_energy_sync} {
        global myOwnerID
        variable gapOwner

        if {$gapOwner != $myOwnerID} {
            log_severe gap out of sync with energy by spear control
        }
    }
}

proc undltrGetIpNum { } {
    set hostname [info hostname]
    set ip_info [exec host $hostname]
    set ip_info [split $ip_info \n]
    set ip_info [lindex $ip_info 0]
    set ip_num [lindex $ip_info end]
    set numList [split $ip_num .]

    set result 0.0
    foreach num $numList {
        set result [expr $result * 256.0 + $num]
    }
    if {$result == 0.0} {
        return -code error "cannot get IP address"
    }
    return [format "%.0f" $result]
}

proc undltrRequestOwner { } {
    global myOwnerID
    variable gapOwnerRequest

    set gapOwnerRequest $myOwnerID
    log_error Please call spear operator to grant ownership
    log_error Please call spear operator to grant ownership
    log_error Please call spear operator to grant ownership
    log_error Please call spear operator to grant ownership
    log_error Please call spear operator to grant ownership
    log_error Please call spear operator to grant ownership
}
proc undltrCheckOwner { waitForOwn } {
    global myOwnerID
    variable gapOwner

    if {$gapOwner != $myOwnerID} {
        ###this log_severe will page staff
        log_severe not owner of undulator gap
        log_error Please call staff to request the ownership of undulator gap.
        log_error Please call staff to request the ownership of undulator gap.
        log_error Please call staff to request the ownership of undulator gap.
        log_error Please call staff to request the ownership of undulator gap.
        log_error Please call staff to request the ownership of undulator gap.
        log_error Please call staff to request the ownership of undulator gap.
        if {$waitForOwn} {
            undltrRequestOwner
            wait_for_string_contents gapOwner $myOwnerID
        } else {
            return -code error "not_owner"
        }
    }
}
proc undltrCheckReady { waitForReady } {
    variable gapReady

    if {!$gapReady} {
        
        if {$waitForReady} {
            log_error undulator_gap not ready, waiting it to become ready
            log_error undulator_gap not ready, waiting it to become ready
            wait_for_string_contents gapReady 1
        } else {
            log_error undulator_gap not ready
            log_error undulator_gap not ready
            return -code error "not ready"
        }
    }
}
proc undltrUpdateConfig { } {
    variable gap
    variable gapRequestDrvH
    variable gapRequestDrvL

    dcss2 sendMessage "htos_configure_device undulator_gap $gap $gapRequestDrvH $gapRequestDrvL 1 1 0"
}
proc undulator_gap_abort { } {
    global myOwnerID
    variable gapOwner
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


proc handleBeamLineOpenStateChange { args } {
    sendLogOfGap beamlineOpenState
}
proc handleGapOwnerChange { args } {
    sendLogOfGap gap_ownership

    ##send abort if we moving undulator, collecting data
    global myOwnerID
    global gDevice
    global gOperation
    variable previousGapOwner
    variable gapOwner

    if {$previousGapOwner == $myOwnerID && $gapOwner != $myOwnerID} {
        if {$gDevice(undulator_gap,status) != "inactive" || \
        $gDevice(energy,status) != "inactive" || \
        $gOperation(collectFrame,status) != "inactive"} {
            abort
        }
    }
    set previousGapOwner $gapOwner
}
proc sendLogOfGap { trigger } {
    if {[catch {
        global myOwnerID
        variable gapOwner
        variable beamlineOpenState
        variable gap

        if {$beamlineOpenState == "Open" && \
        $gapOwner == $myOwnerID && \
        $gap >= 10.0} {
            ::dcss2 sendMessage "htos_log severe server spear_state: $beamlineOpenState  gap: $gap triggered by $trigger"
        }
    } errMsg]} {
        puts "ERROR: $errMsg"
    }
}
proc safeAppendFile { fileName line } {
    if {[catch {open $fileName a} fh]} {
        puts "ERROR open $fileName to append failed: $fh"
        return
    }
    if {[catch {
        puts $fh $line
    } errMsg]} {
        puts "ERROR append $fileName failed; $errMsg"
    }
    if {[catch {
        close $fh
    } errMsg]} {
        puts "ERROR close $fileName failed: $errMsg"
    }
}
