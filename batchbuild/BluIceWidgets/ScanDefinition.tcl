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

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
package require DCSHardwareManager
package require DCSDeviceFactory


class DCS::ScanDefinition {
 	inherit ::DCS::Component

	public variable device "(none)" 

	private variable _totalPoints 21
	private variable _startPosition 0
	private variable _centerPosition 1
	private variable _endPosition 2
	private variable _width 2
	private variable _stepSize 0.1
	private variable _units mm
	private variable _backlash 0
    private variable _limitsOK 1
	
	private variable _initiatorId ""
	private variable _validDevice 0

	public method setScanDefinition
	
	public method getTotalPoints {} {return $_totalPoints}
	public method getStartPosition {} {return [list $_startPosition $_units]}
	public method getCenterPosition {} {return [list $_centerPosition $_units]}
	public method getEndPosition {} {return [list $_endPosition $_units]}
	public method getWidth {} {return [list $_width $_units]}
	public method getStepSize {} {return [list $_stepSize $_units]}
	public method getDeviceName {} {
		if {$_validDevice} {
			return [namespace tail $device]
		} else {
			return ""
		}
	}
	public method getUnits {} {return $_units}
    public method getWillBacklash { } { return $_backlash }
	
	public method changeTotalPoints
	public method changeStartPosition
	public method changeCenterPosition
	public method changeEndPosition
	public method changeWidth
	public method changeStepSize
	
	public variable totalPointsReference ""
	public variable startPositionReference ""
	public variable centerPositionReference ""
	public variable endPositionReference ""
	public variable widthReference ""
	public variable stepSizeReference ""
	
	
	public method handleTotalPointsChange
	public method handleStartPositionChange
	public method handleCenterPositionChange
	public method handleEndPositionChange
	public method handleStepSizeChange
	public method handleWidthChange
	
	public method convertUnits
	public method getRecommendedUnits
	public method getRecommendedPrecision
	protected method beenHereBefore

	public method isEqual

    public method dump {} {
        return "device: {$device} $_totalPoints $_startPosition $_endPosition $_units"
    }

	public method invalidateDefinition {} {set _validDevice 0}

    private method checkBacklash { } 
    private method checkLimits { } 
	
	constructor { args} \
		 {::DCS::Component::constructor \
				{ -totalPoints getTotalPoints \
						-startPosition getStartPosition \
						-centerPosition getCenterPosition \
						-endPosition getEndPosition \
						-width getWidth \
						-stepSize getStepSize \
                        -backlash getWillBacklash \
						-device getDeviceName }} \
		 {
			 eval configure $args
			 announceExist
		 }
	
	destructor {
        announceDestruction
	}
}

configbody DCS::ScanDefinition::device {
    #puts "set device to $device"
	if { $device == "" || $device == "(none)"} {
		set _units mm
	} elseif { $device == "time" } {
		set _units s
	} else {
		set _units [$device cget -baseUnits] 
    }
}


body DCS::ScanDefinition::setScanDefinition { device_ points_ start_ end_ steps_ } {

    puts "+setScanDefinition $device_ $points_ $start_ $end_ $steps_"
    puts "for $this"

    if {$device_ != "" && $device_ != "(none)"} {
	    set _validDevice 1
    } else {
	    set _validDevice 0
    }


    if {$device != $device_} {
	    configure -device $device_
    }


	set _totalPoints $points_
	set _startPosition $start_
	set _stepSize $steps_

    #puts "in setScanDef: start: $_startPosition"
	
	changeEndPosition $end_ ""

	beenHereBefore 0

	updateRegisteredComponents -device $_initiatorId
	updateRegisteredComponents -totalPoints $_initiatorId
	updateRegisteredComponents -startPosition $_initiatorId
    checkBacklash
    #checkLimits
    #puts "-setScanDefinition"
}

body DCS::ScanDefinition::changeTotalPoints { points_ initiatorId_} {
	#set stepSize based on new total points and old width

	if { ![isInt $points_] || $points_ < 2 } {
        log_warning total poinst must be an integer and >= 2
	    #updateRegisteredComponents -totalPoints 0
        return
    }
	if {[beenHereBefore $initiatorId_]} {
        return
    }

	set _totalPoints $points_
	if { ![isFloat $_width] } {
        return
    }
    set newStep \
    [expr abs(double([trim $_width]) / ([trim $_totalPoints] - 1))] 
    if {$_stepSize > 0} {
        set _stepSize $newStep
    } else {
        set _stepSize [expr -1.0 * $newStep]
    }
    #puts "stepSize from total points: $_stepSize"
	updateRegisteredComponents -stepSize $_initiatorId
	updateRegisteredComponents -totalPoints $_initiatorId
}


body DCS::ScanDefinition::changeStartPosition { position_ initiatorId_ } {
	# set center and width based on new start and old end
	if { ![isFloat $position_] } {	
        log_error start must be a float number
	    #updateRegisteredComponents -startPosition 0
        return
	}
	if {[beenHereBefore $initiatorId_]} {
        return
    }

    if {$device == "time"} {
        if {$position_ < 0} {
            log_error for time start must >= 0
	        updateRegisteredComponents -startPosition 0
            return
        }
        if {$position_ >= $_endPosition} {
            log_error for time start must < end: $_endPosition
	        updateRegisteredComponents -startPosition 0
            return
        }
    }

	set _startPosition $position_
	if { ![isFloat $_endPosition] } {	
        return
	}
    #puts "handle start start=$_startPosition end=$_endPosition"
	
	set _width [expr double( [trim $_endPosition] ) - double([trim $_startPosition])]
	set _centerPosition [expr (double([trim $_startPosition]) + double([trim $_endPosition])) / 2.0 ]
    #puts "really set center to $_centerPosition"
	if { [isInt $_totalPoints] && $_totalPoints > 2 } {
		set _stepSize [expr double([trim $_width]) / ( double([trim $_totalPoints]) - 1 )]
	} else {
		set _stepSize 1.0
	}

    set _width [expr abs($_width)]

	updateRegisteredComponents -startPosition $_initiatorId
	updateRegisteredComponents -centerPosition  $_initiatorId
	updateRegisteredComponents -width $_initiatorId
	updateRegisteredComponents -stepSize $_initiatorId
    checkBacklash
    checkLimits
}

