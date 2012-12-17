proc alignCollimator_initialize { } {
    variable cfgAlignCollimatorConstantNameList

    set cfgAlignCollimatorConstantNameList \
    [::config getStr alignCollimatorConstantsNameList]
    
    namespace eval ::alignCollimator {
        global gMotorBeamWidth
        global gMotorBeamHeight
        global gMotorEnergy

        ## attenuation does not need to be build-in here.
        ## it will not move energy
        set mList [list \
        attenuation \
        fluorescence_z \
        ]

        ### name tag in constants
        set nList [list \
            attenuation \
            fluorescence_z \
        ]

        set preset_index -1

        set logKey [list \
        collimator_1_horz_orig \
        collimator_1_horz_new \
        collimator_1_horz_diff \
        collimator_1_vert_orig \
        collimator_1_vert_new \
        collimator_1_vert_dff \
        radius_of_confusion \
        collimator_horz_encoder \
        collimator_vert_encoder \
        ]

        set logEncoderKeyName [list \
        collimator_horz_encoder \
        collimator_vert_encoder \
        ]
        ### operations allowed or included
        ### we may use these in the future
        set logOperation [list \
        alignCollimator \
        ]

        set logStartTime 0
    }
}
########################################################################
### 1. do a horz scan
###    If the peak is less than minPeak, abort
###    If the peak is greater than goodPeak, start normal vert scan
###    If the peak is not good but higher than min, then:
### 2. do one vert scan to see if the peak can reach good.
###    If cannot reach good, abort
###
### 3. normal vert scan:
###    0, 180, 90, 270
### 4. Final horz scan.


