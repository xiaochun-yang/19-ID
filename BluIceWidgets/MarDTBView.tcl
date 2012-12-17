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

package provide BLUICEMarDTBView 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil 1.0
package require DCSSet 1.0
package require DCSComponent 1.0

package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
package require DCSHardwareManager
package require DCSPrompt
package require DCSMotorControlPanel
package require BLUICECanvasShapes
package require BLUICEShutterControl


class DCS::MarDTBView {
 	inherit ::DCS::CanvasShapes

	itk_option define -mdiHelper mdiHelper MdiHelper ""

    public proc getMotorList { } {
        return [list \
        gonio_phi \
		sample_x \
		sample_y \
		sample_z \
        table_horz \
        table_yaw \
        table_vert \
        table_pictch \
        ]
    }

	constructor { args} {

		# draw and label the goniometer
		global BLC_IMAGES

		set goniometerImage [ image create photo -file "$BLC_IMAGES/mardtb.jpg" -palette "8/8/8"]

		place $itk_component(control) -x 220 -y 300

		# construct the goniometer widgets
		motorView gonio_phi 615 30 n
		motorView sample_x  615 80 n um 
		motorView sample_y  615 130 n um
		motorView sample_z  615 180 n um

        motorView table_vert    200 200 nw
        motorView table_pitch   350 200 nw
        motorView table_horz    200 250 nw
        motorView table_yaw     350 250 nw

        itk_component add ss1 {
            ShutterView $itk_component(canvas).sv1 \
            -buttonWidth 10 \
            -labelWidth 5 \
            -openButtonLabel "12V on" \
            -closeButtonLabel "12V off" \
            -openText "on" \
            -closedText "off" \
            -shutterName loc_12v \
        } {
		    keep -mdiHelper
        }
        itk_component add ss2 {
            ShutterView $itk_component(canvas).sv2 \
            -buttonWidth 10 \
            -labelWidth 5 \
            -openButtonLabel "light in" \
            -closeButtonLabel "light out" \
            -openText "in" \
            -closedText "out" \
            -shutterName backlight_in \
        } {
		    keep -mdiHelper
        }
        itk_component add ss3 {
            ShutterView $itk_component(canvas).sv3 \
            -buttonWidth 10 \
            -labelWidth 5 \
            -openButtonLabel "light on" \
            -closeButtonLabel "light off" \
            -openText "on" \
            -closedText "off" \
            -shutterName backlight_on \
        } {
		    keep -mdiHelper
        }
        itk_component add ss4 {
            ShutterView $itk_component(canvas).sv4 \
            -buttonWidth 10 \
            -labelWidth 5 \
            -openButtonLabel "high volt on" \
            -closeButtonLabel "high volt off" \
            -openText "on" \
            -closedText "off" \
            -shutterName hv_on \
        } {
		    keep -mdiHelper
        }
        itk_component add ss5 {
            ShutterView $itk_component(canvas).ss5 \
            -buttonWidth 10 \
            -labelWidth 5 \
            -openButtonLabel "beamextern on" \
            -closeButtonLabel "beamxtern off" \
            -openText "on" \
            -closedText "off" \
            -shutterName beamextern \
        } {
		    keep -mdiHelper
        }

        set deviceFactory [DCS::DeviceFactory::getObject]

        for {set i 1} {$i <= 5} {incr i} {
            set devName [$itk_component(ss$i) cget -shutterName]
            set devName [$deviceFactory getObjectName $devName]
            set y_pos [expr $i * 30]
            if {[$deviceFactory deviceExists $devName]} {
                place $itk_component(ss$i) -x 20 -y $y_pos
            }
        }

		eval itk_initialize $args

		# display photo of the goniometer
		$itk_component(canvas) create image 290 20 -anchor nw -image $goniometerImage



		eval itk_initialize $args
		$itk_component(canvas) configure -width 900 -height 350
	}

}

