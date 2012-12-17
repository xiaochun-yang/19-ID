#### scan3DSetup_info:
#field 0:  match_index: 0 phi not matchi, 1: phi at view 1, 2: phi at view 2
#field 1:  orig: The intersected point of view1 nd view2. Updated by define scan area on videon and on snapshot.
#field 2:  snapshot0 info: filename and orig of the snapshot.
#field 3:  snapshot1 info: filename and orig of the snapshot.
#field 4:  use collimator or not (only changed by staff manually.
#field 5 ,6 ,7:   3D scan area, widh, height and depth. (units: micron)
#field 8, 9, 10:  Number of points for widh, height and depth.
#field 11:   view_index: used in sequence wizard setup style.
#field 12:   scan area on view0 defined (width, height).
#field 13:   scan area on view1 defined (width, depth).
#field 14:   inline camera or sample camera.
#field 15, 16: area offset in video of area 0.  They are updated automatically by "Match" following sample_xyz and phi + ometa
#field 17, 18: area offset in video of area 1.
#field 19, 20 : area offset in snapshot0 (old units: u, new units: relative)
#field 21, 22 : area offset in snapshot0

#field 5, 6, 7 can be negative.  The sign means orientation

#field 15-22 are just for convinence.  BluIce can calculate these values by themselve too.
# Their units are all microns.
# Offsets for snapshots can be fractions because their zoom never change.
# Just want to be consistent with other offiset, so they are microns.:w

###########################################
### scan2DXXXXSetup
###
### X, Y, Z, A (orientation), ROW_HEIGHT, COLUMN_WIDTH, NUM_ROW, NUM_COLUMN
### orientation normally is gonio_phi+gonio_omega (+90 if sample camera).
###
### To be consistent with above structure, the ORIG is defined as:
### X, Y, Z, A (orientation), image_HEIGHT, image_WIDTH, 1, 1.

##########################################
### In video view, orig, A is defined as:
### sample view:
### dx=dV * cos(A)
### dy=dV * sin(A)
### dz= +-dH
### SSRL beamline setup; 
### (phi+ omega)= 0:   sample_x point straight down.
### (phi+ omega)=90:   sample_x point down stream.
### Sample camera: DOWN is down stream   (vector= 90)
### Inline camera: DOWN is vertical up (vector= 0)
### According to this, the sample camera A=(phi+omega - 90)
###                        inline camera A=(phi+omega - 0)
###
### For views, raw data should be the "phi+omega" and the video vector
### (90 for sample, 0 for indline), but the difference is needed for now.
### So we recorded the "phi+omega - video vector".
###
### To fully understand, think as following,
### a view you defined on Sample Camera:
###  when (phi+omega) at an ANGLE, that plane is parallel to the camera ccd.
###  phi+omega               the view plane
###  ANGLE                   90
###  ANGLE+ANY               90 + ANY
###
###  =================================
#### to move the view plane ang angle (90 for sample camera,
###  0 for inline camera and beam), 
#### you need to move phi+omega to (ANGLE - 90) + that angle.



###
### inline camera has left-right flipped because a mirror in optical path.
### so its dz = -dH,
### Because A is vector, so the image_HEIGHT should be always positive
### The imge_WIDTH can be negative to indicate samlpe_z direction 
### on the video image to the RIGHT.

### We define image_WIDTH:
###  positive:  sample_z is along the image left to RIGHT.
###  negative:  sample_z is along the image right to LEFT.
###
### This is the same as in moveSample, inlineMoveSample.
###
### IMPORTANT:
### Scanning Grid from left to RIGHT, you are moving sample
### from right to LEFT.  The grid is sticky with the sample,
### not the video image.
###
### The same goes to vertical.
###########################################################
### To move a video view to sample camera:
### sample camera needs (omega+phi) = A + 90
### inline camera needs (omega+phi) = A

proc scan3DSetup_initialize { } {
    namespace eval ::scan3DSetup {
        set cnt_snapshot0 0
        set cnt_snapshot1 0

        set dir [::config getStr "rastering3DScan.directory"]
        set bid [::config getConfigRootName]

        set image0 [file join $dir ${bid}_0.jpg]
        set image1 [file join $dir ${bid}_1.jpg]

        set handle0 ""
        set handle1 ""

        set info0 [list $image0 {0 0 0 0 0 0}]
        set info1 [list $image1 {0 0 0 0 0 0}]
    }

    ### NOT used anymore.  This is for update raster on live video
    #registerEventListener sample_x    ::nScripts::scan3DSetupMatch
    #registerEventListener sample_y    ::nScripts::scan3DSetupMatch
    #registerEventListener sample_z    ::nScripts::scan3DSetupMatch
    #registerEventListener gonio_phi   ::nScripts::scan3DSetupMatch
    #registerEventListener gonio_omega ::nScripts::scan3DSetupMatch
}
proc scan3DSetup_increaseSnapshotCounter { index } {
    variable ::scan3DSetup::cnt_snapshot0
    variable ::scan3DSetup::cnt_snapshot1
    variable ::scan3DSetup::image0
    variable ::scan3DSetup::image1
    variable ::scan3DSetup::dir
    variable ::scan3DSetup::bid

    set extra [getScrabbleForFilename]
        
    switch -exact -- $index {
        0 {
            set image0 [file join $dir ${bid}_0_${cnt_snapshot0}_${extra}.jpg]
            incr cnt_snapshot0
        }
        1 {
            set image1 [file join $dir ${bid}_1_${cnt_snapshot1}_${extra}.jpg]
            incr cnt_snapshot1
        }
    }
}
proc scan3DSetup_removeFiles { index } {
    variable ::scan3DSetup::dir
    variable ::scan3DSetup::bid

    switch -exact -- $index {
        0 {
            set pat ${bid}_0*.jpg
        }
        1 {
            set pat ${bid}_1*.jpg
        }
        default {
            set pat ${bid}*
        }
    }
    set l [glob -directory $dir -nocomplain $pat]
    if {$l != ""} {
        eval file delete -force $l
    }
}

