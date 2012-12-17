#package require Itcl
#namespace import ::itcl::*
package require DCSRaster

::DCS::Raster4DCSS gRaster4Config
set ::DCS::Raster4DCSS::PROC_RANGE_CHECK [code rasterRunsConfigSetupRangeCheck]

proc rasterRunsConfig_initialize {} {
    log_note "rasterRunsConfig_initialize"
    global gMAXRASTERRUN
    set gMAXRASTERRUN [::DCS::RasterBase::getMAXRUN]
    log_note "MAXRUN: $gMAXRASTERRUN"

    global gCurrentRasterNumber
    set gCurrentRasterNumber -1
    #copied from scan3DSetup
    namespace eval ::rasterRunsConfig {
        set cnt_snapshot0 0
        set cnt_snapshot1 0

        set dir [::config getStr "rasterRun.directory"]
        set bid [::config getConfigRootName]

        set image0 [file join $dir ${bid}_0.jpg]
        set image1 [file join $dir ${bid}_1.jpg]

        set handle0 ""
        set handle1 ""

        set info0 [list $image0 {0 0 0 0 0 0}]
        set info1 [list $image1 {0 0 0 0 0 0}]

        set user_setup_name_list [list \
        distance \
        beamstop \
        delta \
        time \
        time0 \
        time1 \
        is_default_time \
        skip0 \
        skip1 \
        ]

        #set time_index      [lsearch -exact $user_setup_name_list time]
        set isDefault_index [lsearch -exact $user_setup_name_list is_default_time]

        set needClearStatus 0

        puts "DONE init rasterRunsConfig"
    }

}
proc rasterRunsConfig_cleanup {} {
    variable ::rasterRunsConfig::needClearStatus
    variable raster_msg

    if {$needClearStatus} {
        set raster_msg [lreplace $raster_msg 0 0 0]
        set needClearStatus 0
    }
}
proc rasterRunsConfig_start { command args } {
    variable ::rasterRunsConfig::needClearStatus

    switch -exact -- $command {
        deleteAllRasters {
            set needClearStatus 1
            eval rasterRunsDeleteAllRasters $args
        }
        deleteRaster {
            set needClearStatus 1
            rasterRunsDeleteRaster [lindex $args 0]
        }
        resetRaster {
            set needClearStatus 1
            rasterRunsResetRaster [lindex $args 0]
        }
        addNewRaster {
            set needClearStatus 1
            return [eval rasterRunsAddNewRaster $args]
        }
        checkAllRasters {
            rasterRunsCheckRasterStatus [lindex $args 0]
        }
        resetUserSetupToDefault {
            eval rasterRunsResetUserSetupToDefault $args
        }
        setUserDefaultToSystemDefault {
            #### in collectRaster.tcl
            set_raster_user_setup_to_system_setup
        }
        updateUserSetup {
            eval rasterRunsUpdateUserSetup $args
        }
        setUserSetup {
            eval rasterRunsSetUserSetup $args
        }
        auto_set {
            set needClearStatus 1
            eval rasterRunsConfigAutoFillField $args
        }
        take_snapshot {
            set needClearStatus 1
            eval rasterRunsTakeSnapshot $args
        }
        define_view {
            eval rasterRunsDefineView $args
        }
        move_view {
            eval rasterRunsMoveView $args
        }
        clear_results {
            eval rasterRunsClearResults $args
        }
        flip_node {
            ### this is allowed even when collectRaster is running
            eval rasterRunsFlipNode $args
        }
        flip_view {
            eval rasterRunsFlipView $args
        }
        flip_single_view_mode {
            eval rasterRunsFlipSingleViewMode $args
        }
        move_view_to_camera {
            set needClearStatus 1
            eval rasterRunsMoveToView $args
        }
        move_view_to_beam {
            eval rasterRunsMoveToBeam $args
        }
        default {
            return -code error "wrong command: $command"
        }
    }
}

proc rasterRunsDeleteRaster { rasterNumber_ } {
    global gCurrentRasterNumber
    variable raster_runs

    puts "rasterRunsDeleteRaster $rasterNumber_"

    if {$rasterNumber_ == 0} {
        log_warning cannot delete raster0
        return
    }

    set runCount [lindex $raster_runs 0]
    if {$runCount < 1} {
        return
    }

    if {$rasterNumber_ < 0 || $rasterNumber_ > $runCount} {
        return
    }

    rasterRunsConfig_mustBeInactive $rasterNumber_

    ## remember it to remove its files at the end
    variable raster_run$rasterNumber_
    set raster_deleted [set raster_run$rasterNumber_]

    for {set i $rasterNumber_} {$i < $runCount} {incr i} {
        set next [expr $i + 1]
        variable raster_run$i
        variable raster_run$next

        set raster_run$i [set raster_run$next]
    }
    variable raster_run$runCount
    set raster_run$runCount [list inactive 0 not_exists]

    ###reduce the count
    set newCount [expr $runCount - 1]
    set currentRun $rasterNumber_
    if {$currentRun > $newCount} {
        incr currentRun -1
    }
    set raster_runs [lreplace $raster_runs 0 1 $newCount $currentRun]
    puts "done delete run"

    rasterRunsCheckRasterStatus $gCurrentRasterNumber

    rasterRuns_deleteRasterFiles $raster_deleted
}

