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

package provide BLUICEDefaultParmView 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

#package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
#package require DCSHardwareManager
#package require DCSPrompt
#package require DCSMotorControlPanel
package require DCSCheckbutton
#package require DCSGraph
package require DCSLabel
package require DCSFeedback
package require DCSDeviceLog
package require DCSCheckbox
package require DCSEntryfield
package require DCSDeviceFactory
package require BLUICEOptimizedEnergy
package require BLUICEMicroSpecView

class DefaultParamWidget {
    inherit ::itk::Widget

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    constructor { args } {
        itk_component add notebook {
            iwidgets::Tabnotebook $itk_interior.nb -tabpos n -height 400
        } {
        }

        #create all of the pages
        set CollectSite [$itk_component(notebook) add -label "Collect"]
        set RobotSite [$itk_component(notebook) add -label "Robot"]
        set OptimizedEnergySite \
        [$itk_component(notebook) add -label "OptimizedEnergy (Default)"]
        $itk_component(notebook) view 0
        
        itk_component add collect {
          defaultCollectWidget $CollectSite.collect
        } {
        }

        itk_component add robot {
          defaultRobotWidget $RobotSite.robot
        } {
        }

        set oEDObj [DCS::OptimizedEnergyParams::getDefaultObject]
        set oEObj  [DCS::OptimizedEnergyParams::getObject]


        itk_component add optimized {
            DCS::OptimizedEnergyGui $OptimizedEnergySite.optimized $oEDObj $oEObj
        } {
            keep -mdiHelper
        }

        pack $itk_component(collect) -anchor nw
        pack $itk_component(robot) -expand yes -fill both
        pack $itk_component(optimized) -expand yes -fill both

        set deviceFactory [DCS::DeviceFactory::getObject]
        if {[$deviceFactory stringExists microspec_default]} {
            set microSpecSite [$itk_component(notebook) add -label "MicroSpec"]

            itk_component add microSpec {
                MicroSpecDefaultLevel2View $microSpecSite.ms \
                -stringName ::device::microspec_default \
                -systemIdleOnly 0 \
                -activeClientOnly 0 \
            } {
            }
            pack $itk_component(microSpec) -side top -fill x
        }

        pack $itk_component(notebook) -expand yes -fill both
        pack $itk_interior -expand yes -fill both

        eval itk_initialize $args
    }

    destructor {
    }
}

class defaultCollectWidget {
    inherit ::itk::Widget

    public method handleDetectorTypeChange { - targetReady_ - - - } {
        if {!$targetReady_} return
        set index [$m_detector getDefaultModeIndex]
        puts "detector index $index"
        set mode [$m_detector getModeNameFromIndex $index]
        puts "detector mode {$mode}"
        
        $itk_component(mode) configure -text $mode
    }

