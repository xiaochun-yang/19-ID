#!/usr/bin/wish
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


# provide the DCSMessageRouter package
package provide DCSMessageRouter 1.0

# load local packages
package require DCSComponent

##########################################################################
#
# 								   Class MessageRouter
#
# The MessageRouter class is meant to be inherited by other classes that
# will participate in the BLU-ICE component architecture.  Deriving a
# class from MessageRouter makes the class a BLU-ICE component.
#
# Currently, the only common functionality associated with BLU-ICE components
# is related to requesting and providing updates when attributes related
# to a component changes.
# 
#### Initializing the base class ###
#
# A child of MessageRouter must initialize the MessageRouter base class
# by calling the base class constructor explitly.  The first argument to the 
# constructor must be a list specifying the attributes in the child class that 
# should be made available for updates to other components.  Attribute names
# alternate with accessor functions provided for the attributes.  For example,
# if the call to base class constructor is:
#
#   MessageRouter::constructor { position getPosition speed getSpeed }
#
# then two attributes are exported, 'position' and 'speed', and the class
# provides the accessors 'getPosition' and 'getSpeed' for the two attributes
# respectively.
#
# If an exported attribute is a public variable, then the built-in accessor
# may be specified.  For example, if the 'position' attribute is a public
# variable, then the base class constructor might be called as follows:
#
#   MessageRouter::constructor { position {cget -position} speed getSpeed }
#
#
#### Registering for updates of attributes ###
#
# Assume that a child class of MessageRouter Motor, has been instantiated as 
# an object 'motor'.  Then an object 'observer' could register itself for 
# updates of motor's position attribute by issuing the command:
#
#   motor register observer position
#
#
#### Handling updates of attributes ###
#
# Updates of attributes are sent to all registered objects by calling the
# 'handleUpdateFromMessageRouter' method of the registered object.  This method
# must take three arguments, the name of the MessageRouter providing the update,
# the name of the attribute being updated, and the new value of the attribute.
#
#
#### Triggering updates of attributes ###
##
#### Unregistering ###
#
# A registered object may unregister by calling the 'unregister' method,
# passing it's own name and the name of the attribute for which it registerd
# as arguments.  For example:
#
#    motor unregister observer position
#
##########################################################################

class DCS::MessageRouter {
	inherit DCS::Component

	# private data
	private variable _listenerRequests
	
	# public methods
	public method registerForMessage { listenerCallback regularExpression }
	public method unregisterForMessage { listenerCallback regularExpression } 
	public method sendMessageToListeners { text }

	public method registerAdvanced {regularExpression parameterList callbackFormat callbackOrder}
	public method sendMessageToListenersAdvanced { text }

	# constructor
	constructor { args } {
	}

	# destructor
	destructor {
	}
}



##########################################################################
# 
# DCS::MessageRouter::register
#
# This method is used to indicate interest in a particular type of message.
# The caller must pass the name of the object to which relevant messages
# will be sent
#

body DCS::MessageRouter::registerForMessage { listenerCallback regularExpression } {
	#lappend initializes a new list if it doesn't exist yet

	if { [info exists _listenerRequests($regularExpression)] } {
		set index [lsearch $_listenerRequests($regularExpression) $listenerCallback]
		#only add the request if it isn't registered yet
		if { $index == -1 } {
			lappend _listenerRequests($regularExpression) $listenerCallback
		}
	} else {
		lappend _listenerRequests($regularExpression) $listenerCallback
	}
}

body DCS::MessageRouter::registerAdvanced { regularExpression parameterList callbackFormat callbackOrder} {
	#lappend initializes a new list if it doesn't exist yet
	lappend _listenerRequests($regularExpression) $parameterList
   lappend _listenerRequests($regularExpression) $callbackFormat
   lappend _listenerRequests($regularExpression) $callbackOrder
}



body DCS::MessageRouter::unregisterForMessage { listenerCallback regularExpression } {

	# add new object name to registration set for the specified attribute
	if { [info exists _listenerRequests($regularExpression) ]} {
		#found the regular expression
		set index [lsearch $_listenerRequests($regularExpression) $listenerCallback]
		if {$index != -1 } {
			#found the callback...delete it...
			set _listenerRequests($regularExpression) [lreplace _listenerRequests($regularExpression) $index $index]
			if { $_listenerRequests($regularExpression) == "" } {
				#no more listeners for this regular expression, so delete it
				unset _listenerRequests($regularExpression)
			}
		}
	}
}

body DCS::MessageRouter::sendMessageToListeners { text } {

	#puts "MESSAGE ROUTER: $text"

	# send an update to every object in the registration list
	foreach regularExpression [array names _listenerRequests] {
		#puts $regularExpression
		if { [regexp $regularExpression $text] } {
			foreach callback $_listenerRequests($regularExpression) {
				eval $callback {$text}
			}
		}
	}
}


body DCS::MessageRouter::sendMessageToListenersAdvanced { text } {

	# send an update to every object in the registration list
	foreach regularExpression [array names _listenerRequests] {
		foreach {parameterList callbackFormat callbackOrder} $_listenerRequests($regularExpression) {break}
		#puts $parameterList
		#puts $callbackFormat

		#regexp takes 140us on my linux
		if { [eval [eval {list regexp $regularExpression $text} $parameterList]] } {
			#We found a match...create a callback message with the parsed output
			foreach parameter $callbackOrder {
				lappend output [set $parameter]
			}

			#create a message using the specified format...38us
			set callbackCommand [eval [eval {list format $callbackFormat} $output ]]
			eval $callbackCommand
		}
		set output ""
	}
}