body DCS::ScanDefinition::changeEndPosition { position_  initiatorId_ } {
	# set center and width based on old start and new end
	if { ![isFloat $position_] } {	
        log_error end must be a float number
	    #updateRegisteredComponents -endPosition 0
        return
	}
	if {[beenHereBefore $initiatorId_]} {
        return
    }

    if {$device == "time"} {
        set limit 0
	    if {[isFloat $_startPosition] } {	
            set limit $_startPosition
        }
        if {$limit < 0} {
            set limit 0
        }
        if {$position_ < $limit} {
            log_error for time end must > start: $limit
	        updateRegisteredComponents -endPosition 0
            return
        }
    }

	set _endPosition $position_
	if { ![isFloat $_startPosition] } {	
        log_error "start position $_startPosition is not float"
        return
	}

    #puts "handle end start=$_startPosition end=$_endPosition"
	
	set _width [expr double( [trim $_endPosition] ) - double([trim $_startPosition])]
	set _centerPosition [expr (double([trim $_startPosition]) + double([trim $_endPosition])) / double(2) ]
	if { [isInt $_totalPoints] && $_totalPoints > 2 } {
		set _stepSize [expr double([trim $_width]) / ( double([trim $_totalPoints]) - 1 )]
	} else {
		set _stepSize 1.0
	}

    set _width [expr abs($_width)]

	updateRegisteredComponents -endPosition $_initiatorId
	updateRegisteredComponents -centerPosition  $_initiatorId
	updateRegisteredComponents -width $_initiatorId
	updateRegisteredComponents -stepSize $_initiatorId
    checkBacklash
    checkLimits
}

body DCS::ScanDefinition::changeCenterPosition {position_ initiatorId_ } {
	# set start and end from new center and old width
	if { ![isFloat $position_] } {	
        log_error center must be a float number
	    #updateRegisteredComponents -centerPosition 0
        return
	}
    if {$device == "time"} {
	    set newStart [expr double( [trim $position_] ) - double([trim $_width]) / 2]
        if {$newStart < 0} {
            log_error this will make the start time < 0
	        updateRegisteredComponents -centerPosition 0
            return
        }
    }
	if {[beenHereBefore $initiatorId_]} {
        return
    }
	set _centerPosition $position_
	if { ![isFloat $_width] } {	
        return
	}

    if {$_stepSize > 0} {
	    set _startPosition [expr double( [trim $_centerPosition] ) - double([trim $_width]) / 2]
	    set _endPosition [expr double( [trim $_centerPosition] ) + double([trim $_width]) / 2]
    } else {
	    set _endPosition [expr double( [trim $_centerPosition] ) - double([trim $_width]) / 2]
	    set _startPosition [expr double( [trim $_centerPosition] ) + double([trim $_width]) / 2]
    }

	updateRegisteredComponents -startPosition $_initiatorId
	updateRegisteredComponents -endPosition $_initiatorId
	updateRegisteredComponents -centerPosition  $_initiatorId
    checkLimits
}

body DCS::ScanDefinition::changeWidth { width_ initiatorId_ } {
	# set start and end from old center and new width
	if { ![isFloat $width_] || $width_ <= 0 } {	
        log_error width must be a positive float number
	    #updateRegisteredComponents -width 0
        return
	}
	if {[beenHereBefore $initiatorId_]} {
        return
    }

    if {$device == "time"} {
	    set newStart [expr double( [trim $_centerPosition] ) - double([trim $width_]) / 2]
        if {$newStart < 0} {
            log_error this will make the start time < 0
	        updateRegisteredComponents -width 0
            return
        }
    }

	set _width [expr abs($width_)]
	if { ![isFloat $_centerPosition] } {	
        return
	}
    if {$_stepSize > 0} {
	    set _startPosition [expr double( [trim $_centerPosition] ) - double([trim $_width]) / 2]
	    set _endPosition [expr double( [trim $_centerPosition] ) + double([trim $_width]) / 2]
    } else {
	    set _endPosition [expr double( [trim $_centerPosition] ) - double([trim $_width]) / 2]
	    set _startPosition [expr double( [trim $_centerPosition] ) + double([trim $_width]) / 2]
    }

	if { [isInt $_totalPoints] && $_totalPoints > 2 } {
		set newStep [expr double([trim $_width]) / ( double([trim $_totalPoints]) - 1 )]
	} else {
		set newStep 1.0
	}
    if {$_stepSize > 0} {
        set _stepSize $newStep
    } else {
        set _stepSize [expr -1.0 * $newStep]
    }

	updateRegisteredComponents -startPosition $_initiatorId
	updateRegisteredComponents -endPosition $_initiatorId
	updateRegisteredComponents -width  $_initiatorId
	updateRegisteredComponents -stepSize  $_initiatorId
    checkLimits
}

body DCS::ScanDefinition::changeStepSize { stepSize_ initiatorId_ } {
	#change the sign of the width and the total points based on the new step size and old width
	if { ![isFloat $stepSize_] } {	
        log_error stepSize must be a float number
	    #updateRegisteredComponents -stepSize 0
        return
	}
    if {$stepSize_ == 0} {
        log_error stepSize must != 0
	    #updateRegisteredComponents -stepSize 0
        return
    }
	if { abs($stepSize_) > abs($_width) } {
        log_error stepSize too big
	    updateRegisteredComponents -stepSize 0
        return
    }
	if {[beenHereBefore $initiatorId_]} {
        return
    }
    if {$device == "time" && $stepSize_ <= 0} {
        log_error for time stepSize must > 0
	    updateRegisteredComponents -stepSize 0
        return
    }
    set needToSwapStartEnd [expr $_stepSize * $stepSize_ < 0]

	set _stepSize [trim $stepSize_]
	if { ![isFloat $_width] } {
        return
    }

	set _totalPoints [expr abs( round( double($_width) / $_stepSize ) ) + 1 ]


	updateRegisteredComponents -stepSize  $_initiatorId
	updateRegisteredComponents -totalPoints $_initiatorId

    if {$needToSwapStartEnd} {
        changeWidth $_width ""
    }
    checkBacklash
}

configbody DCS::ScanDefinition::totalPointsReference {
	if {$totalPointsReference != "" } {
		foreach {component value} $totalPointsReference break
		::mediator register $this $component $value handleTotalPointsChange
	}
}

configbody DCS::ScanDefinition::startPositionReference {
	if {$startPositionReference != "" } {
		foreach {component value} $startPositionReference break
		::mediator register $this $component $value handleStartPositionChange
	}
}

