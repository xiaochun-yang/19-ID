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

package provide BLUICERepositionView 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
#package require DCSUtil
#package require DCSSet
#package require DCSComponent

package require DCSDeviceView
#package require DCSProtocol
#package require DCSOperationManager
#package require DCSHardwareManager
#package require DCSPrompt
package require DCSMotorControlPanel
package require BLUICECanvasShapes


##### special:
##### It will call the operation instead of moving motors.
##### This way, all motors will be moved symotaniously.
##### Otherwise, it will abort becase x and y both will move sample_x/y.
class ::DCS::MotorControlPanelReposition {
	inherit ::DCS::MotorControlPanel 

    private variable m_objReposition

	public method applyChanges

	constructor { args } {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objReposition [$deviceFactory createOperation reposition]

		eval itk_initialize $args
	}
}

body ::DCS::MotorControlPanelReposition::applyChanges {} {
    set x ""
    set y ""
    set z ""
    set phi ""

    set needMoveX 0
    set needMoveY 0
    set needMoveZ 0
    set needMovePhi 0

    foreach widget $_registeredMotorList {
        set moveCmd [$widget getMoveCommand]
        if {$moveCmd == ""} {
            continue
        }

        #puts "moveCmd: $moveCmd"

        foreach {device tag position} $moveCmd break
        if {$tag == "by"} {
            set obj [$widget cget -device]
            set currentP [$obj cget -scaledPosition]
            set position [expr $currentP + $position]
            #puts "position from by: $position"
        }
        switch -exact -- $device {
            reposition_x {
                set x $position
                set needMoveX 1
            }
            reposition_y {
                set y $position
                set needMoveY 1
            }
            reposition_z {
                set z $position
                set needMoveZ 1
            }
            reposition_phi {
                set phi $position
                set needMovePhi 1
            }
        }
    }
    if {$needMoveX && $needMoveY} {
        #puts "use move operation"
        $m_objReposition startOperation move $phi $x $y $z
    } else {
        #puts "normal move"
        DCS::MotorControlPanel::applyChanges
    }
}

itk::usual TitledMotorEntry {
    keep \
    -mdiHelper \
    -activeClientOnly \
    -systemIdleOnly \
    -honorStatus \
}

class DCS::RepositionView {
    inherit ::itk::Widget

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    private variable m_objRepositionOrigin ""
    private variable m_objReposition ""
    private variable m_nField 0

    public proc getMotorList { } {
        return [list \
        reposition_phi \
        reposition_x \
        reposition_y \
        reposition_z \
        ]
    }

    public method handleOriginUpdate

    public method handleBack { } {
        $m_objReposition startOperation move 0 0 0 0
    }
    public method handleUseCurrent { } {
        $m_objReposition startOperation use_current
    }
    public method handleReset { } {
        $m_objReposition startOperation reset
    }

