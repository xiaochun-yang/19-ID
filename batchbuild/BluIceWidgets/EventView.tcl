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

package provide BLUICEEventView 1.0

# load standard packages
package require Iwidgets
#package require BWidget 1.2.1

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

package require DCSProtocol
package require DCSOperationManager
package require DCSDeviceLog
package require DCSDeviceFactory

class EventViewWidget {
     inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    protected variable m_deviceFactory

    private variable m_OperationList {}
    private variable m_StringList {}
    private variable m_ShutterList {}
    #private variable m_SignalList {}
    private variable m_MotorList {}
    
    public method handleClick

    private method RefreshLists { } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_OperationList [$m_deviceFactory getOperationList]
        set m_StringList [$m_deviceFactory getStringList]
        set m_ShutterList [$m_deviceFactory getShutterList]
        set m_MotorList [$m_deviceFactory getMotorList]

        puts "total op [llength $m_OperationList]"
        set bn 0
        foreach item $m_OperationList {
            $itk_component(operations) add b$bn \
            -text "$item" \
            -command "$this handleClick $itk_component(operations) $bn $item"
            incr bn
        }
        puts "total string [llength $m_StringList]"
        set bn 0
        foreach item $m_StringList {
            $itk_component(strings) add b$bn \
            -text "$item" \
            -command "$this handleClick $itk_component(strings) $bn $item"
            incr bn
        }
        puts "total shutter [llength $m_ShutterList]"
        set bn 0
        foreach item $m_ShutterList {
            $itk_component(shutters) add b$bn \
            -text "$item" \
            -command "$this handleClick $itk_component(shutters) $bn $item"
            incr bn
        }
        puts "total motor [llength $m_MotorList]"
        set bn 0
        foreach item $m_MotorList {
            $itk_component(motors) add b$bn \
            -text "$item" \
            -command "$this handleClick $itk_component(motors) $bn $item"
            incr bn
        }
    }

    #contructor/destructor
    constructor { args  } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        itk_component add top_nb {
            iwidgets::Tabnotebook $itk_interior.nb -tabpos n -height 400
        } {
        }
        set SelectionSite [$itk_component(top_nb) add -label "Selection"]
        set LogSite [$itk_component(top_nb) add -label "Event Log"]

        itk_component add log {
        DCS::DeviceLog $LogSite.log -logStyle all
        } {
        }

        itk_component add slct_nb {
            iwidgets::Tabnotebook $SelectionSite.nb -tabpos n
        } {
        }
        set OperationTab [$itk_component(slct_nb) add -label "Operation"]
        set StringTab [$itk_component(slct_nb) add -label "String"]
        set ShutterTab [$itk_component(slct_nb) add -label "Shutter"]
        set MotorTab [$itk_component(slct_nb) add -label "Motor"]

        itk_component add sc_op {
            iwidgets::scrolledframe $OperationTab.scf \
            -vscrollmode static
        } {
        }
        itk_component add sc_st {
            iwidgets::scrolledframe $StringTab.scf \
            -vscrollmode static
        } {
        }
        itk_component add sc_sh {
            iwidgets::scrolledframe $ShutterTab.scf \
            -vscrollmode static
        } {
        }
        itk_component add sc_mt {
            iwidgets::scrolledframe $MotorTab.scf \
            -vscrollmode static
        } {
        }
        set OperationSite [$itk_component(sc_op) childsite]
        set StringSite [$itk_component(sc_st) childsite]
        set ShutterSite [$itk_component(sc_sh) childsite]
        set MotorSite [$itk_component(sc_mt) childsite]

        itk_component add operations {
            iwidgets::checkbox $OperationSite.cb
        } {
        }
        itk_component add strings {
            iwidgets::checkbox $StringSite.cb
        } {
        }
        itk_component add shutters {
            iwidgets::checkbox $ShutterSite.cb
        } {
        }
        itk_component add motors {
            iwidgets::checkbox $MotorSite.cb
        } {
        }
        RefreshLists

        pack $itk_component(operations) -expand 1 -fill both
        pack $itk_component(strings) -expand 1 -fill both
        pack $itk_component(shutters) -expand 1 -fill both
        pack $itk_component(motors) -expand 1 -fill both

        pack $itk_component(log) -expand 1 -fill both

        pack $itk_component(sc_op) -expand 1 -fill both
        pack $itk_component(sc_st) -expand 1 -fill both
        pack $itk_component(sc_sh) -expand 1 -fill both
        pack $itk_component(sc_mt) -expand 1 -fill both

        pack $itk_component(slct_nb) -expand 1 -fill both
        pack $itk_component(top_nb) -expand 1 -fill both


        $itk_component(top_nb) view 0
        $itk_component(slct_nb) view 0

        eval itk_initialize $args
    }
    destructor {
    }
}

body EventViewWidget::handleClick { check_box index name } {
    set value [$check_box get $index]

    if {$value} {
        $itk_component(log) addDevices $name
    } else {
        $itk_component(log) removeDevices $name
    }
}
