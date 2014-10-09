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

package provide BLUICEAlignFrontEndViewBL12-2 1.0

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

class alignFrontEndViewBL12-2 {
 	inherit ::itk::Widget
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    constructor { args } {
        itk_component add notebook {
            iwidgets::Tabnotebook $itk_interior.nb -tabpos n -height 400 \
            -equaltabs 0
        } {
        }
        #create all of the pages
        set runSite [$itk_component(notebook) add -label "Run"]
        set staffSite [$itk_component(notebook) add -label "Staff Align Beam"]
        set tungstenSite   [$itk_component(notebook) add -label "Config for Align Tungsten"]
        set autofocusSite  [$itk_component(notebook) add -label "Config for Inline Autofocus"]
        set presetSite     [$itk_component(notebook) add -label "Collimator Preset"]
        $itk_component(notebook) view 0

        itk_component add run {
            userAlignBeamRunView $runSite.run
        } {
            keep -mdiHelper
        }
        pack $itk_component(run) -expand yes -fill both

        itk_component add staff_pw {
            ::iwidgets::panedwindow $staffSite.pw \
            -orient vertical \
        } {
        }
        $itk_component(staff_pw) add Control
        $itk_component(staff_pw) add Log
        set sfControlSite [$itk_component(staff_pw) childsite 0]
        set sfLogSite     [$itk_component(staff_pw) childsite 1]

        itk_component add staff {
            DCS::CollimatorPresetLevel2View $sfControlSite.staffRun \
            -stringName ::device::collimator_preset \
            -systemIdleOnly 0 \
            -activeClientOnly 0
        } {
                keep -mdiHelper
        }
        itk_component add log4staff {
            DCS::DeviceLog $sfLogSite.log
        } {
        }
        $itk_component(log4staff) addDeviceObjs ::device::staffAlignBeam

        pack $itk_component(staff)     -side top -expand 1 -fill both
        pack $itk_component(log4staff) -side top -expand 1 -fill both
        pack $itk_component(staff_pw) -side top -expand 1 -fill both

        itk_component add t_config {
            DCS::AlignTungstenConfigView $tungstenSite.config \
            -systemIdleOnly 0 \
            -activeClientOnly 0
        } {
            keep -mdiHelper
        }
        pack $itk_component(t_config) -side top -expand 0 -fill x

        itk_component add a_config {
            DCS::AutofocusConfigView $autofocusSite.config \
            -systemIdleOnly 0 \
            -activeClientOnly 0
        } {
            keep -mdiHelper
        }
        pack $itk_component(a_config) -side top -expand 0 -fill x

        itk_component add preset {
            DCS::CollimatorPresetTabView $presetSite.preset \
            -tabpos w \
            -nameField 0 \
            -stringName ::device::collimator_preset \
            -systemIdleOnly 0 \
            -activeClientOnly 0
        } {
            keep -mdiHelper
        }
        pack $itk_component(preset) -side top -expand 1 -fill both

        eval itk_initialize $args

        pack $itk_component(notebook) -expand 1 -fill both
    }
}
class userAlignBeamRunView {
 	inherit ::itk::Widget

    itk_option define -controlSystem controlsytem ControlSystem ::dcss
    itk_option define -mdiHelper mdiHelper MdiHelper ""

	public method startAlignTungsten
	public method startAlignCollimator
	public method startMatchupSample
	public method startMatchupInline
	public method startFocusInline
    public method savePerfect
	public method mountPin
	public method dismountPin

    private method constructControlPanel { ring }

    private variable m_deviceFactory
    private variable m_opAlignCollimator
    private variable m_opAlignTungsten
    private variable m_opUserAlignBeam
    private variable m_opMatchup
    private variable m_opISample
    private variable m_statusObj
    private variable m_logger

