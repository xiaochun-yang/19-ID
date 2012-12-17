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


##################################
# temperary data are saved in string rastering_data
#################################################3

set MRasteringDataNameList [list \
    setup0 \
    setup1 \
    use_collimator \
    beam_width \
    beam_height \
    log_file_name \
    scan_phase \
    sil_id \
    sil_num_row \
    exposure_time \
    old_i2 \
    old_exposure_time \
    det_mode \
    image_ext \
    max_weight \
    max_index \
    user \
    raw_weight_list \
    passed_threshold \
    scaling_max \
    scaling_index \
    scaling_scale \
] 

set MRasteringSessionID ""
proc manualRastering_initialize {} {
    variable rastering_normal_name_list
    variable rastering_micro_name_list
    variable rastering_data_name_list
    variable MRasteringDataNameList

    variable MRasteringUniqueIDList

    set rastering_normal_name_list [::config getStr "rastering.normalConstantNameList"]
    set rastering_micro_name_list  [::config getStr "rastering.microConstantNameList"]
    set MRasteringUniqueIDList [list]

    namespace eval ::manualRastering {
        global gBeamlineId
        set rastering_data ""
        set restore_cmd ""

        ### here row is row in spreadsheet
        set listRow2Index ""

        set saveRasterFile ""

        set myOwnFilePath ${gBeamlineId}_raster.save

        set user_setup_name_list [list distance beamstop delta time time0 time1 is_default_time]

        set time_index      [lsearch -exact $user_setup_name_list time]
        set isDefault_index [lsearch -exact $user_setup_name_list is_default_time]

        set pendingLogContents ""
        set numStopReceived 0
    }

    variable ::manualRastering::rastering_data

    set ll [llength $MRasteringDataNameList]
    for {set i 0} {$i < $ll} {incr i} {
        lappend rastering_data $i
    }
    set rastering_data_name_list $MRasteringDataNameList

    puts "init rastering_data to length =$ll"
    MRastering_restoreInfoFromFile
}
proc manualRastering_save4Restore { } {
    variable ::manualRastering::restore_cmd

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
        MRasteringLog "save $motor position $pos"
    }
}
proc manualRastering_restore { } {
    variable ::manualRastering::restore_cmd
    variable center_crystal_msg

    set center_crystal_msg "restoring motor positions"

    set movingList ""
    foreach cmd $restore_cmd {
        foreach {motor pos} $cmd break

        move $motor to $pos
        lappend movingList $motor
        MRasteringLog "restore $motor position to $pos"
    }
    if {$movingList != ""} {
        eval wait_for_devices $movingList
    }
    set center_crystal_msg ""
    wait_for_time 0

    set restore_cmd ""
}

proc manualRastering_start { user sessionID directory filePrefix args } {
    variable ::manualRastering::numStopReceived
    variable ::manualRastering::pendingLogContents

    global gMotorBeamWidth
    global gMotorBeamHeight
    global gWaitForGoodBeamMsg

    variable attenuation
    variable $gMotorBeamWidth
    variable $gMotorBeamHeight
    variable gonio_phi
    variable sample_x
    variable sample_y
    variable sample_z
    variable center_crystal_msg
    variable MRasteringSessionID
    variable scan3DSetup_info
    variable scan2DEdgeSetup
    variable scan2DFaceSetup
    variable rasterState

    set numStopReceived 0
    set pendingLogContents ""
    user_log_note raster "======$user started raster======"

    ### disable Stop button with "ing"
    #MRastering_setState starting 1
    MRastering_setState raster0 1

    MRastering_restoreSelection 0
    MRastering_restoreSelection 1
    clear_rastering_user_setup

    set gWaitForGoodBeamMsg center_crystal_msg

    set center_crystal_msg "precheck motor"
    if {[catch correctPreCheckMotors errMsg]} {
        log_error failed to correct motors $errMsg
        user_log_error raster "pre-check motors failed: $errMsg"
        user_log_note  raster "=======end raster========"
        return -code error $errMsg
    }
    set center_crystal_msg "prepare directory and files"

    set timeStart [clock seconds]
    set filePostfix [timeStampForFileName]
    set filePostfix [format %X $timeStart]

    if {$sessionID == "SID"} {
        set sessionID PRIVATE[get_operation_SID]
        puts "manualRastering use operation SID: [SIDFilter $sessionID]"
    }

    #set log_file_name [file join $directory ${filePrefix}_${filePostfix}.log]
    set log_file_name [file join $directory ${filePrefix}.log]
    save_rastering_data log_file_name $log_file_name
    set contents "$user start crystal rastering\n"
    append contents "directory=$directory filePrefix=$filePrefix filePostfix=$filePostfix\n"
    append contents [format "orig beamsize: %5.3fX%5.3f phi: %8.3f\n" \
    [set $gMotorBeamWidth] [set $gMotorBeamHeight] $gonio_phi]
    #####call write file to overwrite if file exists.

    if {[catch {
        impWriteFile $user $sessionID $log_file_name $contents false
    } errMsg]} {
        set center_crystal_msg "failed to create log file"
        user_log_error raster "create log file failed: $errMsg"
        user_log_note  raster "=======end raster========"
        return -code error $errMsg
    }
    user_log_note raster "log_file=$log_file_name"

    if {[catch {
        MRastering_saveSnapshotsForUser $user $sessionID $directory
    } errMsg]} {
        set center_crystal_msg "failed to save snapshot files"
        user_log_error raster "save snapshot files for user failed: $errMsg"
        user_log_note  raster "=======end raster========"
        return -code error $errMsg
    }

    MRastering_saveAllToFile ${filePrefix}_${filePostfix}.log

    #### we need these to write log file
    save_rastering_data user $user
    set MRasteringSessionID $sessionID
    set use_collimator [lindex $scan3DSetup_info 4]
    save_rastering_data use_collimator $use_collimator
    save_rastering_data setup0 $scan2DEdgeSetup
    save_rastering_data setup1 $scan2DFaceSetup

    if {$use_collimator} {
        user_log_note raster "use collimator"
    } else {
        user_log_note raster "use normal beam"
    }

    ##### save to restore after operation
    manualRastering_save4Restore

    save_rastering_data old_i2 0

    ################catch everything##############
    # in case of any failure, restore
    # beam size and phi.
    # in case of total failure, sample_x, y z
    # will be restored.
    ##############################################

    set result "success"
    if {[catch {
        ###do not delete until check tight up in sil.
        ###MRasteringDeleteDefaultSil
        set center_crystal_msg "prepare special spreadsheet"
        MRasteringCreateDefaultSil
 
        ### enable Stop button to Skip
        ##MRastering_setState raster0 1

        ### skip still need this but stop will not need this anymore
        set center_crystal_msg "setup beam"
        MRasteringSetupEnvironments

        ###DEBUG
        MRasteringLogConstant

        if {![eval MRasteringDoManualScan \
        $user $sessionID $directory $filePrefix $filePostfix]} {
            log_error manual scan failed
            return -code error "manual rastering failed"
        }
        MRasteringLog "manual scan successed"
    } errMsg] == 1} {
        if {$errMsg != ""} {
            set result $errMsg
            log_warning "crystal rastering failed: $errMsg"
            MRasteringLog "crystal rastering failed: $result"
            set center_crystal_msg "error: $result"
        }
    }
    ### disable Stop button
    if {$rasterState != "stopping"} {
        MRastering_setState ending 1
    }

    MRastering_saveRasterForUser 1
    MRasteringDeleteDefaultSil

    start_recovery_operation detector_stop

    if {[catch {
        manualRastering_restore
    } errMsg]} {
        ### most likely, aborted already
        puts "manualRastering_restore failed: $errMsg"
    }

    MRasteringLog "end of crystal rastering"
    set center_crystal_msg ""

    set timeEnd [clock seconds]

    set timeUsed [expr $timeEnd - $timeStart]
    set timeUsedText [secondToTimespan $timeUsed]
    MRasteringLog "time used: $timeUsedText ($timeUsed seconds)" 1 1
    user_log_note raster "time used: $timeUsedText ($timeUsed seconds)"

    MRasteringLogData

    ### this may move some motors, like collimator, beamstop, lights
    cleanupAfterAll
    set gWaitForGoodBeamMsg ""

    ### draw cross
    MRastering_setState idle

    if {$result != "success"} {
        user_log_error raster "raster failed: $result"
        user_log_note  raster \
        "=========================end raster============================"
        return -code error $result
    }
    user_log_note raster \
    "=========================end raster============================"
    return $result
}
### called when stop flag set
proc manualRastering_stopCallback { } {
    variable ::manualRastering::numStopReceived
    variable rasterState

    incr numStopReceived

    puts "manualRastering_stopCallaback state=$rasterState"
    puts "stopcount=$numStopReceived"

    if {$numStopReceived < 2} {
        if {$rasterState == "raster1"} {
            set rasterState stopping
        } else {
            set rasterState raster1
        }
    } else {
        set rasterState stopping
    }
}
proc MRasteringSetupEnvironments { } {
    variable ::manualRastering::numStopReceived

    global gMotorBeamWidth
    global gMotorBeamHeight
    global gMotorBeamStop
    global gMotorDistance

    variable center_crystal_msg

    if {$numStopReceived > 1} {
        return -code error stopped
    }

    set use_collimator [get_rastering_data use_collimator]

    set movingList ""
    if {$use_collimator} {
        MRasteringLog "use collimator"
        #set index [get_rastering_constant collimator]
        #collimatorMove_start $index
        
        set center_crystal_msg "prepare collimator"
        foreach {bw bh} [collimatorMoveFirstMicron] break
    } else {
        MRasteringLog "use normal beam"

        if {[isOperation collimatorMove]} {
            collimatorNormalIn
        }

        set bw [get_rastering_constant beamWd]
        set bh [get_rastering_constant beamHt]
        move $gMotorBeamWidth  to $bw
        move $gMotorBeamHeight to $bh
        lappend movingList $gMotorBeamWidth $gMotorBeamHeight
    }
    save_rastering_data beam_width $bw
    save_rastering_data beam_height $bh

    set stop_move [get_rastering_constant stopMove]
    #set stop_v    [get_rastering_constant stopV]
    set stop_v    [get_rastering_user_setup beamstop]

    set dist_move [get_rastering_constant distMove]
    #set dist_v    [get_rastering_constant distV]
    set dist_v    [get_rastering_user_setup distance]
    if {$stop_move && $numStopReceived < 2} {
        move $gMotorBeamStop to $stop_v
        lappend movingList $gMotorBeamStop
    }
    if {$dist_move && $numStopReceived < 2} {
        move $gMotorDistance to $dist_v
        lappend movingList $gMotorDistance
    }
    if {$numStopReceived < 2} {
        set center_crystal_msg "prepare $movingList"
    } else {
        set center_crystal_msg "stopping $movingList"
    }
    if {$movingList != ""} {
        eval wait_for_devices $movingList
    }
    set center_crystal_msg ""

    if {$numStopReceived > 1} {
        return -code error stopped
    }

    #set exposureTime    [get_rastering_constant timeDef]
    set exposureTime    [get_rastering_user_setup time]
    set newTime [MRasteringSetExposureTime $exposureTime]
    if {$newTime != $exposureTime} {
        MRasteringLog "exposure time inited to $newTime"
    }
}

