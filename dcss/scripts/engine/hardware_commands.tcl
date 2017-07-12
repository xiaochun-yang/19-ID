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

set gConfig(updateServer) 1
set gDevice(abortCount) 0
set gWait(status) inactive

proc abort { {mode soft} } {

	# global variables
	global gDevice
	global gWait
	
	incr gDevice(abortCount)
	print "New abort count = $gDevice(abortCount)"

	if { $mode != "soft" && $mode != "hard" } {
		log_error "Invalid argument to abort: $mode"
		set mode "soft"
	}
	
	# send the message to the server immediately
	dcss sendMessage "gtos_abort_all $mode"
}


#added: sort ion chambers to support
#not on the same host
proc read_ion_chamber { seconds args } {
    log_severe please rename read_ion_chamber to read_ion_chambers
    return [eval read_ion_chambers $seconds $args]
}

proc read_ion_chambers { seconds args } {
	#find out if the requested script is already aborted
    puts "read_ion_chambers $seconds $args"
	set scriptInfo [get_script_info]
    puts "read_ion_chambers info: $scriptInfo"
	if { [lindex $scriptInfo 2] == "aborted" } {
		return -code error aborted
	}

    eval read_ion_chambers_nocheck $seconds $args
}
proc read_ion_chambers_nocheck { seconds args } {
	# global variables
	global gDevice

    # sort ion chambers according to hardwareHost
	foreach ionChamber $args {
        set host $gDevice($ionChamber,hardwareHost)
        lappend chamberArray($host) $ionChamber
    }
	foreach ionChamber $args {
		set gDevice($ionChamber,lastResult) normal
		set gDevice($ionChamber,status) counting
	}
    foreach host [array names chamberArray] {
	    set command "gtos_read_ion_chambers $seconds 0"
		eval lappend command $chamberArray($host)
	    dcss sendMessage $command
    }
}


proc get_ion_chamber_counts { args } {

	# global variables
	global gDevice
	
	set result ""
	foreach ionChamber $args {
        if {$gDevice($ionChamber,lastResult) != "normal"} {
            return -code error $gDevice($ionChamber,lastResult)
        }
		lappend result [expr double($gDevice($ionChamber,counts))] 
	}
	
	return $result
}

### we now give strict requirement like in BluIce scripting
proc move { motor pre value {units ""} } {
	global gDevice

    ###check inputs
    if {![isMotor $motor]} {
        log_error $motor is not a motor
        return -code error "$motor is not a motor"
    }
    if {$pre != "to" && $pre != "by"} {
        log_error move $motor MUST followed by "\"to\"" or "\"by\""
        return -code error "move $motor MUST be followed by \"to\" or \"by\""
    }
    ##this will allow something like expression
	if {[catch {set value [expr ($value)]}]} {
        log_error move $motor $pre an invalid position: $value
        return -code error "move $motor $pre an invalid position"
	}
	if {$units == "steps"} {
        set unScaled 1
	} else {
        set unScaled 0
        set value \
        [::units convertUnits $value $units $gDevice($motor,scaledUnits)]
    }
	
	move_no_parse $motor $pre $value $unScaled
}

