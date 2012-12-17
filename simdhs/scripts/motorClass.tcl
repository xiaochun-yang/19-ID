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

package require DCSSet
DCS::Set registered_motor_list

class simulatedMotor {
	public variable name

	public variable upperLimit
	public variable lowerLimit
	

	public variable scaledLowerLimit -100
	public variable scaledUpperLimit 100
	public variable lockOn			    	0
	public variable backlashOn			0
	public variable lowerLimitOn		   1
	public variable upperLimitOn	   	1
	public variable scaleFactor			"undefined"	
	public variable speed					0
	public variable acceleration			0
	private variable scaledBacklash 		0
	public variable reverseOn

	private variable isMoving
	private variable status			   	inactive
	private variable movePath

	private variable configured			0

	private variable errorCode			   none
	private variable lastResult			"normal"

	private variable unscaledUnits		"steps"
	#private variable scaledUnits			"mm"

	private variable unscaled				0
	public variable unscaledBacklash
	public variable scaled				   0

	#variables associated with a moving motor
	private variable totalStepsInMove
	private variable movedSteps  0
	private variable aborting

	public method move
	public method oscillation { shutter delta exposuretime }
	public method setUnscaledPosition { newPosition }
	#public method setScaledPosition { newPosition }
	public method limitsOk { targetPosition }
	public method abort {}
	public method moveIncrement {}
	private method scaled2Unscaled { unscaledValue  }

	public method constructor { args }
	
}

configbody simulatedMotor::scaled {
	set unscaled [expr round($scaled * $scaleFactor) ]
}

configbody simulatedMotor::name {}
configbody simulatedMotor::scaledLowerLimit {}
configbody simulatedMotor::scaledUpperLimit {}
configbody simulatedMotor::lockOn {}
configbody simulatedMotor::backlashOn {}
configbody simulatedMotor::lowerLimitOn {}
configbody simulatedMotor::upperLimitOn {}
configbody simulatedMotor::scaleFactor {}
configbody simulatedMotor::speed {}
configbody simulatedMotor::acceleration {
#acceleration not used in simulation
}
configbody simulatedMotor::reverseOn {
#reverseOn not used in simulation
}
configbody simulatedMotor::unscaledBacklash {
	puts "scaledBacklash $scaledBacklash"
	set scaledBacklash [expr round($scaledBacklash / $scaleFactor) ]
}
configbody simulatedMotor::upperLimit {}
configbody simulatedMotor::lowerLimit {}
#configbody simulatedMotor::isMoving {}



body simulatedMotor::constructor { args } {
	eval $this configure [concat $args]
}

body simulatedMotor::limitsOk { targetPosition } {
	
	# correct limits for backlash correction
	if {  $backlashOn } {
		if { $scaledBacklash < 0 } {
			set lowerLimit $scaledLowerLimit
			set upperLimit [expr $scaledUpperLimit + $scaledBacklash ]
		} else {
			set upperLimit $scaledUpperLimit
			set lowerLimit [expr $scaledLowerLimit + $scaledBacklash]
		}
	} else {
		set upperLimit $scaledUpperLimit
		set lowerLimit $scaledLowerLimit
	}
	
	# return true if position is outside corrected limits
	return [expr !( ( $targetPosition < $lowerLimit && $lowerLimitOn) || \
							  ( $targetPosition > $upperLimit && $upperLimitOn ) ) ]
}


body simulatedMotor::setUnscaledPosition { newPosition } {
	set unscaled $newPosition
	puts "new position $unscaled"
	set scaled [expr $newPosition / $scaleFactor]
	puts "new position $scaled"

	
	puts "Encoder${name}_encoder"
	if {[info command Encoder${name}_encoder] !="" } {
		puts "**************************** ENCODER"
		Encoder${name}_encoder moveWithError $scaled
	}
}

