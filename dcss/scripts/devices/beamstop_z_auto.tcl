# beamstop_z_auto.tcl



proc beamstop_z_auto_initialize {} {
    variable beamstop_z_auto_moving

	# specify children devices
	set_children beamstop_z
    set beamstop_z_auto_moving false
}


proc beamstop_z_auto_move { new_beamstop_z_auto } {
	# global variables
	variable beamstop_z
    variable beamstop_z_auto
    variable beamstop_z_auto_moving

    removeInlineCamera

	# move beamstop_z motor
	move beamstop_z to $new_beamstop_z_auto
    
    #we started moving the beamstop_z
    set beamstop_z_auto_moving true

	if { [catch { wait_for_devices beamstop_z } errorResult] } {
        set beamstop_z_auto_moving false
        return -code error $errorResult
    }
    
    set beamstop_z_auto_moving false

}


proc beamstop_z_auto_set { new_beamstop_z_auto } {

	# global variables
	variable beamstop_z
	variable beamstop_z_auto

    if { $beamstop_z != $beamstop_z_auto } {
        log_error "Cannot configure position of beamstop_z using beamstop_z_auto motor." 
        return
    }

	set beamstop_z $new_beamstop_z_auto
}


proc beamstop_z_auto_update {} {
    variable beamstop_z
    variable beamstop_z_auto
    variable beamstop_z_auto_moving

    if { $beamstop_z_auto_moving == false } {
        return $beamstop_z_auto
    }

	return $beamstop_z
}


proc beamstop_z_auto_calculate { dz } {
    variable beamstop_z_auto
    variable beamstop_z_auto_moving

    if { $beamstop_z_auto_moving == false } {
        return $beamstop_z_auto
    }

	return $dz
}


proc removeInlineCamera {} {
    ### turn off the light
    variable inlineLightStatus

#yang    lightsControl_start setup inline_remove


    	 open_shutter inline_light_in
#yang    close_shutter inline_light_out
	 wait_for_devices inline_light_in
#yang    wait_for_devices inline_light_in inline_light_out
    
    wait_for_time 500
    log_note "Waiting for inline light to move out." 
    if {[catch waitForInlineLightRemoved errMsg]} {
        log_severe failed to wait inline light to move out
        log_error $errMsg
        return -code error $errMsg
    }
    log_note "Inline light moved out" 
}

proc insertInlineCamera {} {

#log_note "yangxx inlineLightStatus=$inlineLightStatus"
    ## max light
#yang    lightsControl_start setup inline_insert
#yang    collimatorMoveOut
         close_shutter inline_light_in
#yang    open_shutter inline_light_out
	 wait_for_devices inline_light_in
#yang    wait_for_devices inline_light_in inline_light_out
    wait_for_time 500

    log_note "Waiting for inline light to move in." 
    if {[catch waitForInlineLightInserted errMsg]} {
        log_severe failed to wait inline light insert
        log_error $errMsg
        return -code error $errMsg
    }
    log_note "Inline light moved in" 
}

proc waitForInlineLightRemoved {} {
    variable inlineLightStatus

#log_note "yangxx inlineLightStatus=$inlineLightStatus"
    set removed 0
    while {!$removed} {
        set paramList $inlineLightStatus
        set index [expr [lsearch -exact $paramList REMOVED] +1]
        if {$index <=0} {
            log_severe cannot wait for inline light removed: \
            no REMOVED field found
            return -code error field_REMOVED_not_found
        }
        set removed [lindex $paramList [expr [lsearch $paramList REMOVED] +1]]
        if {$removed == "yes"} {
            break
        }
        log_note "Waiting for inline light to move out." 
set inlineLightStatus "INSERTED no REMOVED yes"
#yangx        wait_for_strings inlineLightStatus 5000
    }
}

proc waitForInlineLightInserted {} {
    variable inlineLightStatus

    ##assume the position will not change during wait
    set index [expr [lsearch $inlineLightStatus INSERTED] +1]
    if {$index <= 0} {
        log_severe cannot wait for inline light inserted: \
        no INSERTED field found
        return -code error field_INSERTED_not_found
    }
    set inlineLightStatus "INSERTED yes REMOVED no"
log_note "yangx inlineLightStatus=$inlineLightStatus"
    ### timeout can be added at the end of arguments
#yangx    wait_for_string_contents inlineLightStatus yes $index 5000
}
