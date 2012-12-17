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
package provide DCSDeviceView 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSTitledFrame
#package require DCSEntry
package require DCSEntry
package require DCSDeviceFactory
package require ComponentGateExtension


class ::DCS::MotorViewEntry {
	inherit ::DCS::MenuEntry

	itk_option define -device device Device ""
	itk_option define -honorStatus honorStatus HonorStatus 1 {
        handleNewOutput
    }

    #### if the position does not match this motor,
    #### the request to move will be true
	itk_option define -extraDevice extradevice Device ""

    #### 0: no check
    #### 1: check
    #### -1: check even when limits are off
    itk_option define -checkLimits checkLimits CheckLimits 0 {
        updatePromptColor
    }

    itk_option define -warningOutside warningOutside WarningOutside "" {
        if {[llength $itk_option(-warningOutside)] >= 2} {
            foreach {w0 w1} $itk_option(-warningOutside) break
            set u0 ""
            set u1 ""
            foreach {v0 u0} $w0 break
            foreach {v1 u1} $w1 break
            set m_warningOutsideP0 \
            [$itk_option(-device) convertToBaseUnits $v0 $u0]
            set m_warningOutsideP1 \
            [$itk_option(-device) convertToBaseUnits $v1 $u1]
        } else {
            set m_warningOutsideP0 ""
            set m_warningOutsideP1 ""
        }
        updatePromptColor
    }

    ### callback with 1 (ok) or 0 (no)
    itk_option define -onLimitsCheck onLimitsCheck OnLimitsCheck ""

	itk_option define -autoMenuChoices automenuchoices AutoMenuChoices 1 {
	    createMenuChoices
    }
	itk_option define -moveByEnabled moveByEnabled MoveByEnabled 0
	
	# public variables
	public variable menuChoices 		""
	public variable lastDevice ""
    public variable lastExtraDevice ""

    private variable m_origPromptForeground black
    private variable m_limitsOK 1
    private variable m_extraDeviceReady 0
    private variable m_extraDevicePosition 0
    private variable m_matchExtraDevice 1

    private variable m_warningOutsideP0 ""
    private variable m_warningOutsideP1 ""

	# protected methods
    ## we need this hook to adjust "moveBy" entryType:
    protected method onEntryTypeChange { } {
        set type $itk_option(-entryType)
        switch -exact $type {
            positiveFloat {
                set type float
            }
            positiveInt {
                set type int
            }
        }
        $itk_component(moveBy) configure \
        -entryType $type
    }

	public method createMenuChoices {args}

	# public method
	#public method changeDeviceStatus { - - value -}
	public method moveToValue {}
	public method getMoveCommand {}
	public method changeClientState
	public method handleMotorConfig
	public method getStatus {}
#	public method updateScaleFactorEquation { units }
	public method getMoveRequestStatus
	protected method handleReferenceMatchChange
	public method handleMoveByReferenceMatchChange
	public method cancelChanges
	public method toggleMoveBy
	public method moveBy
	public method changeUnits
    public method updateState

    public method handleExtraDevice

    public method getLimitsOK { } { return $m_limitsOK }

    private method checkExtraDevice { }

    private method updatePromptColor { } {
        if {$itk_option(-device) == ""} {
            return
        }
        if {!$itk_option(-checkLimits)} {
            return
        }

        foreach {value units} [get] break
    
        set value $_value
        set value [$itk_option(-device) convertToBaseUnits $value $units]

        set even_if_limits_off 0
        if {$itk_option(-checkLimits) < 0} {
            set even_if_limits_off 1
        }
        set m_limitsOK \
        [$itk_option(-device) limits_ok value $even_if_limits_off]

        if {$m_limitsOK} {
            set color $m_origPromptForeground
            if {[string is double -strict $m_warningOutsideP0] \
            && [string is double -strict $m_warningOutsideP1]} {
                if {$value < $m_warningOutsideP0 \
                || $value > $m_warningOutsideP1} {
                    set color brown
                }
            }
        } else {
            set color red
        }
        configure -promptForeground $color

        if {$itk_option(-onLimitsCheck) != ""} {
            eval $itk_option(-onLimitsCheck) $m_limitsOK
        
        }
    }

    #override
    protected method handleNewOutput { } {
        if {$itk_option(-honorStatus)} {
            DCS::ComponentGateExtension::handleNewOutput
        } else {
            set _state normal
            updateState
            updateBubble
        }
    }
	protected method updateEntryWidget {} {
        updatePromptColor
        if {$_ready && $m_extraDeviceReady} {
            checkExtraDevice
        }

	    # call the parent class method
	    ::DCS::MenuEntry::updateEntryWidget
    }
    protected method internalOnChange { } {
        #puts "internalOnChange: $_value"

        if {$_inSetValue} {
            return
        }
        #puts "updatePromptColor get=[get]"
        updatePromptColor
    }

	protected method repack

	#private method updateWidgetState {}
	#private variable _deviceStatus "moving"
	#private variable _clientState "passive"
	#private variable _baseUnits ""
	#private variable _effectiveUpperLimit ""
	#private variable _effectiveLowerLimit ""
	private variable _constructed 0

	constructor { args } {

		::DCS::Component::constructor \
			 { -value {get} -moveRequest {getMoveRequestStatus} -status { getStatus } -units {getUnits} }
	} {
		set _constructed 0
		
		global BLC_DIR
		
		itk_component add moveBy {
			DCS::MenuEntry $itk_interior.mbe -referenceValue 0 \
				 -entryType float -entryJustify right \
				 -menuChoices {1.0 0.5 0.1 0.0 -0.1 -0.5 -1.0} \
				 -autoConversion 1 \
				 -promptText "" -bitmap @[file join $BLC_DIR images delta.xbm] \
				 -showPrompt 0
		} {
			keep -state -promptWidth -precision -entryWidth -decimalPlaces -unitsList -units -unitConvertor -promptForeground

		}

		$itk_component(moveBy) setValue 0

        set m_origPromptForeground $itk_option(-promptForeground)
		eval itk_initialize $args

		#default values. This is a workaround to avoid the assignment of the default
		#value to the option during the itk_initialize, if the option has been kept.
		#check to see if the options were defined when this object was constructed. If
		#not, set them now.
		array set definedOptions $args
		if { ![info exists definedOptions(-menuColumnMargin)] } {
			configure -menuColumnMargin 4
		}

		if { ![info exists definedOptions(-entryType)] } {
			configure -entryType float
		}

		if { ![info exists definedOptions(-shadowReference)] } {
			configure -shadowReference 1
		}

		if { ![info exists definedOptions(-entryJustify)] } {
			configure -entryJustify right
		}

		if { ![info exists definedOptions(-entryWidth)] } {
			configure -entryWidth 8
		}

		if { ![info exists definedOptions(-autoConversion)] } {
			configure -autoConversion 1
		}

		if { ![info exists definedOptions(-showPrompt)] } {
			configure -showPrompt 0
		}

		set _constructed 1

 		#allow the component mediator to know that this is ready
		if { [namespace tail [$this info class]] == "MotorViewEntry" } {
			announceExist
			repack
            set _ready 1
		}		

		$itk_component(entry) configure -highlightcolor lightgray
	}

	destructor {
		announceDestruction
	}

}

body DCS::MotorViewEntry::repack {} {
 
    DCS::MenuEntry::repack 

	if { $itk_option(-moveByEnabled) } {
	    grid $itk_component(moveBy) -column 0 -row 1 -columnspan 10 -sticky w
	} else {
        grid forget $itk_component(moveBy) 
    }
}

body DCS::MotorViewEntry::updateState {} {
   DCS::MenuEntry::updateState

   switch $_state {
      normal {
         $itk_component(moveBy) configure -state normal
      }

      disabled {
         $itk_component(moveBy) configure -state disabled 
      }
   }
}