configbody DCS::ScanDefinition::centerPositionReference {
	if {$centerPositionReference != "" } {
		foreach {component value} $centerPositionReference break
		::mediator register $this $component $value handleCenterPositionChange
	}
}

configbody DCS::ScanDefinition::endPositionReference {
	if {$endPositionReference != "" } {
		foreach {component value} $endPositionReference break
		::mediator register $this $component $value handleEndPositionChange
	}
}

configbody DCS::ScanDefinition::widthReference {
	if {$widthReference != "" } {
		foreach {component value} $widthReference break
		::mediator register $this $component $value handleWidthChange
	}
}


configbody DCS::ScanDefinition::stepSizeReference {
	if { $stepSizeReference != ""} {
		foreach {component value} $stepSizeReference break

			::mediator register $this $component $value handleStepSizeChange
		
	}
}

body DCS::ScanDefinition::handleTotalPointsChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$value_ == ""} return

	if {$targetReady_} {
        #puts "handleTotalPointsChange $value_"
		changeTotalPoints $value_ $initiatorId_
	}
}

body DCS::ScanDefinition::handleStartPositionChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$value_ == ""} return


	if {$targetReady_} {
        #puts "handleStartPositionChange $value_"
		foreach { value units } $value_ break  
		changeStartPosition [convertUnits $value $units $_units] $initiatorId_
	}
}


body DCS::ScanDefinition::handleCenterPositionChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$value_ == ""} {
        return
    }

	if {$targetReady_} {
        #puts "+handleCenterPositionChange $value_"
		foreach { value units } $value_ break  
		changeCenterPosition [convertUnits $value $units $_units] $initiatorId_
        #puts "-handleCenterPositionChange"
	}
}


body DCS::ScanDefinition::handleEndPositionChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$value_ == ""} {
        return
    }

	if {$targetReady_} {
        #puts "+handleEndPositionChange $value_"
        #puts "system unit $_units"
		foreach { value units } $value_ break  
		changeEndPosition [convertUnits $value $units $_units] $initiatorId_
        #puts "-handleEndPositionChange"
	}
}

body DCS::ScanDefinition::handleWidthChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$value_ == ""} {
        return
    }

	if {$targetReady_} {
        #puts "+handleWidthChange $value_"
		foreach { value units } $value_ break
		changeWidth [convertUnits $value $units $_units] $initiatorId_
        #puts "-handleWidthChange"
	}
}


body DCS::ScanDefinition::handleStepSizeChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$value_ == ""} {
        return
    }

	if {$targetReady_} {
        #puts "+handleStepSizeChange $value_"
		foreach { value units } $value_ break
		changeStepSize [convertUnits $value $units $_units] $initiatorId_
        #puts "-handleStepSizeChange $value_"
	}
}

body DCS::ScanDefinition::convertUnits { value_ fromValue_ toValue_ } {
	if {$value_ == ""} return ""
	
	if { $device != "" && $device != "(none)" && $device != "time" } {
		$device convertUnits $value_ $fromValue_ $toValue_
	} else {
		#give it our best shot
		return [::units convertUnits $value_ $fromValue_ $toValue_]
	}
}

body DCS::ScanDefinition::beenHereBefore { initiatorId_ } { 
	if {$initiatorId_ != "" } {
		#if we started this event cycle, end it here
		if { $_initiatorId >= $initiatorId_ } {
			#puts "SCANDEF: BEEN HERE BEFORE $initiatorId_"
			#we started the original event
			return 1
		} else {
			#puts "SCANDEF: FIRST TIME TO SEE $initiatorId_. erasing $_initiatorId"
			set _initiatorId $initiatorId_
		}
	} else {
		#puts "SCANDEF NO INITIATOR ID $_initiatorId"
		set _initiatorId [::mediator getUniqueInitiatorId]
	}
	
	return 0
}

body DCS::ScanDefinition::getRecommendedUnits { } {
    if {$device == "" || $device == "(none)"} {
        return "mm"
    } elseif { $device == "time" } {
        return "s"
    }

    #puts "ask {$device} for units"
	#puts "[$device getRecommendedUnits]"
	#ask the device for the best units
	return [$device getRecommendedUnits]
}

body DCS::ScanDefinition::getRecommendedPrecision { units_  } {
	#ask the device for the best units
    if {$device == "" || $device == "(none)" || $device == "time" } {
	    #puts "(none) prevision 4 0.0005"
        return [list 4 0.0005]
    }
    #puts "ask {$device} for precision of $units_"
	#puts "[$device getRecommendedPrecision $units_ ]"
	return [$device getRecommendedPrecision $units_ ]
}

#compare a different scan definition object
body DCS::ScanDefinition::isEqual { otherScanDef_ } {

	set this_device [getDeviceName]
	set other_device [$otherScanDef_ getDeviceName]
	if {$this_device != $other_device} {
        #puts "device not the same: {$this_device} {$other_device}" 
        return 0
    }

	#don't compare the details if both devices are (none)
    if {$this_device == "" || $other_device == ""} {
        #puts "one of them is null: {$this_device} {$other_device}" 
        return 1
    }

	if { [getTotalPoints] != [$otherScanDef_ getTotalPoints ]} { return 0 }
    

    set my_start [::units convertUnitValue [getStartPosition] $_units]
	set my_end [::units convertUnitValue [getEndPosition] $_units]
    set other_start [::units convertUnitValue [$otherScanDef_ getStartPosition] $_units]
    set other_end [::units convertUnitValue [$otherScanDef_ getEndPosition] $_units]

    if {$my_start != $other_start} {
        #puts "start not the same"
        #puts "my: $my_start"
        #puts "other: $other_start"
        return 0
    }
    if {$my_end != $other_end} {
        #puts "end not the same"
        #puts "my: $my_end"
        #puts "other: $other_end"
        return 0
    }

	return 1
}
body DCS::ScanDefinition::checkBacklash { } {
    set newBacklash 0
    catch {
        if {$_validDevice && \
	    $device != "" && \
        $device != "(none)" && \
	    $device != "time" && \
        [$device getMotorType] == "real" && \
        [$device getBacklashOn]} {
            set bl [$device getBacklash]
            set bl [lindex $bl 0]
            if {$bl * $_stepSize < 0} {
                set newBacklash 1
            }
        }
    }
    if {$_backlash != $newBacklash} {
        set _backlash $newBacklash
        #puts "new backlash $_backlash"
        updateRegisteredComponents -backlash
    }
}
body DCS::ScanDefinition::checkLimits { } {
    if {[catch {
        if {$_validDevice && \
	    $device != "" && \
        $device != "(none)" && \
	    $device != "time"} {
            set v1 $_startPosition
            set v2 $_endPosition
            ### v1 and v2 may be changed
            if {![$device limits_ok v1] || ![$device limits_ok v2]} {
                set name [$device cget -deviceName]

                set ul [$device getEffectiveUpperLimit]
                set ll [$device getEffectiveLowerLimit]
                foreach {ul units} $ul break
                set ll [lindex $ll 0]
                set ff [getRecommendedPrecision $units]
                set dec [lindex $ff 0]

                set ll [getCleanValue $ll float $dec]
                set ul [getCleanValue $ul float $dec]

                log_error start=$_startPosition end=$_endPosition

                log_error $name limits: $ll to $ul $units

                set _limitsOK 0
            } else {
                if {!$_limitsOK} {
                    log_note limits check ok for $_startPosition $_endPosition
                }
                set _limitsOK 1
            }
        }
    } errMsg]} {
        puts "checkLimits faild: $errMsg"
    }
}

