proc videoVisexSnapshot_initialize { } {
    variable visex_msg
    variable visex_snapshot_nocheck
    variable camera_view_phi

    set visex_msg ""

    set visex_snapshot_nocheck 0
    set camera_view_phi(inline) [::config getStr camera_view_phi.inline]
    set camera_view_phi(sample) [::config getStr camera_view_phi.sample]
    set camera_view_phi(visex)  [::config getStr camera_view_phi.visex]

    set motorList [list \
    sample_x sample_y sample_z \
    gonio_phi gonio_omega \
    camera_zoom inline_camera_zoom \
    ]

    foreach motor $motorList {
        registerEventListener $motor ::nScripts::videoVisexSnapshot_callback
    }
}
proc videoVisexSnapshot_callback { } {
    variable visex_snapshot_nocheck
    variable visex_snapshot_save

    if {$visex_snapshot_nocheck} {
        puts "visex callback nocheck"
        return
    }

    set newCondition [videoVisexSnapshot_getCondition ""]

    puts "visex callback    save=$visex_snapshot_save"
    puts "visex callback current=$newCondition"
    set ll [llength $visex_snapshot_save]

    ### check sample_xyz, phi and omega
    set newMatch [lindex $newCondition 0]
    for {set i 2} {$i < 7} {incr i} {
        set s [lindex $visex_snapshot_save $i]
        set c [lindex $newCondition        $i]
        if {abs($s - $c) > 0.001} {
            set newMatch 0
            break
        }
    }
    set oldMatch [lindex $visex_snapshot_save 0]
    if {$oldMatch != $newMatch} {
        set visex_snapshot_save [lreplace $visex_snapshot_save 0 0 $newMatch]
    }
}
#### from_which_video_view_:
##### sample, inline, visex
##### to_which_video_view_afterwards:
##### sample, inline, visex(unlikely)
proc videoVisexSnapshot_start { from_ } {
    variable visex_msg
    variable visex_snapshot_orig
    variable camera_view_phi
    variable gonio_phi
    variable visexParameters
    variable visex_snapshot_save
    #visex_snapshot_save is used for BluIce to decide whether to show the image.
    #For now (02/06/2012), any change (sample_xyz, phi, zoom) will trigger
    #hiding the image.
    variable visex_snapshot_nocheck
    set visex_snapshot_nocheck 1

    set need_restore_phi 0
    set save_phi $gonio_phi

    #puts "phi sample=$camera_view_phi(sample) visex=$camera_view_phi(visex)"
    #puts "from: $from_"

    if {$from_ != "" && $from_ != "visex"} {
        ### ratate the video view to face the visex camera.
        set d_phi [expr $camera_view_phi(visex) - $camera_view_phi($from_)]
        puts "d_phi=$d_phi"
        move gonio_phi by $d_phi
        wait_for_devices gonio_phi
        set need_restore_phi 1
    }

    set visex_msg "lighting"
    ### turn off all lights
    if {[lightsControl_start setup visex 1]} {
        wait_for_time 4000
        log_warning wait for lights to settle down
    }

    ### take snapshot
    set exposureTime [lindex $visexParameters 0]
    set h [start_waitable_operation visexSnapshot $exposureTime 2]
    wait_for_operation_to_finish $h
    set visex_snapshot_orig [videoVisexSnapshot_getOrig $from_]
    #log_warning visex snapshot at phi=$gonio_phi

    ### restore phi
    if {$need_restore_phi} {
        move gonio_phi to $save_phi
        wait_for_devices gonio_phi
    }

    set camera [lindex $visex_snapshot_orig 8]
    switch -exact $camera {
        sample {
            set visex_msg "adjust sample zoom"
            videoVisexSnapshot_adjustSampleZoom
        }
        inline {
            set visex_msg "adjust inline zoom"
            videoVisexSnapshot_adjustInlineZoom
        }
    }
    
    if {$need_restore_phi} {
        set visex_snapshot_save [videoVisexSnapshot_getCondition $from_]
    } else {
        ## save will be called by caller
    }

    lightsControl_start restore
}
proc videoVisexSnapshot_cleanup { } {
    variable visex_snapshot_nocheck
    variable visex_msg

    set visex_snapshot_nocheck 0
    set visex_msg ""
}
proc videoVisexSnapshot_adjustSampleZoom { } {
    #visexZoom_sampleZoom current
    visexZoom_sampleZoom high
    #visexZoom_sampleZoom med
    #visexZoom_sampleZoom low

}
proc videoVisexSnapshot_adjustInlineZoom { } {
    #visexZoom_inlineZoom current
    visexZoom_inlineZoom high
    #visexZoom_inlineZoom med
    #visexZoom_inlineZoom low
}
proc videoVisexSnapshot_getCondition { from_ } {
    variable visex_snapshot_orig

    ### needed for visex view to get old percent
    variable visex_snapshot_save

    if {$from_ == ""} {
        set from_ [lindex $visex_snapshot_orig 8]
    }
    set viewWidth  [getVisexCameraConstant view_width_mm]
    switch -exact -- $from_ {
        sample {
            getSampleViewSize svWidth svHeight
            set showPercent [expr double($svWidth) / $viewWidth]
        }
        inline {
            getInlineViewSize svWidth svHeight
            set showPercent [expr double($svWidth) / $viewWidth]
        }
        visex -
        default {
            ### no change
            set showPercent [lindex $visex_snapshot_save 0]
        }
    }
    set newMatch [format "%.3f" $showPercent]

    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_omega
    variable gonio_phi

    variable camera_zoom
    variable inline_camera_zoom

    set newContents [list $newMatch $from_ $sample_x $sample_y $sample_z $gonio_phi]
    if {[isMotor gonio_omega]} {
        lappend newContents $gonio_omega
    } else {
        lappend newContents 0
    }
    lappend newContents $camera_zoom
    if {[isMotor inline_camera_zoom]} {
        lappend newContents $inline_camera_zoom
    } else {
        lappend newContents 0
    }
    return $newContents
}
proc videoVisexSnapshot_getOrig { from_ } {
    variable visex_snapshot_orig
    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_omega
    variable gonio_phi

    variable camera_view_phi

    if {$from_ == ""} {
        set from_ [lindex $visex_snapshot_orig 8]
    }

    ### this angle is the angle when this view face beam
    set angle [expr $gonio_omega + $gonio_phi - $camera_view_phi(visex)]
    set viewHeight [getVisexCameraConstant view_height_mm]
    set viewWidth  [getVisexCameraConstant view_width_mm]

    return [list $sample_x $sample_y $sample_z $angle $viewHeight $viewWidth 1 1 $from_]
}
