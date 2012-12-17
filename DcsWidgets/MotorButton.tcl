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

# provide the DCSEntry package
package provide DCSMotorButton 1.0

# load standard packages
package require DCSButton
package require DCSMotorTargetList

#source ../DcsWidgets/MoveMotorList.tcl


###################
#
# MoveMotorsToTargetButton:  This widget will watch a list of
# motors and their positions.  If the motors' positions do not
# match the target positions, the button will become enabled
# and pushing the button will attempt to move all of the offending
# motors to their target position.
#
####################

class DCS::MoveMotorsToTargetButton {
	# inheritance
	inherit ::DCS::Button

	#itk_option define -device device Device ""
	#itk_option define -targetPosition targetPosition TargetPosition ""

	private variable _motorMoveList
	private variable _lastDevice ""

	public method handleNewPosition
	public method addMotor
	public method removeMotor

    ##override
    protected method internalOnCommand { } {
		$_motorMoveList moveToTargets
    }

	constructor { args } {
		set _motorMoveList DCS::MoveMotorsToTargetButton::[DCS::MotorTargetList \#auto]

		addInput [list ::$_motorMoveList gateOutput 1 {Motor(s) in position}]

		eval itk_initialize $args
		
		announceExist
	}
}

body DCS::MoveMotorsToTargetButton::addMotor {device targetPosition} {
	
	$_motorMoveList addMotor $device $targetPosition
	
	addInput "$device status inactive {supporting device}"
}

body DCS::MoveMotorsToTargetButton::removeMotor {device targetPosition} {
	
	$_motorMoveList removeMotor $device $targetPosition
	
	deleteInput "$device status inactive {supporting device}"
}


#####################################################
# MoveMotorRelativeButton:  This widget can be configured
# to move a device by a delta amount each time the button
# is pushed.
#####################################################

class DCS::MoveMotorRelativeButton {
	# inheritance
	inherit ::DCS::Button

	itk_option define -device device Device ""
	itk_option define -delta delta Delta ""

	private variable _lastDevice ""

	public method addMotor

	constructor { args } {

		eval itk_initialize $args
		
		announceExist
	}
}

configbody DCS::MoveMotorRelativeButton::device {

	#verify that the device and delta are both defined before adding the motor
	if {$itk_option(-device) != "" } {
		if {$itk_option(-delta) != "" } {
			addMotor $itk_option(-device) $itk_option(-delta)
		}
	}
}

configbody DCS::MoveMotorRelativeButton::delta {
	
	#verify that the device and delta are both defined before adding the motor
	if {$itk_option(-device) != "" } {
		if {$itk_option(-delta) != "" } {
			addMotor $itk_option(-device) $itk_option(-delta)
		}
	}
}

body DCS::MoveMotorRelativeButton::addMotor {device delta} {
	configure -command "$device move by $delta [$device cget -baseUnits]"
	addInput "$device status inactive {supporting device}"
}
