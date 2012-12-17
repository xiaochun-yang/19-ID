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
package provide DCSEntry 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSBitmaps
package require DCSDeviceFactory
package require ComponentGateExtension

##########################################################################
#
# Usual options.
#
itk::usual DCS::Entry {
    keep -background -borderwidth -cursor -foreground -highlightcolor \
	 -highlightthickness -insertbackground -insertborderwidth \
	 -insertofftime -insertontime -insertwidth -labelfont \
	 -selectbackground -selectborderwidth -selectforeground \
	 -textbackground -textfont
}

class DCS::Entry {

	# inheritance
#	inherit ::itk::Widget ::DCS::ComponentGate
	inherit ::DCS::ComponentGateExtension
	# Color of entry can change based on reference value.
	itk_option define -matchColor match Match black
	itk_option define -mismatchColor mismatch Mismatch red
	itk_option define -reference reference Reference ""
	itk_option define -shadowReference shadowreference ShadowReference 0
	itk_option define -alternateShadowReference alternateShadowReference AlternateShadowReference ""
	itk_option define -state state State "normal"
    itk_option define -leaveSubmit leaveSubmit LeaveSubmit 0
    itk_option define -submitFullValue submitFullValue SubmitFullValue 0

    itk_option define -onlyMatchNumber onlyMatchNumber OnlyMatchNumber 0

    #### when update from alternateShadowReference, whether submit
    itk_option define -alterUpdateSubmit alterUpdateSubmit AlterUpdateSubmit 1

    ### used by beamsize widgets to act like a motor to update the beamsize on video
    ### send value change if the referenceMatches changed
    ### updateRegisteredComponents -value when value not change but color changed
    itk_option define -updateValueOnMatch updateValueOnMatch UpdateValueOnMatch 0
    
	#	itk_option define -referenceMatches referenceMatches ReferenceMatches 0
	protected variable _referenceMatches "-1"

	public method getReferenceMatches {} {return $_referenceMatches}
	public method getUnits {} {return $itk_option(-units)}

	itk_option define -disabledbackground disabledBackground EntryDisabledBackground lightgrey
	itk_option define -labeledbackground labeledBackground EntryLabeledBackground tan
	itk_option define -promptText promptText PromptText ""


	# Entry can force value in a particular format
	itk_option define -entryType entryType EntryType "string" {
        onEntryTypeChange
    }
	itk_option define -nullAllowed nullAllowed NullAllowed "0"
	itk_option define -entryWidth entryWidth EntryWidth 8
	itk_option define -entryMaxLength entrymax EntryMax	""
	itk_option define -precision precision Precision 0.01
	itk_option define -decimalPlaces decimalplaces DecimalPlaces "3"
	itk_option define -zeroPadDigits zeropad Zeropad 0
	itk_option define -escapeToDefault escapeToDefault EscapeToDefault 1
	itk_option define -activeBackground activeBackground ActiveBackground \#c0c0ff
	#itk_option define -activeForeground activeBackground activeBackground #c0c0ff
	itk_option define -unitsList unitslist UnitsList ""
	itk_option define -autoGenerateUnitsList autoGenerateUnitsList AutoGenerateUnitsList 0
	itk_option define -units units Units ""
	itk_option define -showUnits showUnits ShowUnits 1
	itk_option define -showPrompt showPrompt ShowPrompt 1
	itk_option define -autoConversion autoConverstion AutoConversion 0
	itk_option define -unitConvertor unitConvertor UnitConvertor ::units
	itk_option define -referenceValue referenceValue ReferenceValue ""

	protected variable _lastUnits ""
	private variable _units
	protected variable _referenceValue ""
	public method autoGenerateUnitsList
	public method checkValuesMatch

	private method recalcState
    private method adjustRight

	protected method handleNewOutput

    ### give derived class a hook
    protected method internalOnChange { } { }
    protected method onEntryTypeChange { } { }
    public method handleOnSubmitChange { } { }
    protected method value2display { value_ } { return $value_ }

    ### DetectorMenu needs override this
    ### CollimatorMenuEntry too.
	protected method replace%sWithValue { cmd } {
        if {$itk_option(-submitFullValue)} {
            return [replace%sInCommandWithValue $cmd $_fullValue]
        }
        return [replace%sInCommandWithValue $cmd $_value]
    }

	protected variable _value ""
    protected variable _inSetValue 0
	public method setValue

	# public data related to the widget as a whole

	# Variables to remember which component this entry is currently
	# using for a reference.
	private variable _referenceComponent		""
	private variable _referenceVariable 		""
	protected variable _lastReferenceComponent ""
	protected variable _lastReferenceMatches ""

	private variable _shadowReferenceComponent		""
	private variable _shadowReferenceVariable 		""
	protected variable _lastShadowReferenceComponent ""
	protected variable _lastShadowReferenceMatches ""

	#extra functions that can be called when something changes
	itk_option define -onChange onChange OnChange {}
	itk_option define -onSubmit onSubmit OnSumbit {} {
        handleOnSubmitChange
    }

	# private data
	protected variable _deletingValue			 0
	#The _fullValue stores the requested value before being formatted for display.
	protected variable _fullValue             0
	protected variable _state "normal"

    protected variable _hasFocus 0

	private variable _forcedValue ""
	private variable _initiatorId ""

	# public methods
	public method updateFromReference
	public method handleValueChange
	protected method changeUnitsList
	public method convertUnits
	public method convertUnitValue

    public method getState { } { return $_state }

	public method changeUnits
	public method newEvent {} {set _initiatorId ""}

	public method handleLeave { hasFocus }

    public method handleEscape { } {
	    if {$itk_option(-escapeToDefault)} {
			newEvent
            updateFromReference
		}
    }

    public method handleReturn { } {
        handleSubmit
    }
    public method handleFocusIn { } {
        set _hasFocus 1
    }
    public method handleFocusOut { } {
        set _hasFocus 0
        handleSubmit
    }

	# methods overriding ComponentBase class methods
	public method handleSubmit {  }
	public method handleUpdateFromReference
	public method handleUpdateFromShadowReference
	public method repack

	private method reconfigureEntry

	protected variable _ready 0

	# protected methods
	protected method updateEntryColor {}
	protected method updateEntryWidget {}
	protected method updateState
	protected method updateEntryWidth
	protected method handleReferenceMatchChange
	protected method updateReferenceMatches

	public method get
	public method convertValueToCurrentUnits

   private variable m_bubbleMessage ""
   public method getBubbleMessage {} {return $m_bubbleMessage}


	public {
		method delete {args}
		method icursor {args}
		method index {args}
		method insert {args}
		method scan {args}
		method selection {args}
		method xview {args}
		method clear {}
		method bbox
	}

