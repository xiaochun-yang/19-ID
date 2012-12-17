#
#                        Copyright 2001
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
#                       Disclaimer Notice
#
#     The items furnished herewith were developed under the sponsorship
# of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
# Leland Stanford Junior University, nor their employees, makes any war-
# ranty, express or implied, or assumes any liability or responsibility
# for accuracy, completeness or usefulness of any information, apparatus,
# product or process disclosed, or represents that its use will not in-
# fringe privately-owned rights.  Mention of any product, its manufactur-
# er, or suppliers shall not, nor is it intended to, imply approval, dis-
# approval, or fitness for any particular use.  The U.S. and the Univer-
# sity at all times retain the right to use and disseminate the furnished
# items for any purpose whatsoever.                       Notice 91 02 01
#
#   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#

########################3
# string "grid_msg"
# similar to "collect_msg"
# field 0:   0 (idle), 1 (running)
# field 1:   text message of current status
# field 2:   steps (sub state)
# field 3:   beamlinsID
# field 4:   username
# field 5:   grid label
# field 6:   grid index

#package require Itcl
#namespace import ::itcl::*
#package require DCSConfig
#DCS::Config config
package require DCSGridGroupBase


::GridGroup::GridGroup4DCSS ::gGridGroup4Run

set collectGridDataNameList [list \
    log_file_name \
    sil_id \
    beam_width \
    beam_height \
    det_mode \
    image_ext \
    max_weight \
    max_index \
    user \
    sid \
] 

proc collectGrid_initialize { } {
    variable collect_grid_data_name_list
    variable collectGridDataNameList

    variable collectGrid_rowUniqueIDList

    set collectGrid_rowUniqueIDList [list]

    namespace eval ::collectGrid {
        global gBeamlineId
        set gridding_data ""
        set restore_cmd ""

        #### image will be put into queue first.
        #### then it will be put on spreadsheet to process.
        #### the spreadsheet will be used as a ring buffer.
        #### so, our number of nodes are unlimited.
        set imageQueue ""
        set spreadsheetNumRow 0
        set spreadsheetRow2Seq ""
        set spreadsheetStartRow 0

        set numImageSubmitted 0
        set numImageProcessed 0

        set myOwnFilePath ${gBeamlineId}_grid.save

        set pendingLogContents ""

        set groupNum -1
        set gridId -1
        set gridLabel ""
        set needCleanup 1

        set gridUserInput ""

        set gridIsL614 0
        set gridCamera inline

        set numSkipReceived 0
    }

    variable ::collectGrid::gridding_data

    set ll [llength $collectGridDataNameList]
    for {set i 0} {$i < $ll} {incr i} {
        lappend gridding_data $i
    }
    set collect_grid_data_name_list $collectGridDataNameList

    puts "init gridding_data to length =$ll"
}

#called at the end of operation
proc collectGrid_cleanup {} {
    variable ::collectGrid::groupNum
    variable ::collectGrid::gridId
    variable ::collectGrid::gridLabel
    variable ::collectGrid::needCleanup
    variable grid_msg

    if {$needCleanup} {
        set groupNum -1
        set gridId  -1
        set gridLabel ""

        set grid_msg [lreplace $grid_msg 0 0 0]
    }
}

#called when received stop operation message
proc collectGrid_stopCallback { } {
    variable ::collectGrid::numSkipReceived

    incr numSkipReceived
}