    constructor { args } {
        set m_detector [DCS::Detector::getObject]


        set ring $itk_interior

        label $ring.rh1 \
        -anchor e \
        -text "hardcoded detector mode"
        label $ring.rh2 \
        -anchor e \
        -text "delta"
        label $ring.rh3 \
        -anchor e \
        -text "exposure time"
        label $ring.rh4 \
        -anchor e \
        -text "attenuation"

        label $ring.ch1 \
        -text "default"
        label $ring.ch2 \
        -text "minumum"
        label $ring.ch3 \
        -text "maximum"

        label $ring.cell12 \
        -anchor e \
        -relief sunken \
        -width 20 \
        -text "N/A"
        label $ring.cell13 \
        -anchor e \
        -relief sunken \
        -width 20 \
        -text "N/A"

        label $ring.cell22 \
        -anchor e \
        -relief sunken \
        -width 20 \
        -text "hardcoded 0.01"
        label $ring.cell23 \
        -anchor e \
        -relief sunken \
        -width 20 \
        -text "hardcoded 179.99"

        itk_component add mode {
            label $ring.mode \
            -text "unknown" \
            -relief sunken \
            -width 20
        } {
        }

        itk_component add delta {
            DCS::Entryfield $ring.delta    \
            -validate real \
            -fixed 5 -width 20 \
            -justify right \
            -offset 0 \
            -stringName collect_default
        } {
            keep -systemIdleOnly
        }

        itk_component add expose {
            DCS::Entryfield $ring.expose   \
            -validate real \
            -fixed 5 -width 20 \
            -justify right \
            -offset 1 \
            -stringName collect_default
        } {
            keep -systemIdleOnly
        }

        itk_component add attenuation {
            DCS::Entryfield $ring.att   \
            -validate real \
            -fixed 5 -width 20 \
            -justify right \
            -offset 2 \
            -stringName collect_default
        } {
            keep -systemIdleOnly
        }

        itk_component add minT {
            DCS::Entryfield $ring.minT   \
            -validate real \
            -fixed 5 -width 20 \
            -justify right \
            -offset 3 \
            -stringName collect_default
        } {
            keep -systemIdleOnly
        }

        itk_component add maxT {
            DCS::Entryfield $ring.maxT \
            -validate real \
            -fixed 5 -width 20 \
            -justify right \
            -offset 4 \
            -stringName collect_default
        } {
            keep -systemIdleOnly
        }

        itk_component add minA {
            DCS::Entryfield $ring.minA \
            -validate real \
            -fixed 5 -width 20 \
            -justify right \
            -offset 5 \
            -stringName collect_default
        } {
            keep -systemIdleOnly
        }

        itk_component add maxA {
            DCS::Entryfield $ring.maxA \
            -validate real \
            -fixed 5 -width 20 \
            -justify right \
            -offset 6 \
            -stringName collect_default
        } {
            keep -systemIdleOnly
        }

        grid x         $ring.ch1 $ring.ch2 $ring.ch3
        grid $ring.rh1 $itk_component(mode) $ring.cell12 $ring.cell13
        grid $ring.rh2 $itk_component(delta) $ring.cell22 $ring.cell23
        grid $ring.rh3 $itk_component(expose) $itk_component(minT) $itk_component(maxT)
        grid $ring.rh4 $itk_component(attenuation) $itk_component(minA) $itk_component(maxA)

        grid configure $ring.rh1 $ring.rh2 $ring.rh3 $ring.rh4 -sticky e

        #puts "done constructo5r"

        $m_detector register $this type handleDetectorTypeChange

    }
    destructor {
        $m_detector unregister $this type handleDetectorTypeChange
    }
    private variable m_detector ""
}
class defaultRobotWidget {
    inherit ::itk::Widget

    public method openDocument { } {
        if {[catch {
            openWebWithBrowser [::config getStr document.robot_advanced]
        } errMsg]} {
            log_error $errMsg
            log_error $errMsg
            log_error $errMsg
        } else {
            $itk_component(strip_doc) configure -state disabled
            after 10000 [list $itk_component(strip_doc) configure -state normal]
        }
    }

    constructor { args } {

        set ring $itk_interior

        itk_component add first_part {
            DCS::Checkbox $ring.first \
            -orient vertical \
            -itemList {\
            "auto check sample xyz" 14 \
            "check sample on gonometer" 15 \
            "probe cassette" 1 \
            "probe port" 2 \
            "check magnet" 4 \
            "Check Sample on Picker" 13 \
            "strict dismount" 9 \
            "scan barcode during Mount" 12 \
            "check Post Calibration" 5 \
            "collect forces information" 6 \
            "reheat tong if gripper jam" 7 \
            "LN2 filling abort CAL" 10 \
            "debug mode" 8 \
            "detailed CAL msg" 0 \
            } \
            -stringName robot_default \
        } {
            keep -systemIdleOnly
        }

        itk_component add pin {
            DCS::Entryfield $ring.pin    \
            -validate integer \
            -fixed 3 -width 4 \
            -labeltext "pin lost threshold" \
            -labelpos e \
            -offset 3 \
            -stringName robot_default
        } {
            keep -systemIdleOnly
        }
        frame $ring.f_strip
        set stripSite $ring.f_strip
        itk_component add strip {
            DCS::Entryfield $stripSite.num    \
            -validate integer \
            -fixed 3 -width 4 \
            -labeltext "pin strip threshold" \
            -labelpos e \
            -offset 11 \
            -stringName robot_default
        } {
            keep -systemIdleOnly
        }
        itk_component add strip_doc {
            button $stripSite.doc \
            -text "Document" \
            -command "$this openDocument"
        } {
        }
        pack $itk_component(strip) -side left -anchor w
        pack $itk_component(strip_doc) -side left -anchor w

        pack $itk_component(pin) -side top -anchor w
        pack $stripSite -side top -anchor w
        pack $itk_component(first_part) -side top -anchor w
    }
}
