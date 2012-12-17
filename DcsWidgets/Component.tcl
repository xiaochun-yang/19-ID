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
package provide DCSComponent 1.0

# load local packages
package require DCSSet
package require DCSUtil

##########################################################################
#
# objectMediator
#
# Allows objects to specify interest in Component objects that don't exist yet
#
class objectMediator {

	# private data
	private variable _registrationRequests
	private variable futureRequests
	private variable unmatchedTarget
	private variable _debugOn 0

	private variable _initiatorId 1

	# public methods
	public method register { lstnr target attribute callback {alias ""} }
	public method unregister { lstnr target attribute }
	public method announceExistence { newObject }
	public method announceDestruction { destroyedObject }
	public method printStatus { }
	public method getUniqueInitiatorId {} { incr _initiatorId ; return $_initiatorId}

	# constructor
	constructor { args } {}

	# destructor
	destructor { }
}

##########################################################################
# 
# objectMediator::register
#
# This method is used to indicate interest in future updates of an 
# attribute of the "object".  The caller must pass the name of the
# object to which updates should be directed.  The object of interest
# need not exist yet.  Furthermore, the object that is registering for
# interest must announce its existence before the registration actually
# takes place.
#
body objectMediator::register {lstnr target attribute callback {alias ""} } {

	if { $alias == "" } { set alias ${target}~$attribute }

	if { $_debugOn} {puts "!!!!!!!!!!!!!!!!!!!!!!!!! lstnr: $lstnr target: $target $attribute"}

	if { ![info exists ${lstnr}(ready)] } {

		#Have not received a request from this lstnr before
		#We will assume it is not ready to handle updates yet, as it
		#may still be in its constructor.
		#The announceExistence function will set the ready flag to a 1.
		set ${lstnr}(ready) 0
		set futureRequests($lstnr) ""
	}
	

	if { [set ${lstnr}(ready)] == "0" } {
		#The lstnr isn't ready to receive updates yet.
		#puts "CCCC: $lstnr  [set ${lstnr}(ready)]"


		lappend futureRequests($lstnr) [list $target $attribute $callback $alias]
		return
	} 

	set newRequest [list $lstnr $attribute $callback $alias]
	if { ! [info exist _registrationRequests($target) ] } {
		#first request for a new target
		lappend _registrationRequests($target) $newRequest
	} elseif { [lsearch $_registrationRequests($target) $newRequest] == -1 } {
		#another registration  for a target
		lappend _registrationRequests($target) $newRequest
	}
	
	if { [info command $target] != "" } {
		#the object of interest exists
		if { [info exist ${target}(ready)] } {
			if { [set ${target}(ready)] == "1" } {
				#the object is ready to receive registrations
				
				if { $_debugOn} {puts "$lstnr REGISTERING DIRECTLY WITH $target $attribute"}
				$target register $lstnr $attribute $callback $alias
				
				array unset unmatchedTarget $target
				
				return
			}
		}
	}
	
	#The object of interest isn't ready yet. Remember and
	#wait for announcement of its existence.

	# let the listener know that the object doesn't exist yet.
	$lstnr $callback $target 0 $alias "$target does not exist." ""

	#puts "$target NOT ready yet"
	lappend unmatchedTarget($target)
}

body objectMediator::announceExistence { object } {
	
	#The object is now ready to handle registrations and accept 
	#updates from components that it has registered with.
	set ${object}(ready) 1

	#First complete all of the registrations that this
	#new object has already declared interest in.
	if { [info exists futureRequests($object)] } {
		
		if { $_debugOn} {puts "$object can register with other objects now"}

		foreach request $futureRequests($object) {
			foreach {target attribute callback alias} $request {break}
			
			register $object $target $attribute $callback $alias
		}

		#now that the object is ready, we can forget
		array unset futureRequests $object
	}

	#Now complete all registrations for objects that were
	#interested in this object before it existed.
	if { [info exists _registrationRequests($object)] } {

		foreach request $_registrationRequests($object) {
			foreach {lstnr attribute callback alias} $request {}

			register $lstnr $object $attribute $callback $alias
		}
	}
}