proc alignCollimator_start { } {
    variable collimator_horz
    variable collimator_vert

    set timeStart [clock seconds]

    set orig_horz $collimator_horz
    set orig_vert $collimator_vert

    if {[catch {
        alignCollimator_check

        set DO_CHECK 0

        clear_operation_log alignCollimator

        alignCollimator_setup
        inlineLightControl_start remove

        ### prefix
        set dir [file join [pwd] alignCollimator]
        file mkdir $dir
        set TS4Name [timeStampForFileName]

        alignCollimatorLog align collimator started for $TS4Name

        ############### HORZ ###############
        alignCollimator_findGoodHorz $dir $TS4Name
    } errMsg] == 1} {
        set detail "Collimator horz positioning: $errMsg"
        return -code error $detail
    }
    if {[catch {
        ############ VERT 1##############
        set name ${TS4Name}vert_0.scan
        set fileName [file join $dir $name]
        set vert0Result [alignCollimator_scan $fileName vert]
        alignCollimatorLog vert0 $vert0Result
        set v0 [lindex $vert0Result 0]

        ########### VERT 2 ##############
        move gonio_phi by 180.0
        wait_for_devices gonio_phi

        set name ${TS4Name}vert_180.scan
        set fileName [file join $dir $name]
        set vert180Result [alignCollimator_scan $fileName vert]
        alignCollimatorLog vert180 $vert180Result
        set v180 [lindex $vert180Result 0]

        set vCenter0 [expr ($v0 + $v180) / 2.0]
        move collimator_vert to $vCenter0
        ### we are at 180, if v1 > v0, we need to move sample down
        ### in the view of inline camera
        set dd0 [expr $v180 - $vCenter0]
        alignCollimatorLog vert 0-180 the collimator is off by $dd0 mm

        inlineMoveSampleRelativeMM 0.0 $dd0

        if {$DO_CHECK} {
            #####################################################
            ### re-check
            #####################################################
            set name ${TS4Name}check_vert_180.scan
            set fileName [file join $dir $name]
            set checkVert180Result [alignCollimator_scan $fileName vert]
            alignCollimatorLog checkVert180 $checkVert180Result
            set checkV180 [lindex $checkVert180Result 0]

            ### go back to 0.0
            move gonio_phi by 180.0
            wait_for_devices gonio_phi

            set name ${TS4Name}check_vert_0.scan
            set fileName [file join $dir $name]
            set checkVert0Result [alignCollimator_scan $fileName vert]
            alignCollimatorLog checkVert0 $checkVert0Result
            set checkV0 [lindex $checkVert0Result 0]

            set checkVCenter0 [expr ($checkV0 + $checkV180) / 2.0]
            alignCollimatorLog checkVCenter0 $checkVCenter0
            if {abs($vCenter0 - $checkVCenter0) > 0.002} {
                log_error vert 0-180 check failed, center not within 2 microns
            }

            move collimator_vert to $checkVCenter0

            set checkDD0 [expr abs($checkVCenter0 - $checkV180)]
            if {$checkDD0 > 0.002} {
                log_error vert 0-180 recheck failed: still off $checkDD0
            }
        }
    } errMsg] == 1} {
        set detail "Collimator positioning to phi: $errMsg"
        return -code error $detail
    }

    if {[catch {
        ############## 90 degree
        move gonio_phi by 90.0
        wait_for_devices gonio_phi
    
        set name ${TS4Name}vert_90.scan
        set fileName [file join $dir $name]
        set vert90Result [alignCollimator_scan $fileName vert]
        alignCollimatorLog vert90 $vert90Result
        set v90 [lindex $vert90Result 0]

        ####### 270 ######
        move gonio_phi by 180.0
        wait_for_devices gonio_phi

        set name ${TS4Name}vert_270.scan
        set fileName [file join $dir $name]
        set vert270Result [alignCollimator_scan $fileName vert]
        alignCollimatorLog vert270 $vert270Result
        set v270 [lindex $vert270Result 0]

        set vCenter90 [expr ($v90 + $v270) / 2.0]
        alignCollimatorLog vCenter90 $vCenter90

        move collimator_vert to $vCenter90
        wait_for_devices collimator_vert

        set dd90 [expr $v270 - $vCenter90]
        alignCollimatorLog vert 90-270 the collimator is off by $dd90 mm
        inlineMoveSampleRelativeMM 0.0 $dd90

        if {$DO_CHECK} {
            ###########################################################
            # recheck 90-270
            ###########################################################
            set name ${TS4Name}check_vert_270.scan
            set fileName [file join $dir $name]
            set checkVert270Result [alignCollimator_scan $fileName vert]
            alignCollimatorLog checkVert270 $checkVert270Result
            set checkV270 [lindex $checkVert270Result 0]

            ## go back to 90
            move gonio_phi by 180.0
            wait_for_devices gonio_phi

            set name ${TS4Name}check_vert_90.scan
            set fileName [file join $dir $name]
            set checkVert90Result [alignCollimator_scan $fileName vert]
            alignCollimatorLog checkVert90 $checkVert90Result
            set checkV90 [lindex $checkVert90Result 0]

            set checkVCenter90 [expr ($checkV90 + $checkV270) / 2.0]
            alignCollimatorLog checkVCenter90 $checkVCenter90

            if {abs($checkVCenter90 - $checkV270) > 0.002} {
                log_error vert 90-270 check failed, center not within 2 microns
            }

            set checkDD90 [expr abs($checkVCenter90 - $checkV270)]
            if {$checkDD90 > 0.002} {
                log_error vert 90-270 recheck failed: still off $checkDD90
            }
        }

        #############################
        #############################
        if {!$DO_CHECK} {
            set vCenterConfusion [expr ($vCenter0 + $vCenter90) / 2.0]
            set ddConfusion [expr $vCenter90 - $vCenterConfusion]
            set confusionDD [expr $v90 - $vCenterConfusion]
        } else {
            set vCenterConfusion [expr ($checkVCenter0 + $checkVCenter90) / 2.0]
            set ddConfusion [expr $checkVCenter90 - $vCenterConfusion]
            set confusionDD [expr $checkV90 - $vCenterConfusion]
        }

        move collimator_vert to $vCenterConfusion
        wait_for_devices collimator_vert

        if {!$DO_CHECK} {
            alignCollimatorLog vert center 0-180 $vCenter0 90-270 $vCenter90
        } else {
            alignCollimatorLog vert center 0-180 \
            $checkVCenter0 90-270 $checkVCenter90
        }
        alignCollimatorLog radius of confusion=$ddConfusion \
        center=$vCenterConfusion

        save_operation_log radius_of_confusion $ddConfusion

        #### Aina wants to get email if the radius_of_confusion is big
        if {abs($ddConfusion) > 0.002} {
            alignCollimatorLog ERROR \
            radius_of_confusion = $ddConfusion mm > 2 microns

            log_severe radius_of_confusion = $ddConfusion mm > 2 microns
        }
    } errMsg] == 1} {
        set detail "Collimator 90 degree positioning to phi: $errMsg"
        return -code error $detail
    }
    ############### FINAL HORZ ###############
    #set name ${TS4Name}horzFinal.scan
    #set fileName [file join $dir $name]
    #set horzResult [alignCollimator_scan $fileName horz]
    #alignCollimatorLog final horz $horzResult
    #set betterHorz [lindex $horzResult 0]

    #move collimator_horz to $betterHorz
    #wait_for_devices collimator_horz

    alignCollimator_saveResults
    alignCollimatorLogSignals

    alignCollimator_restore

    set timeEnd [clock seconds]
    set timeUsed [expr $timeEnd - $timeStart]
    set timeUsedText [secondToTimespan $timeUsed]

    alignCollimatorLog total collimator time: $timeUsedText
}