class DCS::FullScanDefinition {
 	inherit ::DCS::Component

	public variable signalReference ""
	public variable referenceSignalReference ""
	public variable signal3Reference ""
	public variable signal4Reference ""
	public variable numScansReference ""
	public variable delayBetweenScansReference ""
	public variable integrationTimeReference ""
	public variable motorSettlingTimeReference ""
	public variable scanNumberReference ""
	public variable filenameReference ""
	public variable directoryReference ""
	public variable filterReference ""
	public variable spiralReference ""

    #need this to get username and sessionId
	public variable controlSystem "::dcss"


	public method handleSignalChange
	public method handleReferenceSignalChange
	public method handleSignal3Change
	public method handleSignal4Change
	public method handleNumScansChange
	public method handleDelayBetweenScansChange
	public method handleIntegrationTimeChange
	public method handleMotorSettlingTimeChange
	public method handleScanNumberChange
	public method handleFilenameChange
	public method handleDirectoryChange
	public method handleFilterChange

    public method handleBacklashChange
    public method handleDeviceChange

	public method handleSpiralChange

	public method loadDefinition
	public method saveDefinition
	public method setDefinition

	private method writeScanHeader
	public proc readScanHeader
	public proc readScanHeaderByLine
    private proc  parseFilename
	private method getTimingParametersFromString
	private method getPrefixParametersFromString
	public method makeScanCommand
	private method convertMotorScanDefinitionToString
	private method setMotorScanDefinitionFromString


	public method getMotor1ScanDefinition {} {return $_motor1}
	public method getMotor2ScanDefinition {} {return $_motor2}
	
	public method setListOfMotorsFromAxesDefinitions
	public method getListOfMotors
	public method getNumberOfMotors
	public method getStartPositionForMotor1 {} {return [$_motor1 getStartPosition]}
	public method getEndPositionForMotor1 {} {return [$_motor1 getEndPosition]}
	public method getStartPositionForMotor2 {} {return [$_motor2 getStartPosition]}


    public method getShowSpiral { } { return $m_showSpiral }
    public method getSpiralOn { }   { return $m_spiralOn }

    public method setSpiralOn { v } {
        set m_spiralOn $v
        updateRegisteredComponents -spiralOn
    }

	private variable _motor1
	private variable _motor2
	private variable _signal "i0"
	private variable _referenceSignal ""
    private variable _signal3 ""
    private variable _signal4 ""
	private variable _numScans "1"

	private variable _delayBetweenScans "0.0 s"
	private variable _integrationTime "0.1 s"
	private variable _motorSettlingTime "0.0 s"

	private variable _scanNumber "1"
	private variable _directory "~"
	private variable _filename "scan"
	private variable _operationId ""

	private variable _motorScanList ""
	private variable _numberOfMotors 0

    private variable m_showSpiral 0
    private variable m_spiralOn 0

	private variable _filter ""

	public method getOperationId {} {return $_operationId}
	public method isEqual
	
	public method getSignal {} {
        #puts "getSignal for $this will return $_signal"
        return $_signal
    }
	public method getSignal3 {} { return $_signal3 }
	public method getSignal4 {} { return $_signal4 }
	public method getReferenceSignal {} {return $_referenceSignal}
	public method getNumScans {} {return $_numScans}
	public method getDelayBetweenScans {} {return $_delayBetweenScans}
	public method getIntegrationTime {} {
        #puts "getIntegrationTime for $this will return $_integrationTime"
        return $_integrationTime
    }
	public method getMotorSettlingTime {} {return $_motorSettlingTime}
	public method getScanNumber {} {return $_scanNumber}
	public method getFilename {} {return $_fileName}
	public method startScan
    public method getWillBacklash { } {
        if {[$_motor1 getWillBacklash]} {
            return 1
        }
        if {[$_motor2 getWillBacklash]} {
            return 1
        }
        return 0
    }
   
   private variable m_deviceFactory

