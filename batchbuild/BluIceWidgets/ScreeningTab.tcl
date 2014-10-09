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

package provide BLUICEScreeningTab 1.0

# load the required standard packages
package require Itcl
package require Iwidgets
package require BWidget
package require BLT

# source all Tcl files
package require DCSDeviceFactory

package require BLUICEHutchTab
package require BLUICEVideoNotebook
package require BLUICESamplePosition
package require BLUICESequenceCrystals
package require BLUICEScreeningControl
package require BLUICESequenceActions
package require BLUICEScreeningTask
package require BLUICERobot
package require BLUICECollimatorCheckbutton

class ScreeningTab {
	inherit ::itk::Widget

	itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_deviceFactory
    private variable m_objRobotStatus
    private variable m_mask 1

	public method addChildVisibilityControl
    public method handleRobotStatus

	# public methods
	constructor { args } {
        global gMotorBeamWidth
        global gMotorBeamHeight

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objRobotStatus [$m_deviceFactory createString robot_status]
        $m_objRobotStatus createAttributeFromField status_num 1
        set m_mask [expr 1 << 6]

       itk_component add pw_v {
           iwidgets::panedwindow $itk_interior.pw -orient vertical
       } {
       }
      $itk_component(pw_v) add left -minimum 50 -margin 2 
      $itk_component(pw_v) add right -minimum 50 -margin 2
        set leftSite [$itk_component(pw_v) childsite 0]
        set rightSite [$itk_component(pw_v) childsite 1]
      $itk_component(pw_v) fraction 65 35

       itk_component add pw {
           iwidgets::panedwindow $leftSite.pw -orient horizontal
       } {
       }

      $itk_component(pw) add crystals -minimum 50 -margin 5 
      $itk_component(pw) add video -minimum 50 -margin 5

      set crystals [$itk_component(pw) childsite 0] 
      set video [$itk_component(pw) childsite 1]
      $itk_component(pw) fraction 40 60

       itk_component add pw2 {
           iwidgets::panedwindow $rightSite.pw2 -orient horizontal
       } {
       }
       itk_component add user_action {
           PortJamUserActionWidget $rightSite.user_action \
            -background red
       } {
       }

      $itk_component(pw2) add actions -minimum 50 -margin 5 
      $itk_component(pw2) add preview -minimum 50 -margin 5

      set actions [$itk_component(pw2) childsite 0] 
      set preview [$itk_component(pw2) childsite 1]
      $itk_component(pw2) fraction 50 50


		itk_component add sequenceCrystals {
			SequenceCrystals $crystals.sc
		} {
		}

		itk_component add sequenceTasks {
			ScreeningTaskWidget $preview.tasks \
            -crystalListWidget $itk_component(sequenceCrystals) \
            -width 40 -height 100
		} {
		}
		
		itk_component add video {
			DCS::BeamlineVideoNotebook $video.v "" \
                 -activeClientOnly 0	 \
		         -imageUrl2 [::config getImageUrl 2] \
		         -imageUrl3 [::config getImageUrl 3] \
		         -imageUrl4 [::config getImageUrl 4] \
		         -textUrl2 [::config getTextUrl 2] \
		         -textUrl3 [::config getTextUrl 3] \
		         -textUrl4 [::config getTextUrl 4] \
		         -presetUrl2 [::config getPresetUrl 2] \
		         -presetUrl3 [::config getPresetUrl 3] \
		         -presetUrl4 [::config getPresetUrl 4] \
		         -moveRequestUrl2 [::config getMoveRequestUrl 2] \
		         -moveRequestUrl3 [::config getMoveRequestUrl 3] \
		         -moveRequestUrl4 [::config getMoveRequestUrl 4] \
		         -channelArgs2 [::config getVideoArgs 2] \
		         -channelArgs3 [::config getVideoArgs 3] \
		         -channelArgs4 [::config getVideoArgs 4] \
                 -beamWidthWidget \
                 [$m_deviceFactory getObjectName $gMotorBeamWidth] \
                 -beamHeightWidget \
                 [$m_deviceFactory getObjectName $gMotorBeamHeight]
		} {
			keep -videoParameters
			keep -videoEnabled
		}

		itk_component add globalParam {
			ScreeningGlobalParameters $rightSite.gp
		} {
		}

		itk_component add actions {
			ScreeningSequenceConfig $actions.sa
		} {
		}

        itk_component add collimator {
		    CollimatorDropdown $preview.collimator
        } {
        }

		itk_component add control {
			ScreeningControl $preview.ctrl
		} {
		}

		itk_component add status {
			ScreeningStatus $preview.st
		} {
		}

		#$itk_component(fileViewer) createFileList
		#grid columnconfigure $itk_interior 0 -weight 10
		#grid columnconfigure $itk_interior 1 -weight 0
		#grid columnconfigure $itk_interior 2 -weight 0


		grid rowconfigure $rightSite 0 -weight 0 
		grid rowconfigure $rightSite 1 -weight 1 


		#grid $itk_component(pw) -row 0 -column 0 -rowspan 3 -sticky news
		pack $itk_component(pw) -expand 1 -fill both
		pack $itk_component(video) -expand 1 -fill both
		pack $itk_component(sequenceCrystals) -expand 1 -fill both

		grid $itk_component(globalParam) -row 0 -column 0

		grid $itk_component(pw2) -row 1 -column 0 -sticky news

		pack $itk_component(actions) -expand 1 -fill both

        set cfgShowCollimator [::config getInt bluice.showCollimator 1]
        if {$cfgShowCollimator \
        && [$m_deviceFactory operationExists collimatorMove]} {
		    grid $itk_component(collimator) -row 0 -column 0 -sticky w
        }
		grid $itk_component(control) -row 1 -column 0 -columnspan 2 -sticky news
		grid $itk_component(sequenceTasks) -row 2 -column 0 -sticky news
		grid $itk_component(status) -row 2 -column 1 -sticky news
		grid columnconfigure $preview 0 -weight 1
		grid rowconfigure $preview 2 -weight 1

        pack $itk_component(pw_v) -expand 1 -fill both

      $itk_component(actions) setCondensed 1

		eval itk_initialize $args

        ::mediator announceExistence $this

        ::mediator register $this ::$m_objRobotStatus status_num handleRobotStatus
	}

