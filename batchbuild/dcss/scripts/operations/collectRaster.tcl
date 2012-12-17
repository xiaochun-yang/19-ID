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
# string "raster_msg"
# similar to "collect_msg"
# field 0:   0 (idle), 1 (running)
# field 1:   text message of current status
# field 2:   steps (sub state)
# field 3:   beamlinsID
# field 4:   username
# field 5:   raster name (not used yet, will be "raster"+ label for now
# field 6:   raster_number

package require DCSRaster

::DCS::Raster4DCSS gRaster4Run
::DCS::Raster4DCSS gRasterTemp

set CollectRasterDataNameList [list \
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

set collectRaster_sessionID ""
proc collectRaster_initialize { } {
    global gCurrentRasterNumber
    variable rastering_normal_name_list
    variable rastering_micro_name_list
    variable collect_raster_data_name_list
    variable CollectRasterDataNameList

    variable collectRaster_uniqueIDList

    set gCurrentRasterNumber -1

    set rastering_normal_name_list [::config getStr "rastering.normalConstantNameList"]
    set rastering_micro_name_list  [::config getStr "rastering.microConstantNameList"]
    set collectRaster_uniqueIDList [list]

    namespace eval ::collectRaster {
        global gBeamlineId
        set rastering_data ""
        set restore_cmd ""

        ### here row is row in spreadsheet
        set listRow2Index ""

        set saveRasterFile ""

        set myOwnFilePath ${gBeamlineId}_raster.save

        set user_setup_name_list $DCS::RasterBase::USER_SETUP_NAME_LIST

        set time_index      [lsearch -exact $user_setup_name_list time]
        set isDefault_index [lsearch -exact $user_setup_name_list is_default_time]
        set distance_index  [lsearch -exact $user_setup_name_list distance]
        set beamstop_index  [lsearch -exact $user_setup_name_list beamstop]

        puts "distance_index=$distance_index beamstop_index=$beamstop_index"

        set pendingLogContents ""
        set numSkipReceived 0

        #### allow to hit skip a few times to skip a lot
        #### otherwise, it only checks skip during collecting
        set ALLOW_SKIP_AHEAD 0
    }

    variable ::collectRaster::rastering_data

    set ll [llength $CollectRasterDataNameList]
    for {set i 0} {$i < $ll} {incr i} {
        lappend rastering_data $i
    }
    set collect_raster_data_name_list $CollectRasterDataNameList

    puts "init rastering_data to length =$ll"
}

#called at the end of operation
proc collectRaster_cleanup {} {
    global gCurrentRasterNumber
    variable raster_msg

    set gCurrentRasterNumber -1
    set raster_msg [lreplace $raster_msg 0 0 0]
}

#called when received stop operation message
proc collectRaster_stopCallback { } {
    variable ::collectRaster::numSkipReceived

    incr numSkipReceived

    puts "collectRaster_stopCallaback stopcount=$numSkipReceived"
}

proc collectRaster_start { rasterNumber userName sessionID args } {
    global gCurrentRasterNumber
    global gMotorBeamWidth
    global gMotorBeamHeight
    global gWaitForGoodBeamMsg

    variable ::collectRaster::ALLOW_SKIP_AHEAD
    variable ::collectRaster::numSkipReceived
    variable ::collectRaster::pendingLogContents

    variable raster_runs
    variable raster_msg
    variable beamlineID

    variable attenuation
    variable $gMotorBeamWidth
    variable $gMotorBeamHeight
    variable gonio_phi
    variable sample_x
    variable sample_y
    variable sample_z
    variable collectRaster_sessionID
    variable rasterState

    set pendingLogContents ""

    if [catch {block_all_motors;unblock_all_motors} errMsg] {
        log_error $errMsg
        puts "MUST wait all motors stop moving to start rastering"
        log_error "MUST wait all motors stop moving to start rastering"
        return -code error "MUST wait all motors stop moving to start"
    }

    if {$userName == "USER" || $userName == "USERNAME"} {
        set userName [get_operation_user]
        puts "use operation user: $userName"
    }

    if {$sessionID == "SID"} {
        set sessionID PRIVATE[get_operation_SID]
        puts "use operation SID: [SIDFilter $sessionID]"
    }

    set gCurrentRasterNumber $rasterNumber

    ####check and clear all run status skip this rasterNumber
    rasterRunsCheckRasterStatus $gCurrentRasterNumber

    puts "populate the calculator"
    collectRaster_populate $gCurrentRasterNumber

    set needUserLog 0
    set rasterLabel ""
    if {![collectRaster_checkRaster $rasterNumber $userName $sessionID needUserLog rasterLabel]} {
        return $rasterNumber
    }
    puts "after collectRaster_checkRaster"

    collectRaster_updateRun $gCurrentRasterNumber collecting

    if {$needUserLog} {
        ### not called by collectRasters, but directy by BluIce
        collectRaster_setStatus "precheck motor"
        correctPreCheckMotors
        user_log_note raster "======$userName started raster $rasterNumber ======"
    } else {
        user_log_note raster "======raster $rasterNumber======"
    }

    set data_root [lindex $args 0]
    if {$data_root == ""} {
        set data_root [::config getDefaultDataHome]
    }

    set rasterName [lindex $args 1]
    if {$rasterName == ""} {
        set rasterName "raster$rasterLabel"
    }

    set raster_msg [lreplace $raster_msg 0 6 \
    1 Starting 0 $beamlineID $userName $rasterName $rasterNumber]

    collectRaster_setState raster0 1

    ##### if NOT allow pause and continue, use clearResults
    ######gRaster4Run clearResults
    gRaster4Run clearIntermediaResults

    set gWaitForGoodBeamMsg [list raster_msg 1]

    collectRaster_setStatus "prepare directory and files"
    set crystalID [scan3DSetup_getCurrentCrystalID]
    set DateID    [timeStampForFileName]

    if {[string first $userName $data_root] < 0} {
        set directory [file join $data_root $userName raster $crystalID \
        raster${rasterNumber}_$DateID]
    } else {
        set directory [file join $data_root raster $crystalID \
        raster${rasterNumber}_$DateID]
    }

    set filePrefix ${beamlineID}_raster${rasterNumber}
    set timeStart [clock seconds]
    set filePostfix [format %X $timeStart]

    if {$sessionID == "SID"} {
        set sessionID PRIVATE[get_operation_SID]
        puts "collectRaster use operation SID: [SIDFilter $sessionID]"
    }

    #set log_file_name [file join $directory ${filePrefix}_${filePostfix}.log]
    set log_file_name [file join $directory ${filePrefix}.log]
    save_collect_raster_data log_file_name $log_file_name
    set contents "$userName start crystal rastering\n"
    append contents "directory=$directory filePrefix=$filePrefix filePostfix=$filePostfix\n"
    append contents [format "orig beamsize: %5.3fX%5.3f phi: %8.3f\n" \
    [set $gMotorBeamWidth] [set $gMotorBeamHeight] $gonio_phi]

    if {[catch {
        impWriteFile $userName $sessionID $log_file_name $contents false
    } errMsg]} {
        set gWaitForGoodBeamMsg ""
        collectRaster_updateRun $gCurrentRasterNumber paused
        collectRaster_setStatus "failed to create log file"
        user_log_error raster "create log file failed: $errMsg"
        if {$needUserLog} {
            user_log_note  raster "=======end raster $rasterNumber========"
        }
        return -code error $errMsg
    }
    user_log_note raster "log_file=$log_file_name"

    if {[catch {
        collectRaster_saveSnapshotsForUser $userName $sessionID $directory
    } errMsg]} {
        set gWaitForGoodBeamMsg ""
        collectRaster_updateRun $gCurrentRasterNumber paused
        collectRaster_setStatus "failed to save snapshot files"
        user_log_error raster "save snapshot files for user failed: $errMsg"
        if {$needUserLog} {
            user_log_note  raster "=======end raster $rasterNumber========"
        }
        return -code error $errMsg
    }

    #### we need these to write log file
    save_collect_raster_data user $userName
    set collectRaster_sessionID $sessionID
    set use_collimator [gRaster4Run useCollimator]
    save_collect_raster_data use_collimator $use_collimator

    if {$use_collimator} {
        user_log_note raster "use collimator"
    } else {
        user_log_note raster "use normal beam"
    }

    ##### save to restore after operation
    collectRaster_save4Restore

    save_collect_raster_data old_i2 0

    ################catch everything##############
    # in case of any failure, restore
    # beam size and phi.
    # in case of total failure, sample_x, y z
    # will be restored.
    ##############################################

    set result "success"
    if {[catch {
        if {!$ALLOW_SKIP_AHEAD} {
            set numSkipReceived 0
            clear_operation_stop_flag
        }

        ###do not delete until check tight up in sil.
        ###collectRaster_deleteDefaultSil

        collectRaster_setStatus "prepare special spreadsheet"
        collectRaster_createDefaultSil
 
        ### skip once still need this but skip twice will not need this anymore
        collectRaster_setStatus "setup beam"
        collectRaster_setupEnvironments

        ###DEBUG
        puts "log constant"
        collectRaster_logConstant

        puts "run......."
        if {![eval collectRaster_run \
        $userName $sessionID $directory $filePrefix $filePostfix]} {
            log_error manual scan failed
            return -code error "manual rastering failed"
        }
        collectRaster_log "manual scan successed"
    } errMsg] == 1} {
        if {$errMsg != ""} {
            set result $errMsg
            log_warning "crystal rastering failed: $errMsg"
            collectRaster_log "crystal rastering failed: $result"
            collectRaster_setStatus "error: $result"
        }
    }

    collectRaster_setState ending 1

    collectRaster_saveRasterForUser
    collectRaster_deleteDefaultSil

    start_recovery_operation detector_stop

    if {[catch {
        collectRaster_restore
    } errMsg]} {
        ### most likely, aborted already
        puts "collectRaster_restore failed: $errMsg"
    }

    collectRaster_log "end of crystal rastering"

    set timeEnd [clock seconds]

    set timeUsed [expr $timeEnd - $timeStart]
    set timeUsedText [secondToTimespan $timeUsed]
    collectRaster_log "time used: $timeUsedText ($timeUsed seconds)" 1 1
    user_log_note raster "time used: $timeUsedText ($timeUsed seconds)"

    collectRaster_logData

    ### this may move some motors, like collimator, beamstop, lights
    if {$needUserLog} {
        cleanupAfterAll
    }
    set gWaitForGoodBeamMsg ""

    ### draw cross
    collectRaster_setState idle

    if {$result != "success"} {
        if {[gRaster4Run noneDone]} {
            collectRaster_updateRun $gCurrentRasterNumber inactive
        } else {
            collectRaster_updateRun $gCurrentRasterNumber paused
        }
        user_log_error raster "raster failed: $result"
        if {$needUserLog} {
            user_log_note  raster "=======end raster $rasterNumber========"
        }
        return -code error $result
    }
    if {$needUserLog} {
        user_log_note  raster "=======end raster $rasterNumber========"
    }
    if {[gRaster4Run allDone]} {
        collectRaster_updateRun $gCurrentRasterNumber complete
    } elseif {[gRaster4Run noneDone]} {
        collectRaster_updateRun $gCurrentRasterNumber inactive
    } else {
        collectRaster_updateRun $gCurrentRasterNumber skipped
        #collectRaster_updateRun $gCurrentRasterNumber paused
    }
    return $result
}

proc checkRasterUserSetup { rasterNumber preCheck } {
    global gMotorBeamStop
    global gMotorDistance
    variable ::rasterRunsConfig::dir
    variable raster_run$rasterNumber

    set file [lindex [set raster_run$rasterNumber] 2]

    if {$file == "" || $file == "not_exists"} {
        if {$preCheck} {
            return 1
        } else {
            log_error raster $rasterNumber not defined.
            return 0
        }
    }

    set path [file join $dir $file]

    if {[catch {gRasterTemp load $rasterNumber $path} errMsg]} {
        if {!$preCheck} {
            log_error load raster $rasterNumber failed: $errMsg
            return 0
        } else {
            return 1
        }
    }
    set userSetup [gRasterTemp getUserSetup]
    if {[llength $userSetup] < 2} {
        if {!$preCheck} {
            log_error raster $rasterNumber bad user setup
            return 0
        } else {
            return 1
        }
    }
    foreach {distance beamstop} $userSetup break
    
    if {[adjustPositionToLimit $gMotorDistance distance 1]} {
        log_error raster $rasterNumber detector distance setting bad
        return 0
    }
    if {[adjustPositionToLimit $gMotorBeamStop beamstop 1]} {
        log_error raster $rasterNumber beamstop setting bad
        return 0
    }
    return 1
}
proc collectRaster_populate { rasterNumber } {
    variable ::rasterRunsConfig::dir
    variable raster_run$rasterNumber
    set file [lindex [set raster_run$rasterNumber] 2]
    set path [file join $dir $file]
    gRaster4Run load $rasterNumber $path


    if {[gRaster4Run isInline]} {
        set centerX [getInlineCameraConstant zoomMaxXAxis]
        set centerY [getInlineCameraConstant zoomMaxYAxis]
    } else {
        set centerX [getSampleCameraConstant zoomMaxXAxis]
        set centerY [getSampleCameraConstant zoomMaxYAxis]
    }
    #### this will recreate the 2D setups from current beam center
    gRaster4Run setBeamCenter $centerX $centerY
}

#### return 1 if OK to run
#### return 0 if no need to run
#### throw error on error
#### preCheck is called by collectRasters to make sure all runs are OK
#### We should use gRasterTemp here.  It may be called by collectRasters, not
#### collectRaster.
proc collectRaster_checkRaster { rasterNumber userName sessionID \
rasterLabelREF need_user_logREF \
{preCheck 0}} {
    global gRaster4Run
	global gClient
	global gPauseDataCollection
    variable raster_msg
    variable raster_run$rasterNumber

    upvar $need_user_logREF needUserLog
    upvar $rasterLabelREF runLabel

    ### this should be and is useing gRasterTemp
    if {![checkRasterUserSetup $rasterNumber $preCheck]} {
        return 0
    }

    ## called by collectRasters to check distance, beamstop 
    if {$preCheck} {
        return 1
    }
    ### now we can use gRaster4Run

	#find out the operation handle
	set op_info [get_operation_info]
    set op_name [lindex $op_info 0]
	set operationHandle [lindex $op_info 1]

	#find out the client id that started this operation
	set clientId [expr int($operationHandle)]
	#get the name of the user that started this operation
	set clientUserName $gClient($clientId)

	if { $clientUserName != $userName } {
		#the user didn't start this operation. 
        #Probably started by collectRasters operation
		#the pause flag has already been set.
		if {  $clientUserName != "self" } {
			#it wasn't the user or the self client.
            set raster_msg [lreplace $raster_msg 0 1 0 \
            "Invalid to start rastering for $clientUserName"]
			return -code error hacker
		}
	}
    if {$clientUserName != "self"} {
        set needUserLog 1
		set gPauseDataCollection 0
    }

    puts "collectRaster_checkRaster:: get runstatus"
	set rasterStatus [lindex [set raster_run$rasterNumber] 0]
	set runLabel     [lindex [set raster_run$rasterNumber] 1]
	if { $rasterStatus == "disabled"  } {
        set raster_msg [lreplace $raster_msg 0 1 0 \
        "raster $rasterNumber is disabled"]
		return 0
	}

	#Stop data collection now if we have already been paused.
	if {$gPauseDataCollection } {
		error paused
    }

	if {$rasterNumber != 0} {
        if {[gRaster4Run allDone]} {
            set raster_run$rasterNumber \
            [lreplace [set raster_run$rasterNumber] 0 0 complete]
            set raster_msg [lreplace $raster_msg 0 1 0 \
            "raster $rasterNumber is completed"]
		    return 0
        }
    }

    return 1
}
proc collectRaster_setupEnvironments { } {
    variable ::collectRaster::numSkipReceived

    global gMotorBeamWidth
    global gMotorBeamHeight
    global gMotorBeamStop
    global gMotorDistance
	global gPauseDataCollection

	if {$gPauseDataCollection} {
		error paused
    }

    if {$numSkipReceived > 1} {
        return -code error "skipped by user"
    }

    set use_collimator [get_collect_raster_data use_collimator]

    set movingList ""
    if {$use_collimator} {
        collectRaster_log "use collimator"
        collectRaster_setStatus "prepare collimator"
        set index [get_collect_raster_constant collimator]
        set collimatorInfo [collimatorMove_start $index]
        foreach {- show micr bw bh } $collimatorInfo break
        if {!$show || !$micr} {
            log_severe raster collimator config wrong: selected hidden or non-microbeam index
            log_severe DEBUG: index=$index collimatorInfo=$collimatorInfo
            foreach {bw bh} [collimatorMoveFirstMicron] break
        }
    } else {
        collectRaster_log "use normal beam"

        if {[isOperation collimatorMove]} {
            collimatorNormalIn
        }

        set bw [get_collect_raster_constant beamWd]
        set bh [get_collect_raster_constant beamHt]
        move $gMotorBeamWidth  to $bw
        move $gMotorBeamHeight to $bh
        lappend movingList $gMotorBeamWidth $gMotorBeamHeight
    }
    save_collect_raster_data beam_width $bw
    save_collect_raster_data beam_height $bh

    set stop_move [get_collect_raster_constant stopMove]
    set stop_v    [get_collect_raster_user_setup beamstop]

    set dist_move [get_collect_raster_constant distMove]
    set dist_v    [get_collect_raster_user_setup distance]
    if {$stop_move && $numSkipReceived < 2} {
        move $gMotorBeamStop to $stop_v
        lappend movingList $gMotorBeamStop
    }
    if {$dist_move && $numSkipReceived < 2} {
        move $gMotorDistance to $dist_v
        lappend movingList $gMotorDistance
    }
    if {$numSkipReceived < 2} {
        collectRaster_setStatus "prepare $movingList"
    } else {
        collectRaster_setStatus "stopping $movingList"
    }
    if {$movingList != ""} {
        eval wait_for_devices $movingList
    }
    if {$numSkipReceived > 1} {
        return -code error "skipped by user"
    }
	if {$gPauseDataCollection} {
		error paused
    }

    #set exposureTime    [get_collect_raster_constant timeDef]
    set exposureTime    [get_collect_raster_user_setup time]
    set newTime [collectRaster_setExposureTime $exposureTime]
    if {$newTime != $exposureTime} {
        collectRaster_log "exposure time inited to $newTime"
    }
}
proc collectRaster_run { user sessionID directory \
filePrefix filePostfix } {
	global gPauseDataCollection

    variable ::collectRaster::numSkipReceived
    variable ::collectRaster::ALLOW_SKIP_AHEAD

    variable energy

    if {$gPauseDataCollection} {
        error paused
    }
    if {$numSkipReceived > 1} {
        return -code error "skipped by user"
    }

    set view0_defined [gRaster4Run getViewDefined 0]
    set skip_view0 [get_collect_raster_user_setup skip0]

    if {$view0_defined && $skip_view0 != "1" && $numSkipReceived == 0} {
        save_collect_raster_data scaling_max -1
    
        set maxTry [get_collect_raster_constant maxTry]
        set timesTrying 0
        set tag VIEW1
    
        ####${filePrefix} ${filePostfix}_${timesTrying} 

        ## This will be called several times.
        collectRaster_saveRasterForUser

        set energyFromLastRun [get_collect_raster_user_setup energy]
        if {[string is double -strict $energyFromLastRun] \
        && abs($energyFromLastRun - $energy) > 10.0} {
            ### comment this section if you want to allow user run it
            log_error energy changed from last run $energyFromLastRun eV
            return -code error SETUP_CHANGED

            ### we will clear up old results if energy changed
            colletRaster_restoreSelection 0
            colletRaster_restoreSelection 1
            log_warning previous results cleared
            log_warning running from different energy
        }

        puts "get time0"
        set time0FromLastRun [get_collect_raster_user_setup time0]
        if {[string is double -strict $time0FromLastRun]} {
            set newTime [collectRaster_setExposureTime $time0FromLastRun]
            ### no need, just to be safe
            save_collect_raster_data old_i2 0

            if {$newTime != $time0FromLastRun } {
                colletRaster_restoreSelection 0

                log_warning time from previous run $time0FromLastRun adjusted \
                to $newTime
                log_warning previous results cleared

                user_log_warning time from previous run $time0FromLastRun \
                adjusted to $newTime
            }
        }

        puts "doTask"
        while {![collectRaster_doTask $tag 0 \
        $user $sessionID $directory \
        ${filePrefix} ${timesTrying} \
        ]} {
            if {$numSkipReceived > 0} {
                collectRaster_setRasterState 0 skipped
                user_log_error raster \
                "--------------------$tag skipped by user-----------------------"
                log_warning skip current view and jump to next view
                break
            }
            if {![collectRaster_increaseExposeTime]} {
                collectRaster_setRasterState 0 failed
                user_log_error raster \
                "--------------------$tag no diffraction------------------------"
                log_error "manual collimator scan failed - no diffraction"
                collectRaster_setStatus "error: no diffraction"
                break
            }
            if {![collectRaster_checkScaling]} {
                collectRaster_setRasterState 0 failed
                user_log_error raster \
                "--------------------$tag no diffraction------------------------"
                log_error "manual collimator scan failed - no diffraction"
                collectRaster_setStatus "error: no diffraction"
                break
            }
            incr timesTrying
            if {$timesTrying > $maxTry} {
                collectRaster_setRasterState 0 failed
                collectRaster_setStatus "reached max trying times, skip"
                collectRaster_log "reached max trying times, skip"
                user_log_error raster "$tag reached max retry"
                "--------------------$tag reached max retry---------------------"
                break
            }
            colletRaster_restoreSelection 0
        }
        collectRaster_saveRasterForUser
    }

    set view1_defined [gRaster4Run getViewDefined 1]
    set skip_view1 [get_collect_raster_user_setup skip1]
    if {!$view1_defined || $skip_view1 == "1"} {
        return 1
    }

    ### now Stop means stop
    collectRaster_setState raster1 1
    variable rasterState
    puts "STOP STOP STOP=$numSkipReceived state=$rasterState"

    if {!$ALLOW_SKIP_AHEAD} {
        set numSkipReceived 0
        clear_operation_stop_flag
    } else {
        if {$numSkipReceived > 0} {
            incr numSkipReceived -1
        }
        if {$numSkipReceived <= 0} {
            set numSkipReceived 0
            clear_operation_stop_flag
        }
    }

    set scalingTime [get_collect_raster_constant scaling]
    set time1FromLastRun [get_collect_raster_user_setup time1]
    if {[string is double -strict $time1FromLastRun]} {
        set newTime [collectRaster_setExposureTime $time1FromLastRun]
        set scalingTime 0

        if {$newTime != $time0FromLastRun} {
            colletRaster_restoreSelection 1

            log_warning time from previous run $time1FromLastRun adjusted \
            to $newTime
            log_warning previous results cleared

            user_log_warning time from previous run $time1FromLastRun \
            adjusted to $newTime
        }
    }

    if {$scalingTime} {
        set timeUser [get_collect_raster_user_setup time]
        set timeDef  [get_collect_raster_constant timeDef]
        if {abs($timeUser - $timeDef) > 0.001} {
            collectRaster_log "no time scaling, user has specified exposure time"
            set scalingTime 0
        }
    }
    if {!$scalingTime} {
        save_collect_raster_data old_i2 0

        ### not sure about this
        #set exposureTime    [get_collect_raster_constant timeDef]
        #set newTime [collectRaster_setExposureTime $exposureTime]
        #if {$newTime != $exposureTime} {
        #    collectRaster_log "exposure time inited to $newTime"
        #}
    }

    set tag VIEW2
    set file_prefix ${filePrefix}_$tag
    save_collect_raster_data scaling_max -1
    set timesTrying 0
    while {![collectRaster_doTask $tag 1 \
    $user $sessionID $directory \
    ${filePrefix} ${timesTrying} \
    ]} {
        if {$numSkipReceived} {
            collectRaster_setRasterState 1 skipped
            log_error skipped by user
            user_log_error raster  \
            "--------------------$tag skipped by user-----------------------"
            return 0
        }
        if {![collectRaster_increaseExposeTime]} {
            collectRaster_setRasterState 1 failed
            user_log_error raster \
            "--------------------$tag no diffraction------------------------"
            log_error "manual collimator scan failed - no diffraction"
            collectRaster_setStatus "error: no diffraction"
            return 0
        }
        if {![collectRaster_checkScaling]} {
            collectRaster_setRasterState 1 failed
            user_log_error raster \
            "--------------------$tag no diffraction------------------------"
            log_error "manual collimator scan failed - no diffraction"
            collectRaster_setStatus "error: no diffraction"
            return 0
        }
        incr timesTrying
        if {$timesTrying > $maxTry} {
            collectRaster_setRasterState 1 failed
            collectRaster_setStatus "reached max trying times, stop"
            collectRaster_log "reached max trying times, stop"
            user_log_error raster \
            "--------------------$tag reached max retry---------------------"
            return 0
        }
        colletRaster_restoreSelection 1
    }
    return 1
}
proc collectRaster_doTask { tag view_index \
user sessionID directory file_prefix file_postfix \
} {

    puts "DEBUG doTask tag=$tag view=$view_index $user"

	global gPauseDataCollection

    variable ::collectRaster::listRow2Index
    variable ::collectRaster::numSkipReceived

    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega
    variable energy

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

    save_collect_raster_data scan_phase $tag

    set raster_setup [gRaster4Run getSetup $view_index]
    collectRaster_log "MDoTask setup=$raster_setup"
    ### log message needs these info
    foreach {- - - - cellHeight cellWidth \
    numRow numColumn} $raster_setup break

    if {$numRow * $numColumn <= 1} {
        user_log_error raster "raster matrix size wrong"
        return 0
    }

    if {$numSkipReceived > 0} {
        return 0
    }
    collectRaster_setStatus "move to center of raster" [expr $view_index + 1]
    collectRaster_moveToRaster $view_index
    set orig_phi $gonio_phi

    ###DEBUG
    #collectRaster_logData

    collectRaster_setStatus "get stable ion chamber reading"
    move attenuation to 0
    wait_for_devices attenuation

    #scale exposure time according to ion chamber reading configed by
    #dose control
    if {$numSkipReceived > 0} {
        return 0
    }
    if {[catch {
        set current_i2 [getStableIonCounts 0 1]
        collectRaster_log "stable ion chamber reading: $current_i2"
    } errorMsg]} {
        if {[string first aborted $errorMsg] >= 0} {
            return -code error aborted
        }
        if {[string first skipped $errorMsg] >= 0} {
            log_error skipped by user
            return 0
        }
        set current_i2 0
        collectRaster_log "ion chamber reading error: $errorMsg"
    }
    set old_i2 [get_collect_raster_data old_i2]
    if {![string is double -strict $old_i2]} {
        set old_i2 0
    }
    if {$current_i2 != 0 && $old_i2 != 0} {
        set old_exposure_time [get_collect_raster_data old_exposure_time]
        set new_exposure_time \
        [expr $old_exposure_time * abs( double($old_i2) / double($current_i2))]
        #collectRaster_log "by ion chamber: old time $old_exposure_time"
        #collectRaster_log "by ion chamber: old i2: $old_i2"
        #collectRaster_log "by ion chamber: new i2: $current_i2"
        #collectRaster_log "by ion chamber: new time: $new_exposure_time"

        set newTime [collectRaster_adjustExposureTimeByNumSpot $new_exposure_time]
        
        collectRaster_log "exposure time adjusted by ion chamber and numSpot to $newTime"
        user_log_note raster "exposure time adjusted by ion chamber and numSpot to $newTime"
    }
    
    ###retrieve collect image parameters
    set exposeTime [get_collect_raster_data exposure_time]
    set delta      [get_collect_raster_constant delta]
    set modeIndex  [get_collect_raster_data det_mode]

    save_collect_raster_data old_i2 $current_i2
    save_collect_raster_data old_exposure_time $exposeTime

    #####use attenuation if exposure time is less than 1 second
    collectRaster_log "Exposure time: $exposeTime"
    set rawExposureTime $exposeTime

    set_collect_raster_user_setup time$view_index $exposeTime
    set_collect_raster_user_setup energy $energy

    foreach {att exposeTime} \
    [getExposureSetupFromTime $exposeTime] break
    collectRaster_log "Exposure: time=$exposeTime at attenuation=$att"
    if {$numSkipReceived > 0} {
        return 0
    }
    move attenuation to $att
    wait_for_devices attenuation

    set scan_phase [get_collect_raster_data scan_phase]
    set contents [format \
    "%s %dX%d %.3fX%.3fmm exposure: time $exposeTime attenuation=${att}%%" \
    $scan_phase $numColumn $numRow $cellWidth $cellHeight]
    
    collectRaster_log            $contents
    collectRaster_setStatus "$scan_phase ${numColumn}X${numRow}"

    set ulog_contents [format "%s %dX%d %.3fX%.3fmm" \
    $scan_phase $numColumn $numRow $cellWidth $cellHeight]
    user_log_note raster $ulog_contents

    set ulog_contents [format "Exposure: %f s (time=%.3f s attenuation=%.1f %%)" \
    $rawExposureTime $exposeTime $att]
    user_log_note raster $ulog_contents

    set ext [get_collect_raster_data image_ext]
    set rootPattern ${file_prefix}_${file_postfix}_${tag}_%d_%d
    set pattern [file join $directory $rootPattern]

    set threshold [get_collect_raster_constant spotMin]
    collectRaster_updateSetup $view_index $pattern $ext $threshold

    set log "filename                  phi    omega        x        y        z  bm_x  bm_y sil_row" 
    collectRaster_log $log
    user_log_note raster $log

    collectRaster_clearResult

    if {$numSkipReceived > 0} {
        return 0
    }

    set listRow2Index {}
    set next_index -1
    collectRaster_setRasterState $view_index rastering
    while {1} {
        if {$gPauseDataCollection} {
            collectRaster_setRasterState $view_index paused
            error paused
        }

        if {$numSkipReceived > 0} {
            break
        }
        set next_index [collectRaster_getNextNode $view_index $next_index]
        if {$next_index < 0} {
            collectRaster_log "This raster all done"
            break
        }
        set nodeInfo [gRaster4Run getNodePosition $view_index $next_index]
        foreach {x y z row_index col_index} $nodeInfo break

        #######move to position
        move sample_x to $x
        move sample_y to $y
        move sample_z to $z
        wait_for_devices sample_x sample_y sample_z

        gRaster4Run setNodeState $view_index $next_index X

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

        if {[catch {
            wait_for_operation $operationHandle
        } detErrMsg]} {
            log_error detector error $detErrMsg
            return -code error "Detector error: $detErrMsg"
        }
        set sil_row [llength $listRow2Index]
        set log_contents \
        [format "%-20s %8.3f %8.3f %8.3f %8.3f %8.3f %5.3f %5.3f %d" \
        $fileroot \
        $orig_phi $gonio_omega \
        $sample_x $sample_y $sample_z \
        [get_collect_raster_data beam_width] \
        [get_collect_raster_data beam_height] \
        $sil_row]

        collectRaster_log $log_contents
        user_log_note raster $log_contents
            
        #the data collection moves by delta. Move back.
        move gonio_phi to $orig_phi
        wait_for_devices gonio_phi

        ### add and analyze image
        if {[catch {
            collectRaster_addAndAnalyzeImage $user $sessionID $sil_row \
            $directory $fileroot
        } errMsg]} {
            log_warning submit image failed: $errMsg
            user_log_warning failed to submit $fileroot: $errMsg
        }

        lappend listRow2Index $next_index

        gRaster4Run setNodeState $view_index $next_index D

        collectRaster_checkImage $view_index $user $sessionID
    };
    ### need this to flush out last image
    start_operation detector_stop

    ####restore position
    collectRaster_moveToRaster $view_index

    if {$numSkipReceived == 0} {

        collectRaster_setStatus "$scan_phase wait for results"
        collectRaster_setRasterState $view_index waiting_for_result
        collectRaster_waitForAllImage $view_index $user $sessionID
    }
    ###DEBUG
    #collectRaster_logData

    collectRaster_log "result matrix"
    user_log_note raster "Matrix of Spots"
    collectRaster_logWeight $view_index "%8d" "%8s"

    if {$numSkipReceived > 0} {
        return 0
    }
    if {![collectRaster_checkWeights]} {
        return 0
    }

    collectRaster_setRasterState $view_index done
    user_log_note raster \
    "--------------------$tag done----------------------------------"
    return 1
}
proc collectRaster_checkImage { view_index user sessionID } {
    variable ::collectRaster::listRow2Index

    set sil_id [get_collect_raster_data sil_id]
    set numList [getNumSpotsData $user $sessionID $sil_id]
    puts "numList: $numList"

    set ll [llength $listRow2Index]
    set end [expr $ll - 1]

    puts "ll=$ll"
    
    set result [lrange $numList 0 $end]
    set numValid [collectRaster_distributeResult $view_index $result]

    save_collect_raster_data raw_weight_list $result

    set max_weight [collectRaster_getMaxWeight $result]
    set min_weight_to_proceed [get_collect_raster_constant spotMin]
    if {$max_weight < $min_weight_to_proceed} {
        save_collect_raster_data passed_threshold 1
    } else {
        save_collect_raster_data passed_threshold 0
    }
    return $numValid
}

proc collectRaster_waitForAllImage { view_index user sessionID } {
	global gPauseDataCollection

    variable ::collectRaster::listRow2Index
    variable ::collectRaster::numSkipReceived

    set ll [llength $listRow2Index]
    
    set llResult [collectRaster_checkImage $view_index $user $sessionID]
    if {$llResult > 0} {
        log_warning got $llResult of $ll
    }

    set previous_ll $llResult
    while {$llResult < $ll} {
	    if {$gPauseDataCollection } {
            collectRaster_setRasterState $view_index paused
		    error paused
        }
        if {$numSkipReceived} {
            log_error skipped by user
            return
        }
        wait_for_time 1000
        if {[catch {
            set llResult [collectRaster_checkImage $view_index $user $sessionID]
        } err]} {
            log_warning failed to wait for all data: $err
            break
        }
        if {$llResult > $previous_ll} {
            log_warning got $llResult of $ll
            set previous_ll $llResult
        }
    }
    collectRaster_setRasterState $view_index checking_results
}
proc collectRaster_distributeResult { view_index compactResults } {
    variable ::collectRaster::listRow2Index

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

        gRaster4Run setNodeState $view_index $index $value

        incr numDistributed
    }
    return $numDistributed
}
### This is exactly  MRastering_setState 
### no change yet
#### state with "ing" means busy and cannot be skipped/skipped
proc collectRaster_setState { state {push_out 0} } {
    variable rasterState

    send_operation_update RASTER_STATE $state
    set rasterState $state
    if {$push_out} {
        wait_for_time 0
    }
}
proc collectRaster_moveToRaster { view_index } {
    variable gonio_omega

    set orig [gRaster4Run getSetup $view_index]

    foreach {orig_x orig_y orig_z orig_a} $orig break

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
### skipped, done, failed will trigger draw contours
proc collectRaster_setRasterState { view_index state } {
    gRaster4Run setViewState $view_index $state
}
proc collectRaster_clearResult { } {
    variable collectRaster_sessionID
    set user [get_collect_raster_data user]
    set sessionID $collectRaster_sessionID
    set sil_id [get_collect_raster_data sil_id]
    resetSpreadsheet $user $sessionID $sil_id

    #gRaster4Run clearResults
}
proc collectRaster_deleteDefaultSil { } {
    variable collectRaster_sessionID

    set user [get_collect_raster_data user]
    set sessionID $collectRaster_sessionID
    ###try to delete the previous SIL, may belong to another user
    set sil_id [get_collect_raster_data sil_id]
    if {[string is integer -strict $sil_id] && $sil_id > 0} {
        if {[catch {
            deleteSil $user $sessionID $sil_id
            save_collect_raster_data sil_id 0
        } errMsg]} {
            puts "failed to delete SIL $sil_id: $errMsg"
        }
    }
}
proc collectRaster_createDefaultSil { } {
    variable collectRaster_sessionID
    variable collectRaster_uniqueIDList

    ####create new sil and save the id to the string
    set user [get_collect_raster_data user]
    set sessionID $collectRaster_sessionID
    set sil_id [createDefaultSil $user $sessionID \
    "&templateName=crystal_centering&containerType=crystal_centering"]
    puts "new sil_id: $sil_id"

    if {![string is integer -strict $sil_id] || $sil_id < 0} {
        return -code error "create default sil failed: sil_id: $sil_id not > 0"
    }

    ### get uniqueID for each row
    if {[catch {
        set collectRaster_uniqueIDList [getSpreadsheetProperty \
        $user $sessionID $sil_id UniqueID]
    } errMsg]} {
        set collectRaster_uniqueIDList [list]
        log_error failed to get uniqueIDList: $errMsg
    }

    save_collect_raster_data sil_id $sil_id

    set sil_num_row [llength $collectRaster_uniqueIDList]
    if {$sil_num_row < 96} {
        set sil_num_row 625
    }
    save_collect_raster_data sil_num_row $sil_num_row
}
proc get_collect_raster_data { name } {
    variable ::collectRaster::rastering_data

    set index [collectRaster_dataNameToIndex $name]
    return [lindex $rastering_data $index]
}

proc save_collect_raster_data { name value } {
    variable ::collectRaster::rastering_data

    set index [collectRaster_dataNameToIndex $name]
    set rastering_data [lreplace $rastering_data $index $index $value]
}

proc collectRaster_dataNameToIndex { name } {
    variable collect_raster_data_name_list
    variable ::collectRaster::rastering_data

    if {![info exists rastering_data]} {
        return -code error "string not exists: rastering_data"
    }

    set index [lsearch -exact $collect_raster_data_name_list $name]
    if {$index < 0} {
        puts "DataNameToIndex failed name=$name list=$collect_raster_data_name_list"
        return -code error "data bad name: $name"
    }

    if {[llength $rastering_data] <= $index} {
        return -code error "bad contents of string rastering_data"
    }
    return $index
}
proc collectRaster_saveSnapshotsForUser { user SID directory } {
    foreach {snap0 snap1} [gRaster4Run getSnapshots] break

    set f0 [file tail $snap0]
    set f1 [file tail $snap1]

    set p0 [file join $directory $f0]
    set p1 [file join $directory $f1]

    impCopyFile $user $SID $snap0 $p0
    impCopyFile $user $SID $snap1 $p1
}
proc collectRaster_saveRasterForUser { } {
    variable collectRaster_sessionID

    set user    [get_collect_raster_data user]
    set logPath [get_collect_raster_data log_file_name]

    set dir [file dirname $logPath]

    set path [file join $dir raster.txt]
    ### you can also get it by the raster_runXX
    set src [gRaster4Run getPath]
    if {[catch {
        impCopyFile $user $collectRaster_sessionID $src $path
    } errMsg]} {
        log_warning failed to save raster: $errMsg
        user_log_warning failed to save raster: $errMsg
    } else {
        log_note raster saved to $path
    }
}
##### this will  check range, and set mode and file extension
proc collectRaster_setExposureTime { time } {
    set max_time [get_collect_raster_constant timeMax]
    set min_time [get_collect_raster_constant timeMin]

    if {$max_time < $min_time} {
        ###swap them
        set temp $max_time
        set max_time $min_time
        set min_time $temp
    }

    if {$time < $min_time} {
        set time $min_time
        puts "collectRaster: exposure time to $time (min)"
    }
    if {$time > $max_time} {
        set time $max_time
        puts "collectRaster: exposure time to $time (max)"
    }
    set modeIndex [collectRaster_getDetectorMode $time]
    set new_ext [getDetectorFileExt $modeIndex]

    save_collect_raster_data exposure_time $time
    save_collect_raster_data det_mode $modeIndex
    save_collect_raster_data image_ext $new_ext

    return $time
}
proc get_collect_raster_constant { name } {
    set use_collimator [get_collect_raster_data use_collimator]

    if {$use_collimator} {
        return [get_collect_raster_micro_constant $name]
    } else {
        return [get_collect_raster_normal_constant $name]
    }
}
proc get_collect_raster_normal_constant { name } {
    variable rastering_normal_constant

    set index [collectRaster_normalConstantNameToIndex $name]
    return [lindex $rastering_normal_constant $index]
}
proc get_collect_raster_micro_constant { name } {
    variable rastering_micro_constant

    set index [collectRaster_microConstantNameToIndex $name]
    return [lindex $rastering_micro_constant $index]
}
proc collectRaster_normalConstantNameToIndex { name } {
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
proc collectRaster_microConstantNameToIndex { name } {
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
proc get_collect_raster_user_setup { name } {
    return [gRaster4Run getUserSetupField $name]
}
proc set_collect_raster_user_setup { name value } {
    variable ::collectRaster::user_setup_name_list

    set index [lsearch -exact $user_setup_name_list $name]
    if {$index < 0} {
        log_error "bad name $name for raster user setup"
        return -code error BAD_NAME
    }

    set curSetup [gRaster4Run getUserSetup]

    switch -exact -- $name {
        time {
            set max_time [get_collect_raster_constant timeMax]
            set min_time [get_collect_raster_constant timeMin]

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

    set newSetup [setStringFieldWithPadding $curSetup $index $value]
    if {$name == "time"} {
        collectRaster_checkUserSetupDefault newSetup
    }

    gRaster4Run setUserSetup $newSetup
}
proc collectRaster_checkUserSetupDefault { uSetupREF } {
    variable ::collectRaster::time_index
    variable ::collectRaster::isDefault_index

    upvar $uSetupREF userSetup

    set time    [lindex $userSetup $time_index]
    set timeDef [get_collect_raster_constant timeDef]

    if {abs($time - $timeDef) < 0.001} {
        set isDefault 1
    } else {
        set isDefault 0
    }
    set userSetup /
    [lreplace $userSetup $isDefault_index $isDefault_index $isDefault]
}

### following 2 are called by rasterRunsConfig
proc default_raster_user_setup { normalREF microREF } {
    variable ::collectRaster::isDefault_index

    upvar $normalREF usetup_normal
    upvar $microREF  usetup_micro

    set dist    [get_collect_raster_micro_constant distV]
    set stop    [get_collect_raster_micro_constant stopV]
    set delta   [get_collect_raster_micro_constant delta]
    set time    [get_collect_raster_micro_constant timeDef]
    
    set usetup_micro [lreplace $usetup_micro 0 3 $dist $stop $delta $time]
    set usetup_micro \
    [lreplace $usetup_micro $isDefault_index $isDefault_index 1]

    set dist    [get_collect_raster_normal_constant distV]
    set stop    [get_collect_raster_normal_constant stopV]
    set delta   [get_collect_raster_normal_constant delta]
    set time    [get_collect_raster_normal_constant timeDef]
    
    set usetup_normal [lreplace $usetup_normal 0 3 $dist $stop $delta $time]
    set usetup_normal \
    [lreplace $usetup_normal $isDefault_index $isDefault_index 1]
}
proc update_raster_user_setup { normalREF microREF } {
    upvar $normalREF usetup_normal
    upvar $microREF  usetup_micro

    global gMotorDistance
    global gMotorBeamStop

    variable $gMotorDistance
    variable $gMotorBeamStop

    set dist [set $gMotorDistance]
    set stop [set $gMotorBeamStop]

    set usetup_normal [lreplace $usetup_normal 0 1 $dist $stop]
    set usetup_micro  [lreplace $usetup_micro  0 1 $dist $stop]
}
proc get_default_raster_user_setup { } {
    variable latest_raster_user_setup_normal
    variable latest_raster_user_setup_micro

    set defaultNormal [lreplace $latest_raster_user_setup_normal \
    4 9 {} {} 1 0 0 {}]
    set defaultMicro  [lreplace $latest_raster_user_setup_micro \
    4 9 {} {} 1 0 0 {}]

    return [list $defaultNormal $defaultMicro]
}
proc set_raster_user_setup_to_system_setup { } {
    variable latest_raster_user_setup_normal
    variable latest_raster_user_setup_micro

    foreach {defNormal defMicro} [get_default_raster_system_setup] break

    set latest_raster_user_setup_normal $defNormal
    set latest_raster_user_setup_micro  $defMicro
}
proc get_default_raster_system_setup { } {
    set defaultMicro ""
    set defaultNormal ""
    if {[isString rastering_micro_constant]} {
        set dist    [get_collect_raster_micro_constant distV]
        set stop    [get_collect_raster_micro_constant stopV]
        set delta   [get_collect_raster_micro_constant delta]
        set time    [get_collect_raster_micro_constant timeDef]
    
        set defaultMicro [list $dist $stop $delta $time {} {} 1 0 0 {} 0]
    }

    set dist    [get_collect_raster_normal_constant distV]
    set stop    [get_collect_raster_normal_constant stopV]
    set delta   [get_collect_raster_normal_constant delta]
    set time    [get_collect_raster_normal_constant timeDef]
    
    set defaultNormal [list $dist $stop $delta $time {} {} 1 0 0 {} 0]

    return [list $defaultNormal $defaultMicro]
}
proc colletRaster_restoreSelection { view } {
    gRaster4Run restoreSelection $view
}
proc collectRaster_increaseExposeTime { } {
    ## no adjustment if user specify time
    set timeUser [get_collect_raster_user_setup time]
    set timeDef  [get_collect_raster_constant timeDef]
    if {abs($timeUser - $timeDef) > 0.001} {
        user_log_warning raster "user has specified exposure time, no scaling"
        collectRaster_log "user has specified exposure time"
        return 0
    }

    set current_time [get_collect_raster_data exposure_time]
    set max_time [get_collect_raster_constant timeMax]
    if {$current_time >= $max_time} {
        collectRaster_log "reached max exposure time, quit"
        return 0
    }

    set new_time [collectRaster_adjustExposureTimeByNumSpot $current_time]
    #flag to skip ion chamber scaling
    save_collect_raster_data old_i2 0

    collectRaster_log "exposure time increased to $new_time"
    return 1
}
proc collectRaster_adjustExposureTimeByNumSpot { old_time } {
    set current_max_num_spot [get_collect_raster_data max_weight]
    set target_num_spot      [get_collect_raster_constant spotTgt]

    collectRaster_log "adjusting time by numspots: curren: $current_max_num_spot"
    collectRaster_log "adjusting time by numspots: target: $target_num_spot"
    collectRaster_log "adjusting time by numspots: old time: $old_time"
    
    if {$current_max_num_spot > 0} {
        set maxFactor [get_collect_raster_constant timeIncr]
        set factor [expr double($target_num_spot) / double($current_max_num_spot)]

        if {$factor > $maxFactor} {
            set factor $maxFactor
        }
    } else {
        set factor [get_collect_raster_constant timeIncr]
    }
    save_collect_raster_data scaling_scale $factor
    set exposure_time [expr $old_time * $factor]
    set new_time [collectRaster_setExposureTime $exposure_time]
    return $new_time
}

proc collectRaster_checkWeights { } {
    set raw_weight_list [get_collect_raster_data raw_weight_list]


    set max_weight [collectRaster_getMaxWeight $raw_weight_list]
    puts "max_weight=$max_weight from list: $raw_weight_list"

    ##################check to see if max weight is still too small#####
    set min_weight_to_proceed [get_collect_raster_constant spotMin]
    puts "min required: $min_weight_to_proceed"
    if {$max_weight < $min_weight_to_proceed} {
        collectRaster_log "rastering failed: num of spot too small"
        return 0
    }
    return 1
}
proc collectRaster_getMaxWeight {raw_weight_list} {
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
    save_collect_raster_data max_index $maxIndex
    save_collect_raster_data max_weight $max_weight
    return $max_weight
}
proc collectRaster_checkScaling { } {
    set previous_max [get_collect_raster_data scaling_max]

    if {$previous_max == "" || $previous_max < 0} {
        
        ### first time increase, let go
        set max_weight [get_collect_raster_data max_weight]
        set max_index  [get_collect_raster_data max_index]
        save_collect_raster_data scaling_max   $max_weight
        save_collect_raster_data scaling_index $max_index
        collectRaster_log "first checkScaling, saved $max_weight $max_index"
        return 1
    }

    ## now check
    ## get the weight at the same spot.
    set wList [get_collect_raster_data raw_weight_list]
    set index [get_collect_raster_data scaling_index]

    set current_weight [lindex [lindex $wList $index] 0]
    collectRaster_log "new weight $current_weight"

    if {$previous_max == 0} {
        if {$current_weight > 0} {
            save_collect_raster_data scaling_max $current_weight 
            collectRaster_log "checkScaling,let go, previous=0"
            return 1
        }
        collectRaster_log "checkScaling failed both 0"
        return 0
    }

    set factor [expr $current_weight / double($previous_max)]
    set scale  [get_collect_raster_data scaling_scale]
    collectRaster_log "checkScaling : factor=$factor scale=$scale"
    if {abs($factor) >= 0.75 * abs($scale)} {

        save_collect_raster_data scaling_max $current_weight 

        collectRaster_log "checkScaling pass >= 0.75"
        return 1
    }
    collectRaster_log "checkScaling failed < 0.75"
    return 0
}
proc collectRaster_updateSetup { view_index pattern ext threshold } {
    gRaster4Run updatePattern $view_index $pattern $ext $threshold
}
proc collectRaster_getNextNode { view_index current } {
    return [gRaster4Run getNextNode $view_index $current]
}
proc collectRaster_addAndAnalyzeImage { user sessionID row directory fileroot } {
    variable beamlineID
    variable collectRaster_uniqueIDList

    set fullPath [file join $directory \
    ${fileroot}.[get_collect_raster_data image_ext]]

    set silid [get_collect_raster_data sil_id]

    set uniqueID [lindex $collectRaster_uniqueIDList $row]

    addCrystalImage $user $sessionID $silid $row 1 $fullPath NULL $uniqueID

    analyzeCenterImage \
    $user $sessionID $silid $row $uniqueID 1 $fullPath ${beamlineID} $directory
}
proc collectRaster_getDetectorMode { exposureTime } {
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
proc collectRaster_log { contents {update_operation 1} {force_file 0} } {
    variable ::collectRaster::pendingLogContents

    variable collectRaster_sessionID

    set user      [get_collect_raster_data user]
    set sessionID $collectRaster_sessionID
    set logPath [get_collect_raster_data log_file_name]

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
proc collectRaster_logConstant { } {
    set use_collimator [get_collect_raster_data use_collimator]

    if {$use_collimator} {
        collectRaster_logMicroConstant
    } else {
        collectRaster_logNormalConstant
    }
}
proc collectRaster_logNormalConstant { } {
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
    collectRaster_log $log_contents 0
}
proc collectRaster_logMicroConstant { } {
    variable rastering_micro_constant
    variable rastering_micro_name_list

    set ll [llength $rastering_micro_name_list]

    set log_contents "MANUAL RASTERING PARAMETERS\n"
    foreach name $rastering_micro_name_list value $rastering_micro_name_list {
        append log_contents "$name=$value\n"
    }
    ##### only write to log file, not send operation update
    collectRaster_log $log_contents 0
}
proc collectRaster_logData { } {
    variable collect_raster_data_name_list
    #variable rastering_data
    variable ::collectRaster::rastering_data
    variable collectRaster_sessionID

    set user      [get_collect_raster_data user]
    set sessionID $collectRaster_sessionID

    set ll [llength $collect_raster_data_name_list]
    set log_contents "COLLECT RASTER DATA\n"
    for {set i 0} {$i < $ll} {incr i} {
        append log_contents [lindex $collect_raster_data_name_list $i]
        append log_contents =
        append log_contents [lindex $rastering_data $i]
        append log_contents "\n"
    }
    ##### only write to log file, not send operation update
    collectRaster_log $log_contents 0
}
proc collectRaster_logWeight { view_index numFmt txtFmt } {
    foreach line [gRaster4Run getMatrixLog $view_index $numFmt $txtFmt] {
        collectRaster_log $line
        user_log_note raster $line
    }
}

proc collectRaster_updateRun { rasterNum status } {
    variable raster_run$rasterNum

    set contents [set raster_run$rasterNum]
    set contents [lreplace $contents 0 0 $status]

    set raster_run$rasterNum $contents
}
proc collectRaster_save4Restore { } {
    variable ::collectRaster::restore_cmd

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
        collectRaster_log "save $motor position $pos"
    }
}
proc collectRaster_restore { } {
    variable ::collectRaster::restore_cmd

    collectRaster_setStatus "restoring motor positions" 3

    set movingList ""
    foreach cmd $restore_cmd {
        foreach {motor pos} $cmd break

        move $motor to $pos
        lappend movingList $motor
        collectRaster_log "restore $motor position to $pos"
    }
    if {$movingList != ""} {
        eval wait_for_devices $movingList
    }
    wait_for_time 0

    set restore_cmd ""
}
proc collectRaster_setStatus { txt_status {sub_state -1} } {
    variable raster_msg

    set contents [lreplace $raster_msg 1 1 $txt_status]
    if {$sub_state >= 0} {
        set contents [lreplace $contents 2 2 $sub_state]
    }
    set raster_msg $contents
}
proc collectRaster_copyUserSetupDistanceAndBeamstop { dest source } {
    variable ::collectRaster::distance_index
    variable ::collectRaster::beamstop_index

    set result $dest

    set sDistance [lindex $source $distance_index]
    set sBeamstop [lindex $source $beamstop_index]

    set result \
    [lreplace $result $distance_index $distance_index $sDistance]

    set result \
    [lreplace $result $beamstop_index $beamstop_index $sBeamstop]

    return $result
}
