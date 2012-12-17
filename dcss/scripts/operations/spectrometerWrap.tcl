package require yaml
proc spectrometerWrap_initialize { } {
    variable camera_view_phi
    set camera_view_phi(inline)     [::config getStr camera_view_phi.inline]
    set camera_view_phi(sample)     [::config getStr camera_view_phi.sample]
    set camera_view_phi(visex)      [::config getStr camera_view_phi.visex]
    set camera_view_phi(microspec)  [::config getStr camera_view_phi.microspec]

    namespace eval ::spectrometerWrap {
        set dir [::config getStr "spectrometer.directory"]
        set bid [::config getConfigRootName]

        set dir [file join $dir $bid]

        set rfPath [file join $dir reference_${bid}.yaml]
        set dkPath [file join $dir dark_${bid}.yaml]

        set wavelengthFullList ""

        set rfCondition [list -1 1 0]
        set rfTimestamp 0
        set rfSaturated 0
        set rfWarning ""
        set minTimeStep 0

        set dkCondition [list -1 1 0]
        set dkTimestamp 0

        set rfWList ""
        set rfCList ""
        set rfSaturateThreshold 65535

        set dkWList ""
        set dkCList ""

        set rawWList ""
        set rawCList ""
        set absorbanceCList ""
        set transmittanceCList ""

        set handle ""
        set scanPath ""
        set scanPrefix ""

        set statusStringName spectroWrap_status
        set userName ""
        set sessionId ""

        set lightOnTimestamp ""
        set previousLightStatus ""

        set t0Path ""
        set t0Prefix ""

        set psShutterOpen 0
        set doseRate 0
    }
    variable ::spectrometerWrap::rfPath
    variable ::spectrometerWrap::dkPath
    if {[file readable $rfPath]} {
        spectrometerWrap_retrieveReference
    }
    if {[file readable $dkPath]} {
        spectrometerWrap_retrieveDark
    }

    #registerEventListener spectro_integration \
    #::nScripts::spectrometerWrap_updateStatus
    registerEventListener spectro_config \
    ::nScripts::spectrometerWrap_updateStatus

    registerEventListener spectroWrap_config \
    ::nScripts::spectrometerWrap_updateStatus

    #### the turnOffMicroSpecLight_condition and _command are in
    #### DCS/engine/timerService.tcl
    registerTimerService turnOffMicroSpecLight 3600000 system_idle microspecLightControl

    registerEventListener microspecLightControl ::nScripts::microspecLightControl_callback
}
proc spectrometerWrap_start { cmd args } {
    variable ::spectrometerWrap::userName
    variable ::spectrometerWrap::sessionId
    variable ::spectrometerWrap::statusStringName

    variable spectro_config_msg

    set userName  [get_operation_user]
    set sessionId [get_operation_SID]
    set statusStringName spectroWrap_status

    switch -exact -- $cmd {
        set_parameters {
            eval spectrometerWrap_setParemeters $args
        }
        save_reference {
            set spectro_config_msg "getting new reference"
            spectrometerWrap_clear reference
            if {[lightsControl_start setup visex 1]} {
                log_warning wait for lights to settle down
                wait_for_time 1000
            }
            spectrometerWrap_checkMotor 1
            spectrometerWrap_checkLight
            spectrometerWrap_saveReference
            spectrometerWrap_backupReferenceFile
            spectrometerWrap_updateStatus
            spectrometerWrap_generateValidSetupList
            spectrometerWrap_moveLensOut
            lightsControl_start restore
        }
        extend_reference {
            eval spectrometerWrap_extendRef2File $args
            spectrometerWrap_generateValidSetupList
        }
        extend_reference_from_condition {
            eval spectrometerWrap_extendRefFromCondition $args
            spectrometerWrap_generateValidSetupList
        }
        save_dark {
            set spectro_config_msg "getting new dark"
            spectrometerWrap_clear dark
            if {[lightsControl_start setup visex 1]} {
                log_warning wait for lights to settle down
                wait_for_time 1000
            }
            spectrometerWrap_moveLensOut
            spectrometerWrap_saveDark
            spectrometerWrap_backupDarkFile
            spectrometerWrap_generateValidSetupList
            lightsControl_start restore
        }
        just_save_dark {
            spectrometerWrap_saveDark
            spectrometerWrap_backupDarkFile
            spectrometerWrap_generateValidSetupList
        }
        acquire {
            set num [lindex $args 0]
            if {[string is integer -strict $num] && $num > 1} {
                spectrometerWrap_repeatAcquire $num
            } else {
                return [spectrometerWrap_acquire]
            }
        }
        move_motors {
            return [eval spectrometerWrap_moveMotors $args]
        }
        motor_scan -
        scan_motor {
            eval spectrometerWrap_scanMotor $args
        }
        scan_time_and_phi {
            eval spectrometerWrap_scanTimeAndPhi $args
        }
        optimize_time {
            eval spectrometerWrap_autoTime $args
        }
        clear_result_files {
            ## this will not remove user reference and dark
            spectrometerWrap_removeResultFiles
        }
        clear_setup_files {
            spectrometerWrap_removeSetupFiles
        }
        change_over {
            ## this will remove all user files and copy back the system
            ## references and darks.
            spectrometerWrap_removeUserFiles
            spectrometerWrap_resetScanParameters
            spectrometerWrap_generateValidSetupList
        }
        reset_parameters {
            ###DEBUG
            spectrometerWrap_resetScanParameters
        }
        clear_user_files {
            ###DEBUG
            spectrometerWrap_removeUserFiles
            spectrometerWrap_generateValidSetupList
        }
        move_out {
            ### this called by all operations
            spectrometerWrap_moveLensOut
        }
        add_batch {
            eval spectrometerWrap_addBatch $args
        }
        system_batch {
            if {[lightsControl_start setup visex 1]} {
                wait_for_time 4000
                log_warning wait for lights to settle down
            }
            spectrometerWrap_clear both
            eval spectrometerWrap_batchRefereanceAndDark $args
            spectrometerWrap_generateValidSetupList
            lightsControl_start restore
        }
        refresh_valid_list {
            spectrometerWrap_generateValidSetupList
        }
        refresh_wavelength_full_list {
            spectrometerWrap_refreshWavelengthFullList
        }
        wavelength_to_index {
            spectrometerWrap_calculateIndex [lindex $args 0]
        }
        set_window_cutoff {
            spectrometerWrap_setWindowCutoff [lindex $args 0]
        }
        default {
            log_error command $cmd not supported.
            return -code error not_supported
        }
    }
}
proc spectrometerWrap_moveLensOut { {no_wait 0} } {
    variable ::spectrometerWrap::statusStringName
    variable $statusStringName
    variable microspec_z

    set old_msg [dict get [set $statusStringName] message]

    if {$microspec_z < 30.0} {
        move microspec_z to 30.0
        if {$no_wait} {
            return microspec_z
        }
        dict set $statusStringName message "waiting for lens to move out"
        wait_for_devices microspec_z
        dict set $statusStringName message $old_msg
    }
    return ""
}
proc spectrometerWrap_cleanup { } {
    variable spectroWrap_status
    variable microspec_phiScan_status
    variable microspec_doseScan_status
    variable microspec_timeScan_status
    variable microspec_snapshot_status
    variable ::spectrometerWrap::handle
    if {$handle != ""} {
        puts "WARNING handle not closed in spectrometerWrap"
        close $handle
        set handle ""
    }
    spectrometerWrap_updateStatus

    foreach sName { \
    spectroWrap_status \
    microspec_phiScan_status \
    microspec_doseScan_status \
    microspec_timeScan_status \
    microspec_snapshot_status \
    } {
        set contents [set $sName]
        set msg [dict get $contents message]
        if {![regexp -nocase abort|warn|error|fail $msg]} {
            dict set $sName message ""
        }
    }
}
proc spectrometerWrap_repeatAcquire { num } {
    variable ::spectrometerWrap::rawWList
    variable ::spectrometerWrap::rawCList
    variable ::spectrometerWrap::absorbanceCList
    variable ::spectrometerWrap::transmittanceCList

    ### first time send all list
    spectrometerWrap_acquire

    incr num -1
    for {set i 0} {$i < $num} {incr i} {
        spectrometerWrap_acquire 0
        send_operation_update RAW           $rawWList $rawCList
        send_operation_update ABSORBANCE   $rawWList $absorbanceCList
        send_operation_update TRANSMITTANCE $rawWList $transmittanceCList
    }

}
proc spectrometerWrap_getSamplePosition { } {
    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega

    set sample_angle [expr $gonio_phi + $gonio_omega]
    return [list $sample_x $sample_y $sample_z $sample_angle]
}
proc spectrometerWrap_acquire { {send_update 1} {msg ""}} {
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::rfCList
    variable ::spectrometerWrap::dkWList
    variable ::spectrometerWrap::dkCList
    variable ::spectrometerWrap::rawWList
    variable ::spectrometerWrap::rawCList
    variable ::spectrometerWrap::absorbanceCList
    variable ::spectrometerWrap::transmittanceCList
    variable ::spectrometerWrap::statusStringName
    variable spectro_config
    variable $statusStringName

    spectrometerWrap_checkReference $send_update
    spectrometerWrap_checkDark $send_update

    dict set $statusStringName message "${msg}acquiring spectrum"
    set tsStart [clock clicks -milliseconds]
    set oph [start_waitable_operation get_spectrum 1]

    set opr [wait_for_operation_to_finish $oph]
    set tsNow [clock clicks -milliseconds]
    puts "get spectrum time=[expr $tsNow - $tsStart]"
    if {[llength $opr] < 3} {
        dict set $statusStringName message "ERROR failed to get reference"
        log_error failed to acquire reference spectrum
        return -code failed
    }
    foreach {status rawWList rawCList} $opr break
    set rawWList [string trim $rawWList]
    set rawCList [string trim $rawCList]

    if {$send_update} {
        set sample_position [spectrometerWrap_getSamplePosition]
        send_operation_update CONDITION $spectro_config
        send_operation_update SAMPLE_POSITION $sample_position
        send_operation_update RAW $rawWList $rawCList
    }

    if {$rfWList != $rawWList} {
        log_warning wavelength list changed for spectrometer.
        log_warning rfWList "{$rfWList}"
        log_warning rawWList "{$rawWList}"
        #log_severe wavelength list changed for spectrometer.
        #return -code error need_adjust
    }

    set absorbanceCList ""
    set transmittanceCList ""
    foreach s $rawCList r $rfCList d $dkCList {
        set ref [expr $r - $d]
        set trn [expr $s - $d]
        if {$ref > 0 && $trn > 0} {
            set t [expr 1.0 * $trn / $ref]
            set a [expr -log10( $t )]
        } else {
            set a 0.0
            set t 0.0
        }

        lappend absorbanceCList $a
        lappend transmittanceCList $t
    }
    if {$send_update} {
        send_operation_update ABSORBANCE   $rawWList $absorbanceCList
        send_operation_update TRANSMITTANCE $rawWList $transmittanceCList
    }
    return OK
}

proc spectrometerWrap_saveReference { } {
    variable ::spectrometerWrap::rfCondition
    variable ::spectrometerWrap::rfSaturated
    variable ::spectrometerWrap::rfWarning
    variable ::spectrometerWrap::rfTimestamp
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::rfCList
    variable ::spectrometerWrap::rfSaturateThreshold
    variable ::spectrometerWrap::statusStringName
    variable $statusStringName

    ### motor, we can also get it from string or operation
    variable spectro_config
    variable spectro_status
    variable spectroWrap_config

    set orig_config $spectro_config

    set refNumAvg [lindex $rfCondition 1]
    set cfgNumAvg [lindex $spectro_config 1]
    set minNumAvg [lindex $spectroWrap_config 4]

    set needChange 0
    if {$cfgNumAvg < $refNumAvg} {
        set cfgNumAvg $refNumAvg
        set needChange 1
    }
    if {$cfgNumAvg < $minNumAvg} {
        set cfgNumAvg $minNumAvg
        set needChange 1
    }
    if {$needChange} {
        set spectro_config [lreplace $spectro_config 1 1 $cfgNumAvg]
        wait_for_string_contents spectro_config $cfgNumAvg 1
    }

    dict set $statusStringName message "acquiring reference"
    set oph [start_waitable_operation get_spectrum 1]
    set opr [wait_for_operation_to_finish $oph]
    if {[llength $opr] < 3} {
        log_error failed to acquire reference spectrum
        return -code failed
    }
    foreach {status rfWList rfCList} $opr break
    set rfWList [string trim $rfWList]
    set rfCList [string trim $rfCList]
    set rfSaturateThreshold 65535

    send_operation_update REFERENCE $rfWList $rfCList
    send_operation_update REF_CONDITION $spectro_config

    set ll1 [llength $rfWList]
    set ll2 [llength $rfCList]

    if {$ll1 == 0 || $ll1 != $ll2} {
        log_error reference data corrupt.
        return -code error "bad_reference"
    }
    set rfCondition $spectro_config
    set rfTimestamp [clock seconds]
    if {[catch {dict get $spectro_status num_saturated} rfSaturated]} {
        log_error failed to get num_saturated from spectro_status: $rfSaturated
        set rfSaturated 0
    }

    if {$rfSaturated > 0} {
        set rfWarning "reference saturated: $rfSaturated"
    } else {
        set rfWarning ""
    }
    if {$needChange} {
        set spectro_config $orig_config
        wait_for_strings spectro_config
    }
    spectrometerWrap_saveRef2File
}