body objectMediator::announceDestruction { object } {
	
	#The object is no longer exists and the mediator should
	#delete all of its registration requests
	set ${object}(ready) 0

	#First remove all of the registrations that this
	#new object has already declared interest in.
	array unset futureRequests $object

	#Now inform all listeners that this object is destroyed
	if { [info exists _registrationRequests($object)] } {
		foreach request $_registrationRequests($object) {
			foreach {lstnr attribute callback alias} $request break

			#puts "CCCC: $lstnr $attribute $callback $alias"
			
			set temp [set ${lstnr}(ready)]

			if { $temp } {
				if { [info commands $lstnr] != "" } {
					# let the listener know that the object doesn't exist anymore.
					$lstnr $callback $object 0 $alias "$object does not exist" ""
				}
			}
		}
		unset _registrationRequests($object)
	}

	
	#Now unregister from everything that this object was interested in
	#This is the most inefficient step in unregistration.  A search
	#is need through all of the target's registrations to see if
	#this destroyed object was registered.
	foreach target [array names _registrationRequests] {
		foreach request $_registrationRequests($target) {
			foreach {lstnr attribute callback alias} $request {}
			if { $lstnr == $object } {
				#unregister this request
				#puts "CCCC:  $lstnr is unregistering in interest in $target $attribute"
				::mediator unregister $lstnr $target $attribute
			}
		}
	}

}

#The listener is unregistering from interest in the target
body objectMediator::unregister { unLstnr unTarget unAttribute } {

	if { $_debugOn} {puts "Unregistering $unLstnr $unTarget $unAttribute"}

	if { [info exists futureRequests($unLstnr)]} {
		set tmpRequests ""
		
		foreach registration $futureRequests($unLstnr) {
			foreach {target attribute callback alias} $registration {break}
			if { $target != $unTarget || $attribute != $unAttribute } {
				#this wasn't the unregistration request so we can add it back to the list.
				lappend tmpRequests [list $target $attribute $callback $alias]
			}
		}
		set futureRequests($unLstnr) $tmpRequests
	}
		
	#delete from the list of registration requests
	if { [info exists _registrationRequests($unTarget) ]} {
		#initialize a new list to hold the registration
		set tmpRequests ""
		
		#We had in fact registered with this target before.
		#Search through the registrations for this target for the one that
		#we want to get rid of.
		
		foreach registration $_registrationRequests($unTarget) {
			foreach {lstnr attribute callback alias} $registration {break}
			if { $lstnr != $unLstnr || $attribute != $unAttribute } {
				#this wasn't the unregistration request so we can add it back to the list.
				lappend tmpRequests [list $lstnr $attribute $callback $alias]
			} else {
				if {[ info command $unTarget] != ""} {
					$unTarget unregister $unLstnr $unAttribute $callback $alias
				}
			}
		}
		set _registrationRequests($unTarget) $tmpRequests
	}

}

body objectMediator::printStatus { } {

	puts "**********************************************"
	puts "The following objects have outstanding Future requests, but the listener isn't ready yet:"
	foreach lstnr [array name futureRequests] {
		set fullRequest $futureRequests($lstnr)
		puts "$lstnr: $fullRequest"
	}

	puts "The following objects have registration requests, and the listener is ready."
	foreach target [array name _registrationRequests] {
		set fullRequest $_registrationRequests($target)
		puts "$target: $fullRequest"
		puts ""
	}

	puts "The following targets have interested listeners, but they are not ready."
	foreach target [array name unmatchedTarget] {
		puts "$target"
	}

	puts "**********************************************"
}


