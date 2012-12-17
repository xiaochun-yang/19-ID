proc corner_initialize {} {
    variable runCalculator
    set runCalculator [::DCS::RunSequenceCalculator \#auto]
}
proc corner_start { command filename userName sessionID } {
    switch -exact -- $command {
        grid {
            cornerGrid $filename $userName $sessionID
        }
        diag {
            cornerDiag $filename $userName $sessionID
        }
        default {
            return -code error "wrong command: $command"
        }
    }
}

proc cornerGrid { posFilename userName sessionID } {
    set RUNNUM 1
    variable run$RUNNUM

    #set posList [cornerGenerateGridPosition]
    set posList [cornerReadPosition $posFilename]
    foreach pos $posList {
        log_note prepare for $pos
        #### get offset
        foreach {x y prefix} $pos break

        log_note moving detector
        move detector_horz to $x
        move detector_vert to $y
        wait_for_devices detector_vert detector_horz

        ### prepare for collect
        set runDef [set run$RUNNUM]
        set runDef [lreplace $runDef 0 1 inactive 0]
        set run$RUNNUM [lreplace $runDef 3 3 $prefix]
        #wait_for_string_contents run$RUNNUM $prefix 3

        ### collect
        log_note collecting $pos
        set handle \
        [start_waitable_operation collectRun $RUNNUM  $userName 0 $sessionID]
        wait_for_operation_to_finish $handle
    }
    log_note "DDDDDDOOOOOOOOOONNNNNNNNNNNEEEEEEEEEEE"
}

proc cornerDiag { posFilename userName sessionID } {
    log_note cornerDiag $posFilename
    variable runCalculator

    set RUNNUM 1
    variable run$RUNNUM
    variable runs

    ###retrieve parameters from rundefiniton
    $runCalculator updateRunDefinition [set run$RUNNUM]

    set useDose [lindex $runs 2]
    foreach { \
    directory \
    exposureTime \
    attenuationSetting \
    modeIndex \
    startAngle \
    } [$runCalculator getList \
    directory \
    exposure_time \
    attenuation \
    detector_mode \
    start_angle \
    ] break

    move gonio_phi to $startAngle
    wait_for_devices gonio_phi

    if {!$useDose} {
        move attenuation to $attenuationSetting
        wait_for_devices attenuation
    }

    #set posList [cornerGenerateDiagPosition 2]
    set posList [cornerReadPosition $posFilename]
    foreach pos $posList {
        log_note prepare for $pos
        #### get offset
        foreach {x y prefix} $pos break

        ### move detector
        move detector_horz to $x
        move detector_vert to $y
        wait_for_devices detector_vert
        wait_for_devices detector_horz

        ###snapshot
        log_note collecting for $pos
        set handle [start_waitable_operation collectFrame \
        $RUNNUM \
        $prefix \
        $directory \
        $userName \
        NULL \
        shutter \
        0 \
	    [requestExposureTime_start $exposureTime $useDose] \
        $modeIndex \
        1 \
        0 \
        $sessionID]

        wait_for_operation_to_finish $handle
        log_note done $pos
    }
    log_note "DDDDDDDDDDDOOOOOOOOOONNNNNNNNNNEEEEEEEEE"
}

proc cornerReadPosition { filename } {
    if {[catch {open $filename r} handle]} {
        log_error "failed to open $filename: $handle"
        return
    }
    set xyList ""
    while {![eof $handle]} {
        set line [readOneLine $handle]
        puts "got line: {$line}"
        if {[llength $line] <3} {
            puts "WARNING: skipped short line $line"
            continue
        }
        foreach {x y prefix} $line break
        if {![string is double -strict $x] || \
        ![string is double -strict $y]} {
            puts "WARNING: skipped bad line $line"
            continue
        }
        lappend xyList $line
    }
    close $handle
    return $xyList
}

proc readOneLine { file_handle } {
    while {![eof $file_handle]} {
        set line [gets $file_handle]
        set line [string trim $line]
        if {[string index $line 0] != "#"} {
            return $line
        }
    }
    return ""
}


#set posList [cornerGenerateGridPosition]
#set posList [cornerGenerateDiagPosition 2]
#set posList [cornerReadPosition GRID]
#foreach pos $posList {
#    puts $pos
#}