    destructor {
        ::mediator announceDestruction $this
    }
}

body ScreeningTab::handleRobotStatus { stringName_ targetReady_ alias_ contents_ - } {

    if {!$targetReady_} return

    puts "robot_status status_num: $contents_"
    if {![string is integer -strict $contents_]} {
        puts "ignore, {$contents_} not integer"
        return
    }

    set showPrompt [expr $contents_ & $m_mask]

    if {$showPrompt} {
		grid forget $itk_component(pw2)
		grid $itk_component(user_action) -row 1 -column 0 -sticky news
    } else {
		grid forget $itk_component(user_action)
		grid $itk_component(pw2) -row 1 -column 0 -sticky news
    }
}
#thin wrapper for the video enable based on visibility
body ScreeningTab::addChildVisibilityControl { args} {
	eval $itk_component(video) addChildVisibilityControl $args
}

proc startScreeningTab { configuration_ } {

	global BLC_DATA
	
	#get the configurations for the vide urls
	set hutchVideoUrl [$configuration_ getHutchUrl]
	set outsideHutchVideoUrl [$configuration_ getOutsideHutchUrl]
 	set hutchPtz [$configuration_ getHutchPtz]
 	set outsideHutchPtz [$configuration_ getOutsideHutchPtz]
 	set hutchTextUrl [$configuration_ getHutchTextUrl]
 	set outsideHutchTextUrl [$configuration_ getOutsideHutchTextUrl] 
	
	#get the name of the periodic table specification file
	set periodicFile [$configuration_ getPeriodicFilename]
	if { $periodicFile != ""} {
		#add the directory if we know the name of the file
		set periodicFile [file join $BLC_DATA $periodicFile]
	}

	ScreeningTab .screening \
		 -videoParameters &resolution=high \
		 -sampleXDevice ::device::sample_x \
		 -sampleYDevice ::device::sample_y \
		 -sampleZDevice ::device::sample_z \
		 -videoEnabled 1 \
		 -hutchVideoUrl $hutchVideoUrl \
		 -controlVideoUrl $outsideHutchVideoUrl \
 		 -ptzUrl $hutchPtz \
 		 -controlPtzUrl $outsideHutchPtz \
 		 -hutchVideoTextUrl $hutchTextUrl \
 		 -controlVideoTextUrl $outsideHutchTextUrl \
		 -periodicFile $periodicFile
	
	pack .screening -expand yes -fill both
}

