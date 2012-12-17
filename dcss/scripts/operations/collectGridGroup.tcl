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


proc collectGridGroup_initialize {} {
}
proc collectGridGroup_cleanup {} {
    variable ::collectGrid::groupNum
    variable ::collectGrid::snapshotId
    variable ::collectGrid::gridId
    variable ::collectGrid::gridLabel
    variable ::collectGrid::needCleanup
    variable grid_msg

    set groupNum -1
    set snapshotId -1
    set gridId  -1
    set gridLabel ""

    set grid_msg [lreplace $grid_msg 0 0 0]
}

proc collectGridGroup_getNextIndex { } {
    variable ::collectGrid::gridId

    ### found current index
    set grid [::gGridGroup4Run getGrid $gridId]
    set gridList [::gGridGroup4Run getGridList]
    set currentIndex [lsearch -exact $gridList $grid]
    if {$currentIndex < 0} {
        log_severe current grid not found in the gridList.
        return -1
    }
    set nextIndex [expr $currentIndex + 1]
    set ll [llength $gridList]
    if {$nextIndex < $ll} {
        return $nextIndex
    }
    return -1
}

proc collectGridGroup_start { groupNum gridIndex args } {
	# global variables 
	global gClient
	global gPauseDataCollection
    variable grid_msg
    variable raster_runs
    variable beamlineID

    set userName [get_operation_user]
    set sessionID PRIVATE[get_operation_SID]
    save_collect_grid_data user $userName
    save_collect_grid_data sid $sessionID
    puts "saved user=$userName sid=$sessionID"

    set needUserLog 0
    collectGrid_populate $groupNum $gridIndex needUserLog 1

	#the data collection could not have been paused yet
	set gPauseDataCollection 0
	
    if {[catch correctPreCheckMotors errMsg]} {
        log_error failed to correct motors $errMsg
        return -code error $errMsg
    }

	set nextGridIndex $gridIndex
	
    ########################### user log ##################
    user_log_note raster "======$userName start collectGridGroup====="
    ### the "raster_runs" can change during the run.
    set done 0
	while {$nextGridIndex >= 0} {
		if { [catch {
			set operationHandle [eval start_waitable_operation collectGrid \
            $groupNum $nextGridIndex 1 $args]

			wait_for_operation_to_finish $operationHandle
		} errorResult] } {
			#got an abort.
			if {$errorResult == "error paused"} {
                set grid_msg [lreplace $grid_msg 0 1 0 Paused]
                user_log_note raster "=========end collectGridGroup paused======"
                return
            }

            #set grid_msg "inactive \{Error during data collection: $errorResult .\}" 
            set grid_msg [lreplace $grid_msg 0 1 0 "Error: $errorResult"]

			print "Error running collectRun operation: $errorResult"
            user_log_error raster $errorResult
            user_log_note raster "=========end collectGridGroup==========="
			return -code error $errorResult
		}

        #### find next grid: the grid list maybe changed during the run.
		
	    set nextGridIndex [collectGridGroup_getNextIndex]
	}

    set grid_msg [lreplace $grid_msg 0 1 0 {Data collection completed normally}]
    user_log_note raster "=========end collectGridGroup==========="
    cleanupAfterAll
	return
}