proc collectGrid_start { groupNum_ gridIndex_ args } {
    global gMotorBeamWidth
    global gMotorBeamHeight
    global gWaitForGoodBeamMsg

    variable ::collectGrid::pendingLogContents
    variable ::collectGrid::groupNum
    variable ::collectGrid::gridId
    variable ::collectGrid::gridLabel
    variable ::collectGrid::numSkipReceived
    variable ::collectGrid::needCleanup
    variable ::collectGrid::numImageSubmitted
    variable ::collectGrid::numImageProcessed
    variable ::collectGrid::gridIsL614
    variable ::collectGrid::gridCamera

    variable grid_msg
    variable beamlineID
    variable attenuation
    variable $gMotorBeamWidth
    variable $gMotorBeamHeight
    variable gonio_phi
    variable sample_x
    variable sample_y
    variable sample_z
    variable gridState

    set pendingLogContents ""
    set groupNum -1
    set gridId  -1
    set gridLabel ""
    set needCleanup 1
    set numImageSubmitted 0
    set numImageProcessed 0
    set gridIsL614 0
    set gridCamera inline

    if [catch {block_all_motors;unblock_all_motors} errMsg] {
        log_error $errMsg
        puts "MUST wait all motors stop moving to start rastering"
        log_error "MUST wait all motors stop moving to start rastering"
        return -code error "MUST wait all motors stop moving to start"
    }

    set fromCollectGridGroup [lindex $args 0]
    if {$fromCollectGridGroup == "1"} {
        set needCleanup 0
        set userName  [get_collect_grid_data user]
        set sessionID [get_collect_grid_data sid]
        puts "from group, using user=$userName sid=$sessionID"
    } else {
        set userName [get_operation_user]
        set sessionID PRIVATE[get_operation_SID]
        save_collect_grid_data user $userName
        save_collect_grid_data sid $sessionID
    }

    set needUserLog 0
    set needRun [collectGrid_populate $groupNum_ $gridIndex_  needUserLog]
    if {!$needRun} {
        return $gridIndex_
    }

    collectGrid_updateRun $groupNum collecting

    if {$needUserLog} {
        ### not called by collectRasters, but directy by BluIce
        collectGrid_setStatus "precheck motor"
        correctPreCheckMotors
        user_log_note raster "======$userName started grid$gridLabel ======"
    } else {
        user_log_note raster "======grid${gridLabel}======"
    }

    set gridName "grid$gridLabel"
    set grid_msg [lreplace $grid_msg 0 6 \
    1 Starting 0 $beamlineID $userName $gridName $gridIndex_]

    ##### if NOT allow pause and continue, use reset
    ######::gGridGroup4Run resetGrid
    ::gGridGroup4Run clearGridIntermediaResults $gridId

    set gWaitForGoodBeamMsg [list grid_msg 1]

    collectGrid_setStatus "prepare directory and files"

    set timeStart [clock seconds]

    set directory  [get_collect_grid_user_input directory]
    set filePrefix [get_collect_grid_user_input prefix]

    #set log_file_name [file join $directory ${filePrefix}_${filePostfix}.log]
    set log_file_name [file join $directory ${filePrefix}.log]
    save_collect_grid_data log_file_name $log_file_name
    set contents "$userName start crystal rastering\n"
    append contents "directory=$directory filePrefix=$filePrefix\n"
    append contents [format "orig beamsize: %5.3fX%5.3f phi: %8.3f\n" \
    [set $gMotorBeamWidth] [set $gMotorBeamHeight] $gonio_phi]

    puts "creating log file: user=$userName sid=$sessionID file=$log_file_name"

    if {[catch {
        impWriteFile $userName $sessionID $log_file_name $contents false
    } errMsg]} {
        set gWaitForGoodBeamMsg ""
        collectGrid_updateRun $groupNum paused
        collectGrid_setStatus "failed to create log file"
        user_log_error raster "create log file failed: $errMsg"
        if {$needUserLog} {
            user_log_note  raster "=======end grid${gridLabel}========"
        }
        return -code error $errMsg
    }
    user_log_note raster "log_file=$log_file_name"

    if {[catch {
        collectGrid_saveSnapshotsForUser $userName $sessionID $directory
    } errMsg]} {
        set gWaitForGoodBeamMsg ""
        collectGrid_updateRun $groupNum paused
        collectGrid_setStatus "failed to save snapshot files"
        user_log_error raster "save snapshot files for user failed: $errMsg"
        if {$needUserLog} {
            user_log_note  raster "=======end raster grid${gridLabel}========"
        }
        return -code error $errMsg
    }

    ##### save to restore after operation
    collectGrid_save4Restore

    ################catch everything##############
    # in case of any failure, restore
    # beam size and phi.
    # in case of total failure, sample_x, y z
    # will be restored.
    ##############################################

    set result "success"
    if {[catch {
        clear_operation_stop_flag
        set numSkipReceived 0

        ###do not delete until check tight up in sil.
        ###collectGrid_deleteDefaultSil

        collectGrid_setStatus "prepare special spreadsheet"
        collectGrid_createDefaultSil
 
        ### skip once still need this but skip twice will not need this anymore
        collectGrid_setStatus "setup beam"
        collectGrid_setupEnvironments

        puts "run......."
        collectGrid_run $userName $sessionID
        collectGrid_log "manual scan successed"
    } errMsg] == 1} {
        if {$errMsg != ""} {
            set result $errMsg
            log_warning "crystal rastering failed: $errMsg"
            collectGrid_log "crystal rastering failed: $result"
            collectGrid_setStatus "error: $result"
        }
    }

    if {$needUserLog} {
        collectGrid_saveGridGroupForUser
    }
    collectGrid_deleteDefaultSil

    start_recovery_operation detector_stop

    if {[catch {
        if {!$gridIsL614} {
            collectGrid_restore
        }
    } errMsg]} {
        ### most likely, aborted already
        puts "collectGrid_restore failed: $errMsg"
    }

    collectGrid_log "end of crystal rastering"

    set timeEnd [clock seconds]

    set timeUsed [expr $timeEnd - $timeStart]
    set timeUsedText [secondToTimespan $timeUsed]
    collectGrid_log "time used: $timeUsedText ($timeUsed seconds)" 1 1
    user_log_note raster "time used: $timeUsedText ($timeUsed seconds)"

    collectGrid_logData

    ### this may move some motors, like collimator, beamstop, lights
    if {$needUserLog} {
        cleanupAfterAll
    }
    set gWaitForGoodBeamMsg ""

    if {$result != "success"} {
        if {[::gGridGroup4Run getGridNumImageDone $gridId] == 0} {
            collectGrid_updateRun $groupNum inactive
        } else {
            collectGrid_updateRun $groupNum paused
        }
        user_log_error raster "raster failed: $result"
        if {$needUserLog} {
            user_log_note  raster "=======end raster grid${gridLabel}========"
        }
        collectGrid_setStatus "failed: $result"
        return -code error $result
    }
    if {$needUserLog} {
        user_log_note  raster "=======end raster grid${gridLabel}========"
    }
    if {[::gGridGroup4Run getGridNumImageNeed $gridId] == 0} {
        collectGrid_updateRun $groupNum complete
        collectGrid_setStatus "grid$gridLabel complete"
        collectGrid_setGridStatus complete
    } elseif {[::gGridGroup4Run getGridNumImageDone $gridId] == 0} {
        collectGrid_updateRun $groupNum inactive
        collectGrid_setStatus "grid$gridLabel no touch"
        collectGrid_setGridStatus setup
    } else {
        collectGrid_updateRun $groupNum skipped
        collectGrid_setStatus "grid$gridLabel skipped"
        #collectGrid_updateRun $groupNum paused
        collectGrid_setGridStatus paused
    }
    return $result
}

proc checkGridUserSetup { gridId gridLabel preCheck } {
    variable ::collectGrid::gridUserInput
    variable ::collectGrid::gridIsL614
    global gMotorDistance
    global gMotorBeamStop
    global gMotorBeamWidth
    global gMotorBeamHeight

    set userName  [get_collect_grid_data user]
    set sessionID [get_collect_grid_data sid]

    set gridStatus [::gGridGroup4Run getGridStatus $gridId]
    if {$gridStatus == "compelte" || $gridStatus == "disabled"} {
        if {$preCheck} {
            return 1
        }
        puts "grid already complete or disabled"
        return 0
    }

    set gridUserInput [::gGridGroup4Run getGridUserInput $gridId]

    set collimator [dict get $gridUserInput collimator]
    set useCollimator [lindex $collimator 0]
    set anyError 0
    dict for {name value} $gridUserInput {
        switch -exact -- $name {
            directory {
                if {[catch {
                    checkCollectDirectoryAllowed $value
                    impDirectoryWritable $userName $sessionID $value
                } errMsg]} {
                    log_error grid$gridLabel check directory $value \
                    failed: $errMsg
                    incr anyError
                }
            }
            distance {
                if {[adjustPositionToLimit $gMotorDistance value 1]} {
                    log_error grid$gridLabel detector distance setting bad
                    incr anyError
                }
            }
            attenuation {
                if {[adjustPositionToLimit attenuation value 1]} {
                    log_error grid$gridLabel attenuation setting bad
                    incr anyError
                }
            }
            beam_width {
                ### from micron to mm
                set ww [expr $value / 1000.0]
                if {!$gridIsL614 && !$useCollimator \
                && [adjustPositionToLimit $gMotorBeamWidth ww 1]} {
                    log_error grid$gridLabel beam width setting bad
                    incr anyError
                }
            }
            beam_height {
                set hh [expr $value / 1000.0]
                if {!$gridIsL614 && !$useCollimator \
                && [adjustPositionToLimit $gMotorBeamHeight hh 1]} {
                    log_error grid$gridLabel beam height setting bad
                    incr anyError
                }
            }
            beam_stop {
                if {[adjustPositionToLimit $gMotorBeamStop value 1]} {
                    log_error grid$gridLabel beam stop setting bad
                    incr anyError
                }
            }
        }
    }

    if {$preCheck} {
        ### clear input to force error if some logical wrong.
        ### Otherwise, it will just use last one.
        set gridUserInput ""
    }

    if {$anyError} {
        puts "got some error"
        return 0
    }
    return 1
}
proc collectGrid_populate { groupNum_ startIndex_ need_user_logREF_ \
{forGroup_ 0} } {
    upvar $need_user_logREF_ needUserLog

    variable ::gridGroupConfig::dir
    variable ::collectGrid::groupNum
    variable ::collectGrid::gridId
    variable ::collectGrid::gridLabel
    variable ::collectGrid::gridIsL614
    variable ::collectGrid::gridCamera

    set groupNum $groupNum_

    variable gridGroup$groupNum
    set file [lindex [set gridGroup$groupNum] 2]
    set path [file join $dir $file]
    ::gGridGroup4Run load $groupNum $path

    set gridList [::gGridGroup4Run getGridList]
    foreach grid $gridList {
        if {[$grid getStatus] == "collecting"} {
            set gridId [$grid getId]
            ### do not use grid object to change, must go through group.
            ::gGridGroup4Run setGridStatus $gridId "paused"
        }
    }

    if {$forGroup_} {
        set gridList [lrange $gridList $startIndex_ end]
    } else {
        set gridList [lindex $gridList $startIndex_]
        set grid $gridList
        if {$grid == ""} {
            log_error no grid found for that index.
            return -code error NO_GRID_FOUND
        }
    }

    set needUserLog 0
    set allOK 1
    foreach grid $gridList {
        switch -exact -- [$grid getCamera] {
            inline {
                set centerX [getInlineCameraConstant zoomMaxXAxis]
                set centerY [getInlineCameraConstant zoomMaxYAxis]
            }
            sample {
                set centerX [getSampleCameraConstant zoomMaxXAxis]
                set centerY [getSampleCameraConstant zoomMaxYAxis]
            }
            visex {
                set centerX [getVisexCameraConstant center_x]
                set centerY [getVisexCameraConstant center_y]
            }
            default {
                log_severe unsupported camera=[$grid getCamera]
                set centerX 0.5
                set centerY 0.5
            }
        }
        ### in collectGrid, there will be only one grid, so it is OK here:
        set gridId     [$grid getId]
        set gridLabel  [$grid getLabel]
        if {[$grid getShape] == "l614"} {
            set gridIsL614 1
        }
        set gridCamera [$grid getCamera]
        ::gGridGroup4Run setGridBeamCenter $gridId $centerX $centerY
        set precheckOK [collectGrid_checkGrid $gridId $gridLabel \
        needUserLog $forGroup_]
        if {!$precheckOK} {
            set allOK 0
        }
    }
    if {!$allOK} {
        if {!$forGroup_} {
            return 0
        }
        log_error please correct above errors first
        return -code error gridDefinitionWrong
    }
    return 1
}

