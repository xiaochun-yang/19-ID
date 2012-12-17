proc matchup_initialize { } {
    namespace eval ::matchup {
        set logKey [list \
        inline_horz_orig \
        inline_horz_new \
        inline_horz_diff \
        inline_vert_orig \
        inline_vert_new \
        inline_vert_diff \
        ]

        ### operations allowed or included
        ### we may use these in the future
        set logOperation [list \
        matchup \
        ]

        set logStartTime 0
    }
}

proc matchup_start { cmd args } {
    global gUserName
    global gSessionID
    global gMotorPhi

    clear_operation_log matchup

    #set userName [get_operation_user]
    #set SID [get_operation_SID]
    set userName $gUserName
    set SID      $gSessionID

    set dir [file join [pwd] alignCollimator]
    file mkdir $dir

    switch -exact -- $cmd {
        save_perfect {
            matchup_saveSamplePerfect $userName $SID $dir
            matchup_saveInlinePerfect $userName $SID $dir
        }
        save_perfect_sample {
            matchup_saveSamplePerfect $userName $SID $dir
        }
        save_perfect_inline {
            matchup_saveInlinePerfect $userName $SID $dir
        }
        adjust_sample {
            if {[catch {
                matchup_moveTungstenToBeamQuick $userName $SID $dir
            } errMsg] == 1} {
                set detail "Initial W placement at crosshairs: $errMsg"
                return -code error $detail
            }
        }
        adjust_inline {
            if {[catch {
                matchup_moveInlineToTungstenQuick
            } errMsg] == 1} {
                set detail "Inline camera positioning: $errMsg"
                return -code error $detail
            }
        }
        auto_focus {
            if {[catch {
                matchup_autoFocusInlineCamera $userName $SID $dir
            } errMsg] == 1} {
                set detail "Inline camera focusing: $errMsg"
                return -code error $detail
            }
        }
        test {
            foreach {- -  old_sample_tip_x } \
            [matchup_getOldValues $userName $SID $dir sample] break
            matchup_checkOrientation $userName $SID $dir $old_sample_tip_x
        }
        DEBUG {
            matchup_inlineLightSetup
        }
        DEBUG2 {
            centerRestoreLights
        }
        DEBUG3 {
            sequence_start takeSnapshotWithBeamBox /usr/local/dcs/dcss/linux64/alignTungsten/jjjsong.jpg $gUserName $gSessionID
        }
    }
}
proc matchup_inlineLightSetup { } {
    move inline_camera_zoom to 0.8
    set needWait 0
    if {[collimatorMoveOut]} {
        incr needWait
    }
    if {[inlineLightControl_start insert]} {
        incr needWait
    }
    if {[lightsControl_start setup inline_tip]} {
        incr needWait
    }
    if {$needWait > 0} {
        log_warning wait for light to stable
        wait_for_time 2000
    }
    wait_for_devices inline_camera_zoom
}

proc matchup_moveTungstenToBeamQuick { user SID dir } {
    global gUserName
    global gSessionID

    variable save_loop_size
    variable gonio_phi

    set timeStart [clock seconds]

    #CCrystalCheckLoopCenter
    ### skip restore lights
    set save_phi $gonio_phi
    if {[catch { centerLoop_start 1 } errMsg]} {
        log_warning retry center the pin
        move gonio_phi to [expr $save_phi + 180]
        wait_for_devices gonio_phi
        centerLoop_start 1
    }

    send_operation_update "end of loop center"

    set isMicroMount [lindex $save_loop_size 8]
    if {$isMicroMount != "1"} {
        log_error cannot tell it is a microMount or not
        #return -code error failed_to_detector_microMount
    }
    #move camera_zoom to 1.0
    #wait_for_devices camera_zoom

    matchup_tungstenFaceProfile
    
	centerLoopTip 4 0.03
    move gonio_phi by 90
    wait_for_devices gonio_phi
	centerLoopTip 4 0.03
    move gonio_phi by -90
    wait_for_devices gonio_phi

    #set tipDelta [get_alignTungsten_constant tungsten_delta]
    #move sample_z by $tipDelta
    ### use following is more in line with design.
    set calibrated_sample_z [get_alignTungsten_constant beam_sample_z]
    set h [start_waitable_operation moveEncoders \
    0 [list [list sample_z_encoder $calibrated_sample_z]]]
    wait_for_operation_to_finish $h


    set timeEnd [clock seconds]
    set timeUsed [expr $timeEnd - $timeStart]
    set timeUsedText [secondToTimespan $timeUsed]
    send_operation_update move tungsten to beam cross used: $timeUsedText

    #### save snapshot
    set dir [file join [pwd] alignTungsten]
    file mkdir $dir
    set TS4Name [timeStampForFileName]
    set fname [file join $dir ${TS4Name}_moveCross2Tungsten.jpg]
    sequence_start takeSnapshotWithBeamBox $fname $gUserName $gSessionID
}

