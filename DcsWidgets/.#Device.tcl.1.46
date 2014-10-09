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


# provide the DCSDevice package
package provide DCSDevice 1.0

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

class DCS::Device {

    # inheritance
    inherit ::DCS::Component

    public common controlSystem ::dcss
    public variable deviceName ""
    public variable controller ""
    public variable hardwareName             ""
    public variable locked 0
    public variable status                    inactive        { updateRegisteredComponents status }

    public variable errorCode                none
    public variable undoPosition            ""
    public variable timedOut                0
    public variable timeoutCount            0
    public variable startedByPoll            0
    public variable lastResult                "normal"
   public variable devicePermissions
   public variable staffPermissions "0 1 1 1 1" {setPermissions 1 $staffPermissions} 
   public variable userPermissions "0 1 1 1 1" {setPermissions 0 $userPermissions}

    protected variable _controllerStatus "offline"

    #### String some time needs this function when
    #### its field is mapped into an Entry with units
    public method convertUnits

    public method handleControllerStatusChange
    public method getConfig
   public method checkPermissions
    public method configureDevice

   public method handleClientStateChange
   public method handleClientLocationChange
   public method handleDoorChange
   public method handleStaffChange

    protected method recalcStatus
    protected method recalcPermissions
   protected method updatePermissions
   protected method setPermissions
   protected method registerForPermissions

   protected variable m_logger

   protected variable m_clientState ""
   protected variable m_hutchState "open"
   protected variable m_location "REMOTE"
   protected variable m_staff 0
   protected variable m_permission UNKNOWN
   public method getPermission {} {return $m_permission}
   public method getPermissionMessage 

    public method waitForDevice { } {
        set vName [scope status]
        addToWaitingList $vName

        if {[catch {
            while {1} {
                switch -exact -- $status {
                    waiting -
                    moving -
                    opening -
                    closing -
                    counting -
                    calibrating -
                    child -
                    acquiring {
                        vwait $vName
                        puts "waitForDevice got $status"
                    }
                    default {
                        break
                    }
                }
            }
        } errMsg]} {
            log_error error in wating: $errMsg
        }
        removeFromWaitingList $vName
        if {$status == "aborting"} {
            set lastResult "aborted"
        }
        if {$lastResult != "normal" } {
            return -code error $lastResult
        }
    }

    # constructor
    constructor {  args } {

        # call base class constructor
        ::DCS::Component::constructor {
            status     {cget -status}
            permission {getPermission}
        }
    } {
        set m_logger [DCS::Logger::getObject]

        # trim the namespace qualifications to the $this variable value
        set start [expr [string last : $this] + 1]         
        set deviceName [string range $this $start end]
        
        eval configure $args
        setPermissions 1 $staffPermissions
        setPermissions 0 $userPermissions
 
        registerForPermissions
    }
}

body DCS::Device::convertUnits { value_ fromUnits_ toUnits_ } {
    return [::units convertUnits $value_ $fromUnits_ $toUnits_]
}

body DCS::Device::setPermissions { staff_ permissions_ } {

   if {$permissions_ == ""} return

    set devicePermissions($staff_,passiveOk) [lindex $permissions_ 0]
   set devicePermissions($staff_,remoteOk) [lindex $permissions_ 1]
    set devicePermissions($staff_,localOk) [lindex $permissions_ 2]
    set devicePermissions($staff_,inHutchOk) [lindex $permissions_ 3]
    set devicePermissions($staff_,closedHutchOk) [lindex $permissions_ 4]

    if {[info exists devicePermissions(0,passiveOk)] && \
    [info exists devicePermissions(1,passiveOk)]} {
        updatePermissions
    }
}

body DCS::Device::registerForPermissions {} {

   ::mediator register $this ::dcss clientState handleClientStateChange 
   ::mediator register $this ::dcss location handleClientLocationChange 
   ::mediator register $this ::dcss staff handleStaffChange
   if { $this == "::device::hutchDoorStatus" } return
   ::mediator register $this [DCS::HutchDoorState::getObject] state handleDoorChange 
}

body DCS::Device::handleClientStateChange {- targetReady_ alias value -} {

    if { ! $targetReady_ } return

    set m_clientState $value
    updatePermissions
}

body DCS::Device::handleClientLocationChange {- targetReady_ alias value -} {

    if { ! $targetReady_ } return

    set m_location $value
    updatePermissions
}