proc collectGrid_checkGrid { gridId gridLabel \
need_user_logREF {preCheck 0} } {
    puts "calling checkGrid"
    upvar $need_user_logREF needUserLog

	global gClient
	global gPauseDataCollection
    variable grid_msg

    puts "calling checkGridUserSetup"
    if {![checkGridUserSetup $gridId $gridLabel $preCheck]} {
        puts "checkGridUserSetup return 0, skip"
        return 0
    }

    if {$preCheck} {
        return 1
    }

	#find out the operation handle
	set op_info [get_operation_info]
    set op_name [lindex $op_info 0]
	set operationHandle [lindex $op_info 1]

	#find out the client id that started this operation
	set clientId [expr int($operationHandle)]
	#get the name of the user that started this operation
	set clientUserName $gClient($clientId)

    if {$clientUserName != "self"} {
        set needUserLog 1
		set gPauseDataCollection 0
    }

	#Stop data collection now if we have already been paused.
	if {$gPauseDataCollection } {
		error paused
    }

    if {[::gGridGroup4Run getGridNumImageNeed $gridId] <= 0} {
        ::gGridGroup4Run setGridStatus $gridId complete
        puts "no image needed"
        return 0
    }

    return 1
}
proc collectGrid_setupEnvironments { } {
    global gMotorBeamWidth
    global gMotorBeamHeight
    global gMotorBeamStop
    global gMotorDistance
	global gPauseDataCollection
    variable ::collectGrid::numSkipReceived
    variable ::collectGrid::gridIsL614

    variable user_collimator_status

	if {$gPauseDataCollection} {
		error paused
    }

    collectGrid_lightOut

    set movingList ""
    set collimator [get_collect_grid_user_input collimator]
    set use_collimator [lindex $collimator 0]

    if {$use_collimator} {
        set user_collimator_status $collimator
        foreach {micro index bw bh} $collimator break
        if {!$gridIsL614} {
            set newInfo [collimatorMove_start $index]
            foreach {- realShow realMicro realBw realBh } $newInfo break
            if {!$realShow || !$realMicro} {
                log_severe gridGroup collimator config wrong: \
                selected hidden or non-microbeam index
                log_severe DEBUG: index=$index collimatorInfo=$newInfo
            }
            if {abs($bw - $realBw) > 1 || abs($bh - $realBh) > 1} {
                log_warning current collimator index=$index has \
                bw=$realBw bh=$realBh not the same as bw=$bw bh=$bh
            }
        }
    } else {
        collectGrid_log "use normal beam"
        if {[isOperation collimatorMove]} {
            collimatorNormalIn
        }
        set bw [get_collect_grid_user_input beam_width]
        set bh [get_collect_grid_user_input beam_height]
        set bw [expr $bw / 1000.0]
        set bh [expr $bh / 1000.0]
        if {!$gridIsL614} {
            move $gMotorBeamWidth  to $bw
            move $gMotorBeamHeight to $bh
            lappend movingList $gMotorBeamWidth $gMotorBeamHeight
        }
    }
    save_collect_grid_data beam_width $bw
    save_collect_grid_data beam_height $bh

    #### may add beam stop later
    set distance [get_collect_grid_user_input distance]
    if {$numSkipReceived < 1} {
        move $gMotorDistance to $distance
        lappend movingList $gMotorDistance
    }
    if {![catch {get_collect_grid_user_input beam_stop} beamStop]} {
        if {$numSkipReceived < 1} {
            move $gMotorBeamStop to $beamStop
            lappend movingList $gMotorBeamStop
        }
    }

    if {!$gridIsL614} {
        set att [get_collect_grid_user_input attenuation]
        if {$numSkipReceived < 1} {
            move attenuation to $att
            lappend movingList attenuation
        }
    }
    if {$numSkipReceived < 1} {
        collectGrid_setStatus "prepare $movingList"
    } else {
        collectGrid_setStatus "stopping $movingList"
    }
    if {$movingList != ""} {
        eval wait_for_devices $movingList
    }
    if {$numSkipReceived > 0} {
        return -code error "skipped by user"
    }
	if {$gPauseDataCollection} {
		error paused
    }
}
proc collectGrid_run { user sessionID } {
	global gPauseDataCollection

    variable ::collectGrid::numSkipReceived
    variable ::collectGrid::gridId
    variable ::collectGrid::gridLabel
    variable ::collectGrid::gridIsL614

    variable energy

    if {$gPauseDataCollection} {
        error paused
    }
    if {$numSkipReceived > 0} {
        return -code error "skipped by user"
    }


    set energyUsed [::gGridGroup4Run getGridEnergyUsed $gridId]
    if {$energyUsed > 0 && abs($energyUsed - $energy) > 10.0} {
        log_error energy changed from last run $energyUsed eV
        return -code error SETUP_CHANGED

    }

    puts "doTask"
    if {$gridIsL614} {
        collectGrid_doL614Task $user $sessionID 
    } else {
        collectGrid_doTask $user $sessionID 
    }
    if {$numSkipReceived > 0} {
        collectGrid_setGridStatus skipped
        user_log_error raster \
        "----------------grid$gridLabel skipped by user------------------"
        log_warning skip current grid 
    }
}
proc collectGrid_processImageQueue { } {
    variable ::collectGrid::imageQueue
    variable ::collectGrid::spreadsheetNumRow
    variable ::collectGrid::spreadsheetRow2Seq
    variable ::collectGrid::spreadsheetStartRow

    puts "processImageQueue"

    if {$imageQueue == ""} {
        puts "image queueu is empty"
        return 0
    }

    while {$imageQueue != ""} {
        ### find an idle row starting from StartRow
        set idleRow -1
        for {set i 0} {$i < $spreadsheetNumRow} {incr i} {
            set row [expr ($spreadsheetStartRow + $i) % $spreadsheetNumRow]
            set seq [lindex $spreadsheetRow2Seq $row]
            if {$seq < 0} {
                set idleRow $row
                set spreadsheetStartRow \
                [expr ($spreadsheetStartRow + 1) % $spreadsheetNumRow]
                break
            }
        }
        if {$idleRow < 0} {
            puts "all spreadsheet rows are taken"
            return 1
        }
        set head [lindex $imageQueue 0]
        foreach {seq path} $head break
        if {[catch {
            collectGrid_submitImageForAnalysis $idleRow $path
        } errMsg]} {
            log_error failed to submit $path: $errMsg
            return 1
        }
        ### OK submitted.
        puts "submitted $head"
        set spreadsheetRow2Seq [lreplace $spreadsheetRow2Seq \
        $idleRow $idleRow $seq]

        set imageQueue [lrange $imageQueue 1 end]
    }
    puts "whole queue processed"
    return 0
}
proc collectGrid_addImageToQueue { seq directory fileroot } {
    variable ::collectGrid::imageQueue
    variable ::collectGrid::numImageSubmitted

    puts "addImageToQueue: $fileroot"

    set fullPath [file join $directory \
    ${fileroot}.[get_collect_grid_data image_ext]]

    lappend imageQueue [list $seq $fullPath]
    incr numImageSubmitted
    puts "after add: currentQueue: {$imageQueue}"
}
proc collectGrid_doTask { user sessionID } {
	global gPauseDataCollection

    variable ::collectGrid::spreadsheetRow2Seq
    variable ::collectGrid::numSkipReceived
    variable ::collectGrid::gridId
    variable ::collectGrid::gridLabel

    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega
    variable energy
    variable attenuation

    if {$gPauseDataCollection} {
        error paused
    }

    ###########no motor should be moving
    error_if_moving \
    sample_x \
    sample_y \
    sample_z \
    gonio_phi \
    gonio_omega

    if {$numSkipReceived > 0} {
        return 0
    }
    
    ###retrieve collect image parameters
    set exposeTime [get_collect_grid_user_input time]
    set delta      [get_collect_grid_user_input delta]
    set modeIndex  [collectGrid_getDetectorMode $exposeTime]
    set ext        [getDetectorFileExt $modeIndex]
    ::gGridGroup4Run setDetectorModeAndFileExt $gridId $modeIndex $ext

    save_collect_grid_data det_mode  $modeIndex
    save_collect_grid_data image_ext $ext
    puts "set image_ext to $ext"

    collectGrid_log "Exposure time: $exposeTime"

    if {$numSkipReceived > 0} {
        return 0
    }

    set ulog_contents [format "Exposure: (time=%.3f s attenuation=%.1f %%)" \
    $exposeTime $attenuation]
    user_log_note raster $ulog_contents

    set log "filename                  phi    omega        x        y        z  bm_x  bm_y" 
    collectGrid_log $log
    user_log_note raster $log

    collectGrid_clearSpreadsheet

    if {$numSkipReceived > 0} {
        return 0
    }

    collectGrid_checkNotProcessedImages
    puts "done resubmit images collected before"

    set next_seq -1
    collectGrid_setGridStatus rastering
    while {1} {
        if {$gPauseDataCollection} {
            collectGrid_setGridStatus paused
            error paused
        }

        if {$numSkipReceived > 0} {
            break
        }
        set next_seq [collectGrid_getNextNode $next_seq]
        if {$next_seq < 0} {
            collectGrid_log "This raster all done"
            break
        }
        set nodeInfo [::gGridGroup4Run getGridNodePosition $gridId $next_seq]
        set nodeLabel ""
        foreach {x y z a row_index col_index nodeLabel} $nodeInfo break
        set orig_phi [expr $a - $gonio_omega]

        puts "moving to position"
        #######move to position
        move sample_x to $x
        move sample_y to $y
        move sample_z to $z
        move gonio_phi to $orig_phi
        wait_for_devices sample_x sample_y sample_z gonio_phi

        ::gGridGroup4Run setGridNodeStatusBySequence $gridId $next_seq X

        ###prepare filename for collect image
        set directory [get_collect_grid_user_input directory]
        set prefix    [get_collect_grid_user_input prefix]
        if {$nodeLabel == ""} {
            set fileroot ${prefix}_[expr $next_seq + 1]
        } else {
            set fileroot ${prefix}_$nodeLabel
        }

        set reuseDark 0 
        set operationHandle [start_waitable_operation collectFrame \
                                     0 \
                                     $fileroot \
                                     $directory \
                                     $user \
                                     gonio_phi \
                                     shutter \
                                     $delta \
                                     $exposeTime \
                                     $modeIndex \
                                     0 \
                                     $reuseDark \
                                     $sessionID]

        if {[catch {
            wait_for_operation $operationHandle
        } detErrMsg]} {
            log_error detector error $detErrMsg
            return -code error "Detector error: $detErrMsg"
        }
        set log_contents \
        [format "%-20s %8.3f %8.3f %8.3f %8.3f %8.3f %5.3f %5.3f" \
        $fileroot \
        $orig_phi $gonio_omega \
        $sample_x $sample_y $sample_z \
        [get_collect_grid_data beam_width] \
        [get_collect_grid_data beam_height] \
        ]

        collectGrid_log $log_contents
        user_log_note raster $log_contents
            
        set processing [get_collect_grid_user_input processing]
        if {$processing} {
            if {[catch {
                collectGrid_addImageToQueue $next_seq $directory $fileroot
                collectGrid_processImageQueue
            } errMsg]} {
                log_warning submit image failed: $errMsg
                user_log_warning failed to submit $fileroot: $errMsg
            }
        }

        ::gGridGroup4Run setGridNodeStatusBySequence $gridId $next_seq D

        collectGrid_checkImage $user $sessionID
    }
    ### need this to flush out last image
    start_operation detector_stop

    ####restore position

    if {$numSkipReceived == 0} {
        collectGrid_setStatus "grid$gridLabel wait for results"
        collectGrid_setGridStatus waiting_for_result
        collectGrid_waitForAllImage $user $sessionID
    }
    ###DEBUG
    #collectGrid_logData

    collectGrid_log "result matrix"
    user_log_note raster "Matrix of Spots"
    collectGrid_logWeight "%8d" "%8s"

    if {$numSkipReceived > 0} {
        collectGrid_setStatus "grid$gridLabel skipped"
        return 0
    }

    collectGrid_setStatus "grid$gridLabel complete"
    collectGrid_setGridStatus complete
    user_log_note raster \
    "--------------------grid$gridLabel complete------------------------------"
    return 1
}
proc collectGrid_checkImage { user sessionID } {
    variable ::collectGrid::spreadsheetRow2Seq

    set sil_id [get_collect_grid_data sil_id]
    set numList [getNumSpotsData $user $sessionID $sil_id]
    puts "numList: $numList"

    collectGrid_distributeResult $numList
}