### called automatically by sustem at the end of operations
proc scan3DSetup_cleanup { } {
    variable ::scan3DSetup::handle0
    variable ::scan3DSetup::handle1

    if {$handle0 != ""} {
        close $handle0
        set handle0 ""
    }
    if {$handle1 != ""} {
        close $handle1
        set handle1 ""
    }
}
proc scan3DSetup_start { cmd args } {
    switch -exact -- $cmd {
        clear {
            scan3DSetupClear
        }
        goto_position_0 {
            scan3DSetup_goBackToPosition0
        }
        goto_position_1 {
            scan3DSetup_goToPosition1
        }
        define_scan_area {
            eval scan3DSetup_setArea $args
        }
        define_scan_area_on_snapshot {
            eval scan3DSetup_setSnapshotArea $args
        }
        move_scan_area_on_snapshot {
            eval scan3DSetup_moveSnapshotArea $args
        }
        resize_scan_area_on_snapshot {
            eval scan3DSetup_changeSnapshotAreaSize $args
        }
        create_scan_area {
            eval scan3DSetup_createArea $args
        }
        remove_scan_area {
            eval scan3DSetup_removeArea $args
        }
        take_snapshot {
            eval scan3DSetup_takeSnapshot $args
        }
        set {
            eval scan3DSetup_setField $args
        }
        auto_set {
            scan3DSetup_autoFillField
        }
        move_to_snapshot {
            eval scan3DSetup_moveToSnapshot $args
        }
        start {
            scan3DSetupStartTheScan
        }
        switch_camera {
            eval scan3DSetup_switchCamera $args
        }
        default {
            log_warning not supported cmd: $cmd
        }
    }
}
proc scan3DSetupClearInternal { infoRef } {
    upvar $infoRef info

    set usingCollimator [lindex $info 4]
    set inline          [lindex $info 14]
    if {$inline != "1"} {
        set inline 0
    }
    ### so that sample_xyz never match
    set info [scan3DSetupRangeCheck \
    [list 0 {-999 -999 -999 -999 0 0} {{} {-999 -999 -999 -999 0 0}} {{} {-999 -999 -999 -999 0 0}} $usingCollimator 50 50 50 10 10 10 0 0 0 $inline 0 0 0 0 0 0 0 0] 1]
}
proc scan3DSetupSwitchCameraInternal { inline infoRef } {
    upvar $infoRef info

    if {$inline && ![isString inline_sample_camera_constant]} {
        log_error inline camera not available on this beamline.
        return -code error NOT_AVAILABLE
    }

    ### field 4 is collimator
    set info [lreplace $info  4  4 $inline]   
    set info [lreplace $info 14 14 $inline]   
    scan3DSetupClearInternal info
}
proc scan3DSetup_takeFirstSnapshotInternal { infoRef } {
    upvar $infoRef info

    variable ::scan3DSetup::image0
    variable ::scan3DSetup::handle0
    variable ::scan3DSetup::info0

    scan3DSetup_increaseSnapshotCounter 0

    set inline [lindex $info 14]
    if {$inline == "1"} {
        set contents0 [UtilTakeInlineVideoSnapshot]
    } else {
        set contents0 [UtilTakeVideoSnapshot]
    }

    if {![catch {open $image0 w} handle0]} {
        fconfigure $handle0 -translation binary
        puts -nonewline $handle0 $contents0
        close $handle0
        set handle0 ""
        file attributes $image0 -permissions ugo+rwx
    } else {
        log_error failed to save first snapshot: $handle0
        return -code error $handle0
    }

    set orig [scan3DSetup_getOrigFromCurrentPosition $info]
    set info0 [list $image0 $orig]

    set info [lreplace $info 2 2 $info0]
}
proc scan3DSetup_takeSecondSnapshotInternal { infoRef } {
    upvar $infoRef info

    variable ::scan3DSetup::image1
    variable ::scan3DSetup::handle1
    variable ::scan3DSetup::info1

    scan3DSetup_increaseSnapshotCounter 1

    set inline [lindex $info 14]
    if {$inline == "1"} {
        set contents1 [UtilTakeInlineVideoSnapshot]
    } else {
        set contents1 [UtilTakeVideoSnapshot]
    }

    if {![catch {open $image1 w} handle1]} {
        fconfigure $handle1 -translation binary
        puts -nonewline $handle1 $contents1
        close $handle1
        set handle1 ""
        file attributes $image1 -permissions ugo+rwx
    } else {
        log_error failed to save second snapshot: $handle1
        return -code error $handle1
    }
    set orig [scan3DSetup_getOrigFromCurrentPosition $info]
    set info1 [list $image1 $orig]
    set info [lreplace $info 3 3 $info1]
}