configbody DCS::MotorViewEntry::device {

	if { $itk_option(-device) != "" } {

		#get the name of the device
		set device $itk_option(-device)
        set deviceName [namespace tail $itk_option(-device)]
        set defaultUnits [::config getStr units.$deviceName]
        if {$defaultUnits == ""} {
            set defaultUnits [$itk_option(-device) cget -baseUnits]
        }
        configure -units $defaultUnits

		if { $device != $lastDevice } {
			#unregister
			::mediator unregister $this $lastDevice status
			::mediator unregister $this $lastDevice limits
			deleteInput "$lastDevice status"
		    deleteInput "$lastDevice permission"
		}
		
	    addInput "$device status inactive {supporting device}"
	    addInput "$device permission GRANTED {PERMISSION}"
		
		# set up references to the motor object
		#::mediator register $this $device status changeDeviceStatus
		::mediator register $this $device limits handleMotorConfig
		
		configure -reference "$device scaledPosition"
		
		# store the name of the device for next time
		set lastDevice $itk_option(-device)
	}
}
configbody DCS::MotorViewEntry::extraDevice {
    if {$itk_option(-extraDevice) == $lastExtraDevice} {
        return
    }

    set m_extraDeviceReady 0
    if {$lastExtraDevice != ""} {
		::mediator unregister $this $lastExtraDevice scaledPosition
    }
	if { $itk_option(-extraDevice) != "" } {
        set device $itk_option(-extraDevice)
        ::mediator register $this $device scaledPosition handleExtraDevice
	}
    set lastExtraDevice $itk_option(-extraDevice)
}

#thin wrapper for move command
###almost same as moveToValue
#this generate move command but not really move
#this is for serial move motors by sending
#all commands to dcss's scripting engine
#the command format is:
#  "motor_name to value [units]"
#  "motor_name by value [units]"
body ::DCS::MotorViewEntry::getMoveCommand {} {
	#handle the absolute move request
	if { ! $_referenceMatches } {
        foreach {value units} [get] break
        set value [$itk_option(-device) convertToBaseUnits $value $units]
		return "[$itk_option(-device) cget -deviceName] to $value"
	}

	#handle the relative move request if there is a entry in the moveBy field
	if { ! [$itk_component(moveBy) getReferenceMatches] } {
		$itk_component(moveBy) handleSubmit
		foreach {value units} [$itk_component(moveBy) get] break
        set value [$itk_option(-device) convertToBaseUnits $value $units]
		return "[$itk_option(-device) cget -deviceName] by $value"
	}
    if {!$m_matchExtraDevice} {
		return "[$itk_option(-device) cget -deviceName] by 0.0"
    }
    return ""
}
body ::DCS::MotorViewEntry::moveToValue {} {
	#handle the absolute move request
	if { ! $_referenceMatches } {
		foreach {destination units} [$this get] {break;}

		$itk_option(-device) move to $destination $itk_option(-units)
		return
	}

	#handle the relative move request if there is a entry in the moveBy field
	if { ! [$itk_component(moveBy) getReferenceMatches] } {
		$itk_component(moveBy) handleSubmit
		foreach {value units} [$itk_component(moveBy) get] break
		$itk_option(-device) move by $value $units
	}

    if {!$m_matchExtraDevice} {
		$itk_option(-device) move by 0.0
    }
}

body ::DCS::MotorViewEntry::getMoveRequestStatus {} {
	#If either the entry or the moveBy don't match their reference then this is
	#  is requesting a move.

	if {!$_referenceMatches \
    || !$m_matchExtraDevice \
    || ! [$itk_component(moveBy) getReferenceMatches] \
    } {
		return 1
	}
	
	#no move requested
	return 0
}

configbody ::DCS::MotorViewEntry::moveByEnabled {
	#set up callback when there is a change to the moveBy field
	if { $itk_option(-moveByEnabled) } {
		::mediator register $this ::$itk_component(moveBy) -referenceMatches handleMoveByReferenceMatchChange
	} else {
		#cancel the changes in the moveBy field
		$itk_component(moveBy) updateFromReference
		
		#unregister for interest in this widget
		::mediator unregister $this ::$itk_component(moveBy) -referenceMatches

		# update registered objects waiting for referenceMatches asynchronously
		updateRegisteredComponents -moveRequest
	}

	repack
}

body ::DCS::MotorViewEntry::toggleMoveBy  {} {
	#set up callback when there is a change to the moveBy field
	if { $itk_option(-moveByEnabled) } {
		configure -moveByEnabled 0
	} else {
		configure -moveByEnabled 1
	}
}


body DCS::MotorViewEntry::handleMoveByReferenceMatchChange {- targetReady_ - matches_ -} {
	
	#puts "MOTORVIEW: Entered handleMoveByReferenceMatchChange $targetReady_ $matches_"

	if { ! $targetReady_ } return

	#Check to see if the user is entering changes into the moveBy field
	if { ! $matches_ } {
		#cancel the changes in the absolute position entry field
		updateFromReference
	}

	# update registered objects waiting for referenceMatches asynchronously
	updateRegisteredComponents -moveRequest
}

body DCS::MotorViewEntry::cancelChanges {} {
	updateFromReference
	$itk_component(moveBy) updateFromReference
}

#this returns the overall state of the widget
body ::DCS::MotorViewEntry::getStatus {} {
	return [list $_deviceStatus $_clientState]
}

#this is a call back when the device is active
#body ::DCS::MotorViewEntry::changeDeviceStatus { - - value -} {
	
#	set _deviceStatus $value
#	updateWidgetState

#	updateRegisteredComponents -status
#}

#body DCS::MotorViewEntry::changeClientState { - - value - } {
#	set _clientState $value
#	updateWidgetState

#	updateRegisteredComponents -status
#}


#body ::DCS::MotorViewEntry::updateWidgetState {} {
#	if { $_deviceStatus == "inactive" && $_clientState == "active" } {
#		configure -state normal
#	} else {
#		configure -state disabled
#	}
#}


body ::DCS::MotorViewEntry::handleMotorConfig { device_ targetReady_ alias_ value_ -} {
	
	if { ! $targetReady_ } return

    updatePromptColor
	
	createMenuChoices

	if {$itk_option(-autoGenerateUnitsList)} {
		autoGenerateUnitsList
	}

	#update the units with the current units to redraw everything.
    ## but not call onSubmit
    set save $_ready
    set _ready 0
	configure -units $itk_option(-units)
    set _ready $save
}

