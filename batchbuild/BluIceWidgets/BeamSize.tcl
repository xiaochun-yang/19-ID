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

package provide BLUICEBeamSize 1.0

# load standard packages
package require Iwidgets

package require DCSMotorControlPanel
package require DCSDeviceView


### this one is to move the motors.
## BeamSizeEntry is for user setup parameters
class BeamSizeView {
    inherit ::itk::Widget

    public method getBeamWidthWidget {} {return $itk_component(width)}
    public method getBeamHeightWidget {} {return $itk_component(height)}

	public method handleUserCollimatorStatusChange
    public method handleCurrentCollimatorStatusChange

    private method updateDisplay

    private variable m_deviceFactory ""
    private variable m_strUserCollimatorStatus    ""
    private variable m_strCurrentCollimatorStatus ""
    private variable m_opUserCollimator ""

    private variable m_ctsUserCollimator    "0 -1 2 2"
    private variable m_ctsCurrentCollimator "0 -1 2 2"

    constructor { args }  {
        global gMotorBeamWidth
        global gMotorBeamHeight

        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_strUserCollimatorStatus [$m_deviceFactory createString \
        user_collimator_status]
        $m_strUserCollimatorStatus createAttributeFromField isMicroBeam 0

        set m_strCurrentCollimatorStatus [$m_deviceFactory createString \
        collimator_status]
        $m_strCurrentCollimatorStatus createAttributeFromField isMicroBeam 0

        set m_opUserCollimator [$m_deviceFactory createOperation userCollimator]

        set sizeSite $itk_interior
        #construct the panel of control buttons
        itk_component add control {
            ::DCS::MotorControlPanel $sizeSite.control \
                -width 7 -orientation "horizontal" \
                -ipadx 4 -ipady 2  -buttonBackground #c0c0ff \
                -activeButtonBackground #c0c0ff  -font "helvetica -14 bold"
        } {
        }

        itk_component add motorFrame {
            frame $sizeSite.m_f
        } {
        }

        set ring $itk_component(motorFrame)

        itk_component add width {
            ::DCS::TitledMotorEntry $ring.width \
            -updateValueOnMatch 1 \
            -labelText "Beam Width" \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -units mm \
            -entryType positiveFloat \
            -menuChoiceDelta 0.05 \
            -device [$m_deviceFactory getObjectName $gMotorBeamWidth]
        } {
            keep -activeClientOnly
            keep -systemIdleOnly
            keep -honorStatus
            keep -mdiHelper
            keep -background
            keep -enableOnAnyClick 
        }
        itk_component add height {
            ::DCS::TitledMotorEntry $ring.height \
            -updateValueOnMatch 1 \
            -labelText "Beam Height" \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -units mm \
            -entryType positiveFloat \
            -menuChoiceDelta 0.05 \
            -device [$m_deviceFactory getObjectName $gMotorBeamHeight]
        } {
            keep -activeClientOnly
            keep -systemIdleOnly
            keep -honorStatus
            keep -mdiHelper
            keep -background
            keep -enableOnAnyClick 
        }
	
        itk_component add collimatorBeamWidth {
		    ::DCS::TitledMotorEntry $ring.collimator_width \
            -labelText "Beam Width" \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -units mm \
            -entryType positiveFloat \
            -menuChoiceDelta 0.05 \
            -activeClientOnly 1
	    } {
            keep -systemIdleOnly
		    keep -mdiHelper
	    }

	    itk_component add collimatorBeamHeight {
		    ::DCS::TitledMotorEntry $ring.collimator_height \
            -labelText "Beam Height" \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -units mm \
            -entryType positiveFloat \
            -menuChoiceDelta 0.05 \
            -activeClientOnly 1
	    } {
            keep -systemIdleOnly
		    keep -mdiHelper
	    }

        ### show but disable them
        $itk_component(collimatorBeamWidth) addInput \
        "$m_strUserCollimatorStatus isMicroBeam 0 {collimator selected}"
        $itk_component(collimatorBeamWidth) addInput \
        "$m_strCurrentCollimatorStatus isMicroBeam 0 {collimator inserted}"

        $itk_component(collimatorBeamHeight) addInput \
        "$m_strUserCollimatorStatus isMicroBeam 0 {collimator selected}"
        $itk_component(collimatorBeamHeight) addInput \
        "$m_strCurrentCollimatorStatus isMicroBeam 0 {collimator inserted}"

        itk_component add cross {
            label $ring.cross \
            -text "x" \
            -font "helvetica -14 bold"
        } {
        }
        grid $itk_component(width)  -row 0 -column 0
        grid $itk_component(cross)  -row 0 -column 1 -sticky s
	    grid $itk_component(height) -row 0 -column 2

        set cfgShowCollimator [::config getInt bluice.showCollimator 1]
        if {$cfgShowCollimator \
        && [$m_deviceFactory operationExists collimatorMove]} {
            itk_component add collimator {
			    CollimatorDropdown $ring.collimator
            } {
            }
            grid $itk_component(collimator) -row 1 -column 0 -columnspan 3 -sticky n
        }
       
        pack $itk_component(motorFrame) -side left
        pack $itk_component(control) -side left

        eval itk_initialize $args

        $itk_component(control) registerMotorWidget ::$itk_component(width)
        $itk_component(control) registerMotorWidget ::$itk_component(height)

		$m_strUserCollimatorStatus    register $this contents  handleUserCollimatorStatusChange
		$m_strCurrentCollimatorStatus register $this contents  handleCurrentCollimatorStatusChange
    }

