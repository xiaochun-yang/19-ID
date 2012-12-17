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

# provide the DCSEntry package
package provide DCSOperationView 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSOperationManager
package require DCSDeviceLog
package require DCSButton
package require DCSDeviceFactory

#this class let you start any operation with argument and display the 
#update and final results

class DCS::OperationView {
    inherit ::itk::Widget

    itk_option define -controlSystem controlsytem ControlSystem ::dcss
    itk_option define -operation operation Operation "" {
        $itk_component(op_entry) delete 0 end
        if {$itk_option(-operation) != ""} {
            $itk_component(op_entry) insert 0 $itk_option(-operation)
        }
    }
    itk_option define -editable editable Editable 1 {
        set value $itk_option(-editable)
        if {$value != $m_ShowEdit} {
            if {$value} {
                pack $itk_component(op_entry) -side left
            } else {
                pack forget $itk_component(op_entry)
            }
            set m_ShowEdit $value
        }
    }
    itk_option define -badletter badletter BadLetter ""

    public method validate { newletter } {
        if {$itk_option(-badletter) == "" } {
            return 1
        } else {
            set ee \[$itk_option(-badletter)\]
            return [expr ![regexp  $ee $newletter]]
        }
    }

    public method start { } {
        set opList [eval list [$itk_component(op_entry) get] ]
        set opName [lindex $opList 0]
        set opArg [lrange $opList 1 end]

        set opName [trim $opName]

        if {$opName == ""} {
            set opObj ""
        } else {
            set opObj [$m_deviceFactory createOperation $opName]
        }

        if {$opObj != $m_OpObj} {
            if {$m_OpObj != ""} {
                $itk_component(start) deleteInput "$m_OpObj status"
            }

            $itk_component(log) unregisterAll

            if {$opObj != ""} {
                $itk_component(start) addInput "$opObj status inactive {supporting device}"
                $itk_component(log) addDeviceObjs $opObj
            }
            set m_OpObj $opObj
        }

        #start the operation
        if {[$itk_component(cx) get 0]} {
            $itk_component(log) clear
        }
        if {$m_OpObj != ""} {
            set opHandle [eval $m_OpObj startOperation $opArg]
            if {$opHandle != ""} {
                $itk_component(log) configure -operationID $opHandle
            }
        }
    }

    private variable m_OpObj ""
    private variable m_ShowEdit 1

    private variable m_deviceFactory

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        itk_component add ring {
            frame $itk_interior.r
        }

        itk_component add cmd_frame {
            frame $itk_component(ring).cmd_f
        } {
        }

        itk_component add start {
            DCS::Button $itk_component(cmd_frame).start \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -text "start" \
            -command "$this start"
        } {
        }

        itk_component add cx {
            iwidgets::checkbox $itk_component(ring).cx
        } {
        }

        $itk_component(cx) add b0 -text "clear log for each operation"
        itk_component add op_entry {
            entry $itk_component(cmd_frame).op_e \
            -validate key \
            -vcmd "$this validate %S" \
            -width 60 \
            -justify left
        } {
        }

        itk_component add log {
            DCS::DeviceLog $itk_component(ring).l -logStyle operation_id
        } {
        }


        pack $itk_component(start) -side left
        pack $itk_component(op_entry) -side left
        pack $itk_component(cmd_frame)
        pack $itk_component(cx)
        pack $itk_component(log) -expand 1 -fill both
        pack $itk_component(ring) -expand 1 -fill both
        pack $itk_interior -expand 1 -fill both

        eval itk_initialize $args
    }
    destructor {
    }
}