proc collectGrid_waitForAllImage { user sessionID } {
	global gPauseDataCollection

    variable ::collectGrid::spreadsheetRow2Seq
    variable ::collectGrid::numSkipReceived
    variable ::collectGrid::numImageSubmitted
    variable ::collectGrid::numImageProcessed
    variable ::collectGrid::imageQueue
    variable ::collectGrid::gridId

    collectGrid_checkImage $user $sessionID
    if {$numImageProcessed > 0} {
        log_warning got $numImageProcessed of $numImageSubmitted
    }

    set previous_ll $numImageProcessed
    while {$numImageProcessed < $numImageSubmitted} {
	    if {$gPauseDataCollection } {
            collectGrid_setGridStatus paused
		    error paused
        }
        if {$numSkipReceived} {
            log_error skipped by user
            return
        }
        if {$imageQueue != ""} {
            collectGrid_processImageQueue
        }
        wait_for_time 1000
        if {[catch {
            collectGrid_checkImage $user $sessionID
        } err]} {
            log_warning failed to wait for all data: $err
            break
        }
        if {$numImageProcessed > $previous_ll} {
            log_warning got $numImageProcessed of $numImageSubmitted
            set previous_ll $numImageProcessed
        }
        ### in case the numbers are not right:
        if {$imageQueue == ""} {
            set allDone 1
            foreach seq $spreadsheetRow2Seq {
                if {$seq >= 0} {
                    set allDone 0
                }
            }
            if {$allDone} {
                puts "DEBUG cannot find any image to process"
                puts \
                "DEBUG but only got $numImageProcessed of $numImageSubmitted"
                break
            }
        }
    }
}
proc collectGrid_distributeResult { compactResults } {
    variable ::collectGrid::spreadsheetRow2Seq
    variable ::collectGrid::gridId
    variable ::collectGrid::numImageProcessed

    puts "distribute results: map: $spreadsheetRow2Seq result: $compactResults"
    set ll0 [llength $compactResults]
    set ll1 [llength $spreadsheetRow2Seq]

    set ll [expr ($ll0>$ll1)?$ll1:$ll0]

    for {set i 0} {$i < $ll} {incr i} {
        set seq [lindex $spreadsheetRow2Seq  $i]
        if {$seq < 0} {
            ### not used row or already distributed row.
            if {$seq == -2} {
                if {[catch {
                    collectGrid_clearSpreadsheetOneRow $i
                } errMsg]} {
                    log_warning still failed to clear spreadsheet row: $errMsg
                } else {
                    set spreadsheetRow2Seq \
                    [lreplace $spreadsheetRow2Seq $i $i -1]
                }
            }
            continue
        }
        set value [lindex $compactResults $i]
        set first [lindex $value 0]
        if {$first < 0} {
            continue
        }

        ::gGridGroup4Run setGridNodeStatusBySequence $gridId \
        $seq $value
        incr numImageProcessed

        ### clean up that row, mark for reuse.
        if {[catch {
            collectGrid_clearSpreadsheetOneRow $i
        } errMsg]} {
            log_warning failed to clear spreadsheet row: $errMsg
        } else {
            set spreadsheetRow2Seq [lreplace $spreadsheetRow2Seq $i $i -2]
        }
    }
}
### skipped, complete, failed will trigger draw contours
proc collectGrid_setGridStatus { state } {
    variable ::collectGrid::gridId
    ::gGridGroup4Run setGridStatus $gridId $state
}
proc collectGrid_clearSpreadsheet { } {
    set user [get_collect_grid_data user]
    set sessionID [get_collect_grid_data sid]
    set sil_id [get_collect_grid_data sil_id]
    resetSpreadsheet $user $sessionID $sil_id
}
proc collectGrid_deleteDefaultSil { } {
    set user [get_collect_grid_data user]
    set sessionID [get_collect_grid_data sid]
    ###try to delete the previous SIL, may belong to another user
    set sil_id [get_collect_grid_data sil_id]
    if {[string is integer -strict $sil_id] && $sil_id > 0} {
        if {[catch {
            deleteSil $user $sessionID $sil_id
            save_collect_grid_data sil_id 0
        } errMsg]} {
            puts "failed to delete SIL $sil_id: $errMsg"
        }
    }
}
proc collectGrid_createDefaultSil { } {
    variable ::collectGrid::spreadsheetNumRow
    variable ::collectGrid::spreadsheetRow2Seq
    variable ::collectGrid::spreadsheetStartRow
    variable collectGrid_rowUniqueIDList

    ####create new sil and save the id to the string
    set user [get_collect_grid_data user]
    set sessionID [get_collect_grid_data sid]
    set sil_id [createDefaultSil $user $sessionID \
    "&templateName=crystal_centering&containerType=crystal_centering"]
    puts "new sil_id: $sil_id"

    if {![string is integer -strict $sil_id] || $sil_id < 0} {
        return -code error "create default sil failed: sil_id: $sil_id not > 0"
    }

    ### get uniqueID for each row
    if {[catch {
        set collectGrid_rowUniqueIDList [getSpreadsheetProperty \
        $user $sessionID $sil_id UniqueID]
    } errMsg]} {
        set collectGrid_rowUniqueIDList [list]
        log_error failed to get uniqueIDList: $errMsg
    }

    save_collect_grid_data sil_id $sil_id

    set spreadsheetNumRow [llength $collectGrid_rowUniqueIDList]
    set spreadsheetRow2Seq [string repeat "-1 " $spreadsheetNumRow]
    set spreadsheetStartRow 0
}
proc get_collect_grid_data { name } {
    variable ::collectGrid::gridding_data

    set index [collectGrid_dataNameToIndex $name]
    return [lindex $gridding_data $index]
}