	constructor { args} \
		 {::DCS::Component::constructor \
				{ -signal getSignal \
						-referenceSignal getReferenceSignal \
                        -signal3 getSignal3 \
                        -signal4 getSignal4 \
						-numScans getNumScans \
						-delayBetweenScans getDelayBetweenScans \
						-integrationTime getIntegrationTime \
						-motorSettlingTime getMotorSettlingTime \
						-scanNumber getScanNumber \
                        -backlash getWillBacklash \
                        -showSpiral getShowSpiral \
                        -spiralOn   getSpiralOn \
						-filename getFilename }} \
		 {
            set m_deviceFactory [DCS::DeviceFactory::getObject]
		    set _motor1 [namespace current]::[DCS::ScanDefinition \#auto]
		    set _motor2 [namespace current]::[DCS::ScanDefinition \#auto]
		    set _filter [namespace current]::[DCS::Set \#auto]

            ###hook up
            $_motor1 register $this -backlash handleBacklashChange
            $_motor2 register $this -backlash handleBacklashChange

            $_motor1 register $this -device handleDeviceChange
            $_motor2 register $this -device handleDeviceChange

			 eval configure $args
			 announceExist
		 }
    destructor {
        announceDestruction
    }
}

configbody DCS::FullScanDefinition::signalReference {
	if {$signalReference != "" } {
		foreach {component value} $signalReference break
		::mediator register $this $component $value handleSignalChange
	}
}

configbody DCS::FullScanDefinition::referenceSignalReference {
	if {$referenceSignalReference != "" } {
		foreach {component value} $referenceSignalReference break
		::mediator register $this $component $value handleReferenceSignalChange
	}
}

configbody DCS::FullScanDefinition::signal3Reference {
	if {$signal3Reference != "" } {
		foreach {component value} $signal3Reference break
		::mediator register $this $component $value handleSignal3Change
	}
}

configbody DCS::FullScanDefinition::signal4Reference {
	if {$signal4Reference != "" } {
		foreach {component value} $signal4Reference break
		::mediator register $this $component $value handleSignal4Change
	}
}

configbody DCS::FullScanDefinition::numScansReference {
	if {$numScansReference != "" } {
		foreach {component value} $numScansReference break
		::mediator register $this $component $value handleNumScansChange
	}
}

configbody DCS::FullScanDefinition::delayBetweenScansReference {
	if {$delayBetweenScansReference != "" } {
		foreach {component value} $delayBetweenScansReference break
		::mediator register $this $component $value handleDelayBetweenScansChange
	}
}

configbody DCS::FullScanDefinition::spiralReference {
	if {$spiralReference != "" } {
		foreach {component value} $spiralReference break
		::mediator register $this $component $value handleSpiralChange
	}
}

configbody DCS::FullScanDefinition::integrationTimeReference {
	if {$integrationTimeReference != "" } {
		foreach {component value} $integrationTimeReference break
		::mediator register $this $component $value handleIntegrationTimeChange
	}
}

configbody DCS::FullScanDefinition::motorSettlingTimeReference {
	if {$motorSettlingTimeReference != "" } {
		foreach {component value} $motorSettlingTimeReference break
		::mediator register $this $component $value handleMotorSettlingTimeChange
	}
}

configbody DCS::FullScanDefinition::scanNumberReference {
	if {$scanNumberReference != "" } {
		foreach {component value} $scanNumberReference break
		::mediator register $this $component $value handleScanNumberChange
	}
}

configbody DCS::FullScanDefinition::filenameReference {
	if {$filenameReference != "" } {
		foreach {component value} $filenameReference break
		::mediator register $this $component $value handleFilenameChange
	}
}

configbody DCS::FullScanDefinition::directoryReference {
	if {$directoryReference != "" } {
		foreach {component value} $directoryReference break
		::mediator register $this $component $value handleDirectoryChange
	}
}

configbody DCS::FullScanDefinition::filterReference {
	if {$filterReference != "" } {
		foreach {component value} $filterReference break
		::mediator register $this $component $value handleFilterChange
	}
}


body DCS::FullScanDefinition::handleSignalChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$targetReady_} {
        #puts "handleSignalChange $value_ for $this"
		if {$value_ == "(none)"} {
			set _signal ""
		} else {
		set _signal $value_
		}
	}
}

body DCS::FullScanDefinition::handleReferenceSignalChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$targetReady_} {
		if {$value_ == "(none)"} {
			set _referenceSignal ""
		} else {
			set _referenceSignal $value_
		}
	}
}

body DCS::FullScanDefinition::handleSignal3Change {caller_ targetReady_ - value_ initiatorId_ } {
	if {$targetReady_} {
		if {$value_ == "(none)"} {
			set _signal3 ""
		} else {
		set _signal3 $value_
		}
	}
}

body DCS::FullScanDefinition::handleSignal4Change {caller_ targetReady_ - value_ initiatorId_ } {
	if {$targetReady_} {
		if {$value_ == "(none)"} {
			set _signal4 ""
		} else {
		set _signal4 $value_
		}
	}
}

body DCS::FullScanDefinition::handleNumScansChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$targetReady_} {
		set _numScans $value_
	}
}

body DCS::FullScanDefinition::handleDelayBetweenScansChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$targetReady_} {
        #puts "handle delay between: $value_"
		set _delayBetweenScans $value_
	}
}
body DCS::FullScanDefinition::handleSpiralChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$targetReady_} {
		set m_spiralOn $value_
	}
}

body DCS::FullScanDefinition::handleIntegrationTimeChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$targetReady_} {
        #puts "handle integration time: $value_"
		set _integrationTime $value_
	}
}

body DCS::FullScanDefinition::handleMotorSettlingTimeChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$targetReady_} {
        #puts "handle settle time: $value_"
		set _motorSettlingTime $value_
	}
}

body DCS::FullScanDefinition::handleScanNumberChange {caller_ targetReady_ - value_ initiatorId_ } {
    #puts "handle scan number change $value_"
	if {$targetReady_} {
		set _scanNumber $value_
	}
}

body DCS::FullScanDefinition::handleFilenameChange {caller_ targetReady_ - value_ initiatorId_ } {
    #puts "handle filename change: $value_"
	if {$targetReady_} {
		set _filename $value_
	}
}
body DCS::FullScanDefinition::handleBacklashChange {caller_ targetReady_ - value_ initiatorId_ } {
    updateRegisteredComponents -backlash
}
body DCS::FullScanDefinition::handleDeviceChange {caller_ targetReady_ - value_ initiatorId_ } {
	setListOfMotorsFromAxesDefinitions
    updateRegisteredComponents -showSpiral
}


body DCS::FullScanDefinition::handleDirectoryChange {caller_ targetReady_ - value_ initiatorId_ } {
    #puts "handleDirectory change: caller: $caller_ value: $value_"
	if {$targetReady_} {
		set _directory $value_
	}
}

body DCS::FullScanDefinition::handleFilterChange {caller_ targetReady_ - value_ initiatorId_ } {
	if {$targetReady_} {
        #get the filter name
        set label [$caller_ cget -text]
        set name [::filterLabelMap getDevice $label]

        #puts "handle filter change: $name $value_"
        if {$value_ == "open"} {
            $_filter remove $name
        } else {
            $_filter add $name
        }
	}
}


body DCS::FullScanDefinition::startScan {} {

	set scanCommand [makeScanCommand]

    if {[llength $scanCommand]} {
	    set scanMotorObject [$m_deviceFactory getObjectName scanMotor]
	    set _operationId [eval $scanMotorObject startOperation $scanCommand]
    } else {
        log_error scan not Started
    }
}

