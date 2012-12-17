proc userAlignBeam_initialize { } {
    namespace eval ::userAlignBeam {
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
        collimator_1_horz_orig \
        collimator_1_horz_new \
        collimator_1_horz_diff \
        collimator_1_vert_orig \
        collimator_1_vert_new \
        collimator_1_vert_diff \
        radius_of_confusion \
        inline_focus_orig \
        inline_focus_new \
        inline_focus_diff \
        inline_horz_orig \
        inline_horz_new \
        inline_horz_diff \
        inline_vert_orig \
        inline_vert_new \
        inline_vert_diff \
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
        collimator_horz_encoder \
        collimator_vert_encoder \
        table_horz_orig \
        table_horz_new \
        table_horz_diff \
        mirror_mfd_horz_orig \
        mirror_mfd_horz_new \
        mirror_mfd_horz_diff \
        ]

        ### operations allowed or included
        ### we may use these in the future
        set logOperation [list \
        userAlignBeam \
        matchup \
        alignTungsten \
        alignCollimator \
        ]

        set logStartTime 0
    }
}

proc userAlignBeam_getNeedToDo { {forced 0} } {
    variable user_align_beam_status
    ### field 0: need align beam with tungsten
    ### field 1: need align beam with  collimator
    ### field 2: time span for beam align valid
    ### field 3: time span for collimator align valid
    ### field 4: timestamp of last beam alignment
    ### field 5: timestamp of last collimator aligntment
    ### field 6: after_ID for timer service callback
    ### field 7: after_ID for timer service callback for collimator

    set willDo1 0
    set willDo2 0
    foreach {enable1 enable2 span1 span2 tExpire1 tExpire2} \
    $user_align_beam_status break

    if {$forced} {
        return [list $enable1 $enable2]
    }

    set tNow     [clock seconds]
    if {$enable1 && $tNow >= $tExpire1} {
        set willDo1 1
    }
    if {$enable2 && $tNow >= $tExpire2} {
        set willDo2 1
    }

    ### not need, the program will do that
    if {$willDo2} {
        set willDo1 1
    }

    ### new logical: do both as long as both enabled
    if {($willDo1 || $willDo2) && $enable1 && $enable2} {
        set willDo1 1
        set willDo2 1
    }

    return [list $willDo1 $willDo2]   
}
proc userAlignBeam_start { args } {
    variable robot_status
    set sample_on_gonio [lindex $robot_status 15]
    if {$sample_on_gonio != "" && $sample_on_gonio != "b 0 T"} {
        log_error must dismount sample first.
        return -code error SAMPLE_STILL_MOUNTED
    }

    set forced 0
    if {[lindex $args 0] == "forced"} {
        set forced 1
    }

    foreach {willDo1 willDo2} [userAlignBeam_getNeedToDo $forced] break

    puts "userAlignBeam: do1: $willDo1 do2: $willDo2"

    if {!$willDo1 && !$willDo2} {
        return NO_NEED
    }

    if {![beamGood]} {
        log_warning Skip optimizing, no beam
        return SKIP
    }

    set timeStart [clock seconds]

    clear_operation_log userAlignBeam

    ### STEP 1: mount alignment pin
    if {$sample_on_gonio == ""} {
        ISampleMountingDevice_start mountBeamLineTool
    }

    ### save current loghts to restore
    lightsControl_start save

    if {[catch {
        matchup_start adjust_sample
        alignTungsten_start
        userAlignBeam_markDone 1       

        if {$willDo2} {
            alignCollimator_start
            matchup_start auto_focus
            matchup_start adjust_inline
            userAlignBeam_markDone 2
        }
        set log_file [write_operation_log]
        set webLog [::config getStr "AlignFrontEnd.webLog"]
        if {$log_file != "" && $webLog != ""} {
            file copy -force $log_file $webLog
        }
    } errMsg] == 1} {
        if {[string first aborted $errMsg] >= 0} {
            log_severe Optimizing Beam aborted
            return -code error $errMsg
        }
        send_operation_update "ERROR Optmize Beam faile: $errMsg"
        log_severe Optimize Beam failed: $errMsg
        userAlignBeam_markDone 1       
        userAlignBeam_markDone 2
    }

    #centerRestoreLights
    lightsControl_start restore
    alignTungsten_restore


    if {$sample_on_gonio == ""} {
        ISampleMountingDevice_start dismountBeamLineTool
    }
    ## inline light moved out

    set timeEnd [clock seconds]
    set timeUsed [expr $timeEnd - $timeStart]
    set timeUsedText [secondToTimespan $timeUsed]

    send_operation_update total userAlignBeam: $timeUsedText
}
proc userAlignBeam_markDone { index } {
    variable user_align_beam_status

    foreach {enable1 enable2 span1 span2 tExpire1 tExpire2} \
    $user_align_beam_status break

    switch -exact -- $index {
        1 {
            set span $span1
        }
        2 {
            set span $span2
        }
        default {
            return
        }
    }
    set tNow    [clock seconds]
    set tExpire [expr $tNow + $span]

    switch -exact -- $index {
        1 {
            set user_align_beam_status \
            [lreplace $user_align_beam_status 4 4 $tExpire]
        }
        2 {
            set user_align_beam_status \
            [lreplace $user_align_beam_status 4 5 $tExpire $tExpire]
        }
    }
}