proc scan3DSetupClear { } {
    variable scan3DSetup_info
    variable scan3DHistory

    set copy $scan3DSetup_info

    scan3DSetupClearInternal copy

    set scan3DSetup_info $copy
    scan3DSetup_removeFiles 3

    #### create new file
    ### rule: new file for new snapshots
    MRastering_createScan2DSetups 1
    default_rastering_user_setup

    set scan3DHistory ""
}

proc scan3DSetup_switchCamera { inline } {
    variable scan3DSetup_info
    set copy $scan3DSetup_info

    scan3DSetupSwitchCameraInternal $inline copy

    set scan3DSetup_info $copy

    ### we want to save those files for history reload
    #scan3DSetup_removeFiles 3
}
proc scan3DSetup_goBackToPosition0 { } {
    variable scan3DSetup_info

    set newContents [lreplace $scan3DSetup_info 11 11 0]
    #set newContents [lreplace $newContents 13 13 0]
    #set newContents [lreplace $newContents 3 3 {}]
    #scan3DSetup_removeFiles 1

    set scan3DSetup_info $newContents
    MRastering_createScan2DSetups

    scan3DSetup_moveToSnapshot 0
}
proc scan3DSetup_goToPosition1 { } {
    variable scan3DSetup_info
    set scan3DSetup_info [lreplace $scan3DSetup_info 11 11 1]

    scan3DSetup_moveToSnapshot 1
}
proc scan3DSetupStartTheScan { } {
    variable ::scan3DSetup::bid
    variable scan3DSetup_info
    variable center_crystal_msg

    foreach {area0Defined area1Defined} [lrange $scan3DSetup_info 12 13] break
    if {!$area0Defined || !$area1Defined} {
        log_error rastering areas not defined yet
        return -code error area_not_defined
    }

    foreach {w h d nw nh nd} [lrange $scan3DSetup_info 5 10] break
    if {$w == 0 || $h == 0 || $d == 0 \
    || $nw < 1  || $nh < 1 || $nd < 1} {
        log_error rastering areas wrong 
        return -code error area_not_defined
    }

    set user [get_operation_user]
    set SID  PRIVATE[get_operation_SID]

    set crystalID [scan3DSetup_getCurrentCrystalID]
    set DateID    [timeStampForFileName]

    set dir /data/$user/raster/$crystalID/$DateID

    set fileRoot ${bid}

    set center_crystal_msg "starting the raster"
    wait_for_time 100
    #centerCrystal_start $user $SID $dir $fileRoot rastering
    set h [start_waitable_operation manualRastering $user $SID $dir $fileRoot]
    if {[catch {wait_for_operation_to_finish $h} errMsg]} {
        if {[string first abort $errMsg]} {
            MRastering_setRasterStateFailed aborted
        } else {
            MRastering_setRasterStateFailed failed
        }
        ### rethrow
        return -code error $errMsg
    }
}
proc scan3DSetup_getOrigFromCurrentPosition { info \
{dx 0 } \
{dy 0 } \
{dz 0 } \
} {
    set inline [lindex $info 14]

    return [scan3DSetup_getOrigFromVideoView $inline $dx $dy $dz]
}

proc scan3DSetup_getOrigFromVideoView { \
isInline \
{dx 0 } \
{dy 0 } \
{dz 0 } \
} {
    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_omega
    variable gonio_phi

    set angle [expr $gonio_omega + $gonio_phi]
    if {$isInline == "1"} {
        foreach {imgWmm imgHmm} [inlineMoveSampleRelativeToMM 1 1] break
        ### imgWmm normally is negative in inline view
    } else {
        foreach {imgWmm imgHmm} [moveSample_relativeToMM 1 1] break
        ### sample camera point upward
        set angle [expr $angle - 90.0]
    }

    set x [expr $sample_x + $dx]
    set y [expr $sample_y + $dy]
    set z [expr $sample_z + $dz]

    return [list $x $y $z $angle $imgHmm $imgWmm 1 1]
}

proc scan3DSetup_takeFirstSnapshot { } {
    variable scan3DSetup_info

    set copy $scan3DSetup_info
    scan3DSetup_takeFirstSnapshotInternal scan3DSetup_info
    set scan3DSetup_info $copy
}