proc matchup_moveTungstenToBeam { user SID dir } {
    variable save_loop_size

    ### this will call loop centering if not yet
    ### so we get face on
    CCrystalCheckLoopCenter

    ####check microMount
    set isMicroMount [lindex $save_loop_size 8]
    if {$isMicroMount != "1"} {
        log_error cannot tell it is a microMount or not
        #return -code error failed_to_detector_microMount
    }

    foreach {old_sample_center_x old_sample_center_y old_sample_tip_x } \
    [matchup_getOldValues $user $SID $dir sample] break

    matchup_matchSampleCamera $user $SID $dir $old_sample_tip_x 2

    ## adjust for beam center move
    if {$old_sample_center_x > 0 && $old_sample_center_y > 0} {
        set cur_sample_center_x [getSampleCameraConstant zoomMaxXAxis]
        set cur_sample_center_y [getSampleCameraConstant zoomMaxYAxis]

        set sample_shift_x [expr $cur_sample_center_x - $old_sample_center_x]
        set sample_shift_y [expr $cur_sample_center_y - $old_sample_center_y]
    } else {
        set sample_shift_x 0
        set sample_shift_y 0
    }

    if {$sample_shift_x != 0 || $sample_shift_y != 0} {
        log_warning beam center on the sample camera moved \
        from $old_sample_center_x $old_sample_center_y \
        to $cur_sample_center_x $cur_sample_center_y

        puts "adjust by beam center: $sample_shift_x $sample_shift_y"
        moveSample_start $sample_shift_x $sample_shift_y
    }
}
proc matchup_moveInlineToTungsten { user SID dir } {
    variable inline_camera_horz
    variable inline_camera_vert

    save_operation_log inline_horz_orig $inline_camera_horz
    save_operation_log inline_vert_orig $inline_camera_vert

    foreach {- -  old_sample_tip_x } \
    [matchup_getOldValues $user $SID $dir sample] break

    matchup_checkOrientation $user $SID $dir $old_sample_tip_x

    ###inline camera
    foreach {old_inline_center_x old_inline_center_y old_inline_tip_x } \
    [matchup_getOldValues $user $SID $dir inline] break

    matchup_matchInlineCamera $user $SID $dir $old_inline_tip_x 2
    ## adjust for beam center move
    if {$old_inline_center_x > 0 && $old_inline_center_y > 0} {
        set cur_inline_center_x [getInlineCameraConstant zoomMaxXAxis]
        set cur_inline_center_y [getInlineCameraConstant zoomMaxYAxis]

        set inline_shift_x [expr $cur_inline_center_x - $old_inline_center_x]
        set inline_shift_y [expr $cur_inline_center_y - $old_inline_center_y]
    } else {
        set inline_shift_x 0
        set inline_shift_y 0
    }

    if {$inline_shift_x != 0 || $inline_shift_y != 0} {
        log_warning beam center on the inline camera moved \
        from $old_inline_center_x $old_inline_center_y \
        to $cur_inline_center_x $cur_inline_center_y

        foreach {deltaXmm deltaYmm} [inlineMoveSampleRelativeToMM \
        $inline_shift_x $inline_shift_y] break

        ### realmove
        move inline_camera_horz by $deltaXmm
        move inline_camera_vert by $deltaYmm
        wait_for_devices inline_camera_horz inline_camera_vert

    } else {
        set deltaXmm 0
        set deltaYmm 0
    }

    ### update "Inline" preset position
    #inlineCameraMoveSaveInlinePosition

    save_operation_log inline_horz_by_cross $deltaXmm
    save_operation_log inline_vert_by_cross $deltaYmm
    save_operation_log inline_horz_new $inline_camera_horz
    save_operation_log inline_vert_new $inline_camera_vert
}