body ::DCS::MotorViewEntry::createMenuChoices {} {
	
	if {$itk_option(-device) == "" || $itk_option(-units) == ""} return

	# automatically generate menu choices if requested

	if { $itk_option(-autoMenuChoices) } {
		# clear the current menu
		set menuChoices {}
		
		set valueType $itk_option(-entryType)
		
		#a registered component may update this widget before construction is complete.
		#if { ! [info exists itk_option(-decimalPlaces)] } {return}

		foreach {upperLimit upperLimitUnits} [$itk_option(-device) getEffectiveUpperLimit] break;
		foreach {lowerLimit lowerLimitUnits} [$itk_option(-device) getEffectiveLowerLimit] break;
		
		# get lower and upper limits on the motor
		set lowerLimit [$itk_option(-device) convertUnits $lowerLimit $upperLimitUnits $itk_option(-units) ]
		set upperLimit [$itk_option(-device) convertUnits $upperLimit $lowerLimitUnits $itk_option(-units) ]

		if { $upperLimit < $lowerLimit } {
			#swap the upper and lower limit before we build the menu.
			#this is necessary when viewing the entry in units that have an
			#inverse relationship with the base units for the device.
			# e.g  viewing eV in Angstroms
			foreach {lowerLimit upperLimit} [list $upperLimit $lowerLimit] {break}
		}
		
		set menuChoiceDelta $itk_option(-menuChoiceDelta)
		
		# leave menu empty if more than 50 choices requested
		if { (($upperLimit - $lowerLimit) / $menuChoiceDelta) > 50 } {
			lappend menuChoices [getCleanFloat $lowerLimit $itk_option(-decimalPlaces) 1 ]
			lappend menuChoices [getCleanFloat $upperLimit $itk_option(-decimalPlaces) -1]
			configure -menuChoices $menuChoices

			return
		}
		
		
		# get start of the range of exact multiples of the choice delta
		if { $lowerLimit < 0 } {
			set start [expr $menuChoiceDelta * int($lowerLimit / double($menuChoiceDelta)) ]
		} else {
			set start [expr $menuChoiceDelta * (int($lowerLimit / double($menuChoiceDelta)) + 1) ]
		}
		
		# get end of the range of exact multiples of the choice delta
		if { $upperLimit > 0 } {
			set end  [expr $menuChoiceDelta * int($upperLimit / double($menuChoiceDelta)) ]
		} else {
			set end  [expr $menuChoiceDelta * (int($upperLimit / double($menuChoiceDelta)) - 1) ]
		}
		
		# the first choice is the lower limit
		if { $start != $lowerLimit } {
			lappend menuChoices [getCleanFloat $lowerLimit $itk_option(-decimalPlaces) 1]
		}

		# now add the exact multiples
		for { set choice $start } \
			 { $choice <= $end } \
			 { set choice [expr $choice + $menuChoiceDelta] } {
				 lappend menuChoices [getCleanValue $choice $valueType $itk_option(-decimalPlaces)]
			 }
		
		# the last value is the upper limit
		if { $end != $upperLimit } {
			lappend menuChoices [getCleanFloat $upperLimit $itk_option(-decimalPlaces) -1]
		}
	}
	
	configure -menuChoices $menuChoices
}

body DCS::MotorViewEntry::handleReferenceMatchChange { matches_ } {
	
	if { ! $matches_ } {
		#puts "MOTORVIEW: MATCHES $matches_"

		#cancel the changes in the moveBy field
		$itk_component(moveBy) updateFromReference
	}

	# update registered objects waiting for referenceMatches asynchronously
	updateRegisteredComponents -moveRequest
}

#this is called when the arrow +/- is clicked on the blu-ice canvas
body ::DCS::MotorViewEntry::moveBy { sign } {
	if {$itk_option(-moveByEnabled) == "0" } {
		configure -moveByEnabled 1
	}
	
	#handle the relative move request
	if { ! [$itk_component(moveBy) getReferenceMatches] } {
		foreach {deltaValue units} [$itk_component(moveBy) get] break
		
		switch $sign {
			positive {}
			negative { set deltaValue [expr $deltaValue * -1.0] }
		}
		
		$itk_option(-device) move by $deltaValue $itk_option(-units)
	}
}

body DCS::MotorViewEntry::changeUnits { units_  } {
	DCS::Entry::changeUnits $units_

	createMenuChoices
}
body DCS::MotorViewEntry::handleExtraDevice {- targetReady_ - pos_ -} {
    set m_extraDeviceReady $targetReady_
    #puts "save extra to $pos_"
    set m_extraDevicePosition $pos_

    if {$_ready && $m_extraDeviceReady} {
        checkExtraDevice
    }
}
body DCS::MotorViewEntry::checkExtraDevice { } {
    set match [checkValuesMatch $_value $m_extraDevicePosition]		

    #puts "$this checkExtraDevice got match=$match for v=$_value extra=$m_extraDevicePosition"
    #puts "last=$m_matchExtraDevice"
    if {$match != $m_matchExtraDevice} {
        set m_matchExtraDevice $match
		updateRegisteredComponents -moveRequest
    }
}

class DCS::Crosshair {

	# inheritance
	inherit ::DCS::Component

    #### set to 1 if grid will not move move beam center
    public variable grid_standalone 0

	# public variables
	public variable x			0		update
	public variable y			0		update
	public variable width	6		update
	public variable height	6		update
	public variable color	white	update
	public variable tag		cross

    #### for beam size rectangle
    public variable mode        both update
    public variable beam_horz 0      update
    public variable beam_vert 0      update
    public variable beam_color white update
	public variable beam_tag		beam

    private variable grid_offset_x  0
    private variable grid_offset_y  0
    private variable grid_width     0
    private variable grid_height    0
    private variable grid_column    0
    private variable grid_row       0
    private variable grid_color     blue

    public variable grid_tag         grid
    public variable grid_border_only 1 update

	# public methods
	public method moveTo
    public method setBeamSize { horz vert color } {
        #puts "$this setBeamSize $color"
        set beam_horz $horz
        set beam_vert $vert
        set beam_color $color
        update
    }

    public method setGrid { off_x off_y width height n_horz n_vert color } {
        set grid_offset_x $off_x
        set grid_offset_y $off_y
        set grid_width    $width
        set grid_height   $height
        set grid_column   $n_horz
        set grid_row      $n_vert
        set grid_color    $color
        update
    }

	# protected variables
	protected variable canvas
	protected variable constructionComplete 0

	# protected methods
	protected method update
    protected method draw_cross
    protected method draw_rectangle
    protected method draw_grid

	constructor { path args } {
		
		::DCS::Component::constructor \
			 {  }
	} {
		# store the path of the canvas
		set canvas $path
		
		# process the configuration options
		eval configure $args
		
		# indicate that construction is complete
		set constructionComplete 1

		# update the graphics
		update
	}

	destructor {
		announceDestruction
	}
}


body DCS::Crosshair::update {} {
	# delete the old cross-hair
    catch {
	    $canvas delete -tag $tag
	    $canvas delete -tag $beam_tag
	    $canvas delete -tag $grid_tag
    }

	if { $constructionComplete } {
		switch -exact -- $mode {
            both {
                draw_cross
                draw_rectangle
            }
            cross_only {
                draw_cross
            }
            rectangle_only {
                draw_rectangle
            }
            grid_only {
                draw_grid
            }
            cross_and_grid {
                draw_cross
                draw_grid
            }
        }
	}
}
body DCS::Crosshair::draw_cross {} {
	
	# calculate endpoint ordinates
	set x0 [expr $x - $width / 2.0]
	set x1 [expr $x + $width / 2.0]
	set y0 [expr $y - $height / 2.0 ]
	set y1 [expr $y + $height / 2.0 ]
	
	# draw the vertical line
	$canvas create line $x $y0 $x $y1 -fill $color -width 1 -tag $tag
	
	# draw the horizontal line
	$canvas create line $x0 $y $x1 $y -fill $color -width 1 -tag $tag
}
body DCS::Crosshair::draw_rectangle {} {
	set x0 [expr $x - $beam_horz / 2.0]
	set x1 [expr $x + $beam_horz / 2.0]
	set y0 [expr $y - $beam_vert / 2.0 ]
	set y1 [expr $y + $beam_vert / 2.0 ]

    $canvas create rectangle $x0 $y0 $x1 $y1 \
    -width 1 \
    -outline $beam_color \
    -tags $beam_tag

    #puts "$this crossair draw box with color=$beam_color tags=$beam_tag"
}
	