########################################################################
########################### setup ######################################
########################################################################
proc MRasteringIncreaseExposeTime { } {
    ## no adjustment if user specify time
    set timeUser [get_rastering_user_setup time]
    set timeDef  [get_rastering_constant timeDef]
    if {abs($timeUser - $timeDef) > 0.001} {
        user_log_warning raster "user has specified exposure time, no scaling"
        MRasteringLog "user has specified exposure time"
        return 0
    }


    set current_time [get_rastering_data exposure_time]
    set max_time [get_rastering_constant timeMax]
    if {$current_time >= $max_time} {
        MRasteringLog "reached max exposure time, quit"
        return 0
    }

    set new_time [MRasteringAdjustExposureTimeByNumSpot $current_time]
    #flag to skip ion chamber scaling
    save_rastering_data old_i2 0

    MRasteringLog "exposure time increased to $new_time"
    return 1
}
proc MRasteringCheckWeights { } {
    set raw_weight_list [get_rastering_data raw_weight_list]


    set max_weight [MRasteringGetMaxWeight $raw_weight_list]

    ##################check to see if max weight is still too small#####
    set min_weight_to_proceed [get_rastering_constant spotMin]
    if {$max_weight < $min_weight_to_proceed} {
        MRasteringLog "rastering failed: num of spot too small"
        return 0
    }
    return 1
}

################################################################
######################## web stuff #############################
################################################################
proc MRasteringClearResults { } {
    #MRasteringDeleteDefaultSil
    #MRasteringCreateDefaultSil

    ### used this after Boom implement the clearAllCrystalls
    variable MRasteringSessionID
    set user [get_rastering_data user]
    set sessionID $MRasteringSessionID
    set sil_id [get_rastering_data sil_id]
    resetSpreadsheet $user $sessionID $sil_id
}
proc MRasteringDeleteDefaultSil { } {
    variable MRasteringSessionID

    set user [get_rastering_data user]
    set sessionID $MRasteringSessionID
    ###try to delete the previous SIL, may belong to another user
    set sil_id [get_rastering_data sil_id]
    if {[string is integer -strict $sil_id] && $sil_id > 0} {
        if {[catch {
            deleteSil $user $sessionID $sil_id
            save_rastering_data sil_id 0
        } errMsg]} {
            puts "failed to delete SIL $sil_id: $errMsg"
        }
    }
}
proc MRasteringCreateDefaultSil { } {
    variable MRasteringSessionID
    variable MRasteringUniqueIDList

    ####create new sil and save the id to the string
    set user [get_rastering_data user]
    set sessionID $MRasteringSessionID
    set sil_id [createDefaultSil $user $sessionID \
    "&templateName=crystal_centering&containerType=crystal_centering"]
    puts "new sil_id: $sil_id"

    if {![string is integer -strict $sil_id] || $sil_id < 0} {
        return -code error "create default sil failed: sil_id: $sil_id not > 0"
    }

    ### get uniqueID for each row
    if {[catch {
        set MRasteringUniqueIDList [getSpreadsheetProperty \
        $user $sessionID $sil_id UniqueID]
    } errMsg]} {
        set MRasteringUniqueIDList [list]
        log_error failed to get uniqueIDList: $errMsg
    }

    save_rastering_data sil_id $sil_id

    set sil_num_row [llength $MRasteringUniqueIDList]
    if {$sil_num_row < 96} {
        set sil_num_row 625
    }
    save_rastering_data sil_num_row $sil_num_row
}
proc MRasteringAddAndAnalyzeImage { user sessionID row directory fileroot } {
    variable beamlineID
    variable MRasteringUniqueIDList

    set fullPath [file join $directory \
    ${fileroot}.[get_rastering_data image_ext]]

    set silid [get_rastering_data sil_id]

    set uniqueID [lindex $MRasteringUniqueIDList $row]

    addCrystalImage $user $sessionID $silid $row 1 $fullPath NULL $uniqueID

    analyzeCenterImage \
    $user $sessionID $silid $row $uniqueID 1 $fullPath ${beamlineID} $directory
}

proc MRasteringCheckImage { view_index user sessionID } {
    variable scan2DEdgeInfo
    variable scan2DFaceInfo
    variable ::manualRastering::listRow2Index

    set sil_id [get_rastering_data sil_id]
    set numList [getNumSpotsData $user $sessionID $sil_id]
    puts "numList: $numList"

    set ll [llength $listRow2Index]
    set end [expr $ll - 1]

    puts "ll=$ll"
    
    set result [lrange $numList 0 $end]
    set numValid [MRastering_distributeResults $view_index $result]
    MRastering_saveAllToFile

    save_rastering_data raw_weight_list $result

    set max_weight [MRasteringGetMaxWeight $result]
    set min_weight_to_proceed [get_rastering_constant spotMin]
    if {$max_weight < $min_weight_to_proceed} {
        save_rastering_data passed_threshold 1
    } else {
        save_rastering_data passed_threshold 0
    }
    return $numValid
}

