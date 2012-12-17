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


proc setScaledValue { motor value } {

	# global variables
	global gDevice

	set gDevice($motor,scaled) $value

	if { $gDevice($motor,type) == "real_motor" } {
		set gDevice($motor,unscaled) \
			[expr ($gDevice($motor,scaled) * $gDevice($motor,scaleFactor) ) ]
	}
}


proc setUnscaledValue { motor value } {

	# global variables
	global gDevice

	set gDevice($motor,unscaled) $value
	
	set gDevice($motor,scaled) 											\
		[expr ($gDevice($motor,unscaled) / $gDevice($motor,scaleFactor) ) ]
}


proc configUnitedParameter { motor parameter value units } {

	# global variables
	global gDevice

	set displayValue $value
	if {$units != "steps"} {
        set value \
        [::units convertUnits $value $units $gDevice($motor,scaledUnits)]
	}
		
	# handle each possible parameter		
	switch $parameter {
		
		position {	
			if {$units != "steps"} {
				setScaledValue $motor $value
			} else {
				setUnscaledValue $motor $value
			}
			log "Position of motor $motor set to $displayValue $units."
		}
		
		backlash {
			if {$units != "steps"} {
				setBacklashFromScaledValue $motor $value
			} else {
				setBacklashFromUnscaledValue $motor $value
			}
			log "Backlash for motor $motor set to $displayValue $units."
		}		
	
		lower_limit {
			if {$units != "steps"} {
				setLowerLimitFromScaledValue $motor $value
			} else {
				setLowerLimitFromUnscaledValue $motor $value
			}
			log "Lower limit for motor $motor set to $displayValue $units."
		}
		
		upper_limit {
			if {$units != "steps"} {
				setUpperLimitFromScaledValue $motor $value			
			} else {
				setUpperLimitFromUnscaledValue $motor $value 
			}
			log "Upper limit for motor $motor set to $displayValue $units."
		}	
	}
}


proc configUnitlessParameter { motor parameter value } {

	# global variables
	global gDevice
			
	# handle each possible parameter		
	switch $parameter {
		
		speed {
			if { $value >= 0 } {
				setSpeedValue $motor $value
				log "Speed for motor $motor set to $gDevice($motor,speed) steps/sec."
			} else {
				log_error "Motor speed must be greater or equal to 0 step/sec."
			}

		}
		
		acceleration {
			if { $value >= 1 } {		
				setAccelerationValue $motor $value
				log "Acceleration for motor $motor set to \
					$gDevice($motor,acceleration) steps/sec**2."
			} else {
				log_error "Motor acceleration must be greater or \
					equal to 1 step/sec**2."
			}
		}

		scale {
			if { $value >= 1 } {
				setScaleFactorValue $motor $value
				log "Scale factor for motor $motor set to \
					$gDevice($motor,scaleFactor) steps/$gDevice($motor,scaledUnits)."
			} else {
				log_error "Scale factor must be greater or equal to 1 \
					steps/$gDevice($motor,scaledUnits)."
			}
		}
		
		lock_enable {
			setLockEnableValue $motor $value
			if { $value } {
				log "Motor $motor locked."
			} else {
				log "Motor $motor unlocked."
			}
		}

		lower_limit_enable {
			setLowerLimitEnableValue $motor $value 
			if { $value } {
				log "Lower limit for motor $motor enabled."
			} else {
				log "Lower limit for motor $motor disabled."
			}
		}
		 
		upper_limit_enable {
			setUpperLimitEnableValue $motor $value
			if { $value } {
				log "Upper limit for motor $motor enabled."
			} else {
				log "Upper limit for motor $motor disabled."
			}
		}

		reverse_enable {
			setReverseEnableValue $motor $value
			if { $value } {
				log "Direction of motor $motor is reverse."
			} else {
				log "Direction of motor $motor is forward."
			}
		}
		
		backlash_enable {
			setBacklashEnableValue $motor $value
			if { $value } {
				log "Anti-backlash correction for motor $motor enabled."
			} else {
				log "Anti-backlash correction for motor $motor disabled."
			}
		}
	}
}