	# constructor
    constructor { args } {
        ::DCS::Component::constructor { -value get \
                  -referenceMatches getReferenceMatches \
                  -units "getUnits" \
                  status "getState"
        }

    } {
        itk_component add prompt {
            label $itk_interior.p -takefocus 0 -anchor e
        } {
            keep -font
            keep -background
            #rename -background -promptBackground promptBackground PromptBackground
            rename -activeforeground -promptForeground promptForeground PromptForeground
            rename -foreground -promptForeground promptForeground PromptForeground
            rename -width -promptWidth promptWidth PromptWidth
        }
        itk_component add entry {
            entry $itk_interior.e -validate key -validatecommand "$this handleValueChange %P"
        } {
            #keep -font -background
            keep -font
            rename -justify -entryJustify entryjustify EntryJustify
            rename -relief entryRelief entryRelief EntryRelief
        }
        #add a button for changing units
        itk_component add units {
            menubutton $itk_interior.u -text "" -menu $itk_interior.u.menu -state normal -relief flat -anchor w -borderwidth 0
        } {
            keep -font -bitmap
            keep -background -foreground
            rename -activeforeground -unitsForeground unitsForeground UnitsForeground
            rename -foreground -unitsForeground unitsForeground UnitsForeground
            rename -width -unitsWidth unitswidth UnitsWidth
        }
        itk_component add unitsmenu {
            menu $itk_interior.u.menu -tearoff 0 -activebackground green -background blue
        } {
            keep -background -foreground
        }
        #make the disabled foreground same as normal
        $itk_component(units) configure -disabledforeground black
        # get configuration options
	registerComponent $itk_interior
        eval itk_initialize $args
	# set up binding of carriage return and loss of focus to submit event
        bind $itk_component(entry) <Return> "$this handleReturn"
        bind $itk_component(entry) <FocusIn> "$this handleFocusIn"
        bind $itk_component(entry) <FocusOut> "$this handleFocusOut"
        bind $itk_component(entry) <Leave> "+$this handleLeave %f"
        bind $itk_component(entry) <Escape> "+$this handleEscape"
        # set maximum entry length to entry width if the former is still undefined
        if { $itk_option(-entryMaxLength) == "" } {
            set itk_option(-entryMaxLength) [$itk_component(entry) cget -width]
        }
        if { [namespace tail [$this info class]] == "Entry" } {
            announceExist
            repack
            updateEntryColor
            set _ready 1
        }
    }
    destructor {
        unregisterComponent
        announceDestruction
    }
}

body DCS::Entry::repack {} {
	#Forget the packing of the entry which has already happened in the base class
	grid forget $itk_interior
	grid forget $itk_component(entry)
	grid forget $itk_component(units)


	if { $itk_option(-showPrompt) } {
		grid $itk_component(prompt) -column 0 -row 0 -sticky e
	} else {
		grid forget $itk_component(prompt)
   }

	grid $itk_component(entry) -column 1 -row 0

	if { $itk_option(-showUnits) } {
		grid $itk_component(units) -column 2 -row 0 -sticky w
	}
}

configbody DCS::Entry::state {
	recalcState
}


configbody DCS::Entry::promptText {
	$itk_component(prompt) configure -text $itk_option(-promptText)
}

configbody DCS::Entry::showUnits {
	repack
}

configbody DCS::Entry::entryWidth {
	updateEntryWidth
}

#The referenceValue can be configured directly for the case where you don't want to
#reference an actual object, but just want to give it a constant reference.
configbody DCS::Entry::referenceValue {
	if {$itk_option(-referenceValue) != "" } {
		set _referenceValue $itk_option(-referenceValue)
		updateReferenceMatches
	}
}


body DCS::Entry::convertValueToCurrentUnits {value_} {
	if {$value_ == "" } return ""

	foreach {value units} $value_ {break;}

	if {$itk_option(-autoConversion) && $itk_option(-unitConvertor) != "" } {
		set value [$itk_option(-unitConvertor) convertUnits $value $units $itk_option(-units)]
	}

	return $value
}

body DCS::Entry::updateEntryWidth {} {
	$itk_component(entry) configure -width $itk_option(-entryWidth)
}


body DCS::Entry::handleUpdateFromShadowReference { caller_ targetReady_ - referenceValue_ initiatorId_} {
	if { ! $targetReady_} return

	set _shadowReferenceValue [convertValueToCurrentUnits $referenceValue_]
	updateReferenceMatches

	# update entry value with new shadow value
	if {$initiatorId_ != "" } {
		#if we started this event cycle, end it here
        #puts "DEBUG: initiator length [llength $_initiatorId]"
        set index [lsearch $_initiatorId $initiatorId_]
        if {$index >= 0} {
            if {$index > 0} {
                set rm_i [expr $index - 1]
                set _initiatorId [lreplace $_initiatorId 0 $rm_i]
            }
			return
		}
	}

	#remember where this update came from
	set _initiatorId $initiatorId_

	if {$itk_option(-alterUpdateSubmit)} {
	    setValue $_shadowReferenceValue
    } else {
	    setValue $_shadowReferenceValue 1
    }
}

body DCS::Entry::handleUpdateFromReference { caller_ targetReady_ - referenceValue_ initiatorId_} {

	if { ! $targetReady_} return

	set referenceValue ""
	set referenceUnits ""

	set _referenceValue $referenceValue_

    #### check units
    set deviceBaseUnits [lindex $referenceValue_ 1]
    if {[catch {
        if {$_lastUnits != "" && $_lastUnits != "steps" && \
        $deviceBaseUnits != "" && \
        $_lastUnits != $deviceBaseUnits} {

            ::units getConversionEquation $deviceBaseUnits $_lastUnits
        }
    } errorMsg]} {
        log_error units failed $errorMsg
        log_error "change units to $deviceBaseUnits"
        configure -units $deviceBaseUnits
        changeUnitsList
    }

	# update entry value if shadowing is turned on
	if { $itk_option(-shadowReference) } {
		if { $itk_option(-alternateShadowReference) == "" } {
			#there is not alternateShadowReference, follow the main reference
			if {$initiatorId_ != "" } {
				#if we started this event cycle, end it here
                #puts "DEBUG: initiator length [llength $_initiatorId]"
                set index [lsearch $_initiatorId $initiatorId_]
                if {$index >= 0} {
                    if {$index > 0} {
                        set rm_i [expr $index - 1]
                        set _initiatorId [lreplace $_initiatorId 0 $rm_i]
                    }
			        return
		        }
			}

			#remember where this update came from
			set _initiatorId $initiatorId_

			updateFromReference
		}
	}

	updateReferenceMatches

}

