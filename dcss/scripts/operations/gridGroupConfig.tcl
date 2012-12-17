#package require Itcl
#namespace import ::itcl::*
package require DCSGridGroupBase

#::GridGroup::GridGroup4DCSS gGridGroup4Run
::GridGroup::GridGroup4DCSS gGridGroup4Config

proc gridGroupConfig_initialize {} {
    log_note "gridGroupConfig_initialize"
    global gMAXRASTERGROUP
    set gMAXRASTERGROUP [::GridGroup::GridGroupBase::getMAXGROUP]
    log_note "MAXRASTERGROUP: $gMAXRASTERGROUP"

    namespace eval ::gridGroupConfig {

        set dir [::config getStr "gridGroup.directory"]
        set bid [::config getConfigRootName]
        set user "nobody"

        set file_handle ""

        set needClearStatus 0

        puts "DONE init gridGroupConfig"
    }

    ################# copied from videoVisexSnapshot
    variable camera_view_phi
    set camera_view_phi(inline) [::config getStr camera_view_phi.inline]
    set camera_view_phi(sample) [::config getStr camera_view_phi.sample]
    set camera_view_phi(visex)  [::config getStr camera_view_phi.visex]

    #### update video orig to update grid on live video
    registerEventListener sample_x ::nScripts::gridGroupUpdateVideoOrig
    registerEventListener sample_y ::nScripts::gridGroupUpdateVideoOrig
    registerEventListener sample_z ::nScripts::gridGroupUpdateVideoOrig
    registerEventListener gonio_phi ::nScripts::gridGroupUpdateVideoOrig
    registerEventListener gonio_omega ::nScripts::gridGroupUpdateVideoOrig
    registerEventListener camera_zoom ::nScripts::gridGroupUpdateVideoOrig
    registerEventListener inline_camera_zoom ::nScripts::gridGroupUpdateVideoOrig

    registerEventListener sample_camera_constant ::nScripts::gridGroupUpdateVideoOrig
    registerEventListener inline_sample_camera_constant ::nScripts::gridGroupUpdateVideoOrig
    gridGroupUpdateVideoOrig
}
proc gridGroupConfig_cleanup {} {
    variable ::gridGroupConfig::needClearStatus
    variable raster_msg

    if {$needClearStatus} {
        set raster_msg [lreplace $raster_msg 0 0 0]
        set needClearStatus 0
    }
}
proc gridGroupConfig_start { command args } {
    variable ::gridGroupConfig::needClearStatus
    variable ::gridGroupConfig::user

    set user [get_operation_user]

    switch -exact -- $command {
        addGroup {
            set needClearStatus 1
            return [eval gridGroupAddNewGroup $args]
        }
        addSnapshot {
            eval gridGroupAddSnapshot $args
        }
        deleteSnapshot {
            eval gridGroupDeleteSnapshot $args
        }
        reload {
            #### test
            eval gridGroupReload
        }
        addGrid {
            eval gridGroupAddGrid $args
        }
        addGridFromLiveVideo {
            set groupNum [lindex $args 0]
            foreach {groupNum - orig} $args break
            set camera [lindex $orig 10]
            set snapshotId [gridGroupAddCurrentSnapshotIfNeed $groupNum $camera]
            set args [lreplace $args 1 1 $snapshotId]
            eval gridGroupAddGrid $args
        }
        deleteGrid {
            eval gridGroupDeleteGrid $args
        }
        modifyGrid {
            eval gridGroupModifyGrid 0 $args
        }
        modifyGridFromLiveVideo {
            eval gridGroupModifyGrid 1 $args
        }
        resetGrid {
            eval gridGroupResetGrid $args
        }
        modifyParameter {
            eval gridGroupModifyParameter $args
        }
        flip_node {
            ### this is allowed even when collectGrid is running
            eval gridGroupFlipNode $args
        }
        move_to_grid {
            eval gridGroupMoveToGrid $args
        }
        move_to_node {
            eval gridGroupMoveToNode $args
        }
        on_grid_move {
            eval gridGroupMoveOnGrid $args
        }
        default_grid_parameter {
            eval gridGroupDefaultGrid $args
        }
        update_grid_parameter {
            eval gridGroupUpdateGrid $args
        }
        load_l614_sample_list {
            eval gridGroupLoadL614SampleList $args
        }
        update_l614_sample_list {
            eval gridGroupUpdateL614SampleList $args
        }
        cleanup_for_user_change_over {
            ### delete all gridGroup and their files.
            gridGroupChangeOver
        }
        cleanup_for_dismount {
            #### clean all grid and snapshot, leave empty gridGroups.
            gridGroupDismount
        }
        default {
            return -code error "wrong command: $command"
        }
    }
}

