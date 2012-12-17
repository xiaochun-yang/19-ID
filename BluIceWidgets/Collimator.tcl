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

## just reuse the filename
package provide BLUICECollimatorCheckbutton 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

package require DCSProtocol
package require DCSOperationManager
package require DCSLabel
package require DCSDeviceFactory
package require DCSCollimatorMenu
package require ComponentGateExtension

class CollimatorCheckbutton {
    inherit ::itk::Widget

    private variable m_deviceFactory
    private variable m_strCollimatorStatus
    private variable m_opUserCollimator

    public method toggleCollimatorSetting { } {
        $m_opUserCollimator startOperation
    }

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_strCollimatorStatus [$m_deviceFactory createString \
        user_collimator_status]
        $m_strCollimatorStatus createAttributeFromField isMicroBeam 0

        set m_opUserCollimator [$m_deviceFactory createOperation userCollimator]

        itk_component add collimator {
		    DCS::Checkbutton $itk_interior.collimator \
            -text "Use Microbeam Collimator" \
            -command "$this toggleCollimatorSetting" \
            -reference "$m_strCollimatorStatus isMicroBeam" \
            -shadowReference 1
        } {
        }

        pack $itk_component(collimator) -side left -expand 1 -fill x -anchor w

        eval itk_initialize $args
    }
}
class CollimatorDropdown {
    inherit ::DCS::ComponentGateExtension

    itk_option define -mdiHelper midHelper MdiHelper ""

    private variable m_deviceFactory
    private variable m_strCollimatorStatus
    private variable m_strCollimatorPreset
    private variable m_opUserCollimator

    public method handleChoiceChange { index_ args } {
        $m_opUserCollimator startOperation $index_
    }

    public method handleCurrentChange { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        #puts "user_collimator: $contents_"
        set isMicro [lindex $contents_ 0]
        set index   [lindex $contents_ 1]
        if {$isMicro == "1" && $index >= 0} {
            set name [$m_strCollimatorPreset getCollimatorName $index]
        } else {
            set name "Guard Shield"
        }
        $itk_component(current) configure \
        -text $name
    }

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_strCollimatorStatus [$m_deviceFactory createString \
        user_collimator_status]
        set m_strCollimatorPreset [$m_deviceFactory createString \
        collimator_preset]

        set m_opUserCollimator [$m_deviceFactory createOperation userCollimator]

        itk_component add current {
		    label $itk_interior.current_collimator \
            -anchor w \
            -background tan \
            -relief sunken \
            -width 20 \
            -text "Collimator" \
        } {
        }

        itk_component add choice {
            CollimatorMenu $itk_interior.collimator_choice \
            -forUser 1 \
            -cmd "$this handleChoiceChange"
        } {
        }

        pack $itk_component(current) -side left -expand 1 -fill x -anchor w
        pack $itk_component(choice)

        registerComponent $itk_component(choice)

        eval itk_initialize $args

        announceExist

        $m_strCollimatorStatus register $this contents handleCurrentChange
    }
    destructor {
        $m_strCollimatorStatus unregister $this contents handleCurrentChange
        unregisterComponent
        announceDestruction
    }
}
