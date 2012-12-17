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


create_new_set gDevice(moving_motor_list)
create_new_set gDevice(registered_motor_list)
create_new_set gDevice(activeScriptedDevices)
create_new_set gDevice(encoderList)
create_new_set gDevice(ionChamberList)
set gDevice(all_motors_blocked) unblocked

namespace eval nScripts {
	proc rad { deg } { expr $deg / 57.2975 }
	proc deg { rad } { expr $rad * 57.2975 }
}

proc create_shutter { shutter } {
	#global variables
	global gDevice

	if { ! [info exists gDevice($shutter,observers) ] } {
		set gDevice($shutter,observers) ""
		trace variable nScripts::$shutter r trace_shutter_shortcut_read
	}
	
	set gDevice($shutter,type) shutter
	set gDevice($shutter,status) inactive
	set gDevice($shutter,lastResult) normal
}


proc getMotorBaseUnits { motor } {
    global gDevice
    if {![info exist gDevice($motor,scaledUnits)]} {
        return ""
    } else {
        return $gDevice($motor,scaledUnits)
    }
}

proc create_real_motor { motor component units } {

	# global variables
	global gDevice
		
	# initialize generic motor parameters
	create_generic_motor $motor $component $units

	set gDevice($motor,type)					real_motor
    if {![info exist gDevice($motor,scaledUnits)]} {
	    set gDevice($motor,scaledUnits)			$units
    }
	set gDevice($motor,unscaledUnits)		steps
	set gDevice($motor,unscaled)				0
	set gDevice($motor,scaleFactor)			1.0	
	set gDevice($motor,speed)					0
	set gDevice($motor,acceleration)			0
	set gDevice($motor,scaledBacklash)		0
	set gDevice($motor,reverseOn)				0

 	#trace unscaled position
	trace variable gDevice($motor,unscaled) w \
		"traceMotorUnscaled $motor"

	# trace scaled position
	trace variable gDevice($motor,scaled) w \
		"traceMotorScaled $motor"
	print "created $motor"
}


proc create_pseudo_motor { motor component units } {

	# global variables
	global gDevice

	# initialize generic motor parameters
	create_generic_motor $motor $component $units
	
	set gDevice($motor,type)					pseudo_motor
    if {![info exist gDevice($motor,scaledUnits)]} {
	    set gDevice($motor,scaledUnits)			$units
    }
	set gDevice($motor,configured)			0

	# trace scaled position
	trace variable gDevice($motor,scaled) w \
		"traceMotorScaled $motor"
}



proc create_generic_motor { motor component units } {

	# global variables
	global gDevice
		
	set gDevice($motor,component) 			$component
	set gDevice($motor,scaled)					0
	set gDevice($motor,scaledLowerLimit) 	-100
	set gDevice($motor,scaledUpperLimit)	100
	set gDevice($motor,lockOn)					0
	set gDevice($motor,backlashOn)			0
	set gDevice($motor,lowerLimitOn)			1
	set gDevice($motor,upperLimitOn)			1
	set gDevice($motor,status)					inactive
	set gDevice($motor,undoCommand)			""
	set gDevice($motor,errorCode)				none
	set gDevice($motor,scripted)				0
	set gDevice($motor,children)				""
	set gDevice($motor,siblings)				""
	set gDevice($motor,maxTargetError)		0.001
	set gDevice($motor,lastResult)			"normal"
	set gDevice($motor,configInProgress)	0

	if { ! [info exists gDevice($motor,parents) ] } {
		set gDevice($motor,parents) ""
	}
	
	if { ! [info exists gDevice($motor,observers) ] } {
		set gDevice($motor,observers) ""
	}

	lappend gDevice(motor_list) $motor

	# trace shortcut name
	namespace eval nScripts "variable $motor;set $motor 0"
	trace variable nScripts::$motor r trace_motor_shortcut_read
	trace variable nScripts::$motor w trace_motor_shortcut_write
}


