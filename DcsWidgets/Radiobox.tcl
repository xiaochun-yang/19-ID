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


# provide the DCSRadiobutton package

package provide DCSRadiobox 1.0

# load necessary packages
package require Iwidgets

package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSDeviceFactory
package require ComponentGateExtension

class DCS::Radiobox {

    inherit ::DCS::ComponentGateExtension


    itk_option define -trigger trigger Trigger ""
    itk_option define -state state State "active"

    itk_option define -matchColor match Match black
    itk_option define -mismatchColor mismatch Mismatch red
    itk_option define -disabledMatchColor match Match gray40
    itk_option define -disabledMismatchColor mismatch Mismatch #c04080
    itk_option define -reference reference Reference ""
    itk_option define -shadowReference shadowreference ShadowReference false
    itk_option define -stateList statelist StateList "open closed"
	itk_option define -buttonLabels buttonlabels ButtonLabels {{} {}}
	itk_option define -command command Command ""
    
    private variable _referenceComponent none
    private variable _referenceVariable none
    private variable _referenceValue ""

	private variable stateList ""

    protected variable _lastReferenceComponent none
    protected variable _lastReferenceMatches ""
    protected variable _referenceMatches 0
    protected variable _state "active"

    public method updateTextColor
    public method handleUpdateFromReference
    public method handleReferenceMatchChange
    public method getReferenceMatches {} {return $_referenceMatches}
    public method updateFromReference
    public method get
	public method setValue
    private method recalcStatus
	private method regenerateButtons
	public method doCommand
	protected method handleNewOutput

	private variable _buttonsGenerated false

	private variable stateCount 2

    private variable m_skipCommand 0


    constructor {args}  {
        # call baseclass constructor
        ::DCS::Component::constructor { -value get -referenceMatches getReferenceMatches }
    } {
        
        itk_component add rbox {
            iwidgets::radiobox $itk_interior.rbox \
			-command "$this doCommand" \
        } {
			keep -labeltext -labelfont -labelimage -labelbitmap -labelmargin
			keep -labelvariable -borderwidth -background -foreground
            keep -selectcolor
		}
        pack $itk_component(rbox)
        registerComponent $itk_interior

        eval itk_initialize $args
        announceExist
		puts "done constructing radiobox"
    }
    destructor {
        unregisterComponent
        ::DCS::ComponentGate::destructor
    }
}

configbody DCS::Radiobox::stateList {
	foreach element $itk_option(-stateList) {
		if {[llength [lsearch -all -exact $itk_option(-stateList) $element]] > 1} {
			error "States are not unique"
		}
	}
	regenerateButtons
	set stateCount [llength $itk_option(-stateList)]
}

configbody DCS::Radiobox::buttonLabels {

	if { [llength $itk_option(-buttonLabels)] != [llength $itk_option(-stateList)] } {
		error "Mismatched button label count in DCSRadiobox"
	}
	if {[llength $itk_option(-buttonLabels)] == $stateCount} {
		regenerateButtons
	}
}

body DCS::Radiobox::regenerateButtons {} {
	puts "regenerating radiobuttons"
	if { $_buttonsGenerated } {
		for {set i 0} {$i < $stateCount} {incr i} {
			$itk_component(rbox) delete 0
		}
	}
	foreach label $itk_option(-buttonLabels) \
			ref_val $itk_option(-stateList) {
		$itk_component(rbox) add $ref_val -text $label
	}
	set _buttonsGenerated true
}

configbody DCS::Radiobox::state {
    recalcStatus
}

configbody DCS::Radiobox::trigger {
    addInput $itk_option(-trigger)
}

configbody DCS::Radiobox::reference {
	if {$itk_option(-reference) != "" } {
		# unregister with last reference component
		if { $_lastReferenceComponent != ""} {
			::mediator unregister $this $_lastReferenceComponent \
				$_referenceVariable
		}
		# extrace reference component and variable
		foreach {_referenceComponent _referenceVariable}  \
			$itk_option(-reference) \
			{break}
		if { $_referenceComponent == ""} {
			updateTextColor
			puts "reference not found"
		} else {
			::mediator register $this $_referenceComponent $_referenceVariable \
				handleUpdateFromReference $_referenceVariable
		}

		# keep name of last reference component
		set _lastReferenceComponent $_referenceComponent
	}
}

body DCS::Radiobox::handleUpdateFromReference {name targetReady_ alias
	referenceValue_ - } {
	if {$targetReady_} {
		set _referenceValue $referenceValue_

		if {$itk_option(-shadowReference)} {
			updateFromReference
		} else {
			updateTextColor
		}
	}
}

body DCS::Radiobox::recalcStatus { } {
	if {!$_buttonsGenerated} {
		return
	}
	if { $itk_option(-state) == "disabled" || $_gateOutput == 0 } {
		for {set i 0} {$i < $stateCount} {incr i} {
			$itk_component(rbox) buttonconfigure $i -state disabled
		}
		set _state "disabled"
	} else {
		for {set i 0} {$i < $stateCount} {incr i} {
			$itk_component(rbox) buttonconfigure $i -state active
		}
		set _state "active"
	}
	
	updateBubble
}
body DCS::Radiobox::get {} {
	return [$itk_component(rbox) get]
}
body DCS::Radiobox::setValue {value_ {skip_command 0}} {
    set currentValue [$itk_component(rbox) get]
    if {$value_ == $currentValue && $skip_command} {
        return
    }

    set m_skipCommand $skip_command
	if { $_state == "disabled" } {
		$itk_component(rbox) buttonconfigure $value_ -state active
		$itk_component(rbox) select $value_
		$itk_component(rbox) buttonconfigure $value_ -state disabled
	} else {
		$itk_component(rbox) select $value_
	}
    set m_skipCommand 0
}
body DCS::Radiobox::updateTextColor {} {
	
	updateRegisteredComponents -value

	if {$itk_option(-reference) != "" } {
		if {[$itk_component(rbox) get] == $_referenceValue} {
			set _referenceMatches true
		} else {
			set _referenceMatches false
		}
		
		if { $_lastReferenceMatches != $_referenceMatches } {
			set _lastReferenceMatches $_referenceMatches

			handleReferenceMatchChange $_referenceMatches

			if  { $_referenceMatches } {
				$itk_component(rbox) configure \
				-foreground $itk_option(-matchColor) \
				-activeforeground $itk_option(-matchColor) \
				-disabledforeground $itk_option(-disabledMatchColor)
			} else {
				$itk_component(rbox) configure \
				-foreground $itk_option(-mismatchColor) \
				-activeforeground $itk_option(-mismatchColor) \
				-disabledforeground $itk_option(-disabledMismatchColor)
			}
		}
	}
}

body DCS::Radiobox::handleReferenceMatchChange { - } {

	updateRegisteredComponents -referenceMatches
}

body DCS::Radiobox::updateFromReference { } {

	setValue $_referenceValue
	updateTextColor
}


body DCS::Radiobox::handleNewOutput { } {
	recalcStatus
}

body DCS::Radiobox::doCommand {} {
	updateTextColor

    set cmd $itk_option(-command)
    set v [$itk_component(rbox) get]

    if {$_state == "active" && $cmd != ""} {
        set newCmd [replace%sInCommandWithValue $cmd $v]
        eval $newCmd
    }
}
