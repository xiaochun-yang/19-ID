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
package provide DCSMessageBoard 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSOperationManager
package require DCSDeviceFactory

###############3NEED create base class with MessageBoard#######3

class DCS::MessageBoard {
 	inherit ::itk::Widget

	itk_option define -controlSystem controlsytem ControlSystem ::dcss
    itk_option define -foreground foreground Foreground black

    private variable m_DeviceObjs {}
    private variable m_ControllerObjs {}

    #remember whether we got all the controllers
    #if not, we will re-get and register them when clientState
    #becomes not offline
    private variable m_AllControllersDone 1
    private variable m_Offline 0

    private method unregisterDeviceObjs
    private method unregisterControllerObjs

    public  method addDeviceObjs
    public  method addOperations
    public  method addStrings

    public  method clear { } {
        $itk_component(label) config -text {}
    }

    public  method unregisterAll

    public method handleOperationEvent
    public method handleStringEvent
    public method handleShutterEvent
    public method handleMotorEvent
    public method handleControllerEvent
    public method handleClientStateEvent
    private variable m_deviceFactory

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        itk_component add ring {
            frame $itk_interior.r
        }

        itk_component add label {
            label $itk_component(ring).lll -relief sunken -anchor w
        } {
            usual
            keep -width -background
            ignore -text
        }

        pack $itk_component(label) -expand 1 -fill x
        pack $itk_component(ring) -expand 1 -fill x
        eval itk_initialize $args

        $itk_option(-controlSystem) register $this clientState \
        handleClientStateEvent
    }
    destructor {
        unregisterAll
        $itk_option(-controlSystem) unregister $this clientState handleClientStateEvent
    }
}

