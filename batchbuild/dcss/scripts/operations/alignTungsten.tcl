proc alignTungsten_initialize {} {
    namespace eval ::alignTungsten {
        global gMotorBeamWidth
        global gMotorBeamHeight
        global gMotorEnergy

        #### energy and attenuation are build-in.
        set mList [list \
        $gMotorBeamWidth \
        $gMotorBeamHeight \
        fluorescence_z \
        ]

        ### name tag in constants
        set nList [list \
            beam_width \
            beam_height \
            fluorescence_z \
        ]

        set HORZ_MOVE_MIRROR 0
        set ONLY_MOVE_MFD 1

        set face_phi ""

        set orig_energy ""
        set orig_attenuation ""
        set restore_orig_cmd ""

        set logKey [list \
        energy_aligned_at \
        peak_sample_z \
        new_sample_z \
        sample_z_diff \
        table_vert_orig \
        table_vert_new \
        table_vert_diff \
        cross_horz_orig \
        cross_horz_new \
        cross_horz_diff_mm \
        cross_vert_orig \
        cross_vert_new \
        cross_vert_diff_mm \
        mirror_horz_orig \
        mirror_horz_new \
        mirror_horz_diff \
        i0 \
        i2 \
        piezo_horz \
        piezo_vert \
        lvdt_m0_horz \
        lvdt_m0_yaw \
        t_hutch_table \
        t_mirror_enclosure \
        t_12_0_hutch \
        t_building_130 \
        t_focusing_m2_horz \
        t_mirror_alcove \
        detector_horz_encoder \
        detector_vert_encoder \
        detector_z_encoder \
        table_vert_1_encoder \
        table_vert_2_encoder \
        table_horz_encoder \
        mono_theta_encoder \
        sample_z_encoder \
        gonio_vert_encoder \
        focusing_mirror_2_mfd_vert_encoder \
        mirror_mfd_horz_encoder \
        table_horz_orig \
        table_horz_new \
        table_horz_diff \
        mirror_mfd_horz_orig \
        mirror_mfd_horz_new \
        mirror_mfd_horz_diff \
        ]

        ## must match with above ion chamber list
        set logIonChamberKey [list \
        i0 \
        i2 \
        piezo_horz \
        piezo_vert \
        lvdt_m0_horz \
        lvdt_m0_yaw \
        t_hutch_table \
        t_mirror_enclosure \
        t_12_0_hutch \
        t_building_130 \
        t_focusing_m2_horz \
        t_mirror_alcove \
        ]
        set logIonChamberName [list \
        i0 \
        i2 \
        v_piezo_control_average_horz \
        v_piezo_control_average_vert \
        e_lvdt_m0_horz \
        e_lvdt_m0_yaw \
        t_hutch_table_top \
        t_mirror_enclosure \
        t_12-0_hutch \
        t_building_130_ambient \
        t_focusing_mirror_2_hor \
        t_mirror_alcove_ambient \
        ]

        set logEncoderKeyName [list \
        detector_horz_encoder \
        detector_vert_encoder \
        detector_z_encoder \
        table_vert_1_encoder \
        table_vert_2_encoder \
        table_horz_encoder \
        mono_theta_encoder \
        sample_z_encoder \
        gonio_vert_encoder \
        focusing_mirror_2_mfd_vert_encoder \
        mirror_mfd_horz_encoder \
        ]

        ### operations allowed or included
        ### we may use these in the future
        set logOperation [list \
        alignTungsten \
        ]

        set logStartTime 0

        #### we want to move everything back to original if we failed to
        #### move the crosshair.
        set orig_mfd_horz ""
        set orig_table_vert ""
        set orig_table_horz ""

        set orig_energy_offset ""
    }
}
proc alignTungsten_findGoodVert { dir TS4Name } {
    variable sample_x
    variable sample_y

    #### init vert scan
    set name ${TS4Name}vert_init.scan
    set fileName [file join $dir $name]
    set vert0Result [alignTungsten_scan $fileName vert]
    alignTungstenLog vert0 $vert0Result

    #### check signal
    set peakV0 [lindex $vert0Result 1]
    set goodSignal [get_alignTungsten_constant good_signal]
    if {$peakV0 >= $goodSignal} {
        alignTungstenLog inital vert scan good, skip init horz and use this as vert0
        return $vert0Result
    }

    #### not so good, we do a ini horz scan
    set v0 [lindex $vert0Result 0]
    alignTungstenLog inital vert scan moving sample_x to $v0
    move sample_x to $v0
    wait_for_devices sample_x

    ############ first time horz
    #set name horz_init${TS4Name}.scan
    set name ${TS4Name}horz_init.scan
    set fileName [file join $dir $name]
    alignTungstenLog doing horz scan with sample_x=$sample_x sample_y=$sample_y
    ### it will fail here if the signal is less than min_signal
    set horz0Result [alignTungsten_scan $fileName horz]
    alignTungstenLog horz0 $horz0Result
    set h0 [lindex $horz0Result 0]
    alignTungstenLog move sample_z to $h0
    move sample_z to $h0
    wait_for_devices sample_z

    #### now try vert again
    set name ${TS4Name}vert_0.scan
    set fileName [file join $dir $name]
    set vert0Result [alignTungsten_scan $fileName vert]
    alignTungstenLog vert0 $vert0Result
    set v0 [lindex $vert0Result 0]
    
    ###check signsl
    set peakV0 [lindex $vert0Result 1]
    set goodSignal [get_alignTungsten_constant good_signal]
    if {$peakV0 < $goodSignal} {
        log_error signal too small to continue
        return -code error SIGNAL_TOO_SMALL
    }
    return $vert0Result
}
proc alignTungsten_redoVert { dir TS4Name } {
    variable gonio_omega

    move gonio_phi to [expr 360.0 - $gonio_omega]
    wait_for_devices gonio_phi

    set name ${TS4Name}vert_redo_0.scan
    set fileName [file join $dir $name]
    set vert0Result [alignTungsten_scan $fileName vert]
    alignTungstenLog vert0 $vert0Result
    set v0 [lindex $vert0Result 0]
    
    move gonio_phi by 180
    wait_for_devices gonio_phi
    set name ${TS4Name}vert_redo_180.scan
    set fileName [file join $dir $name]
    set vert180Result [alignTungsten_scan $fileName vert]
    alignTungstenLog vert180 $vert180Result
    set v180 [lindex $vert180Result 0]

    set vCenter0 [expr ($v0 + $v180) / 2.0]
    set dd0 [expr $v180 - $vCenter0]

    move sample_x to $vCenter0
    wait_for_devices sample_x

    alignTungstenLog redo_dd0=$dd0
    log_warning redo_dd0=$dd0

    alignTungstenMovePhiAxisToBeam $dd0
}
proc alignTungsten_start { args } {
    variable ::alignTungsten::face_phi
    variable ::alignTungsten::orig_mfd_horz
    variable ::alignTungsten::orig_table_vert
    variable ::alignTungsten::orig_table_horz
    variable ::alignTungsten::orig_energy_offset
    variable energy
    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega
    variable mirror_horz
    variable table_vert
    variable table_horz
    variable mirror_mfd_horz
    variable focusing_mirror_2_mfd_vert
    variable energy_offset

    if {[lindex $args 0] == "CROSS"} {
        alignTungstenMoveCrossToTungsten
        return
    }

    set orig_mfd_horz   $mirror_mfd_horz
    set orig_table_vert $table_vert
    set orig_table_horz $table_horz
    set orig_energy_offset $energy_offset

    set timeStart [clock seconds]

    set face_phi $gonio_phi
    if {[lindex $args 0] == "DEBUG"} {
        #alignTungstenMoveCrossToTungsten
        #alignTungsten_setup
        #alignTungsten_restore
        return
    }

    clear_operation_log alignTungsten

    ### assume started with face on sample camera
    set orig_z $sample_z

    set dir [file join [pwd] alignTungsten]
    file mkdir $dir
    set TS4Name [timeStampForFileName]

    set dd0 0

    if {[catch {
        alignTungstenLog align tungsten started for $TS4Name sample_z=$orig_z
        alignTungsten_setup
        collimatorNormalIn
        inlineLightControl_start remove

        ##### vertical first because beam vertical is much more narrow
        ### now sample_X cross beam
        move gonio_phi to [expr 360.0 - $gonio_omega]
        wait_for_devices gonio_phi

        set vert0Result [alignTungsten_findGoodVert $dir $TS4Name]
        set v0 [lindex $vert0Result 0]
    
        move gonio_phi by 180
        wait_for_devices gonio_phi
        set name ${TS4Name}vert_180.scan
        set fileName [file join $dir $name]
        set vert180Result [alignTungsten_scan $fileName vert]
        alignTungstenLog vert180 $vert180Result
        set v180 [lindex $vert180Result 0]

        set vCenter0 [expr ($v0 + $v180) / 2.0]
        set dd0 [expr $v180 - $vCenter0]

        move sample_x to $vCenter0
        wait_for_devices sample_x

        alignTungstenLog dd0=$dd0
        log_warning dd0=$dd0
    } errMsg] == 1} {
        log_severe Tungsten scan failed. \
        Restore energy offset.
        set energy_offset $orig_energy_offset
        set detail "Tungsten scan: $errMsg"
        return -code error $detail
    }

    if {[catch {
        alignTungstenMovePhiAxisToBeam $dd0
        if {abs($dd0) > 0.008} {
            alignTungsten_redoVert $dir $TS4Name
        }
    } errMsg] == 1} {
        log_severe Failed to move phi axis to beam. \
        Restore energy offset.
        set energy_offset $orig_energy_offset
        set detail "Beam positioning on phi: $errMsg"
        return -code error $detail
    }

    save_operation_log table_vert_orig $orig_table_vert
    save_operation_log table_vert_new  $table_vert
    save_operation_log table_vert_diff [expr $table_vert - $orig_table_vert]

    ###final horizontal
    if {[catch {
        set name ${TS4Name}horz_final.scan
        set fileName [file join $dir $name]
        set horz1Result [alignTungsten_scan $fileName horz]
        alignTungstenLog horz1 $horz1Result
        set h1 [lindex $horz1Result 0]

        move sample_z to $h1
        wait_for_devices sample_z
        get_encoder sample_z_encoder
        set he1 [wait_for_encoder sample_z_encoder]
        set calibrated_sample_z [get_alignTungsten_constant beam_sample_z]
        set h [start_waitable_operation moveEncoders \
        0 [list [list sample_z_encoder $calibrated_sample_z]]]
        wait_for_operation_to_finish $h
    

        alignTungstenLog final horz scan sample_z = $h1 sample_z_encoder = $he1
        set dz [expr $calibrated_sample_z - $he1]
        log_warning dz=$dz

        set mirror_horz_orig $mirror_horz
        save_operation_log table_horz_orig $table_horz
        save_operation_log mirror_mfd_horz_orig $mirror_mfd_horz
        save_operation_log mirror_horz_orig $mirror_horz

        set npHorz  [get_alignTungsten_constant horz_scan_points]
        if {$npHorz > 0} {
            alignTungstenMoveTableHorzToBeam $dz

            if {abs($dz) > 0.008} {
                alignTungsten_redoHorz $dir $TS4Name
            }
        } else {
            log_warning skip horz adjust
        }

        save_operation_log peak_sample_z $h1
        save_operation_log new_sample_z $sample_z
        save_operation_log sample_z_diff $dz

        save_operation_log table_horz_new $table_horz
        save_operation_log table_horz_diff [expr $table_horz - $orig_table_horz]
        save_operation_log mirror_mfd_horz_new $mirror_mfd_horz
        save_operation_log mirror_mfd_horz_diff \
        [expr $mirror_mfd_horz - $orig_mfd_horz]

        save_operation_log mirror_horz_new $mirror_horz
        save_operation_log mirror_horz_diff [expr $mirror_horz - $mirror_horz_orig]

        alignTungstenLogSignals
    } errMsg] == 1} {
        log_severe Failed to position beam to z_datum point. \
        Restore energy offset.
        set energy_offset $orig_energy_offset
        set detail "Beam positioning to z_datum point: $errMsg"
        return -code error $detail
    }

    ## We may decide to move more into this block in the future.
    if {[catch alignTungstenMoveCrossToTungsten errMsg]} {
        log_severe Failed to move sample camera cross to tunsten. \
        Restore energy offset.
        set energy_offset $orig_energy_offset
        set detail "Profile camera positioning: $errMsg"
        return -code error $detail
    }

    ### we want use face to beam
    #move gonio_phi to [expr 360.0 - $gonio_omega]
    move gonio_phi to [expr $face_phi + 90]
    wait_for_devices gonio_phi

    #### let align collimator or caller to restore the motors
    #alignTungsten_restore
    #write_operation_log alignTungsten

    set timeEnd [clock seconds]
    set timeUsed [expr $timeEnd - $timeStart]
    set timeUsedText [secondToTimespan $timeUsed]

    alignTungstenLog total tungsten time: $timeUsedText
}
proc alignTungstenLogSignals { } {
    variable ::alignTungsten::logIonChamberKey
    variable ::alignTungsten::logIonChamberName
    variable ::alignTungsten::logEncoderKeyName
    if {[catch {
        eval read_ion_chambers 0.2 $logIonChamberName
        eval wait_for_devices $logIonChamberName
        set vList [eval get_ion_chamber_counts $logIonChamberName]
        foreach k $logIonChamberKey v $vList {
            save_operation_log $k $v
        }

        foreach n $logEncoderKeyName {
            get_encoder $n
        }
        foreach k $logEncoderKeyName {
            set v [wait_for_encoder $k]
            save_operation_log $k $v
        }

    } errMsg]} {
        log_error failed to log ion chambers: $errMsg
    }
}
proc alignTungstenMoveCrossToTungsten { } {
    variable ::alignTungsten::face_phi

    if {[catch centerSaveAndSetLights errMsg]} {
        log_warning lights control failed $errMsg
    }

    move gonio_phi to  [expr $face_phi + 90.0]
    wait_for_devices gonio_phi

    ### get beam center by getting tip 0 -180
    set h [start_waitable_operation getLoopTip 0]
    set hr [wait_for_operation_to_finish $h]
    set tipH0 [lindex $hr 1]
    set tipV0 [lindex $hr 2]

    move gonio_phi by 180
    wait_for_devices gonio_phi

    set h [start_waitable_operation getLoopTip 0]
    set hr [wait_for_operation_to_finish $h]
    set tipH180 [lindex $hr 1]
    set tipV180 [lindex $hr 2]

    set vCenter [expr ($tipV0 + $tipV180) / 2.0]

    set dd0 [expr $tipV180 - $vCenter]

    set max_vert [get_alignTungsten_constant max_vert_move]

    foreach {dummy ddMM0} [moveSample_relativeToMM 0 $dd0] break
    if {abs($ddMM0) > abs($max_vert)} {
        alignTungstenLog ERROR \
        centered tungsten tip diff $ddMM0 too much in 0-180 degree views

        log_severe centered tungsten tip diff $ddMM0 too much in 0-180 degree views
        return -code error CENTER_FAILED
    }

    ### perfect center at 0.5
    ##horz
    set tipH    [expr ($tipH0 + $tipH180) / 2.0]
    set tipDelta [get_alignTungsten_constant tungsten_delta]
    foreach {hRelative dummy} [moveSample_mmToRelative $tipDelta 0] break
    set hCenter [expr $tipH - $hRelative]

    alignTungstenLog tipH0=$tipH0 tipH180=$tipH180
    alignTungstenLog tipV0=$tipV0 tipV180=$tipV180
    alignTungstenLog vCenter=$vCenter
    alignTungstenLog tipH=$tipH tipDelta=$tipDelta mm, = $hRelative hCenter=$hCenter
    
    if {abs($vCenter - 0.5) > 0.02} {
        alignTungstenLog ERROR new veritcal beam center $vCenter too much off

        log_severe new veritcal beam center $vCenter too much off\
        video center (2% tolerance).  Please adjust sample camera.
        return -code error MANUAL_ADJUST_NEEDED
    }
    if {abs($hCenter - 0.5) > 0.02} {
        alignTungstenLog ERROR new horz beam center $hCenter too much off\

        log_severe new horz beam center $hCenter too much off\
        video center (2% tolerance).  Please adjust sample camera.
        return -code error MANUAL_ADJUST_NEEDED
    }
    
    set cur_sample_center_x [getSampleCameraConstant zoomMaxXAxis]
    set cur_sample_center_y [getSampleCameraConstant zoomMaxYAxis]
    set moved  [expr $cur_sample_center_y - $vCenter]
    set movedH [expr $cur_sample_center_x - $hCenter]

    if {abs($moved) > 0.1} {
        alignTungstenLog ERROR cross vert exceeds range

        log_severe beam center cross vert exceeds auto adjust range
        log_severe old_y=$cur_sample_center_y new_y $vCenter
        log_severe please confirm and manually adjust

        return -code error MANUAL_ADJUST_NEEDED
    }
    if {abs($movedH) > 0.1} {
        alignTungstenLog ERROR cross horz exceeds range

        log_severe beam center cross horz exceeds auto adjust range
        log_severe old_y=$cur_sample_center_x new_y $hCenter
        log_severe please confirm and manually adjust

        return -code error MANUAL_ADJUST_NEEDED
    }
    log_warning moving sample cross vert from $cur_sample_center_y to $vCenter
    log_warning moving sample cross horz from $cur_sample_center_x to $hCenter
    alignTungstenLog moving sample cross vert from $cur_sample_center_y to $vCenter
    alignTungstenLog moving sample cross horz from $cur_sample_center_x to $hCenter
    foreach {movedHMM movedMM} [moveSample_relativeToMM $movedH $moved] break
    alignTungstenLog vert moved $movedMM  horz moved $movedHMM mm

    ##DEBUG
    setSampleCameraConstant zoomMaxYAxis $vCenter
    setSampleCameraConstant zoomMaxXAxis $hCenter

    save_operation_log cross_vert_orig $cur_sample_center_y
    save_operation_log cross_vert_new  $vCenter
    save_operation_log cross_vert_diff_mm $movedMM
    save_operation_log cross_horz_orig $cur_sample_center_x
    save_operation_log cross_horz_new  $hCenter
    save_operation_log cross_horz_diff_mm $movedHMM
}
proc alignTungstenMovePhiAxisToBeam { dd } {
    variable ::alignTungsten::ONLY_MOVE_MFD

    variable table_vert
    variable focusing_mirror_2_mfd_vert
    variable energy
    # dd positive mean beam is lower
    ### 10 is from experiment

    set max_vert [get_alignTungsten_constant max_vert_move]
    if {abs($dd) > abs($max_vert)} {
        set    errMsg "Phi axis is off [expr 1000.0 * $dd] "
        append errMsg "more than allowed [expr int($max_vert * 1000)] microns."

        alignTungstenLog ERROR $errMsg

        log_error need confirm and manually adjust
        return -code error $errMsg
    }

    alignTungstenLog DEBUG MovePhiAxisToBeam $dd
    if {!$ONLY_MOVE_MFD} {
        alignTungstenLog DEBUG move table_vert by $dd
        alignTungstenLog DEBUG move mfd_vert by [expr -1 * $dd]
        alignTungstenLog DEBUG old table_vert=$table_vert
        alignTungstenLog DEBUG old mfd_vert=$focusing_mirror_2_mfd_vert
    } else {
        set scaled_dd [expr 0.91 * $dd]
        alignTungstenLog DEBUG move mfd_vert by [expr -1 * $scaled_dd]
        alignTungstenLog DEBUG old mfd_vert=$focusing_mirror_2_mfd_vert
    }

    if {!$ONLY_MOVE_MFD} {
        move table_vert by $dd
        move focusing_mirror_2_mfd_vert by [expr -1 * $dd]
        wait_for_devices table_vert focusing_mirror_2_mfd_vert
    } else {
        move focusing_mirror_2_mfd_vert by [expr -1 * $scaled_dd]
        wait_for_devices focusing_mirror_2_mfd_vert
    }

    alignTungstenLog DEBUG resetting energy at $energy
    set energy $energy
}
proc get_alignTungsten_constant { name } {
    variable alignTungsten_constant

    #### Collimator and Tungsten have the same name list
    set index [alignCollimatorConstantNameToIndex $name]
    return [lindex $alignTungsten_constant $index]
}
proc alignTungsten_setup { } {
    global gMotorEnergy
    variable ::alignTungsten::nList
    variable ::alignTungsten::mList
    variable ::alignTungsten::orig_energy
    variable ::alignTungsten::orig_attenuation
    variable ::alignTungsten::restore_orig_cmd

    ### we just move all of them
    set cmdRestore [list]
    set cmdSerialRestore [list]

    ### build-in energy and attenuation
    set movingList ""
    variable $gMotorEnergy
    variable attenuation
    set currentE [set $gMotorEnergy]
    set orig_energy      $currentE
    set orig_attenuation $attenuation

    set eThreshold [get_alignTungsten_constant energy]
    if {$currentE < $eThreshold} {
        ### it will not jump harmonic
        ### checking is done in energy_bl122.tcl
        move $gMotorEnergy to $eThreshold
        lappend movingList $gMotorEnergy
    } else {
        move $gMotorEnergy by 0
        lappend movingList $gMotorEnergy
    }

    ### motors can be parallel moved
    foreach motor $mList tag_name $nList {
        variable $motor
        set setting [get_alignTungsten_constant $tag_name]
        set currentP [set $motor]

        lappend cmdRestore [list $motor $currentP]
        move $motor to $setting
        lappend movingList $motor
    }
    if {$movingList != ""} {
        eval wait_for_devices $movingList
    }
    ### build-in attenuation
    set setting [get_alignTungsten_constant attenuation]
    move attenuation to $setting
    wait_for_devices attenuation

    set restore_orig_cmd $cmdRestore

    save_operation_log energy_aligned_at [set $gMotorEnergy]
}
proc alignTungsten_restore { } {
    variable ::alignTungsten::orig_energy
    variable ::alignTungsten::orig_attenuation
    variable ::alignTungsten::restore_orig_cmd

    ### parallel first
    if {$restore_orig_cmd != ""} {
        set motorList ""
        foreach cmd $restore_orig_cmd {
            set motor [lindex $cmd 0]
            set pos   [lindex $cmd 1]
            move $motor to $pos
            lappend motorList $motor
            alignTungstenLog restore $motor to $pos
        }
        if {$motorList != ""} {
            eval wait_for_devices $motorList
        }
        set restore_orig_cmd ""
    }

    if {$orig_energy != ""} {
        move attenuation to 0
        wait_for_devices attenuation

        move energy to $orig_energy
        wait_for_devices energy
        alignTungstenLog restore energy to $orig_energy
        set orig_energy ""
    }
    if {$orig_attenuation != ""} {
        move attenuation to $orig_attenuation
        wait_for_devices attenuation
        alignTungstenLog restore attenuation to $orig_attenuation
        set orig_attenuation ""
    }
}