body DCS::Crosshair::draw_grid {} {
    if {$grid_width == 0 || $grid_height == 0} {
        return
    }
    if {$x < 0 || $y < 0} {
        return
    }
    if {$grid_standalone} {
        set cx $grid_offset_x
        set cy $grid_offset_y
    } else {
        set cx [expr $x + $grid_offset_x]
        set cy [expr $y + $grid_offset_y]
    }

	set x0 [expr $cx - $grid_width / 2.0]
	set x1 [expr $x0 + $grid_width]
	set y0 [expr $cy - $grid_height / 2.0 ]
	set y1 [expr $y0 + $grid_height]

    #### borders: solid lines
    $canvas create rectangle $x0 $y0 $x1 $y1 \
    -width 1 \
    -outline $grid_color \
    -tags $grid_tag

    if {$grid_border_only} {
        return
    }

    #### inner grid, dashes
    if {$grid_row > 1} {
        set row_height [expr double($grid_height) / $grid_row]
        for {set i 1} {$i < $grid_row} {incr i} {
            set yyy [expr $y0 + $i * $row_height]
            $canvas create line $x0 $yyy $x1 $yyy \
            -fill $grid_color \
            -width 1 \
            -tags $grid_tag \
            -dash .
        }
    }
    if {$grid_column > 1} {
        set column_width [expr double($grid_width) / $grid_column]
        for {set i 0} {$i < $grid_column} {incr i} {
            set xxx [expr $x0 + $i * $column_width]
            $canvas create line $xxx $y0 $xxx $y1 \
            -fill $grid_color \
            -width 1 \
            -tags $grid_tag \
            -dash .
        }
    }
}
	
body DCS::Crosshair::moveTo { newX newY } {

	set deltaX [expr $newX - $x]
	set deltaY [expr $newY - $y]
	
	$canvas move $tag $deltaX $deltaY
	$canvas move $beam_tag $deltaX $deltaY
	$canvas move $grid_tag $deltaX $deltaY

	set x $newX
	set y $newY
}


class ::DCS::TitledMotorEntry {
	# inheritance
	inherit ::itk::Widget DCS::Component

	itk_option define -trigger trigger Trigger ""
	itk_option define -device device Device ""
	itk_option define -shadowReference shadowReference ShadowReference 1
	itk_option define -mdiHelper mdiHelper MdiHelper ""

	itk_option define -noTitleClick noTitleClick NoTitleClick 0

    itk_option define -onChange onChange OnChange ""

	itk_option define -enableOnAnyClick enableOnAnyClick EnableOnAnyClick 1
	itk_option define -autoConversion autoConversion AutoConversion 1 {
        $itk_component(entry) configure -autoConversion $itk_option(-autoConversion)
    }
	
	#public methods
    public method get { } {
        return [$itk_component(entry) get]
    }
    public method getMoveCommand { } {
        return [$itk_component(entry) getMoveCommand]
    }

	#thin wrapper function for 
	public method moveToValue {} {$itk_component(entry) moveToValue }
	public method cancelChanges {} {$itk_component(entry) cancelChanges }
	public method changeEntryStatus
	public method addInput
	public method setValue
	public method newCommand
	public method moveBy
    public method undo
	public method handleUnitsChange

    ###########almost the same code as MotorView::onAnyClick
    public method onAnyClick { } {
        #puts "onAnyClick called"
        if {$itk_option(-enableOnAnyClick)} {
            if {[catch {
                set my_device $itk_option(-device)
                if {$my_device != ""} {
                    set device_name [$itk_option(-device) cget -deviceName]
                    set units [$itk_component(entry) cget -units]
                    if {$units == [$itk_option(-device) cget -baseUnits]} {
                        set units ""
                    }
                    ::DCS::MotorMoveView::changeCommonDevice $device_name $units
                }
            } errMsg]} {
                puts "TitledMotorEntry failed onAnyClick: $errMsg"
            }
        }
    }

    public method onLimitsCheck { ok } {
        set curColor $itk_option(-labelForeground)
        if {$ok} {
            if {$curColor == "red"} {
                configure -labelForeground black
            }
        } else {
            if {$curColor == "black"} {
                configure -labelForeground red
            }
        }
        if {$itk_option(-onChange) != ""} {
            eval $itk_option(-onChange)
        }
    }

	private method constructMenu
	# protected methods

	constructor { args } {
		#create the frame for the Motor View
		itk_component add ring {
			frame $itk_interior.ring
		}
		
		itk_component add TitledFrame {
			::DCS::TitledFrame $itk_component(ring).l
		} {
			keep -labelText -labelFont -labelPadX -labelBackground -labelForeground
		}

		set childsite [$itk_component(TitledFrame) childsite]

		itk_component add entry {
			#entry $childsite.e
			DCS::MotorViewEntry $childsite.e \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -onLimitsCheck "$this onLimitsCheck"
		} {
			keep -font -menuChoices -decimalPlaces -precision -extraMenuChoices
			keep -entryWidth -menuBackground -menuColumnWidth -menuColumnMargin
			keep -reference -showEntry -entryType -entryJustify
			keep -device -unitsList -units -controlSystem -menuChoiceDelta
            keep -extraDevice
			keep -autoMenuChoices -unitsWidth -activeClientOnly
			keep -moveByEnabled -autoGenerateUnitsList
			keep -promptForeground
            keep -systemIdleOnly
            keep -matchColor -mismatchColor
            keep -honorStatus
            keep -checkLimits
            keep -updateValueOnMatch
		}

		eval itk_initialize $args

		array set definedOptions $args
		if { ![info exists definedOptions(-menuColumnMargin)] } {
			configure -menuColumnMargin 4
		}

		if { ![info exists definedOptions(-entryType)] } {
			configure -entryType float
		}

		if { ![info exists definedOptions(-entryJustify)] } {
			configure -entryJustify right
		}

		if { ![info exists definedOptions(-entryWidth)] } {
			configure -entryWidth 8
		}

		if { ![info exists definedOptions(-activeClientOnly)] } {
			configure -activeClientOnly 1
		}

		if { ![info exists definedOptions(-systemIdleOnly)] } {
			configure -systemIdleOnly 0
		}

		if { [info exists definedOptions(-units)] } {
			#force the units to go one more time, configbody for 'unitsList' must
			# be called before configbody for 'units' in some cases
			configure -units $itk_option(-units)
		}

		#allow the subcomponent to tell the titled frame what its status is.
		::mediator register $this ::$itk_component(entry) gateOutput changeEntryStatus
		::mediator register $this ::$itk_component(entry) -units handleUnitsChange
		#allow the subcomponent to tell the titled frame what its status is.
		::mediator register $this ::$itk_component(TitledFrame) -command newCommand


		exportSubComponent -moveRequest ::$itk_component(entry)
		exportSubComponent -value ::$itk_component(entry)

		announceExist

		pack $itk_component(ring)
		pack $itk_component(TitledFrame)
		pack $itk_component(entry)


		$itk_component(TitledFrame) configure \
        -onAnyClick "$this onAnyClick"
		$itk_component(entry) configure \
        -onAnyClick "$this onAnyClick"
	}

	destructor {
		announceDestruction
	}
}

#this is a call back when the embedded entry has changed state
body ::DCS::TitledMotorEntry::newCommand { - targetReady_ - command_ -} {
	
	if { ! $targetReady_ } return
	
	switch $command_ {
		moveByEnabled {$itk_component(entry) toggleMoveBy }
		
		configureMotor {
			if {$itk_option(-mdiHelper) != "" && $itk_option(-device) != "" } {
				#ask the MDI document to pop up the configure window for the device
				$itk_option(-mdiHelper) configureMotor $itk_option(-device)
			}
		}
		
		scanMotor {
			if {$itk_option(-mdiHelper) != "" && $itk_option(-device) != "" } {
				#ask the MDI document to pop up a scan window for the device
				$itk_option(-mdiHelper) scanMotor $itk_option(-device)
			}
		}
		
		undo {
			if { $itk_option(-device) != "" } {
				#puts "MOTORVIEW: [$itk_option(-device) cget -lastStablePosition]"
			   undo	
			}
		}
		
		{} {
			#do nothing command
		}
		
		default {
			return -code error "unknown command for motor: $command_"
		}

	}
}


body ::DCS::TitledMotorEntry::undo {} {
   $itk_component(entry) setValue [$itk_option(-device) getUndoPosition]
}