    destructor {
		$m_strCurrentCollimatorStatus unregister $this contents  handleCurrentCollimatorStatusChange
		$m_strUserCollimatorStatus    unregister $this contents  handleUserCollimatorStatusChange
    }
}
body BeamSizeView::handleUserCollimatorStatusChange { - targetReady_ alias_ contents_ -  } {
	
	if { ! $targetReady_} return
    if {[llength $contents_] < 4} {
        return
    }
    #puts "BeamSizeView user collimator: $contents_"
    set m_ctsUserCollimator $contents_
    updateDisplay
}

body BeamSizeView::handleCurrentCollimatorStatusChange { - targetReady_ alias_ contents_ -  } {
	
	if { ! $targetReady_} return
    if {[llength $contents_] < 4} {
        return
    }
    #puts "BeamSizeView system collimator: $contents_"
    set m_ctsCurrentCollimator $contents_
    updateDisplay
}

body BeamSizeView::updateDisplay { } {
    set userWillUseCollimator [lindex $m_ctsUserCollimator 0]
    set currentCollimatorIn   [lindex $m_ctsCurrentCollimator 0]

    if {$userWillUseCollimator || $currentCollimatorIn} {
	    grid forget $itk_component(width) $itk_component(height)

	    $itk_component(width)  cancelChanges
	    $itk_component(height) cancelChanges

        #puts "isMicro showing collimator size"

        #### current setting has higher priority
        if {$currentCollimatorIn} {
            foreach {isMicro index w h} $m_ctsCurrentCollimator break
        } else {
            foreach {isMicro index w h} $m_ctsUserCollimator break
        }

	    $itk_component(collimatorBeamWidth)  setValue $w
	    $itk_component(collimatorBeamHeight) setValue $h

        grid $itk_component(collimatorBeamWidth)  -row 0 -column 0
	    grid $itk_component(collimatorBeamHeight) -row 0 -column 2
    } else {
        #puts "not micro beam"
        grid forget $itk_component(collimatorBeamWidth) \
        $itk_component(collimatorBeamHeight)

        grid $itk_component(width)  -row 0 -column 0
	    grid $itk_component(height) -row 0 -column 2
    }
}

class BeamSizeEntry {
    inherit ::itk::Widget

    itk_option define -alternateShadowReference alternateSR AlternateSR "" {
        set aSR $itk_option(-alternateShadowReference)
        $itk_component(width) configure \
        -alternateShadowReference "$aSR beam_width"

        $itk_component(height) configure \
        -alternateShadowReference "$aSR beam_height"
    }

    public method getBeamWidthWidget {} {return $itk_component(width)}
    public method getBeamHeightWidget {} {return $itk_component(height)}