body DCS::FullScanDefinition::makeScanCommand {} {

	set motor1Name [$_motor1 getDeviceName]
	set motor2Name [$_motor2 getDeviceName]


	# make sure a scan axis was selected
	if { $motor1Name == "" && $motor2Name == "" } {
		log_error No scan axes selected!
		return
	}

    #make sure two motors are not the same
	if {$motor1Name == $motor2Name} {
		log_error Motor1 and Motor2 are the same
		return
	}

	# construct the two motor arguments
	set motorDef1 [convertMotorScanDefinitionToString $_motor1]
	set motorDef2 [convertMotorScanDefinitionToString $_motor2]
	
	# construct the detectors argument
	set detectors $_signal
	if { $_referenceSignal != ""} {
	    if {[lsearch $detectors $_referenceSignal] < 0} {
		    lappend detectors $_referenceSignal
        } else {
            log_warning duplicated $_referenceSignal removed
        }
	}
	if { $_signal3 != "" } {
	    if {[lsearch $detectors $_signal3] < 0} {
		    lappend detectors $_signal3
        } else {
            log_warning duplicated $_signal3 removed
        }
	}
	if { $_signal4 != "" } {
	    if {[lsearch $detectors $_signal4] < 0} {
		    lappend detectors $_signal4
        } else {
            log_warning duplicated $_signal4 removed
        }
	}
		
	# construct the filters argument
	set filters [$_filter get]
    #puts "filters: {$filters}"

	# construct the timing argument
	set timing [::units convertUnitValue $_integrationTime ms]
	
	lappend timing [::units convertUnitValue $_motorSettlingTime ms]

	lappend timing $_numScans

	lappend timing [::units convertUnitValue $_delayBetweenScans ms]

    #prefix for filenames
    set prefix [list $_directory $_filename $_scanNumber]
    #puts "prefix: $prefix"
	
    set user [$controlSystem getUser]
    global gEncryptSID
    if {$gEncryptSID} {
        set sessionId SID
    } else {
        set sessionId PRIVATE[$controlSystem getSessionId]
    }

    if {$m_showSpiral && $m_spiralOn} {
	    return [list $user $sessionId [list $motorDef1 $motorDef2] $detectors $filters $timing $prefix $m_spiralOn] 
    } else {
	    return [list $user $sessionId [list $motorDef1 $motorDef2] $detectors $filters $timing $prefix] 
    }
	# construct and issue the scan command
}

body DCS::FullScanDefinition::convertMotorScanDefinitionToString { motor_ } {
	set stringDefinition ""

	set motorName [$motor_ getDeviceName]
	if { $motorName != "" } {
		set units [$motor_ getUnits]

		lappend stringDefinition $motorName \
			 [$motor_ getTotalPoints]	\
			 [::units convertUnitValue [$motor_ getStartPosition] $units] \
			 [::units convertUnitValue [$motor_ getEndPosition] $units] \
			 [::units convertUnitValue [$motor_ getStepSize] $units]	\
			 $units
	}
	return $stringDefinition
}

body DCS::FullScanDefinition::setDefinition { motor1defString_ motor2defString_ detectors_ filters_ timingString_ prefixString_ {spiral_ 0} } {
    #puts "full: setDefinition for $this"

	# extract motor1's parameters
	setMotorScanDefinitionFromString $motor1defString_ $_motor1
	
	# extract motor2's parameters
	setMotorScanDefinitionFromString $motor2defString_ $_motor2

	#
	setListOfMotorsFromAxesDefinitions
    updateRegisteredComponents -showSpiral
	
	# set detectors
	foreach {_signal _referenceSignal _signal3 _signal4} $detectors_ break
    #puts "set signal to $_signal in setDefinition"
    updateRegisteredComponents -signal
    updateRegisteredComponents -referenceSignal
    updateRegisteredComponents -signal3
    updateRegisteredComponents -signal4
	
	# set filters
    $_filter clear
    eval $_filter add $filters_
	
	# extract timing information
	getTimingParametersFromString $timingString_
    updateRegisteredComponents -integrationTime
    updateRegisteredComponents -motorSettlingTime
    updateRegisteredComponents -delayBetweenScans
    updateRegisteredComponents -numScans

    # extract dir file and init counter info
    getPrefixParametersFromString $prefixString_

    set m_spiralOn $spiral_
    updateRegisteredComponents -spiralOn
}


body DCS::FullScanDefinition::loadDefinition {} {

	# prompt user for name of definition file
	set filename [tk_getOpenFile]
	
	# make sure the file selection was not cancelled
	if { $filename == {} } {
		return
	}
	
	# make sure file is readable
	if { ! [file readable $filename] } {
		log_error "File $filename is not readable."
		return
	}
	
	# open the file
	if [ catch {open $filename r} fileHandle ] {
		log_error "File $filename could not be opened."
		return
	}

	# get the scan definition information
	readScanHeader $fileHandle motor1 motor2 detectors filters timing prefix

	# close the file
	close $fileHandle

	# set the definition
	setDefinition $motor1 $motor2 $detectors $filters $timing $prefix
}



body DCS::FullScanDefinition::saveDefinition {} {

	set command [makeScanCommand]
	#puts "SCANDEF $command"

	return
	
	# prompt user for name of definition file
	set filename [tk_getSaveFile]
	
	# make sure the file selection was not cancelled
	if { $filename == {} } {
		return
	}
	
	# open scan data file
	if { [catch {set f [open $filename w ] } ] } {
		log_error "Error opening $filename."
		return
	}

	
	# write the scan definition information
	writeScanHeader \
		$f	\
		$filename \
		[lindex $command 1] \
		[lindex $command 2] \
		[lindex $command 3] \
		[lindex $command 4] \
		[lindex $command 5]
	
	# close the definition file
	close $f
}


body DCS::FullScanDefinition::writeScanHeader { fileHandle filename  motor1 motor2 detectors filters timing } {
																		 
	puts $fileHandle "# file       $filename"
	puts $fileHandle "# date       [time_stamp]"
	puts $fileHandle "# motor1     $motor1"
	puts $fileHandle "# motor2     $motor2"
	puts $fileHandle "# detectors  $detectors"
	puts $fileHandle "# filters    $filters"
	puts $fileHandle "# timing     $timing"
	puts $fileHandle "\n\n"	
}

