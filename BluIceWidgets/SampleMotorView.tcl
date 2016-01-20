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
package provide BLUICESampleMotorView 1.0

# load standard packages
#package require Iwidgets
#package require http

# load other BIW packages
#package require DCSUtil
#package require DCSComponent
package require DCSVideo

class BLUICE::SampleMotorWidget {
#	inherit ::itk::Widget
	inherit ::DCS::ComponentGateExtension
	# public variables

	itk_option define -controlSystem controlsytem ControlSystem "dcss"

	# protected variables
   protected variable m_staff ""
   private variable m_realPresetName
   private variable m_extraCounter 0

    public proc getMotorList { } {
        return [list \
        sample_camera_horz \
        sample_camera_vert \
        sample_camera_zoom \
        sample_camera_focus \
        sample_camera_polarizer \
        ]
    }

	# public methods
	public method updateVideoRate

	public method addChildVisibilityControl
	public method addUpdateSpeedInput
   
    public method addExtraWidget { widget args } {
        set extraName extra$m_extraCounter
        itk_component add $extraName {
            eval $widget $itk_component(control).$extraName $args
        } {
        }
        pack $itk_component($extraName)
        incr m_extraCounter
    }

	# constructor
	constructor { args } {
        global gMotorBeamWidth
        global gMotorBeamHeight

        itk_component add control {
            DCS::MotorControlPanel $itk_interior.move \
            -width 7 \
            -orientation horizontal \
            -buttonBackground #c0c0ff \
            -activeButtonBackground #c0c0ff \
            -font "helvetica -14 bold"
        } {
        }

        frame $itk_interior.mf1
        frame $itk_interior.mf2

        set deviceFactory [::DCS::DeviceFactory::getObject]

        foreach motor {sample_camera_horz sample_camera_vert} {
            itk_component add $motor {
                DCS::TitledMotorEntry $itk_interior.mf1.$motor \
                -labelText $motor \
                -autoGenerateUnitsList 1 \
                -device [$deviceFactory getObjectName $motor]
            } {
                keep -mdiHelper
                keep -activeClientOnly
                keep -systemIdleOnly
            }
            pack $itk_component($motor) -side top
            $itk_component(control) registerMotorWidget ::$itk_component($motor)
        }

        foreach motor {sample_camera_zoom sample_camera_focus \
        sample_camera_polarizer} {
            itk_component add $motor {
                DCS::TitledMotorEntry $itk_interior.mf2.$motor \
                -labelText $motor \
                -autoGenerateUnitsList 1 \
                -device [$deviceFactory getObjectName $motor]
            } {
                keep -mdiHelper
                keep -activeClientOnly
                keep -systemIdleOnly
            }
            pack $itk_component($motor) -side top
            $itk_component(control) registerMotorWidget ::$itk_component($motor)
        }

		# create the video image
		itk_component add video {
            SamplePositioningWidget $itk_interior.video \
            [::config getImageUrl 5] \
            sample_sample_camera_constant sample_camera_zoom centerLoop sampleMoveSample \
             -beamWidthWidget ::device::$gMotorBeamWidth \
             -beamHeightWidget ::device::$gMotorBeamHeight
		} {
			keep -videoParameters -videoEnabled
		}
		
		# evaluate configuration parameters	
		eval itk_initialize $args

		grid $itk_component(video) -row 0 -column 0 -sticky news -rowspan 2

        grid $itk_interior.mf2 -row 0 -column 1 -sticky n
        grid $itk_interior.mf1 -row 1 -column 1 -sticky s
        grid $itk_component(control) -row 2 -column 0 -columnspan 3 -sticky e

        grid columnconfigure $itk_interior 0 -weight 100
        grid rowconfigure $itk_interior 0 -weight 100

		::mediator announceExistence $this
	}

}

#thin wrapper for the video enable
body BLUICE::SampleMotorWidget::addChildVisibilityControl { args} {
	eval $itk_component(video) addChildVisibilityControl $args
}

body BLUICE::SampleMotorWidget::addUpdateSpeedInput { trigger } {
	$itk_component(video) addUpdateSpeedInput $trigger
}