##########################################################################
#
# 								   Class Component
#
# The Component class is meant to be inherited by other classes that
# will participate in the BLU-ICE component architecture.  Deriving a
# class from Component makes the class a BLU-ICE component.
#
# Currently, the only common functionality associated with BLU-ICE components
# is related to requesting and providing updates when attributes related
# to a component changes.
# 
#### Initializing the base class ###
#
# A child of Component must initialize the Component base class
# by calling the base class constructor explitly.  The first argument to the 
# constructor must be a list specifying the attributes in the child class that 
# should be made available for updates to other components.  Attribute names
# alternate with accessor functions provided for the attributes.  For example,
# if the call to base class constructor is:
#
#   Component::constructor { position getPosition speed getSpeed }
#
# then two attributes are exported, 'position' and 'speed', and the class
# provides the accessors 'getPosition' and 'getSpeed' for the two attributes
# respectively.
#
# If an exported attribute is a public variable, then the built-in accessor
# may be specified.  For example, if the 'position' attribute is a public
# variable, then the base class constructor might be called as follows:
#
#   Component::constructor { position {cget -position} speed getSpeed }
#
#
#### Registering for updates of attributes ###
#
# Assume that a child class of Component Motor, has been instantiated as 
# an object 'motor'.  Then an object 'lstnr' could register itself for 
# updates of motor's position attribute by issuing the command:
#
#   motor register lstnr position
#
#
#### Handling updates of attributes ###
#
# Updates of attributes are sent to all registered objects by calling the
# 'handleUpdateFromComponent' method of the registered object.  This method
# must take three arguments, the name of the Component providing the update,
# the name of the attribute being updated, and the new value of the attribute.
#
#
#### Triggering updates of attributes ###
#
# Component writers must explicitly indicate when an update for a particular
# attribute should be sent to all registered objects.  This is done by calling
# the Component::updateRegisteredComponents function.  For example,
#
#   updateRegisteredComponents position
#
# will trigger updates of position's value to all registered objects.
# Alternatively, the updateRegisteredComponentsAsynchronously method
# may be used.  This function inserts a call to updateRegisteredComponents
# into the Tcl event queue, allowing the currently active code to complete
# before the update is actually sent.
#
#
#### Unregistering ###
#
# A registered object may unregister by calling the 'unregister' method,
# passing it's own name and the name of the attribute for which it registered
# as arguments.  For example:
#
#    motor unregister lstnr position
#
##########################################################################

class DCS::Component {

	# private data
	private variable registeredComponentArray
	private variable accessorArray
	private variable updateScheduled
	private variable constructionComplete		0
	private variable exportedSubComponent

	protected variable _debugOn 0

	# public methods
	public method register { lstner attribute callback {alias ""}}
	public method unregister { name attribute callback {alias ""}} 
	public method getUpdateNow { name callback attribute alias }
	public method updateRegisteredComponents
	public method updateRegisteredComponentsNow
	public method announceExist {}
	public method announceDestruction
	public method exportSubComponent { attribute subComponent }
	public method addAttribute

    public proc replace%sInCommandWithValue { command value } {
        set first [string first %s $command]
        if {$first == -1} {
            return $command
        }
        set mapList [list %s $value]
	    set replacedStr [string map $mapList $command]

	    return $replacedStr
    }

	# protected methods
	protected method sendUpdate

	#first time a Component is instantiated, an object mediator is constructed
	if { [info commands objectMediator] =="" } {objectMediator ::mediator}

	# constructor
	constructor { args } {
		set constructionComplete 0

		if { ! $constructionComplete } {
			
			# first argument is a list of exported variables and associated accessor functions
			set exportedAttributes [lindex $args 0]
			
			# create an empty set of registered objects for each served variable
			foreach {attribute accessor} $exportedAttributes {
				addAttribute $attribute $accessor
			}

			#puts [array names accessorArray]
			set constructionComplete 1
		}

	}

	# destructor
	destructor {
		
		# destroy the Set associated with each exported variable
		foreach attribute [array names registeredComponentArray] {
			delete object $registeredComponentArray($attribute)
		}

		announceDestruction
	}
}


body DCS::Component::announceExist {} {

	set _onlineStatus 1

	::mediator announceExistence $this
}


body DCS::Component::announceDestruction {} {
	::mediator announceDestruction $this
}

