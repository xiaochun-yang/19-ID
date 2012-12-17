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
package provide DCSString 1.0  

package require DCSDevice

# load standard packages


class DCS::String {
	
	# inheritance
	inherit Device

	# public variables
	protected variable _contents ""
	protected variable _fieldNames
	protected variable _keyNames

	public variable controller ""

	# public methods
	public method setContents
	public method getContents {} {return $_contents}
	public method configureString
	public method handleControllerStatusChange
	public method sendContentsToServer
	
	public method createAttributeFromField
	protected method updateRegisteredFieldListeners
	public method getFieldByIndex

    ### dict
	public method createAttributeFromKey
	protected method updateRegisteredKeyListeners
	public method getFieldByKey



    #copied from iwidgets::Checkbox to convert a field name to index
    private method index
    private method key

	protected method recalcStatus

	public method setLimits { upperLimit lowerLimit }

    #enable wait
    public method waitForString { } {
        configure -status waiting
        waitForDevice
    }
    public method waitForContents { expected_contents {index -1} } {
        while {1} {
            if {$index < 0} {
                set cnt $_contents
            } else {
                set cnt [lindex $_contents $index]
            }

            if {$cnt == $expected_contents} {
                break
            }
            waitForString
        }
    }

	# call base class constructor
	constructor { args } {

		# call base class constructor
		::DCS::Component::constructor \
			 { \
					 status 				{cget -status} \
					 contents	{ getContents } \
                permission {getPermission}
			 }
	} {
		eval configure $args
		announceExist
	}
	
	destructor {
	}
}

body DCS::String::configureString { message_ } {

	#parse the message
	configure -controller  [lindex $message_ 2] 
	set _contents [lrange $message_ 3 end]

	#inform that new configuration is available
	updateRegisteredComponents contents
	updateRegisteredFieldListeners
	updateRegisteredKeyListeners

	recalcStatus
}


body DCS::String::setContents { status_ contents_ } {
    set lastResult $status_
    if {$lastResult == "normal"} {
	    set _contents $contents_
	    #inform that new configuration is available
	    updateRegisteredComponents contents
	    updateRegisteredFieldListeners
	    updateRegisteredKeyListeners
    }
	recalcStatus
}

body DCS::String::sendContentsToServer { contents_ } {
		
	# request server to change the contents of the string
	set message "gtos_set_string $deviceName $contents_"
	$controlSystem sendMessage $message
}


body DCS::String::recalcStatus { } {

	if { $_controllerStatus == "offline" } {
		configure -status offline
	} else {
		configure -status inactive
	}
	
	updateRegisteredComponents status
}

configbody DCS::String::controller {
	if { $controller != "" } {
		::mediator register $this ::device::$controller status handleControllerStatusChange 
	}
}

body DCS::String::handleControllerStatusChange {- targetReady_ alias value -} {

	if { ! $targetReady_ } return

	set _controllerStatus $value
	recalcStatus
}

body DCS::String::createAttributeFromField { fieldName_ args } {
	#add the fieldName to the set
    set _fieldNames($fieldName_) $args

	# add the field as an attribute that can be registered for
	addAttribute $fieldName_  "getFieldByIndex $args"
	updateRegisteredFieldListeners
}

body DCS::String::updateRegisteredFieldListeners {} {
	foreach field [array names _fieldNames] {
		updateRegisteredComponents $field
	}
}

body DCS::String::getFieldByIndex { args } {

    set num_index [eval index $args]

    set field [getContents]
    foreach index $num_index {
	    set field [lindex $field $index]
    }

	return $field
}

body DCS::String::index {args} {
    if {[llength $args] > 1} {
        #only allowed for numbers
        foreach idx $args {
            if {![regexp {(^[0-9]+$)} $idx]} {
                error "bad index for string"
            }
        }
        return $args
    }

    if {[regexp {(^[0-9]+$)} $args]} {
        return $args
    } elseif {[info exists _fieldNames($args)]} {
            return $_fieldNames($args)
    } else {
        error "bad field index \"$args\": must be number or attribute name"
    }
}
body DCS::String::createAttributeFromKey { name_ args } {
    if {$args == ""} {
        set args $name_
    }

    set _keyNames($name_) $args

	# add the field as an attribute that can be registered for
	addAttribute $name_  "getFieldByKey $args"
	updateRegisteredKeyListeners
}
body DCS::String::updateRegisteredKeyListeners {} {
	foreach name [array names _keyNames] {
		updateRegisteredComponents $name
	}
}
body DCS::String::getFieldByKey { args } {

    set kk [eval key $args]

    set field [getContents]
    foreach key $kk {
        if {[catch {dict get $field $key} field]} {
            return ""
        }
    }

	return $field
}
body DCS::String::key {args} {
    if {[llength $args] > 1} {
        return $args
    }

    if {[info exists _keyNames($args)]} {
        return $_keyNames($args)
    }
    return $args
}




#### It does not map to a real DCS string.  It is a local BluIce string
class DCS::VirtualString {
	inherit DCS::String

    ##override
	public method sendContentsToServer { contents } {
        setContents normal $contents
    }
}