proc alignCollimator_findGoodHorz { dir prefix } {
    set goodSignal [get_alignCollimator_constant good_signal]

    ############### HORZ ###############
    set name ${prefix}horz_init.scan
    set fileName [file join $dir $name]

    ### it will fail here if the signal is less than min_signal
    set horzResult [alignCollimator_scan $fileName horz]
    alignCollimatorLog init_horz $horzResult

    set betterHorz [lindex $horzResult 0]
    set peak       [lindex $horzResult 1]


    move collimator_horz to $betterHorz
    wait_for_devices collimator_horz

    if {$peak >= $goodSignal} {
        return
    }

    alignCollimatorLog signal too weak, trying search vertical
    log_warning signal too weak, trying search vertical.
    ############ VERT ##############
    set name ${prefix}vert_init.scan
    set fileName [file join $dir $name]
    set vertResult [alignCollimator_scan $fileName vert]
    alignCollimatorLog init_vert $vertResult
    set betterVert [lindex $vertResult 0]
    set peak       [lindex $vertResult 1]


    if {$peak < $goodSignal} {
        alignCollimatorLog faild: signal still too weak after vertical search
        log_error failed to find enough signal
        return -code error signal_too_small
    }

    move collimator_vert to $betterVert
    wait_for_devices collimator_vert
    log_warning redoing horz after got better signals
    ############### HORZ again ###############
    set name ${prefix}horz_second.scan
    set fileName [file join $dir $name]

    ### it will fail here if the signal is less than min_signal
    set horzResult [alignCollimator_scan $fileName horz]
    alignCollimatorLog horz after vert $horzResult

    set betterHorz [lindex $horzResult 0]
    set peak       [lindex $horzResult 1]

    move collimator_horz to $betterHorz
    wait_for_devices collimator_horz

    if {$peak < $goodSignal} {
        alignCollimatorLog ERROR strange, lost signal after got better vert
        log_severe strange, lost signal after got better vert
        return -code error signal_too_small
    }

}