# this function is only called by move function above
proc move_no_parse { motor prep value isUnscaledMove } {
	
	# global variables
	global gDevice

	#find out if the requested script is already aborted
	set scriptInfo [get_script_info hello]
	puts " ************* scriptInfo **************"
	puts " ************* $scriptInfo **************"
	if { [lindex $scriptInfo 2] == "aborted" } {
		return -code error aborted
	}

	# get old and new positions in scaled units
	if { $isUnscaledMove == 0 } {
		set oldPosition $gDevice($motor,scaled)
		if { $prep == "to" } {
			set newPosition $value
		} else {
			set newPosition [expr $value + $oldPosition]
		}
	} else {
		set scaleFactor $gDevice($motor,scaleFactor)
		set oldPosition [expr $gDevice($motor,unscaled) / $scaleFactor ]
		if { $prep == "to" } {
			set newPosition [expr $value / $scaleFactor ]
		} else {
			set newPosition [expr $value / $scaleFactor + $oldPosition ]
		}
	}

	# make sure device is inactive
	if { $gDevice($motor,status) != "inactive" } {
		print $gDevice($motor,status)
		set gDevice($motor,lastResult) moving
		dcss2 sendMessage "htos_motor_move_completed $motor $gDevice($motor,scaled) moving"
		abort
		return -code error moving
	}

	# make sure motor is not locked
	if { $gDevice($motor,lockOn) } {
		set gDevice($motor,lastResult) locked
		dcss2 sendMessage "htos_motor_move_completed $motor $gDevice($motor,scaled) locked"
		abort
		return -code error locked
	}

	# make sure children are inactive
	foreach child $gDevice($motor,children) {
		if { $gDevice($child,status) != "inactive" } {
			log_error "Child $child of $motor is already moving!"
			return -code error "${child}_moving"
		}
	}
		
	# make sure new positions are within limits
	if {![limits_ok $motor $newPosition] \
    ||  ![parent_limits_ok $motor $newPosition] \
    ||  ![children_limits_ok $motor $newPosition] \
    } {
		set gDevice($motor,lastResult) sw_limit
		dcss2 sendMessage "htos_motor_move_completed $motor $gDevice($motor,scaled) sw_limit"
		abort
		return -code error ${motor}_sw_limit
	}

	# tag motor as moving
	handle_move_start $motor

	set operationID [lindex $scriptInfo 3]
	if {$operationID == "" } {
		set operationID 1
	}

	# start the motor move via the move message handler
	after 0 stoh_start_motor_move $motor $newPosition $operationID
}

proc start_oscillation { motor shutter delta time } {
	global gDevice

	#find out if the requested script is already aborted
	set scriptInfo [get_script_info]
	if { [lindex $scriptInfo 2] == "aborted" } {
		return -code error aborted
	}

	if { ![limits_ok $motor [expr $gDevice($motor,scaled) + $delta]] } {
		print "****************** oscillation would exceed software limit"
		#dcss2 sendMessage "htos_motor_move_completed $motor $gDevice($motor,scaled) sw_limit"
		return -code error ${motor}_osc_sw_limit
	}

	#check to see if the speed of the requested oscillation can be handled by the motor.
	set unscaledDelta [expr int($delta * $gDevice($motor,scaleFactor)) ]
	set requestedSpeed [ expr $unscaledDelta / $time ]
	if { $requestedSpeed > $gDevice($motor,speed) } {
		return -code error "exposure_too_fast_for_$motor"
	}
	
	# tag motor as moving
	handle_move_start $motor
	
	# send the start oscillation message to DCSS
	dcss sendMessage "gtos_start_oscillation $motor $shutter $delta $time"
}

#only waitable operations and operations in lock_operation list will be
#added to the gOutstandingOperations
########################################
# In some DHS implementation, like detector dhs,
# it does not send the operation completed message.
# Before it is fixed, add all operations to the set will cause
# dcss memory leak (the list will grow and grow).
#

proc start_operation { operationName args } {
	global gOperation
    global gDevice

    #make sure the operation exist
    if {![info exists gOperation($operationName,hardwareHost)]} {
        return -code error "operation $operationName not exist"
    }
    
	#find out if the requested script is already aborted
	set scriptInfo [get_script_info]
	if { [lindex $scriptInfo 2] == "aborted" } {
		return -code error aborted
	}

	set operationHandle [create_operation_handle]

	# execute the message start operation message handler if handled by the self client
	if { [info exists gOperation($operationName,status) ] } {
		dcss2 sendMessage "htos_start_operation $operationName $operationHandle $args"
		after 0 eval stoh_start_operation $operationName $operationHandle $args
	} else {
		dcss sendMessage "gtos_start_operation $operationName $operationHandle $args"
	}
}


proc start_recovery_operation { operationName args } {
	global gOperation
    global gDevice

    #make sure the operation exist
    if {![info exists gOperation($operationName,hardwareHost)]} {
        return -code error "operation $operationName not exist"
    }
    
	set operationHandle [create_operation_handle]

	# execute the message start operation message handler if handled by the self client
	if { [info exists gOperation($operationName,status) ] } {
		dcss2 sendMessage "htos_start_operation $operationName $operationHandle $args"
		after 0 eval stoh_start_operation $operationName $operationHandle $args
	} else {
		dcss sendMessage "gtos_start_operation $operationName $operationHandle $args"
	}
}