body DCS::Device::handleDoorChange {- targetReady_ alias value -} {

    if { ! $targetReady_ } return

    set m_hutchState $value
    updatePermissions
}

body DCS::Device::handleStaffChange {- targetReady_ alias value -} {

    if { ! $targetReady_ } return

    set m_staff $value
    updatePermissions
}

body DCS::Device::updatePermissions {} {
   set m_permission [recalcPermissions]
   updateRegisteredComponents permission
}

body DCS::Device::recalcPermissions {} {

    #inform user that they have no permissions
    if { $devicePermissions($m_staff,remoteOk) == "" } { return }
    if { $devicePermissions($m_staff,localOk) == "" } { return }  
    if { $devicePermissions($m_staff,inHutchOk) == "" } { return }
    if { $devicePermissions($m_staff,closedHutchOk) == "" } { return }


    #first reject inconsistent states.
    if { $m_hutchState == "closed" && $m_location == "HUTCH" } {
        return IN_HUTCH_AND_DOOR_CLOSED;
    }

    #inform user that they have no permissions
    if { ! $devicePermissions($m_staff,remoteOk) && 
          ! $devicePermissions($m_staff,localOk) && 
          ! $devicePermissions($m_staff,inHutchOk) &&
          ! $devicePermissions($m_staff,closedHutchOk) } {
      return NO_PERMISSIONS;
   }

    #inform the user that they are not active/master
    if { ! $devicePermissions($m_staff,passiveOk) && $m_clientState != "active" } {
        return NOT_ACTIVE_CLIENT;
    }
 
    #check for special cases when hutch door is open
    if { $m_hutchState == "open" || $m_hutchState == "unknown" } {            
      if { $m_location == "REMOTE" &&
              ! $devicePermissions($m_staff,remoteOk) } {
           return HUTCH_OPEN_REMOTE;
        }
        
        if { $m_location == "LOCAL" &&
              ! $devicePermissions($m_staff,localOk) } {
            return HUTCH_OPEN_LOCAL;
        }
        
        if { $m_location == "HUTCH" &&
              ! $devicePermissions($m_staff,inHutchOk) } {
            return IN_HUTCH_RESTRICTED;
        }
    } else {
        #Hutch door is closed
        if { ! $devicePermissions($m_staff,closedHutchOk) } {
            return HUTCH_DOOR_CLOSED;
        }
    }

    #if we are here than the user can interact with the device.
    return GRANTED;
}

body DCS::Device::getPermissionMessage {} {
   switch $m_permission {
      IN_HUTCH_AND_DOOR_CLOSED {return "Please open the hutch door if you are inside the hutch!"}
      NO_PERMISSIONS {return "This account has no permissions to use this device directly."}
      NOT_ACTIVE_CLIENT {return "This client must be active to use this device."}
      HUTCH_OPEN_REMOTE {return "The hutch door is open and this client is remote."}
      HUTCH_OPEN_LOCAL {return "The hutch door is open and this client is not inside the hutch."}
      IN_HUTCH_RESTRICTED {return "You should not be in the hutch when using this device."}
      HUTCH_DOOR_CLOSED {return "This device can only be controlled from inside the hutch."}
      default {return $m_permission}
   }
}

configbody DCS::Device::controller {
    if { $controller != "" } {
        ::mediator register $this ::device::$controller status handleControllerStatusChange 
    }
}

body DCS::Device::configureDevice {controller_ } {

}

body DCS::Device::handleControllerStatusChange {- targetReady_ alias value -} {

    if { ! $targetReady_ } return

    set _controllerStatus $value
    recalcStatus
}

body DCS::Device::getConfig {} {
    return DCS::Device
}

body DCS::Device::recalcStatus { } {
    if { $_controllerStatus == "offline" } {
        configure -status offline
    } elseif { $locked } {
        configure -status locked
    } else {
        configure -status inactive
    }
    
    updateRegisteredComponents status
}


class DCS::Motor {
    
    # inheritance
    inherit DCS::Device

    # public variables

    protected variable _moving 0 

    public variable scaledPosition    1.0 {
      updateRegisteredComponents positionNoUnits
      updateRegisteredComponents scaledPosition 
      updateRegisteredComponents -value
   }
    public variable lowerLimit     -100.0
    public variable upperLimit      100.0
    public variable lowerLimitOn      1
    public variable upperLimitOn      1
    public variable locked 1
    public variable inMotion 0 { updateRegisteredComponents inMotion }