proc scan3DSetup_takeSecondSnapshot { } {
    variable scan3DSetup_info

    set copy $scan3DSetup_info
    scan3DSetup_takeSecondSnapshotInternal scan3DSetup_info
    set scan3DSetup_info $copy
}
proc scan3DSetup_takeSnapshot { args } {
    variable ::scan3DSetup::info0
    variable ::scan3DSetup::info1
    variable scan3DSetup_info
    variable center_crystal_msg

    set new_inline [lindex $args 0]
    if {$new_inline == "0" || $new_inline == "1"} {
        ### we want to clear the display first
        scan3DSetup_switchCamera $new_inline
    }

    set center_crystal_msg "taking first snapshot"
    set infoContents $scan3DSetup_info
    set orig [scan3DSetup_getOrigFromCurrentPosition $infoContents]
    scan3DSetup_takeFirstSnapshotInternal infoContents

    set center_crystal_msg "taking second snapshot"
    move gonio_phi by 90
    wait_for_devices gonio_phi
    scan3DSetup_takeSecondSnapshotInternal infoContents

    set center_crystal_msg "restore phi"
    move gonio_phi by -90
    wait_for_devices gonio_phi

    set usingCollimator [lindex $infoContents 4]
    set inline [lindex $infoContents 14]
    if {$inline != "1"} {
        set inline 0
    }

    set newContents \
    [list 1 $orig $info0 $info1 $usingCollimator 50 50 50 100 100 100 2 1 1 \
    $inline 0 0 0 0 0 0 0 0]

    set newContents [MRasteringDefaultAreasForScan3DSetup $newContents]
    foreach {w h d} [lrange $newContents 5 7] break

    foreach {w h d} [scan3DSetup_decideSignForArea $newContents $w $h $d] break
    set newContents [lreplace $newContents 5 7 $w $h $d]
    ### update the info
    ## no need to go through range check again
    set scan3DSetup_info $newContents
    #### create new file
    MRastering_createScan2DSetups 1
}
proc scan3DSetupMatch { } {
    variable scan3DSetup_info

    set newContents $scan3DSetup_info

    foreach {old_match orig} $scan3DSetup_info break
    set curOrig [scan3DSetup_getOrigFromCurrentPosition $scan3DSetup_info]

    set anyChange 0

    set new_match 0
    foreach {orig_x orig_y orig_z orig_a} $orig break
    set angle [lindex $curOrig 3]

    set dp [expr int(abs($angle - $orig_a))]

    set n90 [expr $dp / 90]
    set l90 [expr $dp % 90]

    ###DEBUG
    #log_warning DEBUG dp=$dp n90=$n90 l90=$l90
            
    if {$l90 < 2} {
        if {$n90 % 2} {
            set new_match 2
            #log_warning DEBUG match=2
        } else {
            set new_match 1
            #log_warning DEBUG match=1
        }
    } elseif {$l90 > 88} {
        if {$n90 % 2} {
            set new_match 1
            #log_warning DEBUG match=1
        } else {
            set new_match 2
            #log_warning DEBUG match=2
        }
    }
    if {$old_match != $new_match} {
        incr anyChange
        set newContents [lreplace $newContents 0 0 $new_match]
        #log_warning need to change match
    }

    incr anyChange [scan3DSetup_updateVideoOffsetFromOrig newContents]

    if {$anyChange} {
        set scan3DSetup_info $newContents
    }
}


proc scan3DSetupRangeCheck { contents_ {silent_ 0}} {
    return [MRasteringRangeCheckForScan3DSetup $contents_ $silent_]
}

proc scan3DSetup_calculateOrigOffsetFromCurrentPosition { info orig } {
    puts "orig off for $orig"
    ### use current position as orig
    set curOrig [scan3DSetup_getOrigFromCurrentPosition $info]
    puts "current situation: $curOrig"
    foreach {x y z} $orig break
    
    foreach {dVu dHu} [calculateProjectionFromSamplePosition $curOrig $x $y $z 1] break
    puts "orig off in u: $dVu $dHu"
    return [list $dVu $dHu]
}
proc scan3DSetup_calculateOrigOffsetOnVideoView { orig isInline } {
    puts "orig off for $orig on inline? $isInline"
    ### use current position as orig
    set curOrig [scan3DSetup_getOrigFromVideoView $isInline]
    puts "current situation: $curOrig"
    foreach {x y z} $orig break
    
    foreach {dVu dHu} [calculateProjectionFromSamplePosition $curOrig $x $y $z 1] break
    puts "orig off in u: $dVu $dHu"
    return [list $dVu $dHu]
}
proc scan3DSetup_removeArea { args } {
    variable scan3DSetup_info

    set area_index [lindex $args 0]

    switch -exact -- $area_index {
        0 {
            ### remove first area and promote the second into first
            set snap2 [lindex $scan3DSetup_info 2]
            foreach {w h d nw nh nd} [lrange $scan3DSetup_info 5 end] break
            set orig2 [lindex $snap2 1]
            set newContents [lreplace $scan3DSetup_info 1 3 $orig2 $snap2 {}]
            set newContents [lreplace $scan3DSetup_info 5 10 $d $h $w $nd $nh $nw]
            set scan3DSetup_info $newContents
            scan3DSetup_goToPosition1
        }
        1 {
            ### remove second area and rotate to its view so user can redefine it
            ### only remove the area, not the definition so the user still can see it on the video
            set scan3DSetup_info [lreplace $scan3DSetup_info 2 2 {}]
            scan3DSetup_goToPosition1
        }
        default {
            log_error wrong argument: $args
            return -code error WRONG_ARGS
        }
    }
}

