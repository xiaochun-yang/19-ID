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
package provide DCSCheckbutton 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSDeviceFactory
package require ComponentGateExtension

class DCS::Checkbutton {
# 	inherit ::itk::Widget ::DCS::ComponentGate
	inherit ::DCS::ComponentGateExtension
	itk_option define -trigger trigger Trigger  ""
	itk_option define -state state State "normal"

	# Color of entry can change based on reference value.
	itk_option define -matchColor match Match black
	itk_option define -mismatchColor mismatch Mismatch red
	itk_option define -disabledMatchColor match Match gray40
	itk_option define -disabledMismatchColor mismatch Mismatch #c04080
	itk_option define -reference reference Reference ""
	itk_option define -shadowReference shadowreference ShadowReference 0
	itk_option define -command command Command ""

    itk_option define -background background Background gray {
        set _originBG $itk_option(-background)
    }

    itk_option define -onBackground onBackground OnBackground ""
    itk_option define -offBackground offBackground OffBackground ""

	# Variables to remember which component this entry is currently
	# using for a reference.
	private variable _referenceComponent		none
	private variable _referenceVariable 		none
	private variable _referenceValue ""

	protected variable _lastReferenceComponent none
	protected variable _lastReferenceMatches ""
	protected variable _referenceMatches 0
	protected variable _state "normal"

    protected variable _originBG gray

	public method updateTextColor
	public method handleUpdateFromReference
	public method handleReferenceMatchChange
	public method getReferenceMatches {} {return $_referenceMatches}
	public method updateFromReference
	public method get
	public method setValue
	public method doCommand
	protected method handleNewOutput
	private method recalcState
	private common uniqueNameCounter 0

	private variable _checkbuttonVariableName ""

	constructor { args } {
		# call base class constructor
		::DCS::Component::constructor { \
			-value {get}
			-referenceMatches {getReferenceMatches}
		}
	} {
		itk_component add ring {
			frame $itk_interior.r
		}

		set _checkbuttonVariableName ::checkbutton$uniqueNameCounter
		incr uniqueNameCounter

	    if { [info tclversion] < 8.4 } {
		    itk_component add checkbutton {
			    # create the button
			    checkbutton $itk_component(ring).cb \
                -variable $_checkbuttonVariableName -command "$this doCommand"
		    } {
        		keep -onvalue -offvalue wraplength
			    keep -text -font -width -height -activebackground
			    keep -background -relief -selectcolor -foreground
                keep -activeforeground -disabledforeground -highlightcolor
			    keep -highlightthickness -highlightbackground
                keep -justify -anchor
		    }
        } else {
		    itk_component add checkbutton {
			    # create the button
			    checkbutton $itk_component(ring).cb \
                -variable $_checkbuttonVariableName -command "$this doCommand"
		    } {
        		keep -onvalue -offvalue -wraplength
			    keep -text -font -width -height -activebackground
			    keep -background -relief -selectcolor -foreground
                keep -activeforeground -disabledforeground -highlightcolor
			    keep -highlightthickness -highlightbackground -overrelief
                keep -justify -anchor
		    }
        }
        set _originBG [$itk_component(checkbutton) cget -background]

		pack $itk_component(checkbutton)
		pack $itk_component(ring)
		#registerComponent $itk_component(checkbutton)
		registerComponent $itk_interior
		eval itk_initialize $args
		announceExist
	}

	destructor {
		unregisterComponent
		unset $_checkbuttonVariableName
		::DCS::ComponentGate::destructor
	}

}
configbody DCS::Checkbutton::state {
    recalcState
}

configbody DCS::Checkbutton::trigger {
	addInput $itk_option(-trigger)
}

body ::DCS::Checkbutton::doCommand {} {
	updateTextColor

	set fullCommand [replace%sInCommandWithValue $itk_option(-command) [get]]

	eval $fullCommand
}

configbody DCS::Checkbutton::reference {
	
	if {$itk_option(-reference) != "" } {

		# unregister with last reference component
		if { $_lastReferenceComponent != "" } {
			
			::mediator unregister $this $_lastReferenceComponent $_referenceVariable
		}

		# extract reference component and variable
		foreach {_referenceComponent _referenceVariable} $itk_option(-reference) {break}
		
		# register with new reference component
		if { $_referenceComponent == "" } {
			
			updateTextColor
			
		} else {

			::mediator register $this $_referenceComponent $_referenceVariable handleUpdateFromReference $_referenceVariable
		}
		
		# keep name of last reference component
		set _lastReferenceComponent $_referenceComponent
	}
}