proc gridGroupAddNewGroup { args } {
    global gMAXRASTERGROUP
    variable ::gridGroupConfig::dir
    variable ::gridGroupConfig::bid
    variable gonio_phi
    variable gridGroup_sum
    variable camera_view_phi

    ### you can check the number allowed here.
    set groupCount [lindex $gridGroup_sum 0]
    set newNum $groupCount
    if {$newNum >= $gMAXRASTERGROUP} {
        log_error no spare gridGroup place
        return -code error "reached max gridGroup"
    }

    set newCount [expr $groupCount + 1]

    variable gridGroup$newNum

    if {$newNum == 0} {
        set newLabel 1
    } else {
        set lastNum [expr $newNum - 1]
        variable gridGroup$lastNum
        set lastLabel [lindex [set gridGroup$lastNum 1]]
        set newLabel [expr $lastLabel + 1]
    }

    foreach { camera single_view} $args break

    set groupFile ${bid}_[getScrabbleForFilename].yaml
    set groupPath [file join $dir $groupFile]

    set snap1 [gridGroupTakeSnapshot $camera 1]
    set phiFaceBeam [expr $gonio_phi - $camera_view_phi($camera)]
    set tag [format "%.0f" $phiFaceBeam]
    set snapshot1 [linsert $snap1 0 1 $tag 0.0 $camera]

    puts "first snapshot: {$snap1}"
    set orig [lindex $snap1 1]
    set snapshot2 ""
    if {!$single_view} {
        move gonio_phi by 90
        wait_for_devices gonio_phi
        set snap2 [gridGroupTakeSnapshot $camera 2]
        set phiFaceBeam [expr $gonio_phi - $camera_view_phi($camera)]
        set tag [format "%.0f" $phiFaceBeam]
        set snapshot2 [linsert $snap2 0 2 $tag 90.0 $camera]
        move gonio_phi by -90
        wait_for_devices gonio_phi
    }

    ## you can load a not_exist one too
    gGridGroup4Config initialize \
    $newNum $groupPath $orig $snapshot1 $snapshot2

    set gridGroup$newNum [list inactive $newLabel $groupFile]
    set gridGroup_sum [list $newCount $newNum]
}
proc gridGroupAddSnapshot { args } {
    variable cfgSampleMoveSerial
    variable camera_view_phi

    set ll [llength $args]
    if {$ll < 2} {
        log_error arguments for add snapshot: groupNum phi
        return -code error WRONG_ARGS
    }

    foreach {groupNum phi} $args break
    set groupName [gridGroupConfig_load $groupNum 0]
    set camera   [$groupName getDefaultCamera]
    set ssSeqNum [$groupName getSnapshotSequenceNumber]
    set orig     [$groupName getOrig]
    foreach {x y z a h w} $orig break

    ### move to orig and set up camer zoom
    ## this phi is the phi when view face the beam
    set phiToMove [expr $phi + $camera_view_phi($camera)]

    move gonio_phi to $phiToMove
    if {$cfgSampleMoveSerial} {
        move sample_x to $x
        wait_for_devices sample_x
        move sample_y to $y
        wait_for_devices sample_y
        move sample_z to $z
        wait_for_devices sample_z gonio_phi
    } else {
        move sample_x to $x
        move sample_y to $y
        move sample_z to $z
        wait_for_devices sample_x sample_y sample_z gonio_phi
    }
    switch -exact -- $camera {
        sample {
            set zoom [sampleView_calculate_zoom $w]
            move camera_zoom to $zoom
            wait_for_devices camera_zoom
        }
        inline {
            set zoom [inlineView_calculate_zoom $w]
            move inline_camera_zoom to $zoom
            wait_for_devices inline_camera_zoom
        }
        default {
            log_error got unsupported camera: $camera
            return -code error unsupported_camera
        }
    }
    set snap [gridGroupTakeSnapshot $camera $ssSeqNum]
    foreach {ssFile ssOrig} $snap break
    set ssA [lindex $ssOrig 3]
    set sortAngle [expr $ssA - $a]
    while {$sortAngle < 0} {
        set sortAngle [expr $sortAngle + 360.0]
    }
    while {$sortAngle >= 360.0} {
        set sortAngle [expr $sortAngle - 360.0]
    }
    set tag [format "%.0f" $phi]
    $groupName addSnapshotImage $tag $sortAngle $camera $ssFile $ssOrig
}
proc gridGroupAddCurrentSnapshotIfNeed { groupNum camera } {
    variable gonio_omega

    set groupName [gridGroupConfig_load $groupNum 0]
    if {$camera == ""} {
        set camera [$groupName getDefaultCamera]
    }

    ### check if need
    set vOrig [gridGroupConfig_getOrigFromVideoView $camera]
    set snapshotId [$groupName searchSnapshotId $vOrig]
    if {$snapshotId >= 0} {
        return $snapshotId
    }

    ### need to take a new snapshot for this grid
    set ssSeqNum [$groupName getSnapshotSequenceNumber]
    set orig     [$groupName getOrig]
    foreach {x y z a h w} $orig break

    set snap [gridGroupTakeSnapshot $camera $ssSeqNum]
    foreach {ssFile ssOrig} $snap break
    set ssA [lindex $ssOrig 3]
    set sortAngle [expr $ssA - $a]
    set phi [expr $ssA - $gonio_omega]
    while {$sortAngle < 0} {
        set sortAngle [expr $sortAngle + 360.0]
    }
    while {$sortAngle >= 360.0} {
        set sortAngle [expr $sortAngle - 360.0]
    }
    set tag [format "%.0f" $phi]
    set ss [$groupName addSnapshotImage $tag $sortAngle $camera $ssFile $ssOrig]
    set snapshotId [$ss getId]

    return $snapshotId
}
proc gridGroupDeleteSnapshot { args } {
    set ll [llength $args]
    if {$ll < 2} {
        log_error arguments for delete snapshot: groupNum id
        return -code error WRONG_ARGS
    }
    foreach {groupNum id} $args break
    set groupName [gridGroupConfig_load $groupNum 0]
    $groupName deleteSnapshotImage $id
}