	public method handleUserCollimatorStatusChange
    public method handleCurrentCollimatorStatusChange

    private method updateDisplay

    private variable m_deviceFactory ""
    private variable m_strUserCollimatorStatus    ""
    private variable m_strCurrentCollimatorStatus ""
    private variable m_opUserCollimator ""

    private variable m_ctsUserCollimator    "0 -1 2 2"
    private variable m_ctsCurrentCollimator "0 -1 2 2"

    constructor { args }  {
        global gMotorBeamWidth
        global gMotorBeamHeight

        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_strUserCollimatorStatus [$m_deviceFactory createString \
        user_collimator_status]
        $m_strUserCollimatorStatus createAttributeFromField isMicroBeam 0

        set m_strCurrentCollimatorStatus [$m_deviceFactory createString \
        collimator_status]
        $m_strCurrentCollimatorStatus createAttributeFromField isMicroBeam 0

        set m_opUserCollimator [$m_deviceFactory createOperation userCollimator]

        itk_component add ff {
            ::iwidgets::labeledframe $itk_interior.ff \
            -labeltext "Beam Size" \
        } {
        }

        set ring [$itk_component(ff) childsite]

        itk_component add width {
            ::DCS::MotorViewEntry $ring.width \
            -updateValueOnMatch 1 \
            -checkLimits -1 \
            -leaveSubmit 1 \
            -menuChoiceDelta 0.05 \
            -device [$m_deviceFactory getObjectName $gMotorBeamWidth] \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList mm \
            -units mm \
            -showUnits 0 \
            -autoConversion 1 \
            -escapeToDefault 0 \
            -shadowReference 1 \
        } {
            rename -onSubmit -onWidthSubmit onWidthSubmit OnWidthSubmit
            keep -activeClientOnly -systemIdleOnly -honorStatus
            keep -alterUpdateSubmit
        }
	
        itk_component add height {
            ::DCS::MotorViewEntry $ring.height \
            -updateValueOnMatch 1 \
            -checkLimits -1 \
            -leaveSubmit 1 \
            -menuChoiceDelta 0.05 \
            -device [$m_deviceFactory getObjectName $gMotorBeamHeight] \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList mm \
            -units mm \
            -autoConversion 1 \
            -escapeToDefault 0 \
            -shadowReference 1 \
        } {
            rename -onSubmit -onHeightSubmit onHeightSubmit OnHeightSubmit
            keep -activeClientOnly -systemIdleOnly -honorStatus
            keep -alterUpdateSubmit
        }
	
        itk_component add collimatorBeamWidth {
            ::DCS::MotorViewEntry $ring.c_w \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList mm \
            -units mm \
            -showUnits 0 \
            -autoConversion 1
	    } {
	    }

	    itk_component add collimatorBeamHeight {
            ::DCS::MotorViewEntry $ring.c_h \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList mm \
            -units mm \
            -autoConversion 1
        } {
        }

        ### show but disable them
        $itk_component(collimatorBeamWidth) addInput \
        "$m_strUserCollimatorStatus isMicroBeam 0 {collimator selected}"
        $itk_component(collimatorBeamWidth) addInput \
        "$m_strCurrentCollimatorStatus isMicroBeam 0 {collimator inserted}"

        $itk_component(collimatorBeamHeight) addInput \
        "$m_strUserCollimatorStatus isMicroBeam 0 {collimator selected}"
        $itk_component(collimatorBeamHeight) addInput \
        "$m_strCurrentCollimatorStatus isMicroBeam 0 {collimator inserted}"

        itk_component add cross {
            label $ring.cross \
            -text "x" \
            -font "helvetica -14 bold"
        } {
        }
        grid $itk_component(width)  -row 0 -column 0
        grid $itk_component(cross)  -row 0 -column 1 -sticky s
	    grid $itk_component(height) -row 0 -column 2

        set cfgShowCollimator [::config getInt bluice.showCollimator 1]
        if {$cfgShowCollimator \
        && [$m_deviceFactory operationExists collimatorMove]} {
            itk_component add collimator {
			    CollimatorDropdown $ring.collimator
            } {
            }
            grid $itk_component(collimator) -row 1 -column 0 -columnspan 3 -sticky n
        }
       
        pack $itk_component(ff) -side left

        eval itk_initialize $args

		$m_strUserCollimatorStatus    register $this contents  handleUserCollimatorStatusChange
		$m_strCurrentCollimatorStatus register $this contents  handleCurrentCollimatorStatusChange
    }

