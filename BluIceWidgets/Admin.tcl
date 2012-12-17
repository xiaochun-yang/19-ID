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

package provide BLUICEAdmin 1.0

# load standard packages
package require Iwidgets
#package require BWidget 1.2.1

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

#package require DCSDeviceView
package require DCSProtocol

class Admin {
     inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method handleSend { } {
        ####get sender info
        set message "gtos_admin [$itk_component(contents) get 0.0 end]"

        $itk_option(-controlSystem) sendMessage $message
    }

    #contructor/destructor
    constructor { args  } {
        puts "constructor of Admin"

        itk_component add ring {
            frame $itk_interior.r
        } {
            keep -width -height
        }
        
        itk_component add send {
            button $itk_component(ring).b_send \
            -text "Send Admin Command" \
            -command "$this handleSend"
        } {
        }

		itk_component add contents {
			iwidgets::scrolledtext $itk_component(ring).c -textbackground white
		} {
			keep  -vscrollmode -hscrollmode -wrap
		}

        pack $itk_component(send)
        pack $itk_component(contents)
        pack $itk_component(ring)

        eval itk_initialize $args
        puts "done constructor of Admin"
    }
    destructor {
    }
}
