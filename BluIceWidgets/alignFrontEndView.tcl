#!/usr/bin/wish
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

package require Itcl
package require Iwidgets
package require BWidget

package provide BLUICEAlignFrontEndView 1.0

# load the DCS packages
package require DCSString
package require DCSDeviceLog
package require DCSButton
package require DCSDeviceFactory

class alignFrontEndView {
 	inherit ::itk::Widget
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    constructor { args } {
        itk_component add notebook {
            iwidgets::Tabnotebook $itk_interior.nb -tabpos n -height 400
        } {
        }
        #create all of the pages
        set RunSite [$itk_component(notebook) add -label "Run"]
        set ConfigSite [$itk_component(notebook) add -label "Config"]
        $itk_component(notebook) view 0

        itk_component add run {
            alignFrontEndRunView $RunSite.run
        } {
            keep -mdiHelper
        }
        itk_component add config {
            DCS::AlignFrontEndConfigView $ConfigSite.config \
            -systemIdleOnly 0 \
            -activeClientOnly 0
        } {
            keep -mdiHelper
        }

        eval itk_initialize $args

        pack $itk_component(run) -expand yes -fill both
        pack $itk_component(config) -expand yes -fill both
        pack $itk_component(notebook) -expand 1 -fill both
    }
}

class alignFrontEndRunView {
 	inherit ::itk::Widget

    itk_option define -controlSystem controlsytem ControlSystem ::dcss
    itk_option define -mdiHelper mdiHelper MdiHelper ""

	public method startOperation
	public method mountPin
	public method dismountPin

    private method constructControlPanel { ring }

    private variable m_deviceFactory
    private variable m_operation
    private variable m_opISample
    private variable m_statusObj
    private variable m_logger

    private variable m_a1 1
    private variable m_a2 1
    private variable m_a3 2

	constructor { args } {

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_operation [$m_deviceFactory createOperation alignFrontEnd]
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



body alignFrontEndRunView::constructControlPanel { ring } {

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
        DCS::Button $robotSite.m -command "$this mountPin" \
        -width 22 \
        -anchor w \
        -text "Mount Alignment Pin"
    } {
    }

    itk_component add dismount {
        DCS::Button $robotSite.d -command "$this dismountPin" \
        -width 22 \
        -anchor w \
        -text "Dismount Alignment Pin"
    } {
    }

    foreach item {mount dismount} {
        $itk_component($item) addInput \
        "$m_opISample permission GRANTED {PERMISSION}"

        $itk_component($item) addInput \
        "$m_opISample status inactive {supporting device}"

        $itk_component($item) addInput \
        "$m_statusObj status_num 0 {robot not ready}"
    }
    $itk_component(mount) addInput \
    "$m_statusObj mounted {} {dismount first}"
    $itk_component(dismount) addInput \
    "$m_statusObj mounted {b 0 T} {alignment pin not mounted}"

    grid $itk_component(mount)      -row 0 -column 0 -sticky w
    grid $itk_component(dismount)   -row 1 -column 0 -sticky w


    itk_component add control {
        iwidgets::Labeledframe $topSite.control \
        -labelfont "helvetica -16 bold" \
        -labelpos nw \
        -labeltext "Align"
    } {
    }
    set controlSite [$itk_component(control) childsite]

    itk_component add start {
        DCS::Button $controlSite.c -command "$this startOperation" \
        -width 24 \
        -anchor w \
        -text "Start alignFrontEnd"
    } {}

    $itk_component(start) addInput \
    "$m_operation permission GRANTED {PERMISSION}"


    $itk_component(start) addInput \
    "$m_operation status inactive {supporting device}"

    itk_component add arg1 {
        checkbutton $controlSite.a1 \
        -anchor w \
        -text "optimize table" \
        -variable [scope m_a1]
    } {
    }

    itk_component add arg2 {
        checkbutton $controlSite.a2 \
        -anchor w \
        -text "align slits" \
        -variable [scope m_a2]
    } {
    }

    itk_component add arg3 {
        iwidgets::Labeledframe $controlSite.a3 \
        -labelfont "helvetica -16 bold" \
        -labelpos nw \
        -labeltext "horizontal alignment of front end"
    } {
    }
    set a3Site [$itk_component(arg3) childsite]

    radiobutton $a3Site.r1 -text "skip" \
    -anchor w \
    -value 1 -variable [scope m_a3]

    radiobutton $a3Site.r2 -text "sample is in kappa center" \
    -anchor w \
    -value 2 -variable [scope m_a3]

    radiobutton $a3Site.r3 -text "align using kappa" \
    -anchor w \
    -value 3 -variable [scope m_a3]

    pack $a3Site.r1 $a3Site.r2 $a3Site.r3 -side top -expand 1 -fill both

    grid $itk_component(start)      -row 0 -column 0 -sticky w
    grid $itk_component(arg1)       -row 1 -column 0 -sticky w
	grid $itk_component(arg2)       -row 2 -column 0 -sticky w

    grid $itk_component(arg3)       -row 0 -column 1 -rowspan 3 -sticky news

    grid columnconfig $controlSite 1 -weight 1

    itk_component add log {
        DCS::DeviceLog $ring.l
    } {
    }
    $itk_component(log) addDeviceObjs $m_operation

    pack $itk_component(robot) -side left -expand 0 -fill y
    pack $itk_component(control) -side left -expand 1 -fill both


    pack $ring.top -side top -fill x
    pack $itk_component(log) -side top -expand 1 -fill both

}

body alignFrontEndRunView::startOperation {} {
	global env

    #puts "args $m_a1 $m_a2 $m_a3"
    $m_operation startOperation $m_a1 $m_a2 $m_a3
}
body alignFrontEndRunView::mountPin {} {
    $m_opISample startOperation mountBeamLineTool
}
body alignFrontEndRunView::dismountPin {} {
    $m_opISample startOperation dismountBeamLineTool
}