proc scan3DSetup_createArea { args } {
    variable scan3DSetup_info
    set match_index [lindex $scan3DSetup_info 0]
    set view_index  [lindex $scan3DSetup_info 11]
    set inline      [lindex $scan3DSetup_info 14]

    switch -exact -- $match_index {
        1 {
            set areaDefined [lindex $scan3DSetup_info 12]
            set hoff        [lindex $scan3DSetup_info 15]
            set voff        [lindex $scan3DSetup_info 16]
        }
        2 {
            set areaDefined [lindex $scan3DSetup_info 13]
            set hoff        [lindex $scan3DSetup_info 17]
            set voff        [lindex $scan3DSetup_info 18]
        }
        default {
            log_error not on the defined area view
            return -code error NOT_MATCH
        }
    }

    if {$areaDefined != "1"} {
        log_error define area first
        return -code error not_defined
    }
    
    set hoffMM [expr $hoff / -1000.0]
    set voffMM [expr $voff / -1000.0]

    ## center the defined area
    if {$inline == "1"} {
        inlineMoveSampleRelativeMM $hoffMM $voffMM
    } else {
        moveSampleRelativeMM $hoffMM $voffMM
    }
    if {$match_index == 1} {
        scan3DSetup_takeFirstSnapshot
        scan3DSetup_goToPosition1
    } else {
        scan3DSetup_takeSecondSnapshot
    }
    #### create new file
    MRastering_createScan2DSetups 1
}
## set area 0 will erase area 1
proc scan3DSetup_setArea { args } {
    variable ::scan3DSetup::info0
    variable ::scan3DSetup::info1
    variable scan3DSetup_info

    set usingCollimator [lindex $scan3DSetup_info 4]
    set view_index      [lindex $scan3DSetup_info 11]
    set inline [lindex $scan3DSetup_info 14]
    if {$inline != "1"} {
        set inline 0
    }

    if {[llength $args] < 4} {
        log_error setting scan area needs x0 y0 x1 y1
        return -code error not_enough_argument
    }
    foreach {x0 y0 x1 y1} $args break

    ### move sample to the center first
    set x [expr ($x0 + $x1) / 2.0]
    set y [expr ($y0 + $y1) / 2.0]
    set dx [expr abs($x1 - $x0)]
    set dy [expr abs($y1 - $y0)]

    send_operation_update calling define area $x0 $y0 $x1 $y1
    send_operation_update x=$x y=$y dx=$dx dy=$dy

    if {$inline} {
        set bCenterX  [getInlineCameraConstant zoomMaxXAxis]
        set bCenterY  [getInlineCameraConstant zoomMaxYAxis]
        foreach {sample_dx sample_dy sample_dz} \
        [inlineMoveSample_getDXDYDZFromRelative \
        [expr $bCenterX - $x] [expr $bCenterY - $y] \
        ] break
        foreach {dxMM dyMM} [inlineMoveSampleRelativeToMM $dx $dy] break
    } else {
        set bCenterX  [getSampleCameraConstant zoomMaxXAxis]
        set bCenterY  [getSampleCameraConstant zoomMaxYAxis]
        foreach {sample_dx sample_dy sample_dz} \
        [moveSample_getDXDYDZFromRelative \
        [expr $bCenterX - $x] [expr $bCenterY - $y] \
        ] break
        foreach {dxMM dyMM} [moveSample_relativeToMM $dx $dy] break

        send_operation_update delta sample_xyz $sample_dx $sample_dy $sample_dz
        send_operation_update area size in mm $dxMM $dyMM
    }

    set orig [scan3DSetup_getOrigFromCurrentPosition $scan3DSetup_info \
    $sample_dx $sample_dy $sample_dz \
    ]

    send_operation_update orig $orig

    ### I know there is more simple way but we already have this
    if {$view_index == 0} {
        set wU [expr $dxMM * 1000.0]
        set hU [expr $dyMM * 1000.0]

        set newContents \
        [list 1 $orig {} {} $usingCollimator $wU $hU 50 100 100 100 0 1 0 $inline 0 0 0 0 0 0 0 0]
    } else {
        set dU [expr $dyMM * 1000.0]
        ##reserve phi
        set old_orig [lindex $scan3DSetup_info 1]
        set old_a    [lindex $old_orig 3]
        set orig     [lreplace $orig 3 3 $old_a]

        set newContents $scan3DSetup_info
        set newContents [lreplace $newContents 0 1 2 $orig]
        set newContents [lreplace $newContents 3 3 ""]
        set newContents [lreplace $newContents 7 7 $dU]
        set newContents [lreplace $newContents 13 13 1]
    }
    #scan3DSetup_updateVideoOffsetFromOrig newContents
    set scan3DSetup_info [scan3DSetupRangeCheck $newContents 1]
    scan3DSetupMatch
}

proc scan3DSetup_updateVideoOffsetFromOrig { stringRef } {
    upvar $stringRef newContents

    set match  [lindex $newContents 0]
    set orig   [lindex $newContents 1]
    set inline [lindex $newContents 14]

    if {$match != 1 && $match != 2} {
        return 0
    }

    ### because 12-2 has both sample camer and inline camera,
    ### we will update both offsets

    set anyChange 0

    switch -exact -- $match {
        1 {
            set old_hoff [lindex $newContents 15]
            set old_voff [lindex $newContents 16]
            foreach {voff hoff} \
            [scan3DSetup_calculateOrigOffsetFromCurrentPosition \
            $newContents $orig] break

            #log_warning 1off old: $old_hoff $old_voff new: $hoff $voff
            if {$old_hoff != $hoff || $old_voff != $voff} {
                incr anyChange
                set newContents [lreplace $newContents 15 16 $hoff $voff]
            }
            if {$inline} {
                set old_hoff [lindex $newContents 17]
                set old_voff [lindex $newContents 18]
                foreach {voff hoff} \
                [scan3DSetup_calculateOrigOffsetOnVideoView $orig 0] break

                #log_warning 2off old: $old_hoff $old_voff new: $hoff $voff
                if {$old_hoff != $hoff || $old_voff != $voff} {
                    incr anyChange
                    set newContents [lreplace $newContents 17 18 $hoff $voff]
                }
            }
        }
        2 {
            set old_hoff [lindex $newContents 17]
            set old_voff [lindex $newContents 18]
            foreach {voff hoff} \
            [scan3DSetup_calculateOrigOffsetFromCurrentPosition \
            $newContents $orig] break

            #log_warning 2off old: $old_hoff $old_voff new: $hoff $voff
            if {$old_hoff != $hoff || $old_voff != $voff} {
                incr anyChange
                set newContents [lreplace $newContents 17 18 $hoff $voff]
            }
            if {$inline} {
                set old_hoff [lindex $newContents 15]
                set old_voff [lindex $newContents 16]
                foreach {voff hoff} \
                [scan3DSetup_calculateOrigOffsetOnVideoView $orig 0] break

                #log_warning 1off old: $old_hoff $old_voff new: $hoff $voff
                if {$old_hoff != $hoff || $old_voff != $voff} {
                    incr anyChange
                    set newContents [lreplace $newContents 15 16 $hoff $voff]
                }
            }
        }
    }
    return $anyChange
}

