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
package provide DCSCollimatorMenu 1.0

package require DCSCollimatorPreset
package require DCSDevice
package require DCSDeviceFactory

# load standard packages
package require Iwidgets

class CollimatorMenu {
 	inherit ::itk::Widget

    itk_option define -cmd cmd Cmd ""
    ### no dynamic support: you cannot change it after init
    itk_option define -forUser forUser ForUser 0

    public method setValue { value_ args } {
        if {$itk_option(-cmd) != ""} {
            eval $itk_option(-cmd) $value_ $args
        }
    }

    public method handleListUpdate { - ready_ - contents_ - } {
        $itk_component(presetmn) delete 0 end
        if {!$ready_} return
        puts "collimatorList: $contents_"
        set candidateList ""
        foreach item $contents_ {
            set ll [llength $item]
            if {$ll >= 4} {
                ##micro
                foreach {index name width height} $item break
                #set lb [format "%-20s: %.3f X %.3f" $name $width $height]
                set lb $name
            } elseif {$ll >= 2} {
                foreach {index name} $item break
                set width 2.0
                set height 2.0
                set lb $name
            } else {
                puts "skip $item. not enough information"
                continue
            }
            #lappend candidateList [list $lb $index $name [expr $width * $height]]
            lappend candidateList [list $lb $index $name $width]
        }
        set candidateList [lsort -decreasing -real -index 3 $candidateList]
        foreach line $candidateList {
            foreach {lb index name} $line break
            $itk_component(presetmn) add command \
            -label $lb \
            -command "$this setValue $index $name"
        }
    }

    constructor { args } {
        itk_component add presetmb {
            menubutton $itk_interior.mb \
            -menu $itk_interior.mb.menu \
            -image [DCS::MenuEntry::getArrowImage] \
            -width 16 \
            -anchor c \
            -relief raised \
        } {
            keep -state
        }
        itk_component add presetmn {
            menu $itk_interior.mb.menu \
            -activebackground blue \
            -activeforeground white \
            -tearoff 0 \
        } {
        }

        pack $itk_component(presetmb)
        eval itk_initialize $args

        if {$itk_option(-forUser)} {
            ::device::collimator_preset register $this list4user handleListUpdate
        } else {
            ::device::collimator_preset register $this list handleListUpdate
        }
    }
    destructor {
        if {$itk_option(-forUser)} {
            ::device::collimator_preset unregister $this list4user handleListUpdate
        } else {
            ::device::collimator_preset unregister $this list handleListUpdate
        }
    }
}

### should replace CollimatorDropDown and eliminate CollimatorMenu
class CollimatorMenuEntry {
	inherit DCS::MenuEntry

    #### no dynamic support, cannot change after initialization.
    itk_option define -forUser forUser ForUser 0

    public method handleListUpdate { - ready_ - contents_ - }

    ### override to convert value_ between text
    protected method value2display { value_ } {
        set ll [llength $value_]
        if {$ll < 4} {
            puts "wrong value for collimator menuEntry"
            return $value_
        }
        foreach {isMicro index w h} $value_ break
        set m_menuIndex [lsearch -exact $m_choiceIndexList $index]

        if {$isMicro == "1" && $index >= 0} {
            set name [$m_strCollimatorPreset getCollimatorName $index]
        } else {
            set name Out
        }
        return $name
    }

    public method setValueByIndex { index {directAccess_ 0}} {
        set m_menuIndex $index
        set value [$m_strCollimatorPreset getCollimatorInfo $index]
        setValue $value $directAccess_
        puts "calle setValue with $value $directAccess_"
    }
    public method getInfo { } { return $_fullValue }
    public method getIsMicro { } { return [lindex $_fullValue 0] }

    protected method internalOnChange { } {
        updateRegisteredComponents collimator_info
        updateRegisteredComponents is_micro
    }
    private variable m_menuIndex 0
    private variable m_choiceIndexList ""
    private variable m_strCollimatorPreset ""
    private variable m_attr ""

    constructor { args } {
        ::DCS::Component::constructor {
            collimator_info getInfo
            is_micro        getIsMicro
        }
    } {
        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_strCollimatorPreset \
        [$deviceFactory createString collimator_preset]

        eval itk_initialize $args -submitFullValue 1

        if {$itk_option(-forUser)} {
            set m_attr list4user
        } else {
            set m_attr list
        }
        $m_strCollimatorPreset register $this $m_attr handleListUpdate

        announceExist
        updateEntryColor
        set _ready 1
    }
    destructor {
        $m_strCollimatorPreset unregister $this $m_attr handleListUpdate
    }

}
body CollimatorMenuEntry::handleListUpdate { - ready_ - contents_ - } {
    if {!$ready_} return

    puts "collimatorList: $contents_"
    set candidateList ""
    foreach item $contents_ {
        set ll [llength $item]
        if {$ll >= 4} {
            ##micro
            foreach {index name width height} $item break
            #set lb [format "%-20s: %.3f X %.3f" $name $width $height]
            set lb $name
        } elseif {$ll >= 2} {
            foreach {index name} $item break
            set width 2.0
            set height 2.0
            set lb $name
        } else {
            puts "skip $item. not enough information"
            continue
        }
        #lappend candidateList [list $lb $index $name [expr $width * $height]]
        lappend candidateList [list $lb $index $name $width]
    }
    set candidateList [lsort -decreasing -real -index 3 $candidateList]
    set choices ""
    set m_choiceIndexList ""
    foreach line $candidateList {
        foreach {lb index name} $line break
        lappend choices [list $lb [list $this setValueByIndex $index]]

        ### search preset index for menu index
        lappend m_choiceIndexList $index
    }
    configure -extraMenuChoices $choices

    set collimatorIndex [lindex $_value 1]
    set m_menuIndex [lsearch -exact $m_choiceIndexList $collimatorIndex]
    if {$m_menuIndex >= 0} {
        setValueByIndex $m_menuIndex 1
    } else {
        setValueByIndex 0
        log_error check collimator settings.
    }
}