proc save_collect_grid_data { name value } {
    variable ::collectGrid::gridding_data

    set index [collectGrid_dataNameToIndex $name]
    set gridding_data [lreplace $gridding_data $index $index $value]
}

proc collectGrid_dataNameToIndex { name } {
    variable collect_grid_data_name_list
    variable ::collectGrid::gridding_data

    if {![info exists gridding_data]} {
        return -code error "string not exists: gridding_data"
    }

    set index [lsearch -exact $collect_grid_data_name_list $name]
    if {$index < 0} {
        puts "DataNameToIndex failed name=$name list=$collect_grid_data_name_list"
        return -code error "data bad name: $name"
    }

    if {[llength $gridding_data] <= $index} {
        return -code error "bad contents of string gridding_data"
    }
    return $index
}
proc collectGrid_saveSnapshotsForUser { user SID directory } {
    set fileList [::gGridGroup4Run getSnapshotFileList]

    foreach file $fileList {
        set f0 [file tail $file]
        set p0 [file join $directory $f0]
        impCopyFile $user $SID $file $p0
    }
}
proc collectGrid_saveGridGroupForUser { } {
    set user      [get_collect_grid_data user]
    set sessionID [get_collect_grid_data sid]
    set logPath   [get_collect_grid_data log_file_name]

    set dir [file dirname $logPath]

    set anyError 0
    set src_top [::gGridGroup4Run getTopDirectory]
    set src_fileRPathList [::gGridGroup4Run getAllFileRPath]
    foreach rPath $src_fileRPathList {
        set src [file join $src_top $rPath]
        set tgt [file join $dir     $rPath]
        if {[catch {
            impCopyFile $user $sessionID $src $tgt
        } errMsg]} {
            log_warning failed to save raster: $errMsg
            user_log_warning failed to save raster: $errMsg
            incr anyError
        } else {
            log_warning $rPath saved to $dir
        }
    }
    if {!$anyError} {
        log_note raster saved to $dir
    }
}
proc collectGrid_normalConstantNameToIndex { name } {
    variable rastering_normal_name_list
    variable rastering_normal_constant

    set index [lsearch -exact $rastering_normal_name_list $name]
    if {$index < 0} {
        return -code error "bad name normal: $name"
    }

    if {[llength $rastering_normal_constant] <= $index} {
        return -code error "bad contents of string rastering_normal_constant"
    }
    return $index
}
proc collectGrid_microConstantNameToIndex { name } {
    variable rastering_micro_name_list
    variable rastering_micro_constant

    set index [lsearch -exact $rastering_micro_name_list $name]
    if {$index < 0} {
        return -code error "bad name micro: $name"
    }

    if {[llength $rastering_micro_constant] <= $index} {
        return -code error "bad contents of string rastering_micro_constant"
    }
    return $index
}
proc get_collect_grid_user_input { name } {
    variable ::collectGrid::gridUserInput

    if {[catch {dict get $gridUserInput $name} value]} {
        puts "DEBUG: field $name not in userInput"
        set value ""
    }

    return $value
}