#this is a call back when the embedded entry has changed units
body ::DCS::TitledMotorEntry::handleUnitsChange { entry_ targetReady_ - value_ -} {

	if {$targetReady_ } {
		switch $value_ {
			"A" {
				configure -labelText "Wavelength"
			}
			"eV" {
				configure -labelText "Energy"
			}
			"keV" {
				configure -labelText "Energy"
			}
			default {}
		}
	}
}

#this is a call back when the embedded entry has changed state
body ::DCS::TitledMotorEntry::changeEntryStatus { entry targetReady - value -} {

	#delete the help balloon
	catch {wm withdraw .help_shell}
	set message "This blu-ice has a bug."
	
	set outputMessage [$entry getOutputMessage]
   set bubbleMessage [$entry getBubbleMessage]

	#split the output message
	foreach {output blocker status reason} $outputMessage {break}

	#split the blocker into the object and its attribute
	foreach {object attribute} [split $blocker ~] break

	if {! $targetReady } {
		#the entry is not ready
		configure -labelBackground black
		configure -labelForeground white
		set message $value
		#		if {[info commands $object] == "" } {
		#			set message "$object does not exist."
		#		} else {
		#			set message "Internal errors in $object"
		#		}
		
	} elseif { $output } {
		#the widget is enabled
		set message ""
		configure -labelBackground lightgrey
		configure -labelForeground	black
	} elseif { $object == "::device::system_idle"} {
		configure -labelBackground lightgrey
		configure -labelForeground	black
		set message "System not idle: $status"
	} else {
		#set deviceStatus $itk_option(-device).status
		#the widget is disabled
		if {$reason == "supporting device" } {

            #### the while here is to go down the line of child motors
            #### to find out what is the reason
			while {$status == "child" } {
				set status [$object cget -status]
				set blocker [$object getBlockingChild]
				#split the blocker into the object and its attribute
				set tmpList [split $blocker ~]
                if {[llength $tmpList] < 2} {
                    break
                }
                #puts "in while child of TitledMotorEntry::changeEntryStatus"
                #puts "old object: $object"
				foreach {object attribute} $tmpList break
                #puts "new object: $object"
			}

			#something is happening with the device we are interested in.
			switch $status {
				inactive {
					configure -labelBackground lightgrey
					configure -labelForeground	black
					set message "Device is ready to move."
				}
				moving   {
					configure -labelBackground \#ff4040
					configure -labelForeground white
					set message "[namespace tail $object] is moving."
				}
				offline  {
					configure -labelBackground black
					configure -labelForeground white
					set message "[$object cget -controller] is offline (needed for [namespace tail $object])."
				}
				locked  {
					configure -labelBackground lightgrey
					configure -labelForeground	black
					set message "[namespace tail $object] is locked."
				}
                not_connected {
					configure -labelBackground black
					configure -labelForeground white
					set message "not connected"
                }
				default {
					configure -labelBackground black
					configure -labelForeground white
					set message "$object is not ready."
				}
			}

		} elseif {$reason == "PERMISSION" } {
		   configure -labelBackground lightgrey
		   configure -labelForeground	black
         set message [$itk_option(-device) getPermissionMessage]
      } else {
			#unhandled reason, use default reason specified with addInput
			configure -labelBackground lightgrey
			configure -labelForeground	black
			set message $reason
		}
	}

    onLimitsCheck [$entry getLimitsOK]
	
	DynamicHelp::register $itk_component(TitledFrame) balloon $message
	DynamicHelp::configure -bg #c0c0ff -fg black -font *-helvetica-bold-r-normal--12-*-*-*-*-*-*-*
}


configbody ::DCS::TitledMotorEntry::trigger {
	$itk_component(entry) addInput $itk_option(-trigger)
}

configbody ::DCS::TitledMotorEntry::device {
	$itk_component(entry) configure -device $itk_option(-device)	
}

configbody ::DCS::TitledMotorEntry::shadowReference {
	$itk_component(entry) configure -shadowReference $itk_option(-shadowReference)
}

body ::DCS::TitledMotorEntry::addInput {triggerList } {
	$itk_component(entry) addInput $triggerList
}

body ::DCS::TitledMotorEntry::setValue {value } {
	$itk_component(entry) setValue $value
}

body ::DCS::TitledMotorEntry::moveBy { sign } {
	$itk_component(entry) moveBy $sign
}

configbody ::DCS::TitledMotorEntry::mdiHelper {
	constructMenu
}

configbody ::DCS::TitledMotorEntry::noTitleClick {
	constructMenu
}

body ::DCS::TitledMotorEntry::constructMenu {} {
	set commands ""

    if {!$itk_option(-noTitleClick)} {
	    lappend commands {Undo last move}
	    lappend commands undo 

            lappend commands {Toggle 'Move By'}
            lappend commands moveByEnabled
	
	    if {$itk_option(-mdiHelper) != "" } {
#		    lappend commands {Toggle 'Move By'}
#		    lappend commands moveByEnabled

		    lappend commands {Scan this motor}
		    lappend commands scanMotor

		    lappend commands "Configure this motor"
		    lappend commands configureMotor
	    }
    }
	$itk_component(TitledFrame) configure -configCommands $commands
}









#
# Provides a widget for viewing the motor position only (No edit).
# Clicking on the widget can toggle between units if the unitsList is defined.
#
class ::DCS::MotorView {
	inherit ::itk::Widget

	itk_option define -device device Device ""
	itk_option define -decimalPlaces decimalPlaces DecimalPlaces 3
	
	itk_option define -unitsList unitslist UnitsList ""
	itk_option define -autoGenerateUnitsList autoGenerateUnitsList AutoGenerateUnitsList 0
	itk_option define -units units Units ""

	itk_option define -enableOnAnyClick enableOnAnyClick EnableOnAnyClick 1

    itk_option define -checkLimitsAndStatus checkLimitsAndStatus CheckLimitsAndStatus 0

	# public variables
	public variable lastDevice ""

    private method onAnyClick { } {
        #puts "onAnyClick called"
        if {$itk_option(-enableOnAnyClick)} {
            if {[catch {
                set my_device $itk_option(-device)
                if {$my_device != ""} {
                    set device_name [$itk_option(-device) cget -deviceName]
                    set units $itk_option(-units)
                    if {$units == [$itk_option(-device) cget -baseUnits]} {
                        set units ""
                    }
                    ::DCS::MotorMoveView::changeCommonDevice $device_name $units
                }
            } errMsg]} {
                puts "MotorView $this failed onAnyClick: $errMsg"
            }
        }
    }
	
   public method handleStatusUpdate
   public method handleLimitsUpdate
   public method handlePositionUpdate
   public method viewNextUnit
	protected method repack
   private method updateView
   private method calculateDisplayValue

   private variable m_unitSpecs	
   private variable m_basePosition ""
   private variable m_baseUnits ""
   private variable m_displayValue ""
    private variable m_status inactive
    private variable m_origBG gray

	constructor { args }  {
		set _constructed 0
	
		itk_component add prompt {
			label $itk_interior.p -takefocus 0 -anchor e
		} {
			keep -font -height -state -activebackground
			keep -activeforeground -background
			keep -padx -pady
			rename -relief -promptRelief promptRelief PromptRelief
			rename -foreground -promptForeground promptForeground PromptForeground
			rename -width -promptWidth promptWidth PromptWidth
			rename -text -promptText promptText PromptText
      }

        set m_origBG [$itk_component(prompt) cget -background]

      itk_component add position {
			label $itk_interior.pos -takefocus 0 -anchor e
      } {
			keep -font -height -state -activebackground
			keep -activeforeground -background
			rename -width -positionWidth positionWidth PositionWidth
			keep -padx -pady
         keep -relief
      }

      itk_component add units {
			label $itk_interior.u -takefocus 0 -anchor w
      } {

			keep -font -height -state -activebackground
			keep -activeforeground -background
			keep -padx -pady
			rename -width -unitsWidth unitsWidth UnitsWidth
      }
	
      bind $itk_component(units) <1> [list $this viewNextUnit]
      bind $itk_component(position) <1> [list $this viewNextUnit]
      bind $itk_component(prompt) <1> [list $this viewNextUnit]

		eval itk_initialize $args
      
		::mediator announceExistence $this

      pack $itk_component(prompt) -side left
      pack $itk_component(position) -side left
      pack $itk_component(units) -side left
	}