proc start_waitable_operation { operationName args } {
	global gOperation
    global gDevice

    #make sure the operation exist
    if {![info exists gOperation($operationName,hardwareHost)]} {
        return -code error "operation $operationName not exist"
    }
    
	#get the hardware host for this operation
	set hardwareHost  $gOperation($operationName,hardwareHost) 
	#put the set of operations controlled by the hardware host in the global name space
	global gOutstandingOperations${hardwareHost}

	#find out if the requested script is already aborted
	set scriptInfo [get_script_info]
	if { [lindex $scriptInfo 2] == "aborted" } {
		return -code error aborted
	}

	set operationHandle [create_operation_handle]

	set gOperation($operationHandle,status) active
	set gOperation($operationHandle,result) ""
	set gOperation($operationHandle,name) $operationName
    puts "set op $operationHandle name to $operationName"

	#create the update fifo indices
	set gOperation($operationHandle,updateInIndex) 0
	set gOperation($operationHandle,updateOutIndex) 0

    set gOperation($operationName,stopFlag) 0

	# execute the message start operation message handler if handled by the self client
	if { [info exists gOperation($operationName,status) ] } {
		dcss2 sendMessage "htos_start_operation $operationName $operationHandle $args"
		after 0 eval stoh_start_operation $operationName $operationHandle $args
	} else {
		dcss sendMessage "gtos_start_operation $operationName $operationHandle $args"
	}

	#add the operation to the set of operations controlled by the hardware host
	add_to_set gOutstandingOperations${hardwareHost} [list $operationName $operationHandle]
	print "outstanding operations for $hardwareHost: [get_set gOutstandingOperations${hardwareHost}]"

	return $operationHandle
}

proc start_waitable_recovery_operation { operationName args } {
    global gOperation
    global gDevice

    #make sure the operation exist
    if {![info exists gOperation($operationName,hardwareHost)]} {
        return -code error "operation $operationName not exist"
    }
    
        #get the hardware host for this operation
        set hardwareHost  $gOperation($operationName,hardwareHost)
        #put the set of operations controlled by the hardware host in the global name space
        global gOutstandingOperations${hardwareHost}

        set operationHandle [create_operation_handle]

        set gOperation($operationHandle,status) active
        set gOperation($operationHandle,result) ""
	    set gOperation($operationHandle,name) $operationName

        #create the update fifo indices
        set gOperation($operationHandle,updateInIndex) 0
        set gOperation($operationHandle,updateOutIndex) 0

        # execute the message start operation message handler if handled by the self client
        if { [info exists gOperation($operationName,status) ] } {
                dcss2 sendMessage "htos_start_operation $operationName $operationHandle $args"
                after 0 eval stoh_start_operation $operationName $operationHandle $args
        } else {
                dcss sendMessage "gtos_start_operation $operationName $operationHandle $args"
        }

        #add the operation to the set of operations controlled by the hardware host
        add_to_set gOutstandingOperations${hardwareHost} [list $operationName $operationHandle]
        print "outstanding operations for $hardwareHost: [get_set gOutstandingOperations${hardwareHost}]"

        return $operationHandle
}

proc operation_running { operationName } {
    global gOperation
    global gDevice

    set hardwareHost $gOperation($operationName,hardwareHost)
    global gOutstandingOperations${hardwareHost}
    if {![info exists gOutstandingOperations${hardwareHost}] } {
        return 0
    }
	set outstandingOperations [get_set gOutstandingOperations${hardwareHost}]
    ##log_note $hardwareHost pending $outstandingOperations
	foreach operation $outstandingOperations {
		set name [lindex $operation 0]
		set handle [lindex $operation 1]
        if {$name == $operationName} {
            return 1
        }
	}
    return 0
}