proc collectGrid_getNextNode { current } {
    variable ::collectGrid::gridId
    return [::gGridGroup4Run getGridNextNode $gridId $current]
}
proc collectGrid_submitImageForAnalysis { row fullPath } {
    variable beamlineID
    variable collectGrid_rowUniqueIDList

    set user      [get_collect_grid_data user]
    set sessionID [get_collect_grid_data sid]
    set silid     [get_collect_grid_data sil_id]
    set uniqueID  [lindex $collectGrid_rowUniqueIDList $row]

    addCrystalImage $user $sessionID $silid $row 1 $fullPath NULL $uniqueID

    set directory [file dirname $fullPath]

    analyzeCenterImage \
    $user $sessionID $silid $row $uniqueID 1 $fullPath ${beamlineID} $directory
}
proc collectGrid_clearSpreadsheetOneRow { row } {
    variable collectGrid_rowUniqueIDList

    set user      [get_collect_grid_data user]
    set sessionID [get_collect_grid_data sid]
    set silid     [get_collect_grid_data sil_id]
    set uniqueID  [lindex $collectGrid_rowUniqueIDList $row]

    clearCrystalResults $user $sessionID $silid $row $uniqueID
}
proc collectGrid_getDetectorMode { exposureTime } {
    variable detectorType

    set type [lindex $detectorType 0]

    if {$exposureTime < 5.0} {
        switch -exact -- $type {
            MAR325 -
            MAR165 {
                return 0
            }
            MAR345 {
                return 0
            }
            Q315CCD {
                return 2
            }
            Q4CCD {
                return 3
            }
            default {
                return 0
            }
        }
    } else {
        switch -exact -- $type {
            MAR325 -
            MAR165 {
                return 1
            }
            MAR345 {
                return 0
            }
            Q315CCD {
                return 6
            }
            Q4CCD {
                return 7
            }
            default {
                return 0
            }
        }
    }
}
proc collectGrid_log { contents {update_operation 1} {force_file 0} } {
    variable ::collectGrid::pendingLogContents

    set user      [get_collect_grid_data user]
    set sessionID [get_collect_grid_data sid]
    set logPath [get_collect_grid_data log_file_name]

    set ts [clock format [clock seconds] -format "%d %b %Y %X"]

    append pendingLogContents "$ts $contents\n"

    if {[string length $pendingLogContents] > 10240 \
    || $force_file} {
        if {[catch {
            impAppendTextFile $user $sessionID $logPath $pendingLogContents
            set pendingLogContents ""
        } errMsg]} {
            puts "failed to write log file, will try next time:$errMsg"
        }
    }
    if {$update_operation} {
        send_operation_update $contents
    }
}
proc collectGrid_logData { } {
    variable collect_grid_data_name_list
    #variable gridding_data
    variable ::collectGrid::gridding_data

    set user      [get_collect_grid_data user]
    set sessionID [get_collect_grid_data sid]

    set ll [llength $collect_grid_data_name_list]
    set log_contents "COLLECT RASTER DATA\n"
    for {set i 0} {$i < $ll} {incr i} {
        append log_contents [lindex $collect_grid_data_name_list $i]
        append log_contents =
        append log_contents [lindex $gridding_data $i]
        append log_contents "\n"
    }
    ##### only write to log file, not send operation update
    collectGrid_log $log_contents 0
}
proc collectGrid_updateRun { groupNum status } {
    variable gridGroup$groupNum

    set contents [set gridGroup$groupNum]
    set contents [lreplace $contents 0 0 $status]

    set gridGroup$groupNum $contents
}
proc collectGrid_save4Restore { } {
    variable ::collectGrid::restore_cmd

    global gMotorBeamWidth
    global gMotorBeamHeight
    global gMotorBeamStop
    global gMotorDistance

    variable $gMotorBeamWidth
    variable $gMotorBeamHeight
    variable $gMotorBeamStop
    variable $gMotorDistance
    variable gonio_phi
    variable sample_x
    variable sample_y
    variable sample_z
    variable attenuation

    set saveMotorList [list \
    $gMotorBeamWidth \
    $gMotorBeamHeight \
    attenuation \
    ]

    set restore_cmd ""
    foreach motor $saveMotorList {
        set pos [set $motor]
        lappend restore_cmd [list $motor $pos]
        collectGrid_log "save $motor position $pos"
    }
}
proc collectGrid_restore { } {
    variable ::collectGrid::restore_cmd

    collectGrid_setStatus "restoring motor positions" 3

    set movingList ""
    foreach cmd $restore_cmd {
        foreach {motor pos} $cmd break

        move $motor to $pos
        lappend movingList $motor
        collectGrid_log "restore $motor position to $pos"
    }
    if {$movingList != ""} {
        eval wait_for_devices $movingList
    }
    wait_for_time 0

    set restore_cmd ""
}
proc collectGrid_setStatus { txt_status {sub_state -1} } {
    variable grid_msg

    set contents [lreplace $grid_msg 1 1 $txt_status]
    if {$sub_state >= 0} {
        set contents [lreplace $contents 2 2 $sub_state]
    }
    set grid_msg $contents
}
proc collectGrid_checkNotProcessedImages { } {
    variable ::collectGrid::gridId

    variable ::collectGrid::spreadsheetRow2Seq

    set user      [get_collect_grid_data user]
    set sessionID [get_collect_grid_data sid]
    set sil_id    [get_collect_grid_data sil_id]

    set processing [get_collect_grid_user_input processing]
    if {$processing == "0"} {
        return
    }

    set grid [::gGridGroup4Run getGrid $gridId]
    if {$grid == ""} {
        return
    }
    foreach {header nodeSequence} [$grid getNodeListInfo] break

    set directory [get_collect_grid_user_input directory]
    set prefix    [get_collect_grid_user_input prefix]

    set seq -1
    set numSubmitted 0
    foreach node $nodeSequence {
        incr seq
        if {$node == "D"} {
            set fileroot ${prefix}_[expr $seq + 1]
            set fullPath [file join $directory \
            ${fileroot}.[get_collect_grid_data image_ext]]
            if {![file readable $fullPath]} {
                continue
            }
            if {[catch {
                collectGrid_addImageToQueue $seq $directory $fileroot
                collectGrid_processImageQueue
                incr numSubmitted
            } errMsg]} {
                log_warning submit image failed: $errMsg
                user_log_warning failed to submit $fileroot: $errMsg
            }
        }
    }
    if {$numSubmitted > 1} {
        log_warning resubmitted $numSubmitted images to process
    } elseif {$numSubmitted > 0} {
        log_warning resubmitted one image to process
    }
}
proc collectGrid_logWeight { numFmt txtFmt } {
    variable ::collectGrid::gridId

    foreach line [::gGridGroup4Run getGridMatrixLog $gridId \
    $numFmt $txtFmt] {
        collectGrid_log $line
        user_log_note raster $line
    }
}