## the arguments will decide what to do:
## no arguments: copy from last run.
## arguments: new run will be created from that position
## arguments:
## parent_raster (to copy user setup, -1 means not parent, use user default)
## inline (inline=collimator)
## x y z phi {optional width height} {optional depth}
## with only x y z and phi, it will move to that position and take snapshots
## with default width, height and depth.
## without depth, it will create single-view raster.
proc rasterRunsAddNewRaster { args } {
    global gCurrentRasterNumber
    global gMAXRASTERRUN
    variable raster_runs
    variable raster_msg
    variable cfgSampleMoveSerial
    variable ::rasterRunsConfig::bid
    variable ::rasterRunsConfig::dir

    set runCount [lindex $raster_runs 0]
    set newRunNumber [expr $runCount + 1]
    if {$newRunNumber >= $gMAXRASTERRUN} {
        log_error no spare raster place
        return -code error "reached max raster_runs"
    }

    puts "addNewRaster: current: $runCount new: $newRunNumber"

    ####copy the previous run and change the runLabel
    variable raster_run$runCount
    variable raster_run$newRunNumber
    set localContents [set raster_run$runCount]
    set previousLabel [lindex $localContents 1]
    set previousFile  [lindex $localContents 2]
    set newRunLabel [expr $previousLabel + 1]

    set newFile not_exists

    set ll [llength $args]
    set single_view 0

    switch -exact -- $ll {
        0 {
            if {$previousFile != "" && $previousFile != "not_exists"} {
                set previousPath [file join $dir $previousFile]
                if {[file readable $previousPath]} {
                    set newFile ${bid}_[getScrabbleForFilename].txt
                    set newPath [file join $dir $newFile]
                    file copy -force $previousPath $newPath
                    puts "addNewRaster: file copy s=$previousPath n=$newPath"
                    gRaster4Config load $newRunNumber $newPath
                    puts "addNewRaster: load file"
                    gRaster4Config clearResults 1
                    puts "addNewRaster: clear results"
                }
            }
            set newRunContents [list inactive $newRunLabel $newFile]
            set raster_run$newRunNumber $newRunContents
            set raster_runs \
            [lreplace $raster_runs 0 1 $newRunNumber $newRunNumber]
            rasterRunsCheckRasterStatus $gCurrentRasterNumber
            return $newRunNumber
        }
        1 -
        2 -
        3 -
        4 -
        5 {
            log_error addNewRaster needs at least 6 parameters: \
            parent inline x y z phi

            return -code error BAD_ARGS
        }
        6 {
            foreach { parent inline_camera x y z phi } $args break
            set use_collimator $inline_camera
            foreach {width height depth} \
            [rasterRunsConfigGetDefaultScanArea $use_collimator] break
        }
        7 {
            log_error addNewRaster did not support width only
            return -code error BAD_ARGS
        }
        8 {
            set single_view 1
            foreach { parent inline_camera x y z phi width height} $args break
            set depth $height
        }
        9 -
        default {
            foreach { parent inline_camera x y z phi width height depth} $args break
            if {$depth < 0} {
                set single_view 1
                set depth [expr -1 * $depth]
            }
        }
    }

    set raster_msg [lreplace $raster_msg 0 1 1 "moving to selected position"]
    ### move to the position and face the camera
    if {!$inline_camera} {
        set phi [expr $phi + 90]
    }
    if {$cfgSampleMoveSerial} {
        move sample_x to $x
        wait_for_devices sample_x
        move sample_y to $y
        wait_for_devices sample_y
        move sample_z to $z
        wait_for_devices sample_z
        move gonio_phi to $phi
        wait_for_devices gonio_phi
    } else {
        move sample_x to $x
        move sample_y to $y
        move sample_z to $z
        move gonio_phi to $phi
        wait_for_devices sample_x sample_y sample_z gonio_phi
    }

    ###copy parent run and change the runLabel
    puts "addNewRaster: parent=$parent"
    if {$parent >= 0} {
        if {[catch {
            puts "loading parent"
            rasterRunsConfig_loadRaster $parent 1
            set parentMicroBeam [gRaster4Config useCollimator]
            set parentUserSetup [gRaster4Config getUserSetup]
            if {$inline_camera} {
                set strName latest_raster_user_setup_micro
            } else {
                set strName latest_raster_user_setup_normal
            }
            variable $strName
            if {$inline_camera == $parentMicroBeam} {
                ### same micro beam or normal
                set $strName [gRaster4Config getUserSetup]
            } else {
                ### different, only copy distance and beamstop
                set localCopy [set $strName]
                set $strName \
                [collectRaster_copyUserSetupDistanceAndBeamstop \
                $localCopy $parentUserSetup]
                puts "copied parent distance and beamstop"
            }
        } errMsg]} {
            puts "load parent failed: $errMsg"
        }
    }
    #### create empty raster
    set newRunContents [list inactive $newRunLabel $newFile]
    set raster_run$newRunNumber $newRunContents

    ### prepare for takesnapshots
    rasterRunsAutoZoom $inline_camera $width $height $depth
    rasterRunsTakeSnapshot \
    $newRunNumber $inline_camera $width $height $depth $single_view

    puts "done take snapshots"
    set raster_runs [lreplace $raster_runs 0 1 $newRunNumber $newRunNumber]
    rasterRunsCheckRasterStatus $gCurrentRasterNumber

    return $newRunNumber
}