body DCS::Checkbutton::updateTextColor {} {

	updateRegisteredComponents -value

	if { $itk_option(-reference) != "" } {
		
		# determine if value and reference value match
		if {[set $_checkbuttonVariableName] != $_referenceValue } {
			set _referenceMatches 0
		} else {
			set _referenceMatches 1
		}

		if { $_lastReferenceMatches != $_referenceMatches } {
			set _lastReferenceMatches $_referenceMatches

			handleReferenceMatchChange $_referenceMatches
		
			# configure the foreground of the entry widget appropriately
		    if { $_referenceMatches } {
			    $itk_component(checkbutton) configure \
				-foreground $itk_option(-matchColor) \
				-disabledforeground $itk_option(-disabledMatchColor) \
				-activeforeground $itk_option(-matchColor)
		    } else {
			    $itk_component(checkbutton) configure \
			    -foreground $itk_option(-mismatchColor) \
			    -disabledforeground $itk_option(-disabledMismatchColor) \
			    -activeforeground $itk_option(-mismatchColor)
            }
		}
	}
    if {$itk_option(-onBackground) != "" || $itk_option(-offBackground) != ""} {
        if {[get]} {
            set onColor $itk_option(-onBackground)
            if {$onColor == ""} {
                set onColor $_originBG
            }
            $itk_component(checkbutton) configure \
            -background $onColor
        } else {
            set offColor $itk_option(-offBackground)
            if {$offColor == ""} {
                set offColor $_originBG
            }
            $itk_component(checkbutton) configure \
            -background $offColor
        }
    } else {
        $itk_component(checkbutton) configure \
        -background $_originBG
    }
}

body DCS::Checkbutton::handleUpdateFromReference { name targetReady_ alias referenceValue_ -} {
	
	if { $targetReady_ } {

		# store new value of the reference object
		set _referenceValue $referenceValue_
		
		# update entry value if shadowing is turned on
		if { $itk_option(-shadowReference) } {
			#update from the reference value
			updateFromReference
		} else {
			# update the entry color appropriately
			updateTextColor
		}
	}
}



body DCS::Checkbutton::handleReferenceMatchChange { - } {

	# update registered objects waiting for referenceMatches asynchronously
	updateRegisteredComponents -referenceMatches
}

body DCS::Checkbutton::updateFromReference { } {

	if { $_referenceValue == [$itk_component(checkbutton) cget -onvalue] } {
		$itk_component(checkbutton) select
	} else {
		$itk_component(checkbutton) deselect
	}

	updateTextColor
}

body DCS::Checkbutton::get { } {
   return [set $_checkbuttonVariableName]
}

body DCS::Checkbutton::setValue { value_ {directAccess_ 0} } {
	set $_checkbuttonVariableName $value_
	updateTextColor
	return
}
body DCS::Checkbutton::recalcState { } {
	#if the widget is disabled, it doesn't matter what the gate says
	if { $itk_option(-state) == "disabled" || $_gateOutput == 0 } {
        $itk_component(checkbutton) configure -state disabled
	} else {
        $itk_component(checkbutton) configure -state normal
	}

	updateBubble
}

body DCS::Checkbutton::handleNewOutput { } {
	recalcState
}

class DCS::CheckbuttonRight {
# 	inherit ::itk::Widget ::DCS::ComponentGate
	inherit ::DCS::ComponentGateExtension
	itk_option define -trigger trigger Trigger  ""
	itk_option define -state state State "normal"

	# Color of entry can change based on reference value.
	itk_option define -matchColor match Match black
	itk_option define -mismatchColor mismatch Mismatch red
	itk_option define -disabledMatchColor match Match gray40
	itk_option define -disabledMismatchColor mismatch Mismatch #c04080
	itk_option define -reference reference Reference ""
	itk_option define -shadowReference shadowreference ShadowReference 0
	itk_option define -command command Command ""

	# Variables to remember which component this entry is currently
	# using for a reference.
	private variable _referenceComponent		none
	private variable _referenceVariable 		none
	private variable _referenceValue ""

	protected variable _lastReferenceComponent none
	protected variable _lastReferenceMatches ""
	protected variable _referenceMatches 0
	protected variable _state "normal"

	public method updateTextColor
	public method handleUpdateFromReference
	public method handleReferenceMatchChange
	public method getReferenceMatches {} {return $_referenceMatches}
	public method updateFromReference
	public method get
	public method setValue
	public method doCommand
	protected method handleNewOutput
	private method recalcState
	private common uniqueNameCounter 0

	private variable _checkbuttonVariableName ""

	constructor { args } {
		# call base class constructor
		::DCS::Component::constructor { \
			-value {get}
			-referenceMatches {getReferenceMatches}
		}
	} {
		set _checkbuttonVariableName ::checkbutton$uniqueNameCounter
		incr uniqueNameCounter

        itk_component add prompt {
            label $itk_interior.pmt \
            -takefocus 0 \
            -anchor e
        } {
		    keep -text -font -width -height -activebackground
		    keep -background -relief -foreground
            keep -activeforeground -disabledforeground -highlightcolor
		    keep -highlightthickness -highlightbackground
        }

	    if { [info tclversion] < 8.4 } {
		    itk_component add checkbutton {
			    # create the button
			    checkbutton $itk_interior.cb \
                -anchor w \
                -variable $_checkbuttonVariableName -command "$this doCommand"
		    } {
        		keep -onvalue -offvalue
			    keep -height -activebackground
			    keep -background -relief -selectcolor -foreground
                keep -activeforeground -disabledforeground -highlightcolor
			    keep -highlightthickness -highlightbackground
		    }
        } else {
		    itk_component add checkbutton {
			    # create the button
			    checkbutton $itk_interior.cb \
                -anchor w \
                -variable $_checkbuttonVariableName -command "$this doCommand"
		    } {
        		keep -onvalue -offvalue -wraplength
			    keep -height -activebackground
			    keep -background -relief -selectcolor -foreground
                keep -activeforeground -disabledforeground -highlightcolor
			    keep -highlightthickness -highlightbackground -overrelief
		    }
        }

        grid $itk_component(prompt)      -row 0 -column 0 -sticky e
		grid $itk_component(checkbutton) -row 0 -column 1 -sticky w
		#registerComponent $itk_component(checkbutton)
		registerComponent $itk_interior
		eval itk_initialize $args
		announceExist
	}