body DCS::Entry::handleLeave { hasFocus } {
    if {$itk_option(-leaveSubmit) && $hasFocus && \
    [focus] == $itk_component(entry)} {
        handleSubmit
    }
}
#This method is for gui events submitting the new value
body DCS::Entry::handleSubmit { } {
    if {$_state != "normal"} return

	set value [$itk_component(entry) get]

	if { [isBlank $value] && ! $itk_option(-nullAllowed) } {
		# updateFromReference value if entry is blank
		updateFromReference
	} else {
		#puts "ENTRY: configuring the value $value"
		# otherwise just reformat the value
		setValue $value
	}

	return 1
}



configbody DCS::Entry::disabledbackground {
	updateState
}
configbody DCS::Entry::labeledbackground {
    $itk_component(entry) configure \
    -disabledbackground $itk_option(-labeledbackground)
}

body DCS::Entry::updateState {} {

	switch $_state {
		normal {
            $itk_component(entry) configure \
            -state normal \
            -background white \
            -relief sunken
		}
		disabled {
            $itk_component(entry) configure \
            -state normal \
            -background $itk_option(-disabledbackground)
		}
        labeled {
            $itk_component(entry) configure \
            -state disabled
        }
	}

	updateRegisteredComponents status

}


body DCS::Entry::handleValueChange { value_ } {

	#guard against weird inputs
	if { $_deletingValue } {  return 1 }
	if { $_forcedValue != $value_  && $_state == "disabled" } { return 0 }
	if { $itk_option(-entryMaxLength) > 0 && \
	[string length $value_] > $itk_option(-entryMaxLength) } {
        log_error cannot set Value to $value_ exceed max length $itk_option(-entryMaxLength)
        puts "cannot set $this Value to $value_ exceed max length $itk_option(-entryMaxLength)"
        return 0
    }
	if { ! [isIncompleteValue $value_ $itk_option(-entryType) ] } { return 0 }

	if {$_forcedValue == "" } {
		#here because of a keystroke
		set newId [::mediator getUniqueInitiatorId]
        lappend _initiatorId $newId
	} else {
        set newId [lindex $_initiatorId end]
    }

	# store the new value
	set _value $value_

    internalOnChange

	# execute change callback procedure if defined
	if { $itk_option(-onChange) != {} } {
		eval $itk_option(-onChange)
	}

	# update color of widget for reference
	updateReferenceMatches

	# update registered objects asynchronously
	updateRegisteredComponents -value $newId
	#puts "ENTRY: $this updateRegisteredComponents -value $newId"

	# approve the new value
	return 1
}

body DCS::Entry::convertUnitValue { value_  toUnits_ } {

	if {$value_ == "" } {return ""}

	foreach {value units} $value_ break

	if {$units == ""} {return $value}

	set convertedValue  [convertUnits $value $units $toUnits_]

	return $convertedValue
}


body DCS::Entry::checkValuesMatch { value1_ value2_ } {

	set decimalPlaces $itk_option(-decimalPlaces)
	set precision $itk_option(-precision)
	set type $itk_option(-entryType)

	if {$itk_option(-autoConversion) == 1} {
		#convert both values to the current units
		set value1 [convertUnitValue $value1_ $itk_option(-units)]
		set value2 [convertUnitValue $value2_ $itk_option(-units)]
		#puts "ENTRY:  Autoconversion on $value1 $value2 $precision"
	} else {
		set value1 $value1_
		set value2 $value2_
	}

	return [valuesMatch $value1 $value2 $type $decimalPlaces $precision]

}


body DCS::Entry::updateEntryColor {} {

	#puts "ENTRY: entered updateEntry color"
	# configure the foreground of the entry widget appropriately
	if { $_referenceMatches } {
		$itk_component(entry) configure \
        -foreground $itk_option(-matchColor) \
        -disabledforeground $itk_option(-matchColor)
	} else {
		$itk_component(entry) configure \
        -foreground $itk_option(-mismatchColor) \
        -disabledforeground $itk_option(-mismatchColor)
	}
    if {$itk_option(-updateValueOnMatch)} {
        updateRegisteredComponents -value
    }
}

body DCS::Entry::get {} {

	set value [$itk_component(entry) get]

	if {$itk_option(-units) != "" } {
		# return a cleaned up version of the value
		return [list [getCleanValue $value $itk_option(-entryType) $itk_option(-decimalPlaces)] $itk_option(-units)]
	} else {
		return [getCleanValue $value $itk_option(-entryType) $itk_option(-decimalPlaces)]
	}
}

body ::DCS::Entry::setValue { value_ {directAccess_ 0} } {
    set _inSetValue 1
	if {$value_ != "" } {
		#value can be a list of value and units or value only
		foreach {value units} $value_ {break;}

		if { $units != "" && $itk_option(-unitConvertor) != ""  && $itk_option(-entryType) != "string" && $itk_option(-entryType) != "rootDirectory"} {
			#if { $_lastUnits == "" } {
			#	set _lastUnits $units
			#}

			set _fullValue [$itk_option(-unitConvertor) convertUnits $value $units $_lastUnits]
			#puts "ENTRY: $this is remembering $_fullValue"
		} else {
			set _fullValue $value_
			#puts "ENTRY: $this is remembering $_fullValue"
		}
	} else {
		set _fullValue ""
	}

	# make a cleaned up copy of the new value
	set v [getCleanValue $_fullValue $itk_option(-entryType) $itk_option(-decimalPlaces)]

	# pad with zeros if required and value is a valid integer
	if { $itk_option(-zeroPadDigits) > 0 && [isInt $v] } {
		set v [format %0${itk_option(-zeroPadDigits)}d $v]
	}

    set v [value2display $v]

   #check if the current entry is exactly the same
   set currentValue [$itk_component(entry) get]

   if {$v == $currentValue && $directAccess_ == 1} {
      #puts "no need to change $currentValue=$v"
        set _inSetValue 0
      return
   }

    set currentState [$itk_component(entry) cget -state]
    if {$currentState != "normal"} {
	    $itk_component(entry) configure -state normal
    }

	# delete current contents of entry
	set _deletingValue 1
	$itk_component(entry) delete 0 end
	set _deletingValue 0

	# insert new value
	set _forcedValue $v
	$itk_component(entry) insert 0 $v
    if {$currentState != "normal"} {
	    $itk_component(entry) configure -state $currentState
    }
	set _forcedValue ""
    switch -exact -- $itk_option(-entryType) {
        rootDirectory {
            adjustRight
        }
        "" -
        string -
        field {
            if {$itk_option(-entryJustify) == "right"} {
                adjustRight
            }
        }
        int -
        positiveInt -
        float -
        positiveFloat -
        default {
            ##no need to ajust xview
        }
    }
	updateEntryWidget

	if { ! $directAccess_ && $itk_option(-state) == "normal"} {
		if { $itk_option(-onSubmit) != "" && $_ready} {
			set submitCommand [replace%sWithValue $itk_option(-onSubmit)]

			eval $submitCommand
		}
	}
    set _inSetValue 0
}