proc rasterRunsDeleteAllRasters { args } {
    global gMAXRASTERRUN
    variable raster_runs

    for {set i 0} {$i < $gMAXRASTERRUN} {incr i} {
        variable raster_run$i
        set raster_run$i [list inactive $i not_exists]
    }

    set raster_runs [lreplace $raster_runs 0 1 0 0]
    rasterRunsConfig_removeFiles 3
}

proc rasterRunsResetUserSetupToDefault { args } {
    variable latest_raster_user_setup_normal
    variable latest_raster_user_setup_micro

    set ll [llength $args]
    if {$ll < 1} {
        log_error need raster number to reset
        return -code error NEED_RASTERNUM
    }
    set rasterNum [lindex $args 0]
    rasterRunsConfig_mustBeInactive $rasterNum

    ### all fields changed
    foreach {defNormal defMicro} [get_default_raster_system_setup] break

    rasterRunsConfig_loadRaster $rasterNum
    puts "set both to default: $defNormal $defMicro"
    gRaster4Config setBothUserSetup $defNormal $defMicro

    set latest_raster_user_setup_normal $defNormal
    set latest_raster_user_setup_micro  $defMicro
}

proc rasterRunsUpdateUserSetup { args } {
    variable latest_raster_user_setup_normal
    variable latest_raster_user_setup_micro

    set ll [llength $args]
    if {$ll < 1} {
        log_error need raster number to update
        return -code error NEED_RASTERNUM
    }
    set rasterNum [lindex $args 0]
    rasterRunsConfig_mustBeInactive $rasterNum

    rasterRunsConfig_loadRaster $rasterNum
    foreach {setup_normal setup_micro} [gRaster4Config getBothUserSetup] break

    ### only 2 fields changed
    update_raster_user_setup setup_normal setup_micro
    gRaster4Config setBothUserSetup $setup_normal $setup_micro

    set latest_raster_user_setup_normal $setup_normal
    set latest_raster_user_setup_micro  $setup_micro
}