body DCS::MessageBoard::unregisterDeviceObjs {} {
    #puts "unregister device obj"
    foreach devObj $m_DeviceObjs {
        if {[$devObj isa DCS::Operation]} {
            $devObj unRegisterForAllEvents $this handleOperationEvent
        } elseif {[$devObj isa DCS::Motor]} {
            $devObj unregister $this scaledPosition handleMotorEvent
        } elseif {[$devObj isa DCS::Shutter]} {
            $devObj unregister $this state handleShutterEvent
        } elseif {[$devObj isa DCS::String]} {
            $devObj unregister $this contents handleStringEvent
        }
    }
    set m_DeviceObjs {}
}
body DCS::MessageBoard::unregisterControllerObjs {} {
    foreach devObj $m_ControllerObjs {
        #puts "unregister controller $devObj"
        $devObj unregister $this status handleControllerEvent
    }
    set m_ControllerObjs {}
}
body DCS::MessageBoard::addOperations { args } {
    #puts "add operations $args"
    if { $args == {} } return

    #generate deviceObj list to call addDeviceObjs
    set devObjList {}
    foreach operation $args {
        set opObj [$m_deviceFactory createOperation $operation]
        #puts "append $opObj"
        if { $opObj != "" } {
            lappend devObjList $opObj
        }
    }
    #call addDeviceObjs
    #puts "devObj list $devObjList"
    eval addDeviceObjs $devObjList
}
body DCS::MessageBoard::addStrings { args } {
    #puts "add strings $args"
    if { $args == {} } return

    #generate deviceObj list to call addDeviceObjs
    set devObjList {}
    foreach dcs_string $args {
        set opObj [$m_deviceFactory createString $dcs_string]
        #puts "append $opObj"
        if { $opObj != "" } {
            lappend devObjList $opObj
        }
    }
    #call addDeviceObjs
    eval addDeviceObjs $devObjList
}
body DCS::MessageBoard::unregisterAll { } {
    unregisterDeviceObjs
    unregisterControllerObjs
    set m_AllControllersDone 1
}
body DCS::MessageBoard::addDeviceObjs { args } {
    #puts "add device obj $args"
    if {$args == {} } return
    foreach devObj $args {
        #puts "adding $devObj"
        if {[lsearch -exact $m_DeviceObjs $devObj] == -1} {
            if {[$devObj isa DCS::Operation]} {
                $devObj registerForAllEvents $this handleOperationEvent
            } elseif {[$devObj isa DCS::Motor]} {
                $devObj register $this scaledPosition handleMotorEvent
            } elseif {[$devObj isa DCS::Shutter]} {
                $devObj register $this state handleShutterEvent
            } elseif {[$devObj isa DCS::String]} {
                $devObj register $this contents handleStringEvent
            }
            lappend m_DeviceObjs $devObj
            set controller [$devObj cget -controller]
            if { $controller != "" } {
                set ctlObj [$m_deviceFactory getObjectName $controller]
                #puts "adding controller $ctlObj"
                if {[lsearch -exact $m_ControllerObjs $ctlObj] == -1} {
                    $ctlObj register $this status handleControllerEvent
                    lappend m_ControllerObjs $ctlObj
                }
            } else {
                set m_AllControllersDone 0
            }

        }
    }
}
body DCS::MessageBoard::handleOperationEvent { message_ } {
    #puts "operation event $message_"

    set eventType [lindex $message_ 0]
    set operationName [lindex $message_ 1]
    set operationID [lindex $message_ 2]
    if { [llength $message_] > 3 } {
        set operationArgs [lrange $message_ 3 end]
    } else {
        set operationArgs {}
    }

    switch $eventType {
        stog_start_operation {
            $itk_component(label) configure \
            -foreground $itk_option(-foreground) \
            -text "STARTED: $operationName $operationID $operationArgs"
        }

        stog_operation_completed {
            set result [lindex $operationArgs 0]
            if {$result == "normal" \
            && $operationName == "ISampleMountingDevice" } {
                if { [llength $operationArgs] > 1 } { 
                    set result [lindex $operationArgs 1]
                }
            }
            if {$result == "normal"} {
                $itk_component(label) config \
                -foreground $itk_option(-foreground) \
                -text \
                "COMPLETED: $operationName $operationID $operationArgs"
            } else {
                $itk_component(label) config \
                -foreground red \
                -text \
                "COMPLETED: $operationName $operationID $operationArgs"
            }
        }
        stog_operation_update {
            if {[string match -nocase *error* "$operationArgs"] || \
                [string match -nocase *fail* "$operationArgs"] || \
                [string match -nocase *warn* "$operationArgs"]} {
                $itk_component(label) config \
                -foreground red \
                -text \
                "UPDATE: $operationName $operationID $operationArgs"
            } else {
                $itk_component(label) config \
                -foreground $itk_option(-foreground) \
                -text \
                "UPDATE: $operationName $operationID $operationArgs"
            }
        }
        default {
            return -code error \
            "Should not have received this message: $_message"
        }
    }
    #puts "end of event handle in RobotCalibration"
}
body DCS::MessageBoard::handleStringEvent { name_ ready_ alias_ contents_ - } {
    #puts "string event $name_ $ready_ $alias_ $contents_"
    if {!$ready_} return

    if {[string match -nocase *error* "$contents_"] || \
        [string match -nocase *fail* "$contents_"] || \
        [string match -nocase *abort* "$contents_"] || \
        [string match -nocase *warn* "$contents_"]} {
        $itk_component(label) config \
        -foreground red \
        -text "$contents_"
    } else {
        $itk_component(label) config \
        -foreground $itk_option(-foreground) \
        -text "$contents_"
    }
}
body DCS::MessageBoard::handleMotorEvent { name_ ready_ alias_ contents_ - } {
    #puts "MotorEvent: $name_ $ready_ $alias_ $contents_"
    if {!$ready_} return

    set name_ [$name_ cget -deviceName]

    $itk_component(label) config \
    -foreground $itk_option(-foreground) \
    -text "$name_ moved to $contents_"
}
body DCS::MessageBoard::handleShutterEvent { name_ ready_ alias_ contents_ - } {
    #puts "ShutterEvent: $name_ $ready_ $alias_ $contents_"
    if {!$ready_} return

    set name_ [$name_ cget -deviceName]

    $itk_component(label) config \
    -foreground $itk_option(-foreground) \
    -text "$name_ $contents_"
}
body DCS::MessageBoard::handleControllerEvent { name_ ready_ alias_ contents_ - } {
    #puts "ControllerEvent: $name_ $ready_ $alias_ $contents_"
    if {!$ready_} return

    set name_ [$name_ cget -controller]

    if {$contents_ == "offline"} {
        $itk_component(label) config \
        -foreground red \
        -text "$name_ $contents_"
    }
}

body DCS::MessageBoard::handleClientStateEvent { name_ ready_ alias_ contents_ - } {
    #puts "ClientStateEvent: $name_ $ready_ $alias_ $contents_"
    if { !$ready_ } return

    set name_ [namespace tail $name_]

    if { $contents_ == "offline" } {
        if { !$m_Offline } {
            $itk_component(label) config \
            -foreground red \
            -text "$name_ $contents_"
        }
        return
    } else {
        if { $m_Offline } {
            $itk_component(label) config \
            -foreground red \
            -text "$name_ online"
            set m_Offline 0
        }
    }

    if { $m_AllControllersDone } return

    #re-create controller list
    #puts "re-generate controllers list"
    unregisterControllerObjs
    foreach devObj $m_DeviceObjs {
        set controller [$devObj cget -controller]
        if { $controller != "" } {
            set ctlObj [$m_deviceFactory getObjectName $controller]
            #puts "adding controller $ctlObj"
            if {[lsearch -exact $m_ControllerObjs $ctlObj] == -1} {
                $ctlObj register $this status handleControllerEvent
                lappend m_ControllerObjs $ctlObj
            }
        } else {
            return
        }
    }
    #OK reach here, we registered all controllers
    set m_AllControllersDone 1
}

