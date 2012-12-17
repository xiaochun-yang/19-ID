#package require Itcl
#namespace import itcl::*
#source util.tcl


proc update_run { runNumber nextFrame runStatus {incrementStartFrame 0} } {
    variable run$runNumber

    set contents [set run$runNumber]

    if {$runNumber == 0 && $runStatus != "collecting"} {
        ##alwasys set to inactive
	    ::DCS::RunField::setField contents status inactive
	    ::DCS::RunField::setField contents next_frame 0
        #increase count
		set startFrameLabel [::DCS::RunField::getField contents start_frame]
		incr startFrameLabel
	    ::DCS::RunField::setField contents start_frame $startFrameLabel

        ### set
        set run$runNumber $contents
        return
    }

    if {$runStatus != ""} {
	    ::DCS::RunField::setField contents status $runStatus
    }

    if {$nextFrame != ""} {
	    ::DCS::RunField::setField contents next_frame $nextFrame
    }
	
	#if told to do so automatically increase frame start point (for snapshots)
	if { $incrementStartFrame } {
		set startFrameLabel [::DCS::RunField::getField contents start_frame]
		incr startFrameLabel
	    ::DCS::RunField::setField contents start_frame $startFrameLabel
	}

    ### update the string
    set run$runNumber $contents
}

proc fix_run_directory { runNumber username } {
    variable run$runNumber

    set contents [set run$runNumber]
    set dir [::DCS::RunField::getField contents directory]
    if {[checkUsernameInDirectory dir $username]} {
	    ::DCS::RunField::setField contents directory $dir
        set run$runNumber $contents
    }
}

proc getDetectorDistanceMotorName { } {
   if [isMotor detector_z_corr] {
      return detector_z_corr
   } else {
      return detector_z 
   }
}