    # All values reported to other components will be in 'baseUnits' (mm,deg,eV)
    # This value will also be used to handle moves in other units.
    public variable baseUnits mm

    # public methods
    public method move {prep destination {units ""}}
    public method getScaledPosition {} { return [list $scaledPosition $baseUnits] }
    public method getEffectiveUpperLimit {} { return [list $upperLimit $baseUnits]}
    public method getEffectiveLowerLimit {} { return [list $lowerLimit $baseUnits] }

    public method getUpperLimit {} { return [list $upperLimit $baseUnits]}
    public method getLowerLimit {} { return [list $lowerLimit $baseUnits] }

    public method getLockOn {} { return $locked }
    public method getConfig {}
    #this getMotorConfiguration return properties match input of
    #changeMotorConfiguration
    public method getMotorConfiguration

    public method moveStarted {destination status}
    public method moveCompleted {position status}
    public method positionUpdate {position status}
    public method configureDevice

    protected method recalcStatus

    public method setLimits { upperLimit lowerLimit }
    public method getLowerLimitOn {} {return $lowerLimitOn} 
     public method getUpperLimitOn {} {return $upperLimitOn}
    public method getMotorType {} {return pseudo}
    ### setScaledPosition only configure the position
    public method setScaledPosition { position_in_base_units }
    public method changeMotorConfiguration
    public method convertToBaseUnits
    public method getRecommendedUnits

    public variable minimumStepSize 0.001
    
    #variable for holding messages regarding this device
    public method getRecommendedPrecision

    public method limits_ok { posREF {even_limits_off 0}} {
        upvar $posREF pos

        set uL [getEffectiveUpperLimit]
        set lL [getEffectiveLowerLimit]

        set uL [lindex $uL 0]
        set lL [lindex $lL 0]

        if {![string is double -strict $pos]} {
            set pos $lL
            return 0
        }


        if {$pos > $uL && ($upperLimitOn || $even_limits_off)} {
            set pos $uL
            return 0
        }
        if {$pos < $lL && ($lowerLimitOn || $even_limits_off)} {
            set pos $lL
            return 0
        }
        return 1
    }


    public method calculateMinimumDecimalPlacesFromMinimumStepSize
    private method stepSize

    public method saveUndo { } {
        set undoPosition $scaledPosition
    }
    public method getUndoPosition { } {
        return "$undoPosition $baseUnits"
    }

    public variable childrenDevices {}
    public method handleChildrenStatusChange
    public variable parentDevices {}
    private variable _childrenStatus 1
    
    public method getBlockingChild
    private variable _blockingChild ""

    private variable _childrenDevices


