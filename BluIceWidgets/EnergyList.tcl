package provide BLUICEEnergyList 1.0

package require DCSDeviceView

class DynamicEnergyListView {
    inherit ::itk::Widget ::DCS::Component

    itk_option define -onSubmit onSubmit OnSubmit ""

    itk_option define -maxLength maxLength MaxLength 5 {

        enoughEntry $itk_option(-maxLength)

        while {$m_numEntryDisplayed > $itk_option(-maxLength)} {
            incr m_numEntryDisplayed -1
            pack forget $itk_component(ee$m_numEntryDisplayed)
        }
    }

    public method addInput { trigger_ } {
        for {set i 0} {$i < $m_numEntryCreated} {incr i} {
            $itk_component(ee$i) addInput $trigger_
        }
        if {[lsearch -exact $m_previousInput $trigger_] < 0} {
            lappend m_previousInput $trigger_
        }
    }
    public method deleteInput { trigger_ } {
        for {set i 0} {$i < $m_numEntryCreated} {incr i} {
            $itk_component(ee$i) deleteInput $trigger_
        }
        set index [lsearch -exact $m_previousInput $trigger_]

        if {$index >= 0} {
            set m_previousInput [lreplace $m_previousInput $index $index]
        }
    }

    public method updateEnergyList { {directAccess_ 0} }

    public method getEnergyList { } { return $m_energyList }

    public method getFirstEnergy { } {
        return [$itk_component(ee0) get]
    }
    public method convertUnits { v vu du } {
        return [$itk_component(ee0) convertUnits $v $vu $du]
    }

    public method setValue { eList {directAccess 0}}

    private method updateDisplay { }

    private method enoughEntry { num } {
        for {} {$m_numEntryCreated < $num} {incr m_numEntryCreated} {
            if {$m_numEntryCreated == 0} {
                set label "Energy: "
            } else {
                set label ""
            }

            itk_component add ee$m_numEntryCreated {
                DCS::MotorViewEntry $itk_interior.ee$m_numEntryCreated \
                -checkLimits -1 \
                -menuChoiceDelta 1000.0 \
                -device ::device::energy \
                -leaveSubmit 1 \
                -promptText $label \
                -promptWidth 15  \
                -showPrompt 1 \
                -unitsList eV \
                -units eV \
                -shadowReference 0 \
                -onSubmit "$this updateEnergyList" \
                -entryType positiveFloat \
                -entryJustify right \
                -entryWidth 12 \
                -escapeToDefault 0 \
                -autoConversion 1 \
                -nullAllowed 1 \
            } {
                keep -systemIdleOnly -activeClientOnly
                keep -font
            }

            foreach trigger $m_previousInput {
                $itk_component(ee$m_numEntryCreated) addInput $trigger
            }
        }
    }

    private variable m_energyList ""
    private variable m_numEntryCreated 0
    private variable m_numEntryDisplayed 0

    private variable m_previousInput [list]

    private variable m_objEnergy ""

    constructor { args } {
        ::DCS::Component::constructor { 
            -value getFirstEnergy
        }
    } {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objEnergy [$deviceFactory getObjectName energy]

        enoughEntry 5

        eval itk_initialize $args
        announceExist

        updateDisplay
    }
}
body DynamicEnergyListView::updateEnergyList { {directAccess_ 0} } {
    #puts "updateEnergyList d=$directAccess_"
    set m_energyList [list]

    for {set i 0} {$i < $m_numEntryDisplayed} {incr i} {
        set e [lindex [$itk_component(ee$i) get] 0]
        #puts "check entry $i got {$e}"
        if {$e != "" && $e != 0.0} {
            lappend m_energyList $e
        }
    }
    if {[llength $m_energyList] == 0} {
        set m_energyList [lindex [$m_objEnergy cget -scaledPosition] 0]
        updateDisplay
    }
    updateRegisteredComponents -value

    if {$directAccess_} {
        return
    }

    updateDisplay
    set cmd $itk_option(-onSubmit)
    if {$cmd == ""} {
        return
    }
    set cmd [replace%sInCommandWithValue $cmd $m_energyList]
    if {[catch { eval $cmd } errMsg]} {
        log_error onSubmit failed: $errMsg
    }
}

body DynamicEnergyListView::updateDisplay { } {
    set numEnergy [llength $m_energyList]
    set numEntry [expr $numEnergy + 1]
    if {$numEntry > $itk_option(-maxLength)} {
        set numEntry $itk_option(-maxLength)
    }

    while {$m_numEntryDisplayed > $numEntry} {
        incr m_numEntryDisplayed -1
        pack forget $itk_component(ee$m_numEntryDisplayed)
    }
    while {$m_numEntryDisplayed < $numEntry} {
        pack $itk_component(ee$m_numEntryDisplayed) -anchor w -pady 2
        incr m_numEntryDisplayed
    }

    for {set i 0} {$i < $m_numEntryDisplayed} {incr i} {
        set value [lindex $m_energyList $i]
        $itk_component(ee$i) setValue $value 1
    }
}
body DynamicEnergyListView::setValue { value_ {directAccess_  0} } {
    set m_energyList $value_
    updateDisplay

    updateEnergyList $directAccess_
}