proc alignCollimator_check { } {
    variable collimator_status
    variable ::alignCollimator::preset_index

    set microBeam    [lindex $collimator_status 0]
    set preset_index [lindex $collimator_status 1]

    if {$microBeam != 1 || $preset_index < 0} {
        log_warning collimator not at a micro beam position
        log_warning moving in first mirco beam
        collimatorMoveFirstMicron
    }
    set microBeam    [lindex $collimator_status 0]
    set preset_index [lindex $collimator_status 1]

    if {$microBeam != 1 || $preset_index < 0} {
        log_error still no microbeam after tried move in first micro beam collimator
        return -code error NOT_IN_POSITION
    }
}

proc alignCollimator_setup { } {
    variable ::alignCollimator::nList
    variable ::alignCollimator::mList

    ### we just move all of them
    set waitList ""
    foreach motor $mList tag_name $nList {
        set setting [get_alignCollimator_constant $tag_name]
        move $motor to $setting
        lappend waitList $motor
    }
    if {$waitList != ""} {
        eval wait_for_devices $waitList
    }
    return ""
}
proc alignCollimator_restore { } {
	set op_info [get_operation_info]
    set op_name [lindex $op_info 0]
    if {$op_name == "alignCollimator"} {
        alignTungsten_restore
    }
}

proc alignCollimatorConstantNameToIndex { name } {
    variable cfgAlignCollimatorConstantNameList
    variable alignCollimator_constant

    if {![info exists alignCollimator_constant]} {
        return -code error "string not exists: alignCollimator_constant"
    }

    set index [lsearch -exact $cfgAlignCollimatorConstantNameList $name]
    if {$index < 0} {
        return -code error "bad name: $name"
    }

    if {[llength $alignCollimator_constant] <= $index} {
        return -code error "bad contents of string alignCollimator_constant"
    }
    return $index
}
proc get_alignCollimator_constant { name } {
    variable alignCollimator_constant

    set index [alignCollimatorConstantNameToIndex $name]
    return [lindex $alignCollimator_constant $index]
}