proc scan3DSetup_updateSnapshotAreaFromOrig { stringRef } {
    upvar $stringRef newContents

    foreach {match orig snap0 snap1 - w h d} $newContents break
    foreach {x y z} $orig break
    send_operation_update updating snapshot offset from orig $orig

    set orig0 [lindex $snap0 1]
    set orig1 [lindex $snap1 1]

    set anyChange 0
    if {[llength $orig0] >= 6} {
        foreach {dVu dHu} [calculateProjectionFromSamplePosition \
        $orig0 $x $y $z 1] break

        send_operation_update area0: orig=$orig0 xyz=$x $y $z proj=$dVu $dHu

        send_operation_update area0: $dHu $dVu
        
        set newContents [lreplace $newContents 19 20 $dHu $dVu]
        incr anyChange

        ###DEBUG
        foreach {pV pH} [calculateProjectionFromSamplePosition \
        $orig0 $x $y $z] break
        send_operation_update area0: project: h=$pH v=$pV
    }
    if {[llength $orig1] >= 6} {
        foreach {dVu dHu} [calculateProjectionFromSamplePosition \
        $orig1 $x $y $z 1] break
        
        send_operation_update area1: orig=$orig1 xyz=$x $y $z proj=$dVu $dHu
        send_operation_update area1: $dHu $dVu
        set newContents [lreplace $newContents 21 22 $dHu $dVu]
        incr anyChange
    }
    return $anyChange
}
proc scan3DSetup_changeSnapshotAreaSize { args } {
    variable scan3DSetup_info

    set ll [llength $args]
    if {$ll < 2} {
        log_error change snapshot scan area size needs index action 
        return -code error not_enough_argument
    }
    if {$ll >= 3} {
        set setup_info [lindex $args 2]
        scan3DSetup_checkHistorySnapshots $setup_info

        set scan3DSetup_info $setup_info
    }
    foreach {size_name action} $args break

    set newContents $scan3DSetup_info
    switch -exact -- $size_name {
        width {
            set index 5
        }
        height {
            set index 6
        }
        depth {
            set index 7
        }
        default {
            log_error wrong size_name: $size_name
            return
        }
    }
    set old   [lindex $scan3DSetup_info $index]
    set old_n [lindex $scan3DSetup_info [expr $index + 3]]
    if {$old_n > 0} {
        set step [expr double($old) / $old_n]
    } else {
        set step [expr 0.25 * $old]
    }

    if {$action == "expand"} {
        set value [expr $value + 0.9 * $step]
    } else {
        set value [expr $value - 1.1 * $step]
    }
    set newContents [lreplace $newContents $index $index $value]
    set scan3DSetup_info [scan3DSetupRangeCheck $newContents]
    #scan3DSetupMatch
    MRastering_createScan2DSetups
}
proc scan3DSetup_moveSnapshotArea { args } {
    variable scan3DSetup_info
    variable center_crystal_msg

    set ll [llength $args]
    if {$ll < 2} {
        log_error move snapshot scan area needs index direction
        return -code error not_enough_argument
    }
    if {$ll >= 3} {
        set setup_info [lindex $args 2]
        scan3DSetup_checkHistorySnapshots $setup_info

        set scan3DSetup_info $setup_info
    }

    set old_orig [lindex $scan3DSetup_info 1]
    set inline   [lindex $scan3DSetup_info 14]
    foreach {ox oy oz} $old_orig break

    foreach {view_index direction} $args break

    set center_crystal_msg "move raster $direction"

    switch -exact -- $view_index {
        0 {
            set snap [lindex $scan3DSetup_info 2]
            set w    [lindex $scan3DSetup_info 5]
            set h    [lindex $scan3DSetup_info 6]
            set nw   [lindex $scan3DSetup_info 8] 
            set nh   [lindex $scan3DSetup_info 9] 
        }
        1 {
            set snap [lindex $scan3DSetup_info 3]
            set w    [lindex $scan3DSetup_info 5]
            set h    [lindex $scan3DSetup_info 7]
            set nw   [lindex $scan3DSetup_info 8] 
            set nh   [lindex $scan3DSetup_info 10] 
        }
        default {
            log_error wrong view_index for snapshot
            return
        }
    }

    if {$w != 0 && $nw != 0} {
        set stepW [expr abs(0.25 * $w / $nw)]
    } else {
        set stepW [expr 250.0 * [get_rastering_constant columnWd]]
    }
    if {$h != 0 && $nh != 0} {
        set stepH [expr abs(0.25 * $h / $nh)]
    } else {
        set stepH [expr 250.0 * [get_rastering_constant rowHt]]
    }

    set dv 0
    set dh 0

    puts "move $view_index $direction"
    switch -exact -- $direction {
        up {
            set dv -$stepH
        }
        down {
            set dv $stepH
        }
        left {
            if {$inline} {
                set dh $stepW
            } else {
                set dh -$stepW
            }
        }
        right {
            if {$inline} {
                set dh -$stepW
            } else {
                set dh $stepW
            }
        }
        default {
            log_error wrong direction: $direction
            return
        }
    }
    set sorig [lindex $snap 1]
    foreach {dx dy dz} [calculateSamplePositionDeltaFromDeltaProjection \
    $sorig $dv $dh 1] break

    set new_x [expr $ox + $dx]
    set new_y [expr $oy + $dy]
    set new_z [expr $oz + $dz]
    set newOrig [lreplace $old_orig 0 2 $new_x $new_y $new_z]
    send_operation_update snapshot area: new_orig $newOrig

    set newContents $scan3DSetup_info
    set newContents [lreplace $newContents 1 1 $newOrig]

    scan3DSetup_updateSnapshotAreaFromOrig newContents
    set scan3DSetup_info [scan3DSetupRangeCheck $newContents 1]
    ### this will update video offsets
    #scan3DSetupMatch
    MRastering_createScan2DSetups
}
### similar to the BluIce class:
### Scan3DMatrixView::moveToMark
proc scan3DSetup_setSnapshotArea { args } {
    variable scan3DSetup_info

    set ll [llength $args]
    if {$ll < 5} {
        log_error setting snapshot scan area needs index x0 y0 x1 y1
        return -code error not_enough_argument
    }
    if {$ll >= 6} {
        set setup_info [lindex $args 5]
        scan3DSetup_checkHistorySnapshots $setup_info
        set scan3DSetup_info $setup_info
    }

    set old_orig [lindex $scan3DSetup_info 1]
    set inline   [lindex $scan3DSetup_info 14]

    foreach {ox oy oz} $old_orig break


    foreach {view_index sx0 sy0 sx1 sy1} $args break
    set sx [expr ($sx0 + $sx1) / 2.0]
    set sy [expr ($sy0 + $sy1) / 2.0]
    set sdx [expr abs($sx1 - $sx0)]
    set sdy [expr abs($sy1 - $sy0)]

    send_operation_update snapshot area: $view_index $sx0 $sy0 $sx1 $sy1
    send_operation_update snapshot area: x=$sx y=$sy dx=$sdx dy=$sdy

    if {$inline} {
        set sCenterX  [getInlineCameraConstant zoomMaxXAxis]
        set sCenterY  [getInlineCameraConstant zoomMaxYAxis]
    } else {
        set sCenterX  [getSampleCameraConstant zoomMaxXAxis]
        set sCenterY  [getSampleCameraConstant zoomMaxYAxis]
    }
    set soffH [expr $sx - $sCenterX]
    set soffV [expr $sy - $sCenterY]

    send_operation_update snapshot area: soffH=$soffH soffV=$soffV

    switch -exact -- $view_index {
        0 {
            set snap [lindex $scan3DSetup_info 2]
        }
        1 {
            set snap [lindex $scan3DSetup_info 3]
        }
        default {
            log_error wrong view_index for snapshot
            return
        }
    }
    set sorig [lindex $snap 1]
    foreach {dx dy dz} [calculateSamplePositionDeltaFromProjection \
    $sorig $ox $oy $oz $soffV $soffH] break

    send_operation_update snapshot area: dxyz: $dx $dy $dz
    send_operation_update snapshot area: old_orig $old_orig

    set new_x [expr $ox + $dx]
    set new_y [expr $oy + $dy]
    set new_z [expr $oz + $dz]
    set newOrig [lreplace $old_orig 0 2 $new_x $new_y $new_z]
    send_operation_update snapshot area: new_orig $newOrig

    set newContents $scan3DSetup_info
    set newContents [lreplace $newContents 1 1 $newOrig]

    foreach {- - - - imgH imgW} $sorig break

    ### sdx sdy cannot be zero.  We need widthU and heightU to pass in the sign
    if {$sdx == 0} {
        set sdx 0.00000000001
    }
    if {$sdy == 0} {
        set sdy 0.00000000001
    }
    set widthU  [expr $sdx * $imgW * 1000.0]
    set heightU [expr $sdy * $imgH * 1000.0]

    ##DEBUG
    set soffHU [expr $soffH * $imgW * 1000.0]
    set soffVU [expr $soffV * $imgH * 1000.0]
    send_operation_update snapshot area $view_index: offsetU $soffHU $soffVU


    switch -exact -- $view_index {
        0 {
            set newContents [lreplace $newContents 5 6 $widthU $heightU]
            set newContents [lreplace $newContents 12 12 1]
        }
        1 {
            set newContents [lreplace $newContents 5 5 $widthU]
            set newContents [lreplace $newContents 7 7 $heightU]
            set newContents [lreplace $newContents 13 13 1]
        }
    }
    scan3DSetup_updateSnapshotAreaFromOrig newContents
    set scan3DSetup_info [scan3DSetupRangeCheck $newContents 1]
    ### this will update video offsets
    #scan3DSetupMatch
    MRastering_createScan2DSetups
}
proc scan3DSetup_setField { args } {
    variable scan3DSetup_info

    set anyChange 0
    set newContents $scan3DSetup_info
    foreach {index v} $args {
        set old_v [lindex $newContents $index]
        if {$old_v != $v} {
            incr anyChange
            set newContents [lreplace $newContents $index $index $v]
            set newContents [scan3DSetupRangeCheck $newContents]
        }
    }
    if {$anyChange} {
        set scan3DSetup_info $newContents
        MRastering_createScan2DSetups
    }
}
proc scan3DSetup_autoFillField { } {
    variable scan3DSetup_info
    variable center_crystal_msg

    if {[catch {
        ### switch to sample camera
        scan3DSetup_switchCamera 0

        set center_crystal_msg "centering loop"
        set handle [start_waitable_operation centerLoop]
        wait_for_operation_to_finish $handle

        #### 1 at tne end means no log
        #CCrystalGetLoopSize width faceHeight edgeHeight 1
        MRasteringGetLoopSize width faceHeight edgeHeight 1
    } errMsg]} {
        log_error loop center failed: $errMsg
        return -code error $errMsg
    }

    scan3DSetup_takeSnapshot 0

    set w [expr 1000.0 * $width]
    set h [expr 1000.0 * $faceHeight]
    set d [expr 1000.0 * $edgeHeight]

    foreach {w h d} \
    [scan3DSetup_decideSignForArea $scan3DSetup_info $w $h $d] break

    scan3DSetup_setField 5 $w 6 $h 7 $d
}
proc scan3DSetup_decideSignForArea { info w h d } {
    foreach {- orig snap0 snap1} $info break
    set orig0 [lindex $snap0 1]
    set orig1 [lindex $snap1 1]
    set imgW  [lindex $orig0 5]
    set imgH  [lindex $orig0 4]
    set imgD  [lindex $orig1 4]

    set w [expr abs($w)]
    set h [expr abs($h)]
    set d [expr abs($d)]

    if {$imgW < 0} {
        set w [expr -$w]
    }
    if {$imgH < 0} {
        set h [expr -$h]
    }
    if {$imgD < 0} {
        set d [expr -$d]
    }
    return [list $w $h $d]
}
proc scan3DSetup_moveToSnapshot { index {only_phi 0} } {
    variable scan3DSetup_info

    ## here should use the common orig
    ## orig0 normally not match common orig because sample moved when
    ## we define the second area

    switch -exact -- $index {
        0 {
            set snap [lindex $scan3DSetup_info 2]
        }
        1 {
            set snap [lindex $scan3DSetup_info 3]
        }
        default {
            log_error bad snapshot index: $index
            return -code error wrong_snapshot_index
        }
    }
    variable gonio_omega

    set inline [lindex $scan3DSetup_info 14]
    set orig   [lindex $snap 1]
    foreach {x y z a} $orig break
    set phi [expr $a - $gonio_omega]
    if {!$inline} {
        set phi [expr $phi + 90]
    }

    if {$only_phi} {
        move gonio_phi to $phi
        wait_for_devices gonio_phi
        return
    }
    move sample_x to $x
    move sample_y to $y
    move sample_z to $z
    move gonio_phi to $phi
    wait_for_devices sample_x sample_y sample_z gonio_phi

    ### let's only take snapshot during area setup.
    ### This will allow flexible areas definition (they do not need to have
    ### the same orig).
    #switch -exact -- $index {
    #    0 {
    #        scan3DSetup_takeFirstSnapshot
    #    }
    #    1 {
    #        scan3DSetup_takeSecondSnapshot
    #    }
    #}
}