#### return 1 if OK to run
#### return 0 if no need to run
#### throw error on error
#### preCheck is called by collectRuns to make sure all runs are OK
proc checkForRun { runNumber userName sessionID need_user_logREF {preCheck 0}} {
    global gSingleRunCalculator
	global gClient
	global gPauseDataCollection
    variable collect_msg

    upvar $need_user_logREF needUserLog

	#find out the operation handle
	set op_info [get_operation_info]
    set op_name [lindex $op_info 0]
	set operationHandle [lindex $op_info 1]

	#find out the client id that started this operation
	set clientId [expr int($operationHandle)]
	#get the name of the user that started this operation
	set clientUserName $gClient($clientId)

	if { $clientUserName == $userName } {
		#the user started this operation. Reset the pause flag
		set gPauseDataCollection 0
	} else {
		#the user didn't start this operation. 
        #Probably started by collectRuns operation
		#the pause flag has already been set.
		if {  $clientUserName != "self" } {
			#it wasn't the user or the self client.
            set collect_msg [lreplace $collect_msg 0 1 0 \
            "Invalid to start data collection for $clientUserName"]
			return -code error hacker
		}
	}
    if {$clientUserName != "self"} {
        set needUserLog 1
    }

    puts "checkForRun:: get runstatus"
	set runStatus [gSingleRunCalculator getField status]
	if { $runStatus == "disabled"  } {
        set collect_msg [lreplace $collect_msg 0 1 0 \
        "run $runNumber is disabled"]
        if {$preCheck} {
            ### the run Definition is OK.
            ### just will be skipped in the real run
            return 1
        }
		return 0
	}

	#Stop data collection now if we have already been paused.
	if {$gPauseDataCollection } {
		error paused
    }

	if {$runNumber != 0} {
	    set nextFrame [gSingleRunCalculator getField next_frame]
	    set totalFrames [gSingleRunCalculator getTotalFrames]
	    #Check to see if this run is complete
	    if { $nextFrame >= $totalFrames } {
		    update_run $runNumber $nextFrame "complete"
            set collect_msg [lreplace $collect_msg 0 1 0 \
            "run $runNumber is completed"]
            if {$preCheck} {
                ### the run Definition is OK.
                ### just will be skipped in the real run
                return 1
            }
		    return 0
        }
    }

    ### now real check
    set allOK [runDefinitionCheckEnergyAndDistance run$runNumber NULL 0]

    #####check directory permission
	set directory [gSingleRunCalculator getField directory]

    if {[catch {
        checkCollectDirectoryAllowed $directory
        impDirectoryWritable $userName $sessionID $directory
    } errMsg]} {
        log_error run $runNumber check directory $directory failed: $errMsg
        if {!$preCheck} {
            user_log_error collecting \
            "directory check $directory failed: $errMsg"
        }
        set allOK 0
    }

    return $allOK
}
proc moveMotorsForRun { runNumber {wait_done 0} } {
    puts "moveMotorsForRun $runNumber $wait_done"
    variable collect_msg
    variable runs
    variable attenuation
    global gSingleRunCalculator

    global gMotorEnergy
    global gMotorDistance
    global gMotorBeamStop

    foreach {nextFrame distance beamStop attenuationSetting firstEnergy} \
    [gSingleRunCalculator getList \
    next_frame distance beam_stop attenuation energy1] break

	#close the shutter, in case it is open and we need to collect dark images.
	close_shutter shutter

	# move the detector to the correct distance
	if { [catch {
        move $gMotorDistance to $distance
        ### BL12-2 energy will move distance
        wait_for_devices $gMotorDistance
    } errorResult] } {
		log_error "Error moving $gMotorDistance to position: $errorResult"
		update_run $runNumber $nextFrame "paused"
        set collect_msg [lreplace $collect_msg 0 1 0 \
        "Unable to move $gMotorDistance"]
		return -code error $errorResult
	}
    puts "moveMotorsForRun beamstop"
	if { [catch {move $gMotorBeamStop to $beamStop} errorResult] } {
		log_error "Error moving $gMotorBeamStop to position: $errorResult"
		update_run $runNumber $nextFrame "paused"
        set collect_msg [lreplace $collect_msg 0 1 0 \
        {Unable to move $gMotorBeamStop}] 
		return -code error $errorResult
	}

    move attenuation to 0
    wait_for_devices attenuation

    if {$wait_done} {
        puts "moveMotorsForRun energy"
        if {[catch {move $gMotorEnergy to $firstEnergy} errorResult]} {
            log_error Error moving energy to position: $errorResult
		    update_run $runNumber $nextFrame "paused"
            set collect_msg [lreplace $collect_msg 0 1 0 \
            {Unable to move $gMotorEnergy}] 
		    return -code error $errorResult
        }
        puts "moveMotorsForRun wait"
        wait_for_devices $gMotorDistance $gMotorBeamStop $gMotorEnergy
        ###must wait energy finish then move attenuation
        puts "moveMotorsForRun attenuation"
	    if { [catch {
            move attenuation to $attenuationSetting
            wait_for_devices attenuation
        } errorResult] } {
	        log_error "Error moving attenuation to position: $errorResult"
	        update_run $runNumber $nextFrame "paused"
            set collect_msg [lreplace $collect_msg 0 1 0 \
            {Unable to move attenuation}] 
		    return -code error $errorResult
	    }
    }
    puts "moveMotorsForRun done"
}

###return 0 means skip this sample
proc mountSampleForRun { runNumber sessionID } {
    variable collect_msg

    ### get the port to mount
    variable runExtra$runNumber
    set strRunExtra [set runExtra$runNumber]
    set port [lindex $strRunExtra 3]
    if {$port == ""} {
        return 1
    }

    set mCas [string index $port 0]
    set mCol [string index $port 1]
    set mRow [string range $port 2 end]

    ### get current sample on goniometer
    variable robot_status
    set portMnted [lindex $robot_status 15]
    if {[llength $portMnted] == 3} {
        foreach {cas row col} $portMnted break
        if {$mCas == $cas && $mCol == $col && $mRow == $row} {
            log_note skip mounting $port already on goniometer
            return 1
        }
    }

    ##### mount it
    set collect_msg [lreplace $collect_msg 0 2 1 \
    "mounting $port for run$runNumber" 1]
    log_note mounting $port for run$runNumber
    ###if this failed, quit the whole operation
    eval sequenceManual_start mount $port $sessionID

    ################ check mount results ###########
    set portMnted [lindex $robot_status 15]
    if {[llength $portMnted] != 3} {
        log_error mount $port failed
        set collect_msg [lreplace $collect_msg 0 1 0 \
        {Error: mount $port failed}]
        return 0
    }
    foreach {cas row col} $portMnted break
    if {$mCas != $cas || $mCol != $col || $mRow != $row} {
        log_error mount $port failed
        set collect_msg [lreplace $collect_msg 0 1 0 \
        {Error: mount $port failed}]
        return 0
    }
    set collect_msg [lreplace $collect_msg 0 2 1 \
    {loopCentering} 2]
    ###if this failed, skip this sample
    if {[catch centerLoop_start errorMsg]} {
        log_error loopCenter failed: $errorMsg
        set collect_msg [lreplace $collect_msg 0 1 0 \
        {Error: loopCenter Faile: $errorMsg}]
        return 0
    }
    return 1
}