### assumeing the pin already face inline
#### need to decide whether it needs rotate 180.
proc matchup_tungstenFaceInline { } {
    variable ::alignTungsten::face_phi
    variable gonio_phi

    if {$face_phi == ""} {
        log_error face_phi not set, has to run moveTungsten to cross first
        return -code error NOT_READY
    }

    ### face on sample camera
    move gonio_phi to $face_phi
    wait_for_devices gonio_phi


    set save_phi $gonio_phi
    set resultOK 0
    for {set times 0} {$times < 2} {incr times} {
        if {[catch {
            set h [start_waitable_operation getInlineLoopTip 0.5 0.5 0.1 1.0]
            set hr [wait_for_operation_to_finish $h]
            set resultOK 1
        } errMsg]} {
            set contents [UtilTakeInlineVideoSnapshot]
            set imageFile BadLight0_${times}_[timeStampForFileName].jpg
            if {![catch {open $imageFile w} handle0]} {
                fconfigure $handle0 -translation binary
                puts -nonewline $handle0 $contents
                close $handle0
                set handle0 ""
            } else {
                log_error failed to save BAD snapshot: $handle0
            }
            ### avoid glaring.
            move gonio_phi by -7.0
            wait_for_devices gonio_phi
        }
        if {$resultOK} {
            break
        }
        wait_for_time 2000
    }
    move gonio_phi to $save_phi
    wait_for_devices gonio_phi

    if {!$resultOK} {
        send_operation_update "ERROR getInlineLoopTip failed"
        log_severe getInlineLoopTip failed for autofocus:$errMsg
        return -code error $errMsg
    }

    set numScanPoints 9
    set scanWidth 40.0

    foreach {- tipX0 tipY0 tipHeight0} $hr break
    set hList0 [matchup_scanInlineIipHeight $numScanPoints $scanWidth]

    ### now we are at -90
    move gonio_phi by 180
    wait_for_devices gonio_phi
    set save_phi $gonio_phi
    set resultOK 0
    for {set times 0} {$times < 2} {incr times} {
        if {[catch {
            set h [start_waitable_operation getInlineLoopTip 0.5 0.5 0.1 1.0]
            set hr [wait_for_operation_to_finish $h]
            set resultOK 1
        } errMsg]} {
            set contents [UtilTakeInlineVideoSnapshot]
            set imageFile BadLight180_${times}_[timeStampForFileName].jpg
            if {![catch {open $imageFile w} handle0]} {
                fconfigure $handle0 -translation binary
                puts -nonewline $handle0 $contents
                close $handle0
                set handle0 ""
            } else {
                log_error failed to save BAD snapshot: $handle0
            }
            ### avoid glaring.
            move gonio_phi by 7.0
            wait_for_devices gonio_phi
        }
        if {$resultOK} {
            break
        }
        wait_for_time 2000
    }
    move gonio_phi to $save_phi
    wait_for_devices gonio_phi
    if {!$resultOK} {
        send_operation_update "ERROR getInlineLoopTip failed for auto focus"
        log_severe getInlineLoopTip failed for autofocus:$errMsg
        return -code error $errMsg
    }

    foreach {- tipX1 tipY1 tipHeight1} $hr break
    set hList1 [matchup_scanInlineIipHeight $numScanPoints $scanWidth]

    set minH 999999999
    set minI -1
    for {set i 0} {$i < $numScanPoints} {incr i} {
        set h0 [lindex $hList0 $i]
        set h1 [lindex $hList1 $i]
        if {$h0 > 0 && $h1 > 0} {
            set h [expr $h0 + $h1]
        } elseif {$h0 > 0} {
            set h $h0
        } elseif {$h1 > 1} {
            set h $h1
        } else {
            set h 999999999
        }
        if {$h < $minH} {
            set minH $h
            set minI $i
        }
    }
    if {$minI >= 0} {
        puts "adjust phi so that we got min tip height now and expect got face after 90"
        #set start [expr $gonio_phi - $scanWidth / 2]
        #set stepSize [expr $scanWidth / ($numScanPoints - 1.0)]
        #set phi [expr $start + $minI * $stepSize]
        #set delta [expr $phi - $gonio+phi]
        set delta [expr ($minI / ($numScanPoints - 1.0) - 0.5) * $scanWidth]
        puts "minI=$minI delta=$delta"

        move gonio_phi by $delta
        wait_for_devices gonio_phi
    }


    if {$tipY1 > $tipY0} {
        move gonio_phi by 90
    } else {
        move gonio_phi by -90
    }
    wait_for_devices gonio_phi
}
proc matchup_scanInlineIipHeight { numPoints scanWidth } {
    variable gonio_phi

    set orig_phi $gonio_phi

    set stepSize [expr $scanWidth / ($numPoints - 1.0)]
    set start [expr $orig_phi - $scanWidth / 2.0]
    puts "scanInlineTipHeight: orig=$orig_phi start=$start step=$stepSize"

    set heightList ""
    for {set i 0} {$i < $numPoints} {incr i} {
        set phi [expr $start + $i * $stepSize]
        move gonio_phi to $phi
        wait_for_devices gonio_phi
        wait_for_time 500
        set h [start_waitable_operation getInlineLoopTip 0.5 0.5 0.1 1.0]
        if {[catch {
            set hr [wait_for_operation_to_finish $h]
            foreach {- tipX tipY tipHeight} $hr break
            lappend heightList $tipHeight
        } errMsg]} {
            puts "scanInlineTipHeight failed for phi=$phi"
            lappend heightList -1
        }
        puts "scanInlineTipHeight: phi=$phi height=$tipHeight"
    }
    puts "scanInlineTipHeight: list $heightList"

    move gonio_phi to $orig_phi
    wait_for_devices gonio_phi
    wait_for_time 500
    return $heightList
}

proc matchup_scanProfileTipHeight { numPoints scanWidth } {
    variable gonio_phi

    set orig_phi $gonio_phi

    set stepSize [expr $scanWidth / ($numPoints - 1.0)]
    set start [expr $orig_phi - $scanWidth / 2.0]
    puts "scanProfileTipHeight: orig=$orig_phi start=$start step=$stepSize"

    set heightList ""
    for {set i 0} {$i < $numPoints} {incr i} {
        set phi [expr $start + $i * $stepSize]
        move gonio_phi to $phi
        wait_for_devices gonio_phi
        wait_for_time 500
        set h [start_waitable_operation getVerticalCut 0.25 0.5 0.05 1.0]
        set hr [wait_for_operation_to_finish $h]
        foreach {- tipY tipHeight} $hr break
        lappend heightList $tipHeight
        puts "scanProfileTipHeight: phi=$phi height=$tipHeight"
    }
    puts "scanProfileTipHeight: list $heightList"

    move gonio_phi to $orig_phi
    wait_for_devices gonio_phi
    wait_for_time 500
    return $heightList
}