	destructor {
		::mediator announceDestruction $this
	}

}

configbody DCS::MotorView::device {
    if {$lastDevice != $itk_option(-device)} {
        if {$lastDevice != ""} {
		    ::mediator unregister $this $lastDevice status
		    ::mediator unregister $this $lastDevice limits
		    ::mediator unregister $this $lastDevice scaledPosition
            set m_baseUnits ""
        }

	    if { $itk_option(-device) != "" } {
		    set device $itk_option(-device)

            configure -units [$itk_option(-device) cget -baseUnits]

		    # set up references to the motor object
		    ::mediator register $this $device status \
            handleStatusUpdate
		    ::mediator register $this $device limits \
            handleLimitsUpdate
		    ::mediator register $this $device scaledPosition \
            handlePositionUpdate
		
		    # store the name of the device for next time
		    set lastDevice $itk_option(-device)
	    }
    }
}

body ::DCS::MotorView::handleStatusUpdate { device_ targetReady_ - value_ -} {
    if {!$targetReady_} return
    if {!$itk_option(-checkLimitsAndStatus)} return

    set m_status $value_

    updateView
}
body ::DCS::MotorView::handleLimitsUpdate { device_ targetReady_ - value_ -} {
    if {!$targetReady_} return
    if {!$itk_option(-checkLimitsAndStatus)} return

    updateView
}

body ::DCS::MotorView::handlePositionUpdate { device_ targetReady_ alias_ value_ -} {
	if { ! $targetReady_ } return

    #puts "motorview: update positin: $value_"

   set m_basePosition [lindex $value_ 0]
   set newBaseUnits [lindex $value_ 1]

    if {$m_baseUnits == ""} {
        set m_baseUnits $newBaseUnits
    }

    if {$m_baseUnits != $newBaseUnits} {
        log_error motor $device_ has wrong units $m_baseUnits \
        should be $newBaseUnits

        set m_baseUnits $newBaseUnits
        configure -units $m_baseUnits
    }

   
   calculateDisplayValue
   updateView

}

configbody ::DCS::MotorView::units {

   #change the configuration of the widget if specified for these units
   if { [info exists m_unitSpecs($itk_option(-units))] } {
      eval configure $m_unitSpecs($itk_option(-units))
   }

   calculateDisplayValue
   updateView
}


body ::DCS::MotorView::calculateDisplayValue {} {
    #puts "motorView cal valu: $m_basePosition $m_baseUnits to $itk_option(-units)"

   if {$itk_option(-decimalPlaces) == "" } {return}
   if {$itk_option(-units) == "" } {return}
   if {$itk_option(-device) == "" } {return}
   if {$m_basePosition == "" } {return}

   set convertedValue [$itk_option(-device) convertUnits $m_basePosition $m_baseUnits $itk_option(-units)]
   set m_displayValue [format "%.$itk_option(-decimalPlaces)f" $convertedValue]
}

body ::DCS::MotorView::updateView {} {
    if {$m_displayValue == "" } return

    if {$itk_option(-checkLimitsAndStatus)} {
        switch -exact $m_status {
            disconnected -
            offline {
                $itk_component(position) configure \
                -text offline

                configure -background red
                return
            }
            moving -
            inactive -
            default {
                set localCopy $m_basePosition
                set bg red
                catch {
                    if {[$itk_option(-device) limits_ok localCopy]} {
                        set bg $m_origBG
                    }
                }
                configure -background $bg
            }
        }
    }
    $itk_component(position) configure -text $m_displayValue
    $itk_component(units) configure -text $itk_option(-units)   
}


configbody DCS::MotorView::unitsList {
	if {$itk_option(-unitsList) != "" } {
	
   	#get the units and the configuration command (specification) for each units in the list 
	   #array set m_unitSpecs $itk_option(-unitsList)		
   }
	   array set m_unitSpecs $itk_option(-unitsList)		
}

body DCS::MotorView::viewNextUnit {} {

   set unitsList [array names m_unitSpecs]

   set numUnits [llength $unitsList]

    if {$numUnits == 0} {
        onAnyClick
        return
    }

   set index [lsearch $unitsList $itk_option(-units)]
   incr index
   if {$index >= $numUnits} {set index 0}

   configure -units [lindex $unitsList $index]
    onAnyClick
}



class ::DCS::SimpleMotorMoveView {
	inherit ::itk::Widget

	constructor { args }  {
		set _constructed 0

      set ring $itk_interior

       # construct the panel of control buttons
	    itk_component add control {
		    ::DCS::MotorControlPanel $ring.control \
			    -width 7 -orientation "horizontal" \
			    -ipadx 4 -ipady 2  -buttonBackground #c0c0ff \
			    -activeButtonBackground #c0c0ff  -font "helvetica -14 bold"
	    } {
	    }

		itk_component add deviceView {
          ::DCS::TitledMotorEntry $ring.mv \
       } {
          keep -labelText
          keep -activeClientOnly
          keep -systemIdleOnly
          keep -mdiHelper
          keep -background
          keep -device
          keep -autoGenerateUnitsList
          keep -activeClientOnly
          keep -units 
          keep -enableOnAnyClick 
          keep -systemIdleOnly 
          keep -labelText 
       }
       

	    pack $itk_component(deviceView)
	    pack $itk_component(control)

		 eval itk_initialize $args

       $itk_component(control) registerMotorWidget ::$itk_component(deviceView)
	}

	destructor {
	}


}

class ::DCS::MotorScale {
 #	inherit ::itk::Widget ::DCS::ComponentGate
	inherit ::DCS::ComponentGateExtension
	itk_option define -device device Device ""
	itk_option define -enableOnAnyClick enableOnAnyClick EnableOnAnyClick 1

    itk_option define -from from From "" {
        if {$itk_option(-from) != ""} {
            $itk_component(position) config -from $itk_option(-from)
            puts "set from to [$itk_component(position) cget -from]"
        }
    }
    itk_option define -to to To "" {
        if {$itk_option(-to) != ""} {
            $itk_component(position) config -to $itk_option(-to)
            puts "set to to [$itk_component(position) cget -to]"
        }
    }

	# public variables
	public variable lastDevice ""

    private common gScaleVar

    private method onAnyClick { } {
        #puts "onAnyClick called"
        if {$itk_option(-enableOnAnyClick)} {
            if {[catch {
                set my_device $itk_option(-device)
                if {$my_device != ""} {
                    set device_name [$itk_option(-device) cget -deviceName]
                    set units ""
                    ::DCS::MotorMoveView::changeCommonDevice $device_name $units
                }
            } errMsg]} {
                puts "MotorScale $this failed onAnyClick: $errMsg"
            }
        }
    }

    public method handleInMotionUpdate
    public method handlePositionUpdate
    public method handleLowerLimitsUpdate
    public method handleUpperLimitsUpdate
    public method handleMove { } {
        set state [$itk_component(position) cget -state]
        if {$state != "normal" && $state != "active"} {
            puts "state=$state"
            return
        }

        set value $gScaleVar($this,position)
        puts "move to $value"
        set my_device $itk_option(-device)
        if {$my_device != ""} {
            $my_device move to $value
        }
    }

    private variable m_basePosition ""
    private variable m_baseUnits ""
    private variable m_normalColor
    private variable m_deviceFactory