	destructor {
		unregisterComponent
		unset $_checkbuttonVariableName
		::DCS::ComponentGate::destructor
	}

}
configbody DCS::CheckbuttonRight::state {
    recalcState
}

configbody DCS::CheckbuttonRight::trigger {
	addInput $itk_option(-trigger)
}

body ::DCS::CheckbuttonRight::doCommand {} {
	updateTextColor

	set fullCommand [replace%sInCommandWithValue $itk_option(-command) [get]]

	eval $fullCommand
}

configbody DCS::CheckbuttonRight::reference {
	
	if {$itk_option(-reference) != "" } {

		# unregister with last reference component
		if { $_lastReferenceComponent != "" } {
			
			::mediator unregister $this $_lastReferenceComponent $_referenceVariable
		}

		# extract reference component and variable
		foreach {_referenceComponent _referenceVariable} $itk_option(-reference) {break}
		
		# register with new reference component
		if { $_referenceComponent == "" } {
			
			updateTextColor
			
		} else {

			::mediator register $this $_referenceComponent $_referenceVariable handleUpdateFromReference $_referenceVariable
		}
		
		# keep name of last reference component
		set _lastReferenceComponent $_referenceComponent
	}
}

body DCS::CheckbuttonRight::updateTextColor {} {

	updateRegisteredComponents -value

	if { $itk_option(-reference) != "" } {
		
		# determine if value and reference value match
		if {[set $_checkbuttonVariableName] != $_referenceValue } {
			set _referenceMatches 0
		} else {
			set _referenceMatches 1
		}

		if { $_lastReferenceMatches != $_referenceMatches } {
			set _lastReferenceMatches $_referenceMatches

			handleReferenceMatchChange $_referenceMatches
		
			# configure the foreground of the entry widget appropriately
		    if { $_referenceMatches } {
			    $itk_component(prompt) configure \
				-foreground $itk_option(-matchColor) \
				-disabledforeground $itk_option(-disabledMatchColor) \
				-activeforeground $itk_option(-matchColor)
			    $itk_component(checkbutton) configure \
				-foreground $itk_option(-matchColor) \
				-disabledforeground $itk_option(-disabledMatchColor) \
				-activeforeground $itk_option(-matchColor)
		    } else {
			    $itk_component(prompt) configure \
			    -foreground $itk_option(-mismatchColor) \
			    -disabledforeground $itk_option(-disabledMismatchColor) \
			    -activeforeground $itk_option(-mismatchColor)
			    $itk_component(checkbutton) configure \
			    -foreground $itk_option(-mismatchColor) \
			    -disabledforeground $itk_option(-disabledMismatchColor) \
			    -activeforeground $itk_option(-mismatchColor)
            }
		}
	}
}


body DCS::CheckbuttonRight::handleUpdateFromReference { name targetReady_ alias referenceValue_ -} {
	
	if { $targetReady_ } {

		# store new value of the reference object
		set _referenceValue $referenceValue_
		
		# update entry value if shadowing is turned on
		if { $itk_option(-shadowReference) } {
			#update from the reference value
			updateFromReference
		} else {
			# update the entry color appropriately
			updateTextColor
		}
	}
}



body DCS::CheckbuttonRight::handleReferenceMatchChange { - } {

	# update registered objects waiting for referenceMatches asynchronously
	updateRegisteredComponents -referenceMatches
}

body DCS::CheckbuttonRight::updateFromReference { } {

	if { $_referenceValue == [$itk_component(checkbutton) cget -onvalue] } {
		$itk_component(checkbutton) select
	} else {
		$itk_component(checkbutton) deselect
	}

	updateTextColor
}

body DCS::CheckbuttonRight::get { } {
   return [set $_checkbuttonVariableName]
}

body DCS::CheckbuttonRight::setValue { value_ {directAccess_ 0} } {
	set $_checkbuttonVariableName $value_
	updateTextColor
	return
}
body DCS::CheckbuttonRight::recalcState { } {
	#if the widget is disabled, it doesn't matter what the gate says
	if { $itk_option(-state) == "disabled" || $_gateOutput == 0 } {
        $itk_component(checkbutton) configure -state disabled
	} else {
        $itk_component(checkbutton) configure -state normal
	}

	updateBubble
}

body DCS::CheckbuttonRight::handleNewOutput { } {
	recalcState
}