####
### it will be "lA1_IDFROMSPREADSHEET"
###            "lA1"
###            "manual"
proc scan3DSetup_getCurrentCrystalID { } {
    variable crystalStatus

    set raw [user_log_get_current_crystal]
    set mayFromSpreadsheet [lindex $crystalStatus 0]

    if {$mayFromSpreadsheet != "" \
    && [string first $mayFromSpreadsheet $raw] < 0} {
        append raw _$mayFromSpreadsheet
    }
    return $raw
}
proc scan3DSetup_checkHistorySnapshots { setup } {
    variable ::scan3DSetup::dir
    variable ::scan3DSetup::bid

    foreach { - - info0 info1 } $setup break
    set snap0 [lindex $info0 0]
    set snap1 [lindex $info1 0]

    set dir0 [file dirname $snap0]
    set dir1 [file dirname $snap1]

    if {$dir0 != $dir || $dir1 != $dir} {
        log_error wrong directory for snapshots
        return -code error wrong_dir
    }

    set t0 [file tail $snap0]
    set t1 [file tail $snap1]

    set r0 ${bid}_0_
    set r1 ${bid}_1_

    set cl [string length $r0]

    if {![string equal -length $cl $t0 $r0] \
    || ![string equal -length $cl $t1 $r1]} {
        log_error wrong beamline prefix for snapshots
        return -code error wrong_prefix
    }
    if {![file exists $snap0]} {
        log_error the snapshot $snap0 not exists
        return -code error wrong_owner
    }
    if {![file exists $snap1]} {
        log_error the snapshot $snap1 not exists
        return -code error wrong_owner
    }

    if {![file owned $snap0] || ![file owned $snap1]} {
        log_error wrong owner of the snapshot files
        return -code error wrong_owner
    }
}