    constructor { args } {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objRepositionOrigin \
        [$deviceFactory createString reposition_origin]

        set m_objReposition [$deviceFactory createOperation reposition]

        itk_component add leftFrame {
            iwidgets::labeledframe $itk_interior.lf \
            -labelpos nw \
            -labeltext "Relative Position" \
        } {
        }
        itk_component add middleFrame {
            iwidgets::labeledframe $itk_interior.mf \
            -labelpos nw \
            -labeltext "Real Motor" \
        } {
        }
        set lSite [$itk_component(leftFrame) childsite]
        set mSite [$itk_component(middleFrame) childsite]

        itk_component add control {
            ::DCS::MotorControlPanelReposition $lSite.control \
            -width 7 \
            -orientation horizontal \
            -ipadx 4 \
            -ipady 2 \
            -buttonBackground #c0c0ff \
            -activeButtonBackground #c0c0ff \
            -font "helvetica -14 bold"
        } {
        }
        itk_component add phi {
            ::DCS::TitledMotorEntry $lSite.phi \
            -autoGenerateUnitsList 1 \
            -menuChoiceDelta 45 -units deg -unitsWidth 4 \
            -entryWidth 10 \
            -labelText "Phi" \
            -device ::device::reposition_phi \
        } {
            usual
        }
        itk_component add x {
            ::DCS::TitledMotorEntry $lSite.x \
            -autoGenerateUnitsList 1 \
            -units mm -unitsWidth 4 \
            -entryWidth 10 \
            -labelText "x" \
            -device ::device::reposition_x \
        } {
            usual
        }
        itk_component add y {
            ::DCS::TitledMotorEntry $lSite.y \
            -autoGenerateUnitsList 1 \
            -units mm -unitsWidth 4 \
            -entryWidth 10 \
            -labelText "y" \
            -device ::device::reposition_y \
        } {
            usual
        }
        itk_component add z {
            ::DCS::TitledMotorEntry $lSite.z \
            -autoGenerateUnitsList 1 \
            -units mm -unitsWidth 4 \
            -entryWidth 10 \
            -labelText "z" \
            -device ::device::reposition_z \
        } {
            usual
        }
        itk_component add move_back {
            DCS::Button $lSite.back \
            -text "Move back to origin" \
            -command "$this handleBack"
        } {
            keep \
            -activeClientOnly \
            -systemIdleOnly \
        }
        $itk_component(control) registerMotorWidget ::$itk_component(phi)
        $itk_component(control) registerMotorWidget ::$itk_component(x)
        $itk_component(control) registerMotorWidget ::$itk_component(y)
        $itk_component(control) registerMotorWidget ::$itk_component(z)

        pack $itk_component(phi) -side top
        pack $itk_component(x) -side top
        pack $itk_component(y) -side top
        pack $itk_component(z) -side top
        pack $itk_component(control) -side top
        pack $itk_component(move_back) -side top

        set motorList [::config getStr reposition.origin.motorList]

        label $mSite.h0 \
        -anchor e \
        -text "Current Position"

        label $mSite.h1 \
        -anchor e \
        -text "Origin"

        grid $mSite.h0 -row 0 -column 0 -sticky e
        grid $mSite.h1 -row 0 -column 1 -sticky e

        set m_nField 0
        foreach motor $motorList {
            itk_component add r_$motor {
                DCS::MotorView $mSite.$motor \
                -autoGenerateUnitsList 1 \
                -unitsWidth 4 \
                -positionWidth 10 \
                -promptWidth 14 \
                -promptText $motor \
                -device ::device::$motor
            } {
            }

            itk_component add o$m_nField {
                label $mSite.o$m_nField \
                -width 10 \
                -anchor e \
                -text "0.0000"
            } {
            }

            set row [expr $m_nField + 1]

            grid $itk_component(r_$motor) \
            -row $row \
            -column 0 \
            -sticky news

            grid $itk_component(o$m_nField) \
            -row $row \
            -column 1 \
            -sticky news

            incr m_nField
        }


        itk_component add use_current {
            DCS::Button $mSite.current \
            -text "Use current position as origin" \
            -command "$this handleUseCurrent"
        } {
        }
        itk_component add reset {
            DCS::Button $mSite.reset \
            -text "Reset" \
            -command "$this handleReset"
        } {
        }

        set row [expr $m_nField + 1]
        grid $itk_component(use_current) -row $row -column 0
        grid $itk_component(reset) -row $row -column 1


        pack $itk_component(leftFrame) -side left -expand 1 -fill both
        pack $itk_component(middleFrame) -side left -expand 1 -fill both

        $m_objRepositionOrigin register $this contents \
        handleOriginUpdate

        eval itk_initialize $args
    }

    destructor {
        $m_objRepositionOrigin unregister $this contents \
        handleOriginUpdate
    }
}
body DCS::RepositionView::handleOriginUpdate { - targetReady_ - contents_ - } {
    #puts "calling update: $targetReady_ $contents_"
    #puts "nfield: $m_nField"
    if {!$targetReady_} return

    set i 0
    foreach f $contents_ {
        if {$i >= $m_nField} {
            break
        }

        $itk_component(o$i) configure \
        -text [format "%.4f" $f]

        incr i
    }
}