proc rasterRunsSetUserSetup { args } {
    variable latest_raster_user_setup_normal
    variable latest_raster_user_setup_micro

    variable ::rasterRunsConfig::user_setup_name_list
    variable ::rasterRunsConfig::isDefault_index

    set ll [llength $args]
    if {$ll < 3} {
        log_error need raster number, name and value to change setup
        return -code error NOT_ENOUGH_ARGS
    }
    set rasterNum [lindex $args 0]
    set name      [lindex $args 1]
    set value     [lindex $args 2]
    set index [lsearch -exact $user_setup_name_list $name]
    if {$index < 0} {
        log_error "bad name $name for raster user setup"
        return -code error BAD_NAME
    }

    rasterRunsConfig_mustBeInactive $rasterNum
    rasterRunsConfig_loadRaster $rasterNum
    set isCollimator [gRaster4Config useCollimator]
    set userSetup [gRaster4Config getUserSetup]

    switch -exact -- $name {
        time {
            if {$isCollimator} {
                set max_time [get_collect_raster_micro_constant timeMax]
                set min_time [get_collect_raster_micro_constant timeMin]
                set timeDef  [get_collect_raster_micro_constant timeDef]
            } else {
                set max_time [get_collect_raster_normal_constant timeMax]
                set min_time [get_collect_raster_normal_constant timeMin]
                set timeDef  [get_collect_raster_normal_constant timeDef]
            }

            if {$max_time < $min_time} {
                ###swap them
                set temp $max_time
                set max_time $min_time
                set min_time $temp
            }

            if {$value < $min_time} {
                set value $min_time
                log_warning exposure time to $value (minimum)
            }
            if {$value > $max_time} {
                set value $max_time
                log_warning exposure time to $value (maximum)
            }
            if {abs($value - $timeDef) < 0.001} {
                set isDefault 1
            } else {
                set isDefault 0
            }
        }
        delta {
            if {$value <0} {
                log_warning delta >= 0.0
                set value 1.0
            }
        }
        distance {
            global gMotorDistance
            adjustPositionToLimit $gMotorDistance value 1
        }
        beamstop {
            global gMotorBeamStop
            adjustPositionToLimit $gMotorBeamStop value 1
        }
    }

    set newSetup [lreplace $userSetup $index $index $value]
    if {$name == "time"} {
        set newSetup \
        [lreplace $newSetup $isDefault_index $isDefault_index $isDefault]
    }

    gRaster4Config setUserSetup $newSetup

    if {$isCollimator} {
        set latest_raster_user_setup_micro $newSetup

        set latest_raster_user_setup_normal \
        [collectRaster_copyUserSetupDistanceAndBeamstop \
        $latest_raster_user_setup_normal $newSetup]
    } else {
        set latest_raster_user_setup_normal $newSetup

        set latest_raster_user_setup_micro \
        [collectRaster_copyUserSetupDistanceAndBeamstop \
        $latest_raster_user_setup_micro $newSetup]
    }
}

proc rasterRunsClearResults { args } {
    set ll [llength $args]
    if {$ll < 1} {
        log_error need raster number to clear
        return -code error NEED_RASTERNUM
    }
    set rasterNum [lindex $args 0]

    rasterRunsConfig_loadRaster $rasterNum
    gRaster4Config clearResults
}

proc rasterRunsCheckRasterStatus { index_to_skip } {
    global gMAXRASTERRUN
    variable raster_runs

    set runCount [lindex $raster_runs 0]

    for {set i 0} {$i < $gMAXRASTERRUN} {incr i} {
        if {$i == $index_to_skip} {
            continue
        }
        variable raster_run$i
        set r [set raster_run$i]
        set status [lindex $r 0]
        if {$status == "collecting"} {
            set raster_run$i [lreplace $r 0 0 paused]
        }
    }
}
proc rasterRunsFlipNode { args } {
    global gCurrentRasterNumber
    variable ::rasterRunsConfig::dir

    set ll [llength $args]
    if {$ll < 4} {
        log_error flip node needs rasterNum view_index row column
        return -code error NOT_ENOUGH_INFO
    }

    foreach {rasterNum view_index row_index column_index} $args break

    if {$rasterNum == $gCurrentRasterNumber} {
        puts "flipping current running raster"
        global gRaster4Run
        if {$ll < 6} {
            gRaster4Run flip_node $view_index $row_index $column_index
        } else {
            set maskArgs [lrange $args 1 end]
            eval gRaster4Run automask $maskArgs
        }
        return
    }

    rasterRunsConfig_loadRaster $rasterNum
    if {$ll < 6} {
        gRaster4Config flip_node $view_index $row_index $column_index
    } else {
        set maskArgs [lrange $args 1 end]
        eval gRaster4Config automask $maskArgs
    }
}

proc rasterRuns_deleteRasterFiles { raster } {
    variable ::rasterRunsConfig::dir

    set raster_file [lindex $raster 2]
    if {$raster_file == "" || $raster_file == "not_exsits"} {
        return
    }

    set path [file join $dir $raster]
    file delete -force $path

    ### The snapshot files should NOT be deleted.
    ### They may be shared by more than one rasters.
    ### They are deleted by DeleteAllRasters.
}
proc rasterRunsConfig_loadRaster { rasterNum {silent 0} } {
    variable ::rasterRunsConfig::dir

    variable raster_run$rasterNum
    set file [lindex [set raster_run$rasterNum] 2]
    set path [file join $dir $file]

    puts "loading raster$rasterNum from $path"
    gRaster4Config load $rasterNum $path $silent
    puts "loading done"
}
proc rasterRunsConfig_mustBeInactive { rasterNum } {
    variable raster_run$rasterNum

    set rr [set raster_run$rasterNum]
    set status [lindex $rr 0]

    if {$status != "inactive"} {
        log_error raster must be resetted first.
        return -code error WRONG_RASTER_STATUS
    }
}