proc collectGrid_doL614Task { user sessionID } {
	global gPauseDataCollection

    variable ::collectGrid::spreadsheetRow2Seq
    variable ::collectGrid::numSkipReceived
    variable ::collectGrid::gridId
    variable ::collectGrid::gridLabel

    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega
    variable energy
    variable attenuation

    if {$gPauseDataCollection} {
        error paused
    }

    ###########no motor should be moving
    error_if_moving \
    sample_x \
    sample_y \
    sample_z \
    gonio_phi \
    gonio_omega

    if {$numSkipReceived > 0} {
        return 0
    }
    
    set exposeTime [get_collect_grid_user_input time]
    set modeIndex  [collectGrid_getDetectorMode $exposeTime]
    set ext        [getDetectorFileExt $modeIndex]
    ::gGridGroup4Run setDetectorModeAndFileExt $gridId $modeIndex $ext

    save_collect_grid_data det_mode  $modeIndex
    save_collect_grid_data image_ext $ext
    puts "set image_ext to $ext"

    set log "filename                  phi    omega        x        y        z  bm_x  bm_y" 
    collectGrid_log $log
    user_log_note raster $log

    if {$numSkipReceived > 0} {
        return 0
    }

    set next_seq -1
    collectGrid_setGridStatus rastering
    while {1} {
        if {$gPauseDataCollection} {
            collectGrid_setGridStatus paused
            error paused
        }

        if {$numSkipReceived > 0} {
            break
        }
        set next_seq [collectGrid_getNextNode $next_seq]
        if {$next_seq < 0} {
            collectGrid_log "This raster all done"
            break
        }
        set nodeInfo [::gGridGroup4Run getGridNodePosition $gridId $next_seq]
        set nodeLabel ""
        foreach {x y z a row_index col_index nodeLabel} $nodeInfo break
        set orig_phi [expr $a - $gonio_omega]

        puts "moving to position"
        #######move to position
        move sample_x to $x
        move sample_y to $y
        move sample_z to $z
        move gonio_phi to $orig_phi
        wait_for_devices sample_x sample_y sample_z gonio_phi

        ###prepare filename for collect image
        set directory [get_collect_grid_user_input directory]
        set prefix    [get_collect_grid_user_input prefix]
        if {$nodeLabel == ""} {
            set fileroot ${prefix}_[expr $next_seq + 1]
        } else {
            set fileroot ${prefix}_$nodeLabel
        }

        ::gGridGroup4Run setGridNodeStatusBySequence $gridId $next_seq X

        collectGrid_collectOneL614Node \
        $user $sessionID $modeIndex $directory $fileroot

        ::gGridGroup4Run setGridNodeStatusBySequence $gridId $next_seq D
    }
    ### need this to flush out last image
    start_operation detector_stop

    ####restore position

    if {$numSkipReceived > 0} {
        collectGrid_setStatus "grid$gridLabel skipped"
        return 0
    }

    collectGrid_setStatus "grid$gridLabel complete"
    collectGrid_setGridStatus complete
    user_log_note raster \
    "--------------------grid$gridLabel complete------------------------------"
    return 1
}