proc CenterCrystalForRun { runNumber userName sessionID } {
    global gSingleRunCalculator

	set fileroot [gSingleRunCalculator getField file_root]

    variable collect_msg
    variable sample_x
    variable sample_y
    variable sample_z

    ##### save original position
    set orig_sample_x $sample_x
    set orig_sample_y $sample_y
    set orig_sample_z $sample_z

    set collect_msg [lreplace $collect_msg 0 2 1 \
    {center Crystal for run$runNumber} 3]
    if {[catch {
        set handle [start_waitable_operation centerCrystal \
        $userName \
        $sessionID \
        /data/$userName/centerCrystal \
        $fileroot]
        wait_for_operation_to_finish $handle
    } errMsg2]} {
        if {[string first aborted $errMsg2] >= 0} {
            set collect_msg [lreplace $collect_msg 0 1 0 Aborted]
            return -code error $errMsg2
        }
        puts "crystal center error2: $errMsg2"
        move sample_x to $orig_sample_x
        move sample_y to $orig_sample_y
        move sample_z to $orig_sample_z
        wait_for_devices sample_x sample_y sample_z
        log_warning "restored sample position"
        user_log_warning "collectin center crystal failed"
    }
}

#return 0 means skip this crystal
proc prepareForRun { runNumber userName sessionID runName selectedNotFill \
selectedMadScan } {
    puts "prepareForRun"
    variable collect_config


    set anyEnabled [lindex $collect_config 0]
    if {!$anyEnabled} {
        return 1
    }

    set mountShown    [lindex $collect_config 1]
    set mountSelected [lindex $collect_config 4]
    set centerShown    [lindex $collect_config 2]
    set centerSelected [lindex $collect_config 5]
    set autoindexShown    [lindex $collect_config 3]
    set autoindexSelected [lindex $collect_config 6]

    if {($centerShown && $centerSelected) ||
    ($autoindexShown && $autoindexSelected)} {
        puts "move motors for prepareRun"
        moveMotorsForRun $runNumber 1
    }

    if {$mountShown && $mountSelected} {
        puts "prepareForRun mount"
        if {![mountSampleForRun $runNumber $sessionID]} {
            return 0
        }
    }

    if {$centerShown && $centerSelected} {
        puts "prepareForRun center"
        CenterCrystalForRun $runNumber $userName $sessionID
    }

    if {$autoindexShown && $autoindexSelected} {
        puts "prepareForRun autoindex"
        if {[catch {
            eval fillRun_start $runNumber $userName $sessionID $runName \
            $selectedNotFill $selectedMadScan
        } errM]} {
            if {[string first aborted $errM] >= 0} {
                return -code error $errM
            }
            log_error $errM
            return 0
        }
    }
    return 1
}

####all these message will be displayed if not empty
proc clearMessageForRun { } {
    variable auto_sample_msg
    variable center_crystal_msg
    variable fill_run_msg
    variable robot_sample

    set auto_sample_msg     ""
    set center_crystal_msg  ""
    set fill_run_msg        ""
    set robot_sample        ""
}