#### copied and modified from scan3DSetup
proc rasterRunsConfig_removeFiles { index } {
    variable ::rasterRunsConfig::dir
    variable ::rasterRunsConfig::bid

    switch -exact -- $index {
        0 {
            set pat ${bid}_0*.jpg
        }
        1 {
            set pat ${bid}_1*.jpg
        }
        default {
            ### this include the raster files
            set pat ${bid}*
        }
    }
    set l [glob -directory $dir -nocomplain $pat]
    if {$l != ""} {
        eval file delete -force $l
    }
}
proc rasterRunsConfig_increaseSnapshotCounter { index } {
    variable ::rasterRunsConfig::cnt_snapshot0
    variable ::rasterRunsConfig::cnt_snapshot1
    variable ::rasterRunsConfig::image0
    variable ::rasterRunsConfig::image1
    variable ::rasterRunsConfig::dir
    variable ::rasterRunsConfig::bid

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
proc rasterRunsConfig_getOrigFromVideoView { \
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

proc rasterRunsTakeSnapshot { args } {
    variable ::rasterRunsConfig::info0
    variable ::rasterRunsConfig::info1
    variable ::rasterRunsConfig::bid
    variable ::rasterRunsConfig::dir
    variable raster_runs
    variable raster_msg

    set ll [llength $args]

    set rasterNum  [lindex $args 0]
    set numRaster [lindex $raster_runs 0]

    ### ll >= 3 means it is called to create new raster
    if {$rasterNum < 0 || ( $ll < 3 && $rasterNum > $numRaster)} {
        log_error wrong raster index
        return -code error WRONG_RASTER
    }
    set inline [lindex $args 1]
    set use_collimator $inline
    ## default
    if {$ll >= 5} {
        set width  [lindex $args 2]
        set height [lindex $args 3]
        set depth  [lindex $args 4]
    } else {
        foreach {width height depth} \
        [rasterRunsConfigGetDefaultScanArea $use_collimator] break
    }
    set force_single_view 0
    if {$ll >= 6} {
        set force_single_view [lindex $args 5]
    }

    rasterRunsConfig_mustBeInactive $rasterNum

    variable raster_run$rasterNum

    set raster_msg [lreplace $raster_msg 0 1 1 "taking first snapshot"]
    set orig [rasterRunsConfig_getOrigFromVideoView $inline]
    rasterRunsConfig_takeFirstSnapshot $inline
    #result in info0

    set raster_msg [lreplace $raster_msg 0 1 1 "taking second snapshot"]
    move gonio_phi by 90
    wait_for_devices gonio_phi
    rasterRunsConfig_takeSecondSnapshot $inline
    #result in info1

    set raster_msg [lreplace $raster_msg 0 1 1 "restore phi"]
    move gonio_phi by -90
    wait_for_devices gonio_phi

    if {$inline != "1"} {
        set inline 0
        set use_collimator 0
        
        set centerX [getSampleCameraConstant zoomMaxXAxis]
        set centerY [getSampleCameraConstant zoomMaxYAxis]
    } else {
        set use_collimator 1

        set centerX [getInlineCameraConstant zoomMaxXAxis]
        set centerY [getInlineCameraConstant zoomMaxYAxis]
    }

    set newContents \
    [list 1 $orig $info0 $info1 $use_collimator \
    $width $height $depth 100 100 100 2 1 1 \
    $inline 0 0 0 0 $centerX $centerY $centerX $centerY]

    set newContents [rasterRunsConfigSetupRangeCheck $newContents 1]
    foreach {w h d} [lrange $newContents 5 7] break

    foreach {w h d} [rasterRunsConfig_decideSignForArea $newContents $w $h $d] break
    set newContents [lreplace $newContents 5 7 $w $h $d]
    set newFile ${bid}_[getScrabbleForFilename].txt
    set newPath [file join $dir $newFile]
    foreach {defNormal defMicro} [get_default_raster_user_setup] break

    ### ignore error
    catch { rasterRunsConfig_loadRaster $rasterNum 1 }

    #### decide defined ....
    set defined0 1
    set defined1 1

    if {$use_collimator} {
        set lastSingle [lindex $defMicro 10]
    } else {
        set lastSingle [lindex $defNormal 10]
    }

    if {$force_single_view \
    || [gRaster4Config isSingleView] \
    || $lastSingle == "1" \
    } {
        set defined1 0
        if {$use_collimator} {
            set defMicro  [lreplace $defMicro  10 10 1]
        } else {
            set defNormal [lreplace $defNormal 10 10 1]
        }
    }
    set newContents [lreplace $newContents 12 13 $defined0 $defined1]
    
    puts "contents after single=$newContents"
    puts "defNormal=$defNormal"

    gRaster4Config initialize $newPath $newContents $defNormal $defMicro

    set oldContents [set raster_run$rasterNum]
    set raster_run$rasterNum [lreplace $oldContents 2 2 $newFile]
}
proc rasterRunsDefineView { args } {
    foreach {rasterNum view_index sx0 sy0 sx1 sy1} $args break

    rasterRunsConfig_mustBeInactive $rasterNum

    rasterRunsConfig_loadRaster $rasterNum
    gRaster4Config defineArea $view_index $sx0 $sy0 $sx1 $sy1
}
proc rasterRunsMoveView { args } {
    foreach {rasterNum view_index direction} $args break

    rasterRunsConfig_mustBeInactive $rasterNum

    rasterRunsConfig_loadRaster $rasterNum
    puts "loaded now moveArea"
    gRaster4Config moveArea $view_index $direction
}
proc rasterRunsConfig_takeFirstSnapshot { inline } {
    variable ::rasterRunsConfig::image0
    variable ::rasterRunsConfig::handle0
    variable ::rasterRunsConfig::info0

    rasterRunsConfig_increaseSnapshotCounter 0
    if {$inline == "1"} {
        if {[isOperation inlineLightControl] && [isOperation lightsControl]} {
            if {[catch {
                if {[inlineLightControl_start insert]} {
                    log_warning wait for light to stable
                    wait_for_time 2000
                }
            } errMsg]} {
                log_error failed to insert inline light: $errMsg
            }
        }
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

    set orig [rasterRunsConfig_getOrigFromVideoView $inline]
    set info0 [list $image0 $orig]
    return $info0
}
proc rasterRunsConfig_takeSecondSnapshot { inline } {
    variable ::rasterRunsConfig::image1
    variable ::rasterRunsConfig::handle1
    variable ::rasterRunsConfig::info1

    rasterRunsConfig_increaseSnapshotCounter 1

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
    set orig [rasterRunsConfig_getOrigFromVideoView $inline]
    set info1 [list $image1 $orig]

    return $info1
}
proc rasterRunsConfig_decideSignForArea { info w h d } {
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
### handle loop center button
proc rasterRunsConfigAutoFillField { args } {
    variable raster_msg

    if {[llength $args] < 1} {
        log_error need raster number to auto fill
        return -code error MISSING_ARGS
    }

    set rasterNum [lindex $args 0]
    rasterRunsConfig_mustBeInactive $rasterNum

    if {[catch {
        set raster_msg [lreplace $raster_msg 0 1 1 "centering loop"]
        set handle [start_waitable_operation centerLoop]
        wait_for_operation_to_finish $handle
        rasterRunsConfig_getLoopSize width faceHeight edgeHeight 1
    } errMsg]} {
        log_error loop center failed: $errMsg
        return -code error $errMsg
    }

    set w [expr 1000.0 * $width]
    set h [expr 1000.0 * $faceHeight]
    set d [expr 1000.0 * $edgeHeight]
    rasterRunsTakeSnapshot $rasterNum 0 $w $h $d
}
proc rasterRunsConfig_getLoopSize { faceWRef faceHRef edgeHRef {no_log 0}} {
    variable save_loop_size
    variable raster_msg

    upvar $faceWRef faceWmm
    upvar $faceHRef faceHmm
    upvar $edgeHRef edgeHmm

    foreach {status loopWidth faceHeight edgeHeight} $save_loop_size break
    set loop_width_extra [get_collect_raster_constant loopW_extra]
    if {![string is double -strict $loop_width_extra]} {
        set loop_width_extra 0.0
    }
    set loop_height_extra [get_collect_raster_constant loopH_extra]
    if {![string is double -strict $loop_height_extra]} {
        set loop_height_extra 0.0
    }
    set faceWmm [expr $loopWidth + $loop_width_extra]
    set faceHmm [expr $faceHeight + $loop_height_extra]
    set edgeHmm [expr $edgeHeight + $loop_height_extra]

    if {$faceWmm < 0.001} {
        set faceWmm 0.001
    }
    if {$faceHmm < 0.001} {
        set faceHmm 0.001
    }
    if {$edgeHmm < 0.001} {
        set edgeHmm 0.001
    }
    
    if {!$no_log} {
        if {$widthScale != 1.0 || $heightScale != 1.0} {
            collectRaster_log [format "loop size adjusted to: %5.3f %5.3f %5.3f" \
            $faceWmm $faceHmm $edgeHmm]
        } else {
            collectRaster_log [format "loop size: %5.3f %5.3f %5.3f" \
            $faceWmm $faceHmm $edgeHmm]
        }
    }

    ###### move to the real loop center ######
    set dz [expr $loopWidth * 0.1]
    move sample_z by $dz
    wait_for_devices sample_z
    
    if {$faceWmm < 0.001 || $faceHmm < 0.001 || $edgeHmm < 0.001} {
        set raster_msg \
        [lreplace $raster_msg 0 1 1 "error: center loop failed to return size"]
        return -code error "loop center failed to return loop size"
    }
}
proc rasterRunsConfigGetDefaultScanArea { use_collimator } {
    save_collect_raster_data use_collimator $use_collimator

    set nw [get_collect_raster_constant colDef]
    set nh [get_collect_raster_constant rowDef]
    set nd $nh

    set row_height [expr 1000.0 * [get_collect_raster_constant rowHt]]
    set col_width  [expr 1000.0 * [get_collect_raster_constant colWd]]
    
    set w [expr $col_width * $nw]
    set h [expr $row_height * $nh]
    set d [expr $row_height * $nd]

    return [list $w $h $d ]
}
proc rasterRunsConfigSetupRangeCheck { contents_ {silent_ 0}} {
    set use_collimator [lindex $contents_ 4]

    ### this is required for get_collect_raster_constant to return right number
    save_collect_raster_data use_collimator $use_collimator

    set result $contents_

    set row_max    [get_collect_raster_constant rowMax]
    set row_min    [get_collect_raster_constant rowMin]
    set row_height [expr 1000.0 * [get_collect_raster_constant rowHt]]
    ## to micron

    set col_min    [get_collect_raster_constant colMin]
    set col_max    [get_collect_raster_constant colMax]
    set col_width  [expr 1000.0 * [get_collect_raster_constant colWd]]

    foreach {w h d} [lrange $contents_ 5 7] break

    foreach {new_w nw} [rasterRunsConfigDistanceAdjust \
    $w $col_width $col_min $col_max width $silent_] break

    foreach {new_h nh} [rasterRunsConfigDistanceAdjust \
    $h $row_height $row_min $row_max height $silent_] break

    foreach {new_d nd} [rasterRunsConfigDistanceAdjust \
    $d $row_height $row_min $row_max depth $silent_] break

    set sil_num_row [get_collect_raster_data sil_num_row]
    if {![string is integer -strict $sil_num_row] || $sil_num_row < 96} {
        set sil_num_row 400
    }

    if {$nw * $nh > $sil_num_row} {
        set nh [expr $sil_num_row / $nw]
        log_error MAX nodes $sil_num_row, number of points for height reduced to $nh
    }
    if {$nw * $nd > $sil_num_row} {
        set nd [expr $sil_num_row / $nw]
        log_error MAX nodes $sil_num_row, number of points for depth reduced to $nd
    }
    set result [lreplace $contents_ 5 10 $new_w $new_h $new_d $nw $nh $nd]
    return $result
}
proc rasterRunsConfigDistanceAdjust { \
distance \
step_size \
num_min \
num_max \
tag4log \
{silent_ 0} } {

    if {$distance == 0} {
        ### we need the sign of distance
        log_error distance cannot be 0
        return -code BAD_DISTANCE
    }

    set num_step [expr int(ceil(abs($distance) / double($step_size)))]
    if {$num_step > $num_max} {
        set num_step $num_max
    }
    if {$num_step < $num_min} {
        set num_step $num_min
    }
    if {$distance > 0} {
        set d_new [expr $num_step * $step_size]
    } else {
        set d_new [expr -$num_step * $step_size]
    }
    if {!$silent_} {
        if {$distance == 0 || (abs($distance - $d_new) / $distance) > 0.05} {
            log_warning $tag4log adjusted to $d_new from $distance because of step size
        }
    }
    return [list $d_new $num_step]
}
proc rasterRunsMoveToView { args } {
    variable gonio_omega

    set ll [llength $args]
    if {$ll < 2} {
        log_error need raster_run number and view_index
        return -code error BAD_ARGS
    }
    foreach {rasterNum view_index} $args break
    set onlyMovePhi 1
    if {$ll >= 3} {
        set onlyMovePhi [lindex $args 2]
    }

    rasterRunsConfig_loadRaster $rasterNum

    set inline [gRaster4Config isInline]
    set orig   [gRaster4Config getSnapshotCoordinates $view_index]
    foreach {x y z a} $orig break
    set phi [expr $a - $gonio_omega]
    if {!$inline} {
        set phi [expr $phi + 90]
    }

    if {$onlyMovePhi} {
        move gonio_phi to $phi
        wait_for_devices gonio_phi
        return
    }
    move sample_x to $x
    move sample_y to $y
    move sample_z to $z
    move gonio_phi to $phi
    wait_for_devices sample_x sample_y sample_z gonio_phi
}
proc rasterRunsResetRaster { rasterNum } {
    rasterRunsConfig_loadRaster $rasterNum

    gRaster4Config clearResults
    variable raster_run$rasterNum
    set old_contents [set raster_run$rasterNum]
    set new_contents [lreplace $old_contents 0 0 inactive]
    set raster_run$rasterNum $new_contents
}

proc rasterRunsFlipView { args } {

    set ll [llength $args]
    if {$ll < 2} {
        log_error flip view needs rasterNum view_index
        return -code error NOT_ENOUGH_INFO
    }
    foreach {rasterNum view_index} $args break

    rasterRunsConfig_mustBeInactive $rasterNum
    rasterRunsConfig_loadRaster $rasterNum

    gRaster4Config flip_view $view_index
}

proc rasterRunsFlipSingleViewMode { args } {
    variable latest_raster_user_setup_normal
    variable latest_raster_user_setup_micro

    set ll [llength $args]
    if {$ll < 1} {
        log_error flip single view mode needs rasterNum
        return -code error NOT_ENOUGH_INFO
    }
    set rasterNum [lindex $args 0]

    rasterRunsConfig_mustBeInactive $rasterNum
    rasterRunsConfig_loadRaster $rasterNum

    gRaster4Config flip_singleViewMode

    foreach {setup_normal setup_micro} [gRaster4Config getBothUserSetup] break
    set latest_raster_user_setup_normal $setup_normal
    set latest_raster_user_setup_micro  $setup_micro
}

proc rasterRunsMoveToBeam { args } {
    variable gonio_omega
    variable sample_x
    variable sample_y
    variable sample_z

    set ll [llength $args]
    if {$ll < 4} {
        log_error need raster_run_number, view_index, vertical, horz
        return -code error BAD_ARGS
    }
    foreach {rasterNum view_index vert horz} $args break

    #puts "rasterRunsMoveToBeam $args"

    rasterRunsConfig_loadRaster $rasterNum
    ### setup collimator if any
    if {[isOperation userCollimator]} {
        set microBeam [gRaster4Config useCollimator]
        if {$microBeam} {
            save_collect_raster_data use_collimator 1
            set collimator_index [get_collect_raster_constant collimator]
        } else {
            ### guard shield
            set collimator_index Normal
        }
        userCollimator_start $collimator_index
    }

    ### move
    set orig      [gRaster4Config getSetup $view_index]
    set a         [lindex $orig 3]
    set phi       [expr $a - $gonio_omega]

    #puts "orig=$orig"

    foreach {dx dy dz} [calculateSamplePositionDeltaFromProjection \
    $orig $sample_x $sample_y $sample_z $vert $horz] break

    #puts "dx=$dx dy=$dy dz=$dz"

    move sample_x by $dx
    move sample_y by $dy
    move sample_z by $dz
    move gonio_phi to $phi
    wait_for_devices sample_x sample_y sample_z gonio_phi
}
### assuming it is around center.
proc rasterRunsAutoZoom { inline w h d } {
    puts "rasterRunsAutoZoom"
    set w [expr abs($w)]
    set h [expr abs($h)]
    set d [expr abs($d)]
    set h [expr ($h>$d)?$h:$d]

    ## to mm
    set width  [expr $w / 1000.0]
    set height [expr $h / 1000.0]

    if {$inline} {
        getInlineViewSize vW vH

        set motorName inline_camera_zoom
        set calName   inlineView_calculate_zoom
    } else {
        getSampleViewSize vW vH

        set motorName camera_zoom
        set calName   sampleView_calculate_zoom
    }

    if {$vH == 0 || $vW == 0} {
        puts "wrong camera parameters, no auto zoom"
        return
    }

    set ratio [expr double($vW) / $vH]

    set wFromH [expr $height * $ratio]

    puts "auto zoom: w=$width w from h=$wFromH currentView w=$vW"

    if {$width < $wFromH} {
        set width $wFromH
    }

    #### decide whether we will adjust zoom:
    ## if raster > view, we will
    ## if raster < view * / 3.0 , we will.
    ## otherwise, we leave it alone

    if {$width > $vW / 3.0 && $width < $vW} {
        puts "no need to adjust zoom"
        return
    }

    log_warning adjust camera zoom to show raster

    ## some safe buffer
    set width [expr $width * 1.2]
    set zoom [$calName $width]
    if {$zoom < 0} {
        set zoom 0.0
    }
    if {$zoom > 1} {
        set zoom 1.0
    }
    adjustPositionToLimit $motorName zoom 1
    move $motorName to $zoom
    wait_for_devices $motorName
    log_warning zoom adjusted to $zoom
}