proc collectGrid_collectOneL614Node { \
    user sessionID modeIndex directory prefix \
} {
    variable ::collectGrid::gridCamera
    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega
    variable energy
    variable attenuation

    set orig_phi $gonio_phi

    set takeVideoSnapshot   [get_collect_grid_user_input video_snapshot]
    if {$takeVideoSnapshot} {
        collectGrid_lightUp
        set vSnapshotPath [file join $directory ${prefix}.jpg]
        set h [start_waitable_operation videoSnapshot $gridCamera $user \
        $sessionID $vSnapshotPath 1]
        wait_for_operation_to_finish $h
        collectGrid_lightOut
    }

    set takeFirstSingleShot [get_collect_grid_user_input first_single_shot]
    if {$takeFirstSingleShot} {
        set firstAtt [get_collect_grid_user_input first_attenuation]
        move attenuation to $firstAtt
        wait_for_devices attenuation

        set fileroot ${prefix}_firstShot
        set reuseDark 0 
        set operationHandle [start_waitable_operation collectFrame \
                                     0 \
                                     $fileroot \
                                     $directory \
                                     $user \
                                     NULL \
                                     NULL \
                                     0 \
                                     0 \
                                     $modeIndex \
                                     0 \
                                     $reuseDark \
                                     $sessionID]

        if {[catch {
            wait_for_operation_to_finish $operationHandle
        } detErrMsg]} {
            log_error detector error $detErrMsg
            return -code error "Detector error: $detErrMsg"
        }
        set log_contents \
        [format "%-20s %8.3f %8.3f %8.3f %8.3f %8.3f %5.3f %5.3f" \
        $fileroot \
        $orig_phi $gonio_omega \
        $sample_x $sample_y $sample_z \
        [get_collect_grid_data beam_width] \
        [get_collect_grid_data beam_height] \
        ]

        collectGrid_log $log_contents
        user_log_note raster $log_contents
    }

    set numPhiShot [get_collect_grid_user_input num_phi_shot]
    set index2SoftLink [expr $numPhiShot / 2]
    if {$numPhiShot > 0} {
        set phiAtt   [get_collect_grid_user_input attenuation]
        set phiDelta [get_collect_grid_user_input delta]
        set phiTime  [get_collect_grid_user_input time]
        move attenuation to $phiAtt
        wait_for_devices attenuation

        set phiDelta [expr abs($phiDelta)]
        set phi0 [expr $orig_phi - $phiDelta * $numPhiShot / 2.0]

        set reuseDark 0 
        for {set i 0} {$i < $numPhiShot} {incr i} {
            set phi [expr $phi0 + $i * $phiDelta]
            move gonio_phi to $phi
            wait_for_devices gonio_phi

            set fileroot ${prefix}_phi[expr $i + 1]
            set operationHandle [start_waitable_operation collectFrame \
                                     0 \
                                     $fileroot \
                                     $directory \
                                     $user \
                                     gonio_phi \
                                     shutter \
                                     $phiDelta \
                                     $phiTime \
                                     $modeIndex \
                                     0 \
                                     $reuseDark \
                                     $sessionID]

            if {[catch {
                wait_for_operation_to_finish $operationHandle
            } detErrMsg]} {
                log_error detector error $detErrMsg
                return -code error "Detector error: $detErrMsg"
            }
            set log_contents \
            [format "%-20s %8.3f %8.3f %8.3f %8.3f %8.3f %5.3f %5.3f" \
            $fileroot \
            $phi $gonio_omega \
            $sample_x $sample_y $sample_z \
            [get_collect_grid_data beam_width] \
            [get_collect_grid_data beam_height] \
            ]

            collectGrid_log $log_contents
            user_log_note raster $log_contents

            if {$i == $index2SoftLink} {
                set fullPath [file join $directory \
                ${fileroot}.[get_collect_grid_data image_ext]]

                set oh [start_waitable_operation softLinkForL614 \
                add_file $fullPath]
                set oResult [wait_for_operation_to_finish $oh]
                set link [lindex $oResult 1]
                if {$link != ""} {
                    set log_contents "soft_linked to $link"
                    collectGrid_log $log_contents
                    user_log_warning raster $log_contents
                }
            }
        }
    }

    set takeEndSingleShot [get_collect_grid_user_input end_single_shot]
    if {$takeEndSingleShot} {
        set endAtt [get_collect_grid_user_input end_attenuation]
        move attenuation to $endAtt
        move gonio_phi to $orig_phi
        wait_for_devices attenuation gonio_phi

        set fileroot ${prefix}_endShot
        set reuseDark 0 
        set operationHandle [start_waitable_operation collectFrame \
                                     0 \
                                     $fileroot \
                                     $directory \
                                     $user \
                                     NULL \
                                     NULL \
                                     0 \
                                     0 \
                                     $modeIndex \
                                     0 \
                                     $reuseDark \
                                     $sessionID]

        if {[catch {
            wait_for_operation_to_finish $operationHandle
        } detErrMsg]} {
            log_error detector error $detErrMsg
            return -code error "Detector error: $detErrMsg"
        }
        set log_contents \
        [format "%-20s %8.3f %8.3f %8.3f %8.3f %8.3f %5.3f %5.3f" \
        $fileroot \
        $orig_phi $gonio_omega \
        $sample_x $sample_y $sample_z \
        [get_collect_grid_data beam_width] \
        [get_collect_grid_data beam_height] \
        ]

        collectGrid_log $log_contents
        user_log_note raster $log_contents
    }
}
proc collectGrid_lightUp { } {
    if {![isShutter inline_light_in] || ![isShutter inline_light_out]} {
        return
    }

    if {[isOperation lightsControl]} {
        lightsControl_start setup inline_insert
    }

    close_shutter inline_light_in
    open_shutter inline_light_out

    wait_for_devices inline_light_in inline_light_out
    wait_for_time 500

    log_note "Waiting for inline light to move in." 
    if {[catch waitForInlineLightInserted errMsg]} {
        log_severe failed to wait inline light insert
        log_error $errMsg
        return -code error $errMsg
    }
    log_note "Inline light moved in" 
}

### many not need: moving beamstop_z may remove the light.
proc collectGrid_lightOut { } {
    if {![isShutter inline_light_in] || ![isShutter inline_light_out]} {
        return
    }
    if {[isOperation lightsControl]} {
        lightsControl_start setup inline_remove
    }

    open_shutter inline_light_in
    close_shutter inline_light_out

    wait_for_devices inline_light_in inline_light_out
    
    wait_for_time 500
    log_note "Waiting for inline light to move out." 
    if {[catch waitForInlineLightRemoved errMsg]} {
        log_severe failed to wait inline light to move out
        log_error $errMsg
        return -code error $errMsg
    }
    log_note "Inline light moved out" 
}
proc waitForInlineLightRemoved {} {
    variable inlineLightStatus

    set removed 0
    while {!$removed} {
        set paramList $inlineLightStatus
        set index [expr [lsearch -exact $paramList REMOVED] +1]
        if {$index <=0} {
            log_severe cannot wait for inline light removed: \
            no REMOVED field found
            return -code error field_REMOVED_not_found
        }
        set removed [lindex $paramList [expr [lsearch $paramList REMOVED] +1]]
        if {$removed == "yes"} {
            break
        }
        log_note "Waiting for inline light to move out." 
        wait_for_strings inlineLightStatus 5000
    }
}

proc waitForInlineLightInserted {} {
    variable inlineLightStatus

    ##assume the position will not change during wait
    set index [expr [lsearch $inlineLightStatus INSERTED] +1]
    if {$index <= 0} {
        log_severe cannot wait for inline light inserted: \
        no INSERTED field found
        return -code error field_INSERTED_not_found
    }
    ### timeout can be added at the end of arguments
    wait_for_string_contents inlineLightStatus yes $index 5000
}