body DCS::Entry::updateEntryWidget {} {}


body DCS::Entry::convertUnits { value_ fromValue_ toValue_ } {

	if {$value_ == ""} return ""

	if {$itk_option(-unitConvertor) != "" } {
		return [$itk_option(-unitConvertor) convertUnits $value_ $fromValue_ $toValue_]
	} else {
		return [::units convertUnits $value_ $fromValue_ $toValue_]
	}
}

configbody DCS::Entry::decimalPlaces {
	#puts "ENTRY: decimal place $itk_option(-decimalPlaces)"
	setValue $_fullValue
}



configbody DCS::Entry::reference {

	if {$itk_option(-reference) != "" } {

		# unregister with last reference component
		if { $_lastReferenceComponent != "" } {
			::mediator unregister $this $_lastReferenceComponent $_referenceVariable
		}

		# extract reference component and variable
		foreach {_referenceComponent _referenceVariable} $itk_option(-reference) {break}

		# register with new reference component
		if { $_referenceComponent == "" } {

			updateReferenceMatches

		} else {
			::mediator register $this $_referenceComponent $_referenceVariable handleUpdateFromReference $_referenceVariable

			if {$itk_option(-autoGenerateUnitsList) } {
				changeUnitsList
			}

			#use the reference for converting units
			configure -unitConvertor $_referenceComponent
		}

		# keep name of last reference component
		set _lastReferenceComponent $_referenceComponent
	}
}


body DCS::Entry::updateFromReference { } {

	# copy value of reference object into local value variable
	#puts "ENTRY: $_referenceValue <----"

	setValue $_referenceValue 1
}

#override the base clase definition of trigger states.
body DCS::Entry::handleNewOutput { } {
	recalcState
}

body DCS::Entry::recalcState { } {
    if { $itk_option(-state) == "labeled"} {
        set _state labeled
	    updateState
	    updateBubble
        return
    }

	#if the widget is disabled, it doesn't matter what the gate says
    if { $itk_option(-state) == "disabled" || $_gateOutput == 0 } {
		set _state disabled
	} else {
		set _state normal
	}

	updateState
	updateBubble
}

# ------------------------------------------------------------------
# METHOD: delete
#
# Thin wrap of the standard entry widget delete method.
# ------------------------------------------------------------------
body DCS::Entry::delete {args} {
    return [eval $itk_component(entry) delete $args]
}

# ------------------------------------------------------------------
# METHOD: icursor 
#
# Thin wrap of the standard entry widget icursor method.
# ------------------------------------------------------------------
body DCS::Entry::icursor {args} {
	return [eval $itk_component(entry) icursor $args]
}

# ------------------------------------------------------------------
# METHOD: index 
#
# Thin wrap of the standard entry widget index method.
# ------------------------------------------------------------------
body DCS::Entry::index {args} {
    return [eval $itk_component(entry) index $args]
}

# ------------------------------------------------------------------
# METHOD: insert 
#
# Thin wrap of the standard entry widget index method.
# ------------------------------------------------------------------
body DCS::Entry::insert {args} {
    return [eval $itk_component(entry) insert $args]
}

# ------------------------------------------------------------------
# METHOD: scan 
#
# Thin wrap of the standard entry widget scan method.
# ------------------------------------------------------------------
body DCS::Entry::scan {args} {
    return [eval $itk_component(entry) scan $args]
}

# ------------------------------------------------------------------
# METHOD: selection
#
# Thin wrap of the standard entry widget selection method.
# ------------------------------------------------------------------
body DCS::Entry::selection {args} {
    return [eval $itk_component(entry) selection $args]
}

# ------------------------------------------------------------------
# METHOD: xview 
#
# Thin wrap of the standard entry widget xview method.
# ------------------------------------------------------------------
body DCS::Entry::xview {args} {
    return [eval $itk_component(entry) xview $args]
}

# ------------------------------------------------------------------
# METHOD: clear 
#
# Delete the current entry contents.
# ------------------------------------------------------------------
body DCS::Entry::clear {} {
    $itk_component(entry) delete 0 end
    icursor 0
}

body DCS::Entry::handleReferenceMatchChange { - } {

	# update registered objects waiting for referenceMatches asynchronously
	updateRegisteredComponents -referenceMatches
}

# ------------------------------------------------------------------
# METHOD: bbox 
#
# Thin wrap of the standard entry widget bbox method.
# ------------------------------------------------------------------
body DCS::Entry::bbox {args} {
	return [eval $itk_component(entry) bbox $args]
}


configbody DCS::Entry::autoGenerateUnitsList {
	autoGenerateUnitsList
}

body DCS::Entry::autoGenerateUnitsList {} {
	if {$itk_option(-autoGenerateUnitsList) !="" } {
		changeUnitsList
	}
}

configbody DCS::Entry::unitsList {
	if {$itk_option(-unitsList) != "" } {
		changeUnitsList 
	}
}

body DCS::Entry::changeUnitsList { } {

    if {[string first positive $itk_option(-entryType)] < 0} {
        set floatType float
        set intType   int
    } else {
        set floatType positiveFloat
        set intType   positiveInt
    }
	
	set count 0
	$itk_component(unitsmenu) delete 0 last

	if { $itk_option(-autoGenerateUnitsList) } {
		#ask the device itself for the best units to use
		if {$_referenceComponent != "" } {

			set possibleUnits [$_referenceComponent getRecommendedUnits]

			set unitsList ""

			foreach unitType $possibleUnits {

				lappend unitsList $unitType

				if { $unitType != "steps" } {
					foreach {decimalPlaces precision} [$_referenceComponent getRecommendedPrecision $unitType] break
					lappend unitsList "-entryType $floatType -decimalPlaces $decimalPlaces -precision $precision -unitsForeground black"
				} else {
					lappend unitsList "-entryType $intType -unitsForeground blue"
				}
			}
			
			#puts "ENTRY: $_referenceComponent $unitsList:  $unitType  $decimalPlaces $precision"

		} else {
			#wait for the device to get configured
			return
		}
	} else {
		set unitsList $itk_option(-unitsList)
	}
	
	#get the units and the configuration command (specification) for each units in the list 
	foreach {unit specification} $unitsList {
		
		set _units($unit,specification) $specification
		
		$itk_component(unitsmenu) add command -label $unit -command [list $this configure -units $unit]
		incr count
	}
	
	#The units list won't appear if there are no optional units
	if {$count < 2} {
		$itk_component(units) configure -state disabled
	} else {
		$itk_component(units) configure -state normal -cursor hand2
	}
	
	#configure -units [lindex $itk_option(-unitsList 0]
	#repack
}