proc MRasteringWaitForAllImage { view_index user sessionID } {
    variable ::manualRastering::listRow2Index
    variable ::manualRastering::numStopReceived

    set ll [llength $listRow2Index]
    
    set llResult [MRasteringCheckImage $view_index $user $sessionID]
    if {$llResult > 0} {
        log_warning got $llResult of $ll
    }

    set previous_ll $llResult
    while {$llResult < $ll} {
        if {$numStopReceived} {
            log_error stopped by user
            return
        }
        wait_for_time 1000
        if {[catch {
            set llResult [MRasteringCheckImage $view_index $user $sessionID]
        } err]} {
            log_warning failed to wait for all data: $err
            break
        }
        if {$llResult > $previous_ll} {
            log_warning got $llResult of $ll
            set previous_ll $llResult
        }
    }
    MRastering_setRasterState $view_index checking_results
}
################################################################
######################## utilities #############################
################################################################
proc get_rastering_data { name } {
    variable ::manualRastering::rastering_data

    set index [MRasteringDataNameToIndex $name]
    return [lindex $rastering_data $index]
}

proc save_rastering_data { name value } {
    #variable rastering_data
    variable ::manualRastering::rastering_data

    set index [MRasteringDataNameToIndex $name]
    set rastering_data [lreplace $rastering_data $index $index $value]
}

proc MRasteringDataNameToIndex { name } {
    variable rastering_data_name_list
    #variable rastering_data
    variable ::manualRastering::rastering_data

    if {![info exists rastering_data]} {
        return -code error "string not exists: rastering_data"
    }

    set index [lsearch -exact $rastering_data_name_list $name]
    if {$index < 0} {
        puts "DataNameToIndex failed name=$name list=$rastering_data_name_list"
        return -code error "data bad name: $name"
    }

    if {[llength $rastering_data] <= $index} {
        return -code error "bad contents of string rastering_data"
    }
    return $index
}
proc MRasteringNormalConstantNameToIndex { name } {
    variable rastering_normal_name_list
    variable rastering_normal_constant

    set index [lsearch -exact $rastering_normal_name_list $name]
    if {$index < 0} {
        return -code error "bad namen normal: $name"
    }

    if {[llength $rastering_normal_constant] <= $index} {
        return -code error "bad contents of string rastering_normal_constant"
    }
    return $index
}
proc MRasteringMicroConstantNameToIndex { name } {
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
proc MRasteringLog { contents {update_operation 1} {force_file 0} } {
    variable ::manualRastering::pendingLogContents

    variable MRasteringSessionID

    set user      [get_rastering_data user]
    set sessionID $MRasteringSessionID
    set logPath [get_rastering_data log_file_name]

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
proc MRasteringLogConstant { } {
    set use_collimator [get_rastering_data use_collimator]

    if {$use_collimator} {
        MRasteringLogMicroConstant
    } else {
        MRasteringLogNormalConstant
    }
}
proc MRasteringLogNormalConstant { } {
    variable rastering_normal_constant
    variable rastering_normal_name_list

    set ll [llength $rastering_normal_name_list]

    set log_contents "MANUAL RASTERING PARAMETERS\n"
    for {set i 0} {$i < $ll} {incr i} {
        append log_contents [lindex $rastering_normal_name_list $i]
        append log_contents =
        append log_contents [lindex $rastering_normal_constant $i]
        append log_contents "\n"
    }
    ##### only write to log file, not send operation update
    MRasteringLog $log_contents 0
}
proc MRasteringLogMicroConstant { } {
    variable rastering_micro_constant
    variable rastering_micro_name_list

    set ll [llength $rastering_micro_name_list]

    set log_contents "MANUAL RASTERING PARAMETERS\n"
    foreach name $rastering_micro_name_list value $rastering_micro_name_list {
        append log_contents "$name=$value\n"
    }
    ##### only write to log file, not send operation update
    MRasteringLog $log_contents 0
}
proc MRasteringLogData { } {
    variable rastering_data_name_list
    #variable rastering_data
    variable ::manualRastering::rastering_data
    variable MRasteringSessionID

    set user      [get_rastering_data user]
    set sessionID $MRasteringSessionID

    set ll [llength $rastering_data_name_list]
    set log_contents "MANUAL RASTERING DATA\n"
    for {set i 0} {$i < $ll} {incr i} {
        append log_contents [lindex $rastering_data_name_list $i]
        append log_contents =
        append log_contents [lindex $rastering_data $i]
        append log_contents "\n"
    }
    ##### only write to log file, not send operation update
    MRasteringLog $log_contents 0
}
proc MRasteringLogWeight { view_index numFmt txtFmt offset } {
    variable scan2DEdgeSetup
    variable scan2DFaceSetup
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    if {$view_index == 0} {
        set setup $scan2DEdgeSetup
        set info  $scan2DEdgeInfo
    } else {
        set setup $scan2DFaceSetup
        set info  $scan2DFaceInfo
    }

    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $setup break

    for {set row 0} {$row < $numRow} {incr row} {
        set line ""
        for {set col 0} {$col < $numColumn} {incr col} {
            set index [expr $row * $numColumn + $col + 1]
            set node [lindex $info $index]
            if {[llength $node] > $offset} {
                set weight [lindex $node $offset]
            } else {
                set weight [lindex $node 0]
            }
            if {[string is double -strict $weight]} {
                set nodeDisplay [format $numFmt $weight]
            } else {
                switch -exact -- $weight {
                    N {
                        set nodeDisplay Skip
                    }
                    default {
                        set nodeDisplay N/A
                    }
                }
                set nodeDisplay [format $txtFmt $nodeDisplay]
            }
            append line $nodeDisplay
        }
        MRasteringLog $line
        user_log_note raster $line
    }
}
####return face width, face height, and edge height
#### edge width is the same as face width
proc MRasteringGetLoopSize { faceWRef faceHRef edgeHRef {no_log 0}} {
    variable save_loop_size
    variable center_crystal_msg

    upvar $faceWRef faceWmm
    upvar $faceHRef faceHmm
    upvar $edgeHRef edgeHmm

    MRasteringCheckLoopCenter
    foreach {status loopWidth faceHeight edgeHeight} $save_loop_size break
    #set faceWmm [expr $loopWidth * 0.8]
    #set faceHmm $faceHeight
    #set edgeHmm $edgeHeight
    ######### to be safe, increase loop size 20%
    set loop_width_extra [get_rastering_constant loopW_extra]
    if {![string is double -strict $loop_width_extra]} {
        set loop_width_extra 0.0
    }
    set loop_height_extra [get_rastering_constant loopH_extra]
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
            MRasteringLog [format "loop size adjusted to: %5.3f %5.3f %5.3f" \
            $faceWmm $faceHmm $edgeHmm]
        } else {
            MRasteringLog [format "loop size: %5.3f %5.3f %5.3f" \
            $faceWmm $faceHmm $edgeHmm]
        }
    }

    ###### move to the real loop center ######
    set dz [expr $loopWidth * 0.1]
    move sample_z by $dz
    wait_for_devices sample_z
    
    if {$faceWmm < 0.001 || $faceHmm < 0.001 || $edgeHmm < 0.001} {
        set center_crystal_msg "error: center loop failed to return size"
        return -code error "loop center failed to return loop size"
    }
}
proc MRasteringCheckLoopCenter { } {
    variable save_loop_size
    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable center_crystal_msg

    #######################################################
    # anything wrong from the loopcentering, we will call
    # loop centeringg here again
    #######################################################
    set loopCenterOK 1
    if {[llength $save_loop_size] < 8} {
        #send_operation_update "loopCenter result length not right, force loopcentering"
        set loopCenterOK 0
    }
    foreach {status loopWidth faceHeight edgeHeight s_x s_y s_z g_phi } \
    $save_loop_size break
    if {$status != "normal"} {
        #send_operation_update "loopCenter result failed: $save_loop_size, force loopcentering"
        set loopCenterOK 0
    }
    if {abs($sample_x - $s_x) > 0.01 || \
    abs($sample_y - $s_y) > 0.01 || \
    abs($sample_z - $s_z) > 0.01 || \
    abs($gonio_phi - $g_phi) > 0.01} {
        #send_operation_update "sample moved after loopcentering, force loopcentering"
        #send_operation_update "old:     $s_x $s_y $s_z $g_phi"
        #send_operation_update "current: $sample_x $sample_y $sample_z $gonio_phi"
        set loopCenterOK 0
    }

    if {!$loopCenterOK} {
        set center_crystal_msg "center loop"
        set handle [start_waitable_operation centerLoop]
        wait_for_operation_to_finish $handle
        
        ###### check results: #####
        if {[llength $save_loop_size] < 8} {
            set center_crystal_msg "error: $save_loop_size"
            return -code error \
            "failed in get loop size: $save_loop_size"
        }
        #### we do not check position here, we called loop centering ourselves.
        set status [lindex $save_loop_size 0]
        if {$status != "normal"} {
            set center_crystal_msg "error: $save_loop_size"
            return -code error \
            "failed in get loop size: $save_loop_size"
        }
    }
}
proc MRasteringGetMaxWeight {raw_weight_list} {
    set max_weight 0.0;### weight are not negative
    set index -1
    set maxIndex -1

    ## here is safe for node not ready (with weight= -1)
    foreach node $raw_weight_list {
        set weight [lindex $node 0]
        incr index
        if {[string is double -strict $weight] && $weight > $max_weight} {
            set max_weight $weight
            set maxIndex $index
        }
    }
    save_rastering_data max_index $maxIndex
    save_rastering_data max_weight $max_weight
    return $max_weight
}