    constructor { args }  {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set gScaleVar($this,position) 0
        itk_component add position {
            scale $itk_interior.pos \
            -variable [list [::itcl::scope gScaleVar($this,position)]]
        } {
            keep -orient
            keep -showvalue
            keep -label
            keep -resolution
        }
        set m_normalColor [$itk_component(position) cget -troughcolor]
        registerComponent $itk_component(position)
        eval itk_initialize $args
        pack $itk_component(position) -expand 1 -fill x
        bind $itk_component(position) <ButtonRelease-1> "$this handleMove"
        ::mediator announceExistence $this
    }

    destructor {
        unregisterComponent
        ::mediator announceDestruction $this
    }

}

configbody DCS::MotorScale::device {
    if {$lastDevice != ""} {
        puts "unregister lastDevice=$lastDevice"
		deleteInput "$lastDevice status"
	    deleteInput "$lastDevice permission"
		::mediator unregister $this $lastDevice inMotion
		::mediator unregister $this $lastDevice scaledPosition
		::mediator unregister $this $lastDevice lowerLimit
		::mediator unregister $this $lastDevice upperLimit
        set lastDevice ""
    }


	if { $itk_option(-device) != "" } {
		#get the name of the device
		set device $itk_option(-device)

		# set up references to the motor object
		::mediator register $this $device inMotion handleInMotionUpdate
		::mediator register $this $device scaledPosition handlePositionUpdate
		::mediator register $this $device lowerLimit handleLowerLimitsUpdate
		::mediator register $this $device upperLimit handleUpperLimitsUpdate
	    addInput "$device status inactive {supporting device}"
	    addInput "$device permission GRANTED {PERMISSION}"

	}
	set lastDevice $itk_option(-device)
}

body ::DCS::MotorScale::handleInMotionUpdate { device_ targetReady_ alias_ value_ -} {
	if { ! $targetReady_ } return
    if {$device_ != $itk_option(-device)} {
        return
    }

    if {$value_} {
        $itk_component(position) config -troughcolor red
    } else {
        $itk_component(position) config -troughcolor $m_normalColor
    }
}

body ::DCS::MotorScale::handlePositionUpdate { device_ targetReady_ alias_ value_ -} {
	if { ! $targetReady_ } return

    if {$device_ != $itk_option(-device)} {
        return
    }

    set old_state [$itk_component(position) cget -state]
    #puts "position update: $value_ old state:$old_state"

    set m_basePosition [lindex $value_ 0]
    set m_baseUnits [lindex $value_ 1]

    $itk_component(position) config -state normal
    $itk_component(position) set $m_basePosition
    $itk_component(position) config -state $old_state
}
body ::DCS::MotorScale::handleLowerLimitsUpdate { device_ targetReady_ alias_ value_ -} {
	if { ! $targetReady_ } return

    if {$device_ != $itk_option(-device)} {
        return
    }

    puts "lower limits update:$value_"

    if {[llength $value_] < 1} return
    set lowerLimit [lindex $value_ 0]

    if {$itk_option(-from) == ""} {
        $itk_component(position) config -from $lowerLimit
        puts "set from to [$itk_component(position) cget -from]"
    }
}
body ::DCS::MotorScale::handleUpperLimitsUpdate { device_ targetReady_ alias_ value_ -} {
	if { ! $targetReady_ } return

    if {$device_ != $itk_option(-device)} {
        return
    }

    puts "upper limits update:$value_"

    if {[llength $value_] < 1} return

    set upperLimit [lindex $value_ 0]

    if {$itk_option(-to) == ""} {
        $itk_component(position) config -to $upperLimit
        puts "set to to [$itk_component(position) cget -to]"
    }
}

class DCS::DrawContour {

	# inheritance
	inherit ::DCS::Component

	# public variables
	public variable image_width     0       update
	public variable image_height    0       update
	public variable default_color   blue    update
	public variable tag	            contour	

    public variable contents       ""       update

	# protected variables
	protected variable canvas
	protected variable constructionComplete 0

	# protected methods
	protected method update

	constructor { path args } {
		
		::DCS::Component::constructor \
			 {  }
	} {
		# store the path of the canvas
		set canvas $path
		
		# process the configuration options
		eval configure $args
		
		# indicate that construction is complete
		set constructionComplete 1

		# update the graphics
		update
	}

	destructor {
		announceDestruction
	}
}

body DCS::DrawContour::update { } {
    catch {
	    $canvas delete -tag $tag
    }
    if {!$constructionComplete} {
        puts "drawContour construction not completed yet"
        return
    }

    if {$image_width <= 0 || $image_height <= 0 \
    || $contents == ""} {
        puts "drawContour not ready"
        puts "image width=$image_width height=$image_height"
        puts "contents=$contents"
        return
    }

    set index -1
    foreach {color section} $contents {
        puts "draw Contour: $color $section"
        incr index
        set coordList ""
        foreach {rx ry} $section {
            set pix_x [expr $rx * $image_width]
            set pix_y [expr $ry * $image_height]

            lappend coordList $pix_x $pix_y
        }
        if {[catch {
            $canvas create line $coordList \
	        -fill $color -width 1 -tags [list $tag ${tag}_$index]
        } errMsg]} {
            $canvas create line $coordList \
	        -fill $default_color -width 1 -tags [list $tag ${tag}_$index]
        }
    }
}

#### contents of matrix_info
################################
# field 0:
# num_of_row
# num_of_column
# cell height
# cell width
# center Y
# center X
################################
# FOR EACH cell:
# border color (no fill) (no draw and end if color is empty)
# text contents (no draw if empty)
# text color (default to border color)
#################################
# Hope the font size will be small enough and the cell will be big enough.
# Mouse hover over cell will show the text if any.

class DCS::DrawMatrix {
	# inheritance
	inherit ::DCS::Component

	# public variables
	public variable image_width     0       update
	public variable image_height    0       update
	public variable tag             rastering	

    public variable contents       ""       update
    public variable drawPreview     1       update

    public variable grid_color      blue

	# protected variables
	protected variable canvas
	protected variable constructionComplete 0

	# protected methods
	protected method update

    public method removeMark { } {
        puts "removeMark"
        $canvas delete mark
    }
    public method displayMark { row col contents } {
        puts "displayMark"
        removeMark
        puts "displaying $row $col $contents"

        set box [$canvas bbox ${tag}_cell_${row}_${col}]
        foreach {x0 y0 x1 y1} $box break
        
        set x [expr $x0 - 4]
        set y [expr $y0 - 4]

        set text_id [$canvas create text $x $y \
        -tags mark \
        -fill black \
        -anchor se \
        -justify center \
        -text $contents]

        set coords [$canvas bbox $text_id]
        $canvas create rectangle $coords \
        -tags mark \
        -outline white \
        -fill white

        $canvas raise $text_id
    }

	constructor { path args } {
		::DCS::Component::constructor \
			 {  }
	} {
		# store the path of the canvas
		set canvas $path
		
		# process the configuration options
		eval configure $args
		
		# indicate that construction is complete
		set constructionComplete 1

		# update the graphics
		update
	}

	destructor {
		announceDestruction
	}
}

