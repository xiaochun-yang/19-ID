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

package provide BLUICEBL42TableView 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
package require DCSHardwareManager
package require DCSPrompt
package require DCSMotorControlPanel

package require BLUICECanvasShapes

class DCS::BL42TableView {
 	inherit ::DCS::CanvasShapes

	itk_option define -mdiHelper mdiHelper MdiHelper ""

    public proc getMotorList { } {
        return [list \
		table_3_tilt \
		table_3_vert \
		table_3_horz \
		table_2_tilt \
		table_2_vert \
		table_2_horz \
		table_1_tilt \
		table_1_vert \
		table_1_horz \
        ]
    }
	
	constructor { args} {

		place $itk_component(control) -x 300 -y 275

		# construct Table 3 widgets
		motorView table_3_tilt 0 120 sw 
		motorView table_3_vert 135 85 sw 
		motorView table_3_horz 45 200 
		# draw the table
		rect_solid 50 120 150 20 40 60 40 
		motorArrow table_3_tilt 75 120 {} 75 145 87 125 87 145
		motorArrow table_3_vert 168 90 {} 168 140 178 94 178 140
		motorArrow table_3_horz 125 170 {} 92 197 133 172 111 196

		# construct Table 2 widgets
		motorView table_2_tilt 290 120 sw 
		motorView table_2_vert 420 85 sw 
		motorView table_2_horz 335 200 
		# draw the table
		rect_solid 310 120 210 20 40 60 40 
		motorArrow table_2_tilt 340 120 {} 340 145 352 124 352 145
		motorArrow table_2_vert 450 90 {} 450 140 462 94 462 140
		motorArrow table_2_horz 415 170 {} 382 197 423 172 401 196

		# construct Table 1 widgets
		motorView table_1_tilt 590 120 sw 
		motorView table_1_vert 725 90 sw 
		motorView table_1_horz 625 200 
		# draw the table
		rect_solid 630 120 150 20 40 60 40 
		motorArrow table_1_tilt 655 120 {} 655 145 667 124 667 145
		motorArrow table_1_horz 748 90 {} 748 140 760 94 760 140
		motorArrow table_1_horz 705 170 {} 672 197 713 172 691 196

		eval itk_initialize $args
		$itk_component(canvas) configure -width 860 -height 310
	}
}