proc configure { args } {

	# global variables
	global gDevice
	global gConfig
	
	# find out how many arguments were passed
	set argc [llength $args]

	# extract the motor being operated on
	set motor [lindex $args 0]
		
	# check for null string
	if { $motor == "" } {
		log_error "No motor has been selected."
		return
	}
	
	# make sure motor exists
	if { ! [motor_exists $motor] } {
		log_error "Motor $motor does not exist."
		return
	}
	
	# get the value to be assigned
	set value [lindex $args 2]
	
	# convert on/off values to numbers
	if { $value == "on" || $value == "On" || $value == "ON" } {
		set value 1
	} elseif { $value == "off" || $value == "Off" || $value == "OFF" } {
		set value 0
	}

	# make sure value is valid
	if { ! [isExpr $value] } {
		log_error "An invalid value was specified."
		return -1
	}
	
	# get the parameter being changed
	set parameter [lindex $args 1]	

	if { [lsearch { position backlash lower_limit upper_limit } $parameter] != -1 } {
	
		configUnitedParameter $motor $parameter $value [lindex $args 3]
	
	} elseif { [lsearch { speed acceleration scale offset lock_enable	\
			lower_limit_enable upper_limit_enable reverse_enable 		\
			backlash_enable } $parameter] != -1 } {
		
		configUnitlessParameter $motor $parameter $value
	
	} else {
	
		# report error and return
		log_error "Configuration parameter $parameter not recognized."
		return
	}
		
	# update server if requested
	if { $gConfig(updateServer) == 1 } {
		update_motor_config_to_server $motor
	}
}



proc open_shutter { shutter { nocheck 0 } } {
	global gDevice

    if {!$nocheck} {
	    #find out if the requested script is already aborted
	    set scriptInfo [get_script_info]
	    if { [lindex $scriptInfo 2] == "aborted" } {
		    return -code error aborted
	    }
    }

	dcss sendMessage "gtos_set_shutter_state $shutter open"	
	#set the status so that the event can be waited for
	set gDevice($shutter,status) opening
}


proc close_shutter { shutter {nocheck 0} } {
	global gDevice
	
    if {!$nocheck} {
	    #find out if the requested script is already aborted
	    set scriptInfo [get_script_info]
	    if { [lindex $scriptInfo 2] == "aborted" } {
		    return -code error aborted
	    }
    }

	dcss sendMessage "gtos_set_shutter_state $shutter closed"	
	#set the status so that the event can be waited for
	set gDevice($shutter,status) closing
}


proc get_encoder {encoder {ignore_abort 0}} {
	global gDevice

	#find out if the requested script is already aborted
    if {!$ignore_abort} {
	    set scriptInfo [get_script_info]
	    if { [lindex $scriptInfo 2] == "aborted" } {
		    return -code error aborted
	    }
    }


	if { $gDevice($encoder,status) != "inactive" } {
		log_error "Still waiting for previous $encoder activity to complete."
		return
	}

	dcss sendMessage "gtos_get_encoder $encoder"
	set gDevice($encoder,status) acquiring
}


proc set_encoder {encoder position} {
	global gDevice
	
	if { $gDevice($encoder,status) != "inactive" } {
		log_error "Still waiting for previous $encoder activity to complete."
		return
	}
	
	dcss sendMessage "gtos_set_encoder $encoder $position"
	set gDevice($encoder,status) calibrating
}

proc assertMotorLimit {motor targetPosition} {
	
	if { ![limits_ok $motor $targetPosition] } {
		::dcss2 sendMessage "htos_note Warning Moving $motor to $targetPosition would violate software limit."
		return -code error "${motor}_sw_limit"
	}

	return 1
}

proc block_all_motors {} {
	global gDevice
	
	#only scripted operations can call this function. Get the handle of the caller.
	set operationID [lindex [get_operation_info] 1]

	#check to see if the motors are already blocked
	if { $gDevice(all_motors_blocked) != "unblocked" } {
		return -code error block_failed_already_blocked
	}
	
	#check to see if a motors is already moving
 	foreach motor $gDevice(motor_list) {
		if { $gDevice($motor,status) != "inactive" } {
			return -code error block_failed_moving_$motor
		}
	}

    ##clear all motors
 	foreach motor $gDevice(motor_list) {
        set gDevice($motor,lastResult) normal
	}
	
	#store the operationID that issued this command for automatic clean up later.
	set gDevice(all_motors_blocked) $operationID

	return
}

proc unblock_all_motors {} {
	global gDevice

	#Get the operation handle of the caller.
	set operationID [lindex [get_operation_info] 1]

	#verify that this is the same caller as the block_all_motors
	if { $gDevice(all_motors_blocked) != "unblocked" } {
		if { $gDevice(all_motors_blocked) == $operationID } {
			puts "unblocking all motors"
			set gDevice(all_motors_blocked) "unblocked"
		} else {
			return -code error unblock_from_original_operation_only
		}
	}
}