    destructor {
		$m_strCurrentCollimatorStatus unregister $this contents  handleCurrentCollimatorStatusChange
		$m_strUserCollimatorStatus    unregister $this contents  handleUserCollimatorStatusChange
    }
}
body BeamSizeEntry::handleUserCollimatorStatusChange { - targetReady_ alias_ contents_ -  } {
	
	if { ! $targetReady_} return
    if {[llength $contents_] < 4} {
        return
    }
    #puts "BeamSizeEntry user collimator: $contents_"
    set m_ctsUserCollimator $contents_
    updateDisplay
}

body BeamSizeEntry::handleCurrentCollimatorStatusChange { - targetReady_ alias_ contents_ -  } {
	
	if { ! $targetReady_} return
    if {[llength $contents_] < 4} {
        return
    }
    #puts "BeamSizeEntry system collimator: $contents_"
    set m_ctsCurrentCollimator $contents_
    updateDisplay
}

body BeamSizeEntry::updateDisplay { } {
    set userWillUseCollimator [lindex $m_ctsUserCollimator 0]
    set currentCollimatorIn   [lindex $m_ctsCurrentCollimator 0]

    if {$userWillUseCollimator || $currentCollimatorIn} {
	    grid forget $itk_component(width) $itk_component(height)

	    $itk_component(width)  cancelChanges
	    $itk_component(height) cancelChanges

        #puts "isMicro showing collimator size"

        #### current setting has higher priority
        if {$currentCollimatorIn} {
            foreach {isMicro index w h} $m_ctsCurrentCollimator break
        } else {
            foreach {isMicro index w h} $m_ctsUserCollimator break
        }

	    $itk_component(collimatorBeamWidth)  setValue $w
	    $itk_component(collimatorBeamHeight) setValue $h

        grid $itk_component(collimatorBeamWidth)  -row 0 -column 0
	    grid $itk_component(collimatorBeamHeight) -row 0 -column 2
    } else {
        #puts "not micro beam"
        grid forget $itk_component(collimatorBeamWidth) \
        $itk_component(collimatorBeamHeight)

        grid $itk_component(width)  -row 0 -column 0
	    grid $itk_component(height) -row 0 -column 2
    }
}

### This one does not care current (system or user) collimator information.
### It should replace the BeamSizeEntry in the future.
### BeamSizeEntry uses mm as units.
### BeamSizeParameter uses um as units.
### This one support different collimator setttings per run.
class BeamSizeParameter {
    inherit ::itk::Widget ::DCS::Component

    itk_option define -showPrompt showPrompt ShowPrompt 1 { repack }

    itk_option define -units units Units um

    itk_option define -alternateShadowReference alternateSR AlternateSR "" {
        set aSR $itk_option(-alternateShadowReference)
        if {$aSR != ""} {
            $itk_component(width) configure \
            -alternateShadowReference "$aSR beam_width"

            $itk_component(height) configure \
            -alternateShadowReference "$aSR beam_height"

            if {$m_showCollimator} {
                $itk_component(collimator) configure \
                -alternateShadowReference "$aSR collimator"
            }
        } else {
            $itk_component(width) configure \
            -alternateShadowReference ""

            $itk_component(height) configure \
            -alternateShadowReference ""

            $itk_component(collimator) configure \
            -alternateShadowReference ""
        }
    }

    public method getBeamSize { } { return $m_beamsize }

	public method handleCollimatorUpdate

    public method handleValueChange { - ready_ - - - } {
        if {!$ready_} {
            return
        }
        updateBeamSizeInfo
    }