	constructor { args } {

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_opAlignCollimator [$m_deviceFactory createOperation alignCollimator]
        set m_opAlignTungsten [$m_deviceFactory createOperation alignTungsten]
        set m_opUserAlignBeam [$m_deviceFactory createOperation userAlignBeam]
        set m_opMatchup [$m_deviceFactory createOperation matchup]
        set m_opISample [$m_deviceFactory createOperation ISampleMountingDevice]
        set m_statusObj [$m_deviceFactory createString robot_status]
        $m_statusObj createAttributeFromField status_num 1
        $m_statusObj createAttributeFromField mounted 15
        set m_logger [DCS::Logger::getObject]

		# construct the parameter widgets
		constructControlPanel $itk_interior

        eval itk_initialize $args

	}
}

body userAlignBeamRunView::constructControlPanel { ring } {

    frame $ring.top

    set topSite $ring.top

    itk_component add robot {
        iwidgets::Labeledframe $topSite.robot \
        -labelfont "helvetica -16 bold" \
        -labelpos nw \
        -labeltext "Pin"
    } {
    }
    set robotSite [$itk_component(robot) childsite]

    itk_component add mount {
        DCS::Button $robotSite.m -command "$this mountPin 0" \
        -width 22 \
        -anchor w \
        -text "Mount Alignment Pin A"
    } {
    }
    itk_component add mountII {
        DCS::Button $robotSite.m2 -command "$this mountPin 1" \
        -width 22 \
        -anchor w \
        -text "Mount Alignment Pin B"
    } {
    }

    itk_component add dismount {
        DCS::Button $robotSite.d -command "$this dismountPin" \
        -width 22 \
        -anchor w \
        -text "Dismount Alignment Pin"
    } {
    }

    foreach item {mount mountII dismount} {
        $itk_component($item) addInput \
        "$m_opISample permission GRANTED {PERMISSION}"

        $itk_component($item) addInput \
        "$m_opISample status inactive {supporting device}"

        $itk_component($item) addInput \
        "$m_statusObj status_num 0 {robot not ready}"
    }
    $itk_component(mount) addInput \
    "$m_statusObj mounted {} {dismount first}"
    $itk_component(mountII) addInput \
    "$m_statusObj mounted {} {dismount first}"
    $itk_component(dismount) addInput \
    "$m_statusObj OKToDismountTool 1 {alignment pin not mounted}"

    grid $itk_component(mount)      -row 0 -column 0 -sticky w
    grid $itk_component(mountII)    -row 1 -column 0 -sticky w
    grid $itk_component(dismount)   -row 2 -column 0 -sticky ws

    grid rowconfigure $robotSite 2 -weight 10

    itk_component add control {
        iwidgets::Labeledframe $topSite.control \
        -labelfont "helvetica -16 bold" \
        -labelpos nw \
        -labeltext "Align"
    } {
    }
    set controlSite [$itk_component(control) childsite]

    itk_component add startM {
        DCS::Button $controlSite.startM -command "$this startMatchupSample" \
        -width 24 \
        -anchor w \
        -text "Move Tungsten to Beam"
    } {}

    $itk_component(startM) addInput \
    "$m_opMatchup permission GRANTED {PERMISSION}"

    $itk_component(startM) addInput \
    "$m_opMatchup status inactive {supporting device}"

    itk_component add startM1 {
        DCS::Button $controlSite.startM1 -command "$this startMatchupInline" \
        -width 24 \
        -anchor w \
        -text "Move Inline to Tungsten"
    } {}

    $itk_component(startM1) addInput \
    "$m_opMatchup permission GRANTED {PERMISSION}"

    $itk_component(startM1) addInput \
    "$m_opMatchup status inactive {supporting device}"

    itk_component add startM2 {
        DCS::Button $controlSite.startM2 -command "$this startFocusInline" \
        -width 24 \
        -anchor w \
        -text "Autofocus Inline"
    } {}

    $itk_component(startM2) addInput \
    "$m_opMatchup permission GRANTED {PERMISSION}"

    $itk_component(startM2) addInput \
    "$m_opMatchup status inactive {supporting device}"

    itk_component add startT {
        DCS::Button $controlSite.startT -command "$this startAlignTungsten" \
        -width 24 \
        -anchor w \
        -text "Start Align Tungsten"
    } {}

    $itk_component(startT) addInput \
    "$m_opAlignTungsten permission GRANTED {PERMISSION}"

    $itk_component(startT) addInput \
    "$m_opAlignTungsten status inactive {supporting device}"

    itk_component add startA {
        DCS::Button $controlSite.startA -command "$this startAlignCollimator" \
        -width 24 \
        -anchor w \
        -text "Start Align Collimator"
    } {}

    $itk_component(startA) addInput \
    "$m_opAlignCollimator permission GRANTED {PERMISSION}"

    $itk_component(startA) addInput \
    "$m_opAlignCollimator status inactive {supporting device}"

    itk_component add startS1 {
        DCS::HotButton $controlSite.startS1 -command "$this savePerfect" \
        -background yellow \
        -width 32 \
        -text "Save Tungsten Pin Position" \
        -confirmText "Previous snapshot will be erased"
    } {}
    $itk_component(startS1) addInput \
    "$m_opMatchup permission GRANTED {PERMISSION}"

    $itk_component(startS1) addInput \
    "$m_opMatchup status inactive {supporting device}"
    
    grid $itk_component(startM)      -row 0 -column 0 -sticky w
    grid $itk_component(startT)      -row 1 -column 0 -sticky w
    grid $itk_component(startA)      -row 2 -column 0 -sticky w
    grid $itk_component(startM2)     -row 3 -column 0 -sticky w
    grid $itk_component(startM1)     -row 4 -column 0 -sticky w

    grid rowconfigure $controlSite 5 -weight 10

    #grid $itk_component(startS1)     -row 0 -column 1 -sticky w
    #grid columnconfig $controlSite 1 -weight 1

    itk_component add config {
        iwidgets::Labeledframe $topSite.config \
        -labelfont "helvetica -16 bold" \
        -labelpos nw \
        -labeltext "Optimize Beam Options"
    } {
    }
    set configSite [$itk_component(config) childsite]

    itk_component add top_config {
        DCS::UserAlignBeamStatusView $configSite.view \
        -activeClientOnly 0 \
        -systemIdleOnly 0 \
    } {
    }
    pack $itk_component(top_config) -side top -fill x

    itk_component add log {
        DCS::DeviceLog $ring.l
    } {
    }
    $itk_component(log) addDeviceObjs $m_opAlignCollimator $m_opMatchup \
    $m_opAlignTungsten $m_opUserAlignBeam

    pack $itk_component(robot) -side left -expand 0 -fill y
    pack $itk_component(control) -side left -expand 0 -fill y
    pack $itk_component(config) -side left -expand 1 -fill both

    pack $ring.top -side top -fill x
    pack $itk_component(log) -side top -expand 1 -fill both

}

body userAlignBeamRunView::startAlignTungsten {} {
    $m_opAlignTungsten startOperation
}
body userAlignBeamRunView::startAlignCollimator {} {
    $m_opAlignCollimator startOperation
}
body userAlignBeamRunView::startMatchupSample {} {
    $m_opMatchup startOperation adjust_sample
}
body userAlignBeamRunView::startMatchupInline {} {
    $m_opMatchup startOperation adjust_inline
}
body userAlignBeamRunView::startFocusInline {} {
    $m_opMatchup startOperation auto_focus
}
body userAlignBeamRunView::savePerfect {} {
    $m_opMatchup startOperation save_perfect
}
body userAlignBeamRunView::mountPin { tool_num } {
    $m_opISample startOperation mountBeamLineTool $tool_num
}
body userAlignBeamRunView::dismountPin {} {
    $m_opISample startOperation dismountBeamLineTool
}