proc alignTungstenLog { args } {
    catch {
        send_operation_update "$args"

        set logFileName alignTungsten.log
        set timeStamp [clock format [clock seconds] -format "%D-%T"]
        if {[catch {open $logFileName a} fh]} {
            puts "failed to open log file: $logFileName"
        } else {
            puts $fh "$timeStamp $args"
            close $fh
        }
    }
}
proc alignTungsten_scan { fileName vert_or_horz } {
    variable ::alignTungsten::face_phi
    variable gonio_phi

    set savePhi4Horz $gonio_phi
    set restorePhi 0

    switch -exact -- $vert_or_horz {
        horz {
            set motorName sample_z
            set tag horz

            #### using face to beam to reduce noise from other metal
            set restorePhi 1
            move gonio_phi to [expr $face_phi + 90]
            wait_for_devices gonio_phi
        }
        vert {
            set motorName sample_x
            set tag vert
        }
        vert90 {
            set motorName sample_y
            set tag vert
        }
    }

    set width     [get_alignTungsten_constant ${tag}_scan_width]
    set numPoint  [get_alignTungsten_constant ${tag}_scan_points]
    set signal    [get_alignTungsten_constant signal]
    set time      [get_alignTungsten_constant ${tag}_scan_time]
    set timeWait  [get_alignTungsten_constant ${tag}_scan_wait]
    set minSignal [get_alignTungsten_constant min_signal]
    if {![isMotor $motorName]} {
        log_error $motorName is not motor
        return -code error "wrong_align_collimator_config"
    }

    if {$numPoint < 0} {
        set numPoint [expr -1 * $numPoint]
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

    ##TODO: check backlash
    if {[swapIfBacklash $motorName startP endP]} {
        puts "alignTungsten scan  $vert_or_horz swapped start and end because backlash"
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
            set failed_reason "lost beam"
            set result failed
            if {$i < $MAX_RETRY} {
                log_warning retrying
            }
        }
    }

    move $motorName to $save_POS
    wait_for_devices $motorName

    if {$restorePhi} {
        move gonio_phi to $savePhi4Horz
        wait_for_devices gonio_phi
    }

    if {$result == "failed"} {
        alignTungstenLog ERROR $failed_reason
        return -code error "failed_after_max_retry: $failed_reason"
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
proc alignTungstenMoveTableHorzToBeam { dd } {
    variable ::alignTungsten::HORZ_MOVE_MIRROR
    variable ::alignTungsten::ONLY_MOVE_MFD
    variable table_horz
    variable mirror_mfd_horz
    variable mirror_horz
    variable energy

    puts "moveTableHorzToBeam $dd"

    set max_horz [get_alignTungsten_constant max_horz_move]
    if {abs($dd) > abs($max_horz)} {
        alignTungstenLog ERROR beam horz is off range.

        log_severe beam horz is off $dd more than [expr int($max_horz * 1000)] microns.
        log_error need confirm and manually adjust
        return -code error 
    }

    alignTungstenLog DEBUG MoveTableHorzToBeam $dd

    if {$HORZ_MOVE_MIRROR} {
        alignTungstenLog HORZ_MOVE_MIRROR
        alignTungstenLog old mirror_horz=$mirror_horz

        set mirror_delta [expr $dd * -13]
        alignTungstenLog mirror_delta=$mirror_delta
        move mirror_horz_combo by $mirror_delta
        wait_for_devices mirror_horz_combo
        alignTungstenLog new mirror_horz=$mirror_horz 
        save_operation_log mirror_horz_new $mirror_horz
        save_operation_log mirror_horz_diff $mirror_delta

        alignTungstenLog DEBUG resetting energy at $energy
        set energy $energy
        return
    }

    if {!$ONLY_MOVE_MFD} {
        alignTungstenLog DEBUG move table_horz by $dd
        alignTungstenLog DEBUG move mfd_horz by [expr -1.0 * $dd]
        alignTungstenLog DEBUG old table_horz=$table_horz
        alignTungstenLog DEBUG old mfd_horz=$mirror_mfd_horz
    } else {
        ### 2.1 is from experiment (scan).
        set scaled_dd [expr 2.1 * $dd]
        alignTungstenLog DEBUG move mfd_horz by [expr -1.0 * $scaled_dd]
        alignTungstenLog DEBUG old mfd_horz=$mirror_mfd_horz
    }

    if {!$ONLY_MOVE_MFD} {
        move table_horz by $dd
        move mirror_mfd_horz by [expr -1.0 * $dd]
        wait_for_devices table_horz mirror_mfd_horz
    } else {
        move mirror_mfd_horz by [expr -1.0 * $scaled_dd]
        wait_for_devices mirror_mfd_horz
    }

    alignTungstenLog DEBUG resetting energy at $energy
    set energy $energy
}
proc alignTungsten_redoHorz { dir TS4Name } {
    variable sample_z

    set name ${TS4Name}horz_final_redo.scan
    set fileName [file join $dir $name]
    set horz1Result [alignTungsten_scan $fileName horz]
    alignTungstenLog horz1 $horz1Result
    set h1 [lindex $horz1Result 0]

    move sample_z to $h1
    wait_for_devices sample_z
    get_encoder sample_z_encoder
    set he1 [wait_for_encoder sample_z_encoder]

    set calibrated_sample_z [get_alignTungsten_constant beam_sample_z]
    set h [start_waitable_operation moveEncoders \
    0 [list [list sample_z_encoder $calibrated_sample_z]]]
    wait_for_operation_to_finish $h

    alignTungstenLog final redo horz scan sample_z = $h1 sample_z_encoder = $he1
    set dz [expr $calibrated_sample_z - $he1]

    save_operation_log peak_sample_z $h1
    save_operation_log new_sample_z  $sample_z
    save_operation_log sample_z_diff $dz

    alignTungstenLog moving beam from sample_z_encoder=$he1 to $calibrated_sample_z

    log_warning redo dz=$dz
    
    alignTungstenMoveTableHorzToBeam $dz
}