body simulatedMotor::move { targetPosition } {
	#puts "currentPosition: $scaled, targetPosition: $targetPosition"
	
	# check limits on motor..
	#if { ![limitsOk $targetPosition] } {
	#	dcss sendMessage "htos_motor_move_completed $name $scaled sw_limit"
	#}

	# make sure device is inactive
	if { $status != "inactive" } {
		#dcss sendMessage "htos_motor_move_completed $name $scaled moving"
		return
	}
	
	# make sure motor is not locked
	if { $lockOn } {
		dcss sendMessage "htos_motor_move_completed $name $scaled locked"
		return
	}
	
	#inform dcss that the motor move has started.
	dcss sendMessage "htos_motor_move_started $name $targetPosition"
	
	set unscaledTargetPosition [scaled2Unscaled $targetPosition]

	#calculate how far we need to move
	set delta [expr $unscaledTargetPosition - $unscaled] 

	#check to see that the move is necessary
	if { $delta == 0  } {
		puts "Zero delta! Completing move."
		dcss sendMessage "htos_motor_move_completed $name $scaled normal"
	    return
	}

	#get the direction of the move.
	if { $delta < 0 } {
		set direction -1 
	} else {
		set direction 1
	}

	set doBacklash 0
	#check for 0 backlash before we divide by zero
	if { $backlashOn && ($unscaledBacklash != 0) } {
		if  { ($direction / $unscaledBacklash) < 0 } {
			set doBacklash 1
		}
	}
	
	if { $doBacklash } {
		
		#I want to be able to move the motor only by steps that are integers values.
		#this will help simulate problems with stepper motor round off.  The drawback
		#is that the actual time for completing a move will have a little error in it.
		set stepsPerIncrement [ expr int ( ($speed + 0.999) ) /10 ];
		puts "stepsPerIncrement: $stepsPerIncrement"
		
		
		puts "UnscaledBacklash $unscaledBacklash"
		set totalSteps [ expr int (abs ($unscaledTargetPosition -$unscaledBacklash - $unscaled)) / $stepsPerIncrement ]
		puts "totalSteps: $totalSteps"
		
		set i 0
		if { $totalSteps > 0} {

			#set up array of position for 1st segment of move
			set virtualPosition $unscaled
			for {} { $i < $totalSteps } { incr i } {		
				set virtualPosition [ expr $virtualPosition + $stepsPerIncrement * $direction]
				set movePath($i) $virtualPosition
				puts "movePath($i): $movePath($i)"
			}
		} else {
			set movePath($i) $unscaled
			set totalSteps 1
			incr i
		}
		
		set virtualPosition [expr $unscaledTargetPosition - $unscaledBacklash ]
		set movePath($i) $virtualPosition
		
		set totalBacklashSteps [ expr int (abs ($unscaledBacklash) / $stepsPerIncrement) ]
		if { $totalBacklashSteps > 0 } {
			for {set x 0} { $x < $totalBacklashSteps } { incr x; incr i } {		
				set virtualPosition [ expr $virtualPosition + $stepsPerIncrement * -1 * $direction]
				set movePath($i) $virtualPosition
				puts "backlash movePath($i): $movePath($i)"
			}
		} else {
			set movePath($i) $virtualPosition
			set totalBacklashSteps 1
			incr i
		}
		
		set virtualPosition [expr $unscaledTargetPosition ]
		set movePath($i) $virtualPosition

		
		puts "backlash movePath($i): $movePath($i)"
		set totalStepsInMove [expr $totalSteps + $totalBacklashSteps]

		puts "Total Steps in move $totalStepsInMove"
	} else {
		#this is the non backlash code
		#I want to be able to move the motor only by steps that are integers values.
		#this will help simulate problems with stepper motor round off.  The drawback
		#is that the actual time for completing a move will have a little error in it.
		set stepsPerIncrement [ expr int ( ($speed + 0.999) ) /10 ];
		puts "stepsPerIncrement: $stepsPerIncrement"

		set totalSteps [ expr int (abs ($unscaledTargetPosition - $unscaled)) / $stepsPerIncrement ]
		puts "totalSteps: $totalSteps"

		set i 0
		if { $totalSteps > 0} {

			set virtualPosition $unscaled
			for {} { $i < $totalSteps } { incr i } {		
				set virtualPosition [ expr $virtualPosition + $stepsPerIncrement * $direction]
				set movePath($i) $virtualPosition
				puts "movePath($i): $movePath($i)"
			}
		} else {
			set movePath($i) $unscaled
			set totalSteps 1
			incr i
		}
		
		set movePath($i) [expr $unscaledTargetPosition ]
		puts "movePath($i): $movePath($i)"

		set totalStepsInMove $totalSteps
	}

	set aborting 0
	set movedSteps 0
	after 100 "$this moveIncrement"
}