proc setUpperLimitFromScaledValue { motor value } {

	# global variables
	global gDevice

	set gDevice($motor,scaledUpperLimit) $value
	
	if { $gDevice($motor,type) == "real_motor" } {	
		set unscaled [expr $value * $gDevice($motor,scaleFactor) ]
	}
}


proc setUpperLimitFromUnscaledValue { motor value } {

	# global variables
	global gDevice

	set scaled [expr $value / $gDevice($motor,scaleFactor) ]
	set gDevice($motor,scaledUpperLimit) $scaled
}


proc setLowerLimitFromScaledValue { motor value } {

	# global variables
	global gDevice
				
	set gDevice($motor,scaledLowerLimit) $value
	
	if { $gDevice($motor,type) == "real_motor" } {
		set unscaled [expr $value * $gDevice($motor,scaleFactor) ]
	}
}


proc setLowerLimitFromUnscaledValue { motor value } {

	# global variables
	global gDevice
				
	set scaled [expr $value / $gDevice($motor,scaleFactor) ]
	set gDevice($motor,scaledLowerLimit) $scaled
}


proc setBacklashFromScaledValue { motor value } {

	# global variables
	global gDevice

	set gDevice($motor,scaledBacklash) $value
	set unscaled [expr $value * $gDevice($motor,scaleFactor) ]				
}


proc setBacklashFromUnscaledValue { motor value } {

	# global variables
	global gDevice

	set scaled [expr $value / $gDevice($motor,scaleFactor) ]
	set gDevice($motor,scaledBacklash) $scaled		
}


proc setSpeedValue { motor value } {

	# global variables
	global gDevice
	
	set gDevice($motor,speed) [expr round($value)]		
}


proc setAccelerationValue { motor value } {

	# global variables
	global gDevice
	
	set gDevice($motor,acceleration) [expr round($value)]
}


proc setScaleFactorValue { motor value } {

	# global variables
	global gDevice
	
	set gDevice($motor,scaleFactor) $value
}


proc setLockEnableValue { motor value } {

	# global variables
	global gDevice
	
	set gDevice($motor,lockOn) $value
}

proc setLowerLimitEnableValue { motor value } {

	# global variables
	global gDevice
	
	set gDevice($motor,lowerLimitOn) $value
}

proc setUpperLimitEnableValue { motor value } {

	# global variables
	global gDevice
	
	set gDevice($motor,upperLimitOn) $value
}

proc setReverseEnableValue { motor value } {

	# global variables
	global gDevice
	
	set gDevice($motor,reverseOn) $value
}

proc setBacklashEnableValue { motor value } {

	# global variables
	global gDevice
	
	set gDevice($motor,backlashOn) $value
}


proc setSubcomponentList { motor value } {

	# global variables
	global gDevice
	
	set gDevice($motor,subcomponentList) $value
}



proc getScaleFactorValue { motor } {
	global gDevice
	
	return $gDevice($motor,scaleFactor)
}


proc getScaledValue { motor } {
	global gDevice

	return $gDevice($motor,scaled)
}


proc getUpperLimitScaledValue { motor } {
	global gDevice

	return $gDevice($motor,scaledUpperLimit)
}


proc getLowerLimitScaledValue { motor } {
	global gDevice
				
	return $gDevice($motor,scaledLowerLimit)
}

proc getSpeedValue { motor } {
	global gDevice
	
	return $gDevice($motor,speed)		
}

proc getAccelerationValue { motor } {
	global gDevice
	
	return $gDevice($motor,acceleration)
}

proc getBacklashScaledValue { motor } {
	global gDevice

	return $gDevice($motor,scaledBacklash) 	
}

proc getLowerLimitEnableValue { motor } {
	global gDevice
	
	return $gDevice($motor,lowerLimitOn)
}

proc getUpperLimitEnableValue { motor } {
	global gDevice
	
	return $gDevice($motor,upperLimitOn)
}

proc getLockEnableValue { motor } {
	global gDevice
	
	return $gDevice($motor,lockOn)
}

proc getBacklashEnableValue { motor } {
	global gDevice
	
	return $gDevice($motor,backlashOn)
}

proc getReverseEnableValue { motor } {
	global gDevice
	
	return $gDevice($motor,reverseOn)
}