proc matchup_getTungstenInlinePosition { } {
    variable gonio_phi

    ###### lights setup
    matchup_inlineLightSetup

    set save_phi $gonio_phi

    set h [start_waitable_operation getInlineLoopTip 0.5 0.5 0.1 1.0]
    if {[catch {
        set hr [wait_for_operation_to_finish $h]
    } errMsg]} {
        set contents [UtilTakeInlineVideoSnapshot]
        set imageFile BadLightTungstenPosition_[timeStampForFileName].jpg
        if {![catch {open $imageFile w} handle0]} {
            fconfigure $handle0 -translation binary
            puts -nonewline $handle0 $contents
            close $handle0
            set handle0 ""
        } else {
            log_error failed to save BAD snapshot: $handle0
        }
        return -code erro $errMsg
    }
    foreach {- tipX tipY tipHeight} $hr break

    set tipDeltaMM [get_alignTungsten_constant tungsten_delta]
    foreach {tipDelta -} [inlineMoveSample_mmToRelative $tipDeltaMM 0] break
    set tipDelta [expr abs($tipDelta)]

    set tungstenX [expr $tipX - $tipDelta]
    set tungstenY $tipY
    return [list $tungstenX $tungstenY]
}
proc matchup_autoFocusInlineCamera { user SID dir } {
    set timeStart [clock seconds]

    matchup_inlineLightSetup
    matchup_tungstenFaceInline
    inlineCameraAutofocus_start

    set timeEnd [clock seconds]
    set timeUsed [expr $timeEnd - $timeStart]
    set timeUsedText [secondToTimespan $timeUsed]
    send_operation_update autofocus inline used: $timeUsedText
}
proc matchup_moveInlineToTungstenQuick { } {
    variable inline_camera_horz
    variable inline_camera_vert

    set timeStart [clock seconds]

    set orig_horz $inline_camera_horz
    set orig_vert $inline_camera_vert

    save_operation_log inline_horz_orig $inline_camera_horz
    save_operation_log inline_vert_orig $inline_camera_vert

    ##################################################
    set max_vert [get_alignTungsten_constant max_vert_move]
    set max_horz [get_alignTungsten_constant max_horz_move]
    for {set times 0} {$times < 2} {incr times} {
        foreach {tungstenX tungstenY} [matchup_getTungstenInlinePosition] break

        set cur_inline_center_x [getInlineCameraConstant zoomMaxXAxis]
        set cur_inline_center_y [getInlineCameraConstant zoomMaxYAxis]

        ### inline camera is horz flipped
        set tungstenX [expr 1.0 - $tungstenX]
        set inline_shift_x [expr $cur_inline_center_x - $tungstenX]
        set inline_shift_y [expr $cur_inline_center_y - $tungstenY]

        foreach {deltaXmm deltaYmm} [inlineMoveSampleRelativeToMM \
        $inline_shift_x $inline_shift_y] break

        send_operation_update "relative move: $inline_shift_x $inline_shift_y"
        send_operation_update "mme move: $deltaXmm $deltaYmm"

        if {abs($deltaYmm) > abs($max_vert) \
        ||  abs($deltaXmm) > abs($max_horz) } {
            send_operation_update "ERROR inline camera off range"
            log_severe inline camera off ($deltaXmm,$deltaYmm) more than allowed \
            ($max_horz,$max_vert)
            log_error need confirm and manually adjust
            return -code error 
        }

        ### realmove
        move inline_camera_horz by $deltaXmm
        move inline_camera_vert by $deltaYmm
        wait_for_devices inline_camera_horz inline_camera_vert

        if {abs($deltaXmm) < 0.005 && abs($deltaYmm) < 0.005} {
            break
        } else {
            send_operation_update "moved more than 5 micron, may need redo"
            log_warning moved more than 5 micron, may need redo
        }
    }
    ### update "Inline" preset position
    #inlineCameraMoveSaveInlinePosition

    if {[catch matchup_fineTuneInlineVert errMsg]} {
        log_error fineTuneInlineVert failed: $errMsg
        send_operation_update "ERROR fine tune inline vert failed: $errMsg"
    }

    save_operation_log inline_horz_new $inline_camera_horz
    save_operation_log inline_vert_new $inline_camera_vert
    save_operation_log inline_horz_diff [expr $inline_camera_horz - $orig_horz]
    save_operation_log inline_vert_diff [expr $inline_camera_vert - $orig_vert]
    set timeEnd [clock seconds]
    set timeUsed [expr $timeEnd - $timeStart]
    set timeUsedText [secondToTimespan $timeUsed]
    send_operation_update move inline to tungsten used: $timeUsedText

    return [list $deltaXmm $deltaYmm]
}
proc matchup_fineTuneInlineVert { } {
    set cur_inline_center_x [getInlineCameraConstant zoomMaxXAxis]
    set cur_inline_center_y [getInlineCameraConstant zoomMaxYAxis]

    ### distance from sample position to tungsten
    ### this is to aim the little horizontal bar close to tungsten.
    ### we use that to fine tune vert.
    set dd_horz 0.007
    set width  0.005
    set height 0.030

    foreach {offset_horz -} [inlineMoveSample_mmToRelative $dd_horz 0] break
    foreach {w h} [inlineMoveSample_mmToRelative $width $height] break

    set x [expr 1.0 - $cur_inline_center_x + abs($offset_horz)]
    set y $cur_inline_center_y

    send_operation_update "fineTuneInlineVert ROI $x $y $w $h"
    set h [start_waitable_operation getInlineLoopTip $x $y $w $h]
    if {[catch {
        set hr [wait_for_operation_to_finish $h]
    } errMsg]} {
        set contents [UtilTakeInlineVideoSnapshot]
        set imageFile BadFineTuneVert_[timeStampForFileName].jpg
        if {![catch {open $imageFile w} handle0]} {
            fconfigure $handle0 -translation binary
            puts -nonewline $handle0 $contents
            close $handle0
            set handle0 ""
        } else {
            log_error failed to save BAD snapshot: $handle0
        }
        return -code error $errMsg
    }
    foreach {- tipX tipY tipHeight} $hr break

    set inline_shift_y [expr $cur_inline_center_y - $tipY]
    foreach {- deltaYmm} [inlineMoveSampleRelativeToMM \
    0 $inline_shift_y] break

    if {abs($deltaYmm) > 0.01} {
        send_operation_update "ERROR inlineFineTuneVert failed"
        log_severe inlineFineTuneVert failed delta $deltaYmm too big, \
        please check.
        return
    }
    move inline_camera_vert by $deltaYmm
    wait_for_devices inline_camera_vert
    send_operation_update "fineTuneInlineVert by $deltaYmm mm"
}
proc matchup_saveSampleCameraImage { user SID dir prefix {backup 0}} {
    set fileName [file join $dir ${prefix}.jpg]
    videoSnapshot_start $user $SID $fileName
    if {$backup} {
        set fileCopy [file join $dir ${prefix}_[timeStampForFileName].jpg]
        impCopyFile $user $SID $fileName $fileCopy
    }
}
proc matchup_saveInlineCameraImage { user SID dir prefix {backup 0}} {
    set needWait 0
    if {[collimatorMoveOut]} {
        incr needWait
    }
    if {[centerMaxInineLight]} {
        incr needWait
    }
    if {[inlineLightControl_start insert]} {
        incr needWait
    }
    if {$needWait > 0} {
        log_warning wait for light to stable
        wait_for_time 2000
    }

    set fileName [file join $dir ${prefix}.jpg]
    inlineSnapshot_start $user $SID $fileName
    if {$backup} {
        set fileCopy [file join $dir ${prefix}_[timeStampForFileName].jpg]
        impCopyFile $user $SID $fileName $fileCopy
    }
}
proc matchup_saveSamplePerfect { user SID dir } {
    puts "saving sample image"
    matchup_saveSampleCameraImage $user $SID $dir perfectSample 1

    set h [start_waitable_operation getLoopTip 0]
    set hr [wait_for_operation_to_finish $h]
    set sampleTip [lindex $hr 1]
    set cur_sample_center_x [getSampleCameraConstant zoomMaxXAxis]
    set cur_sample_center_y [getSampleCameraConstant zoomMaxYAxis]

    ##### tungsten deposit is at 15 micron from tip
    foreach {dx dy} [moveSample_mmToRelative 0.016 0] break
    set sTipFromCenter [expr $cur_sample_center_x + $dx]
    set dd [expr abs($sTipFromCenter - $sampleTip)]
    puts "16u==>rel: $dx dd=$dd"
    ### 2 pixels
    if {$dd > 0.003} {
        log_error looks like tungsten deposit is not at the beam center on sample camera
        log_error DEBUG tip=$sampleTip from beam center=$sTipFromCenter
    }

    set    contents "BEAM_CENTER_ON_VIDEO_X=$cur_sample_center_x\n"
    append contents "BEAM_CENTER_ON_VIDEO_Y=$cur_sample_center_y\n"
    append contents "TIP_X=$sampleTip\n"

    set fileName [file join $dir perfectSample.txt]
    set fileCopy [file join $dir perfectSample_[timeStampForFileName].txt]
    puts "saving file $fileName and $fileCopy"
    impWriteFile $user $SID $fileName $contents 0
    impWriteFile $user $SID $fileCopy $contents 0
    log_warning perfect sample image saved
}