    #### should only be called to update the display so
    ##### directAccess_ == 1
    public method setValue { w h c {directAccess_ 0}} {
        #puts "setValue for BeamSizeParameter: $w $h {$c}"
        $itk_component(width) setValue $w 1
        $itk_component(height) setValue $h 1
        $itk_component(collimator) setValue $c 1
    }

    public method addInput { trigger } {
        $itk_component(width)      addInput $trigger
        $itk_component(height)     addInput $trigger
        $itk_component(collimator) addInput $trigger
    }

    private method repack
    private method updateDisplay
    private method updateBeamSizeInfo

    private variable m_ctsCollimator    "0 -1 2 2"
    private variable m_gotCollimator 0
    private variable m_beamsize         "0.1 0.1 white"
    private variable m_showCollimator 0

    constructor { args }  {
        ::DCS::Component::constructor {
            instant_beam_size getBeamSize
        }
    } {
        global gMotorBeamWidth
        global gMotorBeamHeight

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set cfgShowCollimator [::config getInt bluice.showCollimator 1]
        if {$cfgShowCollimator \
        && [$m_deviceFactory operationExists collimatorMove]} {
            set m_showCollimator 1
        }

        itk_component add prompt {
            label $itk_interior.p \
            -takefocus 0 \
            -anchor e
        } {
            keep -font
            keep -background
            rename -activeforeground -promptForeground promptForeground PromptForeground
            rename -foreground -promptForeground promptForeground PromptForeground
            rename -width -promptWidth promptWidth PromptWidth

            rename -text -promptText promptText PromptText
        }

        itk_component add ff {
            frame $itk_interior.ff
        } {
        }

        set ring $itk_component(ff)

        itk_component add width {
            ::DCS::MotorViewEntry $ring.width \
            -updateValueOnMatch 1 \
            -checkLimits -1 \
            -leaveSubmit 1 \
            -menuChoiceDelta 0.05 \
            -device [$m_deviceFactory getObjectName $gMotorBeamWidth] \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -showUnits 0 \
            -autoConversion 1 \
            -escapeToDefault 0 \
            -shadowReference 0 \
        } {
            rename -onSubmit -onWidthSubmit onWidthSubmit OnWidthSubmit
            keep -activeClientOnly -systemIdleOnly -honorStatus
            keep -alterUpdateSubmit
            keep -state
            keep -font
        }
	
        itk_component add height {
            ::DCS::MotorViewEntry $ring.height \
            -updateValueOnMatch 1 \
            -checkLimits -1 \
            -leaveSubmit 1 \
            -menuChoiceDelta 0.05 \
            -device [$m_deviceFactory getObjectName $gMotorBeamHeight] \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -autoConversion 1 \
            -escapeToDefault 0 \
            -shadowReference 0 \
        } {
            rename -onSubmit -onHeightSubmit onHeightSubmit OnHeightSubmit
            keep -activeClientOnly -systemIdleOnly -honorStatus
            keep -alterUpdateSubmit
            keep -state
            keep -font
        }
	
        itk_component add collimatorBeamWidth {
            ::DCS::MotorViewEntry $ring.c_w \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -showUnits 0 \
            -autoConversion 1
	    } {
            keep -activeClientOnly -systemIdleOnly -honorStatus
            keep -alterUpdateSubmit
            keep -font
	    }

	    itk_component add collimatorBeamHeight {
            ::DCS::MotorViewEntry $ring.c_h \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -autoConversion 1
        } {
            keep -font
        }

        itk_component add cross {
            label $ring.cross \
            -text "x" \
            -font "helvetica -14 bold"
        } {
        }
        grid $itk_component(width)  -row 0 -column 0
        grid $itk_component(cross)  -row 0 -column 1 -sticky s
	    grid $itk_component(height) -row 0 -column 2

        itk_component add collimator {
            CollimatorMenuEntry $ring.collimator \
            -showPrompt 0 \
            -forUser 1 \
            -entryWidth 25 \
            -entryMaxLength 100 \
            -entryType string \
            -showEntry 0 \
            -reference "::device::user_collimator_status contents" \
            -shadowReference 0
        } {
            rename -onSubmit -onCollimatorSubmit \
            onCollimatorSubmit OnCollimatorSubmit

            keep -state
            keep -font
        }
        if {$m_showCollimator} {
            set m_gotCollimator 1
            grid $itk_component(collimator) \
            -row 1 -column 0 -columnspan 4 -sticky nw -padx 1

            grid columnconfigure $ring 3 -weight 5

            ### show but disable them
            $itk_component(collimatorBeamWidth) addInput \
            "::$itk_component(collimator) is_micro 0 {collimator selected}"

            $itk_component(collimatorBeamHeight) addInput \
            "::$itk_component(collimator) is_micro 0 {collimator selected}"

            $itk_component(collimator) register $this collimator_info \
            handleCollimatorUpdate
        }

        $itk_component(width)      register $this -value handleValueChange
        $itk_component(height)     register $this -value handleValueChange
        $itk_component(collimator) register $this -value handleValueChange

        eval itk_initialize $args
        announceExist
    }
}
configbody BeamSizeParameter::units {
    set u $itk_option(-units)

    switch -exact -- $u {
        um {
            set decimal 1
            set delta 10.0
        }
        mm {
            set decimal 4
            set delta 0.01
        }
        default {
            set decimal 3
            set delta 0.05
        }
    }

    foreach name {width height collimatorBeamWidth collimatorBeamHeight} {
        $itk_component($name) configure \
        -unitsList $u \
        -units $u \
        -decimalPlaces $decimal \
        -menuChoiceDelta $delta \
    }
}
body BeamSizeParameter::handleCollimatorUpdate {- targetReady_ - contents_ -} {
	if { ! $targetReady_} return
    if {[llength $contents_] < 4} {
        return
    }
    #puts "BeamSizeParameter collimator: $contents_"
    set m_ctsCollimator $contents_
    updateDisplay
}

