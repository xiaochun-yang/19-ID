### SPEAR now uses gapReady to indicate gap is ready and we have the ownership.

proc undulator_monitor_initialize {} {
    global myOwnerID
    variable previousGapOwner

    set previousGapOwner ""

    set myOwnerID [undltrGetIpNum]
        
	set_children
	set_siblings

	set_triggers undulator_gap energy

    ###for log message
    registerEventListener beamlineOpenState ::nScripts::handleBeamLineOpenStateChange
    registerEventListener gapOwner ::nScripts::handleGapOwnerChange
}

proc undulator_monitor_move { pos } {
    variable undulator_monitor

    set undulator_monitor $pos
}

proc undulator_monitor_set { new_undulator_gap } {
    variable undulator_monitor

    set undulator_monitor $new_undulator_gap
}

proc undulator_monitor_update {} {
    variable undulator_monitor
    return $undulator_monitor
}
###this is update and config messages
### we want to check gap with energy at the end of
### energy moving or gap moving
### we will try to avoid checking while gap or energy is moving
proc undulator_monitor_trigger { triggerDevice } {
    global gDevice

    if {$gDevice(undulator_gap,status) == "inactive" \
    && $gDevice(energy,status) == "inactive"} {
        undltrCheckSyncWithEnergy
    }
}

proc undltrCheckSyncWithEnergy { } {
    variable gap
    variable energy
    variable d_spacing
    variable gap_energy_sync

    if {[catch {
	    set new_mono_theta [energy_calculate_mono_theta $energy $d_spacing]
        set gapFromE [expr [energy_calculate_undulator_gap $new_mono_theta] \
        + [energy_get_gap_offset]]
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
    set diff [expr $gapFromE - $gap]

    ####DEBUG
    #log_note energy_gap_check
    #log_note energy:     $energy
    #log_note gap:        $gap
    #log_note d_spacing:  $d_spacing
    #log_note new_mono_theta $new_mono_theta
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