proc trace_motor_shortcut_read { motor element op } {

	# global variables
	global gDevice

	# copy scaled position into shortcut variable
	set nScripts::$motor $gDevice($motor,scaled)
}


proc trace_motor_shortcut_write { motor element op } {

	# global variables
	global gDevice

	if { $gDevice($motor,configInProgress) } {
		set gDevice($motor,scaled) [set nScripts::$motor]
	} else {
		configure $motor position [set nScripts::$motor] $gDevice($motor,scaledUnits)
	}
}


proc trace_shutter_shortcut_read { shutter element op } {
	
	# global variables
	global gDevice
	
	# copy scaled position into shortcut variable
	set nScripts::$shutter $gDevice($shutter,state)
}



proc create_string { stringName } {
	
	# global variables
	global gDevice
	set gDevice($stringName,type) string
	set gDevice($stringName,status) inactive
	set gDevice($stringName,lastResult) "normal"
	set gDevice($stringName,configInProgress) 0	

	lappend gDevice(string_list) $stringName

	# trace shortcut name
	namespace eval nScripts "variable $stringName;set $stringName NULL"
	trace variable nScripts::$stringName r trace_string_shortcut_read
	trace variable nScripts::$stringName w trace_string_shortcut_write

	if { ! [info exists gDevice($stringName,observers) ] } {
		set gDevice($stringName,observers) ""
	}
}


proc trace_string_shortcut_read { stringName element op } {

	# global variables
	global gDevice

	# copy scaled position into shortcut variable
	set nScripts::$stringName $gDevice($stringName,contents)
}


proc trace_string_shortcut_write { stringName element op } {

	# global variables
	global gDevice
	
	if { $gDevice($stringName,configInProgress) } {
		#the string is being configured by an external source.
		set gDevice($stringName,contents) [set nScripts::$stringName]
	} else {
		if { $gDevice($stringName,scripted) } {
			#This string is owned by the scripting engine. Therefore we run the string's personal configure script.
			if { [catch {set result [namespace eval nScripts ${stringName}_configure [set nScripts::$stringName] ]} errorResult] } {
				return -code error $errorResult
			} else {
				#the function returned the new string successfully
				set gDevice($stringName,contents) $result
				::dcss2 sendMessage "htos_set_string_completed $stringName normal $gDevice($stringName,contents)"
			}
		} else {
            set gDevice($stringName,status) waiting_for_change

			#The string is not owned by DCSS, so we send out a configuration message as a GUI client.
			#WARNING: Technically we should wait for the stog_set_string_completed message, before allowing the
			#string contents to change in the scripting engine's memory.
			#::dcss sendMessage "gtos_set_string $stringName $gDevice($stringName,contents)"
            upvar $stringName nnnn
            #puts "string name: $stringName"
			::dcss sendMessage "gtos_set_string $stringName $nnnn"
		}
	}
}



proc motor_exists { motor } {

	# global variables
	global gDevice

	if { [lsearch $gDevice(motor_list) $motor] == -1 } {
		return 0
	} else {
		return 1
	}
}


proc reset_all {} {

	# global variables
	global gDevice
 
 	# loop over all motors
 	foreach motor $gDevice(motor_list) {
		if { $gDevice($motor,status) != "inactive" } {
			reset_motor $motor
		}
	}
}


proc reset_motor { motor } {

	# global variables
	global gDevice

	if { $motor == "all" } {
		reset_all
		return 
	}
	
	# make sure motor exists
	if { ! [isMotor $motor] } {
		log_error "No such motor $motor."
		return
		}
	
	if { $gDevice($motor,status) == "inactive" } {
		log_error "Motor $motor is inactive."
		return
		}

	handle_move_complete	$motor
	log_note "The status of motor $motor has been reset."
}



proc handle_move_complete { motor } {
	
	# global variables
	global gDevice
	
	print "Handling move complete for $motor..."

	# update status of motor
	set gDevice($motor,status) inactive
	remove_from_set gDevice(moving_motor_list) $motor

	#inform all interested devices that the motor has stopped moving
    updateEventListeners $motor
	update_observers $motor
}