body DCS::FullScanDefinition::parseFilename { fileName base counter ext } {
    upvar $base fnBase
    upvar $counter fnCounter
    upvar $ext fnExt

    #find extension first
    set dot_index [string last . $fileName]
    if { $dot_index == -1 } {
        set fnExt ""
        set fNoExt $fileName
    } else {
        incr dot_index
        set fnExt [string range $fileName $dot_index end]
        incr dot_index -2
        set fNoExt [string range $fileName 0 $dot_index]
    }
    #DEBUG
    #puts "ext={$fnExt} base+counter={$fNoExt}"

    #find counter
    set ll [string length $fNoExt]
    for {set i 0} {$i < $ll} {incr i} {
        set strIndex [expr $ll - $i - 1]
        set letter [string index $fNoExt $strIndex]
        if {[lsearch {0 1 2 3 4 5 6 7 8 9} $letter] < 0} {
            break
        }
    }
    set fnCounter 0
    if {$i > 0} {
        set c [string range $fNoExt end-[expr $i - 1] end]
        scan $c "%d" fnCounter
    }

    #find the filename prefix
    set fnBase [string range $fNoExt 0 end-$i]

    #takeout _ if it is at the end of prefix
    while {[string index $fnBase end] == "_"} {
        set fnBase [string range $fnBase 0 end-1]
    }
    #DEBUG
    #puts "base={$fnBase} counter={$fnCounter}"
}

body DCS::FullScanDefinition::readScanHeaderByLine { l0 l1 l2 l3 l4 l5 l6 m1 m2 d f t p } {
	
	# access variables
	upvar $m1 	motor1
	upvar $m2 	motor2
	upvar $d		detectors
	upvar $f		filters
	upvar $t		timing
	upvar $p		prefix
	
    #first line is the current file
    #new format also appended directory file_name_prefix file_name_count_init_value

    set buffer $l0
    set ll [llength $buffer]
    ##########check
    if {$ll < 3 || [lindex $buffer 0] != "\#" || [lindex $buffer 1] != "file"} {
        return -code error "not a scan file"
    }

    if { $ll == 3 } {
        #old format, no prefix and counter start value
        #we will parse it from the current file name
        set filename [lindex $buffer 2]
        set fnPrefix ""
        set fnCounter 0
        set fnExt ""
        parseFilename $filename fnPrefix fnCounter fnExt
        set prefix [list ~ $fnPrefix $fnCounter]
        #puts "parse file name prefix={$prefix}"
    } elseif { $ll >= 6 } {
        set prefix [lrange $buffer 3 5]
        #puts "new format prefix={$prefix}"
    }

    #timestamp
    set buffer $l1
	
	# read motor 1 parameters
    set buffer $l2
	set motor1 [lrange $buffer 2 7]
	
	# read motor 2 parameters
    set buffer $l3
	set motor2 [lrange $buffer 2 7]	

	# read detector parameters
    set buffer $l4
	set detectors [lrange $buffer 2 end]

	# read filter parameters
    set buffer $l5
	set filters [lrange $buffer 2 end]

	# read timing parameters
    set buffer $l6
	set timing [lrange $buffer 2 6]
}

body DCS::FullScanDefinition::readScanHeader { fileHandle m1 m2 d f t p } {
	
	# access variables
	upvar $m1 	motor1
	upvar $m2 	motor2
	upvar $d		detectors
	upvar $f		filters
	upvar $t		timing
	upvar $p		prefix
	
    #first line is the current file
    #new format also appended directory file_name_prefix file_name_count_init_value
	gets $fileHandle buffer

    set ll [llength $buffer]
    ##########check
    if {$ll < 3 || [lindex $buffer 0] != "\#" || [lindex $buffer 1] != "file"} {
        return -code error "not a scan file"
    }

    if { $ll == 3 } {
        #old format, no prefix and counter start value
        #we will parse it from the current file name
        set filename [lindex $buffer 2]
        set fnPrefix ""
        set fnCounter 0
        set fnExt ""
        parseFilename $filename fnPrefix fnCounter fnExt
        set prefix [list ~ $fnPrefix $fnCounter]
        #puts "parse file name prefix={$prefix}"
    } elseif { $ll >= 6 } {
        set prefix [lrange $buffer 3 5]
        #puts "new format prefix={$prefix}"
    }

	gets $fileHandle buffer
	
	# read motor 1 parameters
	gets $fileHandle buffer
	set motor1 [lrange $buffer 2 7]
	
	# read motor 2 parameters
	gets $fileHandle buffer
	set motor2 [lrange $buffer 2 7]	

	# read detector parameters
	gets $fileHandle buffer
	set detectors [lrange $buffer 2 end]

	# read filter parameters
	gets $fileHandle buffer
	set filters [lrange $buffer 2 end]

	# read timing parameters
	gets $fileHandle buffer
	set timing [lrange $buffer 2 6]

}

body DCS::FullScanDefinition::setMotorScanDefinitionFromString { stringDef_ motor_ } {

    puts "+setMotorDefFromString $stringDef_ $motor_"

	# extract the motor parameters
	set name 	 	[lindex $stringDef_ 0]
	set points 		[lindex $stringDef_ 1]
	set start  		[lindex $stringDef_ 2]
	set end	 		[lindex $stringDef_ 3]
	set step 	 	[lindex $stringDef_ 4]
	set units		[lindex $stringDef_ 5]

	#get the object name for the motor
	if {$name == "" } { 
		$motor_ invalidateDefinition
	} else {
        set device [$m_deviceFactory getObjectName $name] 
		if {$name == "(none)" || $name == "time" } {
            set device $name 
        }
		$motor_ setScanDefinition $device $points $start $end $step
	}
    #puts "-setMotorDefFromString"
}

body DCS::FullScanDefinition::getTimingParametersFromString { timingString_ } {
    #puts "timing $timingString_"
 	# extract the motor parameters
	foreach {_integrationTime _motorSettlingTime _numScans _delayBetweenScans units} $timingString_ break

    set _delayBetweenScans "$_delayBetweenScans $units"
    set _integrationTime "$_integrationTime s"
    set _motorSettlingTime "$_motorSettlingTime s"

    #puts "int time : $_integrationTime"
}

body DCS::FullScanDefinition::getPrefixParametersFromString { prefixString_ } {
 	# extract the motor parameters
	foreach {_directory _filename _scanNumber} $prefixString_ break
}