    # call base class constructor
    constructor { args } {

        # call base class constructor
        ::DCS::Component::constructor \
             { \
                     status                 {cget -status} \
                     inMotion                 {cget -inMotion} \
                     scaledPosition    {getScaledPosition} \
                     -value    {getScaledPosition} \
                     lowerLimit            {getLowerLimit} \
                     upperLimit            {getUpperLimit} \
                     limits           {getConfig} \
                     lowerLimitOn {getLowerLimitOn} \
                     upperLimitOn {getUpperLimitOn} \
                     lockOn {getLockOn} \
                     positionNoUnits { cget -scaledPosition } \
                     deviceMessage {} \
                permission {getPermission}
             }
    } {
        

        set _childrenDevices [namespace current]::[::DCS::ComponentGate \#auto]
        #register addInput "$::DCS::MotorConfigWidget::_unappliedChanges gateOutput 0 {First make changes to a motor entry.}"
        
        eval configure $args

        
        announceExist
    }
    
    destructor {
    }
}

body DCS::Motor::setScaledPosition { position_in_base_units_ } {
    changeMotorConfiguration \
    $position_in_base_units_ \
    $upperLimit \
    $lowerLimit \
    $lowerLimitOn \
    $upperLimitOn \
    $locked
}

body DCS::Motor::configureDevice { message } {
    
        #parse the message
    foreach { dummy motor controller hardwareName position \
                      upperLimit lowerLimit lowerLimitOn upperLimitOn locked_ status_ } $message {break}
    
    configure -controller $controller
    configure -scaledPosition $position
    configure -hardwareName $hardwareName    
    configure -upperLimit $upperLimit -lowerLimit $lowerLimit
    configure -lowerLimitOn $lowerLimitOn
    configure -upperLimitOn $upperLimitOn
    configure -locked $locked_

   #$m_logger logNote "$motor configured:  position: $position, upper limit: $upperLimit, lowerLimit: $lowerLimit, DHS: $controller" 

   #initialize the undo position   
   if {$undoPosition == "" } {
      saveUndo
   }

    set _moving $status_

    #inform that new configuration is available
    updateRegisteredComponents limits
    
    recalcStatus
}


body DCS::Motor::moveStarted { destination newStatus } {
    
    set _moving 1
   configure -inMotion 1
    recalcStatus
}


body DCS::Motor::moveCompleted { position status_ } {
    set _moving 0
   configure -inMotion 0 

    set lastResult $status_
    
    switch $status_ {
        normal {
            $m_logger logNote "Move of motor $deviceName completed normally at $position."
        }

        motor_active {
            $m_logger logError "Motor $deviceName already moving."
        }
    
        cw_hw_limit {
            $m_logger logError "Motor $deviceName hit clockwise hardware limit."
        }
    
        ccw_hw_limit {
            $m_logger logError "Motor $deviceName hit counterclockwise hardware limit."
        }

        both_hw_limits {
            $m_logger logError "Motor $deviceName hit both hardware limits."
            $m_logger logError "Check hardware reset button (green button)."
        }

        sw_limit {
            $m_logger logError "Motor move would exceed software limit."
        }
        no_hw_host {
            $m_logger logError "Hardware host for motor $deviceName not connected."
        }

        hutch_open_remote {
            $m_logger logError "Hutch door must be closed to move $deviceName from remote console."
        }

        hutch_open_local {
            $m_logger logError "Hutch door must be closed to move $deviceName from local console."
        }

        in_hutch_restricted {
            $m_logger logError "User may not be in the hutch to move $deviceName."
        }

        in_hutch_and_door_closed {
            $m_logger logError "Hutch door must be open to use console in hutch."
        }

        no_permissions {
            $m_logger logError "User has no permissions to use $deviceName."
        }

        hutch_door_closed {
            $m_logger logError "User must be in the hutch to use $deviceName."
        }

        default {
            $m_logger logError "Motor $deviceName reported: $status_."
        }
    }

    configure -scaledPosition $position
    recalcStatus
}

body DCS::Motor::positionUpdate { position newStatus } {
    configure -scaledPosition $position

    #need implementation for child-parent motors
    #blu-ice may be started while motor moving already started
    #if {!$_moving} {
    #    set _moving 1
    #    recalcStatus
    #}
}


body DCS::Motor::getConfig {} {
    return [list DCS::PseudoMotor $locked \
    [getUpperLimit] [getLowerLimit] \
    $upperLimitOn $lowerLimitOn \
    [getEffectiveUpperLimit] [getEffectiveLowerLimit] ]
}


body DCS::Motor::move { prep destination {units ""} } {

    	puts "$deviceName move"

    # make sure motor isn't locked
    if { $locked } {
        $m_logger logError "Motor $deviceName is locked and cannot be moved."
        return
    }

    	# permission check
    	if {$m_permission != "GRANTED"} {
        	set msg [getPermissionMessage]
        	$m_logger logError $msg
        	return  -code error $msg
    	}

    	#clear lastResult
    	set lastResult normal
  	puts "yang12" 
	#yangb
	if {$destination == "home"} {
		set convertedDestination "home"
	} else {
		
		 #clear lastResult 
    		set lastResult normal 
    		if {$units == ""} {
        		set units $baseUnits
    		}	

		set convertedDestination [::units convertUnits $destination $units $baseUnits]
		#puts "MOTOR: $destination $units == $convertedDestination $baseUnits"
	
		switch $prep {
			by { set convertedDestination [expr $convertedDestination + $scaledPosition]  }
			to {}
			default {return -code error "Bad preposition: $prep.  Should be 'by' or 'to'"}
		}
	}
	#yange
	# make sure motor is not already moving
	switch $status {
		inactive { }
		moving {
       		    $m_logger logError "Motor $deviceName is already moving."
           		return
        	}	
		offline {$m_logger logError "DHS is offline."
	        	return
        		}
		}

	# set the undo message
    	saveUndo
		
	# request server to start the move
	$controlSystem sendMessage "gtos_start_motor_move $deviceName $convertedDestination"

    set _moving 1
    recalcStatus
}



configbody DCS::Motor::upperLimit {
    updateRegisteredComponents upperLimit
}

configbody DCS::Motor::lowerLimit {
    updateRegisteredComponents lowerLimit
}

configbody DCS::Motor::upperLimitOn {
    updateRegisteredComponents upperLimitOn
}

configbody DCS::Motor::lowerLimitOn {
    updateRegisteredComponents lowerLimitOn
}

configbody DCS::Motor::locked {
    updateRegisteredComponents lockOn
}
body DCS::Motor::getMotorConfiguration {} {
    return [list $scaledPosition $upperLimit $lowerLimit $lowerLimitOn $upperLimitOn $locked]
}

body DCS::Motor::changeMotorConfiguration { position_ upperLimit_ lowerLimit_ lowerLimitOn_ upperLimitOn_ locked_ } {

    # make sure motor is not moving
    switch $status {
        inactive {}
        moving {
            $m_logger logError "Motor $deviceName is moving."
            return -code error "Motor $deviceName is moving."
        }
        offline {
            $m_logger logError "DHS is offline."
            return -code error "DHS is offline."
        }
    }
    
    # request server to change the motor configuration
    $controlSystem sendMessage "gtos_configure_device $deviceName $position_ $upperLimit_ $lowerLimit_ $lowerLimitOn_ $upperLimitOn_ $locked_"

}


body DCS::Motor::recalcStatus { } {

    if { $_controllerStatus == "offline" } {
        configure -status offline
    } elseif { $lastResult == "not_connected" } {
        configure -status not_connected
    } elseif { $_childrenStatus == 0 } {
        configure -status child
    } elseif { $locked } {
        configure -status locked
    } elseif { $_moving } {
        configure -status moving
    } else {
        configure -status inactive
    }
    
    updateRegisteredComponents status
}



configbody DCS::Motor::childrenDevices {
    if { $childrenDevices != "" } {
        ::mediator register $this $_childrenDevices gateOutput handleChildrenStatusChange 

        foreach child $childrenDevices {
            $_childrenDevices addInput "$child status inactive {supporting device}"
        }
    }
}

body DCS::Motor::handleChildrenStatusChange {child_ targetReady_ - value_ -} {
    if {! $targetReady_ } return

    #puts "MOTOR child $child_ status $value_"
    set _childrenStatus $value_

    if { $_childrenStatus == 0 } {
        set reason [$child_ getOutputMessage]
        set _blockingChild [lindex $reason 1]
    }

    recalcStatus
}

#public method getChildrenStatusMessage

#body DCS::Motor::getChildrenStatusMessage {} {

#   if {$status != "CHILD" } return
 
#   set object [getBlockingChild]
#    set childStatus [$object cget -status]

#    set blocker [$object getBlockingChild]
#   while {$childStatus == "child" } {
#       set childStatus [$object cget -status]
#        set blocker [$object getBlockingChild]
        #split the blocker into the object and its attribute
#        foreach {object attribute} [split $blocker ~] break
#    }
#}

body DCS::Motor::getBlockingChild {} {return $_blockingChild}

body DCS::Motor::convertToBaseUnits { value_ fromUnits_ } {
    #RealMotor will override convertUnits to deal with steps
    return [convertUnits $value_ $fromUnits_ $baseUnits]
}

body DCS::Motor::getRecommendedUnits { } {
    return [::units getConversionsForUnits $baseUnits]
}


#returns the recommended precision for the motor represented in different units 
body DCS::Motor::getRecommendedPrecision { units_ } {

    switch $units_ {
        eV {set convertedStepSize 0.01}
        keV {set convertedStepSize 0.00001}
        A {set convertedStepSize 1.37755099994e-05}
        default {
            set convertedStepSize [convertUnits [stepSize] $baseUnits $units_]
        }
    }
    
    set decimalPlaces [calculateMinimumDecimalPlacesFromMinimumStepSize $convertedStepSize]

    set precision [expr double($convertedStepSize) / 2 ]

    return [list $decimalPlaces $precision]
}


body DCS::Motor::calculateMinimumDecimalPlacesFromMinimumStepSize { stepSize_ } {
    if { [catch {set decimalPlaces [expr int(log10([expr 1.0 / $stepSize_])) + 1]} errorResult ]} {
        set decimalPlaces 1
    }
    
    if {$decimalPlaces < 1} {set decimalPlaces 1}

    return $decimalPlaces
}

body DCS::Motor::stepSize { } {
    return $minimumStepSize
}



class DCS::RealMotor {