proc spectrometerWrap_saveRef2File { } {
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::rfPath
    variable ::spectrometerWrap::rfCondition
    variable ::spectrometerWrap::rfSaturated
    variable ::spectrometerWrap::rfTimestamp
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::rfCList
    variable ::spectrometerWrap::rfSaturateThreshold


    set hW [eval huddle list $rfWList]
    set hC [eval huddle list $rfCList]

    foreach {t n c} $rfCondition break

    set hhhh [huddle create \
    TITLE spectrometer_reference \
    integrationTime $t \
    scansToAverage  $n \
    boxcarWidth     $c \
    saturateThreshold $rfSaturateThreshold \
    numSaturated    $rfSaturated \
    timestamp       $rfTimestamp \
    timestamp_txt   [clock format $rfTimestamp -format "%D %T"] \
    wavelengthList  $hW \
    countList       $hC \
    ]

    if {$rfSaturated > 0} {
        huddle set hhhh warning "reference saturated: $rfSaturated"
    }

    set yyyy [::yaml::huddle2yaml $hhhh 4 80]

    if {$handle != ""} {
        close $handle
        set handle ""
    }
    if {![catch {open $rfPath w} handle]} {
        puts $handle $yyyy
        close $handle
        set handle ""
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to save spectrometer reference to $rfPath: $errMsg
        return -code error $errMsg
    }
}
proc spectrometerWrap_saveDark { } {
    variable ::spectrometerWrap::dkCondition
    variable ::spectrometerWrap::dkTimestamp
    variable ::spectrometerWrap::dkWList
    variable ::spectrometerWrap::dkCList
    variable ::spectrometerWrap::statusStringName
    variable $statusStringName
    variable spectroWrap_status
    variable spectro_config
    variable spectroWrap_config

    set orig_config $spectro_config

    set drkNumAvg [lindex $dkCondition 1]
    set cfgNumAvg [lindex $spectro_config 1]
    set minNumAvg [lindex $spectroWrap_config 4]

    set needChange 0
    if {$cfgNumAvg < $drkNumAvg} {
        set cfgNumAvg $drkNumAvg
        set needChange 1
    }
    if {$cfgNumAvg < $minNumAvg} {
        set cfgNumAvg $minNumAvg
        set needChange 1
    }
    if {$needChange} {
        set spectro_config [lreplace $spectro_config 1 1 $cfgNumAvg]
        wait_for_string_contents spectro_config $cfgNumAvg 1
    }

    dict set $statusStringName message "acquiring dark"
    set oph [start_waitable_operation get_spectrum 1]
    set opr [wait_for_operation_to_finish $oph]
    if {[llength $opr] < 3} {
        log_error failed to acquire reference spectrum
        return -code failed
    }
    foreach {status dkWList dkCList} $opr break
    set dkWList [string trim $dkWList]
    set dkCList [string trim $dkCList]

    send_operation_update DARK $dkWList $dkCList
    send_operation_update DARK_CONDITION $spectro_config

    set ll1 [llength $dkWList]
    set ll2 [llength $dkCList]

    if {$ll1 == 0 || $ll1 != $ll2} {
        log_error dark data corrupt.
        return -code error "bad_dark"
    }
    set dkCondition $spectro_config
    set dkTimestamp [clock seconds]
    if {$needChange} {
        set spectro_config $orig_config
        wait_for_strings spectro_config
    }
    spectrometerWrap_saveDark2File
}
proc spectrometerWrap_saveDark2File { } {
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::dkPath
    variable ::spectrometerWrap::dkCondition
    variable ::spectrometerWrap::dkTimestamp
    variable ::spectrometerWrap::dkWList
    variable ::spectrometerWrap::dkCList

    foreach {t n c} $dkCondition break

    set hW [eval huddle list $dkWList]
    set hC [eval huddle list $dkCList]

    set hhhh [huddle create \
    TITLE spectrometer_dark \
    integrationTime $t \
    scansToAverage  $n \
    boxcarWidth     $c \
    timestamp       $dkTimestamp \
    timestamp_txt   [clock format $dkTimestamp -format "%D %T"] \
    wavelengthList  $hW \
    countList       $hC \
    ]

    set yyyy [::yaml::huddle2yaml $hhhh 4 80]

    if {$handle != ""} {
        close $handle
        set handle ""
    }
    if {![catch {open $dkPath w} handle]} {
        puts $handle $yyyy
        close $handle
        set handle ""
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to save spectrometer dark to $dkPath: $errMsg
        return -code error $errMsg
    }
}
proc spectrometerWrap_retrieveReference { } {
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::rfPath
    variable ::spectrometerWrap::rfCondition
    variable ::spectrometerWrap::rfSaturated
    variable ::spectrometerWrap::rfWarning
    variable ::spectrometerWrap::rfTimestamp
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::rfCList
    variable ::spectrometerWrap::rfSaturateThreshold

    puts "trying to retrieve spectrometer reference from $rfPath"

    if {$handle != ""} {
        close $handle
        set handle ""
    }
    if {![catch {open $rfPath r} handle]} {
        set yyyy [read -nonewline $handle]
        close $handle
        set handle ""
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to read spectrometer reference from $rfPath: $errMsg
        return -code error $errMsg
    }
    set hhhh [::yaml::yaml2huddle $yyyy]

    set title [huddle gets $hhhh TITLE]
    if {$title != "spectrometer_reference"} {
        log_error wrong yamle file, TITLE = $title != spectrometer_reference
        return -code error bad_contents
    }

    set rfWList         [huddle gets $hhhh wavelengthList]
    set rfCList         [huddle gets $hhhh countList]
    set rfTimestamp     [huddle gets $hhhh timestamp]

    set iTime           [huddle gets $hhhh integrationTime]
    set numAvg          [huddle gets $hhhh scansToAverage]
    set bW              [huddle gets $hhhh boxcarWidth]
    set rfSaturated     [huddle gets $hhhh numSaturated]
    if {[catch {huddle gets $hhhh warning} rfWarning]} {
        set rfWarning ""
    }
    if {[catch {huddle gets $hhhh saturateThreshold} rfSaturateThreshold]} {
        set rfSaturateThreshold 65535
    } else {
        puts "got rfSaturateThreshold=$rfSaturateThreshold"
    }
    set rfCondition [list $iTime $numAvg $bW]

    puts "spectrum reference retrieved from $rfPath ll=[llength $rfCList]"

    puts "rfCList={$rfCList}"
    puts "rfCondition=$rfCondition"
}
proc spectrometerWrap_retrieveDark { } {
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::dkPath
    variable ::spectrometerWrap::dkCondition
    variable ::spectrometerWrap::dkTimestamp
    variable ::spectrometerWrap::dkWList
    variable ::spectrometerWrap::dkCList

    puts "trying to retrieve spectrometer dark from $dkPath"

    if {$handle != ""} {
        close $handle
        set handle ""
    }
    if {![catch {open $dkPath r} handle]} {
        set yyyy [read -nonewline $handle]
        close $handle
        set handle ""
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to read spectrometer dark from $dkPath: $errMsg
        return -code error $errMsg
    }
    set hhhh [::yaml::yaml2huddle $yyyy]

    set title [huddle gets $hhhh TITLE]
    if {$title != "spectrometer_dark"} {
        log_error wrong yamle file, TITLE = $title != spectrometer_dark
        return -code error bad_contents
    }

    set dkWList         [huddle gets $hhhh wavelengthList]
    set dkCList         [huddle gets $hhhh countList]
    set dkTimestamp     [huddle gets $hhhh timestamp]

    set iTime           [huddle gets $hhhh integrationTime]
    set numAvg          [huddle gets $hhhh scansToAverage]
    set bW              [huddle gets $hhhh boxcarWidth]
    set dkCondition [list $iTime $numAvg $bW]
    puts "spectrum dark retrieved from $dkPath ll=[llength $dkCList]"

    puts "dkCList={$dkCList}"
    puts "dkCondition=$dkCondition"
}
proc spectrometerWrap_conditionValid { condition } {
    variable spectro_config

    puts "spectrometerWrap_conditionValid {$condition} spectro_config=$spectro_config"

    foreach {iTime nAvg nB} $spectro_config break
    foreach {cTime cAvg cB} $condition break

    if {![string is double -strict $iTime] \
    ||  ![string is double -strict $cTime]} {
        return 0
    }

    if {abs($iTime - $cTime) < 0.001 && $nAvg <= $cAvg && $nB == $cB} {
        return 1
    }
    return 0
}
proc spectrometerWrap_updateStatus { } {
    variable ::spectrometerWrap::rfCondition
    variable ::spectrometerWrap::rfSaturated
    variable ::spectrometerWrap::rfWarning
    variable ::spectrometerWrap::dkCondition
    variable ::spectrometerWrap::rfTimestamp
    variable ::spectrometerWrap::dkTimestamp
    variable ::spectrometerWrap::minTimeStep
    variable spectroWrap_status
    variable spectro_config
    variable spectroWrap_config

    variable spectro_config_msg
    #global gDevice

    set rfValidTimespan [lindex $spectroWrap_config 1]
    set dkValidTimespan [lindex $spectroWrap_config 2]

    puts "spectrometerWrap_updateStatus"

    set rfValid [spectrometerWrap_conditionValid $rfCondition]
    set dkValid [spectrometerWrap_conditionValid $dkCondition]
    if {!$rfValid && !$dkValid} {
        spectrometerWrap_clear both
    } elseif {!$rfValid} {
        spectrometerWrap_clear reference
    } elseif {!$dkValid} {
        spectrometerWrap_clear dark
    }

    set now [clock seconds]
    if {!$rfValid} {
        spectrometerWrap_searchReference
        set rfValid [spectrometerWrap_conditionValid $rfCondition]
    }
    set rfTSFmt "%D %T"
    if {$rfValid && $now > $rfTimestamp + $rfValidTimespan} {
        #set rfValid 0
        log_severe microspec reference old > \
        [secondToTimespan $rfValidTimespan] for $rfCondition
        set rfTSFmt "OLD %D %T"
    }
    if {!$dkValid} {
        spectrometerWrap_searchDark
        set dkValid [spectrometerWrap_conditionValid $dkCondition]
    }
    set dkTSFmt "%D %T"
    if {$dkValid && $now > $dkTimestamp + $dkValidTimespan} {
        #set dkValid 0
        log_severe microspec dark old > \
        [secondToTimespan $dkValidTimespan] for $dkCondition.
        set dkTSFmt "OLD %D %T"
    }

    foreach {rfTime rfNum rfWidth} $rfCondition break
    foreach {dkTime dkNum dkWidth} $dkCondition break

    set newContents $spectroWrap_status

    dict set newContents refValid            $rfValid
    if {$rfValid} {
        dict set newContents refIntegrationTime  $rfTime
        dict set newContents refScansToAverage   $rfNum
        dict set newContents refBoxcarWidth      $rfWidth
        dict set newContents refSaturated        $rfSaturated
        dict set newContents refWarning          $rfWarning
        dict set newContents refTimestamp \
        [clock format $rfTimestamp -format $rfTSFmt]
    } else {
        dict set newContents refIntegrationTime  -
        dict set newContents refScansToAverage   -
        dict set newContents refBoxcarWidth      -
        dict set newContents refSaturated        0
        dict set newContents refWarning          ""
        dict set newContents refTimestamp        -
    }

    dict set newContents darkValid           $dkValid
    if {$dkValid} {
        dict set newContents darkIntegrationTime $dkTime
        dict set newContents darkScansToAverage  $dkNum
        dict set newContents darkBoxcarWidth     $dkWidth
        dict set newContents darkTimestamp \
        [clock format $dkTimestamp -format $dkTSFmt]
    } else {
        dict set newContents darkIntegrationTime -
        dict set newContents darkScansToAverage  -
        dict set newContents darkBoxcarWidth     -
        dict set newContents darkTimestamp       -
    }

    set spectroWrap_status $newContents

    foreach {iTime nAvg bWidth} $spectro_config break
    set minTimeStep [expr ($iTime + 0.016) * $nAvg + 0.16 + 0.2]
    set minTimeStep [expr $minTimeStep * 1.2]

    ### convert to 0.5 1.0 .....
    set nnnn [expr $minTimeStep * 2]
    set nnnn [expr int(ceil($nnnn))]
    set minTimeStep [expr $nnnn / 2.0]
    set minTimeStep [format %.3f $minTimeStep]

    if {$rfValid && $dkValid} {
        set numDisplay [expr ($rfNum > $dkNum) ? $dkNum:$rfNum]
        
        set spectro_config_msg "Loaded successfully, valid for average = 1-$numDisplay.  Min time step=$minTimeStep seconds"
    } elseif {$rfValid} {
        set spectro_config_msg "warning: no valid dark found"
    } elseif {$dkValid} {
        set spectro_config_msg "warning: no valid reference found"
    } else {
        set spectro_config_msg "warning: neither valid reference nor dark found"
    }
}
proc spectrometerWrap_moveMotors { args } {
    variable ::spectrometerWrap::statusStringName
    variable $statusStringName

    dict set $statusStringName message "moving motor"
    eval moveMotors_start $args

    return [spectrometerWrap_acquire]
}
proc spectrometerWrap_scanMotor { args } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::rfCList
    variable ::spectrometerWrap::dkWList
    variable ::spectrometerWrap::dkCList
    variable ::spectrometerWrap::rawWList
    variable ::spectrometerWrap::rawCList
    variable ::spectrometerWrap::absorbanceCList
    variable ::spectrometerWrap::transmittanceCList
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::statusStringName
    variable $statusStringName
    variable spectro_config

    set ll [llength $args]
    if {$ll < 5} {
        log_error scan_motor need more parameters
        return -code error ARGS
    }

    clear_operation_stop_flag
    foreach {motorName startP endP numPoint timeWait} $args break
    if {$numPoint < 2} {
        log_error scan needs at least 2 points
        return -code error bad_arguments
    }

    set openShutter 0
    if {$motorName == "time" && [lsearch $args shutter] >= 0} {
        set openShutter 1
        log_warning it will open shutter
    }

    if {[swapIfBacklash $motorName startP endP]} {
        log_warning swapped start and end position to avoid backlashing.
    }

    spectrometerWrap_checkReference 0
    spectrometerWrap_checkDark 0

    set sample_position [spectrometerWrap_getSamplePosition]

    send_operation_update SCAN_WAVELENGTH $rfWList
    send_operation_update SCAN_REFERENCE  $rfCList
    send_operation_update SCAN_DARK       $dkCList
    send_operation_update SCAN_CONDITION  $spectro_config
    send_operation_update SCAN_SAMPLE_POSITION $sample_position


    if {$motorName != "time"} {
        variable $motorName
        set orig_position [set $motorName]
    }

    spectrometerWrap_writeYAMLHeader \
    $motorName $startP $endP $numPoint $timeWait

    set stepSize [expr ($endP - $startP) / ($numPoint - 1.0)]

    if {$openShutter} {
        open_shutter shutter
        wait_for_shutters shutter
    }
    for {set i 0} {$i < $numPoint} {incr i} {
        dict set $statusStringName scan_progress "$i of $numPoint"
        set now [clock format [clock seconds] -format "%D %T"]
        if {[get_operation_stop_flag]} {
            break
        }
        set p [expr $startP + $i * $stepSize]
        set contents "---\n"
        append contents "index: $i\n"
        append contents "position: $p\n"
        append contents "timestamp: $now\n"
        if {$motorName != "time"} {
            move $motorName to $p
            wait_for_devices $motorName
            if {$timeWait > 0} {
                log_warning wait for settle down
                wait_for_time $timeWait
            }
        } else {
            wait_for_time [expr int(1000.0 * $stepSize)]
        }
        set msgPrefix "scan $motorName [expr $i + 1] of $numPoint: "
        spectrometerWrap_acquire 0 $msgPrefix
        
        send_operation_update SCAN_RAW           $i $p $now $rawCList
        #send_operation_update SCAN_ABSORBANCE   $i $absorbanceCList
        #send_operation_update SCAN_TRANSMITTANCE $i $transmittanceCList

        spectrometerWrap_appendList contents 0 raw           $rawCList
        #spectrometerWrap_appendList contents 2 raw           $rawCList
        #spectrometerWrap_appendList contents 2 absorbance   $absorbanceCList
        #spectrometerWrap_appendList contents 2 transmittance $transmittanceCList
        #spectrometerWrap_appendYAML $contents
        spectrometerWrap_saveScanResult $i $contents
    }
    dict set $statusStringName scan_progress "$i of $numPoint"

    dict set $statusStringName message "restoring $motorName"
    if {$openShutter} {
        close_shutter shutter
        wait_for_shutters shutter
    }
    if {$motorName != "time"} {
        move $motorName to $orig_position
        wait_for_devices $motorName
    }
    if {[get_operation_stop_flag]} {
        log_error phi scan stopped by user.
    }
}
proc spectrometerWrap_checkReference { send_update } {
    variable ::spectrometerWrap::rfCondition
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::rfCList
    variable ::spectrometerWrap::rfSaturateThreshold

    set rfValid [spectrometerWrap_conditionValid $rfCondition]
    if {!$rfValid} {
        #log_warning aquiring reference \
        #for exposure time = $spectro_integration
        log_error need to retake reference for new configuration
        return -code error reference_invalid
    } elseif {$send_update} {
        send_operation_update REFERENCE_THRESHOLD $rfSaturateThreshold
        send_operation_update REFERENCE $rfWList  $rfCList
    }
}
proc spectrometerWrap_checkDark { send_update } {
    variable ::spectrometerWrap::dkCondition
    variable ::spectrometerWrap::dkWList
    variable ::spectrometerWrap::dkCList

    set dkValid [spectrometerWrap_conditionValid $dkCondition]
    if {!$dkValid} {
        log_error need to retake dark for new configuration
        return -code error dark_invalid
    } elseif {$send_update} {
        send_operation_update DARK $dkWList $dkCList
    }
}
proc spectrometerWrap_appendList { contentsREF level key list } {
    upvar $contentsREF contents

    set padLength [expr 4 * $level]
    set pad [string repeat " " $padLength]
    
    append contents "${pad}$key:\n"
    foreach e $list {
        append contents "${pad}    - $e\n"
    }
}
proc spectrometerWrap_writeYAMLHeader { \
    motorName startP endP numPoint timeWait \
} {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::rfCList
    variable ::spectrometerWrap::dkWList
    variable ::spectrometerWrap::dkCList
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::scanPath
    variable ::spectrometerWrap::scanPrefix
    variable spectroWrap_status
    variable spectro_config
    variable spectro_status
    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega

    foreach {iTime nAvg bWidth} $spectro_config break
    set devName [lindex $spectro_status 0]

    set fileBase ${bid}_${motorName}_[getScrabbleForFilename]
    set scanPrefix [file join $dir ${fileBase}]
    set scanPath   ${scanPrefix}.yaml
    set now [clock format [clock seconds] -format "%D %T"]

    set contents "---\n"
    append contents "title: scan_motor_for_microSpectrometer\n"
    append contents "motorName: $motorName\n"
    append contents "startP: $startP\n"
    append contents "endP: $endP\n"
    append contents "numPoint: $numPoint\n"
    append contents "settleTime: $timeWait\n"
    append contents "timestamp: $now\n"
    append contents "spectrometer: $devName\n"
    append contents "integrationTime: $iTime\n"
    append contents "scansToAverage: $nAvg\n"
    append contents "boxcarWidth: $bWidth\n"
    append contents "sample_x: $sample_x\n"
    append contents "sample_y: $sample_y\n"
    append contents "sample_z: $sample_z\n"
    append contents "sample_angle: [expr $gonio_phi + $gonio_omega]\n"
    spectrometerWrap_appendList contents 0 wavelength $rfWList
    spectrometerWrap_appendList contents 0 reference  $rfCList
    spectrometerWrap_appendList contents 0 dark       $dkCList
    append contents "scan_result:\n"

    if {![catch {open $scanPath w} handle]} {
        puts -nonewline $handle $contents
        close $handle
        set handle ""
        dict set spectroWrap_status scan_result [file tail $scanPath]
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to save spectrometer scan header to $scanPath: $errMsg
        return -code error failed_to_save_result
    }
}
proc spectrometerWrap_appendYAML { contents } {
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::scanPath

    if {![catch {open $scanPath a} handle]} {
        puts -nonewline $handle $contents
        close $handle
        set handle ""
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to save microspectrometer result to $scanPath: $errMsg
    }
}
proc spectrometerWrap_saveScanResult { index contents } {
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::scanPath
    variable ::spectrometerWrap::scanPrefix

    #### save the result to file first
    set filePath ${scanPrefix}_${index}.yaml
    if {![catch {open $filePath w} handle]} {
        puts -nonewline $handle $contents
        close $handle
        set handle ""
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to save micrSpec scan result result to \
        $filePath: $errMsg
        return
    }

    set fileName [file tail $filePath]
    send_operation_update SCAN_FILE $index $fileName

    if {![catch {open $scanPath a} handle]} {
        puts -nonewline $handle "    - ${fileName}\n"
        close $handle
        set handle ""
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to save microspectrometer result to $scanPath: $errMsg
    }
}
proc spectrometerWrap_autoTime { args } {
    variable spectro_config
    variable spectro_integration

    foreach {tLowLimit tHighLimit} [getGoodLimits spectro_integration] break


    #### counts: 0-65535.
    #### 65535 means saturated.
    #### peak target:
    set PEAK_RANGE_LOW  40000.0
    set PEAK_TARGET     50000.0
    set PEAK_RANGE_HIGH 55000.0
    if {$args != ""} {
        set percent [lindex $args 0]
        set PEAK_TARGET [expr 65535.0 * $percent]
    }
    log_warning Target Peak: $PEAK_TARGET


    #### set to no average, no boxcar
    set save_config $spectro_config
    set spectro_config [lreplace $save_config 1 2 0 0]
    wait_for_strings spectro_config

    if {[catch {
        for {set tryTime 0} {$tryTime < 5} {incr tryTime} {
            set peakInfo [spectrometerWrap_getPeakInfo]
            foreach {max indexMax numSaturated start length} $peakInfo break
            if {$max < $PEAK_RANGE_LOW} {
                if {$max <= 0} {
                    log_error get peak value 0. Something wrong.
                    return -code error peak_value_0
                }
                if {abs($spectro_integration - $tHighLimit) < 0.001} {
                    log_warning reached max integration time $tHighLimit \
                    with peak = $max
                    break
                }
                ### need increase integration time
                set ratio [expr $PEAK_TARGET / $max]
            } elseif {$max <= $PEAK_RANGE_HIGH} {
                log_warning good integration time: $spectro_integration \
                with peak = $max
                break
            } else {
                if {abs($spectro_integration - $tLowLimit) < 0.001} {
                    log_warning reached min integration time $tLowLimit \
                    with peak = $max
                    break
                }
                set ratio [expr $PEAK_TARGET / $max]
                if {$numSaturated > 0} {
                    set ratio 0.5
                    if {$length > 150} {
                        set ratio 0.3
                    }
                }
            }
            set newTime [expr $spectro_integration * $ratio]
            adjustPositionToLimit spectro_integration newTime 1
            log_warning retry with integration time $newTime
            move spectro_integration to $newTime
            wait_for_devices spectro_integration
        }
    } errMsg] == 1} {
        log_error optimize integration time failed: $errMsg
        set spectro_config $save_config
        return -code error FAILED
    }
    if {$tryTime >= 5} {
        log_error failed to get optimized integration time after 5 times trying.
    }

    #### restore other setup
    set spectro_config [lreplace $save_config 0 0 $spectro_integration]
}
proc spectrometerWrap_getPeakInfo { } {
    variable ::spectrometerWrap::rawWList
    variable ::spectrometerWrap::rawCList

    set oph [start_waitable_operation get_spectrum 1]
    set opr [wait_for_operation_to_finish $oph]
    if {[llength $opr] < 3} {
        log_error failed to acquire reference spectrum
        return -code failed
    }
    foreach {status rawWList rawCList} $opr break
    set rawWList [string trim $rawWList]
    set rawCList [string trim $rawCList]

    set SATURATED_COUNT 65535
    set max -1
    set indexMax -1
    set numSaturated 0
    set saturatedSectionList ""
    set sectStart -1
    set sectLength 0
    set i -1
    foreach c $rawCList {
        incr i
        if {$c > $max} {
            set max $c
            set indexMax $i
        }
        if {$c >= $SATURATED_COUNT} {
            incr numSaturated
            if {$sectLength == 0} {
                set sectLength 1
                set sectStart $i
            } else {
                incr sectLength
            }
        } else {
            if {$sectLength > 0} {
                lappend saturatedSectionList [list $sectStart $sectLength]
                set sectLength 0
                set sectStart -1
            }
        }
    }
    if {$sectLength > 0} {
        lappend saturatedSectionList [list $sectStart $sectLength]
    }
    if {$numSaturated == 0} {
        return [list $max $indexMax 0 0 0]
    }
    ### find max saturated section
    set sortedList [lsort -real -decreasing -index 1 $saturatedSectionList]
    set largest [lindex $sortedList 0]
    foreach {start length} $largest break

    return [list $max $indexMax $numSaturated $start $length]
}
proc spectrometerWrap_backupReferenceFile { } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::rfPath
    variable ::spectrometerWrap::rfCondition

    spectrometerWrap_purgeReference $rfCondition

    foreach {iTime nAvg bWidth} $rfCondition break
    set nTime [expr int($iTime * 1000)]

    set backupFile reference_${bid}_${nTime}_${nAvg}_${bWidth}.yaml

    set backupPath [file join $dir $backupFile]
    file copy -force $rfPath $backupPath

    set isStaff [get_operation_isStaff]
    if {$isStaff} {
        set backupPath [file join $dir system $backupFile]
        file copy -force $rfPath $backupPath
        log_warning reference save to system: $backupFile
    }
}
proc spectrometerWrap_backupDarkFile { } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::dkPath
    variable ::spectrometerWrap::dkCondition

    spectrometerWrap_purgeDark $dkCondition

    foreach {iTime nAvg bWidth} $dkCondition break
    set nTime [expr int($iTime * 1000)]

    set backupFile dark_${bid}_${nTime}_${nAvg}_${bWidth}.yaml

    set backupPath [file join $dir $backupFile]
    file copy -force $dkPath $backupPath

    set isStaff [get_operation_isStaff]
    if {$isStaff} {
        set backupPath [file join $dir system $backupFile]
        file copy -force $dkPath $backupPath
        log_warning dark save to system: $backupFile
    }
}
proc spectrometerWrap_scanTimeAndPhi { args } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::rfCList
    variable ::spectrometerWrap::dkWList
    variable ::spectrometerWrap::dkCList
    variable ::spectrometerWrap::rawWList
    variable ::spectrometerWrap::rawCList
    variable ::spectrometerWrap::absorbanceCList
    variable ::spectrometerWrap::transmittanceCList
    variable ::spectrometerWrap::handle
    variable spectro_config
    variable spectroWrap_status

    set ll [llength $args]
    if {$ll < 6} {
        log_error scan_motor need more parameters
        return -code error ARGS
    }

    clear_operation_stop_flag
    foreach {startTime endTime nPTime startPhi endPhi nPPhi} $args break

    set openShutter 0
    if {[lsearch $args shutter] >= 0} {
        set openShutter 1
        log_warning it will open shutter
    }

    if {[swapIfBacklash gonio_phi startPhi endPhi]} {
        log_warning swapped start and end position to avoid backlashing.
    }

    spectrometerWrap_checkReference 0
    spectrometerWrap_checkDark 0

    set sample_position [spectrometerWrap_getSamplePosition]

    send_operation_update SCAN_WAVELENGTH $rfWList
    send_operation_update SCAN_REFERENCE  $rfCList
    send_operation_update SCAN_DARK       $dkCList
    send_operation_update SCAN_CONDITION  $spectro_config
    send_operation_update SCAN_SAMPLE_POSITION $sample_position

    variable gonio_phi
    set orig_position $gonio_phi

    spectrometerWrap_writeYAMLHeader \
    gonio_phi $startPhi $endPhi $nPPhi 0

    set phiStepSize  [expr ($endPhi - $startPhi) / ($nPPhi - 1.0)]
    set timeStepSize [expr ($endTime - $startTime) / ($nPTime - 1.0) * 1000]
    

    if {$openShutter} {
        open_shutter shutter
        wait_for_shutters shutter
    }
    set total [expr $nPTime * $nPPhi]

    set tsStart [clock clicks -milliseconds]
    for {set iTime 0} {$iTime < $nPTime} {incr iTime} {
        set nextTime [expr $tsStart + $timeStepSize * $iTime]
        set tsNow [clock clicks -milliseconds]
        if {$nextTime > $tsNow} {
            set tWait [expr int($nextTime - $tsNow)]
            log_warning wait for next time in $tWait ms.
            wait_for_time $tWait
        }
        for {set iPhi 0} {$iPhi < $nPPhi} {incr iPhi} {
            set index [expr $iTime * $nPPhi + $iPhi]
            dict set spectroWrap_status scan_progress "$index of $total"
            set now [clock format [clock seconds] -format "%D %T"]
            if {[get_operation_stop_flag]} {
                break
            }
            set p [expr $startPhi + $iPhi * $phiStepSize]
            set contents "---\n"
            append contents "index: $index\n"
            append contents "position: $p\n"
            append contents "timestamp: $now\n"
            move gonio_phi to $p
            wait_for_devices gonio_phi
            set msgPrefix "scan_phi [expr $index + 1] of $total: "
            spectrometerWrap_acquire 0 $msgPrefix
        
            send_operation_update SCAN_RAW   $index $p $now $rawCList
            spectrometerWrap_appendList contents 0 raw  $rawCList
            spectrometerWrap_saveScanResult $index $contents
        }
    }
    set index [expr $iTime * $nPPhi + $iPhi]
    dict set spectroWrap_status scan_progress "$index of $total"

    dict set spectroWrap_status message "restoring gonio_phi"
    if {$openShutter} {
        close_shutter shutter
        wait_for_shutters shutter
    }
    move gonio_phi to $orig_position
    wait_for_devices gonio_phi
    if {[get_operation_stop_flag]} {
        log_error phi scan stopped by user.
    }
}
### it is called in other operations
proc spectrometerWrap_generatePointList { args } {
    foreach {motorName startP endP stepSize} $args break
    if {$motorName == "snapshot"} {
        return [list snapshot 0 0 0 1 0]
    }

    set ll [llength $args]
    if {$ll < 4} {
        log_error scan need more parameters
        return -code error ARGS
    }

    set bad 0
    if {$startP == $endP} {
        log_error end position cannot be the same as start position
        incr bad
    }
    if {$stepSize == 0} {
        log_error stepsize cannot be zero
        incr bad
    }
    if {$bad} {
        return -code error ARGS
    }

    if {[swapIfBacklash $motorName startP endP]} {
        log_warning swapped start and end position to avoid backlashing.
    }
    if {$motorName == "time" || $motorName == "dose"} {
        if {$startP < 0 || $endP <=0 || $stepSize <= 0} {
            log_error bad scan parameters
            return -code error ARGS
        }
    }

    set stepSize [expr abs($stepSize)]
    
    ### error: [expr ceil( 4.2 / 0.7)] == 7.0
    #set nPointM1 [expr int(ceil(abs($endP - $startP) / $stepSize))]
    set nPointM1 [expr abs($endP - $startP) / $stepSize]
    set nPointM1 [expr int(ceil($nPointM1))]
    set numPoint [expr $nPointM1 + 1]
    set stepSize [expr ($endP > $startP)?$stepSize:-$stepSize]

    if {[isMotor $motorName]} {
        set pList [list]
        for {set i 0} {$i < $nPointM1} {incr i} {
            set p [expr $startP + $i * $stepSize]
            lappend pList $p
        }
        if {abs($p - $endP) > 0.001} {
            lappend pList $endP
        } else {
            puts "DEBUG_ERROR: pList wrong: lastP=$p endp=$endP"
            puts "DEBUG_ERROR: startP=$startP stepSize=$stepSize"
            puts "DEBUG_ERROR: nPoint=$numPoint"
            incr numPoint -1
        }
    } else {
        ### for time and dose, the pList starting from 0
        set pList [list]
        set tsStepSize [expr int($stepSize * 1000)]
        for {set i 0} {$i < $nPointM1} {incr i} {
            set p [expr $i * $tsStepSize]
            lappend pList $p
        }
        ### last
        set dt [expr int(($endP - $startP) * 1000)]
        if {abs($dt - $p) > 1} {
            lappend pList $dt
        } else {
            puts "DEBUG_ERROR: pList wrong for time: lastP=$p end dt=$dt"
            puts "DEBUG_ERROR: startP=$startP endP=$endP stepSize=$stepSize"
            puts "DEBUG_ERROR: nPoint=$numPoint"
            incr numPoint -1
        }
    }

    return [list $motorName $startP $endP $stepSize $numPoint $pList]
}
proc spectrometerWrap_basicScan { args } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::rfCList
    variable ::spectrometerWrap::rfSaturateThreshold
    variable ::spectrometerWrap::dkWList
    variable ::spectrometerWrap::dkCList
    variable ::spectrometerWrap::rawWList
    variable ::spectrometerWrap::rawCList
    variable ::spectrometerWrap::absorbanceCList
    variable ::spectrometerWrap::transmittanceCList
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::statusStringName
    variable ::spectrometerWrap::psShutterOpen
    variable ::spectrometerWrap::doseRate
    variable spectro_config
    variable $statusStringName
    variable shutter

    set warningMsg ""

    set psShutterOpen 0
    set doseRate 0
    clear_operation_stop_flag

    foreach {motorName startP endP stepSize numPoint pList} \
    [eval spectrometerWrap_generatePointList $args] break

    spectrometerWrap_setupEnvironment $motorName
    spectrometerWrap_saveVideoSnapshot $motorName $pList

    set openShutter 0
    if {$motorName == "dose"} {
        set openShutter 1
    }
  
    ### move to position and setup lights
    spectrometerWrap_getReady
    ### only check, no operation update
    spectrometerWrap_checkReference 0
    spectrometerWrap_checkDark 0

    set sample_position [spectrometerWrap_getSamplePosition]

    ## this is needed in calculation of absorbance and tranmmittance.
    ## it is better in operation message, not status string message.
    send_operation_update SCAN_REFERENCE_THRESHOLD  $rfSaturateThreshold

    send_operation_update SCAN_WAVELENGTH $rfWList
    send_operation_update SCAN_REFERENCE  $rfCList
    send_operation_update SCAN_DARK       $dkCList
    send_operation_update SCAN_CONDITION  $spectro_config
    send_operation_update SCAN_SAMPLE_POSITION $sample_position

    set motorMovable 0
    if {[isMotor $motorName]} {
        variable $motorName
        set orig_position [set $motorName]
        set motorMovable 1
    }

    spectrometerWrap_writeBasicYAMLHeader \
    $motorName $startP $endP $stepSize $numPoint

    set tsStart [clock clicks -milliseconds]
    ### only used by time and dose
    set tsEnd [expr $tsStart + [lindex $pList end]]
    set i -1
    foreach p $pList {
        incr i
        dict set $statusStringName scan_progress "$i of $numPoint"
        if {[get_operation_stop_flag]} {
            set warningMsg "stopped by user"
            break
        }
        if {$motorMovable} {
            variable $motorName
            move $motorName to $p
            dict set $statusStringName message "waiting for $motorName"
            wait_for_devices $motorName
            #set position $p
            set position [set $motorName]
        } else {
            set nextTime [expr $tsStart + $p]
            set tsNow [clock clicks -milliseconds]
            if {$tsNow > $tsEnd && $motorName != "snapshot"} {
                log_error reached duration time before taking all the scans.
                user_log_error microspec \
                reached duration time before taking all the scans.

                set warningMsg \
                "reached duration time before taking all the scans"
                break
            }
            if {$nextTime > $tsNow} {
                set tWait [expr int($nextTime - $tsNow)]
                log_warning wait for next point in $tWait ms.
                wait_for_time $tWait
                set position [expr $p / 1000.0]
            } else {
                if {$i != 0} {
                    log_warning time step size too small
                }
                set position [expr ($tsNow - $tsStart) / 1000.0]
            }
        }
        set msgPrefix "scan $motorName [expr $i + 1] of $numPoint: "
        set now [clock format [clock seconds] -format "%D %T"]

        if {$psShutterOpen > 0 && $doseRate > 0} {
            set dose [expr $doseRate * ($position - $psShutterOpen)]
        } else {
            set dose 0
        }

        set tsOneStart [clock clicks -milliseconds]
        spectrometerWrap_acquire 0 $msgPrefix
        set tsOneGot [clock clicks -milliseconds]
        
        send_operation_update EXTENDED_SCAN_RAW \
        $i $position $now $rawCList $dose

        if {$i == 0 && $openShutter} {
            open_shutter shutter
            wait_for_shutters shutter
            set tsNow [clock clicks -milliseconds]
            set psShutterOpen [expr ($tsNow - $tsStart) / 1000.0]

            puts "shutter open at: $psShutterOpen"
        }

        set contents "---\n"
        append contents "index: $i\n"
        append contents "position: $position\n"
        append contents "timestamp: $now\n"
        if {$dose > 0} {
            append contents "dose: $dose\n"
            append contents "doseRate: $doseRate\n"
        }
        spectrometerWrap_appendList contents 0 raw           $rawCList
        spectrometerWrap_saveBasicScanResult $i $motorName $position $contents

        if {$i == 0 && $openShutter} {
            user_log_note microspec \
            time=[format %.3f $psShutterOpen] shutter opened
        }
        set tsOneEnd [clock clicks -milliseconds]
        puts "OneShot: done [expr $tsOneGot - $tsOneStart] end=[expr $tsOneEnd  - $tsOneStart]"
    }
    dict set $statusStringName scan_progress "[expr $i +1 ] of $numPoint"

    if {$motorMovable} {
        dict set $statusStringName message "restoring $motorName"
        move $motorName to $orig_position
        set mList [spectrometerWrap_moveLensOut 1]
        eval wait_for_devices $motorName $mList
    }
    if {[get_operation_stop_flag]} {
        log_error stopped by user.
    }

    if {$warningMsg != ""} {
        dict set $statusStringName message "Warning: $warningMsg"
    }
}
proc spectrometerWrap_setupEnvironment { motorName } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::scanPath
    variable ::spectrometerWrap::scanPrefix
    variable ::spectrometerWrap::statusStringName
    variable spectro_config
    variable $statusStringName

    foreach {iTime nAvg bWidth} $spectro_config break
    set fileBase ${bid}_${motorName}_[getScrabbleForFilename]
    set userFileBase ${bid}_${motorName}_[timeStampForFileName]

    #sytem: cannot save to status, otherwise, the BluIce will try to load it.
    set scanPrefix [file join $dir ${fileBase}]
    set scanPath   ${scanPrefix}.yaml

    ### user saved to status
    set status [set $statusStringName]
    set userScanDir    [dict get $status user_scan_dir]
    set userScanPrefix [file join $userScanDir ${userFileBase}]
    set userScanFile   ${userScanPrefix}.yaml
    dict set $statusStringName user_scan_file $userScanFile
    dict set $statusStringName user_scan_prefix $userScanPrefix
}
proc spectrometerWrap_writeBasicYAMLHeader { \
    motorName startP endP stepSize numPoint\
} {
    global gMotorBeamWidth
    global gMotorBeamHeight

    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::rfCList
    variable ::spectrometerWrap::rfSaturateThreshold
    variable ::spectrometerWrap::dkWList
    variable ::spectrometerWrap::dkCList
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::scanPath
    variable ::spectrometerWrap::scanPrefix
    variable ::spectrometerWrap::statusStringName
    variable ::spectrometerWrap::userName
    variable ::spectrometerWrap::sessionId
    variable ::spectrometerWrap::doseRate
    variable spectro_config
    variable spectro_status
    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega
    variable shutter
    variable spectroWrap_config

    variable $statusStringName

    foreach {iTime nAvg bWidth} $spectro_config break
    set devName [lindex $spectro_status 0]

    set lightSpotDiameter [lindex $spectroWrap_config 3]

    set now [clock format [clock seconds] -format "%D %T"]

    send_operation_update SCAN_HEADER_FILE [file tail $scanPath]

    set contents "---\n"
    append contents "title: scan_motor_for_microSpectrometer\n"
    append contents "beamline: $bid\n"
    append contents "ligntSpotDiameter: $lightSpotDiameter\n"
    append contents "motorName: $motorName\n"
    append contents "startP: $startP\n"
    append contents "endP: $endP\n"
    append contents "stepSize: $stepSize\n"
    append contents "numPoint: $numPoint\n"
    append contents "timestamp: $now\n"
    append contents "spectrometer: $devName\n"
    append contents "integrationTime: $iTime\n"
    append contents "scansToAverage: $nAvg\n"
    append contents "boxcarWidth: $bWidth\n"
    append contents "sample_x: $sample_x\n"
    append contents "sample_y: $sample_y\n"
    append contents "sample_z: $sample_z\n"
    append contents "sample_angle: [expr $gonio_phi + $gonio_omega]\n"
    append contents "shutter: $shutter\n"
    append contents "reference_threshold: $rfSaturateThreshold\n"
    if {$motorName == "dose"} {
        variable energy
        variable attenuation
        variable $gMotorBeamWidth
        variable $gMotorBeamHeight
        append contents "energy: $energy\n"
        append contents "attenuation: $attenuation\n"
        append contents \
        "beamsize: [set $gMotorBeamWidth]X[set $gMotorBeamHeight]\n"

        if {[catch spectrometerWrap_getDoseRate doseRate]} {
            log_error get dose rate failed: $doseRate
            set doseRate 0
        }
        append contents \
        "dose_rate: $doseRate\n"

        send_operation_update SCAN_DOSE_RATE $doseRate
    }

    spectrometerWrap_appendList contents 0 wavelength $rfWList
    spectrometerWrap_appendList contents 0 reference  $rfCList
    spectrometerWrap_appendList contents 0 dark       $dkCList
    append contents "scan_result:\n"

    if {![catch {open $scanPath w} handle]} {
        puts -nonewline $handle $contents
        close $handle
        set handle ""
        dict set $statusStringName scan_result [file tail $scanPath]
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to save spectrometer scan header to $scanPath: $errMsg
        return -code error failed_to_save_result
    }

    ##### copy to user directory
    set status [set $statusStringName]
    set userScanFile   [dict get $status user_scan_file]
    impCopyFile $userName $sessionId $scanPath $userScanFile

    user_log_note microspec header_file $userScanFile
}
proc spectrometerWrap_saveBasicScanResult {index motorName position contents} {
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::scanPath
    variable ::spectrometerWrap::scanPrefix
    variable ::spectrometerWrap::statusStringName
    variable ::spectrometerWrap::userName
    variable ::spectrometerWrap::sessionId

    variable $statusStringName

    #### save the result to file first
    set filePath ${scanPrefix}_${index}.yaml
    if {![catch {open $filePath w} handle]} {
        puts -nonewline $handle $contents
        close $handle
        set handle ""
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to save micrSpec scan result result to \
        $filePath: $errMsg
        return
    }

    set fileName [file tail $filePath]
    send_operation_update SCAN_FILE $index $fileName

    set lineToAppend "    - ${fileName}\n"
    if {![catch {open $scanPath a} handle]} {
        puts -nonewline $handle $lineToAppend
        close $handle
        set handle ""
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to save microspectrometer result to $scanPath: $errMsg
    }

    ########### user file #################
    #set filePath ${scanPrefix}_${index}.yaml
    #set fileName [file tail $filePath]
    #set lineToAppend "    - ${fileName}\n"

    set status [set $statusStringName]
    set userScanPrefix [dict get $status user_scan_prefix]
    set userFilePath ${userScanPrefix}_${index}.yaml
    set userFileName [file tail $userFilePath]

    set userScanFile [dict get $status user_scan_file]
    set userLineToAppend "    - ${userFileName}\n"

    impCopyFile $userName $sessionId $filePath $userFilePath
    impAppendTextFile $userName $sessionId $userScanFile $userLineToAppend

    if {[isMotor $motorName]} {
        user_log_note microspec \
        $motorName=[format "%.3f" $position] $userFilePath
    } else {
        user_log_note microspec time=[format "%.3f" $position] \
        $userFilePath
    }
}
proc microspecLightControl_callback { } {
    variable ::spectrometerWrap::lightOnTimestamp
    variable ::spectrometerWrap::previousLightStatus

    variable microspecLightControl

    if {[catch {
        set lightStatus [dict get $microspecLightControl HALOGEN]
    } errMsg]} {
        puts "ERROR in microSpecLightControl_callback: $errMsg"
        set lightStatus off
    }
    if {$previousLightStatus == ""} {
        ### first time since dcss startup
        set previousLightStatus $lightStatus
        set lightOnTimestamp 0
        return
    }
    if {$lightStatus == "on"} {
        if {$previousLightStatus != "on"} {
            set lightOnTimestamp [clock seconds]
            puts "set lightOnTimestamp to [clock format $lightOnTimestamp -format {%D %T}]" 
        }
    } else {
        set lightOnTimestamp ""
    }
    set previousLightStatus $lightStatus
}
proc spectrometerWrap_checkLight { } {
    variable ::spectrometerWrap::lightOnTimestamp
    variable ::spectrometerWrap::statusStringName
    variable spectroWrap_config
    variable microspecLightControl

    variable $statusStringName

    set delay [lindex $spectroWrap_config 0]

    set timeToWait 0
    set lightStatus [dict get $microspecLightControl HALOGEN]
    puts "spectrometerWrap_checkLight delay=$delay light=$lightStatus"
    puts "timestamp=$lightOnTimestamp"
    if {$lightStatus == "off"} {
        set microspecLightControl "HALOGEN on"
        dict set $statusStringName message \
        "waiting for the light to turn on"
        while {$lightStatus != "on"} {
            wait_for_strings microspecLightControl
            set lightStatus [dict get $microspecLightControl HALOGEN]
        }
        if {[string is double -strict $delay] && $delay > 0} {
            set timeToWait $delay
        }
    } else {
        if {[string is double -strict $lightOnTimestamp] \
        &&  [string is double -strict $delay] && $delay > 0} {
            set timeNow [clock seconds]
            set timeReady [expr $lightOnTimestamp + $delay]
            if {$timeNow < $timeReady} {
                set timeToWait [expr $timeReady - $timeNow]
                puts "need delay $timeToWait"
            }
        }
    }
    while {$timeToWait > 0} {
        set n_min     [expr int($timeToWait + 59) / 60]
        set n_oneWait [expr ($timeToWait > 60)?60:$timeToWait]

        if {$n_min > 1} {
            set msg "$n_min minutes"
        } else {
            set msg "$n_oneWait seconds"
        }
        dict set $statusStringName message \
        "waiting $msg for microspec light to stablize"

        wait_for_time [expr int(1000 * $n_oneWait)]
        set timeToWait [expr $timeToWait - 60]
    }
    dict set $statusStringName message ""
}
proc spectrometerWrap_checkMotor { {wait 0} } {
    variable ::spectrometerWrap::statusStringName
    variable $statusStringName
    variable microspec_z_corr

    if {abs($microspec_z_corr) > 0.001} {
        dict set $statusStringName message "moving microspec to position"
        move microspec_z_corr to 0
        if {$wait} {
            wait_for_devices microspec_z_corr
            return ""
        }
        return microspec_z_corr
    }
    return ""
}
proc spectrometerWrap_checkDirectory { } {
    variable ::spectrometerWrap::statusStringName
    variable ::spectrometerWrap::userName
    variable ::spectrometerWrap::sessionId
    variable $statusStringName

    set status  [set $statusStringName]
    set userDir [dict get $status user_dir]

    if {[checkUsernameInDirectory userDir $userName]} {
        dict set $statusStringName user_dir $userDir
    }

    set userPrefix [dict get $status user_prefix]
    set counter \
    [impDirectoryWritable $userName $sessionId $userDir $userPrefix]
    set userScanDir [file join $userDir ${userPrefix}_${counter}]
    impDirectoryWritable $userName $sessionId $userScanDir

    dict set $statusStringName user_scan_dir $userScanDir
    dict set $statusStringName user_counter [expr $counter + 1]
}
proc spectrometerWrap_prepare { } {
    variable ::spectrometerWrap::statusStringName
    variable $statusStringName
    variable microspecLightControl

    set contents [set $statusStringName]
    dict set contents scan_result "" 
    dict set contents user_scan_file ""
    dict set contents user_scan_prefix ""
    dict set contents scan_progress "0 of 100"

    set $statusStringName $contents

    if {[catch spectrometerWrap_checkHardware errMsg]} {
        dict set $statusStringName message "ERROR: hardware failure: $errMsg"
        log_severe timeout in talking to microspec. \
        May need to restart the service on the pc.

        return -code error $errMsg
    }

    set lightStatus [dict get $microspecLightControl HALOGEN]
    if {$lightStatus == "off"} {
        set microspecLightControl "HALOGEN on"
    }

    dict set $statusStringName message "checking directory"
    spectrometerWrap_checkDirectory
    dict set $statusStringName message ""
}
proc spectrometerWrap_getReady { } {
    if {[lightsControl_start setup visex]} {
        log_warning wait for sample lights to turn off
        wait_for_time 1000
    }

    #### peudo motor here cause trouble, so  we need to wait first
    #set needWait [spectrometerWrap_checkMotor]
    spectrometerWrap_checkMotor 1
    spectrometerWrap_checkLight
}
proc spectrometerWrap_getDoseRate { } {
    global gMotorBeamWidth
    global gMotorBeamHeight

    variable energy
    variable flux
    variable $gMotorBeamWidth
    variable $gMotorBeamHeight

    ### make sure to get up to date flux
    move flux to 0
    wait_for_devices flux

    puts "dose calculation with flux=$flux"

    set beamWidth  [set $gMotorBeamWidth]
    set beamHeight [set $gMotorBeamHeight]
    set energyInKeV [expr $energy / 1000.0]
    set fluxPPS     [expr $flux * 1.0e11]

    set exe [::config getStr "raddose.path"]
    if {$exe == "" || ![file executable $exe]} {
        log_error cannot find raddose to do the calculation
        user_log_warning microspec failed to calculate the dose.
        return 0
    }

    if {$fluxPPS < 100.0} {
        log_error flux is 0, no real beam
        user_log_warning microspec failed to calculate the dose.
        return 0
    }

    set input "REMARK Absorbed dose per 1e-3 cubic mm of protein"
    append input "\nCELL 90. 90. 90. 90. 90. 90."
    append input "\nSOLVENT 0.5"
    append input "\nCRYSTAL 0.1 0.1 0.1"
    append input "\nBEAM $beamWidth $beamHeight"
    append input "\nENERGY $energyInKeV"
    append input "\nPHOSEC $fluxPPS"
    append input "\nGAUSS $beamWidth $beamHeight"
    append input "\nIMAGES 1"
    append input "\nEXPOSURE 1.0"
    append input "\nUSERLI 1.5e+07"
    append input "\nEND"

    set output [exec $exe << $input]

    set lines [split $output "\n"]

    set dose 0
    set found 0
    foreach line $lines {
        if {[string first "Total absorbed dose" $line] >= 0} {
            puts "raddose:$line"
            if {[llength $line] > 4} {
                set dose [lindex $line 4]
                if {[string is double -strict $dose]} {
                    set found 1
                    break
                }
            }
        }
    }
    if {!$found} {
        puts "raddose failed"
        puts "input=$input"
        puts "ouput=$output"
        user_log_warning microspec failed to calculate the dose.
        return 0
    }
    puts "raddose: dose rate $dose"
    return $dose
}
proc spectrometerWrap_searchReference { } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::rfPath
    variable spectro_config
    variable spectro_config_msg

    foreach {iTime nAvg bWidth} $spectro_config break
    set nTime [expr int($iTime * 1000)]

    set refPat reference_${bid}_${nTime}_*_${bWidth}.yaml
    set refList [glob -directory $dir -types f -nocomplain -tails $refPat]

    set maxAvg -1
    foreach ref $refList {
        set n [scan $ref reference_${bid}_${nTime}_%d_  a]
        if {$n == 1 && $a > $maxAvg} {
            set maxAvg $a
        }
    }
    if {$maxAvg < $nAvg} {
        log_error no reference found for $spectro_config
        return
    }

    set file reference_${bid}_${nTime}_${maxAvg}_${bWidth}.yaml
    set path [file join $dir $file]
    if {[file readable $path]} {
        set spectro_config_msg "loading reference"
        file copy -force $path $rfPath
        spectrometerWrap_retrieveReference
    }
}
proc spectrometerWrap_searchDark { } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::dkPath
    variable spectro_config
    variable spectro_config_msg

    foreach {iTime nAvg bWidth} $spectro_config break
    set nTime [expr int($iTime * 1000)]

    set drkPat dark_${bid}_${nTime}_*_${bWidth}.yaml
    set drkList [glob -directory $dir -types f -nocomplain -tails $drkPat]

    set maxAvg -1
    foreach drk $drkList {
        set n [scan $drk dark_${bid}_${nTime}_%d_  a]
        if {$n == 1 && $a > $maxAvg} {
            set maxAvg $a
        }
    }
    if {$maxAvg < $nAvg} {
        log_error no dark found for $spectro_config
        return
    }

    set file dark_${bid}_${nTime}_${maxAvg}_${bWidth}.yaml

    set path [file join $dir $file]
    if {[file readable $path]} {
        set spectro_config_msg "loading dark"
        file copy -force $path $dkPath
        spectrometerWrap_retrieveDark
    }
}
proc spectrometerWrap_removeUserFiles { } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid

    variable spectroWrap_status
    variable microspec_phiScan_status
    variable microspec_doseScan_status
    variable microspec_timeScan_status
    variable microspec_snapshot_status

    foreach sName [list \
    spectroWrap_status \
    microspec_phiScan_status \
    microspec_doseScan_status \
    microspec_timeScan_status \
    microspec_snapshot_status \
    ] {
        set contents [set $sName]
        dict set contents scan_result "" 
        dict set contents user_scan_file ""
        dict set contents user_scan_prefix ""
        dict set contents message ""
        set $sName $contents
    }

    set pat *
    set l [glob -directory $dir -types f -nocomplain $pat]
    if {$l != ""} {
        eval file delete -force $l
    }
    
    #### copy sytem files (created by staff) to current ...
    set sys_dir [file join $dir system]
    set l [glob -directory $sys_dir -nocomplain $pat]
    if {$l != ""} {
        eval file copy -force $l $dir
    }
}
proc spectrometerWrap_removeResultFiles { } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid

    variable spectroWrap_status
    variable microspec_phiScan_status
    variable microspec_doseScan_status
    variable microspec_timeScan_status
    variable microspec_snapshot_status

    foreach sName [list \
    spectroWrap_status \
    microspec_phiScan_status \
    microspec_doseScan_status \
    microspec_timeScan_status \
    microspec_snapshot_status \
    ] {
        set contents [set $sName]
        dict set contents scan_result "" 
        dict set contents user_scan_dir ""
        dict set contents user_scan_file ""
        dict set contents user_scan_prefix ""
        dict set contents user_counter ""
        dict set contents message ""
        set $sName $contents
    }

    set pat ${bid}_*
    set l [glob -directory $dir -types f -nocomplain $pat]
    if {$l != ""} {
        eval file delete -force $l
    }
}
proc spectrometerWrap_removeSetupFiles { } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid

    set pat reference_*
    set sys_dir [file join $dir system]
    set l [glob -directory $sys_dir -nocomplain $pat]
    if {$l != ""} {
        eval file delete -force $l
    }

    set pat dark_*
    set l [glob -directory $sys_dir -nocomplain $pat]
    if {$l != ""} {
        eval file delete -force $l
    }
}
proc spectrometerWrap_resetScanParameters { } {
    variable microspec_timeScan_status
    variable microspec_phiScan_status
    variable microspec_doseScan_status
    variable microspec_snapshot_status
    variable microspec_default
    variable spectro_config

    set cfgDefault      [lindex $microspec_default 0]
    set timeDefault     [lindex $microspec_default 1]
    set phiDefault      [lindex $microspec_default 2]
    set doseDefault     [lindex $microspec_default 3]
    set snapshotDefault [lindex $microspec_default 4]

    set spectro_config $cfgDefault
    wait_for_strings spectro_config

    #############3 time ###############
    foreach {prefix dir start end step} $timeDefault break
    set dddd [eval dict create $microspec_timeScan_status]
    dict set dddd user_prefix $prefix
    dict set dddd user_dir    $dir
    dict set dddd start       $start
    dict set dddd end         $end
    dict set dddd step_size   $step

    set microspec_timeScan_status $dddd

    ##############3 phi #####################
    foreach {prefix dir start end step} $phiDefault break
    set dddd [eval dict create $microspec_phiScan_status]
    dict set dddd user_prefix $prefix
    dict set dddd user_dir    $dir
    dict set dddd start       $start
    dict set dddd end         $end
    dict set dddd step_size   $step

    set microspec_phiScan_status $dddd

    ############## dose #####################
    foreach {prefix dir start end step en att phi w h} $doseDefault break
    set dddd [eval dict create $microspec_doseScan_status]
    dict set dddd user_prefix $prefix
    dict set dddd user_dir    $dir
    dict set dddd start       $start
    dict set dddd end         $end
    dict set dddd step_size   $step
    dict set dddd energy      $en
    dict set dddd attenuation $att
    dict set dddd gonio_phi   $phi
    dict set dddd beam_width  $w
    dict set dddd beam_height $h

    set microspec_doseScan_status $dddd

    #############3 snapshot ###############
    foreach {prefix dir} $snapshotDefault break
    set dddd [eval dict create $microspec_snapshot_status]
    dict set dddd user_prefix $prefix
    dict set dddd user_dir    $dir

    set microspec_snapshot_status $dddd

    return OK
}
proc spectrometerWrap_batchRefereanceAndDark { args } {
    variable spectro_config
    variable microspec_setup_batch

    if {$args == ""} {
        set sorted \
        [lsort -unique -command spectrometerWrap_listSortCmd $microspec_setup_batch]
        set onlyMax [spectrometerWrap_listMaxAverageOnly $sorted]
        if {[llength $onlyMax] != [llength $microspec_setup_batch]} {
            log_error repeated setup removed.  Only max average times kept.
            set microspec_setup_batch $onlyMax
        }
        set args $microspec_setup_batch
    } else {
        set sorted \
        [lsort -unique -command spectrometerWrap_listSortCmd $args]
        set onlyMax [spectrometerWrap_listMaxAverageOnly $sorted]
        if {[llength $onlyMax] != [llength $args]} {
            log_error repeated setup removed.  Only max average times needed.
            set args $onlyMax
        }
    }

    if {![get_operation_isStaff]} {
        log_error only staff can do batch
        return -code error STAFF_ONLY
    }

    ### dark first
    spectrometerWrap_moveLensOut
    foreach condition $args {
        set spectro_config $condition
        wait_for_devices spectro_config
        spectrometerWrap_saveDark
        spectrometerWrap_backupDarkFile
    }
    #### reference
    spectrometerWrap_checkMotor 1
    spectrometerWrap_checkLight
    foreach condition $args {
        set spectro_config $condition
        wait_for_devices spectro_config
        spectrometerWrap_saveReference
        spectrometerWrap_backupReferenceFile
    }

    spectrometerWrap_moveLensOut
    return ALL_DONE
}
proc spectrometerWrap_clear { item } {
    variable spectroWrap_status

    set newContents $spectroWrap_status

    if {$item == "reference" || $item == "both"} {
        dict set newContents refValid 0
        dict set newContents refIntegrationTime  -
        dict set newContents refScansToAverage   -
        dict set newContents refBoxcarWidth      -
        dict set newContents refSaturated        0
        dict set newContents refTimestamp        -
    }
    if {$item == "dark" || $item == "both"} {
        dict set newContents darkValid 0
        dict set newContents darkIntegrationTime -
        dict set newContents darkScansToAverage  -
        dict set newContents darkBoxcarWidth     -
        dict set newContents darkTimestamp       -
    }

    set spectroWrap_status $newContents
}
proc spectrometerWrap_checkTimeStepSize { contentsREF } {
    variable ::spectrometerWrap::minTimeStep

    upvar $contentsREF contents

    set stepSize [dict get $contents step_size]
    if {$stepSize < $minTimeStep} {
        dict set contents step_size $minTimeStep
        dict set contents message \
        "WARNING: step adjusted to $minTimeStep, which is minimum for this setup"
    }
}
proc spectrometerWrap_setParemeters { mode args } {
    variable ::spectrometerWrap::userName
    variable ::spectrometerWrap::sessionId
    variable ::spectrometerWrap::minTimeStep

    variable microspec_phiScan_status
    variable microspec_doseScan_status
    variable microspec_timeScan_status
    variable microspec_snapshot_status

    switch -exact -- $mode {
        snapshot {
            set sName microspec_snapshot_status
        }
        time_scan {
            set sName microspec_timeScan_status
        }
        phi_scan {
            set sName microspec_phiScan_status
        }
        dose_scan {
            set sName microspec_doseScan_status
        }
        default {
            log_error not supported mode=$mode
            return -code error WRONG_MODE
        }
    }
    set ll [llength $args]
    if {$ll % 2} {
        log_error wrong number of argument for setParameters
        return -code error WRONG_ARGS
    }
    set needUpdateCounter 0
    set newDir ""

    set contents [set $sName]
    set newContents [eval dict create $contents]
    foreach {name value} $args {
        dict set newContents $name $value
        if {$name == "step_size"} {
            if {$mode == "time_scan" || $mode == "dose_scan"} {
                spectrometerWrap_checkTimeStepSize newContents
            }
        }
        if {$name == "user_dir"} {
            set newDir $value
            set needUpdateCounter 1
        } elseif {$name == "user_prefix"} {
            set needUpdateCounter 1
        }
    }
    if {$needUpdateCounter} {
        set userDir    [dict get $newContents user_dir]
        set userPrefix [dict get $newContents user_prefix]
        if {[catch {
            impDirectoryWritable $userName $sessionId $userDir $userPrefix
        } counter]} {
            log_error $counter
            set counter NOT_WRITABLE_DIR
        }
        dict set newContents user_counter $counter
    }
    set $sName $newContents

    if {$newDir == ""} {
        return OK
    }
    foreach aName [list \
    microspec_phiScan_status \
    microspec_doseScan_status \
    microspec_timeScan_status \
    microspec_snapshot_status \
    ] {
        if {$aName == $sName} {
            continue
        }
        set contents [set $aName]
        set newContents [eval dict create $contents]
        dict set newContents user_dir $newDir
        set userPrefix [dict get $newContents user_prefix]
        if {[catch {
            impDirectoryWritable $userName $sessionId $newDir $userPrefix
        } counter]} {
            log_error $counter
            set counter NOT_WRITABLE_DIR
        }
        dict set newContents user_counter $counter
        if {$aName == "microspec_timeScan_status" \
        ||  $aName == "microspec_doseScan_status" \
        } {
            spectrometerWrap_checkTimeStepSize newContents
        }

        set $aName $newContents
    }
    return OK
}
proc spectrometerWrap_generateValidSetupList { } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable microspec_validSetup

    set refPat reference_${bid}_*.yaml
    set drkPat dark_${bid}_*.yaml
    set refList [glob -directory $dir -types f -nocomplain -tails $refPat]
    set drkList [glob -directory $dir -types f -nocomplain -tails $drkPat]

    set refValidList ""
    foreach ref $refList {
        set n [scan $ref reference_${bid}_%d_%d_%d i a b]
        if {$n == 3} {
            lappend refValidList [list $i $a $b]
        }
    }
    set drkValidList ""
    foreach drk $drkList {
        if {[scan $drk dark_${bid}_%d_%d_%d i a b] == 3} {
            lappend drkValidList [list $i $a $b]
        }
    }

    set refSorted \
    [lsort -unique -command spectrometerWrap_listSortCmd $refValidList]

    set drkSorted \
    [lsort -unique -command spectrometerWrap_listSortCmd $drkValidList]

    set llRef [llength $refSorted]
    set llDrk [llength $drkSorted]
    if {$llRef == 0 || $llDrk == 0} {
        set microspec_validSetup ""
        return ""
    }
    set bothValidList ""
    set refIndex 0
    set drkIndex 0
    set ref [lindex $refSorted $refIndex]
    set drk [lindex $drkSorted $drkIndex]    
    while {1} {
        set cmp [spectrometerWrap_listSortCmd $ref $drk]
        if {$cmp == 0} {
            lappend bothValidList $ref
            incr refIndex
            incr drkIndex
            if {$refIndex >= $llRef || $drkIndex >= $llDrk} {
                break
            }
            set ref [lindex $refSorted $refIndex]
            set drk [lindex $drkSorted $drkIndex]    
        } elseif {$cmp < 0} {
            incr refIndex
            if {$refIndex >= $llRef} {
                break
            }
            set ref [lindex $refSorted $refIndex]
        } else {
            incr drkIndex
            if {$drkIndex >= $llDrk} {
                break
            }
            set drk [lindex $drkSorted $drkIndex]    
        }
    }
    set bothValidList [spectrometerWrap_listMaxAverageOnly $bothValidList]
    # for now, let BluIce expand it.
    #set bothValidList [spectrometerWrap_expandValidSetupList $bothValidList]
    set microspec_validSetup $bothValidList
    return $bothValidList
}
proc spectrometerWrap_listSortCmd { e1 e2 } {
    foreach {i1 a1 b1} $e1 break
    foreach {i2 a2 b2} $e2 break

    if {$i1 > $i2} {
        return 1
    } elseif {$i1 < $i2} {
        return -1
    }
    if {$b1 > $b2} {
        return 1
    } elseif {$b1 < $b2} {
        return -1
    }
    if {$a1 > $a2} {
        return 1
    } elseif {$a1 < $a2} {
        return -1
    }

    return 0
}
proc spectrometerWrap_listMaxAverageOnly { inputList } {
    puts "clean up list: $inputList"

    if {[llength $inputList] < 2} {
        return $inputList
    }

    set previous [lindex $inputList 0]
    foreach {preTime - preBC} $previous break
    set result ""
    foreach condition $inputList {
        puts "checking $condition"
        foreach {iTime - nBC} $condition break
        if {abs($iTime - $preTime) > 0.001 || $nBC != $preBC} {
            lappend result $previous
        }
        set previous $condition
        foreach {preTime - preBC} $previous break
    }
    lappend result $previous
    puts "result: $result"
    return $result
}
proc spectrometerWrap_extendRef2File { iTime  } {
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::rfPath
    variable ::spectrometerWrap::rfCondition
    variable ::spectrometerWrap::rfSaturateThreshold
    variable ::spectrometerWrap::rfSaturated
    variable ::spectrometerWrap::rfTimestamp
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::rfCList
    variable ::spectrometerWrap::dkCList
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid

    if {![get_operation_isStaff]} {
        log_error only staff can extend the reference
        return -code error STAFF_ONLY
    }

    foreach {t n c} $rfCondition break
    if {$iTime <= $t} {
        log_error extended reference expecting a longer integration time > $t
        return -code error BAD_ARGS
    }

    set extendedCondition [list $iTime $n $c]
    set extendedDark [spectrometerWrap_getDarkFromCondition $extendedCondition]

    set nTime [expr int($iTime * 1000)]
    set fileName reference_${bid}_${nTime}_${n}_${c}.yaml

    set scaling [expr 1.0 * $iTime / $t]
    set newSaturateThreshold [expr $rfSaturateThreshold * $scaling]
    set srfCList ""
    foreach v $rfCList old_dark $dkCList new_dark $extendedDark {
        if {$v < $rfSaturateThreshold} {
            set pureRef [expr $v - $old_dark]
            if {$pureRef < 0} {
                set pureRef 0
            }
            set newPureRef [expr $pureRef * $scaling]
            set newRef [expr $newPureRef + $new_dark]
        } else {
            set newRef $newSaturateThreshold
        }
        lappend srfCList $newRef
    }

    set hW [eval huddle list $rfWList]
    set hC [eval huddle list $srfCList]

    set hhhh [huddle create \
    TITLE spectrometer_reference \
    integrationTime $iTime \
    scansToAverage  $n \
    boxcarWidth     $c \
    saturateThreshold $newSaturateThreshold \
    numSaturated    $rfSaturated \
    warning         "reference extended from $t second" \
    timestamp       $rfTimestamp \
    timestamp_txt   [clock format $rfTimestamp -format "%D %T"] \
    wavelengthList  $hW \
    countList       $hC \
    ]

    set yyyy [::yaml::huddle2yaml $hhhh 4 80]

    if {$handle != ""} {
        close $handle
        set handle ""
    }
    set filePath [file join $dir $fileName]

    set condition [lreplace $rfCondition 0 0 $iTime] 
    spectrometerWrap_purgeReference $condition

    if {![catch {open $filePath w} handle]} {
        puts $handle $yyyy
        close $handle
        set handle ""
        log_warning extended reference saved to $fileName
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to save extended reference to $filePath: $errMsg
        return -code error $errMsg
    }
    set backupPath [file join $dir system $fileName]
    file copy -force $filePath $backupPath
    log_warning reference save to system: $fileName
}
proc spectrometerWrap_checkHardware { } {
    variable spectro_config

    foreach {iTime nAvg bWidth} $spectro_config break

    ### estimate operation time
    set hardTime [expr $iTime * $nAvg]
    set timeToWait [expr $hardTime * 2.0 + 2.0]
    set timeInMs [expr int($timeToWait * 1000.0)]

    set tsStart [clock clicks -milliseconds]
    set oph [start_waitable_operation get_spectrum 1]
    set opr [wait_for_operation_to_finish $oph $timeInMs]
    set tsNow [clock clicks -milliseconds]
    puts "get spectrum time=[expr $tsNow - $tsStart]"
}
proc spectrometerWrap_saveVideoSnapshot { motorName pList } {
    variable ::spectrometerWrap::userName
    variable ::spectrometerWrap::sessionId
    variable ::spectrometerWrap::scanPath
    variable ::spectrometerWrap::scanPrefix
    variable ::spectrometerWrap::statusStringName

    variable $statusStringName
    variable gonio_phi
    variable camera_view_phi
    variable spectroWrap_config

    set lightDiameter [lindex $spectroWrap_config 3]
    ### use high zoom, the light Diameter is quite small
    set limits [getGoodLimits camera_zoom]
    set upperL [lindex $limits 1]
    move camera_zoom to $upperL
    # wait later
    #wait_for_devices camera_zoom

    set d_phi [expr $camera_view_phi(sample) - $camera_view_phi(microspec)]
    puts "d_phi from microspec to sample camera=$d_phi"

    ### in fact, we can tell motorName from the statusStringName
    
    set status [set $statusStringName]
    set userScanPrefix [dict get $status user_scan_prefix]
    switch -exact -- $motorName {
        gonio_phi {
            set phiList $pList
            set usrFList ""
            set sysFList ""
            set ll [llength $pList]
            for {set i 0} {$i < $ll} {incr i} {
                lappend sysFList ${scanPrefix}_${i}.jpg
                lappend usrFList ${userScanPrefix}_${i}.jpg
            }
        }
        dose {
            set phiList [dict get $status gonio_phi]
            set sysFList $scanPrefix.jpg
            set usrFList $userScanPrefix.jpg
        }
        time -
        snapshot -
        default {
            set phiList $gonio_phi
            set sysFList $scanPrefix.jpg
            set usrFList $userScanPrefix.jpg
        }
    }

    ### TODO: use inline if exists
    if {[lightsControl_start setup 1 5.0 0.0 - 1]} {
        log_warning wait for lights to settle down
        dict set $statusStringName message \
        "waiting lights to stablize for video snapshots"
        wait_for_time 4000
    }

    ### moving is at the beginning.
    wait_for_devices camera_zoom

    set orig_phi $gonio_phi

    ### may need to adjust zoom

    set ll [llength $phiList]

    set i 0
    foreach phi $phiList sysF $sysFList usrF $usrFList {
        incr i
        dict set $statusStringName message \
        "taking video snapshots $i of $ll"
        move gonio_phi to [expr $phi + $d_phi]
        wait_for_devices gonio_phi
        if {[catch {
            spectrometerWrap_takeSnapshotWithCircle $sysF $lightDiameter
        } errMsg]} {
            log_error failed to save video snapshot: $errMsg
            user_log_error micrspect failed to save video snapshot: $errMsg
            dict set $statusStringName message \
            "failed to save video snapshot: $errMsg"
            return -code error $errMsg
        }
        impCopyFile $userName $sessionId $sysF $usrF
    }
    dict set $statusStringName message \
    "restore phi"
    move gonio_phi to $orig_phi
    wait_for_devices gonio_phi
}
proc spectrometerWrap_takeSnapshotWithCircle { path diameter  } {
    global gUserName
    global gSessionID

    set sampleImageWidth  [getSampleCameraConstant sampleImageWidth]
    set sampleImageHeight [getSampleCameraConstant sampleImageHeight]
    set zoomMaxXAxis      [getSampleCameraConstant zoomMaxXAxis]
    set zoomMaxYAxis      [getSampleCameraConstant zoomMaxYAxis]

    set umPerPixelH 1
    set umPerPixelV 1
    getSampleScaleFactor umPerPixelH umPerPixelV NULL
    set w [expr 1000.0 * $diameter / ($umPerPixelH * $sampleImageWidth)]
    set h [expr 1000.0 * $diameter / ($umPerPixelV * $sampleImageHeight)]

    set drawCmd "-x $zoomMaxXAxis -y $zoomMaxYAxis -w $w -h $h -round"

    set urlSOURCE [::config getSnapshotDirectUrl]
    if {$urlSOURCE == ""} {
        set urlSOURCE [::config getSnapshotUrl]
    }

    set urlTarget "http://[::config getImpDhsImpHost]"
    append urlTarget ":[::config getImpDhsImpPort]"
    append urlTarget "/writeFile?impUser=$gUserName"
    append urlTarget "&impSessionID=$gSessionID"
    append urlTarget "&impWriteBinary=true"
    append urlTarget "&impBackupExist=true"
    append urlTarget "&impAppend=false"

    set urlTargetBox $urlTarget
    append urlTargetBox "&impFilePath=$path"
    set cmd "java -Djava.awt.headless=true url $urlSOURCE $drawCmd -o $urlTargetBox"
    puts "snapshot cmd=$cmd"
    log_note cmd: $cmd
    set mm [eval exec $cmd]
    puts "save round result: $mm"
}
proc spectrometerWrap_purgeReference { condition } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid

    foreach {iTime nAvg bWidth} $condition break
    set nTime [expr int($iTime * 1000)]

    set pat reference_${bid}_${nTime}_*_${bWidth}.yaml

    set l [glob -directory $dir -nocomplain $pat]
    if {$l != ""} {
        eval file delete -force $l
        puts "purged reference $l"
    }
    set isStaff [get_operation_isStaff]
    if {$isStaff} {
        set sys_dir [join $dir system]
        set l [glob -directory $sys_dir -nocomplain $pat]
        if {$l != ""} {
            eval file delete -force $l
            log_warning purged system reference $l
        }
    }
}
proc spectrometerWrap_purgeDark { condition } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid

    foreach {iTime nAvg bWidth} $condition break
    set nTime [expr int($iTime * 1000)]

    set pat dark_${bid}_${nTime}_*_${bWidth}.yaml

    set l [glob -directory $dir -nocomplain $pat]
    if {$l != ""} {
        puts "purged dark: $l"
        eval file delete -force $l
    }
    set isStaff [get_operation_isStaff]
    if {$isStaff} {
        set sys_dir [join $dir system]
        set l [glob -directory $sys_dir -nocomplain $pat]
        if {$l != ""} {
            eval file delete -force $l
            log_warning purged system dark: $l
        }
    }
}
proc spectrometerWrap_expandValidSetupList { inputList } {
    set result ""
    foreach condition $inputList {
        foreach {iTime nAvg nBCWidth} $condition break
        lappend result "$iTime 1 $nBCWidth"
        set num 5
        while {$num < $nAvg} {
            lappend result "$iTime $num $nBCWidth"
            incr num 5
        }
        if {$nAvg != 1} {
            lappend result $condition
        }
    }
    return $result
}
proc spectrometerWrap_getDarkFromCondition { condition } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::dkWList

    foreach {iTime nAvg bWidth} $condition break
    set nTime [expr int($iTime * 1000)]

    set drkPat dark_${bid}_${nTime}_*_${bWidth}.yaml
    set drkList [glob -directory $dir -types f -nocomplain -tails $drkPat]

    set maxAvg -1
    foreach drk $drkList {
        set n [scan $drk dark_${bid}_${nTime}_%d_  a]
        if {$n == 1 && $a > $maxAvg} {
            set maxAvg $a
        }
    }
    if {$maxAvg < $nAvg} {
        log_error no dark found for $condition
        return -code error DARK_NOT_FOUND
    }

    set file dark_${bid}_${nTime}_${maxAvg}_${bWidth}.yaml

    set path [file join $dir $file]
    if {![file readable $path]} {
        log_error dark not readable for $condition
        return -code error DARK_NOT_FOUND
    }

    puts "trying to retrieve spectrometer dark from $path"

    if {$handle != ""} {
        close $handle
        set handle ""
    }
    if {![catch {open $path r} handle]} {
        set yyyy [read -nonewline $handle]
        close $handle
        set handle ""
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to read spectrometer dark for $condition: $errMsg
        return -code error $errMsg
    }

    set hhhh [::yaml::yaml2huddle $yyyy]
    set title [huddle gets $hhhh TITLE]
    if {$title != "spectrometer_dark"} {
        log_error wrong yamle file, TITLE = $title != spectrometer_dark
        return -code error bad_contents
    }

    set wList         [huddle gets $hhhh wavelengthList]
    set cList         [huddle gets $hhhh countList]

    if {$wList != $dkWList} {
        log_severe wavelength not match between current dark and loaded dark for $condition

        return -code error WAVELENGTH_NOT_MATCH
    }

    return $cList
}
proc spectrometerWrap_calculateIndex { wavelength } {
    variable ::spectrometerWrap::statusStringName
    variable ::spectrometerWrap::wavelengthFullList
    variable microspec_wavelength_info

    if {$wavelengthFullList == ""} {
        spectrometerWrap_refreshWavelengthFullList
    }

    set i -1
    foreach wl $wavelengthFullList {
        incr i
        if {$wl >= $wavelength} {
            set microspec_wavelength_info \
            [lreplace $microspec_wavelength_info 3 4 $wl $i]
            return $i
        }
    }
    dict set $statusStringName message \
    "ERROR wavelength $wavelength micron not covered by this device."
    log_error wavelength $wavelength micron not covered by this device.
    return -code error NOT_SUPPORTED
}
proc spectrometerWrap_refreshWavelengthFullList { } {
    variable ::spectrometerWrap::statusStringName
    variable ::spectrometerWrap::wavelengthFullList
    variable microspec_wavelength_info

    ### -1 means no cut from the spectro_window
    set oph [start_waitable_operation get_spectrum -1]
    set opr [wait_for_operation_to_finish $oph]
    if {[llength $opr] < 3} {
        dict set $statusStringName message "ERROR failed to get wavelength full list"
        log_error failed to get wavelength full list
        return -code failed
    }
    foreach {status wList cList} $opr break
    set wavelengthFullList [string trim $wList]
    set length [llength $wavelengthFullList]
    set first [lindex $wavelengthFullList 0]
    set last  [lindex $wavelengthFullList end]

    log_warning refreshed wavelength full list: length=$length \
    first = $first last = $last 
    
    set microspec_wavelength_info [lreplace $microspec_wavelength_info 0 2 \
    $length $first $last]
}
proc spectrometerWrap_setWindowCutoff { index } {
    variable ::spectrometerWrap::statusStringName
    variable ::spectrometerWrap::wavelengthFullList
    variable microspec_wavelength_info
    variable microspec_validSetup
    variable spectro_window

    spectrometerWrap_generateValidSetupList
    if {$microspec_validSetup != ""} {
        dict set $statusStringName message \
        "ERROR clear setup files before changing hardware window"
        log_error clear ALL references and darks before changing window.
        return -code failed
    }

    if {$index == ""} {
        set index [lindex $microspec_wavelength_info 4]
    }
    
    set spectro_window [lreplace $spectro_window 0 0 $index]
    wait_for_strings spectro_window

    log_warning spectro_window changed to $spectro_window
    log_warning first wavelength=[lindex $wavelengthFullList $index] micron.
    return OK
}
proc spectrometerWrap_getReferenceFromCondition { condition } {
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::rfWList

    foreach {iTime nAvg bWidth} $condition break
    set nTime [expr int($iTime * 1000)]

    set refPat reference_${bid}_${nTime}_*_${bWidth}.yaml
    set refList [glob -directory $dir -types f -nocomplain -tails $refPat]

    set maxAvg -1
    foreach ref $refList {
        set n [scan $ref reference_${bid}_${nTime}_%d_  a]
        if {$n == 1 && $a > $maxAvg} {
            set maxAvg $a
        }
    }
    if {$maxAvg < $nAvg} {
        log_error no reference found for $condition
        return -code error REFERENCE_NOT_FOUND
    }

    set file reference_${bid}_${nTime}_${maxAvg}_${bWidth}.yaml

    set path [file join $dir $file]
    if {![file readable $path]} {
        log_error reference not readable for $condition
        return -code error REFERENCE_NOT_FOUND
    }

    puts "trying to retrieve spectrometer reference from $path"

    if {$handle != ""} {
        close $handle
        set handle ""
    }
    if {![catch {open $path r} handle]} {
        set yyyy [read -nonewline $handle]
        close $handle
        set handle ""
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to read spectrometer reference for $condition: $errMsg
        return -code error $errMsg
    }

    set hhhh [::yaml::yaml2huddle $yyyy]
    set title [huddle gets $hhhh TITLE]
    if {$title != "spectrometer_reference"} {
        log_error wrong yamle file, TITLE = $title != spectrometer_reference
        return -code error bad_contents
    }

    set wList         [huddle gets $hhhh wavelengthList]
    set cList         [huddle gets $hhhh countList]
    set timestamp     [huddle gets $hhhh timestamp]
    set numSaturated  [huddle gets $hhhh numSaturated]
    if {[catch {huddle gets $hhhh saturateThreshold} saturateThreshold]} {
        set saturateThreshold 65535
    }

    if {$wList != $rfWList} {
        log_severe wavelength not match between current reference \
        and loaded reference for $condition

        return -code error WAVELENGTH_NOT_MATCH
    }
    if {$saturateThreshold > 65535} {
        log_warning extending from a non-original refereence.
    }

    return [list $timestamp $saturateThreshold $numSaturated $cList]
}
proc spectrometerWrap_extendRefFromCondition { iTime old_condition } {
    variable ::spectrometerWrap::rfWList
    variable ::spectrometerWrap::handle
    variable ::spectrometerWrap::dir
    variable ::spectrometerWrap::bid

    if {![get_operation_isStaff]} {
        log_error only staff can extend the reference
        return -code error STAFF_ONLY
    }

    foreach {t n c} $old_condition break
    if {$iTime <= $t} {
        log_error extended reference expecting a longer integration time > $t
        return -code error BAD_ARGS
    }
    set extendedCondition [list $iTime $n $c]

    set oldDark      [spectrometerWrap_getDarkFromCondition $old_condition]
    set extendedDark [spectrometerWrap_getDarkFromCondition $extendedCondition]
    foreach {ts saturateThreshold numSaturated oldRef} \
    [spectrometerWrap_getReferenceFromCondition $old_condition] break

    set nTime [expr int($iTime * 1000)]
    set fileName reference_${bid}_${nTime}_${n}_${c}.yaml

    set scaling [expr 1.0 * $iTime / $t]
    set newSaturateThreshold [expr $saturateThreshold * $scaling]
    set srfCList ""
    foreach v $oldRef old_dark $oldDark new_dark $extendedDark {
        if {$v < $saturateThreshold} {
            set pureRef [expr $v - $old_dark]
            if {$pureRef < 0} {
                set pureRef 0
            }
            set newPureRef [expr $pureRef * $scaling]
            set newRef [expr $newPureRef + $new_dark]
        } else {
            set newRef $newSaturateThreshold
        }

        lappend srfCList $newRef
    }

    set hW [eval huddle list $rfWList]
    set hC [eval huddle list $srfCList]

    set hhhh [huddle create \
    TITLE spectrometer_reference \
    integrationTime $iTime \
    scansToAverage  $n \
    boxcarWidth     $c \
    saturateThreshold $newSaturateThreshold \
    numSaturated    $numSaturated \
    warning         "reference extended from $t second" \
    timestamp       $ts \
    timestamp_txt   [clock format $ts -format "%D %T"] \
    wavelengthList  $hW \
    countList       $hC \
    ]

    set yyyy [::yaml::huddle2yaml $hhhh 4 80]

    if {$handle != ""} {
        close $handle
        set handle ""
    }
    set filePath [file join $dir $fileName]

    set condition [lreplace $old_condition 0 0 $iTime] 
    spectrometerWrap_purgeReference $condition

    if {![catch {open $filePath w} handle]} {
        puts $handle $yyyy
        close $handle
        set handle ""
        log_warning extended reference saved to $fileName
    } else {
        set errMsg $handle
        set handle ""
        log_error failed to save extended reference to $filePath: $errMsg
        return -code error $errMsg
    }
    set backupPath [file join $dir system $fileName]
    file copy -force $filePath $backupPath
    log_warning reference save to system: $fileName
}
proc spectrometerWrap_addBatch { args } {
    variable spectroWrap_config
    variable microspec_setup_batch

    set ll [llength $args]
    if {$ll < 3} {
        log_error need iTime nAvg and bcWidth
        return -code error BAD_ARGS
    }
    foreach {iTime nAvg bWidth} $args break
    if {![string is double  -strict $iTime] \
    ||  ![string is integer -strict $nAvg] \
    ||  ![string is integer -strict $bWidth] \
    || $iTime <=0 \
    || $bWidth < 0 \
    } {
        log_error bad arguments
        return -code error BAD_ARGS
    }
    set minNumAvg [lindex $spectroWrap_config 4]
    if {$nAvg < $minNumAvg} {
        set nAvg $minNumAvg
        log_warning numAverage adjusted to $nAvg
    }
    set oldContents $microspec_setup_batch
    lappend oldContents [list $iTime $nAvg $bWidth]
    set sorted \
    [lsort -unique -command spectrometerWrap_listSortCmd $oldContents]
    set onlyMax [spectrometerWrap_listMaxAverageOnly $sorted]
    set microspec_setup_batch $onlyMax

    return OK
}