configbody DCS::Entry::alternateShadowReference {

	if {$itk_option(-alternateShadowReference) != "" } {

		#follow a different reference.
		# unregister with last reference component
		if { $_lastShadowReferenceComponent != "" } {
			::mediator unregister $this $_lastShadowReferenceComponent $_shadowReferenceVariable
		}
		
		# extract reference component and variable
		foreach {_shadowReferenceComponent _shadowReferenceVariable} $itk_option(-alternateShadowReference) {break}
		
		# register with new reference component
		if { $_shadowReferenceComponent == "" } {
		} else {
			::mediator register $this $_shadowReferenceComponent $_shadowReferenceVariable handleUpdateFromShadowReference $_shadowReferenceVariable
		}
		
		# keep name of last reference component
		set _lastShadowReferenceComponent $_shadowReferenceComponent
	}
}

configbody DCS::Entry::units {
	if {$itk_option(-units) != "" } {
		changeUnits $itk_option(-units)
	}
}

body DCS::Entry::changeUnits { units_ } {
	
	#return quickly if the change is not significant
	if { $units_ == $_lastUnits } {
		#reconfigure the entry
		reconfigureEntry $units_
		return
	}

	#change the label on the units selection button
	$itk_component(units) configure -text $units_


	#leave here if we are not supposed to convert
	if { ! $itk_option(-autoConversion) } {
		set _lastUnits $itk_option(-units)
		reconfigureEntry $units_
		return
	}
	
	#if the convertor object is defined, do the conversion
	if {$_lastUnits != "" && $itk_option(-unitConvertor) != "" } {

		set convertedValue [$itk_option(-unitConvertor) convertUnits $_fullValue $_lastUnits $units_]
		
		#set the value directly before we reconfigure the entry, otherwise
		#  a message will be generated for a reference mismatch
		setValue $convertedValue
		
		#When the units change, reconfigure the entry
		reconfigureEntry $units_

		#puts "ENTRY: $convertedValue $_referenceValue"
		
	} else {
		setValue $_fullValue
	}
	
	set _lastUnits $units_
	
	#let others know that there has been a change in units
	updateRegisteredComponents -units
	
	#repack
}

body DCS::Entry::reconfigureEntry { units_ } {
	#Reconfigure the entry for the 
	if { [info exists _units($units_,specification) ] } {
		
		eval configure $_units($units_,specification)

		setValue $_fullValue
	}
}

body DCS::Entry::adjustRight { } {
    set vv [xview]
    foreach {start end} $vv break
    if {$end < 1.0} {
        #set newStart [expr $start + 1.0 - $end]
        set newStart 1.0
        xview moveto $newStart
    }
}

body DCS::Entry::updateReferenceMatches {} {
	if { $_referenceValue  == "" } { return }

    if {$itk_option(-submitFullValue)} {
	    set _referenceMatches [checkValuesMatch $_fullValue $_referenceValue]
    } else {
	    set _referenceMatches [checkValuesMatch $_value $_referenceValue]
    }
    if {$_referenceMatches \
    &&  $itk_option(-onlyMatchNumber) \
    &&  ![string is double -strict $_value] \
    } {
        set _referenceMatches 0
    }
	
	if { $_lastReferenceMatches != $_referenceMatches } {
		set _lastReferenceMatches $_referenceMatches
		handleReferenceMatchChange $_referenceMatches
		updateEntryColor
	}
}

class DCS::DirectoryEntry {
	inherit ::DCS::Entry

    itk_option define -listLength listLength ListLength 20 {
        $itk_component(candidates) configure \
        -visibleitems $itk_option(-entryWidth)x$itk_option(-listLength)
    }

    protected variable _oldValueForCandidates ""
    protected variable _do_not_refresh_candidates 0
    protected variable _listBox ""
    protected variable _candidatesDisplayed 0

    private common uniqueNameCounter 0
    private variable _listboxVariableName ""

    public method handleSelectionChange { }
    public method handleCandidatesMotion { y }
    public method handleEntryKey { k }

    public method getDirOK { } {
        set eList [file split [get]]
        foreach e $eList {
            if {[string equal -nocase $e username]} {
                return 0
            }
        }
        return 1
    }

    public method handleButtonClick { } {
        if {$_candidatesDisplayed} {
            hideCandidates
        } else {
            #puts "refresh candidates by click"
            refreshCandidates [get]
            showCandidates
        }
    }

    protected method updateEntryFromSelection { }

    protected method refreshCandidates { value } {
        if {$_state != "normal"} return

        if {$_oldValueForCandidates == $value} {
            return
        }

        set _oldValueForCandidates $value
        set cList [getDirectoryCandidateList $_oldValueForCandidates]
        set $_listboxVariableName $cList

        set ll [llength $cList]
        if {$ll > $itk_option(-listLength)} {
            set ll $itk_option(-listLength)
        }
        $_listBox configure \
        -visibleitems $itk_option(-entryWidth)x$ll
    }
    
    public proc getExistingDir { path } {
        set tail "*"
        set dir [file nativename $path]
        while {$dir != "/"} {
            if {[file isdirectory $dir]} {
                break
            }
            set tail "[file tail $dir]*"
            set dir [file dirname $dir]
        }
        return [list $dir $tail]
    }
    public proc getDirectoryCandidateList { path } {
        foreach {dir pattern} [getExistingDir $path] break
        #puts "got dir=$dir pattern=$pattern"

        set canList [glob -nocomplain -directory $dir -types d -- $pattern]
        #foreach can $canList {
        #    puts "can=$can"
        #}
        set canList [lsort $canList]

        set result ""
        foreach can $canList {
            if {[valueValid $can rootDirectory]} {
                lappend result $can
            } else {
                log_warning not a good directory name: $can
                puts "not a good directory name: $can"
            }
        }

        return $result
    }