    # inheritance
    inherit DCS::Motor

    # public variables
    public variable unscaledPosition        0
    public variable scaleFactor            1.0    
    public variable speed                    0
    public variable acceleration            0
    public variable backlash                0
    public variable backlashOn                0
    public variable reverseOn                0

    # public methods
    public method getEffectiveUpperLimit
    public method getEffectiveLowerLimit
    public method getConfig {}
    #this getMotorConfiguration return properties match input of
    #changeMotorConfiguration
    public method getMotorConfiguration
    public method move

    public method configureDevice


     public method getScaleFactor {} {return [list $scaleFactor steps/$baseUnits]}
     public method getSpeed {} {return [list $speed steps/sec]}
     public method getReverseOn {} {return $reverseOn}
     public method getAcceleration {} {return [list $acceleration ms]}
     public method getBacklash {} {return [list $backlash steps]}
     public method getBacklashOn {} {return $backlashOn}
    public method getMotorType {} {return real}
    ### setScaledPosition only configure the position
    public method setScaledPosition { position_in_base_units }
    public method changeMotorConfiguration
    public method convertUnits

    public method getReasonableUnitsList
    public method getRecommendedUnits

    private method stepSize

    # call base class constructor
    constructor { args } {

        # call base class constructor
        ::DCS::Component::constructor \
             { \
                     status                 {cget -status} \
                     scaledPosition    {getScaledPosition} \
                     -value    {getScaledPosition} \
                     lowerLimit            {getLowerLimit} \
                     upperLimit            {getUpperLimit} \
                     backlash            {getBacklash} \
                     backlashOn            {getBacklashOn } \
                     limits           {getConfig} \
                     scaleFactor {getScaleFactor} \
                     speed {getSpeed} \
                     acceleration {getAcceleration} \
                     reverseOn            { getReverseOn } \
                permissions {getPermission}
             }
    } {
        eval configure $args
    }
}

body DCS::RealMotor::configureDevice { message } {
    
    foreach { dummy motor controller hardwareName \
                      position upperLimit lowerLimit scaleFactor speed_ acceleration_ backlash_ \
                      lowerLimitOn upperLimitOn locked_ backlashOn_ reverseOn_ status_} $message {break}

    configure -controller $controller
    configure -scaledPosition $position
    configure -hardwareName $hardwareName
    configure -lowerLimit $lowerLimit
    configure -upperLimit $upperLimit
    configure -locked $locked_
    configure -lowerLimitOn $lowerLimitOn
    configure -upperLimitOn $upperLimitOn
    configure -scaleFactor $scaleFactor
    configure -acceleration $acceleration_
    configure -upperLimit $upperLimit -lowerLimit $lowerLimit

    configure -backlash $backlash_
    configure -backlashOn $backlashOn_
    configure -reverseOn $reverseOn_

    configure -speed $speed_
    
   #initialize the undo position   
   if {$undoPosition == "" } {
      set undoPosition $scaledPosition
   }

   #$m_logger logNote "$motor configured:  position: $position, scaleFactor: $scaleFactor, upper limit: $upperLimit, lowerLimit: $lowerLimit, DHS: $controller" 

    set _moving $status_

    updateRegisteredComponents limits

    recalcStatus
}


body DCS::RealMotor::getConfig {} {
    return [list DCS::RealMotor $locked \
    [getUpperLimit] [getLowerLimit] \
    $upperLimitOn $lowerLimitOn \
    [getEffectiveUpperLimit] [getEffectiveLowerLimit] \
    $scaleFactor $backlash $backlashOn $reverseOn $speed $acceleration]
}

body DCS::RealMotor::getEffectiveLowerLimit {} {

    # handle effects of backlash if enabled
    if { $backlashOn && $backlash > 0 } {

        set limit [expr $lowerLimit + double($backlash) /  $scaleFactor ]

    } else {

        set limit $lowerLimit

    }

    # correct for roundoff issue
    return [list [expr $limit + (1.0 / $scaleFactor) ] $baseUnits]
}

body DCS::RealMotor::getEffectiveUpperLimit {} {

    # handle effects of backlash if enabled
    if { $backlashOn && $backlash < 0 } {
        set limit [expr $upperLimit + double($backlash) /  $scaleFactor ]
    } else {
        set limit $upperLimit
    }
    return [list [expr $limit - (1.0 / $scaleFactor) ] $baseUnits]
}

body DCS::RealMotor::move { prep destination {units ""} } {

	#puts "yang11b"
	# make sure motor isn't locked
	if { $locked } {
		$m_logger logError "Motor $this is locked and cannot be moved."
		return
	}
    	# permission check
    	if {$m_permission != "GRANTED"} {
        	set msg [getPermissionMessage]
        	$m_logger logError $msg
        	return  -code error $msg
    	}

    	#clear lastResult
    	set lastResult normal

        #yangb
	#puts "yang11"

        if {$destination == "home"} {
                set convertedDestination "home"
		#puts "yang convertedDestination=$convertedDestination"
	} else {
    		if {$units == ""} {
        		set units $baseUnits
    		}
	
		if { $units == "steps" } {
			set convertedDestination [expr $destination / $scaleFactor]
		} else {
			set convertedDestination [::units convertUnits $destination $units $baseUnits]
			#puts "REALMOTOR: $destination $units == $convertedDestination $baseUnits"
		}	
	
		switch $prep {
			by { set convertedDestination [expr $convertedDestination + $scaledPosition]  }
			to {}
			default {return -code error "Bad preposition: $prep.  Should be 'by' or 'to'"}
		}	
	}

	# make sure motor is not already moving
	switch $status {
		inactive { set status moving }
		moving {
            		$m_logger logError "Motor $deviceName is already moving."
            		return
        	}
		offline {
            		$m_logger logError "DHS is Offline"
            		return 
        	}
	}

    # remember the undo position
    set undoPosition $scaledPosition
        
    # request server to start the move
    $controlSystem sendMessage "gtos_start_motor_move $deviceName $convertedDestination"

    set _moving 1
    recalcStatus
}


configbody DCS::RealMotor::scaleFactor {
    updateRegisteredComponents scaleFactor
}

configbody DCS::RealMotor::speed {
    updateRegisteredComponents speed
}

configbody DCS::RealMotor::backlash {
    updateRegisteredComponents backlash
}

configbody DCS::RealMotor::acceleration {
    updateRegisteredComponents acceleration
}

configbody DCS::RealMotor::backlashOn {
    updateRegisteredComponents backlashOn
}

configbody DCS::RealMotor::reverseOn {
    updateRegisteredComponents reverseOn
}

body DCS::RealMotor::getMotorConfiguration {} {
    return [list $scaledPosition $upperLimit $lowerLimit $scaleFactor $speed $acceleration $backlash $lowerLimitOn $upperLimitOn $locked $backlashOn $reverseOn]
}
body DCS::RealMotor::setScaledPosition { position_in_base_units_ } {
    changeMotorConfiguration \
    $position_in_base_units_ \
    $upperLimit \
    $lowerLimit \
    $scaleFactor \
    $speed \
    $acceleration \
    $backlash \
    $lowerLimitOn \
    $upperLimitOn \
    $locked \
    $backlashOn \
    $reverseOn
}
body DCS::RealMotor::changeMotorConfiguration    { position_ upperLimit_ lowerLimit_ scaleFactor_ speed_ acceleration_ backlash_ lowerLimitOn_ upperLimitOn_ locked_ backlashOn_ reverseOn_ } {

    # make sure motor is not moving
    switch $status {
        inactive {}
        moving {
            $m_logger logError "Motor $deviceName is moving."
            return -code error "Motor $deviceName is moving."
        }
        offline {
            $m_logger logError "DHS is offline."
            return -code error "DHS is offline."
        }
    }
    
    # request server to change the motor configuration
    $controlSystem sendMessage "gtos_configure_device $deviceName $position_ $upperLimit_ $lowerLimit_ $scaleFactor_ $speed_ $acceleration_ [expr int($backlash_)] $lowerLimitOn_ $upperLimitOn_ $locked_ $backlashOn_ $reverseOn_"
}

body DCS::RealMotor::convertUnits { value_ fromUnits_ toUnits_ } {
    
    #puts "REALMOTOR: VALUE $value_ FROM $fromUnits_ TO $toUnits_"

    if {$fromUnits_ == $toUnits_} {return $value_}

    if { $toUnits_ == "steps" } {
        set steps [::units convertUnits $value_ $fromUnits_ $baseUnits ]
        return [expr round($steps * $scaleFactor) ]
    } elseif { $fromUnits_ == "steps" } {
        set scaledValue [expr double($value_) / double($scaleFactor) ]
        return [::units convertUnits $scaledValue $baseUnits $toUnits_ ]
    } else {
        #use the default units converter
        return [::units convertUnits $value_ $fromUnits_ $toUnits_]
    }
}

body DCS::RealMotor::stepSize { } {
    return [expr 1.0 / $scaleFactor]
}

body DCS::RealMotor::getRecommendedUnits { } {
    set possibleUnits [::units getConversionsForUnits $baseUnits]
    lappend possibleUnits steps
    return $possibleUnits
}

class DCS::Shutter {

