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


###
## Please setup following mapping in databse:
#xppDAQBegin         XPP:DAQ:BEGIN
#xppDAQEnd           XPP:DAQ:DCONNECT
#xppDAQNumOfEvent    XPP:DAQ:NEVT
#xppDAQWait          XPP:DAQ:WAIT

#=======
#XRay laser request:
#xppNumShot          PATT:Sys0:1:MPSBURSTCNTMAX
#xppBurst            PATT:Sys0:1:MPSBURSTCTRL

#======
#phi
#xppPhiSpeed         XPP:GON:MMS:11.VELO
#xppPhiBaseSpeed     XPP:GON:MMS:11.VBAS
#xppPhiAcc           XPP:GON:MMS:11.ACCL


#need:
#xppDAQFileName      XPP:DAQ:FILE ?????



## phi_acc XPP:GON:MMS:


package require DCSSpreadsheet

proc collectFrame_initialize {} {
    global gCollectFrameEVTState
    global gCollectFrameEVTDoneFlag

    set gCollectFrameEVTState none
    set gCollectFrameEVTDoneFlag 0

    namespace eval ::xpp {
    }


    registerEventListener ecsPlayStatus ::nScripts::collectFrame_updateState
    registerAbortCallback collectFrame_abort
}
proc collectFrame_updateState { } {
    global gCollectFrameEVTState
    global gCollectFrameEVTDoneFlag

    variable ecsPlayStatus

    switch -exact -- $gCollectFrameEVTState {
        waiting_evt_start {
            if {$ecsPlayStatus != 0} {
                set gCollectFrameEVTState waiting_evt_end
                log_warning evt sequence started
            }
        }
        waiting_evt_end {
            if {$ecsPlayStatus == 0} {
                set gCollectFrameEVTState none 
                log_warning evt sequence ended 
                set gCollectFrameEVTDoneFlag 1
            }
        }
        none -
        default {
        }
    }
}
proc collectFrame_abort { } {
    global gCollectFrameEVTState
    global gCollectFrameEVTDoneFlag

    set gCollectFrameEVTState none 
    set gCollectFrameEVTDoneFlag -1
}
proc xppSetupEventSequence { time delta } {
    variable ecsCodeList
    variable ecsBeamDelayList
    variable ecsFiducialDelayList
    variable ecsLength
    variable ecsPlayMode
    variable ecsValidate
    variable ecsPlayStatus
    variable xppDAQNumOfEvent
    variable xppDAQNumberDesc2
    variable xppDAQNumberValue2

    if {$ecsPlayStatus != 0} {
        log_error EPICS EV1 is still running.
        return -code error NEED_IDLE
    }

    if {$delta == 0} {
        set delay 0
    } else {
        ##TODO: get delay from time and delta.
        set delay 0.2
    }

    set numShot  [expr int(120.0 * $time)]
    if {$numShot < 1} {
        set numShot 1
    }
    log_warning numShot=$numShot
    set timeReal [expr $numShot / 120.0]
    if {abs($time - $timeReal) > 0.001} {
        log_warning exposure time adjusted to $timeReal second
    }

    set numDelay [expr int(120.0 * $delay)]
    if {$numDelay < 0} {
        set numDelay 0
    }

    set xppDAQNumberDesc2 "exposure_time"
    set xppDAQNumberValue2 $timeReal

    if {$numDelay == 0} {
        set evCodeList  ""
    	set evDelayList "1 "
    } else {
        set evCodeList "67 "
    	set evDelayList "1 $numDelay "
    }
    append evCodeList  [string repeat "68 " $numShot]
    ### delay has extra one element.  just for the sake of simple programe.
    append evDelayList [string repeat " 1"  $numShot]
    set evCodeList  [string trim $evCodeList]
    set evDelayList [string trim $evDelayList]
    set ll          [llength $evCodeList]

    set ecsCodeList      $evCodeList
    set ecsBeamDelayList $evDelayList
    set ecsLength        $ll
    set ecsValidate      1
    ### play once.
    set ecsPlayMode      0

    set xppDAQNumOfEvent $numShot

    puts "xppSetupEventSequence $time $delta"
    set line0 ""
    set line1 ""
    for {set i 0} {$i < $ll} {incr i} {
        set code  [lindex $evCodeList  $i]
        set delay [lindex $evDelayList $i]
        append line0 [format %5d $code]
        append line1 [format %5d $delay]
    }
    puts "code:  $line0"
    puts "delay: $line1"
}
proc xppRunEvent { filename time delta } {
    global gCollectFrameEVTState
    global gCollectFrameEVTDoneFlag

    variable gonio_phi
    variable detector_status

    variable xppDAQStringDesc1
    variable xppDAQStringValue1
    variable xppDAQNumberDesc1
    variable xppDAQNumberValue1
    variable xppDAQBegin
    variable xppDAQWait
    variable ecsPlayControl
    variable ecsPlayStatus

    set xppDAQStringDesc1 "filename"
    set xppDAQStringValue1 $filename
    set xppDAQNumberDesc1 "phi"
    set xppDAQNumberValue1 $gonio_phi

    set xppDAQBegin 1

    if {$delta != 0} {
	    set operationHandle [start_waitable_operation moveMotorOnInput gonio_phi $delta $time]
	    set result [wait_for_operation $operationHandle]
	    set status [lindex $result 0]
	    if { $status != "update" } {
            error "expected update message from dhs"
        }
    }
    log_warning waiting for the DAQ software to startup
    wait_for_string_contents xppDAQWait 1
    #wait_for_time 500

    ### start trigger sequence
    set gCollectFrameEVTState waiting_evt_start
    set gCollectFrameEVTDoneFlag 0
    set ecsPlayControl 1

    vwait gCollectFrameEVTDoneFlag

    start_operation detector_transfer_image
    set detector_status "Reading Out Detector..."

    if {$gCollectFrameEVTDoneFlag < 0} {
        log_error aborted
        return -code error aborted
    }
    
    log_warning waiting for WAIT to end
    wait_for_string_contents xppDAQWait 0

    if {$delta != 0} {
	    set result [wait_for_operation_to_finish $operationHandle]
        wait_for_motor_if_moving gonio_phi
    }
}

