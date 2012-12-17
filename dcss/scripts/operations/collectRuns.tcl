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


proc collectRuns_initialize {} {
	# global variables 
}
proc collectRuns_cleanup {} {
    variable collect_msg
    set collect_msg [lreplace $collect_msg 0 0 0]
}

proc collectRunsCheckRunDefinition { runNumber userName sessionID } {
    variable runs

    set allOK 1

    ########re-check run definitions
	set nextRun $runNumber
	while { $nextRun <= [lindex $runs 0] } {
        fix_run_directory $runNumber $userName
        set runName run$nextRun
        variable $runName

        gSingleRunCalculator updateRunDefinition [set $runName]
        set dummy 0
        if {![checkForRun $nextRun $userName $sessionID dummy 1]} {
            set allOK 0
        }
		if {$runNumber == 0} {
            break
		} else {
			#move to the next run
			incr nextRun
		}
	}
    if {!$allOK} {
        log_error please correct above errors first
        return -code error runDefinitionWrong
    }
}


proc collectRuns_start { runNumber sessionID args } {
	# global variables 
    global gCollectWebStatusFile
    global gCollectWebUser
    global gCollectWebSID
	global gClient
	global gPauseDataCollection
    variable collect_msg
    variable runs
    variable beamlineID

    if {$sessionID == "SID"} {
        set sessionID PRIVATE[get_operation_SID]
        puts "use operation SID: [SIDFilter $sessionID]"
    }

    set gCollectWebStatusFile ""
    set gCollectWebUser ""
    set gCollectWebSID ""

	#the data collection could not have been paused yet
	set gPauseDataCollection 0
	
	#find out the operation handle
	set op_info [get_operation_info]
	set operationHandle [lindex $op_info 1]
	#find out the client id that started this operation
	set clientId [expr int($operationHandle)]
	#get the name of the user that started this operation
	set userName $gClient($clientId)
	
    collectRunsCheckRunDefinition $runNumber $userName $sessionID

    if {[catch correctPreCheckMotors errMsg]} {
        log_error failed to correct motors $errMsg
        return -code error $errMsg
    }

    #set collect_msg "collecting \{Started data collection at run $runNumber.\}" 
    set collect_msg [lreplace $collect_msg 0 6 \
    1 Starting 0 $beamlineID $userName {} $runNumber]

	set nextRun $runNumber
	
    ########################### user log ##################
    user_log_note collecting "======$userName start collectRuns $runNumber====="
	#loop over all remaining frames until this run is complete

    ###here the total runs has to get from the string "runs" directly.
    ### the "runs" can change during the run.
	while { $nextRun <= [lindex $runs 0] } {
		if { [catch {
			set operationHandle [eval start_waitable_operation collectRun $nextRun $userName 0 $sessionID $args]
			wait_for_operation_to_finish $operationHandle
		} errorResult] } {
			#got an abort.
			if {$errorResult == "error paused"} {
                set collect_msg [lreplace $collect_msg 0 1 0 Paused]
                user_log_note collecting "=========end collectRuns paused======"
                return
            }

            #set collect_msg "inactive \{Error during data collection: $errorResult .\}" 
            set collect_msg [lreplace $collect_msg 0 1 0 "Error: $errorResult"]

			print "Error running collectRun operation: $errorResult"
            user_log_error collecting $errorResult
            user_log_note collecting "=========end collectRuns==========="
			return -code error $errorResult
		}
		
		#automatically increment to the next run if we are not in run 0
		if {$runNumber == 0} {
            user_log_note collecting "=========end collectRuns==========="
			return snapshotFinished
		} else {
			#move to the next run
			incr nextRun
		}
	}

    set collect_msg [lreplace $collect_msg 0 1 0 {Data collection completed normally}]
    user_log_note collecting "=========end collectRuns==========="
	return
}

