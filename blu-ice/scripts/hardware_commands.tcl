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

proc correct { {motor default} } {

	# global variables
	global gDevice

	# handle default argument
	if { $motor == "default" } {
		# report error if no motor selected
		if { $gDevice(control,motor) == "" } {
			log_error "No motor has been selected."
			return
		} else {
			set motor $gDevice(control,motor)
		}
	}

	# make sure motor is a pseudomotor
	if { $gDevice($motor,type) != "pseudo_motor" } {
		log_error "Motor $motor is not a pseudomotor!"
		return
		}

	# make sure motor is not already moving
	if { $gDevice($motor,status) != "inactive" } {
		log_error "Motor $motor is already moving!"
		return
		}
	
	handle_move_start $motor
	
	# request server to start the move
	dcss sendMessage "gtos_correct_motor $motor"	

}


proc undo { {motor default} } {

	# global variables
	global gDevice

	# handle default argument

	if { $motor == "default" } {
		# report error if no motor selected
		if { $gDevice(control,motor) == "" } {
			log_error "No motor has been selected."
			return
		} else {
			set motor $gDevice(control,motor)
		}
	}
	
	# make sure an undo command is available
	if { $gDevice($motor,undoCommand) == "" } {
		log_error "No undo for this motor."
		return
	}
	
	# make sure the motor is inactive
	if { $gDevice($motor,status) != "inactive" } {
		log_error "Cannot undo while motor is active."
		return
	}
	
	# disable the undo button if device is currently selected
	if { $gDevice(control,motor) == $motor } {
		$gDevice(control,undoButton) configure -state disabled		
	}
	
	# execute the undo command
	uplevel #0 $gDevice($motor,undoCommand)
	
	# clear the undo message
	set gDevice($motor,undoCommand) ""
}


proc abort { {mode soft} } {

	# global variables
	global gDevice
	global gWait
	global gScan
	
	if { $mode != "soft" && $mode != "hard" } {
		log_error "Invalid argument to abort: $mode"
		set mode "soft"
	}
	
	# send the message to the server immediately
	dcss sendMessage "gtos_abort_all $mode"
	
	# abort wait timer if running
	if { $gWait(status) == "waiting" } {
		set gWait(status) aborting
	}

	# indicate that scan was ended abrubtly
	set gScan(aborted) 1
	
	# update the motor control
	updateMotorControlButtons
}

proc abort_motor { motorname mode  } {

	# global variables
	global gDevice
	global gWait
	global gScan
	
	if { $mode != "soft" && $mode != "hard" } {
		log_error "Invalid argument to abort: $mode"
		set mode "soft"
	}
	
	# send the message to the server immediately
	dcss sendMessage "gtos_abort_motor_move $motorname $mode"
	
	# abort wait timer if running
	if { $gWait(status) == "waiting" } {
		set gWait(status) aborting
	}
	
	# update the motor control
	updateMotorControlButtons
}



proc read_ion_chambers { time args } {

	# global variables
	global gDevice
	
	# first check that each device is an ion chamber
	foreach device $args {
		if { ! [isDeviceType ion_chamber $device] } {
			log_error "Device $device is not an ion chamber!"
			return -1;
		}
	}

	# next set the status of each device to counting
	foreach device $args {
		set gDevice($device,status) counting
	}
	
	# finally send the message to the server
	dcss sendMessage "gtos_read_ion_chambers $time 0 $args"
}


proc get_ion_chamber_counts { ionChamber } {

	# global variables
	global gDevice

	return $gDevice($ionChamber,counts)
}


proc show_motor { motor } {

	# global variables
	global gDevice

	# expand motor abbreviations
	set motor [expandMotorAbbrev $motor]

	# make sure motor exists
	if { ! [info exists gDevice($motor,component)] } {
		log_error "Motor $motor does not exist."
		return -1
	}
	
	# determine what component is a part of
	set component $gDevice($motor,component)
	
	# pop the document showing the motor
	if { $component == "default" } {
		popConfigureWindow $motor
	} else {
		show_mdw_document $component
	}

	# update the motor control highlights
	update_motor_highlight
}

# shortcuts for show_motor command
proc show    { motor } { show_motor $motor }


