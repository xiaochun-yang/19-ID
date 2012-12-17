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
##########################################################################
#
#                       Permission Notice
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
# BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
##########################################################################

# provide the DCSComponent package
package provide DCSMotorTargetList 1.0

package require DCSComponent

#############
#
# add motors and their desired positions to this class.
#
# This class will monitor the motors' positions and 
# enable the output (which another object can register interest in)
# when a motor is not in its correct position.  Issuing the moveToTargets
# method will move the offending motors back into position.
#
class DCS::MotorTargetList {
	
	inherit ::DCS::ComponentGate

	protected method calculateOutput
	public method moveToTargets
	public method addMotor
    public method removeMotor

	constructor { args } 		{
		::DCS::ComponentGate::constructor { 
			gateOutput {getOutput} }
	} {
		announceExist
	}
}


body DCS::MotorTargetList::calculateOutput { } {

	#set _motorTargetList($deviceName) $targetPosition
	#puts "TARGET entered calculateOutput "	


	set tempOutput 0
	set _outputMessage "ready"
	set _blockingInput ""
	set _blockingValue ""

	# Check that each relevant target object is in the correct state before
	set tempOutput 0
	foreach {attribute} [array names _blockingValuesArray] {
		
		#remember the wanted trigger value
		set targetPosition $_blockingValuesArray($attribute) 
		foreach {currentPosition -} $_inputValueArray($attribute) break

		#puts "TARGET: $targetPosition"

		if { abs ( $currentPosition - $targetPosition) < 0.01 } {
			set _outputMessage $_inputMessageArray($attribute)
			set _blockingValue $_inputValueArray($attribute)
			set _blockingInput $attribute
		} else {
			set tempOutput 1
            break
		}
	}
	
	#this object has changed states, update the registered components
	set _gateOutput $tempOutput
	
	updateRegisteredComponents gateOutput
	handleNewOutput
}

body DCS::MotorTargetList::addMotor {device targetPosition } {

	#puts "TARGET $this entered addMotor $device $targetPosition"	

	# set up references to the motor object
	addInput "$device scaledPosition $targetPosition {not at Position}"
}
body DCS::MotorTargetList::removeMotor {device targetPosition } {
	deleteInput "$device scaledPosition $targetPosition {not at Position}"
}


body DCS::MotorTargetList::moveToTargets { } {
	#puts "TARGET $this moveToTargets entered: [array names _blockingValuesArray]"

	# Check that each relevant target object is in the correct state before
	foreach {attribute} [array names _blockingValuesArray] {
		#puts "TARGET: $attribute"

		foreach {device dummy} [split $attribute ~] break

		#remember the wanted trigger value
		set targetPosition $_blockingValuesArray($attribute)
		
		$device move to $targetPosition [$device cget -baseUnits]
	}
}