proc matchup_saveInlinePerfect { user SID dir } {
    puts "saving inline image"
    matchup_saveInlineCameraImage $user $SID $dir perfectInline 1
    set h [start_waitable_operation getInlineLoopTip 0.5 0.5 1.0 1.0]
    if {[catch {
        set hr [wait_for_operation_to_finish $h]
    } errMsg]} {
        set contents [UtilTakeInlineVideoSnapshot]
        set imageFile BadSavePerfect_[timeStampForFileName].jpg
        if {![catch {open $imageFile w} handle0]} {
            fconfigure $handle0 -translation binary
            puts -nonewline $handle0 $contents
            close $handle0
            set handle0 ""
        } else {
            log_error failed to save BAD snapshot: $handle0
        }
        return -code erro $errMsg
    }
    set inlineTip [lindex $hr 1]

    set cur_inline_center_x [getInlineCameraConstant zoomMaxXAxis]
    set cur_inline_center_y [getInlineCameraConstant zoomMaxYAxis]

    ####check center
    set dd [expr $inlineTip - $cur_inline_center_x]
    puts "inline dd=$dd"
    foreach {ddMM dummy} [inlineMoveSampleRelativeToMM $dd 0] break
    puts "inline ddMM=$ddMM"
    set ddMM [expr abs($ddMM) - 0.016]
    ### here is 3 microns
    if {abs($ddMM) > 0.003} {
        log_error looks like tungsten deposit is not at beam center on inline camera
        log_error DEBUG ddMM=$ddMM
    }

    ### txt file
    set    contents "BEAM_CENTER_ON_VIDEO_X=$cur_inline_center_x\n"
    append contents "BEAM_CENTER_ON_VIDEO_Y=$cur_inline_center_y\n"
    append contents "TIP_X=$inlineTip\n"

    set fileName [file join $dir perfectInline.txt]
    set fileCopy [file join $dir perfectInline_[timeStampForFileName].txt]
    puts "saving file $fileName and $fileCopy"
    impWriteFile $user $SID $fileName $contents 0
    impWriteFile $user $SID $fileCopy $contents 0

    log_warning perfect inline image saved
}
proc matchup_doMatch { user SID perfect snapshot } {
    set cmd "/usr/local/dcs/matchup/run_matchup.com%20${perfect}%20${snapshot}"
    set url "http://localhost:61001"
    append url "/runScript?impUser=$user"
    append url "&impSessionID=$SID"
    append url "&impCommandLine=$cmd"
    append url "&impUseFork=false"
    append url "&impEnv=HOME=/home/${user}"

    puts "matchup url: [SIDFilter $url]"

    set token [http::geturl $url -timeout 8000]
    checkHttpStatus $token
    set result [http::data $token]
    upvar #0 $token state
    array set meta $state(meta)
    http::cleanup $token
     
    puts "match url result: $result"
    foreach name [array names meta] {
        puts "$name=$meta($name)"
    }

    set tokens [split $result "\n"]
    set lastLine ""
    set line ""
    foreach {line} $tokens {
        if {$line != ""} {
            puts "matchup result line = $line"
            set lastLine $line
        }
    }
    if {$lastLine == ""} {
        send_operation_update "ERROR matchup failed"
        log_severe matchup failed
        alignCollimatorLog image matchup failed: empty result
        return -code error match_failed
    }

    if {[llength $lastLine] < 3} {
        send_operation_update "ERROR matchup failed"
        log_severe matchup failed
        alignCollimatorLog image matchup failed: wrong result format
        return -code error matchup_failed
    }

    foreach {pixel_h pixel_v score} $lastLine break
    if {![string is double -strict $pixel_h] \
    || ![string is double -strict $pixel_v]
    || ![string is double -strict $score]} {
        send_operation_update "ERROR matchup failed"
        log_severe matchup failed
        alignCollimatorLog image matchup failed: wrong results
        return -code error match_failed
    }
    if {$score < 0.75} {
        send_operation_update "ERROR matchup failed"
        log_severe matchup failed
        alignCollimatorLog image matchup failed: score $score too low
        return -code error matchup_failed
    }

    return [list $pixel_h $pixel_v $score]
}
proc matchup_getOldValues { user SID dir sample_or_inline } {
    ## default
    set old_center_x -1
    set old_center_y -1
    set old_tip_x -1

    if {$sample_or_inline == "inline"} {
        set fileName [file join $dir perfectInline.txt]
    } else {
        set fileName [file join $dir perfectSample.txt]
    }

    if {[catch {
        set contents [impReadFile $user $SID $fileName]
        set lineList [split $contents \n]
        foreach line $lineList {
            set nv_pair [split $line =]
            set name  [lindex $nv_pair 0]
            set value [lindex $nv_pair 1]
            switch -exact -- $name {
                BEAM_CENTER_ON_VIDEO_X {
                    set old_center_x $value
                }
                BEAM_CENTER_ON_VIDEO_Y {
                    set old_center_y $value
                }
                TIP_X {
                    set old_tip_x $value
                }
            }
        }
    } errMsg]} {
        log_warning failed to retrieve information for perfect.
        log_warning will SKIP beam center adjust or tip verify
    }

    return [list $old_center_x $old_center_y $old_tip_x]
}
proc matchup_matchSampleCamera { user SID dir old_tip max_loop } {
    #### lights control is copied from centerLoop
    set restore_lights 1
    if {[catch centerSaveAndSetLights errMsg]} {
        log_warning lights control failed $errMsg
        set restore_lights 0
    }
    move camera_zoom to 1.0
    wait_for_devices camera_zoom
    log_warning wait lights to stable
    wait_for_time 5000

    
	centerLoopTip 4 0.03
    move gonio_phi by 90
    wait_for_devices gonio_phi
	centerLoopTip 4 0.03
    move gonio_phi by -90
    wait_for_devices gonio_phi

    set samplePerfect [file join $dir perfectSample.jpg]
    foreach {old_w old_h} [matchup_getImageSize $samplePerfect] break
    set sample_w -1
    set sample_h -1
    if {$max_loop < 1} {
        set max_loop 1
    }
    for {set i 0} {$i < $max_loop} {incr i} {
        set fileName [file join $dir matchSample_$i.jpg]
        videoSnapshot_start $user $SID $fileName
        if {$sample_w < 0} {
            foreach {sample_w sample_h} [matchup_getImageSize $fileName] break
            if {$sample_w != $old_w || $sample_h != $old_h} {
                send_operation_update "ERROR image size not match"
                log_severe image size not match
                alignCollimatorLog image matchup failed: image size not match
                return -code error IMAGE_SIZE_CHANGED
            }
        }
        foreach {sample_pixel_h sample_pixel_v} \
        [matchup_doMatch $user $SID $samplePerfect $fileName] break

        set sample_dx [expr -1.0 * $sample_pixel_h / $sample_w]
        set sample_dy [expr -1.0 * $sample_pixel_v / $sample_h]
        log_warning sample camera matchup [expr $i + 1]: \
        pixel $sample_pixel_h $sample_pixel_v \
        rel: $sample_dx $sample_dy

        moveSample_start $sample_dx $sample_dy

        if {abs($sample_pixel_h) < 2 && abs($sample_pixel_v) < 2} {
            break
        }
        log_warning wait motors to settle down and video server delay
        wait_for_time 5000
    }

    if {$old_tip > 0} {
        set h [start_waitable_operation getLoopTip 0]
        set hr [wait_for_operation_to_finish $h]
        set sampleTip [lindex $hr 1]

        ## about 2 pixels 2/704=
        if {abs($sampleTip - $old_tip) > 0.003} {
            log_warning sample tip not match with perfect: \
            old: $old_tip new: $sampleTip
            send_operation_update "ERROR matchup: tip check failed"
            log_severe matchup failed: tip check failed.
            alignCollimatorLog image matchup failed: tip not match
            return -code error TIP_NOT_MATCH
        }
    }

    if {$restore_lights} {
        centerRestoreLights
    }
}
proc matchup_getImageSize { fileName } {
    puts "try to get image size of $fileName"
    set size [lindex [exec identify $fileName] 2]
    puts "size=$size"

    set size [split $size x]
    set w [lindex $size 0]
    set h [lindex $size 1]
    if {![string is double -strict $w] \
    || ![string is double -strict $h]} {
        log_severe failed to get image size
        alignCollimatorLog ERROR image matchup failed: failed to get image size
        return -code error FAIL_TO_GET_SIZE
    }
    return [list $w $h]
}
proc matchup_matchInlineCamera { user SID dir old_tip max_loop } {
    collimatorMoveOut
    #centerMaxInlineLight
    inlineLightControl_start insert
    log_warning wait for light to stable
    wait_for_time 2000

    set inlinePerfect [file join $dir perfectInline.jpg]
    foreach {old_w old_h} [matchup_getImageSize $inlinePerfect] break
    set inline_w -1
    set inline_h -1
    if {$max_loop < 1} {
        set max_loop 1
    }
    for {set i 0} {$i < $max_loop} {incr i} {
        set fileName [file join $dir matchInline_$i.jpg]
        inlineSnapshot_start $user $SID $fileName
        if {$inline_w < 0} {
            foreach {inline_w inline_h} [matchup_getImageSize $fileName] break
            if {$inline_w != $old_w || $inline_h != $old_h} {
                log_severe inlinle image size not match
                alignCollimatorLog ERROR image matchup failed: inline image size not match
                return -code error INLINE_IMAGE_SIZE_CHANGED
            }
        }
        foreach {inline_pixel_h inline_pixel_v} \
        [matchup_doMatch $user $SID $inlinePerfect $fileName] break

        set inline_dx [expr -1.0 * $inline_pixel_h / $inline_w]
        set inline_dy [expr -1.0 * $inline_pixel_v / $inline_h]

        foreach {deltaXmm deltaYmm} [inlineMoveSampleRelativeToMM \
        $inline_dx $inline_dy] break

        log_warning inline camera matchup [expr $i + 1]: \
        pixel $inline_pixel_h $inline_pixel_v \
        rel: $inline_dx $inline_dy \
        mm: $deltaXmm $deltaYmm

        if {abs($deltaXmm) > 0.025 || abs($deltaYmm) > 0.01} {
            log_severe inline camera off more than 25 microns.
            log_severe Please confirm and manually adjust it.
            alignCollimatorLog ERROR image matchup failed: inline camera off more than 25 mircons
            return -code error EXCEED_ADJUST_LIMIT
        }

        ### horz move camera.  vert move sample
        move inline_camera_horz by $deltaXmm
        move inline_camera_vert by $deltaYmm
        wait_for_devices inline_camera_horz inline_camera_vert

        if {abs($inline_pixel_h) < 2 && abs($inline_pixel_v) < 2} {
            break
        }
        log_warning wait motors to settle down and video server delay
        wait_for_time 2000
    }

    if {$old_tip > 0} {
        if {[catch {
            set h [start_waitable_operation getInlineLoopTip 0.5 0.5 1.0 1.0]
            set hr [wait_for_operation_to_finish $h]
            set inlineTip [lindex $hr 1]
        } errMsg]} {
            log_warning inline camera tip failed, skip tip checking
        } else {
            ## about 2 pixels 2/704=
            if {abs($inlineTip - $old_tip) > 0.003} {
                log_warning inline tip not match with perfect: \
                old: $old_tip new: $inlineTip
                #return -code error INLINE_TIP_NOT_MATCH
            }
        }
    }
}
proc matchup_movePhiToShowEdgeOnSampleCamera { } {
    variable gonio_phi
    set handle [start_waitable_operation addImageToList 0]
    set result [wait_for_operation $handle 30000]
    set hOld [lindex $result 1]
    set pOld $gonio_phi

    set hMin $hOld
    set pMin $pOld

    set MAX_TIMES 20
    set STEP_SIZE 5.0

    send_operation_update "init phi=$pOld h=$hOld"

    set dir 1.0
    set reversing 0
    for {set i 0} {$i < $MAX_TIMES} {incr i} {
        if {$reversing} {
            ## skip the old position
            move gonio_phi by [expr $dir * 2.0 * $STEP_SIZE]
        } else {
            move gonio_phi by [expr $dir * $STEP_SIZE]
        }
        wait_for_devices gonio_phi
        set handle [start_waitable_operation addImageToList 0]
        set result [wait_for_operation $handle 30000]
        set hNow [lindex $result 1]
        set pNow $gonio_phi
        if {$hNow < $hMin} {
            set hMin $hNow
            set pMin $pNow
            send_operation_update "set hMin=$hMin pMin to $pMin"
        }

        send_operation_update "i=$i phi=$pNow h=$hNow"
        if {$hNow > $hOld} {
            if {$i > 0} {
                move gonio_phi to $pOld
                wait_for_devices gonio_phi
                break
            }
            ### switch direction
            set dir [expr $dir * -1]
            set reversing 1
        } else {
            set reversing 0
            set pOld $pNow
            set hOld $hNow
        }
    }

    send_operation_update "scan around current phi: $gonio_phi"
    set handle [start_waitable_operation addImageToList 0]
    set result [wait_for_operation $handle 30000]

    set newSTEPSIZE 1.0
    set N [expr int($STEP_SIZE)]

    set p0 [expr $gonio_phi - $N * $newSTEPSIZE / 2.0]
    for {set i 0} {$i <= $N} {incr i} {
        set p [expr $p0 + $i * $newSTEPSIZE]
        move gonio_phi to $p
        wait_for_devices gonio_phi
        set handle [start_waitable_operation addImageToList 0]
        set result [wait_for_operation $handle 30000]
        set h [lindex $result 1]
        send_operation_update "i=$i phi=$gonio_phi h=$h"
        if {$h < $hMin} {
            set hMin $h
            set pMin $gonio_phi
        }
    }
    move gonio_phi to $pMin
    wait_for_devices gonio_phi
}
proc matchup_checkOrientation { user SID dir old_tip } {
    #matchup_movePhiToShowEdgeOnSampleCamera

    move camera_zoom to 0
    wait_for_devices camera_zoom

    set samplePerfect [file join $dir perfectSample.jpg]
    foreach {old_w old_h} [matchup_getImageSize $samplePerfect] break
    set sample_w -1
    set sample_h -1

    set fileName [file join $dir matchSample_0.jpg]
    videoSnapshot_start $user $SID $fileName
    foreach {sample_w sample_h} [matchup_getImageSize $fileName] break
    if {$sample_w != $old_w || $sample_h != $old_h} {
        log_severe sample image size not match
        alignCollimatorLog ERROR image matchup failed: sample image size not match
        return -code error IMAGE_SIZE_CHANGED
    }
    if {[catch {
        foreach {h0 v0 score0} \
        [matchup_doMatch $user $SID $samplePerfect $fileName] break
    } error] == 1} {
        set h0 0
        set v0 0
        set score0 0
    }
    log_warning match orientation 0: $h0 $v0 $score0

    move gonio_phi by 180
    wait_for_devices gonio_phi
    wait_for_time 2000

    set fileName [file join $dir matchSample_180.jpg]
    videoSnapshot_start $user $SID $fileName
    if {[catch {
        foreach {h1 v1 score1} \
        [matchup_doMatch $user $SID $samplePerfect $fileName] break
    } error] == 1} {
        set h1 0
        set v1 0
        set score1 0
    }
    log_warning match orientation 180: $h1 $v1 $score1

    if {$score0 == 0 && $score1 == 0} {
        log_severe failed to detect edge orientation
        alignCollimatorLog ERROR failed to detect edge or orientation
        return -code error ORIENTATION_FAILED
    }

    if {abs($score1 - $score0) < 0.02} {
        log_error edge orientation detection failed: difference too small.
        #return -code error ORIENTATION_FAILED
    }

    if {$score0 > $score1} {
        move gonio_phi by 180
        wait_for_devices gonio_phi
    }

    if {$old_tip > 0} {
        set h [start_waitable_operation getLoopTip 0]
        set hr [wait_for_operation_to_finish $h]
        set sampleTip [lindex $hr 1]

        ## about 2 pixels 2/704=
        if {abs($sampleTip - $old_tip) > 0.003} {
            log_warning sample tip not match with perfect: \
            old: $old_tip new: $sampleTip
        }
    }
    move camera_zoom to 1
    wait_for_devices camera_zoom
}
### must immediately follows centerLoop
proc matchup_tungstenFaceProfile { } {
    move gonio_phi by 90
    wait_for_devices gonio_phi

    set numScanPoints 9
    set scanWidth 40.0
    set hList [matchup_scanProfileTipHeight $numScanPoints $scanWidth]
    set minH 999999999
    set minI -1
    for {set i 0} {$i < $numScanPoints} {incr i} {
        set h [lindex $hList $i]
        if {$h < $minH} {
            set minH $h
            set minI $i
        }
    }
    if {$minI >= 0} {
        set delta [expr ($minI / ($numScanPoints - 1.0) - 0.5) * $scanWidth]
        puts "minI=$minI delta=$delta"

        move gonio_phi by $delta
        wait_for_devices gonio_phi
    }
    move gonio_phi by -90
    wait_for_devices gonio_phi
}
