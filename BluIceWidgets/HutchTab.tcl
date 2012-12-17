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

package provide BLUICEHutchTab 1.0

package require DCSTabNotebook
package require BLUICEResolution
package require BLUICECryojet

package require BLUICEBL93HutchOverview
package require BLUICEBL3BM1HutchOverview
package require BLUICEHutchOverviewBL12-2

class HutchTab {
	inherit ::itk::Widget

	public method addChildVisibilityControl

	# public methods
	constructor { args } {
		
		set childsite $itk_interior

        set hutchClass [::config getHutchView]
        
		#pack the hutch overview widget in the titled frame
		itk_component add hutchWidget {
			$hutchClass ${childsite}.hutch 
		} {
			keep -detectorType -gonioPhiDevice -gonioOmegaDevice
			keep -gonioKappaDevice -detectorVertDevice
			keep -detectorHorzDevice -detectorZDevice -energyDevice
			keep -attenuationDevice -beamWidthDevice -beamHeightDevice
			keep -beamstopDevice -beamstopHorzDevice -beamstopVertDevice
		}

        #create a frame to host resolution and sample wash
        itk_component add right_frame {
            frame $itk_interior.r_frame
        } {
        }

		# create labeled frame for resolution widget
		itk_component add resolutionFrame {
			::DCS::TitledFrame $itk_component(right_frame).res \
				 -background lightgrey \
				 -labelFont "helvetica -16 bold" \
				 -labelText "Resolution Predictor"
		} {
		}

		set childsite [$itk_component(resolutionFrame) childsite]

		#pack the resolution in the titled widget
		itk_component add resolution {
			DCS::ResolutionWidget ${childsite}.res \
				 -detectorBackground  #c0c0ff \
				 -detectorForeground white \
		} {
			keep -detectorType
		}

		#let the resolution widget know the names of the motor widgets
		$itk_component(resolution) configure -detectorXWidget [$itk_component(hutchWidget) getDetectorHorzWidget ]
		$itk_component(resolution) configure -detectorYWidget [$itk_component(hutchWidget) getDetectorVertWidget ]
		$itk_component(resolution) configure -detectorZWidget [$itk_component(hutchWidget) getDetectorZWidget ]
		$itk_component(resolution) configure -beamstopZWidget [$itk_component(hutchWidget) getBeamstopZWidget ]
		$itk_component(resolution) configure -beamstopXWidget [$itk_component(hutchWidget) getBeamstopHorzWidget ]
		$itk_component(resolution) configure -beamstopYWidget [$itk_component(hutchWidget) getBeamstopVertWidget ]
		$itk_component(resolution) configure -energyWidget [$itk_component(hutchWidget) getEnergyWidget ]

	
        #create a frame to host video and anneal
        itk_component add middle_frame {
            frame $itk_interior.m_frame
        } {
        }

		itk_component add video {
			DCS::BeamlineVideoNotebook $itk_component(middle_frame).v "" \
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
        -beamWidthWidget  [$itk_component(hutchWidget) getBeamWidthWidget] \
        -beamHeightWidget  [$itk_component(hutchWidget) getBeamHeightWidget]

		#pack the resolution in the titled widget
		eval itk_initialize $args
		
		grid columnconfigure $itk_interior 0 -weight 2
		grid columnconfigure $itk_interior 1 -weight 1
		grid rowconfigure $itk_interior 0 -weight 0
		grid rowconfigure $itk_interior 1 -weight 1

		grid $itk_component(hutchWidget) -row 0 -column 0 -columnspan 3 -sticky news
		grid $itk_component(middle_frame) -row 1 -column 0 -sticky news
		grid $itk_component(right_frame) -row 1 -column 1 -sticky news

		pack $itk_component(resolutionFrame) -expand 1 -fill both
		pack $itk_component(resolution) -expand 1 -fill both

		pack $itk_component(video) -side top -expand 1 -fill both
		return
	}
}

#thin wrapper for the video enable based on visibility
body HutchTab::addChildVisibilityControl { args} {
	eval $itk_component(video) addChildVisibilityControl $args
}

