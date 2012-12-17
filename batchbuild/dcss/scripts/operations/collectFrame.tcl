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

package require DCSSpreadsheet

proc collectFrame_initialize {} {
	# global variables 
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

    set detectorMode $modeIndex
	
    set needUserLog 0
    
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
			
			set status [lindex $result 0]
			set result [lindex $result 1]
			if { $status == "update" } {
				set request [lindex $result 0]
				puts $request
				if { $request == "start_oscillation" } {
					set requestShutter [lindex $result 1]
					set requestExposure [lindex $result 2]
					
                    set detector_status "Exposing [lindex $result 3]..."

					#start the expose operation
					set exposeOperationHandle [start_waitable_operation expose $motor \
															 $requestShutter \
															 $delta \
															 $requestExposure ]
					#wait for the exposure
					print "Wait for exposure"
					wait_for_operation $exposeOperationHandle
					
					print "Exposure Completed"
					
					#inform the detector that the exposure is done
					start_operation detector_transfer_image
                    set detector_status "Reading Out Detector..."
				}
					
				if { $request == "prepare_for_oscillation" } {
					if { $motor != "NULL" } {
						set requestPhi [lindex $result 1]
						
						# start the motor moving
						move $motor to $requestPhi
						
						# wait for the oscillation to complete
						wait_for_devices $motor
					}
					#inform detector dhs that we are in position.
					start_operation detector_oscillation_ready
				}
				if { $request == "scanning_plate" } {
                    set detector_status " Scanning Plate [lindex $result 1]%..."
                }
				if { $request == "erasing_plate" } {
                    set detector_status " Erasing Plate [lindex $result 1]%..."
                }
			}
		}

        ############### user log ###################
        if {$needUserLog} {
            set startAngle [format "%.3f" $startAngle]
            set    log_contents "[user_log_get_current_crystal] collectFrame"
            append log_contents " $directory/"
            append log_contents "$filename.[getDetectorFileExt $modeIndex]"
            append log_contents " $startAngle deg"
            user_log_note collecting $log_contents
        }
		
		#image is complete
		if { $flush } {
			start_operation detector_stop
			set runStatus complete
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
