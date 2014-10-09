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

package provide BLUICESampleTab 1.0
package require BLUICECryojet
package require BLUICEBeamSize
package require BLUICELightControl

class SampleTab {
	inherit ::itk::Widget

	public method addChildVisibilityControl

	# public methods
	constructor { args } {
        itk_component add pw_v {
            iwidgets::panedwindow $itk_interior.pw \
            -orient vertical
        } {
        }
        $itk_component(pw_v) add left  -minimum 50 -margin 2
        $itk_component(pw_v) add right -minimum 50 -margin 2
        set leftSite  [$itk_component(pw_v) childsite 0]
        set rightSite [$itk_component(pw_v) childsite 1]
        $itk_component(pw_v) fraction 50 50

        ##### this is just to pack the video and light_control so that
        ##### their distance will not expand ##
        itk_component add pw_r {
            iwidgets::panedwindow $rightSite.pw \
            -orient horizontal
        } {
        }
        $itk_component(pw_r) add up -minimum 200 -margin 2
        $itk_component(pw_r) add low -minimum 0 -margin 2
        set right_upSite [$itk_component(pw_r) childsite 0]
        $itk_component(pw_r) fraction 100 0

        set useRobot [::config getBluIceUseRobot]
        if { $useRobot } {
           itk_component add robot {
               RobotMountWidget $leftSite.robot
           } {}
        }

        itk_component add beam_size {
            BeamSizeView $right_upSite.bs \
            -activeClientOnly 1 \
            -systemIdleOnly 1 \
            -honorStatus 1
        } {
        }

		itk_component add video {
			DCS::BeamlineVideoNotebook $right_upSite.v "" \
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
		         -channelArgs4 [::config getVideoArgs 4]
		} {
			keep -videoParameters
			keep -videoEnabled 
		}

        $itk_component(video) configure \
        -beamWidthWidget  [$itk_component(beam_size) getBeamWidthWidget] \
        -beamHeightWidget [$itk_component(beam_size) getBeamHeightWidget]

        # create labeled frame for anneal widget
        itk_component add annealFrame {
            ::DCS::TitledFrame $right_upSite.a_f\
                 -background lightgrey \
                 -labelText "Sample Annealing"
        } {
        }
        set annealSite [$itk_component(annealFrame) childsite]

        itk_component add anneal {
            iwidgets::tabnotebook $annealSite.nb \
            -tabpos n \
            -height 60
        } {
        }
        set flowSite  [$itk_component(anneal) add -label "Flow Control"]
        set blockSite [$itk_component(anneal) add -label "Stream Block"]
        $itk_component(anneal) view 0

        itk_component add anneal_flow {
            AnnealWidget $flowSite.anneal \
            -systemIdleOnly 1 \
            -activeClientOnly 1
        } {
        }
        itk_component add anneal_block {
            BlockAnnealWidget $blockSite.anneal \
            -systemIdleOnly 1 \
            -activeClientOnly 1
        } {
        }

		eval itk_initialize $args
		
        if {$useRobot} {pack $itk_component(robot) -side top -expand 1 -fill both}
		pack $itk_component(anneal) -side top -fill both
		pack $itk_component(anneal_flow) -side top
		pack $itk_component(anneal_block) -side top

		pack $itk_component(annealFrame) -side top -fill x
		pack $itk_component(beam_size) -side top -fill x
		pack $itk_component(video) -side top -fill both -expand 1

		pack $itk_component(pw_r) -side top -expand 1 -fill both
		pack $itk_component(pw_v) -side left -expand 1 -fill both

		return
	}
}

#thin wrapper for the video enable based on visibility
body SampleTab::addChildVisibilityControl { args} {
	eval $itk_component(video) addChildVisibilityControl $args
}