body BeamSizeParameter::updateDisplay { } {
    set isMicro [lindex $m_ctsCollimator 0]

    if {$isMicro == "1"} {
	    grid forget $itk_component(width) $itk_component(height)

	    $itk_component(width)  cancelChanges
	    $itk_component(height) cancelChanges

        #puts "isMicro showing collimator size"

        foreach {isMicro index w h} $m_ctsCollimator break

	    $itk_component(collimatorBeamWidth)  setValue "$w mm"
	    $itk_component(collimatorBeamHeight) setValue "$h mm"

        grid $itk_component(collimatorBeamWidth)  -row 0 -column 0
	    grid $itk_component(collimatorBeamHeight) -row 0 -column 2
    } else {
        #puts "not micro beam"
        grid forget $itk_component(collimatorBeamWidth) \
        $itk_component(collimatorBeamHeight)

        grid $itk_component(width)  -row 0 -column 0
	    grid $itk_component(height) -row 0 -column 2
    }
}
body BeamSizeParameter::repack { } {
    grid forget $itk_component(prompt)
    grid forget $itk_component(ff)

    if {$itk_option(-showPrompt)} {
        grid $itk_component(prompt) -column 0 -row 0 -sticky ne
    }
    grid $itk_component(ff) -row 0 -column 1 -sticky news
}
body BeamSizeParameter::updateBeamSizeInfo { } {
    #puts "updating beamsize info"
    if {$m_gotCollimator} {
        set c [$itk_component(collimator) getInfo]
        foreach {isMicro index w h} $c break
        if {$isMicro == "1"} {
            if {[$itk_component(collimator) getReferenceMatches]} {
                set color white
            } else {
                set color red
            }
            set m_beamsize [list $w $h $color]
            #puts "beamsize: $m_beamsize"
            updateRegisteredComponents instant_beam_size
            return
        }
    }
    ### now normal beam.
    ### the units here are microns
    set wU [$itk_component(width) get]
    set hU [$itk_component(height) get]
    foreach {w uw} $wU break
    foreach {h uh} $hU break
    set wMM [::units convertUnits $w $uw mm]
    set hMM [::units convertUnits $h $uh mm]

    set color white
    if {![$itk_component(width)  getReferenceMatches] \
    ||  ![$itk_component(height) getReferenceMatches] \
    } {
        set color red
    }
    set m_beamsize [list $wMM $hMM $color]
    #puts "instant_beam_size: $m_beamsize"
    updateRegisteredComponents instant_beam_size
}