body DCS::FullScanDefinition::setListOfMotorsFromAxesDefinitions {} {
	#get the list of motors
	set _motorScanList ""
	
	foreach motorDef [list $_motor1 $_motor2] {
		set deviceName [$motorDef getDeviceName] 
		if { $deviceName != {} && $deviceName != "(none)"} {
			lappend _motorScanList $deviceName
		}
	}

	set _numberOfMotors [llength $_motorScanList]

    if {$_numberOfMotors == 2 && [string first time $_motorScanList] < 0} {
        set m_showSpiral 1
    } else {
        set m_showSpiral 0
    }
}

body DCS::FullScanDefinition::getListOfMotors {} {
	return $_motorScanList
}

body DCS::FullScanDefinition::getNumberOfMotors {} {
	return $_numberOfMotors
}


#compare a different scan definition object
body DCS::FullScanDefinition::isEqual { otherScanDef_ } {

    #### signal, reference ###
    set otherSignal [$otherScanDef_ getSignal]
    set otherReferenceSignal [$otherScanDef_ getReferenceSignal]
    set otherSignal3 [$otherScanDef_ getSignal3]
    set otherSignal4 [$otherScanDef_ getSignal4]
    #puts "sigal: {$_signal} {$otherSignal}"
    #puts "ref sigal: {$_referenceSignal} {$otherReferenceSignal}"
    if {$_signal != $otherSignal} {
        #puts "signal not the same: {$_signal} {$otherSignal}"
        return 0
    }
    if {$_referenceSignal != $otherReferenceSignal} {
        #puts "reference signal not the same: {$_referenceSignal} {$otherReferenceSignal}"
        return 0
    }
    if {$_signal3 != $otherSignal3} {
        #puts "signal3 not the same: {$_signal3} {$otherSignal3}"
        return 0
    }
    if {$_signal4 != $otherSignal4} {
        #puts "signal4 not the same: {$_signal4} {$otherSignal4}"
        return 0
    }

    #### timing #######
    set otherIntegrationTime [$otherScanDef_ getIntegrationTime]
    set otherMotorSettlingTime [$otherScanDef_ getMotorSettlingTime]

	set my_timing [::units convertUnitValue $_integrationTime ms]
	set other_timing [::units convertUnitValue $otherIntegrationTime ms]
    if {$my_timing != $other_timing} {
        #puts "i time not the same"
        #puts "this: $_integrationTime  $my_timing"
        #puts "other: $otherIntegrationTime $other_timing"
        return 0
    }

	set my_timing [::units convertUnitValue $_motorSettlingTime ms]
	set other_timing [::units convertUnitValue $otherMotorSettlingTime ms]
    if {$my_timing != $other_timing} {
        #puts "s time not the same"
        #puts "this: $my_timing"
        #puts "other: $other_timing"
        return 0
    }

	set otherMotor1 [$otherScanDef_ getMotor1ScanDefinition]
	set otherMotor2 [$otherScanDef_ getMotor2ScanDefinition]

	if { ! [$_motor1 isEqual $otherMotor1] } {
        #puts "motor 1 not the same"
        #puts "this: [$_motor1 dump]"
        #puts "other: [$otherMotor1 dump]"
        return 0
    }
	if { ! [$_motor2 isEqual $otherMotor2] } {
        #puts "motor 2 not the same"
        #puts "this: [$_motor2 dump]"
        #puts "other: [$otherMotor2 dump]"
        return 0
    }

	return 1
}


proc trim { string } {
     
	if { $string == "0" } { 
		return $string 
	} else {
		string trimleft $string 0
	}
}
						
proc testScanDefinition {} {

	DCS::ScanDefinition lastScanDef
	DCS::ScanDefinition newScanDef

	lastScanDef setScanDefinition ::device::table_vert_1 21 0.0 2.0 0.1
	newScanDef setScanDefinition  ::device::table_vert_2 21 0.0 2.0 0.1

	newScanDef configure -stepSizeReference {::.ss -value}
	newScanDef configure -totalPointsReference {::.p -value}
	newScanDef configure -startPositionReference {::.sp -value}
	newScanDef configure -centerPositionReference {::.cp -value}
	newScanDef configure -endPositionReference {::.ep -value}
	newScanDef configure -widthReference {::.w -value}
	
	DCS::Entry .p -promptText "Points" -alternateShadowReference {::newScanDef -totalPoints}  -entryType int -entryWidth 12 -reference "::lastScanDef -totalPoints" -activeClientOnly 0 -systemIdleOnly 0

	pack .p
	
	DCS::Entry .sp -promptText "Start Position" -unitsList "mm {-decimalPlaces 6}" -alternateShadowReference {::newScanDef -startPosition} -entryType float -units mm -entryWidth 12 -reference "::lastScanDef -startPosition" -activeClientOnly 0 -systemIdleOnly 0
	pack .sp

	DCS::Entry .cp -promptText "Center Position" -unitsList "mm {-decimalPlaces 6}" -alternateShadowReference {::newScanDef -centerPosition} -entryType float -units mm -entryWidth 12 -reference "::lastScanDef -centerPosition" -activeClientOnly 0 -systemIdleOnly 0
	pack .cp

	DCS::Entry .ep -promptText "End Position" -unitsList "mm {-decimalPlaces 6}" -alternateShadowReference {::newScanDef -endPosition} -entryType float -units mm -entryWidth 12 -reference "::lastScanDef -endPosition"  -activeClientOnly 0 -systemIdleOnly 0
	pack .ep

	DCS::Entry .w -promptText "Width" -unitsList "mm {-decimalPlaces 6}" -alternateShadowReference {::newScanDef -width} -entryType float -units mm -entryWidth 12 -reference "::lastScanDef -width"  -activeClientOnly 0 -systemIdleOnly 0
	pack .w


	DCS::Entry .ss -promptText "Step Size" -unitsList "mm {-entryType float -decimalPlaces 6} steps {-entryType int}" -alternateShadowReference {::newScanDef -stepSize} -entryType float -units mm -entryWidth 12 -reference "::lastScanDef -stepSize" -precision 0.00001
	pack .ss -activeClientOnly 0 -systemIdleOnly 0

	
	#-device ::device::gonio_phi \
	#	 -buttonBackground  #c0c0ff \
	#	 -activeButtonBackground  #c0c0ff \
	#	 -width 8

	#pack .test -fill both -expand yes

	# create the apply button
	::DCS::ActiveButton .activeButton

	pack .activeButton

	dcss connect

	
	return
}

#testScanDefinition