body DCS::DrawMatrix::update { } {
    catch {
	    $canvas delete -tag $tag
    }
    if {!$constructionComplete} {
        puts "DrawMatrix construction not completed yet"
        return
    }

    if {$image_width <= 0 || $image_height <= 0 \
    || $contents == ""} {
        puts "drawMatrix not ready"
        puts "image width=$image_width height=$image_height"
        puts "contents=$contents"
        return
    }

    set header [lindex $contents 0]
    foreach {num_row num_column cell_h cell_w center_y center_x} $header break

    if {$num_row <= 0 || $num_column <= 0 || $cell_h <= 0 || $cell_w <= 0} {
        return
    }
    set y0 [expr $center_y - 0.5 * $cell_h * $num_row]
    set y1 [expr $center_y + 0.5 * $cell_h * $num_row]
    set x0 [expr $center_x - 0.5 * $cell_w * $num_column]
    set x1 [expr $center_x + 0.5 * $cell_w * $num_column]

    set pix_y0 [expr $y0 * $image_height]
    set pix_y1 [expr $y1 * $image_height]
    set pix_x0 [expr $x0 * $image_width]
    set pix_x1 [expr $x1 * $image_width]

    set pix_cell_h [expr $cell_h * $image_height]
    set pix_cell_w [expr $cell_w * $image_width]

    if {$drawPreview} {
        ### draw grid even no individual cell data
        for {set i 0} {$i <= $num_row} {incr i} {
            set y [expr $pix_y0 + $i * $pix_cell_h]
            $canvas create line $pix_x0 $y $pix_x1 $y \
	        -fill $grid_color -width 1 -tags [list $tag ${tag}_grid] -dash .
        }
        for {set i 0} {$i <= $num_column} {incr i} {
            set x [expr $pix_x0 + $i * $pix_cell_w]
            $canvas create line $x $pix_y0 $x $pix_y1 \
	        -fill $grid_color -width 1 -tags [list $tag ${tag}_grid] -dash .
        }
    }

    ### display 3-4 digits
    set font_size0 [expr int($pix_cell_h * 0.75)]
    set font_size1 [expr int($pix_cell_w * 0.25)]
    if {$font_size0 > $font_size1} {
        set font_size $font_size1
    } else {
        set font_size $font_size0
    }

    for {set row 0} {$row < $num_row} {incr row} {
        set rec_y0 [expr $pix_y0 + $row * $pix_cell_h]
        set rec_y1 [expr $rec_y0 + $pix_cell_h]
        for {set col 0} {$col < $num_column} {incr col} {
            set rec_x0 [expr $pix_x0 + $col * $pix_cell_w]
            set rec_x1 [expr $rec_x0 + $pix_cell_w]
            ### 1 is for the header
            set offset [expr $row * $num_column + $col + 1]
            set cellInfo [lindex $contents $offset]
            set cellColor ""
            set cellText ""
            set textColor ""
            foreach {cellColor cellText textColor} $cellInfo break
            if {$cellColor == ""} {
                return
            }
            puts "drawing cell $row $col with color=$cellColor and text=$cellText"
            if {$textColor == ""} {
                set textColor $cellColor
            }
            $canvas create rectangle $rec_x0 $rec_y0 $rec_x1 $rec_y1 \
            -outline $cellColor \
            -width 2 \
            -tags [list $tag ${tag}_cell_${row}_${col}]

            if {$cellText != ""} {
                set center_x [expr ($rec_x0 + $rec_x1) / 2.0]
                set center_y [expr ($rec_y0 + $rec_y1) / 2.0]
                $canvas create text $center_x $center_y \
                -text $cellText \
                -fill $textColor \
                -tags [list $tag ${tag}_text_${row}_${col}]

                $canvas bind ${tag}_cell_${row}_${col} <Enter> \
                "$this displayMark $row $col $cellText"

                $canvas bind ${tag}_cell_${row}_${col} <Leave> \
                "$this removeMark"

                #$canvas bind ${tag}_text_${row}_${col} <Enter> \
                #"$this displayMark $row $col $cellText"

                #$canvas bind ${tag}_text_${row}_${col} <Leave> \
                #"$this removeMark"
            }
        }
    }
}

### beamsize is used more than here, so we take out this part of code
class BeamsizeToDisplay {
    inherit ::itk::Widget ::DCS::Component

    itk_option define -beamWidthWidget beamWidthWidget BeamWidthWidget ""
    itk_option define -beamHeightWidget beamHeightWidget BeamHeightWidget ""
    itk_option define -honorCollimator honorCollimator HonorCollimator 1 {
        if {$itk_option(-honorCollimator)} {
            puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            puts "register collimator"
		    ::mediator register $this ::device::user_collimator_status contents handleUserCollimator
		    ::mediator register $this ::device::collimator_status contents handleCurrentCollimator
        } else {
		    ::mediator unregister $this ::device::user_collimator_status contents
		    ::mediator unregister $this ::device::collimator_status contents
        }
    }

    public method getBeamSize { } {
        return $m_beamsize
    }
    public method handleBeamSizeX
    public method handleBeamSizeY
    public method handleUserCollimator
    public method handleCurrentCollimator

    private method updateBeamSize

    private variable m_beamsize [list 0.25 0.25 white]
    private variable _beamSizeX    0.25
    private variable _beamSizeY    0.25
    private variable _userCollimatorStatus [list 0 -1 2 2]
    private variable _currentCollimatorStatus [list 0 -1 2 2]

    constructor { args } {
		::DCS::Component::constructor {
            beamsize getBeamSize
        }
    } {
		eval itk_initialize $args
		announceExist
    }
}
configbody BeamsizeToDisplay::beamWidthWidget {
    if {$itk_option(-beamWidthWidget) != ""} {
        ::mediator register $this ::$itk_option(-beamWidthWidget) -value handleBeamSizeX
    }
}
configbody BeamsizeToDisplay::beamHeightWidget {
    if {$itk_option(-beamHeightWidget) != ""} {
        ::mediator register $this ::$itk_option(-beamHeightWidget) -value handleBeamSizeY
    }
}
body BeamsizeToDisplay::handleBeamSizeX { object_ ready_ - value_ - } {
	if { $ready_ } {
		foreach { value units } $value_ break;
        set _beamSizeX $value
		updateBeamSize
	}
}
body BeamsizeToDisplay::handleBeamSizeY { object_ ready_ - value_ - } {
	if { $ready_ } {
		foreach { value units } $value_ break;
        set _beamSizeY $value
		updateBeamSize
	}
}
body BeamsizeToDisplay::handleUserCollimator { object_ ready_ - contents_ - } {
	if { $ready_ } {
        puts "user collimator: $contents_"
        set _userCollimatorStatus $contents_
		updateBeamSize
	}
}

body BeamsizeToDisplay::handleCurrentCollimator { object_ ready_ - contents_ - } {
	if { $ready_ } {
        puts "current collimator: $contents_"
        set _currentCollimatorStatus $contents_
		updateBeamSize
	}
}
body BeamsizeToDisplay::updateBeamSize { } {
    global gMotorBeamWidth
    global gMotorBeamHeight

    set userWillUseCollimator [lindex $_userCollimatorStatus 0]
    set currentCollimatorIn   [lindex $_currentCollimatorStatus 0]

    if {$itk_option(-honorCollimator) \
    && ($userWillUseCollimator == "1" || $currentCollimatorIn == "1") \
    } {
        puts "honor collimator"
        #### current setting has higher priority
        if {$currentCollimatorIn} {
            foreach {isMicro indexMatched width height} $_currentCollimatorStatus break
        } else {
            foreach {isMicro indexMatched width height} $_userCollimatorStatus break
        }
        if {$width > $_beamSizeX || $height > $_beamSizeY} {
            puts "collimator size > focus beam size"
            puts "collimator $width $height focus $_beamSizeX $_beamSizeY"
        }
        set color white
    } else {
        set width  $_beamSizeX
        set height $_beamSizeY
        set realW [::device::$gMotorBeamWidth cget -scaledPosition]
        set realH [::device::$gMotorBeamHeight cget -scaledPosition]
        if {abs($realW - $width) < 0.001 \
        && abs($realH - $height) < 0.001} {
            set color white
        } else {
            set color red
        }
    }
    foreach {old_w old_h old_color} $m_beamsize break
    if {abs($width - $old_w) >= 0.0001 \
    || abs($height - $old_h) >= 0.0001 \
    || $color != $old_color} {
        set m_beamsize [list $width $height $color]
        updateRegisteredComponents beamsize
    }
}
