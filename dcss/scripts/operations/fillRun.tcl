package require Itcl
package require DCSSpreadsheet

####field of runExtra
#
# 0: space group index used to fill the run
#      {} means not filled yet
#
# 1: autoindex status
#
# 2: run name
#
# 3: port name
#
# 4: laueGroup
#
# 5: unitCell
#
# 6: experiment type

proc fillRun_initialize { } {
}
proc fillRun_start { runNum user SID args } {
    puts "enter fillRun"
    variable fill_run_msg
    variable beamlineID
    variable strategy_file
    variable strategy_status
    variable run$runNum
    variable runExtra$runNum
    variable collect_msg

    if {$SID == "SID"} {
        set SID PRIVATE[get_operation_SID]
        puts "use operation SID: $SID"
    }

    set fill_run_msg ""

    set runName [lindex $args 0]
    set selectedNotFill [lindex $args 1]
    if {$selectedNotFill == ""} {
        set selectedNotFill 0
    }
    set selectedMadScan [lindex $args 2]
    if {$selectedMadScan == ""} {
        set selectedMadScan 0
    }

    set startedByBluIce [client_started_operation fillRun]

    set oldExtra [set runExtra$runNum]
    set runExtra$runNum [lreplace $oldExtra 0 2 {} autoindexing {}]


    set localRun [set run$runNum]
    foreach {runStatus exposure_time delta prefix} \
    [::DCS::RunField::getList localRun \
    status exposure_time delta file_root ] break

    if {$runStatus == "disabled"} {
        set fill_run_msg "error: $runNum is disabled."
        if {!$startedByBluIce} {
            set collect_msg [lreplace $collect_msg 0 6 \
            0 {run$runNum disabled} 0 $beamlineID $user $runName $runNum]
        }
        return -code error "run$runNum disabled"
    }

    if {$startedByBluIce} {
        user_log_note collecting "====$user start autoindex for run$runNum==="
    }

    ##### do this first so that the failure will abort the operation before
    ##### other time-consuming actions.
    puts "create dir"
    set strategyDir [file join [::config getStrategyDir] $beamlineID]
    file mkdir $strategyDir

    #### take 2 diffraction images for autoindex
    log_note autoindex taking 2 images
    set fill_run_msg "taking 2 images"

    set strategy_file [lreplace $strategy_file 0 0 autoindexing]

    if {!$startedByBluIce} {
        set collect_msg [lreplace $collect_msg 0 6 \
        1 {taking 2 images for autoindex} 4 $beamlineID $user $runName $runNum]
    }

    if {[catch {
        foreach {imgFile0 imgFile1} \
        [FRTakeTwoImages $runNum $delta $exposure_time $user $SID] break
    } errorMsg]} {
        set strategy_file \
        [lreplace $strategy_file 0 0 failed]
        log_error $errorMsg
        if {$startedByBluIce} {
            user_log_error collecting "autoindex: $errorMsg"
            user_log_note collecting "==end autoindex for run$runNum=="
        } else {
            set collect_msg \
            [lreplace $collect_msg 1 1 "autoindex Error: $errorMsg"]
        }
        return -code error $errorMsg
    }

    set oldExtra [set runExtra$runNum]
    set laueGroup [lindex $oldExtra 4]
    set unitCell [lindex $oldExtra 5]
    set expType [lindex $oldExtra 6]
    set workDir [lindex $oldExtra 7]
    set madScanArgs [lindex $oldExtra 8]
    set madScanResult [lindex $oldExtra 9]
	 set numHeavyAtoms [lindex $oldExtra 10]
	 set numResidues [lindex $oldExtra 11]
	 set strategyMethod [lindex $oldExtra 12]
	 
    #####start madScan if needed######
    if {$selectedMadScan && \
    $expType != "" && \
    ![string equal -nocase -length 4 $expType "Mono"]} {
        if {[llength $madScanArgs] != 6} {
            log_error bad arguments for madscan: length != 6: $madScanArgs
        } else {
            set handle \
            [eval start_waitable_operation madScan $user $SID $madScanArgs]
    
            log_note waiting for madScan
            set fill_run_msg "started madScan"
            if {!$startedByBluIce} {
                set collect_msg [lreplace $collect_msg 1 1 \
                "madScan"]
            }
            set result [wait_for_operation_to_finish $handle]
            ###restructor madScanResult
            set madScanResult [list \
            [lindex $madScanArgs 2] \
            [lindex $result 1] \
            [lindex $result 4] \
            [lindex $result 7] \
            ]
        }
    }

    ####do strategy
    set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set strategyFile "${prefix}_auto_${timestamp}.tcl"
    set strategyFile [file join $strategyDir $strategyFile]
    ##make sure the file not exists
    file delete -force $strategyFile

    if {$runName == ""} {
        set runStamp [clock format [clock seconds] -format "%H%M%S_%Y%m%d"]
        set runName ${prefix}_${runStamp}_$beamlineID
    }

    set strategy_file \
    [lreplace $strategy_file 0 1 $strategyFile $runName]
    log_note autoindex checking impdhs
    wait_for_string_contents strategy_status $strategyFile 1
    set oldExtra [set runExtra$runNum]
    set runExtra$runNum [lreplace $oldExtra 0 2 {} $strategyFile $runName]

    ####this will put strategy calculation into a background queue.
    ####it is running on another machine in most cases.
    log_note autoindex submit job
    set fill_run_msg "submit autoindex job"

    if {!$startedByBluIce} {
        set collect_msg [lreplace $collect_msg 0 6 \
        1 autoindexing 5 $beamlineID $user $runName $runNum]
    }

    ###extra for autoindex: madScan results
    foreach {edge inflection peak remote} $madScanResult break

    if {[catch {
        autoindexCrystal $user $SID \
        -1 -1 -1 \
        $imgFile0 $imgFile1 $beamlineID $runName 1 $strategyFile \
        $expType $laueGroup $unitCell $workDir \
        $edge $inflection $peak $remote $numHeavyAtoms $numResidues $strategyMethod
    } errorMsg]} {
        set strategy_file \
        [lreplace $strategy_file 0 0 failed]
        log_error $errorMsg
        if {$startedByBluIce} {
            user_log_error collecting "autoindex: $errorMsg"
            user_log_note collecting "==end autoindex for run$runNum=="
        } else {
            set collect_msg \
            [lreplace $collect_msg 1 1 "autoindex Error: $errorMsg"]
        }
        return -code error $errorMsg
    }
	puts "after calling autoindexCrystal"

    #####wait strategyFile
    log_note autoindex waiting for result
    set fill_run_msg "waiting for autoindex results"

    set file_ready 0
    while {!$file_ready} {
        set status [lindex $strategy_status 0]
        switch -exact $status {
            ready { set file_ready 1}
            errorSvr {
                log_error autoindex result not there in time.
                if {$startedByBluIce} {
                    user_log_error collecting "autoindex: status file not there"
                    user_log_note collecting "==end autoindex for run$runNum=="
                } else {
                    set collect_msg [lreplace $collect_msg 1 1 \
                    "autoindex Error: status file not there in time"]
                }
                return -code error "strategy result not available"
            }
            not_ready -
            pending -
            running -
            default {
                wait_for_strings strategy_status
            }
        }
    }

    log_note autoindex parse result 
    set fill_run_msg "parsing results"
    set currentFile [lindex $strategy_status 1]
    if {$currentFile != $strategyFile} {
        log_error autoindex new strategy started:$currentFile
        if {$startedByBluIce} {
            user_log_error collecting "autoindex new strategy started: $currentFile"
            user_log_note collecting "====end autoindex for run$runNum==="
        } else {
            set collect_msg \
            [lreplace $collect_msg 1 1 "autoindex Error: new strategy started"]
        }
        return -code error "new strategy started:$currentFile"
    }

    if {!$selectedNotFill} {
        ##### parse the file and get the first space group
        ##### populate the run definition ####
        FRParseStrategyFile $strategyFile $runNum $startedByBluIce
    } else {
        log_note notFill selected
    }
    set fill_run_msg ""
    if {$startedByBluIce} {
        user_log_note collecting "====end autoindex for run$runNum==="
    }
}
proc FRTakeTwoImages { runNum delta exposure_time user SID } {
    global gWaitForGoodBeamMsg
    global gMotorPhi
    global gMotorOmega
    variable runs
    variable run$runNum

    set localRun [set run$runNum]
    foreach {directory prefix modeIndex axisMotorName} \
    [::DCS::RunField::getList localRun \
    directory file_root detector_mode axis_motor] break

    switch -exact -- $axisMotorName {
        Omega {
            set axisMotor $gMotorOmega
        }
        default {
            set axisMotor $gMotorPhi
        }
    }

    variable $axisMotor
    set orig_axisMotor [set $axisMotor]

    set useDose [lindex $runs 2]

    set fileExt [getDetectorFileExt $modeIndex]

    if {[catch correctPreCheckMotors errMsg]} {
        log_error failed to correct motors $errMsg
        return -code error $errMsg
    }

    set gWaitForGoodBeamMsg fill_run_msg
    if {![beamGood]} {
        wait_for_good_beam
    }

    set fileroot "autoindex_${prefix}"
    if {[catch {
        impGetNextFileIndex $user $SID $directory $fileroot $fileExt} \
    counter]} {
        set counter 1
    }

    for {set imgNum 0} {$imgNum < 2} {incr imgNum} {
        set filename "${fileroot}_[format "%03d" $counter]"
        incr counter

        #set expTime $exposure_time
        set expTime [requestExposureTime_start $exposure_time $useDose]

        switch -exact $imgNum {
            0 {
                set flush 0
                set imgFile0 [file join $directory ${filename}.${fileExt}]
            }
            1 {
                move $axisMotor by 90
                wait_for_devices $axisMotor
                set flush 1
                set imgFile1 [file join $directory ${filename}.${fileExt}]
            }
        }
        set phiPosition [set $axisMotor]
        set handle [eval start_waitable_operation collectFrame \
        $runNum \
        $filename \
        $directory \
        $user \
        $axisMotor \
        shutter \
        $delta \
        $expTime \
        $modeIndex \
        $flush \
        0 \
        $SID]
        if {[catch {
            wait_for_operation_to_finish $handle
            set logAngle [format "%.3f" $phiPosition]
            set    log_contents "[user_log_get_current_crystal]"
            append log_contents " autoindex image"
            append log_contents " $directory/$filename.$fileExt"
            append log_contents " $logAngle deg"
            user_log_note collecting $log_contents
        } errMsg]} {
            set fill_run_msg "error: $errMsg"
            log_error autoindex $errMsg
            return -code error $errMsg
        }
    }
    set gWaitForGoodBeamMsg ""

    move $axisMotor to $orig_axisMotor
    wait_for_devices $axisMotor

    return [list $imgFile0 $imgFile1]
}
proc FRParseStrategyFile { full_path runNum startedByBluIce } {
    variable beamlineID
    variable run$runNum
    variable runExtra$runNum
    variable collect_msg

    puts "parse strategyfile $full_path"
    set url [::config getStrategyStatusUrl]
    append url "?beamline=$beamlineID"
    append url "&file=$full_path"
    puts "strategyStatus: $url"

    if {[catch {
        set token [http::geturl $url -timeout 8000]
        checkHttpStatus $token
        set result [http::data $token]
        http::cleanup $token
    } errMsg]} {
        if {!$startedByBluIce} {
            set collect_msg [lreplace $collect_msg 0 1 \
            0 {Autoindex Error: $errMsg}]
        }
        log_error "failed to get strategy results: $errMsg"
        return -code error $errMsg
    }
    set status [lindex $result 0]
    set contents [lindex $result 1]
    puts "file_status: $status"

    if {[string first error $status] >= 0} {
        puts "error contents: $contents"
        #set msg [strategyParseError $contents]
        set msg [strategyParseError $contents]
        log_error $msg
        if {!$startedByBluIce} {
            set collect_msg [lreplace $collect_msg 0 1 \
            0 "Autoindex Error: $msg"]
        }
        return -code error $msg
    }
    if {[string first done $status] < 0} {
        set msg "maybe corrupted strategy file: $status"
        log_error $msg
        if {!$startedByBluIce} {
            set collect_msg [lreplace $collect_msg 0 1 \
            0 "Autoindex Error: maybe corrupted file: $status"]
        }
        return -code error $msg
    }

    set runDef [strategyParseFirstGroup $contents]
    puts "runDef: $runDef"

    #####populate the run definition
    #### keep original runlabel, fileroot and directory
    set localRun [set run$runNum]
    foreach {runLabel fileroot directory} [::DCS::RunField::getList \
    localRun \
    run_label file_root directory] break

    ::DCS::RunField::setList runDef \
    status inactive \
    next_frame 0 \
    run_label $runLabel \
    file_root $fileroot \
    directory $directory


    set oldExtra [set runExtra$runNum]

    set run$runNum $runDef
    set runExtra$runNum [lreplace $oldExtra 0 0 0]
    #wait_for_strings run$runNum runExtra$runNum
}