proc collectFrame_start { darkCacheNumber filename directory userName \
motor shutterName \
delta time \
modeIndex flush reuseDark sessionId args } {

    # global variables
    global gClient
    global gDevice

    global gMotorEnergy
    global gMotorDistance
    global gMotorVert
    global gMotorHorz
    global gMotorPhi
    global gMotorOmega
    
    variable $gMotorDistance
    variable $gMotorPhi
    variable $gMotorOmega
    variable $gMotorEnergy
    variable $gMotorVert
    variable $gMotorHorz

    variable detector_status
    variable detectorMode

    variable ::xpp::dRamp
    variable ::xpp::tRamp

    variable xppDAQWait
    variable xppDAQBegin
    variable xppDAQEnd
    variable xppBurst
    variable xppDAQNumberDesc3
    variable xppDAQNumberValue3

    set detectorMode $modeIndex
    
    set needUserLog 0

    if {$motor == "NULL"} {
        set delta 0
    }

    set xppDAQNumberDesc3 "delta"
    set xppDAQNumberValue3 $delta
    
    #find out the operation handle
    set op_info [get_operation_info]
    set op_name [lindex $op_info 0]
    set operationHandle [lindex $op_info 1]

    #find out the client id that started this operation
    set clientId [expr int($operationHandle)]
    #get the name of the user that started this operation
    set clientUserName $gClient($clientId)
    if { $clientUserName != $userName && $clientUserName != "self" } {
        return -code error hacker
    }
    
    if {$sessionId == "SID"} {
        set sessionId PRIVATE[get_operation_SID]
        puts "use operation SID: [SIDFilter $sessionId]"
    }

    if {$clientUserName != "self"} {
        set needUserLog 1
    }
    ########################### user log ##################
    if {$needUserLog} {
        user_log_note collecting "=======$userName start collectFrame=========="
        puts "calling user log system status"
        user_log_system_status collecting
    }


    ###more generic
    ###set wavelength [expr 12398.0 / $energy ]
    set eu $gDevice($gMotorEnergy,scaledUnits)
    log_note $gMotorEnergy units $eu

    if {$eu != "eV" && $eu != "keV" && $eu != "A"} {
        log_error $gMotorEnergy has wrong units: $eu
        return -code error "energy has wrong units: $eu"
    }
    
    set wavelength [::units convertUnits [set $gMotorEnergy] $gDevice($gMotorEnergy,scaledUnits) A]
    log_note wavelength $wavelength A
    
    if { $motor != "NULL" } {
        variable $motor
        set startAngle [set $motor]
    } else {
        set startAngle [set $gMotorPhi]
    }
    
    #catch and handle errors during the exchange with the detector
    if { [catch {
        set new_filename  [TrimStringForCrystalID $filename]
        set new_directory [TrimStringForRootDirectoryName $directory]
        if {$new_filename != $filename} {
            log_warning filename changed from $filename to $new_filename
            set filename $new_filename
        }
        if {$new_directory != $directory} {
            log_warning directory changed from $directory to $new_directory
            set directory $new_directory
        }
		set operationHandle [start_waitable_operation detector_collect_image \
										 $darkCacheNumber \
										 $filename \
										 $directory \
										 $userName \
										 $motor \
										 $time \
										 $startAngle \
										 $delta \
										 [set $gMotorDistance] \
										 $wavelength \
										 [set $gMotorHorz] \
										 [set $gMotorVert] \
										 $modeIndex \
										 $reuseDark \
                                         $sessionId]

		set status "update"
		#loop over all intermediate messages from the detector
		while { $status == "update" } {
			set result [wait_for_operation $operationHandle]
            log_warning got update from detector_collect_image: $result
			
			set status [lindex $result 0]
			set result [lindex $result 1]
			if { $status == "update" } {
				set request [lindex $result 0]
				puts $request
				if { $request == "start_oscillation" } {
                    break
				}
			} else {
                log_severe the detector_collect_image does not send any update message.  Need to change code.
            }
		}
        xppSetupEventSequence $time $delta
        xppRunEvent $filename $time $delta

        wait_for_operation_to_finish $operationHandle

        ############### user log ###################
        if {$needUserLog} {
            set startAngle [format "%.3f" $startAngle]
            set    log_contents "[user_log_get_current_crystal] collectFrame"
            append log_contents " $directory/"
            append log_contents "$filename.[getDetectorFileExt $modeIndex]"
            append log_contents " $startAngle deg"
            user_log_note collecting $log_contents
        }
    } errorResult ] } {
        #handle every error that could be raised during data collection
        start_recovery_operation detector_stop
        close_shutter shutter
        if {$needUserLog} {
            user_log_error collecting $errorResult
            user_log_note collecting "=============end collectFrame==========="
        }
        return -code error $errorResult
    }
    if {$needUserLog} {
        user_log_note collecting "=============end collectFrame==========="
    }
}