body DCS::Component::addAttribute { attribute_ accessor_ } {

	#return if this attribute has already been added
	if { [info exists registeredComponentArray($attribute_) ] } {
		return
	}

	# initialize a set to hold the names of the registered components for the variable
	set registeredComponentArray($attribute_) [DCS::Set \#auto]
	
	# store the name of the accessor function used to get new values of the variable
	set accessorArray($attribute_) $accessor_
	
	set updateScheduled($attribute_) 0
}

body DCS::Component::exportSubComponent { attribute subComponent } {
	set exportedSubComponent($attribute) $subComponent
}

##########################################################################
# 
# Component::register
#
# This method is used to indicate interest in future updates of an 
# attribute of this component.  The caller must pass the name of the
# object to which updates 
# 
#
body DCS::Component::register { lstnr attribute callback {alias ""} } {

	if { $alias == "" } { set alias ${this}~$attribute }
	
	if { $_debugOn} {puts "$lstnr is registering for interest in $this's $attribute"}

	# make sure requested attribute is exported
	if { [info exists registeredComponentArray($attribute)] } {
		# add new object lstnr to registration set for the specified attribute
		$registeredComponentArray($attribute) add [list $lstnr $callback $alias]

		# request an immediate update for the specified attribute
		getUpdateNow $lstnr $callback $attribute $alias

		#puts [array lstnrs registeredComponentArray($attribute)]
		
	} elseif {  [info exists exportedSubComponent($attribute)] } {
		if { $_debugOn} {puts "!!!!EXPORTING SUB COMPONENT: $exportedSubComponent($attribute) == $alias !!!!!!!!!!!!!!"}

		#forward the registration request down to the subcomponent
		::mediator register $lstnr $exportedSubComponent($attribute) $attribute $callback $alias
		
	} else {
		# return failure
		return -code error "$this does not export attribute '$attribute'"
	}
}


body DCS::Component::unregister { lstnr attribute callback {alias ""} } {

	if { $alias == "" } { set alias ${this}~$attribute }

	if { $_debugOn} { puts "$this is unregistering $lstnr $attribute"}

	# remove name from registration set for the specified attribute
	if { [info exists registeredComponentArray($attribute)]} {
		$registeredComponentArray($attribute) remove [list $lstnr $callback $alias]
	} elseif {  [info exists exportedSubComponent($attribute)] } {
		if { $_debugOn} {puts "!!!!UNREGISTERING SUB COMPONENT:"}

		#forward the registration request down to the subcomponent
		::mediator unregister $lstnr $exportedSubComponent($attribute) $attribute

	} else {
		# return failure
		return -code error "$this does not export attribute '$attribute'"
	}

}


body DCS::Component::updateRegisteredComponentsNow { attribute {initiatorId_ ""}} {

	#log_note "$this updating $attribute ($updateScheduled($attribute) requests aggregated)"
	set updateScheduled($attribute) 0

	#puts "$this looping over: [$registeredComponentArray($attribute) get]"

	# send an update to every object in the registration list
	foreach lstnr [$registeredComponentArray($attribute) get] {
		foreach {name callback alias} $lstnr {}
		sendUpdate ${name} ${callback} $attribute $alias $initiatorId_
	}
}


proc safeCallback { command_} {
	if [catch {eval $command_} err] {
      global errorInfo
      puts $errorInfo
	}
}
	
	
body DCS::Component::updateRegisteredComponents { attribute {initiatorId_ ""} } {
	
	if { [catch {
		# count the number of requests to update the attribute
		incr updateScheduled($attribute)
		
		# schedule update of registered components in event queue if this is the first request
		if { $updateScheduled($attribute) == 1 } {
			after idle [list safeCallback "$this updateRegisteredComponentsNow $attribute $initiatorId_"]	
		}
	} errorResult ] } {
		return -code error "$this does not export '$attribute'"
	}

}



body DCS::Component::getUpdateNow { name callback attribute alias } {

	# send an update to the requesting object
	sendUpdate $name $callback $attribute $alias 
}



body DCS::Component::sendUpdate { name callback attribute alias {initiatorId_ ""} } {

	# get the current value of the attribute
	set tempValue [eval $this $accessorArray($attribute)]
	
	# send an update to the specified object
	$name $callback $this 1 $alias $tempValue $initiatorId_

	if { $_debugOn} {puts "$this is sending:	$name $callback $this 1 $alias $tempValue"}
}

#This class registers for multiple components
#and calls a member function which can be used to update a status
#This class can be inherited by widgets that
#need to watch the status of several components before making
#a decision regarding state, etc.
#This class can also be instantiated alone and then used to
#watch the status of multiple components and update listeners
#when an interesting event happens.
#The member function can be overiden by a child class for handling
#fancy logic.  The default logic is that all of the states must
#meet the specified trigger state before setting a status
#to "enabled"
class DCS::ComponentGate {

	inherit ::DCS::Component

	protected variable _gateOutput 0

	protected variable _blockingValuesArray
	
	public method addInput
	public method deleteInput
	public method getOutputMessage
	public method getOutput

	#override a couple of methods
	public method sendUpdate
	public method announceExist
	public method handleNewOutput

	#array for holding text messages to accompany a input event
	protected variable _inputMessageArray
	protected variable _inputValueArray
	protected variable _inputStatusArray


	protected variable _outputMessage "undefined"
	protected variable _blockingInput ""
	protected variable _blockingValue ""

	protected variable _onlineStatus 0

	public method handleUpdateFromTarget
	protected method calculateOutput

	constructor { args } 		{
		::DCS::Component::constructor { 
			gateOutput {getOutput} }
	} {

		#		if {$this == "::dataCollectionActive" } {set _debugOn 1}
		#		if {$this == "::DCS::TitledMotorEntry::.hutchTest.canvas.phi.ring.l.ring.b.c.e" } {set _debugOn 1}
		#if {$this == "::HutchTab::.hutchTest.canvas.automation.ring.b.c.optimize" } {set _debugOn 1}

		if { [namespace tail [$this info class]] == "ComponentGate" } {
			announceExist
		}

	}
	
	public method destructor
}

body DCS::ComponentGate::destructor {} {

	# unregister for all of the objects used as inputs
	foreach {alias} [array names _blockingValuesArray] {

		foreach {object attribute} [split $alias ~] break
		
		# unregister for interest in the target
		::mediator unregister $this $object $attribute
	}

	announceDestruction
}

body DCS::ComponentGate::handleUpdateFromTarget { target targetReady alias value initiatorId_} {
	if { $_debugOn} {puts "$this $target $targetReady $alias $value ++++++++++++++++++++++++++"}

	#update the array of input values
	set _inputValueArray($alias) $value
	set _inputStatusArray($alias) $targetReady

	# Check that each input is valid before calculating the output
	foreach {attribute} [array names _blockingValuesArray] {
		
		#check if the target device exists yet
		if { $_debugOn} {puts "$this Checking $attribute status: $_inputStatusArray($attribute)"}
		if { ! $_inputStatusArray($attribute) } {

			set tempOutput "$this reports bad input ($_inputValueArray($attribute))"

			set _onlineStatus 0
			set _outputMessage $tempOutput
			set _blockingValue $tempOutput
			
			#store which was the latest trigger event
			set _blockingInput $attribute

			#this object has changed states, update the registered components
			set _gateOutput $tempOutput

			updateRegisteredComponents gateOutput

			handleNewOutput

			#get out of here without recalculating the output			
			return
		}
	}

	set _onlineStatus 1
	calculateOutput
}

body DCS::ComponentGate::handleNewOutput { } {
	#do nothing... virtual function to be overriden
}

body DCS::ComponentGate::calculateOutput { } {

	set tempOutput 0
	set _outputMessage "ready"
	set _blockingInput ""
	set _blockingValue ""

	set attributes [array names _blockingValuesArray]

	if { $attributes == ""} {
		set _gateOutput 1
		updateRegisteredComponents gateOutput
		handleNewOutput
		return
	}

	# Check that each relevant target object is in the correct state before
	foreach {attribute} $attributes {

		#remember the wanted trigger value
		set triggerState $_blockingValuesArray($attribute)
		
		if { $_debugOn} {puts "$this Check $_inputValueArray($attribute) == $triggerState ?"}
		
		if { $_inputValueArray($attribute) != $triggerState } {
			set tempOutput 0
			set _outputMessage $_inputMessageArray($attribute)
			set _blockingValue $_inputValueArray($attribute)
			set _blockingInput $attribute

			break
		} else {
			set tempOutput 1
		}
	}

	#this object has changed states, update the registered components
	set _gateOutput $tempOutput

	updateRegisteredComponents gateOutput

	handleNewOutput
}


body DCS::ComponentGate::addInput { triggerList } {

	# store the name of the component which can enable this button
	foreach { object attribute filterValue reason } $triggerList {

		set alias ${object}~${attribute}

		# the registration should overwrite these values
		set _inputStatusArray($alias) 0
		set _inputValueArray($alias) ""
		set _blockingValuesArray($alias) $filterValue
		set _inputMessageArray($alias) $reason
		# register for interest in the target
		::mediator register $this $object $attribute handleUpdateFromTarget
	}
}

body DCS::ComponentGate::deleteInput { triggerList  } {

	# store the name of the component which can enable this button
	foreach { object attribute } $triggerList {
		::mediator unregister $this $object $attribute	
		
		#delete the trigger value from the array
		array unset _blockingValuesArray ${object}~${attribute}
		array unset _inputMessageArray ${object}~${attribute}

	}

	calculateOutput
}

body DCS::ComponentGate::getOutput {} {
	return $_gateOutput
}

body DCS::ComponentGate::getOutputMessage {} {
	return [list $_gateOutput $_blockingInput $_blockingValue $_outputMessage]
}


#set up a singleton object mediator called ::mediator
if { [info commands ::mediator] == "" } {
	#set up a list of default motors
	objectMediator mediator
}


#override this function for the case where an input is causing an ambiguous output
body DCS::ComponentGate::sendUpdate { name callback attribute alias {initiatorId_ ""}} {
	
	if { $_onlineStatus } {
		DCS::Component::sendUpdate $name $callback $attribute $alias $initiatorId_
	} else {
		if { $_debugOn} {puts "$this is sending:	$name $callback $this $_onlineStatus $alias $_blockingValue"}
		
		#ambigous inputs are causing the output to be undefined.
		
		# send an update to the specified object with the blockingValue instead
		$name $callback $this 0 $alias $_blockingValue $initiatorId_
	}
}


body DCS::ComponentGate::announceExist {} {
	#first set the default _onlineStatus value

	set _onlineStatus 1
	#then call the base class function
	DCS::Component::announceExist
}


class DCS::ComponentORGate {

	inherit ::DCS::ComponentGate
	protected method calculateOutput

	constructor { args } 		{
		::DCS::ComponentGate::constructor { 
			gateOutput {getOutput} }
	} {
		if { [namespace tail [$this info class]] == "ComponentORGate" } {
			announceExist
		}
	}

	destructor {
		announceDestruction
	}
}

body DCS::ComponentORGate::calculateOutput { } {

	set tempOutput 0
	set _outputMessage "ready"
	set _blockingInput ""
	set _blockingValue ""

	# Check that each relevant target object is in the correct state before
	foreach {attribute} [array names _blockingValuesArray] {

		#remember the wanted trigger value
		set triggerState $_blockingValuesArray($attribute)
		
		if { $_debugOn} {puts "$this Check $_inputValueArray($attribute) == $triggerState ?"}
		
		if { $_inputValueArray($attribute) == $triggerState } {
			set tempOutput 0
			set _outputMessage $_inputMessageArray($attribute)
			set _blockingValue $_inputValueArray($attribute)
			set _blockingInput $attribute
			
			break
		} else {
			set tempOutput 1
		}
	}

	#this object has changed states, update the registered components
	set _gateOutput $tempOutput

	updateRegisteredComponents gateOutput
	handleNewOutput
}

#we cannot use itk::Widget in addInput even the object is also sub class
#from DCS::Component.
#the object is deleted before the container's destructor being called.
#We do not have chance to call deleteInput.
#This will cause error message on the console.
#so we will create some mediator object for it.

class DCS::ItkWigetWrapper {
    inherit DCS::Component

    private variable m_obj ""
    private variable m_att ""
    private variable m_value ""

    public method getValue { } {
        return $m_value
    }

    public method handleUpdate { name_ targetReady_ alias_ contents_ - } {
        if {!$targetReady_} return
        set m_value $contents_
        updateRegisteredComponents $m_att
    }

    constructor { object attribute } {
        DCS::Component::constructor "$attribute getValue"
    } {
        #puts "itk wrapper constructor of $this"
        set m_obj $object
        set m_att $attribute
        $m_obj register $this $m_att handleUpdate
        announceExist
    }
    destructor {
        #puts "itk wrapper destructor of $this"
    }
}
####to use something as an input
class DCS::ManualInputWrapper {
    inherit DCS::Component

    private variable m_value 0

    public method getValue { } {
        return $m_value
    }

    public method setValue { newValue } {
        set m_value $newValue
        updateRegisteredComponents value
    }

    constructor { } {
        DCS::Component::constructor "value getValue"
    } {
        announceExist
    }
    destructor {
    }
}