    ###override
    public method handleEscape { } {
        ### hide candidates and rollback to old value
        $_listBox selection clear 0 end
        updateEntryFromSelection
        hideCandidates

        #::DCS::Entry::handleEscape
    }
    public method handleOnSubmitChange { } {
        hideCandidates
        ::DCS::Entry::handleOnSubmitChange
    }
    public method handleFocusOut { } {
        hideCandidates

        ::DCS::Entry::handleFocusOut
    }
    public method handleReturn { } {
        hideCandidates

        ::DCS::Entry::handleReturn
    }
	protected method updateEntryWidth { } {
	    $itk_component(entry) configure -width $itk_option(-entryWidth)
        $itk_component(candidates) configure \
        -visibleitems $itk_option(-entryWidth)x$itk_option(-listLength)
    }
    protected method internalOnChange { } {
        #puts "internalOnChange: $_value"

        updateRegisteredComponents dirOK

        if {$_inSetValue} {
            return
        }

        if {!$_do_not_refresh_candidates} {
            #puts "refresh candidates by CHANGE"
            refreshCandidates $_value
            $_listBox yview moveto 0
        }
    }
    public method hideCandidates { } {
        if {!$_candidatesDisplayed} return

        place forget $_listBox
        $_listBox selection clear 0 end
        set _candidatesDisplayed 0
    }
    public method showCandidates { } {
        if {$_candidatesDisplayed} return
        if {$_state != "normal"} return

        set ww [winfo geometry .]
        set geo [split $ww "x+"]
        foreach {w0 h0 x0 y0} $geo break
        #puts "root : ww=$ww"

        set ww [winfo geometry $itk_component(entry)]
        set geo [split $ww "x+"]
        foreach {ew eh ex ey} $geo break
        set rx [winfo rootx $itk_component(entry)]
        set ry [winfo rooty $itk_component(entry)]
        #puts "entry : at $rx $ry ww=$ww"

        set float_x [expr $rx - $x0]
        set float_y [expr $ry - $y0 + $eh]
        set float_w [expr $ew + 13]

        set hReq [winfo reqheight $itk_component(candidates)]
        set hAvail [expr $h0 - $float_y]
        #puts "height: request $hReq available: $hAvail"

        #set wReq [winfo reqwidth $itk_component(candidates)]
        set wReq $float_w
        set wAvail [expr $w0 - $float_x]
        #puts "width: request $wReq available: $wAvail"

        #puts "show candidates at: $float_x $float_y w=$float_w"
        if {$hAvail >= $hReq} {
            set hSet ""
        } else {
            set hSet $hAvail
        }
        if {$wAvail >= $wReq} {
            set wSet $wReq
        } else {
            set wSet $wAvail
        }

        place $_listBox \
        -x $float_x \
        -y $float_y \
        -width $wSet \
        -height $hSet \
        -anchor nw
        raise $_listBox

        set _candidatesDisplayed 1
    }

	constructor { args } {
        ::DCS::Component::constructor { -value get dirOK getDirOK}
    } {


        incr uniqueNameCounter
        set _listboxVariableName ::EntryListBox$uniqueNameCounter
        set lbName candidates$uniqueNameCounter

        ###create at top level so that it can be displayed anywhere
        itk_component add candidates {
            ::iwidgets::scrolledlistbox .$lbName \
            -listvariable $_listboxVariableName \
            -selectioncommand "$this handleSelectionChange" \
            -selectbackground #a0a0c0 \
            -visibleitems 128x20 \
            -scrollmargin 0 \
            -sbwidth 10 \
            -textbackground white \
            -hscrollmode static \
            -vscrollmode static \
            -selectborderwidth 0 \
            -borderwidth 1 \
        } {
            rename -selectbackground activeBackground activeBackground ActiveBackground
        }


        eval itk_initialize $args

        set _listBox $itk_component(candidates)
        set lb [$_listBox component listbox]

        bind $_listBox <Leave> "$this hideCandidates"
        bind $lb  <Motion> "+$this handleCandidatesMotion %y"

        bind $itk_component(entry) <Key> "+$this handleEntryKey %k"
        bind $itk_component(entry) <Button-1> "+$this handleButtonClick"

        if { [namespace tail [$this info class]] == "DirectoryEntry" } {
            announceExist
            repack
            updateEntryColor
            set _ready 1
        }
    }
    destructor {
        unregisterComponent
        announceDestruction
    }
}
body DCS::DirectoryEntry::updateEntryFromSelection { } {
    if {$_listBox == ""} {
        return
    }
    set i [$_listBox curselection]
    set i [lindex $i 0]
    if {$i !=""} {
        set v [lindex [set $_listboxVariableName] $i]
    } else {
        set v $_oldValueForCandidates
    }

    set _do_not_refresh_candidates 1
    setValue $v
    set _do_not_refresh_candidates 0
}
body DCS::DirectoryEntry::handleSelectionChange { } {
    #puts "selection changed"
    updateEntryFromSelection

    hideCandidates
}
body DCS::DirectoryEntry::handleEntryKey { k } {
    puts "got key: $k"

    set i [$_listBox curselection]
    set i [lindex $i 0]
    $_listBox selection clear 0 end

    switch -exact -- $k {
        "104" {
            ##down
            #puts "got down current i=$i"
            if {$i == ""} {
                set _oldValueForCandidates [$itk_component(entry) get]
                $_listBox selection set 0
                $_listBox see 0
            } else {
                #puts "try go down"
                set l [$_listBox size]
                incr i
                if {$i >= $l} {
                    #puts "wrap back to old value"
                } else {
                    #puts "really go down"
                    $_listBox selection set $i
                    $_listBox see $i
                }
            }
            updateEntryFromSelection
        }
        "98" {
            ##up
            #puts "got up current i=$i"
            if {$i == ""} {
                set _oldValueForCandidates [$itk_component(entry) get]
                $_listBox selection set end
                $_listBox see end
            } else {
                #puts "try go up"
                incr i -1
                if {$i < 0} {
                    #puts "wrap back to old value"
                } else {
                    #puts "really go up"
                    $_listBox selection set $i
                    $_listBox see $i
                }
            }
            updateEntryFromSelection
        }
        "36" {
            ### return: we submit
            puts "got 36: return"
        }
        "9" {
            ### esc: we put back the old value
            puts "got 9 esc"
        }
    }

    if {$k == 36 || $k == 9} {
        hideCandidates
    } else {
        showCandidates
    }
}
body DCS::DirectoryEntry::handleCandidatesMotion { y } {
    set i [$_listBox curselection]
    set i [lindex $i 0]

    set i_new [$_listBox nearest $y]

    if {$i_new < 0 || $i_new == $i} {
        return
    }

    $_listBox selection clear 0 end
    $_listBox selection set $i_new
}

class DCS::MenuEntry  {

	# inheritance
	inherit ::DCS::Entry
	
    public proc getArrowImage { } {
        return $arrowButtonImage
    }

	public method selectMenuItem { newValue }
	public method add
    public method removeAll { } {
		$itk_component(Menu) delete 0 end
    }
	
	protected method updateEntryWidget {}
	protected method updateState {}
	protected method repack 
	protected method updateEntryWidth
	protected method updateEntryColor
	
	public method getCurrentMenuChoiceIndex
	
