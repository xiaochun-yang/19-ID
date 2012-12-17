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

package provide BLUICETable 1.0

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

class DCS::TableWidget {
 	inherit ::DCS::CanvasShapes

	itk_option define -mdiHelper mdiHelper MdiHelper ""

    public proc getMotorList { } {
        return [list \
		table_vert \
        table_vert_1 \
        table_vert_2 \
        table_horz \
        table_horz_1 \
        table_horz_2 \
        table_yaw \
        table_pitch \
        ]
    }
	
	constructor { args} {

		place $itk_component(control) -x 230 -y 275

		# construct the table widgets
		motorView table_vert 280 90 sw 
      motorView table_vert_1 145 90 sw
      motorView table_vert_2 410 90 sw
      motorView table_horz 215 200 
      motorView table_horz_1 75 200 
      motorView table_horz_2 355 200
      motorView table_yaw 20 110
      motorView table_pitch 520 110

		# draw the table
		rect_solid 180 120 250 20 40 60 40 

		motorArrow table_vert 330 90 {} 330 140	342 94 342 140
		motorArrow table_vert_1 210  90 {} 210 140 222 94 222 140
		motorArrow table_vert_2 450  90 {} 450 140 462 95 462 140
		motorArrow table_horz 305 170 {} 272 197 313 172 291 196
		motorArrow table_horz_1  190 170 {} 158 197 198 172 176 196
		motorArrow table_horz_2 430 170 {} 403 197 442 177 422 196
		motorArrow table_yaw 165 165 {125 137} 200 135 154 172 186 125
		motorArrow table_pitch 470  110 {500 120 500 160} 470 170 486 104 486 176


		eval itk_initialize $args
      $itk_component(canvas) configure -width 660 -height 310

        configure -serialMove 1
	}
}