proc handle_move_start { motor {startedByPoll 0} } {
	
	# global variables
	global gDevice

	#get the hardware host for this motor
	set hardwareHost  $gDevice($motor,hardwareHost) 
	#put the set of devices controlled by this hardware host in the global namespace
	print "Handling move start for $motor..."

	# update status of motor
	set gDevice($motor,status) moving
	set gDevice($motor,lastResult) normal
	set gDevice($motor,startedByPoll) $startedByPoll
	set gDevice($motor,timedOut) 0
	add_to_set gDevice(moving_motor_list) $motor

	#inform all interested devices that the motor has started moving
    updateEventListeners $motor
	update_observers $motor
}


proc update_polled_motors {} {

	# global variables
	global gDevice
	
	# check each moving motor
	foreach motor $gDevice(moving_motor_list) {
		
		# move is complete if no updates in last 1 second
		if { $gDevice($motor,timedOut) } {
			handle_move_complete $motor
			continue
		} else {
			# reset the timeout
			set gDevice($motor,timedOut) 1
		}
	}
}



proc traceMotorScaled { motor args } {

	# global variables
	global gDevice
	global gConfig
	
	set formatted [format "%.3f" $gDevice($motor,scaled)]
	set gConfig($motor,scaled) $formatted
}


proc traceMotorUnscaled { motor args } {

	# global variables
	global gDevice
	global gConfig
	
	set formatted  [expr round($gDevice($motor,unscaled)) ]
	set gConfig($motor,unscaled) $formatted
}


proc clearTraces { variableName } {

	# access global variable
	upvar #0 $variableName variable

	foreach trace [trace vinfo variable] {
		trace vdelete variable [lindex $trace 0] [lindex $trace 1]
	}
}

set gDevice(polling) 0

proc start_polling { motorList } {

	# global variables
	global gDevice

	foreach motor $motorList {
		if { [motor_exists $motor] } {
			if { ![is_in_set gDevice(activeScriptedDevices) $motor] } {
				add_to_set gDevice(activeScriptedDevices) $motor
				start_polling $gDevice($motor,parents)
			}
		}
	}

	if { ! $gDevice(polling) } {
		set gDevice(polling) 1
		after 10 perform_polling
	}
}


proc perform_polling {} {
	
	# global variables
	global gDevice

	if { $gDevice(activeScriptedDevices) != "" } {

		foreach motor $gDevice(activeScriptedDevices) {
			set lastValue $gDevice($motor,scaled)
			set newValue  [nScripts::${motor}_update]
			if { $lastValue != $newValue} {
				#puts "LastValue: $lastValue != $gDevice($motor,scaled)" 
                update_motor_position $motor $newValue
			}
			# make sure motor is within it's limits
			if { ! [limits_ok $motor $gDevice($motor,scaled)] } {
				abort soft
				print "****** Motor $motor is outside limits! *******"
				dcss2 sendMessage "htos_motor_move_completed $motor $gDevice($motor,scaled) sw_limit"
			}
		}
		
		set gDevice(activeScriptedDevices) ""
		after 100 perform_polling
	} else {
		set gDevice(polling) 0
	}
}


proc update_motor_position { motor position {updateTarget 0} } {
	global gDevice

    if {$updateTarget} {
        set gDevice($motor,target) $position
    }

	set gDevice($motor,scaled) $position
	dcss2 sendMessage "htos_update_motor_position $motor $gDevice($motor,scaled) normal"
    updateEventListeners $motor
	update_observers $motor
}

####################################
# October 6th, 2010
# roll back to old code so that software limits also limits backlash move.