proc collectRunWithShutter { runNumber userName reuseDark sessionID args } {
	# global variables 
	global gPauseDataCollection
    global gWaitForGoodBeamMsg
    global gSingleRunCalculator
    global gCurrentRunNumber
    global gMotorBeamWidth
    global gMotorBeamHeight
    global gMotorEnergy
    global gMotorPhi
    global gMotorOmega
    global gMotorDistance
    global gMotorBeamStop

    variable runs
    variable collect_msg
    variable beamlineID
    variable attenuation

    set flagSaveSystemSnapshotForEachRun 1
    set flagSaveSystemSnapshotForEachFrame 0

    if [catch {block_all_motors;unblock_all_motors} errMsg] {
        log_error $errMsg
        puts "MUST wait all motors stop moving to start collecting"
        log_error "MUST wait all motors stop moving to start collecting"
        return -code error "MUST wait all motors stop moving to start"
    }

    if {$sessionID == "SID"} {
        set sessionID PRIVATE[get_operation_SID]
        puts "use operation SID: [SIDFilter $sessionID]"
    }

    set gCurrentRunNumber $runNumber

    ####check and clear all run status
    #checkRunStatus -1
    ####check and clear all run status skip this runNumber
    checkRunStatus $runNumber

    set runName [lindex $args 0]
    set selectedStop [lindex $args 1]
    set selectedMadScan [lindex $args 2]

    puts "populate the calculator"
    variable run$runNumber
    puts "rundef: [set run$runNumber]"
    gSingleRunCalculator updateRunDefinition [set run$runNumber]
    puts "after populate"

    set needUserLog 0
    if {![checkForRun $runNumber $userName $sessionID needUserLog]} {
        ### just to make sure
        set collect_msg [lreplace $collect_msg 0 0 0]
        return $runNumber
    }
    puts "after checkForRun"

    if {$needUserLog} {
        ### not called by collectRuns, but directy by BluIce
        correctPreCheckMotors
    }

    clearMessageForRun
    set collect_msg [lreplace $collect_msg 0 6 \
    1 Starting 0 $beamlineID $userName $runName $runNumber]

   
    if { $runNumber != 0 } {
        puts "prepareForRun"
        if {![prepareForRun $runNumber $userName $sessionID $runName \
        $selectedStop $selectedMadScan]} {
		    update_run $runNumber "" "inactive"
            if {$needUserLog} {
                user_log_error collecting [lindex $collect_msg 1]
                user_log_note collecting "=======end collectRun $runNumber====="
            } else {
                log_warning skip run$runNumber
            }
	        return $runNumber
        }
        if {$selectedStop == "1"} {
            log_warning prepareForRun fill only, no real collection
		    update_run $runNumber "" "inactive"
            set collect_msg [lreplace $collect_msg 0 1 0 completed]
            if {$needUserLog} {
                user_log_note collecting "=======end collectRun $runNumber========"
            }
	        return $runNumber
        }
    }

    moveMotorsForRun $runNumber

	#get all the data that is stored in this class, so
    #we can update the run later when the frame changes.
    foreach { \
	directory       \
	exposureTime    \
	axisMotorName   \
    attenuationSetting \
	modeIndex       \
	nextFrame       \
	runLabel        \
	delta           \
	startAngle      \
	endAngle        \
	startFrameLabel \
	fileroot        \
	wedgeSize       \
	inverseOn       \
    } [gSingleRunCalculator getList \
	directory       \
	exposure_time   \
	axis_motor      \
    attenuation     \
	detector_mode   \
	next_frame      \
	run_label        \
	delta           \
	start_angle      \
	end_angle        \
	start_frame \
	file_root        \
	wedge_size       \
	inverse_on       \
    ] break

    ##### decode the axis motor names here
    switch -exact -- $axisMotorName {
        Omega {
            set axisMotor $gMotorOmega
        }
        default {
            set axisMotor $gMotorPhi
        }
    }
    puts "axisMotor: $axisMotor"

	set useDose [lindex $runs 2]

	set energyList [gSingleRunCalculator getEnergies]
    puts "e list; $energyList"
	#find out how many frames are in this run
	set totalFrames [gSingleRunCalculator getTotalFrames]

    if {$runNumber == 0} {
		set nextFrame 0
		set totalFrames 1
    }

    puts "total frames: $totalFrames"
		
	#inform the guis that we are collecting
	update_run $runNumber $nextFrame "collecting"

    ########################### user log ##################
    if {$needUserLog} {
        user_log_note collecting "======$userName start collectRun $runNumber======"
    } else {
        user_log_note collecting "=========run $runNumber========"
    }

    set fileExt [getDetectorFileExt $modeIndex]

    ### this way, collect_msg will be set by wait_for_good_beam and
    ### requestExposureTime which also call wait_for_good_beam inside
    set gWaitForGoodBeamMsg [list collect_msg 1]

    set collect_msg [lreplace $collect_msg 0 2 \
    1 {collecting} 6]

	#loop over all remaining frames until this run is complete
	if { [catch {
		while { $nextFrame < $totalFrames } {

			#Stop data collection now if we have been paused.
			if { !$gPauseDataCollection } {
				update_run $runNumber $nextFrame "collecting"
                if { $runNumber == 0 } {
                    set collect_msg [lreplace $collect_msg 0 1 \
                    1 "collecting snapshot"]
                } else {
                    set collect_msg [lreplace $collect_msg 0 1 1 \
                    "collecting run $runNumber frame $nextFrame of $totalFrames"]
                }
			} else {
				error paused
			}
			
			#get the motor positions for this frame
			set thisFrame \
            [gSingleRunCalculator getMotorPositionsAtIndex $nextFrame]
			#extract the motor positions from the result
			set filename [lindex $thisFrame 0]
			set phiPosition [lindex $thisFrame 1]
			set energyPosition [lindex $thisFrame 2]
            set sub_dir [lindex $thisFrame 6]

            ### disable feature for now until more feedback
            #set directoryNew [file join $directory $sub_dir]
            set directoryNew $directory

			move $axisMotor to $phiPosition
			move $gMotorEnergy to $energyPosition
			
			wait_for_devices \
            $axisMotor \
            $gMotorEnergy \
			$gMotorDistance \
			$gMotorBeamStop
            move attenuation to $attenuationSetting
            wait_for_devices attenuation
            set needSaveSystemSnapshot 0

            ### this will also write out user_log, so do not merge with other
            ### conditions.
            if {[user_log_system_status collecting]} {
                set needSaveSystemSnapshot 1
            }
            if {$flagSaveSystemSnapshotForEachFrame} {
                set needSaveSystemSnapshot 1
            }
            if {$flagSaveSystemSnapshotForEachRun} {
                set flagSaveSystemSnapshotForEachRun 0
                set needSaveSystemSnapshot 1
            }
puts "yangx-b"
          #  if {$needSaveSystemSnapshot} {
          #      set snapshotPath [file join $directoryNew $filename.txt]
          #      saveSystemSnapshot $userName $sessionID $snapshotPath
          #  }
puts "yangx-e"
            ### beamGood check is in the requestExposureTime
            ### it will be called before start collectFrame
			set operationHandle [eval start_waitable_operation collectFrame \
											 $runNumber \
											 $filename \
											 $directoryNew \
											 $userName \
											 $axisMotor \
											 shutter \
											 $delta \
											 [requestExposureTime_start $exposureTime $useDose] \
											 $modeIndex \
											 0 \
											 $reuseDark \
                                             $sessionID \
                                             $args]
			
			wait_for_operation $operationHandle

            ########################### user log ##################
            set logAngle [format "%.3f" $phiPosition]
            set    log_contents "[user_log_get_current_crystal]"
            append log_contents " collect"
            append log_contents " $directoryNew/$filename.$fileExt"
            append log_contents " $logAngle deg"
            user_log_note collecting $log_contents

			#If we are in dose mode and we lost beam then don't go to the next frame.
			if { ![beamGood] } {
				#The beam went down during the last frame.
				#Don't move to the next frame, but wait for the beam to come back
				wait_for_good_beam
                set collect_msg [lreplace $collect_msg 0 1 1 \
                "collecting re-run $runNumber frame $nextFrame of $totalFrames"]
			} else {
				#move to the next frame
				incr nextFrame
			}
		}
puts "yangx-5"
        set gWaitForGoodBeamMsg ""
		#run is complete, flush the last image out
		start_operation detector_stop
		set runStatus complete
		
		if { $runNumber == 0 } {
			#add one to the start frame index	
			update_run $runNumber $nextFrame "complete" 1
		} else {
			update_run $runNumber $nextFrame "complete"
		}

	} errorResult ] } {
		#handle every error that could be raised during data collection
        set gWaitForGoodBeamMsg ""
		start_recovery_operation detector_stop
		update_run $runNumber $nextFrame "paused"
        set collect_msg [lreplace $collect_msg 0 1 0 $errorResult]

        if {$needUserLog} {
            user_log_error collecting "run$runNumber $errorResult"
            user_log_note collecting "=======end collectRun $runNumber========"
        }
        
        log_error collect failed for run$runNumber $errorResult
		return -code error $errorResult
	}

    ########################### user log ##################
    if {$needUserLog} {
        user_log_note collecting "=======end collectRun $runNumber========"
        cleanupAfterAll
    }
	
    set collect_msg [lreplace $collect_msg 0 1 0 "completed"]
	return $runNumber
}







