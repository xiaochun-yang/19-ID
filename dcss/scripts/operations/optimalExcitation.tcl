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

proc optimalExcitation_initialize {} {
}



proc optimalExcitation_start { userName_ sessionId_ directory_ fileRoot_ selectedEdge_ energy_ scanTime_ } {
    global gWaitForGoodBeamMsg
    variable scan_msg

    variable excitationScanStatus

    set index(active) 0
    set index(message) 1
    set index(user) 2
    set index(directory) 3
    set index(fileRoot) 4
    set index(edge) 5
    set index(energy) 6
    set index(cutoff) 7
    set index(time) 8
    set index(madResult) 9
    set index(exciteResult) 10

    checkUsernameInDirectory directory_ $userName_

    set excitationScanStatus [lreplace $excitationScanStatus 0 $index(time) \
    1 \
    {Optimizing fluorescence signal.} \
    $userName_ \
    $directory_ \
    $fileRoot_ \
    $selectedEdge_ \
    [list $energy_ eV] \
    N/A \
    [list $scanTime_ s] \
    ]

    if [catch {block_all_motors;unblock_all_motors} errMsg] {
        log_error $errMsg
        puts "MUST wait all motors stop moving to start"
        log_error "MUST wait all motors stop moving to start"
        return -code error "MUST wait all motors stop moving to start"
    }
    
    if {$sessionId_ == "SID"} {
        set sessionId_ "PRIVATE[get_operation_SID]"
        puts "use operation SID: [SIDFilter $sessionId_]"
    }

    ################# check directory #####################
    if {[catch {
        impDirectoryWritable $userName_ $sessionId_ $directory_
    } errMsg]} {
        log_error directory $directory_ check failed: $errMsg
        return -code error "directory not writable"
    }

    if {[catch correctPreCheckMotors errMsg]} {
        log_error failed to correct motors $errMsg
        return -code error $errMsg
    }

    set referenceDetector "i2"

    #############user log ######
    user_log_note excitationscan "============ $userName_ start =========="
    user_log_note excitationscan "edge       $selectedEdge_"
    user_log_note excitationscan "energy     $energy_"
    user_log_note excitationscan "scanTime   $scanTime_"
    user_log_note excitationscan "directory  $directory_"
    user_log_note excitationscan "fileRoot   $fileRoot_"
    user_log_note excitationscan "crystal    [user_log_get_current_crystal]"

    # store old motor positions as necessary
    set filterStatusList [getAllFilterStatus]

    set gWaitForGoodBeamMsg scan_msg

    if {[catch {    
        set skip_save 0
        set scan_done 0
        while {!$scan_done} {
            if {![beamGood]} {
                wait_for_good_beam
            }
            if {[catch {
                #prepare for the scan
                set scan_msg "prepare for scan"
                set opHandle [start_waitable_operation prepareForScan $energy_ $skip_save]
                set prepareResult [wait_for_operation $opHandle]

                ##### record system status after prepare
                user_log_note excitationscan "after prepareForScan"
                user_log_system_status excitationscan
            
                set scan_msg "excitation spectrum"
                #Get the excitation spectrum without starting another operation
                #This will reduce the amount of network traffic caused by operation results being broadcast.
                set scanResult [excitationScan_start 0 25600 1024 $referenceDetector $scanTime_]

                if {[beamGood]} {
                    set scan_done 1
                }
            } EM]} {
                if {[string first BEAM_NOT_GOOD $EM] < 0} {
                    return -code error $EM
                }
                log_warning waiting for good beam to restart excitationscan
                user_log_warning excitationscan BEAM_NOT_GOOD, restarting scan
                set skip_save 1
            }
        }

        set percentDeadTime [lindex $scanResult 0]
        set referenceCounts [lindex $scanResult 1]
        set scanPoints [lrange $scanResult 2 end]

        user_log_note excitationscan "result percent_deadtime $percentDeadTime"
        user_log_note excitationscan "result ref_counts       $referenceCounts"

        #foreach {percentDeadTime referenceCounts scanPoints} $scanResult break

        set fullPath [file join $directory_ ${fileRoot_}.bip]
        log_warning $fullPath
        set delta 25
        set beamline [::config getConfigRootName]
        set writeScanOp [start_waitable_operation writeExcitationScanFile $userName_ $sessionId_ $fullPath $percentDeadTime $referenceCounts $delta $selectedEdge_ $energy_ $scanTime_ $beamline $scanPoints] 

        #send_operation_update $selectedEdge_ [lrange $scanResult 1 end]
        set scan_msg "recover from scan"
        set recoverOp [start_waitable_operation recoverFromScan]

        set result [wait_for_operation $writeScanOp]

        user_log_note excitationscan "result file             $fullPath"

        #set exciteResult [lrange $result 1 end]
        set exciteResult $fullPath

        if {[catch {
            set scanDir [::config getExcitationScanDirectory]
            if {$scanDir != ""} {
                global gBeamlineId
                set commonFile [file join $scanDir $gBeamlineId.bip]

                ##### take this out once we can force copy in service
                catch {file delete $commonFile}
                ###########################################

                impCopyFile $userName_ $sessionId_ $fullPath $commonFile "0777"
                set exciteResult $commonFile
            } else {
                log_warning others may not be able to see the excitaion scan: common file not enabled
            }
        } copyErr]} {
            log_warning others may not be able to see the excitation scan: failed to create common file: $copyErr
        }

        send_operation_update $exciteResult 

        wait_for_operation $recoverOp
    } errorResult ] } {
        variable excitationScanStatus
        set excitationScanStatus [lreplace $excitationScanStatus 0 $index(message) 0 "Excitation scan failed: $errorResult."]

        set gWaitForGoodBeamMsg ""

        # restore filter states
        restoreFilterStatus $filterStatusList
        close_shutter shutter 1
        log_error "Excitation scan failed: $errorResult"
        user_log_error excitationscan "failed $errorResult"
        user_log_note  excitationscan "==================end=================="

        set scan_msg "error: $errorResult"
        return -code error $errorResult
    }

    set gWaitForGoodBeamMsg ""

    # restore filter states
    restoreFilterStatus $filterStatusList
    close_shutter shutter 1


    set fluorScanTemp [lreplace $excitationScanStatus 0 $index(message) 0 "Excitation scan completed normally."]
    set excitationScanStatus [lreplace $fluorScanTemp $index(exciteResult) $index(exciteResult) $exciteResult]

    user_log_note  excitationscan "==================end=================="

    set scan_msg ""

    cleanupAfterAll
    return $exciteResult
}
