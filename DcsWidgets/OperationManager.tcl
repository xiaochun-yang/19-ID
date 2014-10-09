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
package provide DCSOperationManager 1.0

# load standard packages

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent


class DCS::Operation {
	
	# inheritance
	inherit Device
	
	# public variables
	public variable lastResult ""
	public variable lastCompletionStatus ""

	public method handleOperationStart
	public method handleOperationComplete
	public method handleOperationUpdate
	public method handleControllerStatusChange
	public method configureDevice
	public method recalcStatus
	private common _operationCounter 1
	
	private proc getUniqueOperationHandle
	public method startOperation
	public method stopOperation

	public method updateListeners
	public method registerForAllEvents
	public method unRegisterForAllEvents

	private variable _message
	private variable _eventListeners


	public method startWaitableOperation
	public proc waitForOperation

    public proc waitForOperationToFinish { h } {
        while {1} {
            set status [lindex [waitForOperation $h] 0]
            if {$status != "update"} {
                break
            }
        }
    }

	private common _uniqueResult
	private common _uniqueUpdate
	private common _uniqueUpdateInIndex
	private common _uniqueUpdateOutIndex
	private common uniqueNameCounter 0
	private common _operationStatusVariable

	# constructor
	constructor { args } {

		# call base class constructor
		::DCS::Component::constructor {
			status {cget -status} \
				 -newOperation {getLatestOperationId} \
				 -completedOperation {getLastCompletedOperation} \
                permission {getPermission}
		}
	} {
		set _eventListeners [::DCS::Set \#auto]

		eval configure $args
		announceExist
	}
}

body DCS::Operation::configureDevice { controller_ args} {

	configure -controller $controller_
	
	#The following is a deffeciency in the DCS protocol.  The status
	# of the operation is not sent in the configuration message.
	configure -status "inactive"
}


body DCS::Operation::handleOperationStart { message_ } {
	set lastResult ""
	
	configure -status active
	updateRegisteredComponents status
	updateRegisteredComponentsNow -newOperation

	set _message $message_
	updateListeners
}



body DCS::Operation::handleOperationComplete { message_ } {

	set operationHandle [lindex $message_ 2]
	set lastCompletionStatus [lindex $message_ 3]
	set lastResult [lrange $message_ 3 end]

	configure -status inactive
	updateRegisteredComponents status
	updateRegisteredComponentsNow -completedOperation

	set _message $message_
	updateListeners

	#If the operationHandle is being watched with a waitForOperation
	# then store the result and trigger the vwait.
	if { [info exists _operationStatusVariable($operationHandle) ] } {
		set _uniqueResult($operationHandle) $lastResult
		set $_operationStatusVariable($operationHandle) $lastCompletionStatus
	}

}

body DCS::Operation::handleOperationUpdate { message_ } {
    if {[cget -status] != "active"} {
	    configure -status active
	    updateRegisteredComponents status
	    updateRegisteredComponentsNow -newOperation

        #puts "DEBUG OPERATION++++++++++++: set to active by update $message_"
    }

	set operationHandle [lindex $message_ 2]

	set _message $message_
	updateListeners

	#if the operationHandle has been started as waitable, store the result
	if { [info exists _operationStatusVariable($operationHandle) ] } {

		#store the update in the fifo
		set _uniqueUpdate($operationHandle,$_uniqueUpdateInIndex($operationHandle)) [lrange $message_ 3 end]
		incr _uniqueUpdateInIndex($operationHandle)
		#trigger the vwait in wait_for_operation
		set $_operationStatusVariable($operationHandle) "active"
    }
}


body DCS::Operation::handleControllerStatusChange {- targetReady alias value -} {
	#overide the status

	configure -status $value
	recalcStatus
}

body DCS::Operation::recalcStatus {} {
	if { $status == "online" } {set status "inactive"}
	if { $status == "unknown" } {set status "inactive"}
	
	updateRegisteredComponents status
}

body DCS::Operation::getUniqueOperationHandle { } {
	
	#increment the operation counter for all operation objects
	incr _operationCounter
	set clientID [$controlSystem cget -clientID]

	return "${clientID}.$_operationCounter"
}


body DCS::Operation::startOperation { args } {

	set operationHandle [getUniqueOperationHandle]
	
	dcss sendMessage "gtos_start_operation $deviceName $operationHandle $args"
	
	return $operationHandle
}

body DCS::Operation::stopOperation { } {
	dcss sendMessage "gtos_stop_operation $deviceName"
}


body DCS::Operation::startWaitableOperation { args } {

	set operationHandle [getUniqueOperationHandle]

	#set the operation status
	set _operationStatusVariable($operationHandle) ::operationStatus$uniqueNameCounter

	incr uniqueNameCounter

	set $_operationStatusVariable($operationHandle) active
	set _uniqueResult($operationHandle) ""
	
	#create the update fifo indices
	set _uniqueUpdateInIndex($operationHandle) 0
	set _uniqueUpdateOutIndex($operationHandle) 0

	dcss sendMessage "gtos_start_operation $deviceName $operationHandle $args"

	return $operationHandle
}


body DCS::Operation::waitForOperation { operationHandle } {

    if {![info exists _operationStatusVariable($operationHandle)] ||
    ![info exists _uniqueResult($operationHandle)] ||
    ![info exists _uniqueUpdateInIndex($operationHandle)] ||
    ![info exists _uniqueUpdateOutIndex($operationHandle)]} {
        return -code error "bad handle $operationHandle"
    }

	#check to see if there are any updates stored in the update fifo
	if { $_uniqueUpdateInIndex($operationHandle) > $_uniqueUpdateOutIndex($operationHandle) } {
		set result $_uniqueUpdate($operationHandle,$_uniqueUpdateOutIndex($operationHandle))
		#clear out the update to avoid a memory leak
		unset _uniqueUpdate($operationHandle,$_uniqueUpdateOutIndex($operationHandle))
		incr _uniqueUpdateOutIndex($operationHandle)
		return "update $result"
	}

	# if the operation is still active, wait for device to become inactive, aborting or get an update
	if { [set $_operationStatusVariable($operationHandle)] == "active" } {

		addToWaitingList $_operationStatusVariable($operationHandle)
		vwait $_operationStatusVariable($operationHandle)
		removeFromWaitingList $_operationStatusVariable($operationHandle)
	    if { [set $_operationStatusVariable($operationHandle)] == "aborting" } {
		    while { $_uniqueUpdateInIndex($operationHandle) > $_uniqueUpdateOutIndex($operationHandle) } {
			    #clear out the update to avoid a memory leak
			    unset _uniqueUpdate($operationHandle,$_uniqueUpdateOutIndex($operationHandle))
			    incr _uniqueUpdateOutIndex($operationHandle)
		    }
	        unset _uniqueResult($operationHandle)
	        unset $_operationStatusVariable($operationHandle)
	        unset _uniqueUpdateInIndex($operationHandle)
	        unset _uniqueUpdateOutIndex($operationHandle)
            return -code error "aborted"
        }
    }
	#updates could have come in while we were waiting...
	#check to see if there are any updates stored in the update fifo
	if { $_uniqueUpdateInIndex($operationHandle) > $_uniqueUpdateOutIndex($operationHandle) } {
		set result $_uniqueUpdate($operationHandle,$_uniqueUpdateOutIndex($operationHandle))
		#clear out the update to avoid a memory leak
		unset _uniqueUpdate($operationHandle,$_uniqueUpdateOutIndex($operationHandle))
		incr _uniqueUpdateOutIndex($operationHandle)
		return "update $result"
	}
	
	if  { $_uniqueUpdateInIndex($operationHandle) !=  $_uniqueUpdateOutIndex($operationHandle) } {
		puts "WARNING: ***************  operation update fifo not depleted ! ************** "
	}
	
	set tempResult $_uniqueResult($operationHandle) 	
	set tempStatus [set $_operationStatusVariable($operationHandle)]
	
	unset _uniqueResult($operationHandle)
	unset $_operationStatusVariable($operationHandle)
	unset _uniqueUpdateInIndex($operationHandle)
	unset _uniqueUpdateOutIndex($operationHandle)
	
	# return an error if any operation completed abnormally
	if { $tempStatus == "normal" } { 
		return "$tempResult"
	} else {
		return -code error "$tempResult"
	}
}


body DCS::Operation::registerForAllEvents { lstnr callback } {
	$_eventListeners add [list $lstnr $callback]	
}

body DCS::Operation::unRegisterForAllEvents { lstnr callback } {
	$_eventListeners remove [list $lstnr $callback]
}


body DCS::Operation::updateListeners { } {

	foreach request [$_eventListeners get] {
		foreach {lstnr callback} $request break
		
		$lstnr $callback $_message
	}
}