proc getGoodLimits { motor } {
	global gDevice
	
	# correct limits for backlash correction
	if {$gDevice($motor,type) == "real_motor" && $gDevice($motor,backlashOn)} {
		if {$gDevice($motor,scaledBacklash) < 0} {
			set lowerLimit $gDevice($motor,scaledLowerLimit)
			set upperLimit [expr $gDevice($motor,scaledUpperLimit) + \
			$gDevice($motor,scaledBacklash) ]
		} else {
			set upperLimit $gDevice($motor,scaledUpperLimit)
			set lowerLimit [expr $gDevice($motor,scaledLowerLimit) + \
			$gDevice($motor,scaledBacklash)]
		}
	} else {
		set upperLimit $gDevice($motor,scaledUpperLimit)
		set lowerLimit $gDevice($motor,scaledLowerLimit)
	}
    return [list $lowerLimit $upperLimit]
}

###will return limits if current is out of limits
###and limits on
proc getMotorGoodPosition { motor } {
    global gDevice

    set position $gDevice($motor,scaled)

    ###do not care ajust or not
    adjustPositionToLimit $motor position

    return $position
}

proc adjustPositionToLimit { motor posREF {even_limits_off 0}} {
    global gDevice
    upvar $posREF position

    set anyChange 0

    if {!$gDevice($motor,lowerLimitOn) && !$gDevice($motor,upperLimitOn) \
    && !$even_limits_off} {
        return 0
    }

    ###check limits now
    foreach {lowerLimit upperLimit} [getGoodLimits $motor] break;

    if { $position < $lowerLimit \
    && ($gDevice($motor,lowerLimitOn) || $even_limits_off) } {
        set position $lowerLimit
        log_warning $motor exceeds lower limit, using $position
        set anyChange 1
    }

    if { $position > $upperLimit \
    && ($gDevice($motor,upperLimitOn) || $even_limits_off) } {
        set position $upperLimit
        log_warning $motor exceeds upper limit, using $position
        set anyChange 1
    }

    return $anyChange
}
proc limits_ok { motor position } {
	
	# global variables
	global gDevice
	
	# correct limits for backlash correction
    foreach {lowerLimit upperLimit} [getGoodLimits $motor] break;
    puts "+limit including backlash for $motor : $upperLimit"
    puts "-limit including backlash for $motor : $lowerLimit"

	# return true if position is outside corrected limits
	if { $position < $lowerLimit && $gDevice($motor,lowerLimitOn) } {
      puts "lower limit check failed"
      log_warning "$motor would exceed lower limit of $lowerLimit if moved to $position."
      return 0      
   }

   if { $position > $upperLimit && $gDevice($motor,upperLimitOn) } {
      log_warning "$motor would exceed upper limit of $upperLimit if moved to $position."
      puts "upper limit check failed"
      return 0
   }

    puts "upper and lower limits ok"

   return 1
}

proc limits_ok_quiet { motor position } {
	global gDevice
    foreach {lowerLimit upperLimit} [getGoodLimits $motor] break;
	if { $position < $lowerLimit && $gDevice($motor,lowerLimitOn) } {
      return 0      
    }

    if { $position > $upperLimit && $gDevice($motor,upperLimitOn) } {
        return 0
    }
    return 1
}

proc parent_limits_ok { motor position } {
	# global variables
	global gDevice

	# check each parent's limits
	foreach parent $gDevice($motor,parents) {
        print "$motor's parents: $parent"
        if {!$gDevice($parent,lowerLimitOn) && \
        !$gDevice($parent,upperLimitOn)} {
            print "skip both limits disabled"
            continue
        }

		# check if current position is within limits
		if { ![limits_ok $parent $gDevice($parent,scaled)] } {
         log_error "$parent is not within software limits."
			return 0
		}
		
		# check if new position is within limits
		set calculate_command nScripts::${parent}_calculate
		foreach child $gDevice($parent,children) {
            print "$motor's parents's: child: $child"
			if { $child == $motor } {
				lappend calculate_command $position
			} else {
				lappend calculate_command $gDevice($child,scaled)
			}
		}
		#set parentPosition [ eval $calculate_command ]
        if {[catch {eval $calculate_command} parentPosition]} {
            log_error Parent motor $parent limits failed
            log_error ${parent}_calculate returned error: $parentPosition
            log_error Mostlikely, children motor list does not match arguments for ${parent}_calculate
            log_error You can disable the limits for ${parent} as a workaround
            log_error But please report this to software group
            return 0
        }
		if { ![limits_ok $parent $parentPosition] || ![parent_limits_ok $parent $parentPosition] } {
         log_error "$parent would exceed software limit if moved to $parentPosition."
			return 0
		}
	}
	
	# return true
	return 1
}