	itk_option define -showEntry showentry ShowEntry 1
	itk_option define -showArrow showarrow ShowArrow 1
	itk_option define -fixedEntry fixedentry FixedEntry "" 
	itk_option define -menuColumnWidth menucolumnwidth MenuColumnWidth {8}
	itk_option define -menuColumnBreak menucolumnbreak MenuColumnBreak {35}
	itk_option define -menuColumnMargin menucolumnmargin MenuColumnMargin {20}
	itk_option define -menuEntryCount menuentrycount MenuEntryCount {0}
	itk_option define -menuChoices menuchoices MenuChoices {} { updateMenu }
	itk_option define -menuChoiceDelta menuchoicedelta MenuChoiceDelta 10000.0
	itk_option define -extraMenuChoices extraMenuchoices ExtraMenuChoices {} { updateMenu }

	itk_option define -onAnyClick onAnyClick OnAnyClick "" {
        if {$itk_option(-onAnyClick) != ""} {

            #########base class components
            #$itk_component(unitsmenu) configure \
            #-postcommand $itk_option(-onAnyClick)

            bind $itk_component(units) <Button-1> $itk_option(-onAnyClick)
            bind $itk_component(prompt) <Button-1> $itk_option(-onAnyClick)
            bind $itk_component(entry) <Button-1> $itk_option(-onAnyClick)

            ##########this class components
            #$itk_component(Menu) configure \
            #-postcommand $itk_option(-onAnyClick)
            bind $itk_component(dropdown) <Button-1> $itk_option(-onAnyClick)

            bind $itk_component(arrowButton) <Button-1> +$itk_option(-onAnyClick)
        }
    }


	private common arrowButtonImage
	set arrowButtonImage [image create bitmap -foreground black -data \
		"#define arrow_width 16
		#define arrow_height 16
		static unsigned char arrow_bits[] = {
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfc, 0x1f,
		0xf8, 0x0f, 0xf0, 0x07, 0xe0, 0x03, 0xc0, 0x01, 0x80, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};"]


	protected common blankLine "                                             "
	protected variable m_menuEntryCounts 0
    
    protected method updateMenu { }

	# constructor
	constructor { args } {::DCS::Component::constructor { -value get \
																				 -referenceMatches getReferenceMatches \
																				 -units "$this getUnits" \
																				 status "cget -state"} } {
			
		itk_component add dropdown {
			# create the menubutton, which is going to be hidden with some
			#fancy packing/placing under the entry box.  Another button
			#will be created which will have the pop up menu event bound to
			# it.  This allows the pop-up to appear directly under the entry and
			#also has the effect of disapearing when the button is released.
			menubutton $itk_interior.menu -menu $itk_interior.menu.menu
		} {
			keep -cursor -activeforeground -font -foreground
			#rename -background -entryButtonBackground entryButtonBackground EntryButtonBAckground
			rename -justify -entryJustify entryjustify EntryJustify
            rename -anchor -dropdownAnchor dropdownAnchor DropdownAnchor
		}

		itk_component add Menu {
			# create the button
			menu $itk_interior.menu.menu -tearoff 0 -activeborderwidth 0
		} {
			#	keep  -cursor -activeforeground -foreground
			rename -activebackground -menuActiveBackground activebackground ActiveBackground
			rename -background -menuBackground menuBackground MenuBackground
		}


		# create the arrow button
		itk_component add arrowButton {
			label $itk_interior.arrowButton	\
				 -image $arrowButtonImage -width 16 -anchor c -relief raised
		} {
			
		}
		
		if { [info tclversion] < 8.4 } {
			# bind menu posting to button click on the "fake" menu button
			bind $itk_component(arrowButton) <Button-1> \
				 "tkMbPost $itk_component(dropdown) %X %Y"
			bind $itk_component(arrowButton) <ButtonRelease-1> \
				 "tkMbButtonUp $itk_component(dropdown)"
		} else {
			# bind menu posting to button click on the "fake" menu button
			bind $itk_component(arrowButton) <Button-1> \
				 "tk::MbPost $itk_component(dropdown) %X %Y"
			bind $itk_component(arrowButton) <ButtonRelease-1> \
				 "tk::MbButtonUp $itk_component(dropdown)"
		}

		#bind $itk_interior <FocusOut> "$this handleSubmit"

		$arrowButtonImage configure -foreground black

		
		# get configuration options
		eval itk_initialize $args
		
		#allow the component mediator to know that this
		if { [namespace tail [$this info class]] == "MenuEntry" } {
			announceExist
			updateEntryColor
			set _ready 1
		}
	}

	destructor {
		announceDestruction
	}

}

configbody DCS::MenuEntry::showEntry {

	updateEntryWidget
	repack
}


#thin wrapper for adding a menu option with command
body DCS::MenuEntry::add { args } {
    incr m_menuEntryCounts
	set columnBreak [expr ($m_menuEntryCounts % $itk_option(-menuColumnBreak) ) == 0]
    
	eval $itk_component(Menu) add $args -columnbreak $columnBreak
}


body DCS::MenuEntry::repack {} {

	#Forget the packing of the entry which has already happened in the base class
	grid forget $itk_component(prompt)
	grid forget $itk_component(entry)
	grid forget $itk_component(dropdown)
	grid forget $itk_component(arrowButton)
	grid forget $itk_component(units)


	if { $itk_option(-showPrompt) } {
		grid $itk_component(prompt) -column 0 -row 0 -stick e
	} else {
		grid forget $itk_component(prompt)
   }

	if { $itk_option(-showEntry) } {
		grid $itk_component(entry) -column 1 -row 0 -ipadx 2 
		grid $itk_component(dropdown) -column 1 -row 0
		#Make sure the entry box hides the "real" menu button.
		raise $itk_component(entry)

	} else {
		grid $itk_component(dropdown) -column 1 -row 0
	}
	#pack the "fake" menu button
    if {$itk_option(-showArrow)} {
	    grid $itk_component(arrowButton) -column 2 -row 0 -sticky news
    }

	#pack the units
	if {$itk_option(-showUnits)} {
		grid $itk_component(units) -column 3 -row 0 -sticky w
	}
}


body DCS::MenuEntry::updateMenu { } {

    $itk_component(Menu) delete 0 end

    set menuEntryCount 0
    set columnBreak 0
    # create left margin
    set leftMargin [string range $blankLine 0 $itk_option(-menuColumnMargin)]

	if { $itk_option(-menuChoices) != "" } {
		foreach choice $itk_option(-menuChoices) {
			
			set length [string length $choice]
			set rightMargin [string range $blankLine 0 \
										[expr $itk_option(-menuColumnWidth) - $length - $itk_option(-menuColumnMargin)] ]
			$itk_component(Menu) add command \
				 -label "${leftMargin}${choice}${rightMargin}"	\
				 -command [list $this setValue "$choice"] \
				 -columnbreak $columnBreak
			
			# count the menu entries
			incr menuEntryCount
			
			set columnBreak [expr ($menuEntryCount % $itk_option(-menuColumnBreak) ) == 0]
		}
	}
	if { $itk_option(-extraMenuChoices) != "" } {
		foreach item $itk_option(-extraMenuChoices) {
			foreach {choice cmd} $item break
			set length [string length $choice]
			set rightMargin [string range $blankLine 0 \
										[expr $itk_option(-menuColumnWidth) - $length - $itk_option(-menuColumnMargin)] ]
			$itk_component(Menu) add command \
				 -label "${leftMargin}${choice}${rightMargin}"	\
				 -command $cmd \
				 -columnbreak $columnBreak
			
			# count the menu entries
			incr menuEntryCount
			
			set columnBreak [expr ($menuEntryCount % $itk_option(-menuColumnBreak) ) == 0]
		}
    }
}

#Return an index into the list of current menu choices
# Returns -1 if the current selection doesn't match an entry exactly
body DCS::MenuEntry::getCurrentMenuChoiceIndex {} {

	set currentChoice [get]

	set menuChoiceIndex [lsearch -exact $itk_option(-menuChoices) $currentChoice] 

	return $menuChoiceIndex
}


body DCS::MenuEntry::selectMenuItem { newValue } {

	# assign new choice to the value of the widget
	setValue $newValue
    xview 0
}



#the configbody of a base clase cannot be overidden.
#this function allows the change in value to do extra stuff when
#the value changes.
body DCS::MenuEntry::updateEntryWidget {} {

	# call the parent class method
	::DCS::Entry::updateEntryWidget
	
   if { $itk_option(-showEntry) } {
      #the entry can be edited with the keyboard
      #shrink the border so that it cannot be seen under the entry widget.

		$itk_component(dropdown) configure \
         -borderwidth 0 \
         -background white

      return
   }

   if { $itk_option(-fixedEntry) != "" } {
      #The entry only shows a fixed label, but the value can be selected.
      #The value cannot be edited via keyboard.	
      $itk_component(dropdown) configure -text $itk_option(-fixedEntry) \
         -relief raised -background $itk_option(-activeBackground) -borderwidth 2
      return
   }

   #the menubutton shows the current selection, and cannot be edited	
   $itk_component(dropdown) configure -text [get] -relief sunken \
      -background white -borderwidth 2
}

body DCS::MenuEntry::updateState {} {
	Entry::updateState

	switch $_state {
		normal {
			$itk_component(dropdown) configure -state normal

			#pack the "fake" menu button
            if {$itk_option(-showArrow)} {
	            grid $itk_component(arrowButton) -column 2 -row 0 -sticky news
			    $itk_component(arrowButton) configure -background $itk_option(-activeBackground)
			    $itk_component(arrowButton) configure -state normal 
            }
         if { !$itk_option(-showEntry) && $itk_option(-fixedEntry) ==""} {
            $itk_component(dropdown) configure -background white
         }
		}
        labeled -
		disabled {
			$itk_component(dropdown) configure -state disabled
			$itk_component(arrowButton) configure -background $itk_option(-disabledbackground)
			$itk_component(arrowButton) configure -state disabled 
         if { !$itk_option(-showEntry) && $itk_option(-fixedEntry) ==""} {
            $itk_component(dropdown) configure -background $itk_option(-disabledbackground)
		   }
	   }
   }
}

configbody DCS::MenuEntry::fixedEntry {
	updateEntryWidget
}

body DCS::MenuEntry::updateEntryWidth {} {

	if {$itk_option(-entryWidth) != "" } {

		$itk_component(entry) configure -width $itk_option(-entryWidth)
		$itk_component(dropdown) configure -width $itk_option(-entryWidth) 
	}
}

body DCS::MenuEntry::updateEntryColor {} {
	
	if { $itk_option(-showEntry) } {
		DCS::Entry::updateEntryColor
	}
	
	# configure the dropdown button color
	if { $_referenceMatches } {
		$itk_component(dropdown) configure -foreground $itk_option(-matchColor)
	} else {
		$itk_component(dropdown) configure -foreground $itk_option(-mismatchColor)
	}
}

#entry with + and - symbols on each side.
class DCS::ZoomEntry {