proc alignCollimatorMakeSureEnoughConstant { } {
    variable cfgAlignCollimatorConstantNameList
    variable alignCollimator_constant

    set ln [llength $cfgAlignCollimatorConstantNameList]
    set lc [llength $alignCollimator_constant]

    if {$ln > $lc} {
        set nAdd [expr $ln - $lc]
        log_error alignCollimator_constant does not have enough data. $nAdd space appended
        log_error Please check with config tab

        for {set i 0} {$i < $nAdd} {incr i} {
            lappend alignCollimator_constant ""
        }
        return -code error "constant_not_enought_data"
    }
}
proc alignCollimatorLog { args } {
    catch {
        send_operation_update "$args"

        set logFileName alignCollimator.log
        set timeStamp [clock format [clock seconds] -format "%D-%T"]
        if {[catch {open $logFileName a} fh]} {
            puts "failed to open log file: $logFileName"
        } else {
            puts $fh "$timeStamp $args"
            close $fh
        }
    }
}
### assume it is already at the location
proc alignCollimator_scan { fileName vert_or_horz } {
    set motorName collimator_$vert_or_horz

    set width     [get_alignCollimator_constant ${vert_or_horz}_scan_width]
    set numPoint  [get_alignCollimator_constant ${vert_or_horz}_scan_points]
    set signal    [get_alignCollimator_constant signal]
    set time      [get_alignCollimator_constant ${vert_or_horz}_scan_time]
    set timeWait  [get_alignCollimator_constant ${vert_or_horz}_scan_wait]
    set minSignal [get_alignCollimator_constant min_signal]
    if {![isMotor $motorName]} {
        log_error $motorName is not motor
        return -code error "wrong_align_collimator_config"
    }
    if {$numPoint < 2} {
        log_error wrong numPoint: $numPoint should be > 1
        return -code error "wrong_align_collimator_config"
    }
    if {![isIonChamber $signal]} {
        log_error wrong signal: $signal is not an ion chamber
        return -code error "wrong_align_collimator_config"
    }

    variable $motorName
    set save_POS [set $motorName]
    set halfW    [expr $width / 2.0]
    set startP   [expr $save_POS - $halfW]
    set endP     [expr $save_POS + $halfW]
    set CUT_OFF  0.25

    if {[swapIfBacklash $motorName startP endP]} {
        puts "alignCollimator scan  $vert_or_horz swapped start and end because backlash"
    }

    #log_error peakGeneric_scan $fileName $motorName $startP $endP \
    $numPoint $time $signal $timeWait $CUT_OFF $minSignal -1 1

    set MAX_RETRY 2
    set result failed
    set failed_reason ""
    for {set i 0} {$i < $MAX_RETRY} {incr i} {
        wait_for_good_beam
        if {[catch {
            set result [peakGeneric_scan $fileName $motorName $startP $endP \
            $numPoint $time $signal $timeWait $CUT_OFF $minSignal -1 1]

            if {$result != "0 0 0"} {
                break
            } else {
                set result failed
            }
        } errMsg]} {
            puts "scan error: $errMsg"
            if {$errMsg == ""} {
                puts "errMsg==EMPTY and result=$result"
                break
            }
            set failed_reason $errMsg
            if {[string first abort $errMsg] >= 0} {
                return -code error $errMsg
            }
        }
        if {![beamGood]} {
            log_warning lost beam during $motorName scan
            set result failed
            set failed_reason "lost beam"
            if {$i < $MAX_RETRY} {
                log_warning retrying
            }
        }
    }

    move $motorName to $save_POS
    wait_for_devices $motorName

    if {$result == "failed"} {
        alignCollimatorLog ERROR: $failed_reason
        return -code error "failed_after_max_retry"
    }

    ####more check
    if {$startP > $endP} {
        foreach {startP endP} [list $endP $startP] break
    }
    set maxP [lindex $result 0]
    if {$maxP < $startP || $maxP > $endP} {
        log_error found max out side of scan range
        return -code error "faile_out_of_range"
    }

    return $result
}
# 01/06/12: adjust all presets
proc alignCollimator_saveResults { } {
    variable ::alignCollimator::preset_index
    variable cfgCollimatorPresetNameToIndexMap
    variable collimator_preset
    variable collimator_horz
    variable collimator_vert

    set nIndex  $cfgCollimatorPresetNameToIndexMap(name)
    set hIndex  $cfgCollimatorPresetNameToIndexMap(horz)
    set vIndex  $cfgCollimatorPresetNameToIndexMap(vert)
    set eHIndex $cfgCollimatorPresetNameToIndexMap(horz_encoder)
    set eVIndex $cfgCollimatorPresetNameToIndexMap(vert_encoder)
    set mIndex  $cfgCollimatorPresetNameToIndexMap(is_micron_beam)
    set ajIndex $cfgCollimatorPresetNameToIndexMap(adjust)

    set ADJUST_METHOD ALL_PRESET
    
    set ll [llength $collimator_preset]

    if {$preset_index < 0 || $preset_index >= $ll} {
        log_severe alignCollimator error: \
        bad preset_index $preset_index should not happen, already checked
        alignCollimatorLog ERROR failed to save the results to preset
        return -code error wrong_preset_index
    }

    set current [lindex $collimator_preset $preset_index]
    set currentH [lindex $current $hIndex]
    set currentV [lindex $current $vIndex]
    set currentEH [lindex $current $eHIndex]
    set currentEV [lindex $current $eVIndex]

    set ddHorz [expr $collimator_horz - $currentH]
    set ddVert [expr $collimator_vert - $currentV]

    if {[string is double -strict $currentEH] \
    &&  [string is double -strict $currentEV]} {
        get_encoder collimator_horz_encoder
        get_encoder collimator_vert_encoder
        set horz_encoder [wait_for_encoder collimator_horz_encoder]
        set vert_encoder [wait_for_encoder collimator_vert_encoder]

        set ddEHorz [expr $horz_encoder - $currentEH]
        set ddEVert [expr $vert_encoder - $currentEV]
    } else {
        set ddEHorz 0
        set ddEVert 0
    }

    ###### check range allowed
    set maxH [get_alignCollimator_constant max_horz_move]
    set maxV [get_alignCollimator_constant max_vert_move]
    set failed 0
    if {abs($ddHorz) > $maxH} {
        incr failed
        log_severe alignCollimator found horz off $ddHorz exceed allowed $maxH
    }
    if {abs($ddVert) > $maxV} {
        incr failed
        log_severe alignCollimator found vert off $ddVert exceed allowed $maxV
    }
    if {abs($ddEHorz) > $maxH} {
        incr failed
        log_severe \
        alignCollimator found horz_enocder off $ddEHorz exceed allowed $maxH
    }
    if {abs($ddEVert) > $maxH} {
        incr failed
        log_severe \
        alignCollimator found vert_enocder off $ddEVert exceed allowed $maxV
    }
    if {$failed} {
        return -code error EXCEED_RANGE
    }

    save_operation_log collimator_${preset_index}_horz_orig $currentH
    save_operation_log collimator_${preset_index}_horz_new  $collimator_horz
    save_operation_log collimator_${preset_index}_horz_diff \
    [expr $collimator_horz - $currentH]
    save_operation_log collimator_${preset_index}_vert_orig $currentV
    save_operation_log collimator_${preset_index}_vert_new  $collimator_vert
    save_operation_log collimator_${preset_index}_vert_diff \
    [expr $collimator_vert - $currentV]

    set new_presets $collimator_preset

    set warningMsgList ""

    for {set i 0} {$i < $ll} {incr i} {
        set pset [lindex $collimator_preset $i]
        set adjust [lindex $pset $ajIndex]
        ### always adjust the one we used
        if {$i != $preset_index && $adjust == "0"} {
            continue
        }
        ### change
        set current [lindex $collimator_preset $i]
        set currentN [lindex $current $nIndex]
        set currentH [lindex $current $hIndex]
        set currentV [lindex $current $vIndex]
        set currentEH [lindex $current $eHIndex]
        set currentEV [lindex $current $eVIndex]
        set newH [expr $currentH + $ddHorz]
        set newV [expr $currentV + $ddVert]
        set newSetting $current
        set newSetting [lreplace $newSetting $hIndex $hIndex $newH]
        set newSetting [lreplace $newSetting $vIndex $vIndex $newV]
        set msg "collimator $currentN moved from $currentH $currentV"
        append msg " to $newH $newV"
        lappend warningMsgList $msg

        if {[string is double -strict $currentEH] \
        &&  [string is double -strict $currentEV]} {
            set newEH [expr $currentEH + $ddEHorz]
            set newEV [expr $currentEV + $ddEVert]
            set newSetting [lreplace $newSetting $eHIndex $eHIndex $newEH]
            set newSetting [lreplace $newSetting $eVIndex $eVIndex $newEV]
            set msg "collimator $currentN encoder from $currentEH $currentEV"
            append msg " to $newEH $newEV"
            lappend warningMsgList $msg
        }

        set new_presets [lreplace $new_presets $i $i $newSetting]
    }
    ### do the change once.
    set collimator_preset $new_presets
    foreach msg $warningMsgList {
        eval log_warning $msg
        eval alignCollimatorLog $msg
    }
}
proc alignCollimatorLogSignals { } {
    variable ::alignCollimator::logEncoderKeyName
    if {[catch {
        foreach n $logEncoderKeyName {
            get_encoder $n
        }
        foreach k $logEncoderKeyName {
            set v [wait_for_encoder $k]
            save_operation_log $k $v
        }

    } errMsg]} {
        log_error failed to log signals: $errMsg
    }
}