###Thee is no pattern to calculate children motor position from parent position.
# For example, in energy, most of them are calcualted from mono_theta, not from
# energy.
# So, we will not do recursive.
proc children_limits_ok { motor position {quiet 0}} {
    if {[info commands ::nScripts::${motor}_childrenLimitsOK] != ""} {
        puts "checking children limits"
        if {![::nScripts::${motor}_childrenLimitsOK $position $quiet]} {
            if {!$quiet} {
                log_warning "$motor children limits check failed"
            }
            return 0
        }
    }
    return 1
}

proc parents_unlocked { motor } {

	# global variables
	global gDevice
	
	foreach parent $gDevice($motor,parents) {
		if { $gDevice($parent,lockOn) } {
            log_error "$parent is locked"
        }
		if { $gDevice($parent,lockOn) || ![parents_unlocked $parent] } {
			return 0
		}
	}
	
	# return true
	return 1
}

proc parents_inConfig { motor } {
	# global variables
	global gDevice
	
	foreach parent $gDevice($motor,parents) {
		if { $gDevice($parent,configInProgress) } {
            log_error $parent still in config
        }
		if {$gDevice($parent,configInProgress) || [parents_inConfig $parent]} {
			return 1
		}
	}
	return 0
}



proc siblings_not_moving { motor } {

	# global variables
	global gDevice
	
	foreach sibling $gDevice($motor,siblings) {
		if { [is_in_set gDevice(moving_motor_list) $sibling] } {
			return 0
		}
	}
	
	# return true
	return 1
}


proc update_parents { child updateTarget } {
	
	# global variables
	global gDevice

	foreach motor $gDevice($child,parents) {

		if { [motor_exists $motor] } {

			# update the motor position
			set p [nScripts::${motor}_update]
            update_motor_position $motor $p $updateTarget
		}
	}

	foreach motor $gDevice($child,parents) {
		if { [motor_exists $motor] } {
			# poll the parents of this motors too
			update_parents $motor $updateTarget
		}
	}

}


# This function loops over a device's list of observers
# and calls the predefined _trigger function for each device in the list.
# The _trigger function is passed the name of the device that triggered the
# call.
proc update_observers { triggerDevice } {
	
	# global variables
	global gDevice
	
	#return immediately if this device does not have observers
	if { $gDevice($triggerDevice,observers) == "" } {
		return
	}

	# Loop over the list of observer devices and inform 
	# them of the device's activity.
	foreach device $gDevice($triggerDevice,observers) {
		if { [motor_exists $device] } { 
			# Do not inform an  observing device until the observer has
			# been configured.
			if {  $gDevice($device,configured) } {
				# Call the devices trigger function with the
				# name of the device that triggered the call.
                if {[catch {
				    nScripts::${device}_trigger $triggerDevice
                } errMsg]} {
                    log_error $errMsg
                }
			}
		}
        if {[isEncoder $device] || [isString $device]} {
            if {[catch {
	            nScripts::${device}_trigger $triggerDevice
            } errMsg]} {
                log_error $errMsg
            }
        }
	}
}


proc parents_not_moving { motor } {

	# global variables
	global gDevice

	foreach parent $gDevice($motor,parents) {

		if { [is_in_set gDevice(moving_motor_list) $parent] } {
			return 0
		}

#		if { ! [parents_not_moving $parent] } {
#			return 0
#		}
	}
	
	# return true
	return 1
}