    # inheritance
    inherit DCS::Device
    
    public variable state    closed
    
    public method toggle
    public method open
    public method close

    public method reported { new_state } {
        configure \
        -state $new_state \
        -status inactive
    }

    # call base class constructor
    constructor { args } {

        # call base class constructor
        ::DCS::Component::constructor \
             { \
                     status         {cget -status} \
                     state        {cget -state} \
                     permission {getPermission} \
                 }
    } {
        eval configure $args
        announceExist
    }
}

body ::DCS::Shutter::toggle {} {
    switch $state {
        closed {    open }
        default { close }
    }
}

body ::DCS::Shutter::open {} {
    $controlSystem sendMessage "gtos_set_shutter_state $deviceName open"
    configure -status opening
}

body ::DCS::Shutter::close {} {
    $controlSystem sendMessage "gtos_set_shutter_state $deviceName closed"
    configure -status closing
}


configbody ::DCS::Shutter::state {
   $m_logger logNote "$deviceName $state" 
   updateRegisteredComponents state
}

class DCS::IonChamber {
    # inheritance
    inherit DCS::Device

    public variable ionChamberResult normal
    public variable counts 0
    public variable cps 0

    #called by message_handler: DcsProtocol
    public method reported { time args }

    #called by scripts
    #currently gtos_read_ion_chamber is not broadcased as stog_XXX
    public method started { }