 	inherit ::itk::Widget

   public method get {} {return [$itk_component(entry) get]}
   public method setValue { value_ {directAccess_ 0} } {
      $itk_component(entry) setValue $value_ $directAccess_
   }

   constructor {args} {

	   global gBitmap

	   # make decrease button
	   itk_component add decrease {
		   button $itk_interior.d -image $gBitmap(minus_sign) \
			   -width 15 -height 15
      } {
         rename -command -decreaseCommand decreaseCommand DecreaseCommand
      }

      itk_component add label {
         label $itk_interior.label
      } {
         keep -text
      }


      itk_component add entry {
         DCS::Entry $itk_interior.e	\
         -entryJustify right -activeClientOnly 0 -systemIdleOnly 0
      } {
         keep -onSubmit
         keep -entryWidth
         keep -entryType
      }

	   # make the increase buttons
	   itk_component add increase {
		   button $itk_interior.u -image $gBitmap(plus_sign) \
			   -width 15 -height 15
      } {
         rename -command -increaseCommand increaseCommand IncreaseCommand
      }

      eval itk_initialize $args

      grid columnconfigure $itk_interior  1 -weight 1

      grid $itk_component(label) -column 0 -row 0 -sticky ew -columnspan 3
      grid $itk_component(decrease) -column 0 -row 1 -sticky w
      grid $itk_component(entry) -column 1 -row 1 -stick ew
      grid $itk_component(increase) -column 2 -row 1 -sticky w

   }
}



proc testEntry {} {
	
	DCS::Entry .t -promptText hello   -unitsList "mm {-decimalPlaces 1} um {-decimalPlaces 4}" -shadowReference 1 -entryType float -units mm -entryWidth 12 -reference "::.y -value" -activeClientOnly 0 -systemIdleOnly 0
	pack .t


	DCS::Entry .y -promptText hello -unitsList "mm {-decimalPlaces 6} um {-decimalPlaces 3}"  -shadowReference 1 -entryType float  -units mm -entryWidth 12 -activeClientOnly 0 -systemIdleOnly 0
# -reference "::.t -value"
	pack .y
	
	DCS::Entry .u -promptText hello -unitsList "mm {-decimalPlaces 6} um {-decimalPlaces 3}"  -alternateShadowReference {::.y -value} -entryType float  -units mm -entryWidth 12  -reference "::.t -value" -activeClientOnly 0 -systemIdleOnly 0
	pack .u

}

#testEntry