proc select_motor { motor {window ""}} {

	# global variables
	global gDevice

	# check for motor name of "none"
	if { $motor == "none" }  {
		set gDevice(control,motor) ""
		set gDevice($motor,selectedWindow) ""
		comboBoxSetChoices units ""
		update_motor_highlight
		updateMotorControlButtons
		return
	}

	# expand motor abbreviations
	set motor [expandMotorAbbrev $motor]	

	# make sure motor exists
	if { ! [info exists gDevice($motor,component)] } {
		log_error "Motor $motor does not exist."
		return -1
	}

	# set the control motor value
	set gDevice(control,motor) $motor
	
	# default selection window is graphics document for the motor
	if { $window == "" } {
		set window $gDevice($motor,component)
	}
	
	# store name of window from which motor was selected
	set gDevice($motor,selectedWindow) $window
	
	# fill unit history list
	comboBoxSetChoices units $gDevice($motor,units)
		
	set_units $gDevice($motor,currentUnits)
	
	# update the motor name highlights
	update_motor_highlight

	# update the buttons on the control
	updateMotorControlButtons
	
}

# shortcuts for select_motor command
proc sel    { motor } { select_motor $motor }
proc select { motor } { select_motor $motor }


proc set_units { units } {

	# global variables
	global gDevice
	global gColors

	# determine currently selected motor
	set motor $gDevice(control,motor)
	
	# determine what component is a part of
	set component $gDevice($motor,component)
	
	# do nothing if no motor selected
	if { $gDevice(control,motor) == "" } { return }

	# make sure new units are appropriate for current motor
	if { [lsearch $gDevice($motor,units) $units] == -1 } {
		log_error " Motor $motor cannot be moved in $units."
		return
	}
	
	# set the control units and current units values
	set gDevice(control,units) $units
	
	set gDevice($motor,currentUnitIndex) [lsearch $gDevice($motor,units) $units]
	
	set gDevice($motor,currentUnits) $units
	
	if { $units != "steps" } {
		set gDevice($motor,currentScaledUnits) $units
		set gDevice($motor,scaled) $gDevice($motor,scaled)
	}
}


proc move { args } {

	# global variables
	global gDevice
	global gScan
	
	# get number of arguments
	set argc [llength $args]
	set arg 0

	# get motor name from fist argument
	set motor [expandMotorAbbrev [lindex $args $arg] ]

	# if no argument or first argument not a motor use current motor
	if { $arg == $argc || ! [isMotor $motor] } {

		# make sure a motor is selected
		if { $gDevice(control,motor) == "" } {
			log_error "No motor has been selected."
			return
		} else {
			set motor $gDevice(control,motor)
		}	
	} else {
		incr arg
	}
	
	# select the motor
	#select_motor $motor
	
	# make sure motor isn't locked
	if { $gDevice($motor,lockOn) } {
		log_error "Motor $motor is locked and cannot be moved."
		return
	}
	
	# make sure motor isn't being configured
	if { $gDevice($motor,configInProgress) } {
		log_error "Motor $motor cannot be moved while there are\
			unapplied changes in its configure window."
		return
	}
	
	# make sure this client is the master
	if { ! [dcss is_master] } {
		log_error "This client is passive.  Motor moves\
		are not allowed."
		return
	}

	# make sure a scan isn't in progress
	if { $gScan(status) != "inactive" } {
		log_error "A scan is in progress.  Motor moves\
		are not allowed."
		return
	}
		
	# get move preposition
	if { $arg == $argc || ! [isPrep [set prep [lindex $args $arg]]] } {
		set prep "by"
	} else {
		incr arg
	}
	
	# get move value
	if { $arg == $argc || ! [isExpr [set value [lindex $args $arg]]] } {
		set value $gDevice(control,value)
	} else {
		incr arg
	}	
	
	# get move units
	if { $arg == $argc || ! [isUnits [set units [lindex $args $arg]]] } {
		set units $gDevice(control,units)
	} else {
		incr arg
	}
	
	# handle move by angstroms
	if { $prep == "by" && $units == "A" } {
	
		set currentAngstroms [convert_scaled_units \
			$gDevice($motor,scaled) $gDevice($motor,scaledUnits) A]
		set value [expr $currentAngstroms + $value]
		set prep "to"
	}
	
	# report an error if any arguments still uninterpreted
	if { $arg != $argc } {
		log_error check args: should be \"move ?motor? ?by/to? ?value? ?units?\"
		return
	}
	
	# make sure the value is a number
	if { [catch { set value [expr ($value)]  }] } {
		log_error "A valid value was not specified."
		return -1
	}
	
	# find out what kind of unit this is (0=scaled, 1=unscaled)
	if { $units == "scaled" } {
		set unitIndex 0
		set units $gDevice($motor,scaledUnits)
	} elseif { $units == "unscaled" } {
		set unitIndex 1
		set units steps
	} else {
		set unitIndex [lsearch $gDevice($motor,units) $units] 
	}
	
	# check if motor can be moved in units of current increment
	if { $unitIndex == -1 } {
		log_error "Motor $motor cannot be moved in $units."
		return -1
	}
	
	# handle optional scaled units
	if { $units != "steps" && $unitIndex > 0 } {
		set value [convert_scaled_units $value \
			$units $gDevice($motor,scaledUnits) ]
		set unitIndex 0
	}
	
	move_no_parse $motor $prep $value $unitIndex
}