body simulatedMotor::oscillation { shutter delta exposuretime } {
	set unscaledDelta [scaled2Unscaled $delta]
	set requestedSpeed [ expr $unscaledDelta / $exposuretime ]
	set unscaledTargetPosition [expr $unscaled + $unscaledDelta]

	#check to make sure that the motor is allowed to move this fast
	if { $requestedSpeed > $speed } {
		dcss sendMessage "htos_motor_move_completed $name $scaled too_fast"
		return 
	}


	if { ($unscaledTargetPosition - $unscaled) < 1} {
		set direction -1 
	} else {
		set direction 1
	}

	#Move the motor only by steps that are integers values.
	#this will help simulate problems with stepper motor round off.  The drawback
	#is that the actual time for completing a move will have a little error in it.
	set stepsPerIncrement [ expr int ( ($requestedSpeed + 0.999) ) /10 ];
	if { $stepsPerIncrement < 1 } {
		set stepsPerIncrement 1
		dcss sendMessage "htos_note oscillation_too_slow $name"
	}

	puts "stepsPerIncrement: $stepsPerIncrement"

	set totalSteps [ expr int (abs ($unscaledTargetPosition - $unscaled)) / $stepsPerIncrement ]
	puts "totalSteps: $totalSteps"

	set i 0
	if { $totalSteps > 0} {

		set virtualPosition $unscaled
		for {} { $i < $totalSteps } { incr i } {		
			set virtualPosition [ expr $virtualPosition + $stepsPerIncrement * $direction]
			set movePath($i) $virtualPosition
			puts "movePath($i): $movePath($i)"
		}
	} else {
		set movePath($i) $unscaled
		set totalSteps 1
		incr i
	}
	
	set movePath($i) [expr $unscaledTargetPosition ]
	puts "movePath($i): $movePath($i)"
	
	set totalStepsInMove $totalSteps

	set aborting 0
	set movedSteps 0
	after 100 "$this moveIncrement"

}


body simulatedMotor::moveIncrement {} {
	if { $aborting == 1 } {
		dcss sendMessage "htos_motor_move_completed $name $scaled aborted"
		set aborting  0
		return
	}
	
	incr movedSteps
	setUnscaledPosition $movePath($movedSteps)

	if { $movedSteps < $totalStepsInMove } {
		dcss sendMessage "htos_update_motor_position $name $scaled normal";
		after 100 "$this moveIncrement"
	} else {
		dcss sendMessage "htos_motor_move_completed $name $scaled normal"
	}
}

body simulatedMotor::abort {} {
	set aborting 1
}


body simulatedMotor::scaled2Unscaled { unscaledValue  } {
	if { $scaleFactor != "undefined" } {
		return  [expr round($unscaledValue * $scaleFactor) ]
	} else {
		error "undefined scaleFactor"
	}
}

#class motorPath {
#	private variable virtualPosition
#	private variable totalSteps
#	private variable movePath
#	
#	public method reset { unscaledPosition }
#	public method add { unscaledDestination unscaledSteps }
#}

#body motorPath::reset { position } {
#	set virtualPosition $unscaled
#	set totalStep 0
#	array unset movePath
#}

#body motorPath::add { unscaledDestination stepsPerIncrement } {
#	set additionalSteps [ expr int (abs ($unscaledDestination - $virtualPosition)) / $stepsPerIncrement ]
#	puts "totalSteps: $totalSteps"

#	set i 0
#	if { $additionalSteps > 0} {
#		for {} { $i < $additionalSteps } { incr i; incr totalSteps } {		
#			set virtualPosition [ expr $virtualPosition + $stepsPerIncrement * $direction]
#			set movePath($totalSteps) $virtualPosition
#			puts "movePath($i): $movePath($i)"
#		}
#	}
#}



class simulatedEncoder {
	public variable name
	public variable position 0
	public variable associatedMotor ""
	public variable errorOffset 0.0

	public method constructor { args } {}
	public method moveWithError { newPosition}
	
}

body simulatedEncoder::moveWithError { newPosition } {
	puts "MOVE WITH ERROR"
	#set motorRange [expr [Motor$associatedMotor cget -lowerLimit] - [Motor$associatedMotor cget -upperLimit]]
	set motorRange 100
	set randomDelta 0.0
	#set randomDelta [expr (rand() - 0.5) * $motorRange * .05]
	
	set errorOffset [expr $errorOffset + $randomDelta]
	
	set position [expr $newPosition + $errorOffset]
}


