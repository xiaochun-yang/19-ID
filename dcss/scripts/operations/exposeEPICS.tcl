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
proc expose_abort { } {
    global gExposeWaitingState
    global gExposeAfterID
    global gExposeDoneFlag

    log_warning abort expose

    after cancel gExposeAfterID
    set gExposeAfterID ""
    set gExposeWaitingState none
    set gExposeDoneFlag -1
}

proc exposeHandleTimeout { } {
    global gExposeWaitingState
    global gExposeAfterID

    set gExposeAfterID ""
    log_warning expose wait_for_start timed out
    set gExposeWaitingState wait_for_done
}
proc exposeHandleStatusUpdate { } {
    global gExposeWaitingState
    global gExposeAfterID
    global gExposeDoneFlag
    global gOperation

    variable exposeStatus

    #log_warning exposeHandleStatusUpdate: status=$exposeStatus
    #log_warning waitingState=$gExposeWaitingState

    if {$gOperation(expose,status) == "inactive"} {
        #log_warning exposing by others or dtb is busy
        return
    }

    switch -exact $gExposeWaitingState {
        wait_for_start {
            #log_warning enter wait_for_start
            if {$exposeStatus != 0} {
                #log_warning got start, now waiting for finish
                after cancel $gExposeAfterID
                set gExposeAfterID ""
                set gExposeWaitingState wait_for_done
                #log_warning new state=$gExposeWaitingState
            } else {
                log_warning got exposeStatus ==0 while wait for start
            }
        }
        wait_for_done {
            #log_warning enter wait_for_done
            if {$exposeStatus == 0} {
                #log_warning got finish
                set gExposeWaitingState none
                set gExposeDoneFlag 1
            } else {
                log_warning got exposeStatus = $exposeStatus while waiting for done
            }
        }
        default {
            #log_warning got exposeStatus=$exposeStatus while state=$gExposeWaitingState
        }
    }
}

proc expose_initialize {} {
    global gExposeWaitingState
    global gExposeAfterID

    set gExposeWaitingState none
    set gExposeAfterID ""

    registerEventListener exposeStatus ::nScripts::exposeHandleStatusUpdate

    registerAbortCallback expose_abort
}


### this is to use EPICS PVs to control expose
#string mapping:
#  exposeMode (mbbo or bo: number, not text)
#  exposeTime (ao)
#  exposeMotor  (string)
#  exposeMRange (ao)
#  exposeCmd (bo)
#  exposeStatus (ai or li) : 0 means done


proc expose_start { motor shutter delta time} {
    global gExposeWaitingState
    global gExposeAfterID
    global gExposeDoneFlag

    variable exposeMode
    variable exposeTime
    variable exposeMotor
    variable exposeMRange
    variable exposeCmd
    variable exposeStatus

    if { $time <= 0 } return

    switch -exact -- $motor {
        gonio_phi {
        }
        NULL {
        }
        default {
            log_error expose only support gonio_phi not $motor
            return -code error "bad motor $motor"
        }
    }

    if {$motor == "NULL" && $shutter == "NULL"} {
        wait_for_time [expr $time * 1000]
        return
    }

    if {$exposeStatus != 0} {
        #log_warning MarDTB or detector still busy ${exposeStatus}% waiting
        wait_for_string_contents exposeStatus 0
    }

    set exposeMode 0
    set exposeTime $time
    if {($motor == "NULL") || ($delta == 0)} {
        set exposeMotor ""
        set exposeMRange 0
    } else {
        set exposeMotor phi
        set exposeMRange $delta
    }

    set gExposeWaitingState wait_for_start
    set gExposeDoneFlag 0

    #### send start command
    set gExposeAfterID [after 3000 ::nScripts::exposeHandleTimeout]
    set exposeCmd 1

    ### wait it done
    #log_warning waiting expose done
    vwait gExposeDoneFlag
    #log_warning expose done

    if {$gExposeDoneFlag == -1} {
        return -code error aborted
    }
}

