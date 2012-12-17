proc changeOver_initialize {} {
    #### default to overwrite optimizedEnergyParameters
    variable OEPDefaultMask

    ### we want to replace 2-8, 11. 12, 14-29, 31-end
    #                       1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3 3 3
    #   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3
    set OEPDefaultMask [list \
        0 0 1 1 1 1 1 1 1 0 0 1 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1  \
    ]
}

proc changeOverNeed { command tag } {
    if {$command == "all"} {
        return 1
    }
    if {$command == $tag} {
        return 1
    }
    return 0
}

proc changeOver_start { command } {

    log_error calling change_over with $command

    set sessionID PRIVATE[get_operation_SID]
    set userName [get_operation_user]

    if {[changeOverNeed $command "clear_run"]} {
        changeOverClearRun $userName $sessionID
    }
    if {[changeOverNeed $command "clear_mounted"]} {
        changeOverClearMounted $userName $sessionID
    }
    if {[changeOverNeed $command "reset_all_port"]} {
        changeOverResetAllPort $userName $sessionID
    }
    if {[changeOverNeed $command "clear_spreadsheet"]} {
        changeOverClearSpreadsheet $userName $sessionID
    }
    if {[changeOverNeed $command "reset_robot_attribute"]} {
        changeOverResetRobotAttribute $userName $sessionID
    }
    if {[changeOverNeed $command "clear_user_log"]} {
        changeOverClearUserLog $userName $sessionID
    }
    if {[changeOverNeed $command "reset_screening"]} {
        changeOverResetScreening $userName $sessionID
    }
    if {[changeOverNeed $command "reset_optimization"]} {
        changeOverResetOptimization $userName $sessionID
    }
    if {[changeOverNeed $command "get_gap"]} {
        changeOverGetGapOwnership $userName $sessionID
    }
    if {[changeOverNeed $command "clear_cassette_owner"]} {
        changeOverClearCassetteOwner $userName $sessionID
    }
    if {[changeOverNeed $command "clear_user_notify"]} {
        changeOverClearUserNotify $userName $sessionID
    }
    if {[changeOverNeed $command "clear_user_chat"]} {
        changeOverClearUserChat $userName $sessionID
    }
    if {[changeOverNeed $command "clear_sort"]} {
        changeOverClearSort $userName $sessionID
    }
}
proc changeOverClearUserNotify { userName sessionID } {
    if {[isOperation userNotify]} {
        userNotify_start clear_all
    }
}
proc changeOverClearUserChat { userName sessionID } {
    if {[isOperation userChat]} {
        userChat_start
    }
}
proc changeOverClearSort { userName sessionID } {
    if {[isOperation moveCrystal]} {
        moveCrystal_start remove_all
    }
}
proc changeOverClearRun { userName sessionID } {
    set h [start_waitable_operation runsConfig $userName resetAllRuns]
    if {[catch {wait_for_operation_to_finish $h} errMsg]} {
        log_error clear runs failed: $errMsg
    }
    variable run0
    set dDH [::config getDefaultDataHome]
    ### here "username" is a tag.  Buttons will be disabled until
    ### it has been changed.
    set dir [file join $dDH username]
    set run0 [lreplace $run0 4 4 $dir]


    if {[isString fluorScanStatus]} {
        variable fluorScanStatus
        set fluorScanStatus [lreplace $fluorScanStatus 3 3 $dir]
    }
    if {[isString madScanStatus]} {
        variable madScanStatus
        set madScanStatus [lreplace $madScanStatus 3 3 $dir]
    }
    if {[isString excitationScanStatus]} {
        variable excitationScanStatus
        set excitationScanStatus [lreplace $excitationScanStatus 3 3 $dir]
    }

    if {[isOperation rasterRunsConfig]} {
        ### this part is also called when sample dismounted
        set h [start_waitable_operation rasterRunsConfig deleteAllRasters]
        if {[catch {wait_for_operation_to_finish $h} errMsg]} {
            log_error failed to delete all rasters: $errMsg
        }
        set h [start_waitable_operation \
        rasterRunsConfig setUserDefaultToSystemDefault]
        if {[catch {wait_for_operation_to_finish $h} errMsg]} {
            log_error failed to reset user default: $errMsg
        }
    }
    if {[isOperation spectrometerWrap]} {
        if {[catch {
            set h [start_waitable_operation spectrometerWrap change_over]
            wait_for_operation_to_finish $h
        } errMsg]} {
            puts "microspec change_over clear failed: $errMsg"
        }
    }
}
proc changeOverClearSpreadsheet { userName sessionID } {
    set beamline [::config getConfigRootName]

    ### call CrystalData.tcl
    if {[catch {clearSpreadsheet $beamline $userName $sessionID} errMsg]} {
        log_error clear spreadsheet failed: $errMsg
    }
}
proc changeOverClearMounted { userName sessionID } {
    set h [start_waitable_operation sequence clear_mounted $sessionID]
    if {[catch {wait_for_operation_to_finish $h} errMsg]} {
        log_error clear robot mounted failed: $errMsg
    }
}
proc changeOverClearUserLog { userName sessionID } {
    set h [start_waitable_operation userLog]
    if {[catch {wait_for_operation_to_finish $h} errMsg]} {
        log_error clear user log failed: $errMsg
    }
}
proc changeOverClearCassetteOwner { userName sessionID } {
    global gUserName

    variable cassette_owner
    variable barcode_port
    variable cassette_barcode
    variable scanId_config

    set barcode_port [list {} {} {}]
    set cassette_barcode [list unknown unknown unknown unknown]
    set scanId_config [list 1 1 1]

    set un $gUserName
    if {$un == ""} {
        set un blctl
    }

    #### default: user cannot see any cassette
    set cassette_owner [list $un $un $un $un]

    #### cassette_owner may be triggered by cassette status (unknown) too
}
proc changeOverResetAllPort { userName sessionID } {
    ## the "1" at the end will ask robot to delete the probe info permanently.
    set h [start_waitable_operation robot_config reset_cassette 1]
    if {[catch {wait_for_operation_to_finish $h} errMsg]} {
        log_error reset all ports failed: $errMsg
    }
}
proc changeOverResetRobotAttribute { userName sessionID } {
    variable robot_attribute
    variable robot_default
    variable auto_sample_const
    variable check_sample_const
    variable table_setup

    set l_a [llength $robot_attribute]
    set l_d [llength $robot_default]

    if {$l_d >= $l_a} {
        set end_a [expr $l_a - 1]
        set new_att [lrange $robot_default 0 $end_a]
    } else {
        ::dcss2 sendMessage "htos_log software_severe robot_default missing robot_attributes"
        log_warning use hardcode value for robot attributes

        set new_att [list 1 1 1 1 1 0 0 1 0 1 0 -1 0 1]
    }

    if {$l_d >= $l_a + 1} {
        set auto_on [lindex $robot_default $l_a]
    } else {
        ::dcss2 sendMessage "htos_log software_severe robot_default missing auto_check_sample_xyz"
        log_warning auto_sample_xyz turned on by default
        set auto_on 1
    }
    if {$l_d >= $l_a + 2} {
        set index [expr $l_a + 1]
        set check_on [lindex $robot_default $index]
    } else {
        ::dcss2 sendMessage "htos_log software_severe robot_default missing check_sample_on"
        log_warning check_sample_on turned on by default
        set check_on 1
    }

    ####robot_attribute owned by robot not "self" so we need to wait
    set robot_attribute $new_att
    wait_for_strings robot_attribute
    if {$robot_attribute != $new_att} {
        log_error set robot attribute to default failed
    }
    if {[llength $auto_sample_const] > 29} {
        set auto_sample_const [lreplace $auto_sample_const 29 29 $auto_on]
    } else {
        log_error wrong contents of auto_sample_const
    }
    if {[llength $check_sample_const] > 9} {
        set check_sample_const [lreplace $check_sample_const 9 9 $check_on]
    } else {
        log_error wrong contents of check_sample_const
    }

    if {[llength $table_setup] > 4} {
        set table_setup [lreplace $table_setup 4 4 0]
    }
}
proc changeOverResetScreening { userName sessionID } {
    variable lc_error_threshold

    set h [start_waitable_operation sequenceSetConfig reset $sessionID]
    if {[catch {wait_for_operation_to_finish $h} errMsg]} {
        log_error reset screening parameters failed: $errMsg
    }
    set dDH [::config getDefaultDataHome]
    set dir [file join $dDH username]
    set h [start_waitable_operation sequenceSetConfig setConfig directory $dir $sessionID]
    if {[catch {wait_for_operation_to_finish $h} errMsg]} {
        log_error reset screening parameters failed: $errMsg
    }
    set lc_error_threshold [list 3 0]
}
proc changeOverResetOptimization { userName sessionID } {
    variable OEPDefaultMask
    variable optimizedEnergyParameters
    variable optimizedEnergy_default

    if {![isString optimizedEnergyParameters]} {
        log_error optimizedEnergyParameters not defined
        return
    }
    if {![isString optimizedEnergy_default]} {
        log_error optimizedEnergy_default not defined
        return
    }

    set llP [llength $optimizedEnergyParameters]
    set llD [llength $optimizedEnergy_default]
    set llM [llength $OEPDefaultMask]
    if {$llP != $llD} {
        log_error optimizedEnergyParameters format not matching \
        optimizedEnergy_default
        return
    }
    if {$llP != $llM} {
        log_error optimizedEnergyParameters format not matching \
        default to parameter mask. Need update software.
        return
    }

    set new_contents $optimizedEnergyParameters
    for {set i 0 } {$i < $llP} {incr i} {
        set m [lindex $OEPDefaultMask $i]
        if {$m == "1"} {
            set dd [lindex $optimizedEnergy_default $i]
            set new_contents [lreplace $new_contents $i $i $dd]
        }
    }
    set optimizedEnergyParameters $new_contents
}
proc changeOverGetGapOwnership { userName sessionID } {
    if {[isOperation checkGapOwnership]} {
        set h [start_waitable_operation checkGapOwnership]
        if {[catch {wait_for_operation_to_finish $h} errMsg]} {
            log_error request undulator gap ownership failed: $errMsg
        }
    }
}
