proc madCollect_initialize { } {
    namespace eval ::madCollect {
        set userName ""
        set sessionId ""
        set energyRegionList [list]
        set phiRegionList [list]
    }
}
proc madCollect_checkRegionList { regions_ } {
    set result 0

    foreach r $regions_ {
        if {[llength $r] < 3} {
            log_error bad region $r
            return -code error bad_region
        }
        foreach {start end step} $r break
        if {![string is double -strict $start] \
        || ![string is double -strict $end] \
        || ![string is double -strict $step] \
        || $step ==0} {
            log_error start end step must all be numbers and step != 0
            return -code error bad_region
        }

        set numStep [expr int(double($end - $start) / $step) + 1]
        incr result $numStep
    }
    return $result
}
proc madCollect_start { dir_ prefix_ exposureTime_ energyRegions_ phiRegions_ } {
    global gMotorEnergy
    global gMotorPhi
    global gWaitForGoodBeamMsg

    variable scan_msg

    ## tell wait_for_good_beam to display msg
    set gWaitForGoodBeamMsg scan_msg
    if {![beamGood]} {
        wait_for_good_beam
    }

    set counterFormat [::config getFrameCounterFormat]

    ##check input parameters
    set numER [llength $energyRegions_]
    set numPR [llength $phiRegions_]
    if {$numER <= 0 || $numPR <= 0} {
        log_error no energy region or phi region defined
        return -code error "wrong_regions"
    }
    log_warning DEBUG checking energyRegions
    set totalE [madCollect_checkRegionList $energyRegions_]
    log_warning DEBUG checking phiRegions
    set totalP [madCollect_checkRegionList $phiRegions_]

    set totalNum [expr $totalE * $totalP]

    ###check dir
    set userName [get_operation_user]
    set sessionID PRIVATE[get_operation_SID]
    impDirectoryWritable $userName $sessionID $dir_

    if [catch {block_all_motors;unblock_all_motors} errMsg] {
        log_error $errMsg
        puts "MUST wait all motors stop moving to start collecting"
        log_error "MUST wait all motors stop moving to start collecting"
        return -code error "MUST wait all motors stop moving to start"
    }

    variable runs
	set useDose [lindex $runs 2]

    if {[catch {
        if {$useDose} {
            normalize_start
        }
    } errMsg]} {
        log_error normalize for dose mode failed: $errMsg
        return -code error $errMsg
    }

    user_log_note collecting "======$userName start madCollect======"
    user_log_note collecting "Total energy region $numER phiRegion $numPR images: $totalNum"

    set imageCount 0

    if {[catch {
        set modeIndex 0
        set fileExt [getDetectorFileExt $modeIndex]

        for {set eIndex 0} {$eIndex < $numER} {incr eIndex} {
            log_warning EEEEEEEEIndex $eIndex
            foreach {eStart eEnd eStep} [lindex $energyRegions_ $eIndex] break
            log_warning energy region $eStart $eEnd $eStep
            set numEnergy [expr int(double($eEnd - $eStart) / $eStep) + 1]
            for {set eCounter 0} {$eCounter < $numEnergy} {incr eCounter} {
                set e [expr $eStart + $eCounter * $eStep]
                log_warning moving energy to $e
                move $gMotorEnergy to $e
                wait_for_devices $gMotorEnergy
                user_log_system_status collecting

                set eLabel [expr $eCounter + 1]

                for {set pIndex 0} {$pIndex < $numPR} {incr pIndex} {
                    set filePrefix \
                    ${prefix_}_E[expr $eIndex + 1]_[format $counterFormat $eLabel]_P[expr $pIndex + 1]

                    foreach {pStart pEnd pStep} [lindex $phiRegions_ $pIndex] break
                    set numPhi [expr int(double($pEnd - $pStart) / $pStep) + 1]

                    for {set phiCounter 0} {$phiCounter < $numPhi} {incr phiCounter} {
                        set phiLabel [expr $phiCounter + 1]
                        set phi [expr $pStart + $phiCounter * $pStep]
                        move $gMotorPhi to $phi
                        wait_for_devices $gMotorPhi
                        set logAngle [format "%.3f" $phi]

                        set filename ${filePrefix}_[format $counterFormat $phiLabel]

                        incr imageCount

                        set scan_msg "collecting $imageCount of $totalNum"
                        set imageDone 0
                        while {!$imageDone} {

                            read_ion_chambers 0.1 i2
                            wait_for_devices i2
                            set ic [get_ion_chamber_counts i2]
                            user_log_note collecting "i2=$ic"

                            set operationHandle [eval start_waitable_operation \
                            collectFrame \
                            16 \
                            $filename \
                            $dir_ \
                            $userName \
                            $gMotorPhi \
                            shutter \
                            $pStep \
                            [requestExposureTime_start $exposureTime_ $useDose] \
                            $modeIndex \
                            0 \
                            0 \
                            $sessionID \
                            ]
			                wait_for_operation_to_finish $operationHandle

                            set    log_contents "[user_log_get_current_crystal]"
                            append log_contents " madCollect $imageCount of $totalNum"
                            append log_contents " $dir_/$filename.$fileExt"
                            append log_contents " $logAngle deg"
                            user_log_note collecting $log_contents

			                if { ![beamGood] } {
				                #The beam went down during the last frame.
				                #Don't move to the next frame, but wait for the beam to come back
				                wait_for_good_beam
                                set scan_msg \
                                "re-collecting $imageCount of $totalNum: $filename"
			                } else {
				                #move to the next frame
				                set imageDone 1
			                }
                        }
                    }
                }
            }
        }
    } errMsg]} {
        set gWaitForGoodBeamMsg ""
		start_recovery_operation detector_stop
        user_log_error collecting "madCollect $errMsg"
        user_log_note collecting "=======end madCollect========"
        set scan_msg "error: $errMsg"

        return -code error $errMsg
    }
    set gWaitForGoodBeamMsg ""
    set scan_msg ""
    user_log_note collecting "=======end madCollect========"
}
