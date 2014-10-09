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

package provide BLUICELaserControl 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSDeviceFactory
package require DCSUtil
package require DCSButton

class LaserControlWidget {
    inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method handleClick

    private variable m_deviceFactory
    private variable m_objOp

    private variable LABEL_LIST
    private variable BOARD_LIST
    private variable CHANNEL_LIST
    private variable N_ITEM

    private variable m_useNewDaqBoard 0

    #contructor/destructor
    constructor { args  } {
        set LABEL_LIST [list \
        goniometer \
        sample \
        table_vert_1 \
        table_vert_2 \
        table_horz_1 \
        table_horz_2]

        set BOARD_LIST {}
        set CHANNEL_LIST {}
        ##get laser config
        foreach item $LABEL_LIST {
            set cfg [::config getStr laser.$item.control]
            lappend BOARD_LIST [lindex $cfg 0]
            lappend CHANNEL_LIST [lindex $cfg 1]
            puts "laser: $item: $cfg"
        }
        set N_ITEM [llength $LABEL_LIST]

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set hwList [$m_deviceFactory getControllerList]
        #puts "hwList: $hwList"
        if {[lsearch -exact $hwList ADAC5500] < 0} {
            set m_useNewDaqBoard 1
            set m_objOp [$m_deviceFactory createOperation setDigOutBit]
            set label "Displacement Sensor Laser On/Off Control on NEW DaqBoard"
        } else {
            set m_useNewDaqBoard 0
            set m_objOp [$m_deviceFactory createOperation setDigitalOutput]
            set label "Displacement Sensor Laser On/Off Control"
        }

        itk_component add fr {
            iwidgets::labeledframe $itk_interior.lf \
            -labelpos nw \
            -labeltext $label
        } {
        }
        set controlSite [$itk_component(fr) childsite]

        for {set i 0} {$i < $N_ITEM} {incr i} {
            itk_component add l$i {
                label $controlSite.l$i \
                -text [lindex $LABEL_LIST $i] \
                -width 12
            } {
            }

            itk_component add on$i {
                DCS::Button $controlSite.on$i \
                -text "On" \
                -width 11 \
                -command "$this handleClick $i 1"
            } {
                keep -systemIdleOnly -activeClientOnly
            }

            itk_component add off$i {
                DCS::Button $controlSite.off$i \
                -text "Off" \
                -width 11 \
                -command "$this handleClick $i 0"
            } {
                keep -systemIdleOnly -activeClientOnly
            }

            grid $itk_component(l$i) -row 0 -column $i
            grid $itk_component(on$i) -row 1 -column $i
            grid $itk_component(off$i) -row 2 -column $i

            $itk_component(on$i) addInput \
            "$m_objOp status inactive {supporting device}"
            $itk_component(on$i) addInput \
            "$m_objOp permission GRANTED {PERMISSION}"
        }

        pack $itk_component(fr) -expand 1 -fill both

        eval itk_initialize $args
    }
}
body LaserControlWidget::handleClick { bit_no on } {
    if {$bit_no < 0 || $bit_no >= $N_ITEM} {
        log_error "bad bit_no $bit_no in control laser"
        return
    }
    set board   [lindex $BOARD_LIST $bit_no]
    set channel [lindex $CHANNEL_LIST $bit_no]

    if {$m_useNewDaqBoard} {
        $m_objOp startOperation $board $channel $on
    } else {
        set mask [expr 1 << $bit_no]
        set value [expr ($on)?255:0]
        $m_objOp startOperation 0 $value $mask
    }
}