proc gridGroupTakeSnapshot { camera seqNum } {
    variable ::gridGroupConfig::file_handle
    variable ::gridGroupConfig::dir
    variable ::gridGroupConfig::bid

    if {$camera == "inline"} {
        if {[lightsControl_inlineLightAvailable] \
        &&  [isOperation inlineLightControl]} {
            if {[catch {
                if {[inlineLightControl_start insert]} {
                    log_warning wait for light to stable
                    wait_for_time 2000
                }
            } errMsg]} {
                log_error failed to insert inline light: $errMsg
            }
        }
        set contents [UtilTakeInlineVideoSnapshot]
    } elseif {$camera == "sample"} {
        set contents [UtilTakeVideoSnapshot]
    } elseif {$camera == "visex"} {
        log_severe not sure what to do yet.
        return -code error not_implemented_yet
    }

    set filename ${bid}_${seqNum}_[getScrabbleForFilename].jpg

    set path [file join $dir $filename]

    if {![catch {open $path w} file_handle]} {
        fconfigure $file_handle -translation binary
        puts -nonewline $file_handle $contents
        close $file_handle
        set file_handle ""
        file attributes $path -permissions ugo+rwx
    } else {
        log_error failed to save first snapshot: $file_handle
        return -code error $file_handle
    }

    set orig [gridGroupConfig_getOrigFromVideoView $camera]
    set info [list $path $orig]
    return $info
}
proc gridGroupConfig_getOrigFromVideoView { camera } {
    variable camera_view_phi

    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_omega
    variable gonio_phi

    set angle [expr $gonio_omega + $gonio_phi - $camera_view_phi($camera)]

    switch -exact -- $camera {
        inline {
            foreach {imgWmm imgHmm} [inlineMoveSampleRelativeToMM 1 1] break
            set centerHorz [getInlineCameraConstant zoomMaxXAxis]
            set centerVert [getInlineCameraConstant zoomMaxYAxis]
        }
        sample {
            foreach {imgWmm imgHmm} [moveSample_relativeToMM 1 1] break
            set centerHorz [getSampleCameraConstant zoomMaxXAxis]
            set centerVert [getSampleCameraConstant zoomMaxYAxis]
        }
        visex {
            foreach {imgWmm imgHmm} [visexMoveSampleRelativeToMM 1 1] break
            set centerHorz [getVisexCameraConstant center_x]
            set centerVert [getVisexCameraConstant center_y]
        }
    }

    set x $sample_x
    set y $sample_y
    set z $sample_z

    return \
    [list $x $y $z $angle $imgHmm $imgWmm 1 1 $centerVert $centerHorz $camera]
}
proc gridGroupConfig_load { groupNum_ silent } {
    variable ::gridGroupConfig::dir
    variable ::collectGrid::groupNum

    puts "+gridGroupConfig_load $groupNum_"

    variable gridGroup$groupNum_
    set groupFile [lindex [set gridGroup$groupNum_] 2]
    if {$groupFile == "not_exists"} {
        log_error gridGroup not exists
        return -code error not_exists
    }

    set groupPath [file join $dir $groupFile]
    
    ## this is the most of cases
    if {$groupNum_ == $groupNum} {
        puts "-gridGroupConfig_load using gGridGroup4Run"
        return gGridGroup4Run
    }

    puts "loading"
    gGridGroup4Config load $groupNum_ $groupPath $silent
    puts "-gridGroupConfig_load using gGridGroup4Config"
    return gGridGroup4Config
}
proc gridGroupReload { } {
    global gMAXRASTERGROUP
    variable ::gridGroupConfig::dir
    variable ::gridGroupConfig::bid
    variable gonio_phi
    variable gridGroup_sum
    variable gridGroup0

    foreach {status label file} $gridGroup0 break

    set path [file join $dir $file]

    gGridGroup4Config load 0 $path

    set dd [gGridGroup4Config getSnapshotIdMap]
    dict for {k v} $dd {
        set ff [$v getFile]
        send_operation_update "$k -- $ff"
    }
}
proc gridGroupAddGrid { args } {
    puts "+gridGroupAddGrid"

    set ll [llength $args]
    if {$ll < 6} {
        puts "-gridGroupAddGrid"
        log_error addGrid need 6 parameters: \
        groupId snapshotId orig geo matrix nodes.
        return -code error UNSUFFICIENT_ARGS
    }
    foreach {groupNum snapshotId orig geo matrix nodes} $args break
    set groupName [gridGroupConfig_load $groupNum 0]

    set param [gridGroupGenerateParam from_latest]

    set grid [$groupName addGrid $snapshotId $orig $geo $matrix $nodes $param]

    if {$grid != "" && [$grid getShape] == "l614"} {
        set id [$grid getId]
        gridGroupUpdateL614SampleList $groupNum $id
    }

    puts "-gridGroupAddGrid"
}
proc gridGroupGenerateParam { base } {
    variable ::gridGroupConfig::user
    variable crystalStatus
    variable screeningParameters
    variable latest_raster_user_setup

    set crystalId [lindex $crystalStatus 0]
    if {$crystalId != ""} {
        set root_dir [lindex $screeningParameters 2]
        set sub_dir  [lindex $crystalStatus 4]
        set dir      [file join $root_dir $sub_dir raster]
        checkUsernameInDirectory dir $user

        ##"GRID_LABEL" is a keyword, will be replace.
        set prefix ${crystalId}_rasterGRID_LABEL
    } else {
        set prefix rasterGRID_LABEL
        set dir    [dict get $latest_raster_user_setup directory]
        checkUsernameInDirectory dir $user
    }
    set param [dict create prefix $prefix directory $dir]

    switch -exact -- $base {
        from_latest {
            dict for {name v} $latest_raster_user_setup {
                switch -exact -- $name {
                    prefix -
                    directory {
                        ## already done
                    }
                    default {
                        dict set param $name $v
                    }
                }
            }
        }
        from_system_current {
            global gMotorDistance
            global gMotorBeamStop
            global gMotorBeamWidth
            global gMotorBeamHeight
            variable $gMotorDistance
            variable $gMotorBeamStop
            variable $gMotorBeamWidth
            variable $gMotorBeamHeight
            variable user_collimator_status
            variable attenuation

            if {[isString user_collimator_status]} {
                dict set param collimator  $user_collimator_status
            } else {
                dict set param collimator  [list 0 -1 2.0 2.0]
            }
            dict set param beam_width  [expr 1000.0 * [set $gMotorBeamWidth]]
            dict set param beam_height [expr 1000.0 * [set $gMotorBeamHeight]]
            dict set param distance    [set $gMotorDistance]
            dict set param beam_stop   [set $gMotorBeamStop]
            dict set param attenuation [expr $attenuation + 0.001]
            dict set param first_attenuation 0
            dict set param end_attenuation 0
        }
        default {
            return ""
        }
    }
    
    return $param
}
proc gridGroupModifyGrid { fromLiveVideo args } {
    puts "+gridGroupModifyGrid"

    set ll [llength $args]
    if {$ll < 3} {
        puts "-gridGroupModifyGrid"
        log_error modifyGrid need 3 parameters: \
        groupId gridId info.
        return -code error UNSUFFICIENT_ARGS
    }
    set groupNum [lindex $args 0]
    set groupName [gridGroupConfig_load $groupNum 0]
    set gridList [lrange $args 1 end]

    foreach {gridId info} $gridList {
        if {[llength $info] < 4} {
            puts "DEBUG bad info={$info}"
            return -code error bad_parameters
        }
        foreach {orig geo matrix nodes} $info break
        $groupName modifyGrid $gridId $orig $geo $matrix $nodes
        if {$fromLiveVideo} {
            set grid [$groupName getGrid $gridId]
            set camera [$grid getCamera]
            set videoOrig [gridGroupConfig_getOrigFromVideoView $camera]
            if {[$grid newOrigIsBetter $videoOrig]} {
                set snapshotId \
                [gridGroupAddCurrentSnapshotIfNeed $groupNum $camera]
                $groupName modifyGridSnapshotId $gridId $snapshotId
                log_warning grid[$groupName getGridLabel $gridId] \
                has new snapshot.
            }
        }
    }

    puts "-gridGroupModifyGrid"
}
proc gridGroupDeleteGrid { args } {
    puts "+gridGroupDeleteGrid"
    set ll [llength $args]
    if {$ll < 2} {
        log_error wrong argument for deleteGrid
        return -code error UNSUFFICENT_ARGS
    }

    set groupNum [lindex $args 0]
    set idList [lrange $args 1 end]

    set groupName [gridGroupConfig_load $groupNum 0]
    foreach id $idList {
        $groupName deleteGrid $id
    }
    puts "-gridGroupDeleteGrid"
}
proc gridGroupFlipNode { args } {
    set ll [llength $args]
    if {$ll < 4} {
        log_error flip node needs 4 parameters: \
        groupId, gridId, row, column
        return -code error bad_argument
    }
    foreach {groupNum gridId row column} $args break

    set groupName [gridGroupConfig_load $groupNum 0]
    $groupName flipGridNode $gridId $row $column

    return OK
}
proc gridGroupUpdateVideoOrig { } {
    variable sampleVideoOrig
    variable inlineVideoOrig

    if {[catch {
        set newSample [gridGroupConfig_getOrigFromVideoView sample]
        if {$sampleVideoOrig != $newSample} {
            set sampleVideoOrig $newSample
        }
    } errMsg]} {
        puts "ERROR in updating sampleVideoOrig: $errMsg"
    }

    if {![isString inlineVideoOrig]} {
        return
    }
    if {[catch {
        set newInline [gridGroupConfig_getOrigFromVideoView inline]
        if {$inlineVideoOrig != $newInline} {
            set inlineVideoOrig $newInline
        }
    } errMsg]} {
        puts "ERROR in updating inlineVideoOrig; $errMsg"
    }
}
proc gridGroupModifyParameter { args } {
    variable ::gridGroupConfig::user
    puts "+gridGroupModifyParameter"

    set ll [llength $args]
    if {$ll < 3} {
        puts "-gridGroupModifyParameter"
        log_error modifyParameter need 3 parameters: \
        groupId gridId param.
        return -code error UNSUFFICIENT_ARGS
    }
    set groupNum [lindex $args 0]
    set groupName [gridGroupConfig_load $groupNum 0]
    set gridList [lrange $args 1 end]

    foreach {gridId param} $gridList {
        set label [$groupName getGridLabel $gridId]
        gridGroupReplaceUsernameAndGridLabelInDictionary param $user $label
        #$groupName modifyGridParameter $snapshotId $gridId $param
        $groupName modifyGridUserInput $gridId $param
    }

    puts "-gridGroupModifyParameter"
}
proc gridGroupMoveToNode { args } {
    variable camera_view_phi
    variable gonio_omega

    set ll [llength $args]
    if {$ll < 4} {
        log_error move_to_node need 4 parameters:
        group grid frame face_beam
        return -code error UNSUFFICIENT_ARGS
    }
    foreach {grpId id seq faceBeam} $args break
    set groupName [gridGroupConfig_load $grpId 0]
    
    ## we need beam center to move to
    gridGroupSetBeamCenter $groupName $id

    set pos    [$groupName getGridNodePosition $id $seq]
    set camera [$groupName getDefaultCamera]

    foreach {x y z a row col} $pos break
    set phiFaceBeam   [expr $a - $gonio_omega]
    set phiFaceCamera [expr $phiFaceBeam + $camera_view_phi($camera)]

    move sample_x to $x
    move sample_y to $y
    move sample_z to $z
    if {$faceBeam == "1"} {
        move gonio_phi to $phiFaceBeam
    } else {
        move gonio_phi to $phiFaceCamera
    }
    wait_for_devices sample_x sample_y sample_z gonio_phi
    set gridLabel [$groupName getGridLabel $id]
    log_note move to node [expr $seq + 1] of grid $gridLabel completed \
    successfully.
}
proc gridGroupMoveToGrid { args } {
    variable gonio_omega
    variable camera_view_phi

    set ll [llength $args]
    if {$ll < 3} {
        log_error move_to_grid need 3 parameters:
        group grid face_beam
        return -code error UNSUFFICIENT_ARGS
    }
    foreach {grpId id faceBeam} $args break
    set groupName [gridGroupConfig_load $grpId 0]
    
    ## we need beam center to move to
    foreach {cX cY } [gridGroupSetBeamCenter $groupName $id] break

    ### get camera from here in the near future
    set pos    [$groupName getGridCenterPosition $id]
    set camera [$groupName getDefaultCamera]

    puts "move to grid: orig=$pos"
    foreach {x y z a ch cw row col} $pos break
    set phiFaceBeam [expr $a - $gonio_omega]
    set phiFaceCamera [expr $phiFaceBeam + $camera_view_phi($camera)]

    set width  [expr $col * $cw * 1.5]
    set height [expr $row * $ch * 1.5]

    ### in case beam center is not at (0.5, 0.5)
    if {$cX <= 0.0 && $cY != 0.5 && $cY >= 1.0} {
        if {$cX > 0.5} {
            set width [expr $width * 0.5 / (1.0 - $cX)]
        } else {
            set width [expr $width * 0.5 / $cX]
        }
    }
    if {$cY <= 0.0 && $cY != 0.5 && $cY >= 1.0} {
        if {$cY > 0.5} {
            set height [expr $height * 0.5 / (1.0 - $cY)]
        } else {
            set height [expr $height * 0.5 / $cY]
        }
    }

    set zoomMotor ""
    switch -exact -- $camera {
        sample {
            set zoomMotor camera_zoom
            set zoom [sampleView_calculate_zoom $width $height]
            adjustPositionToLimit camera_zoom zoom 1
        }
        inline {
            set zoomMotor inline_camera_zoom
            set zoom [inlineView_calculate_zoom $width $height]
            adjustPositionToLimit inline_camera_zoom zoom 1
        }
    }

    move sample_x to $x
    move sample_y to $y
    move sample_z to $z
    if {$faceBeam == "1"} {
        move gonio_phi to $phiFaceBeam
    } else {
        move gonio_phi to $phiFaceCamera
    }
    if {$zoomMotor != ""} {
        move $zoomMotor to $zoom
        wait_for_devices sample_x sample_y sample_z gonio_phi $zoomMotor
    } else {
        wait_for_devices sample_x sample_y sample_z gonio_phi
    }
    set gridLabel [$groupName getGridLabel $id]
    log_note move to center of grid $gridLabel completed successfully.
}
proc gridGroupSetBeamCenter { group id } {

    set camera [$group getDefaultCamera]
    switch -exact -- $camera {
        sample {
            set centerX [getSampleCameraConstant zoomMaxXAxis]
            set centerY [getSampleCameraConstant zoomMaxYAxis]
        }
        inline {
            set centerX [getInlineCameraConstant zoomMaxXAxis]
            set centerY [getInlineCameraConstant zoomMaxYAxis]
        }
        visex {
            set centerX [getVisexCameraConstant center_x]
            set centerY [getVisexCameraConstant center_y]
        }
        default {
            log_error unknown camera: $camera
            return -code error NOT_SUPPORTED_CAMERA
        }
    }
    $group setGridBeamCenter $id $centerX $centerY

    return [list $centerX $centerY]
}
proc gridGroupDefaultGrid { args } {
    variable ::gridGroupConfig::user

    variable default_raster_user_setup
    variable latest_raster_user_setup
    puts "+gridGroupDefaultGrid"

    set latest_raster_user_setup $default_raster_user_setup

    set ll [llength $args]
    if {$ll < 2} {
        puts "-gridGroupDefaultGrid bad args"
        log_error defaultGrid need 2 parameters: \
        groupId gridId.
        return -code error UNSUFFICIENT_ARGS
    }
    foreach {groupNum id} $args break
    if {$groupNum >= 0 && $id >= 0} {
        set groupName [gridGroupConfig_load $groupNum 0]
        set label [$groupName getGridLabel $id]
        set param $default_raster_user_setup
        gridGroupReplaceUsernameAndGridLabelInDictionary param $user $label
        $groupName modifyGridUserInput $id $param
    }

    puts "-gridGroupDefaultGrid"
}
proc gridGroupUpdateGrid { args } {
    variable ::gridGroupConfig::user

    set param [gridGroupGenerateParam from_system_current]
    puts "updateGrid, param from_system_current={$param}"
    
    set ll [llength $args]
    if {$ll < 2} {
        puts "-gridGroupUpdateGridParameter"
        log_error defaultGrid need 2 parameters: \
        groupId gridId.
        return -code error UNSUFFICIENT_ARGS
    }
    foreach {groupNum id} $args break

    if {$groupNum >= 0 && $id >= 0} {
        set groupName [gridGroupConfig_load $groupNum 0]
        set label [$groupName getGridLabel $id]
        gridGroupReplaceUsernameAndGridLabelInDictionary param $user $label

        $groupName modifyGridParameter $id \
        $param
    } else {
        variable latest_raster_user_setup

        puts "only update latest"

        set latest_raster_user_setup [dict merge $latest_raster_user_setup $param]
    }

    puts "-gridGroupUpdateGridParameter"
}
proc gridGroupResetGrid { args } {
    puts "+gridGroupResetGrid"
    set ll [llength $args]
    if {$ll < 2} {
        log_error wrong argument for resetGrid
        return -code error UNSUFFICENT_ARGS
    }

    foreach {groupNum id} $args break

    set groupName [gridGroupConfig_load $groupNum 0]
    $groupName resetGrid $id
    puts "-gridGroupResetGrid"
}
proc gridGroupMoveOnGrid { args } {
    variable camera_view_phi
    variable gonio_omega

    set ll [llength $args]
    if {$ll < 5} {
        log_error on_grid_move need 5 parameters:
        group grid x y faceBeam
        return -code error UNSUFFICIENT_ARGS
    }
    foreach {grpId id ux uy faceBeam} $args break
    set groupName [gridGroupConfig_load $grpId 0]
    
    ## we need beam center to move to
    gridGroupSetBeamCenter $groupName $id

    set pos    [$groupName getOnGridMovePosition $id $ux $uy]
    set camera [$groupName getDefaultCamera]

    foreach {x y z a} $pos break
    set phiFaceBeam   [expr $a - $gonio_omega]
    set phiFaceCamera [expr $phiFaceBeam + $camera_view_phi($camera)]

    move sample_x to $x
    move sample_y to $y
    move sample_z to $z
    if {$faceBeam == "1"} {
        move gonio_phi to $phiFaceBeam
    } else {
        move gonio_phi to $phiFaceCamera
    }
    wait_for_devices sample_x sample_y sample_z gonio_phi
    set gridLabel [$groupName getGridLabel $id]
    log_note on grid move $ux $uy of grid $gridLabel completed \
    successfully.
}
proc gridGroupLoadL614SampleList { groupId id args } {
    set groupName [gridGroupConfig_load $groupId 0]

    $groupName loadL614SampleList $id $args

    log_note sample positions loaded, please check.
}
proc gridGroupReplaceUsernameAndGridLabelInDictionary { paramREF user label } {
    upvar $paramREF param

    set anyChange 0
    foreach name {directory prefix} {
        if {[dict exists $param $name]} {
            set value [dict get $param $name]
            if {$name == "directory"} {
                if {[checkUsernameInDirectory value $user]} {
                    dict set param $name $value
                    incr anyChange
                }
                set goodValue [TrimStringForRootDirectoryName $value]
                if {$goodValue != $value} {
                    dict set param $name $goodValue
                    incr anyChange
                }
            }
            set new_value [string map "GRID_LABEL $label" $value]
            if {$new_value != $value} {
                dict set param $name $new_value
                incr anyChange
            }
        }
    }
    return $anyChange
}
proc gridGroupUpdateL614SampleList { groupNum id } {
    variable crystalStatus
    set gridSampleLocation [lindex $crystalStatus 7]
    set locList [split $gridSampleLocation {, }]
    set goodList ""
    foreach loc $locList {
        set firstChar [string index $loc 0]
        set left      [string range $loc 1 end]
        switch -exact -- $firstChar {
            A -
            C -
            E {
                if {[string is integer -strict $left] \
                && $left > 0 && $left < 17} {
                    lappend goodList $loc
                }
            }
            B -
            D {
                if {[string is integer -strict $left] \
                && $left > 0 && $left < 16} {
                    lappend goodList $loc
                }
            }
            default {
            }
        }
    }
    if {$goodList == ""} {
        log_warning empty sample location list, setting skipped
        return
    }
    eval gridGroupLoadL614SampleList $groupNum $id $goodList
}
proc gridGroupChangeOver { } {
    global gMAXRASTERGROUP
    variable ::gridGroupConfig::dir
    variable ::gridGroupConfig::bid
    variable gridGroup_sum

    set gridGroup_sum "0 -1"

    for {set groupNum 0} {$groupNum < $gMAXRASTERGROUP} {incr groupNum} {
        variable gridGroup$groupNum
        if {[isString gridGroup$groupNum]} {
            set gridGroup$groupNum "inactive -1 not_exists"
        }
    }

    ### delete all the files.
    set pat ${bid}*
    set l [glob -directory $dir -types f -nocomplain $pat]
    if {$l != ""} {
        eval file delete -force $l
    }
}
proc gridGroupDismount { } {
    global gMAXRASTERGROUP

    for {set groupNum 0} {$groupNum < $gMAXRASTERGROUP} {incr groupNum} {
        variable gridGroup$groupNum
        if {[isString gridGroup$groupNum]} {
            set groupName [gridGroupConfig_load $groupNum 0]
            $groupName clearAll
        }
    }
}