class CellSize {
    inherit ::itk::Widget

    itk_option define -showPrompt showPrompt ShowPrompt 1 { repack }

    itk_option define -units units Units um

    itk_option define -alternateShadowReference alternateSR AlternateSR "" {
        set aSR $itk_option(-alternateShadowReference)
        if {$aSR != ""} {
            $itk_component(width) configure \
            -alternateShadowReference "$aSR cell_width"

            $itk_component(height) configure \
            -alternateShadowReference "$aSR cell_height"
        } else {
            $itk_component(width) configure \
            -alternateShadowReference ""

            $itk_component(height) configure \
            -alternateShadowReference ""
        }
    }

    #### should only be called to update the display so
    ##### directAccess_ == 1
    public method setValue { w h {directAccess_ 0}} {
        $itk_component(width) setValue $w 1
        $itk_component(height) setValue $h 1
    }
    public method getValue { } {
        set w [lindex [$itk_component(width) get] 0]
        set h [lindex [$itk_component(height) get] 0]

        return [list $w $h]
    }

    public method addInput { trigger } {
        $itk_component(width)  addInput $trigger
        $itk_component(height) addInput $trigger
    }

    private method repack

    constructor { args }  {
        itk_component add prompt {
            label $itk_interior.p \
            -takefocus 0 \
            -anchor e
        } {
            keep -font
            keep -background
            rename -activeforeground -promptForeground promptForeground PromptForeground
            rename -foreground -promptForeground promptForeground PromptForeground
            rename -width -promptWidth promptWidth PromptWidth

            rename -text -promptText promptText PromptText
        }

        itk_component add ff {
            frame $itk_interior.ff
        } {
            keep -background
        }

        set ring $itk_component(ff)

        itk_component add width {
            ::DCS::MenuEntry $ring.width \
            -updateValueOnMatch 1 \
            -leaveSubmit 1 \
            -menuChoices {10 20 25 30 40 50 100 150 200} \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -showUnits 0 \
            -autoConversion 1 \
            -escapeToDefault 0 \
            -shadowReference 1 \
        } {
            rename -onSubmit -onWidthSubmit onWidthSubmit OnWidthSubmit
            keep -activeClientOnly -systemIdleOnly
            keep -alterUpdateSubmit
            keep -background
            keep -state
            keep -font
        }
	
        itk_component add height {
            ::DCS::MenuEntry $ring.height \
            -leaveSubmit 1 \
            -menuChoices {10 20 25 30 40 50 100 150 200} \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -autoConversion 1 \
            -escapeToDefault 0 \
            -shadowReference 1 \
        } {
            rename -onSubmit -onHeightSubmit onHeightSubmit OnHeightSubmit
            keep -activeClientOnly -systemIdleOnly
            keep -alterUpdateSubmit
            keep -background
            keep -state
            keep -font
        }
	
        itk_component add cross {
            label $ring.cross \
            -text "x" \
            -font "helvetica -14 bold"
        } {
            keep -background
        }
        grid $itk_component(width)  -row 0 -column 0
        grid $itk_component(cross)  -row 0 -column 1 -sticky s
	    grid $itk_component(height) -row 0 -column 2

        eval itk_initialize $args
    }
}
configbody CellSize::units {
    set u $itk_option(-units)

    switch -exact -- $u {
        um {
            set decimal 1
            set delta 10.0
        }
        mm {
            set decimal 4
            set delta 0.01
        }
        default {
            set decimal 3
            set delta 0.05
        }
    }

    foreach name {width height} {
        $itk_component($name) configure \
        -unitsList $u \
        -units $u \
        -decimalPlaces $decimal \
        -menuChoiceDelta $delta \
    }
}
body CellSize::repack { } {
    grid forget $itk_component(prompt)
    grid forget $itk_component(ff)

    if {$itk_option(-showPrompt)} {
        grid $itk_component(prompt) -column 0 -row 0 -sticky e
    }
    grid $itk_component(ff) -row 0 -column 1 -sticky news
}
