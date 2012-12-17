#!/bin/sh
# the next line restarts using -*-Tcl-*-sh \
	 exec wish "$0" ${1+"$@"}
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

package provide BLUICEQueueTab 1.0

# load the required standard packages
package require Itcl
package require Iwidgets

# source all Tcl files
package require DCSDeviceFactory

#package require BLUICEHutchTab
package require BLUICESequenceCrystals
package require BLUICEScreeningControl
package require BLUICEScreeningTask
package require BLUICEQueueView

class QueueTab {
	inherit ::itk::Widget

	itk_option define -controlSystem controlSystem ControlSystem "::dcss"

	public method addChildVisibilityControl

	# public methods
	constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        itk_component add pw_v {
            iwidgets::panedwindow $itk_interior.pw -orient vertical
        } {
        }
        $itk_component(pw_v) add left -minimum 50 -margin 2 
        $itk_component(pw_v) add right -minimum 50 -margin 2
        set leftSite [$itk_component(pw_v) childsite 0]
        set rightSite [$itk_component(pw_v) childsite 1]
        $itk_component(pw_v) fraction 35 65

        itk_component add pw {
            iwidgets::panedwindow $leftSite.pw -orient horizontal
        } {
        }

        $itk_component(pw) add crystal -minimum 50 -margin 5 
        $itk_component(pw) add control -minimum 50 -margin 5

        set crystalSite [$itk_component(pw) childsite 0] 
        set controlSite   [$itk_component(pw) childsite 1]
        $itk_component(pw) fraction 70 30


		itk_component add sequenceCrystals {
			SequenceCrystals $crystalSite.sc
		} {
		}

		itk_component add sequenceTasks {
			ScreeningTaskWidget $controlSite.tasks \
            -crystalListWidget $itk_component(sequenceCrystals) \
            -width 40 -height 100
		} {
		}
		
		itk_component add control {
			ScreeningControl $controlSite.ctrl
		} {
		}

		itk_component add status {
			ScreeningStatus $controlSite.st
		} {
		}

		itk_component add queue {
            DCS::QueueView $rightSite.qv
        } {
            keep -videoParameters
            keep -videoEnabled
		}

        ##crystalSite
		pack $itk_component(sequenceCrystals) -expand 1 -fill both

        ##controlSite
		grid $itk_component(control) -row 0 -column 0 -columnspan 2 -sticky news
		grid $itk_component(sequenceTasks) -row 1 -column 0 -sticky news
		grid $itk_component(status) -row 1 -column 1 -sticky news
		grid columnconfigure $controlSite 0 -weight 1
		grid rowconfigure $controlSite 1 -weight 1

        ### leftSite
		pack $itk_component(pw) -expand 1 -fill both

        ### rightSite
        pack $itk_component(queue) -expand 1 -fill both

        ### top level
        pack $itk_component(pw_v) -expand 1 -fill both

		eval itk_initialize $args

        ::mediator announceExistence $this

        $itk_component(queue) hook $itk_component(sequenceCrystals)
	}

    destructor {
        ::mediator announceDestruction $this
    }
}

#thin wrapper for the video enable based on visibility
body QueueTab::addChildVisibilityControl { args} {
	eval $itk_component(queue) addChildVisibilityControl $args
}