    public method read { time } {
        if {$status != "inactive"} {
            log_error "Still waiting for previous $deviceName activity to complete"
            log_error current status $status
            return -code error "Still waiting for previous $deviceName activity to complete"
        }
        $controlSystem sendMessage "gtos_read_ion_chambers $time 0 $deviceName"
        started
    }

    public method getCounts { } { return $counts }

    constructor { args } {
        # call base class constructor
        ::DCS::Component::constructor \
             { \
                     status                 {cget -status} \
                     -value    {getCounts} \
                     permission {getPermission} \
             }
    } {
        eval configure $args
        announceExist
    }
    
    destructor {
    }
}
body DCS::IonChamber::started { } {
    set lastResult normal
    set ionChamberResult normal
    set counts 0
    set cps 0
    configure -status counting
}
body DCS::IonChamber::reported { time result } {
    if {$time <= 0} {
        set counts 0
        set cps 0
        set ionChamberResult $result
        log_error ion chamber $deviceName reading error: $result
    } else {
        set counts $result
        catch {set cps [expr int($counts / $time)]}
        set ionChamberResult normal
    }
    set lastResult normal
    configure -status inactive
    updateRegisteredComponents -value
}
class DCS::Encoder {
    # inheritance
    inherit DCS::Device

    public variable position