proc move_no_parse { motor prep value isUnscaledMove } {
	
	# global variables
	global gDevice
	global gScan

	# make sure motor is not already moving
	if { $gDevice($motor,status) != "inactive" } {
		log_error "Motor $motor is already moving!"
		return
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
	
	# set the undo message
	set gDevice($motor,undoCommand) \
		"move $motor to $oldPosition $gDevice($motor,scaledUnits)"
	
	log_current_position $motor
	
	# update gui
	handle_move_start $motor
		
	# request server to start the move
	dcss sendMessage "gtos_start_motor_move $motor $newPosition"	

}


proc m { args } {

	# global variables
	global gDevice
	
	# find out how many arguments were passed
	set argc [llength $args]

	# handle 1, 2, or other number of arguments
	if { $argc == 1 } {
		# only value was specified
		move $gDevice(control,motor) by [lindex $args 0] scaled
	} elseif { $argc == 2 } {
		# both motor and value were specified
		move [lindex $args 0] by [lindex $args 1] scaled
	} else {
		# report an error
		log_error wrong # args: should be \"m ?motor? value\"
	}
}


proc md { args } {

	# global variables
	global gDevice
	
	# find out how many arguments were passed
	set argc [llength $args]

	# handle 1, 2, or other number of arguments
	if { $argc == 1 } {
		# only value was specified
		move $gDevice(control,motor) to [lindex $args 0] scaled
	} elseif { $argc == 2 } {
		# both motor and value were specified
		move [lindex $args 0] to [lindex $args 1] scaled
	} else {
		# report an error
		log_error wrong # args: should be \"md ?motor? value\"
	}
}


proc mn { args } {

	# global variables
	global gDevice
	
	# find out how many arguments were passed
	set argc [llength $args]

	# handle 1, 2, or other number of arguments
	if { $argc == 1 } {
		# only value was specified
		move $gDevice(control,motor) by [lindex $args 0] unscaled
	} elseif { $argc == 2 } {
		# both motor and value were specified
		move [lindex $args 0] by [lindex $args 1] unscaled
	} else {
		# report an error
		log_error wrong # args: should be \"mn ?motor? value\"
	}
}

proc configure { args } {

	# global variables
	global gDevice
	global gConfig
	
	# find out how many arguments were passed
	set argc [llength $args]

	# bring up configure window for motor if 0 or 1 arguments
	if { $argc == 0 } {
		# configure currently selected motor
		popConfigureWindow $gDevice(control,motor)
		return
	} elseif { $argc == 1 } {
		# configure specified motor
		popConfigureWindow $args
		return
	}
	
	# if 1st argument isn't a motor name, insert default motor into list
	if { ![motor_exists [expandMotorAbbrev [lindex $args 0]]] } {
		set args [linsert $args 0 $gDevice(control,motor)]
		incr argc
	}

	# extract the motor being operated on
	set motor [expandMotorAbbrev [lindex $args 0] ]
		
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
	
	# make sure this client is the master
	if { ! [dcss is_master] } {
		log_error "This client is passive.  Configurations\
		are not allowed."
		return
	}
		
	# make sure motor isn't being configured
	if { $gDevice($motor,configInProgress) } {
		log_error "Motor $motor cannot be configured while there are\
			unapplied changes in its configure window."
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
	
	# disable the undo button
	$gDevice(control,undoButton) configure -state disabled
		
	# update server if requested
	if { $gConfig(updateServer) == 1 } {
		update_motor_config_to_server $motor
	}
}


# shortcuts for configure command
proc c      { args } { eval "configure $args" }
proc config { args } { eval "configure $args" }




proc log_current_position { motor } {

	# global variables
	global gScan
	global gDevice

	# report current position of motor
	if { $gScan(status) == "inactive" } {
		log_note "Motor $motor is currently at $gDevice($motor,scaled) $gDevice($motor,scaledUnits)."
	}
}


proc move_vector_no_parse { motor_1 motor_2 newPosition_1 newPosition_2 vectorSpeed } {
	
	# global variables
	global gDevice
	global gScan

	# make sure this client is the master
	if { ! [dcss is_master] } {
		log_error "This client is passive.  Motor moves\
		are not allowed."
		return
	}

	if { $motor_1 != "NULL" } {
		# make sure motor is not locked
		if { $gDevice($motor_1,lockOn) } {
			log_error "Motor $motor_1 is locked and cannot be moved."
			return
		}

		# make sure motor is not being configured
		if { $gDevice($motor_1,configInProgress) } {
			log_error "Motor $motor_1 cannot be moved while there are\
			unapplied changes in its configure window."
			return
		}	

		# make sure motor is not already moving
		if { $gDevice($motor_1,status) != "inactive" } {
			log_error "Motor $motor_1 is already moving!"
			return
		}
		log_current_position $motor_1
		# update gui
		handle_move_start $motor_1
	}

	if { $motor_2 != "NULL" } {
		# make sure motor is not locked
		if { $gDevice($motor_2,lockOn) } {
			log_error "Motor $motor_2 is locked and cannot be moved."
			return
		}

		# make sure motor is not being configured
		if { $gDevice($motor_2,configInProgress) } {
			log_error "Motor $motor_2 cannot be moved while there are\
			unapplied changes in its configure window."
			return
		}	
		
	   # make sure motor is not already moving
	   if { $gDevice($motor_2,status) != "inactive" } {
		   log_error "Motor $motor_2 is already moving!"
		   return
		}

	   log_current_position $motor_2
		# update gui
	   handle_move_start $motor_2
	}

	# request server to start the move
	dcss sendMessage "gtos_start_vector_move $motor_1 $motor_2 $newPosition_1 $newPosition_2 $vectorSpeed"	
}

proc vector_stop_move { motor_1 motor_2 } {
	# make sure this client is the master
	if { ! [dcss is_master] } {
		return
	}
	dcss sendMessage "gtos_stop_vector_move $motor_1 $motor_2"
	}


proc vector_change_speed { motor_1 motor_2 speed} {
	
	# make sure this client is the master
	if { ! [dcss is_master] } {
		return
	}
	
	dcss sendMessage "gtos_change_vector_speed $motor_1 $motor_2 $speed"
}

proc requestLastImage { } {
	global requestedImage
	
	set requestedImage 1
	start_operation requestCollectedImage
}


proc start_operation { operation args } {

	set operationHandle [create_operation_handle]

	dcss sendMessage "gtos_start_operation $operation $operationHandle $args"

}


proc start_waitable_operation { operation args } {
	global gOperation

	set operationHandle [create_operation_handle]

	#set the operation status
	set gOperation($operationHandle,status) active
	set gOperation($operationHandle,result) ""
	
	dcss sendMessage "gtos_start_operation $operation $operationHandle $args"
	
	#return the unique handle to wait for.
	return $operationHandle
}

proc start_waitable_operation { operation args } {
	global gOperation

	set operationHandle [create_operation_handle]

	set gOperation($operationHandle,status) active
	set gOperation($operationHandle,result) ""

	#create the update fifo indices
	set gOperation($operationHandle,updateInIndex) 0
	set gOperation($operationHandle,updateOutIndex) 0

	dcss sendMessage "gtos_start_operation $operation $operationHandle $args"

	return $operationHandle
}

proc get_encoder {encoder} {
	global gDevice

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