proc MRasteringGetDetectorMode { exposureTime } {
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

proc MRasteringAdjustExposureTimeByNumSpot { old_time } {
    set current_max_num_spot [get_rastering_data max_weight]
    set target_num_spot [get_rastering_constant spotTgt]

    MRasteringLog "adjusting time by numspots: curren: $current_max_num_spot"
    MRasteringLog "adjusting time by numspots: target: $target_num_spot"
    MRasteringLog "adjusting time by numspots: old time: $old_time"
    
    if {$current_max_num_spot > 0} {
        set maxFactor [get_rastering_constant timeIncr]
        set factor [expr double($target_num_spot) / double($current_max_num_spot)]

        if {$factor > $maxFactor} {
            set factor $maxFactor
        }
    } else {
        set factor [get_rastering_constant timeIncr]
    }
    save_rastering_data scaling_scale $factor
    set exposure_time [expr $old_time * $factor]
    set new_time [MRasteringSetExposureTime $exposure_time]
    return $new_time
}

##### this will  check range, and set mode and file extension
proc MRasteringSetExposureTime { time } {
    set max_time [get_rastering_constant timeMax]
    set min_time [get_rastering_constant timeMin]

    if {$max_time < $min_time} {
        ###swap them
        set temp $max_time
        set max_time $min_time
        set min_time $temp
    }

    if {$time < $min_time} {
        set time $min_time
        puts "manualRastering: exposure time to $time (min)"
    }
    if {$time > $max_time} {
        set time $max_time
        puts "manualRastering: exposure time to $time (max)"
    }
    set modeIndex [MRasteringGetDetectorMode $time]
    set new_ext [getDetectorFileExt $modeIndex]

    save_rastering_data exposure_time $time
    save_rastering_data det_mode $modeIndex
    save_rastering_data image_ext $new_ext

    return $time
}

proc MRasteringDoManualScan { user sessionID directory \
filePrefix filePostfix } {
    variable ::manualRastering::numStopReceived

    if {$numStopReceived > 1} {
        return -code error stopped
    }

    if {$numStopReceived == 0} {
        set setup [get_rastering_data setup0]
        save_rastering_data scaling_max -1
    
        set maxTry [get_rastering_constant maxTry]
        set timesTrying 0
        set tag VIEW1
    
        ####${filePrefix} ${filePostfix}_${timesTrying} 
    
        MRastering_saveRasterForUser
        while {![MRasteringDoTask $tag $setup 0 \
        $user $sessionID $directory \
        ${filePrefix} ${timesTrying} \
        ]} {
            if {$numStopReceived > 0} {
                MRastering_setRasterState 0 stopped
                user_log_error raster \
                "--------------------$tag stopped by user-----------------------"
                log_warning skip current view and jump to next view
                break
            }
            if {![MRasteringIncreaseExposeTime]} {
                MRastering_setRasterState 0 failed
                user_log_error raster \
                "--------------------$tag no diffraction------------------------"
                log_error "manual collimator scan failed - no diffraction"
                set center_crystal_msg "error: no diffraction"
                break
            }
            if {![MRasteringCheckScaling]} {
                MRastering_setRasterState 0 failed
                user_log_error raster \
                "--------------------$tag no diffraction------------------------"
                log_error "manual collimator scan failed - no diffraction"
                set center_crystal_msg "error: no diffraction"
                break
            }
            incr timesTrying
            if {$timesTrying > $maxTry} {
                MRastering_setRasterState 0 failed
                set center_crystal_msg "reached max trying times, skip"
                MRasteringLog "reached max trying times, skip"
                user_log_error raster "$tag reached max retry"
                "--------------------$tag reached max retry---------------------"
                break
            }
            MRastering_restoreSelection 0
        }
        MRastering_saveRasterForUser
    }
    ### now Stop means stop
    MRastering_setState raster1 1
    variable rasterState
    puts "STOP STOP STOP=$numStopReceived state=$rasterState"
    if {$numStopReceived == 1} {
        set numStopReceived 0
        ## so the getStableCount will not fail
        clear_operation_stop_flag
        puts "clear stop flag"
    }

    set scalingTime [get_rastering_constant scaling]

    if {$scalingTime} {
        set timeUser [get_rastering_user_setup time]
        set timeDef  [get_rastering_constant timeDef]
        if {abs($timeUser - $timeDef) > 0.001} {
            MRasteringLog "no time scaling, user has specified exposure time"
            set scalingTime 0
        }
    }
    if {!$scalingTime} {
        save_rastering_data old_i2 0

        ### not sure about this
        #set exposureTime    [get_rastering_constant timeDef]
        #set newTime [MRasteringSetExposureTime $exposureTime]
        #if {$newTime != $exposureTime} {
        #    MRasteringLog "exposure time inited to $newTime"
        #}
    }

    set tag VIEW2
    set file_prefix ${filePrefix}_$tag
    save_rastering_data scaling_max -1
    set setup [get_rastering_data setup1]
    set timesTrying 0
    while {![MRasteringDoTask $tag $setup 1 \
    $user $sessionID $directory \
    ${filePrefix} ${timesTrying} \
    ]} {
        if {$numStopReceived} {
            MRastering_setRasterState 1 stopped
            log_error stopped by user
            user_log_error raster  \
            "--------------------$tag stopped by user-----------------------"
            return 0
        }
        if {![MRasteringIncreaseExposeTime]} {
            MRastering_setRasterState 1 failed
            user_log_error raster \
            "--------------------$tag no diffraction------------------------"
            log_error "manual collimator scan failed - no diffraction"
            set center_crystal_msg "error: no diffraction"
            return 0
        }
        if {![MRasteringCheckScaling]} {
            MRastering_setRasterState 1 failed
            user_log_error raster \
            "--------------------$tag no diffraction------------------------"
            log_error "manual collimator scan failed - no diffraction"
            set center_crystal_msg "error: no diffraction"
            return 0
        }
        incr timesTrying
        if {$timesTrying > $maxTry} {
            MRastering_setRasterState 1 failed
            set center_crystal_msg "reached max trying times, stop"
            MRasteringLog "reached max trying times, stop"
            user_log_error raster \
            "--------------------$tag reached max retry---------------------"
            return 0
        }
        MRastering_restoreSelection 1
    }
    return 1
}
proc MRasteringMoveToRaster { raster_setup } {
    variable gonio_omega

    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $raster_setup break

    set A4Beam $orig_a
    set orig_phi [expr $A4Beam - $gonio_omega]
    
    variable cfgSampleMoveSerial
    if {$cfgSampleMoveSerial == "1"} {
        move sample_x to $orig_x
        wait_for_devices sample_x
        move sample_y to $orig_y
        wait_for_devices sample_y
        move sample_z to $orig_z
        move gonio_phi to $orig_phi
        wait_for_devices sample_z gonio_phi
    } else {
        move sample_x to $orig_x
        move sample_y to $orig_y
        move sample_z to $orig_z
        move gonio_phi to $orig_phi
        wait_for_devices sample_x sample_y sample_z gonio_phi
    }
}

proc get_rastering_constant { name } {
    set use_collimator [get_rastering_data use_collimator]

    if {$use_collimator} {
        return [get_rastering_micro_constant $name]
    } else {
        return [get_rastering_normal_constant $name]
    }
}
proc get_rastering_normal_constant { name } {
    variable rastering_normal_constant

    set index [MRasteringNormalConstantNameToIndex $name]
    return [lindex $rastering_normal_constant $index]
}
proc get_rastering_micro_constant { name } {
    variable rastering_micro_constant

    set index [MRasteringMicroConstantNameToIndex $name]
    return [lindex $rastering_micro_constant $index]
}
proc get_rastering_user_setup { name } {
    variable ::manualRastering::user_setup_name_list

    variable raster_user_setup_normal
    variable raster_user_setup_micro

    set index [lsearch -exact $user_setup_name_list $name]
    if {$index < 0} {
        log_error "bad name $name for raster user setup"
        return -code error BAD_NAME
    }

    set use_collimator [get_rastering_data use_collimator]

    if {$use_collimator} {
        return [lindex $raster_user_setup_micro $index]
    } else {
        return [lindex $raster_user_setup_normal $index]
    }
}
proc set_rastering_user_setup { name value } {
    variable ::manualRastering::user_setup_name_list

    variable raster_user_setup_normal
    variable raster_user_setup_micro
    variable scan3DSetup_info

    set index [lsearch -exact $user_setup_name_list $name]
    if {$index < 0} {
        log_error "bad name $name for raster user setup"
        return -code error BAD_NAME
    }

    set use_collimator [lindex $scan3DSetup_info 4]
    save_rastering_data use_collimator $use_collimator

    switch -exact -- $name {
        time {
            set max_time [get_rastering_constant timeMax]
            set min_time [get_rastering_constant timeMin]

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

    if {$use_collimator} {
        set raster_user_setup_micro \
        [lreplace $raster_user_setup_micro $index $index $value]
        if {$name == "time"} {
            check_default_user_setup_micro
        }
    } else {
        set raster_user_setup_normal \
        [lreplace $raster_user_setup_normal $index $index $value]
        if {$name == "time"} {
            check_default_user_setup_normal
        }
    }
}
proc check_default_user_setup_normal { } {
    variable ::manualRastering::time_index
    variable ::manualRastering::isDefault_index
    variable raster_user_setup_normal

    set time    [lindex $raster_user_setup_normal $time_index]
    set timeDef [get_rastering_normal_constant timeDef]

    set oldIs  [lindex $raster_user_setup_normal $isDefault_index]
    if {abs($time - $timeDef) < 0.001} {
        set newIs 1
    } else {
        set newIs 0
    }
    if {$oldIs != $newIs} {
        set raster_user_setup_normal \
        [lreplace $raster_user_setup_normal $isDefault_index $isDefault_index $newIs]
    }
}
proc check_default_user_setup_micro { } {
    variable ::manualRastering::time_index
    variable ::manualRastering::isDefault_index
    variable raster_user_setup_micro

    set time    [lindex $raster_user_setup_micro $time_index]
    set timeDef [get_rastering_micro_constant timeDef]

    set oldIs  [lindex $raster_user_setup_micro $isDefault_index]
    if {abs($time - $timeDef) < 0.001} {
        set newIs 1
    } else {
        set newIs 0
    }
    if {$oldIs != $newIs} {
        set raster_user_setup_micro \
        [lreplace $raster_user_setup_micro $isDefault_index $isDefault_index $newIs]
    }
}
proc clear_rastering_user_setup { } {
    variable raster_user_setup_normal
    variable raster_user_setup_micro

    if {[isString raster_user_setup_micro]} {
        set raster_user_setup_micro \
        [lreplace $raster_user_setup_micro 4 5 {} {}]
    }
    
    set raster_user_setup_normal \
    [lreplace $raster_user_setup_normal 4 5 {} {}]
}
proc default_rastering_user_setup { } {
    variable ::manualRastering::isDefault_index

    variable raster_user_setup_normal
    variable raster_user_setup_micro

    if {[isString raster_user_setup_micro]} {
        set dist    [get_rastering_micro_constant distV]
        set stop    [get_rastering_micro_constant stopV]
        set delta   [get_rastering_micro_constant delta]
        set time    [get_rastering_micro_constant timeDef]
    
        set raster_user_setup_micro \
        [lreplace $raster_user_setup_micro 0 3 \
        $dist $stop $delta $time]
        set raster_user_setup_micro \
        [lreplace $raster_user_setup_micro $isDefault_index $isDefault_index 1]
    }

    set dist    [get_rastering_normal_constant distV]
    set stop    [get_rastering_normal_constant stopV]
    set delta   [get_rastering_normal_constant delta]
    set time    [get_rastering_normal_constant timeDef]
    
    set raster_user_setup_normal \
    [lreplace $raster_user_setup_normal 0 3 \
    $dist $stop $delta $time]
    set raster_user_setup_normal \
    [lreplace $raster_user_setup_normal 6 6 1]
}
proc update_rastering_user_setup { } {
    variable raster_user_setup_normal
    variable raster_user_setup_micro

    global gMotorDistance
    global gMotorBeamStop

    variable $gMotorDistance
    variable $gMotorBeamStop

    set dist [set $gMotorDistance]
    set stop [set $gMotorBeamStop]

    set raster_user_setup_normal \
    [lreplace $raster_user_setup_normal 0 1 $dist $stop]

    if {[isString raster_user_setup_micro]} {
        set raster_user_setup_micro \
        [lreplace $raster_user_setup_micro  0 1 $dist $stop]
    }
}
proc MRasteringGetExposureFromTime { time0 } {
    variable collect_default

    foreach {defD defT defA minT maxT minA maxA} $collect_default break

    #### here should be $minT
    set tPrefer $defT

    ### try prefered time first
    ### this can be negative
    set a [expr 100.0 * (1.0 - $time0 / $tPrefer)]
    if {$a < $minA} {
        ### use minA and increase time
        set a $minA
        set t [expr $time0 / (1.0 - $a / 100.0)]
        if {$t > $maxT} {
            log_warning exposure time limited to $maxT from $t
            CCrystalLog "exposure time limited to $maxT from $t"
            set t $maxT
        }
        ## assumed tPrefer >= minT
    } elseif {$a > $maxA} {
        ###scale down time from tPrefer
        set a $maxA
        set t [expr $time0 / (1.0 - $a / 100.0)]
        if {$t < $minT} {
            log_warning exposure time limited to $minT from $t
            CCrystalLog "exposure time limited to $minT from $t"
            set t $minI
        }
    } else {
        ##$a >= $minA && $a <= $maxA
        set t $tPrefer
    }
    return [list $a $t]
}

#### fixed step size
proc MRasteringDistanceAdjust { \
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

#### used by calling scan3DSetup
proc MRasteringDefaultAreasForScan3DSetup { contents_ } {
    set use_collimator [lindex $contents_ 4]
    save_rastering_data use_collimator $use_collimator

    set nw [get_rastering_constant colDef]
    set nh [get_rastering_constant rowDef]
    set nd $nh

    set row_height [expr 1000.0 * [get_rastering_constant rowHt]]
    set col_width  [expr 1000.0 * [get_rastering_constant colWd]]
    
    set w [expr $col_width * $nw]
    set h [expr $row_height * $nh]
    set d [expr $row_height * $nd]

    return [lreplace $contents_ 5 10 $w $h $d $nw $nh $nd]
}
proc MRasteringRangeCheckForScan3DSetup { contents_ {silent_ 0}} {
    set use_collimator [lindex $contents_ 4]

    ### this is required for get_rastering_constant to return right number
    save_rastering_data use_collimator $use_collimator

    set result $contents_

    set row_max    [get_rastering_constant rowMax]
    set row_min    [get_rastering_constant rowMin]
    set row_height [expr 1000.0 * [get_rastering_constant rowHt]]
    ## to micron

    set col_min    [get_rastering_constant colMin]
    set col_max    [get_rastering_constant colMax]
    set col_width  [expr 1000.0 * [get_rastering_constant colWd]]

    foreach {w h d} [lrange $contents_ 5 7] break

    foreach {new_w nw} [MRasteringDistanceAdjust \
    $w $col_width $col_min $col_max width $silent_] break

    foreach {new_h nh} [MRasteringDistanceAdjust \
    $h $row_height $row_min $row_max height $silent_] break

    foreach {new_d nd} [MRasteringDistanceAdjust \
    $d $row_height $row_min $row_max depth $silent_] break

    set sil_num_row [get_rastering_data sil_num_row]
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
proc MRasteringCheckScaling { } {
    set previous_max [get_rastering_data scaling_max]

    if {$previous_max == "" || $previous_max < 0} {
        
        ### first time increase, let go
        set max_weight [get_rastering_data max_weight]
        set max_index  [get_rastering_data max_index]
        save_rastering_data scaling_max   $max_weight
        save_rastering_data scaling_index $max_index
        MRasteringLog "first checkScaling, saved $max_weight $max_index"
        return 1
    }

    ## now check
    ## get the weight at the same spot.
    set wList [get_rastering_data raw_weight_list]
    set index [get_rastering_data scaling_index]

    set current_weight [lindex [lindex $wList $index] 0]
    MRasteringLog "new weight $current_weight"

    if {$previous_max == 0} {
        if {$current_weight > 0} {
            save_rastering_data scaling_max $current_weight 
            MRasteringLog "checkScaling,let go, previous=0"
            return 1
        }
        MRasteringLog "checkScaling failed both 0"
        return 0
    }

    set factor [expr $current_weight / double($previous_max)]
    set scale  [get_rastering_data scaling_scale]
    MRasteringLog "checkScaling : factor=$factor scale=$scale"
    if {abs($factor) >= 0.75 * abs($scale)} {

        save_rastering_data scaling_max $current_weight 

        MRasteringLog "checkScaling pass >= 0.75"
        return 1
    }
    MRasteringLog "checkScaling failed < 0.75"
    return 0
}
proc MRastering_setNodeExposing { view_index index } {
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    incr index

    if {$view_index == 0} {
        set result [string map {X D} $scan2DEdgeInfo]
        set result [lreplace $result 0 0 rastering]
        set scan2DEdgeInfo [lreplace $result $index $index X]
    } else {
        set result [string map {X D} $scan2DFaceInfo]
        set result [lreplace $result 0 0 rastering]
        set scan2DFaceInfo [lreplace $result $index $index X]
    }
    MRastering_sendInfoUpdate $view_index $index
    MRastering_saveAllToFile
}

### stopped, done, failed will trigger draw contours
proc MRastering_setRasterState { view_index state } {
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    if {$view_index == 0} {
        set scan2DEdgeInfo [lreplace $scan2DEdgeInfo 0 0 $state]
    } else {
        set scan2DFaceInfo [lreplace $scan2DFaceInfo 0 0 $state]
    }
    ### update whole info.  This is only called at the end or beginning
    MRastering_sendInfoUpdate $view_index
    MRastering_saveAllToFile
}
proc MRastering_setRasterStateFailed { flag } {
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    set status0 [lindex $scan2DEdgeInfo 0]
    set status1 [lindex $scan2DFaceInfo 0]
    switch -exact -- $status0 {
        aborted -
        stopped -
        failed -
        done {
        }
        default {
            MRastering_setRasterState 0 $flag
        }
    }
    switch -exact -- $status1 {
        aborted -
        stopped -
        failed -
        done {
        }
        default {
            MRastering_setRasterState 1 $flag
        }
    }
}
proc MRastering_setNodeDone { view_index index } {
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    incr index

    if {$view_index == 0} {
        set result [string map {X D} $scan2DEdgeInfo]
        set scan2DEdgeInfo [lreplace $result $index $index D]
    } else {
        set result [string map {X D} $scan2DFaceInfo]
        set scan2DFaceInfo [lreplace $result $index $index D]
    }
    MRastering_sendInfoUpdate $view_index $index
    MRastering_saveAllToFile
}
proc MRastering_restoreSelection { view_index } {
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    puts "restore selection $view_index"

    set result init
    if {$view_index == 0} {
        set listState $scan2DEdgeInfo
    } else {
        set listState $scan2DFaceInfo
    }

    set listResult [lrange $listState 1 end]
    foreach s $listResult {
        if {$s == "N"} {
            lappend result N
        } else {
            lappend result S
        }
    }
    if {$view_index == 0} {
        set scan2DEdgeInfo $result
    } else {
        set scan2DFaceInfo $result
    }
    MRastering_sendInfoUpdate $view_index
    MRastering_saveAllToFile
}
proc MRastering_getNextNode { view_index current } {
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    if {$view_index == 0} {
        set listState $scan2DEdgeInfo
    } else {
        set listState $scan2DFaceInfo
    }

    set listSelection [lrange $listState 1 end]
    set ll [llength $listSelection]

    set next [expr $current + 1]
    if {$next < 0} {
        set next 0
    }
    if {$next >= $ll} {
        set next 0
    }
    for {set i $next} {$i < $ll} {incr i} {
        if {$i == $current} {
            continue
        }
        set s [lindex $listSelection $i]
        if {$s == "S"} {
            return $i
        }
    }
    for {set i 0} {$i < $next} {incr i} {
        if {$i == $current} {
            continue
        }
        set s [lindex $listSelection $i]
        if {$s == "S"} {
            return $i
        }
    }
    return -1
}
proc MRastering_distributeResults { view_index compactResults } {
    variable ::manualRastering::listRow2Index

    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    puts "distribute results: map: $listRow2Index result: $compactResults"
    set ll0 [llength $compactResults]
    set ll1 [llength $listRow2Index]

    set ll [expr ($ll0>$ll1)?$ll1:$ll0]

    set numDistributed 0

    for {set i 0} {$i < $ll} {incr i} {
        set value [lindex $compactResults $i]
        set first [lindex $value 0]
        if {$first < 0} {
            continue
        }

        set index [lindex $listRow2Index  $i]
        incr index

        if {$view_index == 0} {
            set old [lindex $scan2DEdgeInfo $index]
            if {$old != $value} {
                set scan2DEdgeInfo \
                [lreplace $scan2DEdgeInfo $index $index $value]
                MRastering_sendInfoUpdate $view_index $index
            }
        } else {
            set old [lindex $scan2DFaceInfo $index]
            if {$old != $value} {
                set scan2DFaceInfo \
                [lreplace $scan2DFaceInfo $index $index $value]
                MRastering_sendInfoUpdate $view_index $index
            }
        }
        incr numDistributed
    }
    return $numDistributed
}
proc MRasteringDoTask { tag raster_setup view_index \
user sessionID directory file_prefix file_postfix \
} {
    variable ::manualRastering::listRow2Index
    variable ::manualRastering::numStopReceived

    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega
    variable center_crystal_msg

    MRasteringLog "MDoTask setup=$raster_setup"

    ###########no motor should be moving
    error_if_moving \
    sample_x \
    sample_y \
    sample_z \
    gonio_phi \
    gonio_omega

    save_rastering_data scan_phase $tag

    ### move to orig
    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $raster_setup break

    if {$numRow * $numColumn <= 1} {
        user_log_error raster "raster matrix size wrong"
        return 0
    }

    if {$numStopReceived > 0} {
        return 0
    }
    set center_crystal_msg "move to center of raster"
    MRasteringMoveToRaster $raster_setup
    set orig_phi $gonio_phi

    ###DEBUG
    #MRasteringLogData

    set center_crystal_msg "get stable ion chamber reading"
    move attenuation to 0
    wait_for_devices attenuation

    #scale exposure time according to ion chamber reading configed by
    #dose control
    if {$numStopReceived > 0} {
        return 0
    }
    if {[catch {
        set current_i2 [getStableIonCounts 0 1]
        MRasteringLog "stable ion chamber reading: $current_i2"
    } errorMsg]} {
        if {[string first aborted $errorMsg] >= 0} {
            return -code error aborted
        }
        if {[string first stopped $errorMsg] >= 0} {
            log_error stopped by user
            return 0
        }
        set current_i2 0
        MRasteringLog "ion chamber reading error: $errorMsg"
    }
    set old_i2 [get_rastering_data old_i2]
    if {![string is double -strict $old_i2]} {
        set old_i2 0
    }
    if {$current_i2 != 0 && $old_i2 != 0} {
        set old_exposure_time [get_rastering_data old_exposure_time]
        set new_exposure_time \
        [expr $old_exposure_time * abs( double($old_i2) / double($current_i2))]
        #MRasteringLog "by ion chamber: old time $old_exposure_time"
        #MRasteringLog "by ion chamber: old i2: $old_i2"
        #MRasteringLog "by ion chamber: new i2: $current_i2"
        #MRasteringLog "by ion chamber: new time: $new_exposure_time"


        set newTime [MRasteringAdjustExposureTimeByNumSpot $new_exposure_time]
        
        MRasteringLog "exposure time adjusted by ion chamber and numSpot to $newTime"
        user_log_note raster "exposure time adjusted by ion chamber and numSpot to $newTime"
    }
    
    ###retrieve collect image parameters
    set exposeTime [get_rastering_data exposure_time]
    set delta      [get_rastering_constant delta]
    set modeIndex  [get_rastering_data det_mode]

    save_rastering_data old_i2 $current_i2
    save_rastering_data old_exposure_time $exposeTime

    #####use attenuation if exposure time is less than 1 second
    MRasteringLog "Exposure time: $exposeTime"
    set rawExposureTime $exposeTime

    set_rastering_user_setup time$view_index $exposeTime

    foreach {att exposeTime} \
    [MRasteringGetExposureFromTime $exposeTime] break
    MRasteringLog "Exposure: time=$exposeTime at attenuation=$att"
    if {$numStopReceived > 0} {
        return 0
    }
    move attenuation to $att
    wait_for_devices attenuation

    set scan_phase [get_rastering_data scan_phase]
    set contents [format \
    "%s %dX%d %.3fX%.3fmm exposure: time $exposeTime attenuation=${att}%%" \
    $scan_phase $numColumn $numRow $cellWidth $cellHeight]
    
    MRasteringLog            $contents
    set center_crystal_msg "$scan_phase ${numColumn}X${numRow}"

    set ulog_contents [format "%s %dX%d %.3fX%.3fmm" \
    $scan_phase $numColumn $numRow $cellWidth $cellHeight]
    user_log_note raster $ulog_contents

    set ulog_contents [format "Exposure: %f s (time=%.3f s attenuation=%.1f %%)" \
    $rawExposureTime $exposeTime $att]
    user_log_note raster $ulog_contents

    set ext [get_rastering_data image_ext]
    set rootPattern ${file_prefix}_${file_postfix}_${tag}_%d_%d
    set pattern [file join $directory $rootPattern]

    set threshold [get_rastering_constant spotMin]
    MRastering_updateSetup $view_index $pattern $ext $threshold

    set log "filename                  phi    omega        x        y        z  bm_x  bm_y sil_row" 
    MRasteringLog $log
    user_log_note raster $log

    MRasteringClearResults

    if {$numStopReceived > 0} {
        return 0
    }

    set listRow2Index {}
    set next_index -1
    MRastering_setRasterState $view_index rastering
    while {1} {
        if {$numStopReceived > 0} {
            break
        }
        set next_index [MRastering_getNextNode $view_index $next_index]
        if {$next_index < 0} {
            MRasteringLog "This raster all done"
            break
        }
        set row_index [expr $next_index / $numColumn]
        set col_index [expr $next_index % $numColumn]
        set proj_v [expr $row_index - ($numRow - 1) / 2.0]
        set proj_h [expr $col_index - ($numColumn - 1) / 2.0]

        foreach {dx dy dz} \
        [calculateSamplePositionDeltaFromProjection \
        $raster_setup \
        $sample_x $sample_y $sample_z \
        $proj_v $proj_h] break

        #######move to position
        move sample_x by $dx
        move sample_y by $dy
        move sample_z by $dz
        wait_for_devices sample_x sample_y sample_z

        MRastering_setNodeExposing $view_index $next_index

        ###prepare filename for collect image
        set fileroot \
        [format $rootPattern [expr $row_index + 1] [expr $col_index + 1]]

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

        wait_for_operation $operationHandle
        set sil_row [llength $listRow2Index]
        set log_contents \
        [format "%-20s %8.3f %8.3f %8.3f %8.3f %8.3f %5.3f %5.3f %d" \
        $fileroot \
        $orig_phi $gonio_omega \
        $sample_x $sample_y $sample_z \
        [get_rastering_data beam_width] \
        [get_rastering_data beam_height] \
        $sil_row]

        MRasteringLog $log_contents
        user_log_note raster $log_contents
            
        #the data collection moves by delta. Move back.
        move gonio_phi to $orig_phi
        wait_for_devices gonio_phi

        ### add and analyze image
        if {[catch {
            MRasteringAddAndAnalyzeImage $user $sessionID $sil_row \
            $directory $fileroot
        } errMsg]} {
            log_warning submit image failed: $errMsg
            user_log_warning failed to submit $fileroot: $errMsg
        }

        lappend listRow2Index $next_index

        MRastering_setNodeDone $view_index $next_index

        MRasteringCheckImage $view_index $user $sessionID
    };
    ### need this to flush out last image
    start_operation detector_stop

    ####restore position
    move sample_x to $orig_x
    move sample_y to $orig_y
    move sample_z to $orig_z
    wait_for_devices sample_x sample_y sample_z

    if {$numStopReceived == 0} {

        set center_crystal_msg "$scan_phase wait for results"
        MRastering_setRasterState $view_index waiting_for_result
        MRasteringWaitForAllImage $view_index $user $sessionID
    }
    ###DEBUG
    #MRasteringLogData

    MRasteringLog "result matrix"
    user_log_note raster "Matrix of Spots"
    MRasteringLogWeight $view_index "%8d" "%8s" 0

    if {$numStopReceived > 0} {
        return 0
    }
    if {![MRasteringCheckWeights]} {
        return 0
    }

    MRastering_setRasterState $view_index done
    user_log_note raster \
    "--------------------$tag done----------------------------------"
    return 1
}
proc MRastering_flipSelection { view row col } {
    variable scan2DEdgeSetup
    variable scan2DFaceSetup
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    if {$view == 0} {
        set setup $scan2DEdgeSetup
        set info  $scan2DEdgeInfo
    } else {
        set setup $scan2DFaceSetup
        set info  $scan2DFaceInfo
    }

    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $setup break

    set index [expr $row * $numColumn + $col + 1]

    set current [lindex $info $index]
    send_operation_update row=$row col=$col index=$index curr=$current

    switch -exact -- $current {
        N -
        NA {
            set new S
        }
        default {
            set new N
        }
    }

    if {$view == 0} {
        set scan2DEdgeInfo [lreplace $info $index $index $new]
    } else {
        set scan2DFaceInfo [lreplace $info $index $index $new]
    }
    MRastering_sendInfoUpdate $view $index
    MRastering_saveAllToFile
}

proc MRastering_updateSetup { view_index pattern ext threshold } {
    variable scan2DEdgeSetup
    variable scan2DFaceSetup

    if {$view_index == 0} {
        set scan2DEdgeSetup \
        [lreplace $scan2DEdgeSetup 8 10 $pattern $ext $threshold]
        send_operation_update VIEW_SETUP0 $scan2DEdgeSetup
    } else {
        set scan2DFaceSetup \
        [lreplace $scan2DFaceSetup 8 10 $pattern $ext $threshold]
        send_operation_update VIEW_SETUP1 $scan2DFaceSetup
    }
    ## always update full info upon setup update
    MRastering_sendInfoUpdate $view_index

    MRastering_saveAllToFile
}

proc MRastering_initializeInfo { } {
    variable scan2DEdgeSetup
    variable scan2DFaceSetup
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    set enw [lindex $scan2DEdgeSetup 6]
    set enh [lindex $scan2DEdgeSetup 7]
    set fnw [lindex $scan2DFaceSetup 6]
    set fnh [lindex $scan2DFaceSetup 7]

    set lEdge [expr $enw * $enh]
    set lFace [expr $fnw * $fnh]
    
    set scan2DEdgeInfo "init [string repeat {S } $lEdge]"
    set scan2DFaceInfo "init [string repeat {S } $lFace]"

    ##MRastering_saveAllToFile
}
proc MRastering_createScan2DSetups { {new_file 0} } {
    variable ::scan3DSetup::bid
    variable scan3DSetup_info

    variable scan2DEdgeSetup
    variable scan2DFaceSetup
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    foreach {match orig snap0 snap1 useCollimator w h d nw nh nd} \
    $scan3DSetup_info break

    save_rastering_data use_collimator $useCollimator

    set orig0 [lindex $snap0 1]
    set orig1 [lindex $snap1 1]
    set a0 [lindex $orig0 3]
    set a1 [lindex $orig1 3]

    foreach {orig_x orig_y orig_z orig_a} $orig break

    if {$a0 == ""} {
        set a0 $orig_a
    }
    if {$a1 == ""} {
        set a1 [expr $orig_a + 90]
    }

    ### convert to mm
    set w [expr $w / 1000.0]
    set h [expr $h / 1000.0]
    set d [expr $d / 1000.0]

    set stepSizeW [expr $w / $nw]
    set stepSizeH [expr $h / $nh]
    set stepSizeD [expr $d / $nd]

    
    set scan2DEdgeSetup [list \
    $orig_x $orig_y $orig_z $a0 \
    $stepSizeH $stepSizeW $nh $nw \
    /tmp/not_exists \
    img 0 \
    ]

    set scan2DFaceSetup [list \
    $orig_x $orig_y $orig_z $a1 \
    $stepSizeD $stepSizeW $nd $nw \
    /tmp/not_exists \
    img 0 \
    ]

    send_operation_update VIEW_SETUP0 $scan2DEdgeSetup
    send_operation_update VIEW_SETUP1 $scan2DFaceSetup

    MRastering_initializeInfo
    MRastering_sendInfoUpdate 3
    clear_rastering_user_setup
    if {$new_file} {
        MRastering_saveAllToFile ${bid}_[getScrabbleForFilename].txt
    } else {
        MRastering_saveAllToFile
    }
}
proc MRastering_sendInfoUpdate { view_index {field -1}} {
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    switch -exact -- $view_index {
        0 {
            if {$field < 0} {
                send_operation_update VIEW_DATA0 $scan2DEdgeInfo
            } else {
                send_operation_update VIEW_NODE0 $field [lindex $scan2DEdgeInfo $field]
            }
        }
        1 {
            if {$field < 0} {
                send_operation_update VIEW_DATA1 $scan2DFaceInfo
            } else {
                send_operation_update VIEW_NODE1 $field [lindex $scan2DFaceInfo $field]
            }
        }
        default {
            send_operation_update VIEW_DATA0 $scan2DEdgeInfo
            send_operation_update VIEW_DATA1 $scan2DFaceInfo
        }
    }
}
proc MRastering_restoreInfoFromFile { } {
    variable ::manualRastering::saveRasterFile
    variable ::manualRastering::myOwnFilePath

    variable scan2DEdgeSetup
    variable scan2DFaceSetup
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    catch {
        if {$saveRasterFile != ""} {
            close $saveRasterFile
            set saveRasterFile ""
        }
    }

    if {![catch {open $myOwnFilePath r} saveRasterFile]} {
        gets $saveRasterFile scan2DEdgeSetup
        gets $saveRasterFile scan2DFaceSetup
        gets $saveRasterFile scan2DEdgeInfo
        gets $saveRasterFile scan2DFaceInfo
        close $saveRasterFile
        set saveRasterFile ""
        puts "edge info: $scan2DEdgeInfo"
        puts "face info: $scan2DFaceInfo"
    } else {
        puts "failed to readback raster info"
    }
}

proc MRastering_saveAllToFile { {filename ""} } {
    variable ::scan3DSetup::dir
    variable ::scan3DSetup::bid
    variable ::manualRastering::saveRasterFile
    variable ::manualRastering::myOwnFilePath

    variable scan3DSetup_info
    variable scan2DEdgeSetup
    variable scan2DFaceSetup
    variable scan2DEdgeInfo
    variable scan2DFaceInfo

    variable scan3DStatus

    variable raster_user_setup_normal
    variable raster_user_setup_micro

    set use_collimator [lindex $scan3DSetup_info 4]

    catch {
        if {$saveRasterFile != ""} {
            close $saveRasterFile
            set saveRasterFile ""
        }
    }

    if {$filename != ""} {
        set scan3DStatus [file join $dir $filename]
    }

    if {![catch {open $myOwnFilePath w} saveRasterFile]} {
        puts $saveRasterFile $scan2DEdgeSetup
        puts $saveRasterFile $scan2DFaceSetup
        puts $saveRasterFile $scan2DEdgeInfo
        puts $saveRasterFile $scan2DFaceInfo
        puts $saveRasterFile $scan3DSetup_info
        if {$use_collimator} {
            puts $saveRasterFile $raster_user_setup_micro
            set collimator_index [get_rastering_constant collimator]
        } else {
            puts $saveRasterFile $raster_user_setup_normal
            set collimator_index -1
        }
        set beamSizeInfo [list \
        $collimator_index \
        [get_rastering_data beam_width] \
        [get_rastering_data beam_height] \
        ]
        puts $saveRasterFile $beamSizeInfo

        close $saveRasterFile

        file copy -force $myOwnFilePath $scan3DStatus

    } else {
        log_warning failed to save information to file: $saveRasterFile
    }
    set saveRasterFile ""
}

#### state with "ing" means busy and cannot be skipped/stopped
proc MRastering_setState { state {push_out 0} } {
    variable rasterState

    send_operation_update RASTER_STATE $state
    set rasterState $state
    if {$push_out} {
        wait_for_time 0
    }
}
proc MRastering_saveSnapshotsForUser { user SID directory } {
    variable scan3DSetup_info

    foreach {match orig snap0 snap1} $scan3DSetup_info break

    set snap0 [lindex $snap0 0]
    set snap1 [lindex $snap1 0]

    set f0 [file tail $snap0]
    set f1 [file tail $snap1]

    set p0 [file join $directory $f0]
    set p1 [file join $directory $f1]

    impCopyFile $user $SID $snap0 $p0
    impCopyFile $user $SID $snap1 $p1
}
proc MRastering_saveRasterForUser { {put_into_history 0} } {
    variable scan3DStatus
    variable MRasteringSessionID
    variable scan3DHistory

    set user      [get_rastering_data user]
    set logPath [get_rastering_data log_file_name]

    set dir [file dirname $logPath]

    set path [file join $dir raster.txt]
    if {[catch {
        impCopyFile $user $MRasteringSessionID $scan3DStatus $path
    } errMsg]} {
        log_warning failed to save raster: $errMsg
        user_log_warning failed to save raster: $errMsg
    } else {
        log_note raster saved to $path
        if {$put_into_history} {
            set scan3DHistory [linsert $scan3DHistory 0 $path]
        }
    }
}
proc get_default_rastering_user_setup { } {
    set defaultMicro ""
    set defaultNormal ""
    if {[isString raster_user_setup_micro]} {
        set dist    [get_rastering_micro_constant distV]
        set stop    [get_rastering_micro_constant stopV]
        set delta   [get_rastering_micro_constant delta]
        set time    [get_rastering_micro_constant timeDef]
    
        set defaultMicro [list $dist $stop $delta $time {} {} 1 0 0]
    }

    set dist    [get_rastering_normal_constant distV]
    set stop    [get_rastering_normal_constant stopV]
    set delta   [get_rastering_normal_constant delta]
    set time    [get_rastering_normal_constant timeDef]
    
    set defaultNormal [list $dist $stop $delta $time {} {} 1 0 0]

    return [list $defaultNormal $defaultMicro]
}