    #called by message_handler: DcsProtocol
    public method completed { position_ status_ } {
        set lastResult $status_
        if {$lastResult == "normal"} {
            set position $position_
        } else {
            log_error "Error $deviceName: $lastResult"
        }
        configure -status inactive
        updateRegisteredComponents -value
    }

    #called by scripts
    #currently gtos_read_ion_chamber is not broadcased as stog_XXX
    public method get_position { } {
        if {$status != "inactive"} {
            log_error "Still waiting for previous $deviceName activity to complete"
            return -code error "Still waiting for previous $deviceName activity to complete"
        }
        $controlSystem sendMessage "gtos_get_encoder $deviceName"
        configure -status acquiring
    }
    public method set_position { new_position } {
        if {$status != "inactive"} {
            log_error "Still waiting for previous $deviceName activity to complete"
            return -code error "Still waiting for previous $deviceName activity to complete"
        }
        $controlSystem sendMessage "gtos_set_encoder $deviceName $new_position"
        configure -status calibrating
    }

    constructor { args } {
        # call base class constructor
        ::DCS::Component::constructor \
             { \
                     status                 {cget -status} \
                     -value    {cget -position} \
                     permission {getPermission} \
             }
    } {
        eval configure $args
        announceExist
    }
    
    destructor {
    }
}
