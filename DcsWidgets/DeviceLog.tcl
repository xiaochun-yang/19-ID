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
package provide DCSDeviceLog 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSOperationManager
package require DCSDeviceFactory

class DCS::DeviceLog {
 	inherit ::itk::Widget

	itk_option define -controlSystem controlsytem ControlSystem ::dcss
	itk_option define -enableClear enableClear EnableClear 1

    #logStyle: 
    #          all:                 everything received
    #          operation_id:        only operation match the id
    #          all_during_operation:log all during that operation 
	itk_option define -logStyle logStyle LogStyle "all"
	itk_option define -operationID  operationID OperationID ""
    # after the operation started with match ID, log all events
    # until the operation completed

    private variable m_LogSenders {}
    private variable m_DeviceObjs {}
    private variable m_ControllerObjs {}
    private variable m_ShowMessage 1

    #remember whether we got all the controllers
    #if not, we will re-get and register them when clientState
    #becomes not offline
    private variable m_AllControllersDone 1
    private variable m_Offline 0

    private method unregisterOneDeviceObj
    private method unregisterDeviceObjs
    private method unregisterControllerObjs
    private method unregisterLogSenders

    public  method addDeviceObjs
    public  method addDevices
    public  method addOperations
    public  method addStrings
    public  method addShutters
    public  method addMotors
    public  method addLogSenders

    #these remove will not remove the controller behind it
    public  method removeDeviceObjs
    public  method removeDevices
    public  method removeLogSenders

    public  method clear { } {
        $itk_component(log) clear
    }

    public  method unregisterAll

    public method handleOperationEvent
    public method handleStringEvent
    public method handleShutterEvent
    public method handleMotorEvent
    public method handleControllerEvent
    public method handleClientStateEvent
    public method handleLogMessageEvent
    private variable m_deviceFactory

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        itk_component add ring {
            frame $itk_interior.r
        }

        itk_component add log {
            DCS::scrolledLog $itk_component(ring).lll
        } {
            keep -background -relief -width
        }

        itk_component add clear_log {
            button $itk_component(ring).c -text "Clear Log" \
            -command "$itk_component(log) clear"
        } {
        }

        pack $itk_component(clear_log)
        pack $itk_component(log) -expand 1 -fill both
        pack $itk_component(ring) -expand 1 -fill both
        eval itk_initialize $args

        $itk_option(-controlSystem) register $this clientState \
        handleClientStateEvent
    }
    destructor {
        unregisterAll
        $itk_option(-controlSystem) unregister $this clientState handleClientStateEvent
    }
}

body DCS::DeviceLog::unregisterOneDeviceObj { devObj } {
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

body DCS::DeviceLog::unregisterDeviceObjs {} {
    #puts "unregister device obj"
    foreach devObj $m_DeviceObjs {
        unregisterOneDeviceObj $devObj
    }
    set m_DeviceObjs {}
}

body DCS::DeviceLog::unregisterControllerObjs {} {
    foreach devObj $m_ControllerObjs {
        #puts "unregister controller $devObj"
        $devObj unregister $this status handleControllerEvent
    }
    set m_ControllerObjs {}
}
body DCS::DeviceLog::addOperations { args } {
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
body DCS::DeviceLog::addLogSenders { args } {
    puts "add logSensers $args"
    if { $args == {} } return

    foreach sender $args {
        if {[lsearch $m_LogSenders $sender] == -1} {
            $itk_option(-controlSystem) registerForLogMessage $sender "$this handleLogMessageEvent"
            lappend m_LogSenders $sender
        }
    }
}
body DCS::DeviceLog::removeLogSenders { args } {
    puts "remove logSensers $args"
    if { $args == {} } return

    foreach sender $args {
        set  index [lsearch $m_LogSenders $sender]
        if {$index != -1} {
            $itk_option(-controlSystem) unregisterForLogMessage $sender "$this handleLogMessageEvent"
            set m_LogSenders [lreplace $m_LogSenders $index $index]
        }
    }
}
body DCS::DeviceLog::unregisterLogSenders { } {
    foreach sender $m_LogSenders {
            $itk_option(-controlSystem) unregisterForLogMessage $sender "$this handleLogMessageEvent"
    }
    set m_LogSenders {}
}
body DCS::DeviceLog::addStrings { args } {
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
body DCS::DeviceLog::addShutters { args } {
    puts "add Shutters $args"
    if { $args == {} } return

    #generate deviceObj list to call addDeviceObjs
    set devObjList {}
    foreach item $args {
        set opObj [$m_deviceFactory createShutter $item]
        #puts "append $opObj"
        if { $opObj != "" } {
            lappend devObjList $opObj
        }
    }
    #call addDeviceObjs
    eval addDeviceObjs $devObjList
}
body DCS::DeviceLog::addDevices { args } {
    puts "add Devices $args"
    if { $args == {} } return

    #generate deviceObj list to call addDeviceObjs
    set devObjList {}
    foreach item $args {
        set opObj [$m_deviceFactory getObjectName $item]
        #puts "append $opObj"
        if { $opObj != "" } {
            lappend devObjList $opObj
        }
    }
    #call addDeviceObjs
    eval addDeviceObjs $devObjList
}
body DCS::DeviceLog::addMotors { args } {
    eval addDevices $args
}

body DCS::DeviceLog::removeDevices { args } {
    puts "remove devices $args"
    if { $args == {} } return

    foreach device $args {
        set devObj [$m_deviceFactory getObjectName $device]
        #puts "append $opObj"
        if { $devObj != "" } {
            set index [lsearch -exact $m_DeviceObjs $devObj]

            if {$index >= 0} {
                unregisterOneDeviceObj $devObj
                set m_DeviceObjs [lreplace $m_DeviceObjs $index $index]
            }
        }
    }
}

body DCS::DeviceLog::unregisterAll { } {
    unregisterDeviceObjs
    unregisterControllerObjs
    unregisterLogSenders
    set m_AllControllersDone 1
}
body DCS::DeviceLog::addDeviceObjs { args } {
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
body DCS::DeviceLog::handleOperationEvent { message_ } {
    #puts "operation event $message_"

    set eventType [lindex $message_ 0]
    set operationName [lindex $message_ 1]
    set operationID [lindex $message_ 2]
    if { [llength $message_] > 3 } {
        set operationArgs [lrange $message_ 3 end]
    } else {
        set operationArgs {}
    }

    if {$operationID != $itk_option(-operationID)} {
        if { ! $m_ShowMessage } return
    }
    switch $eventType {
        stog_start_operation {
            $itk_component(log) log_string \
            "STARTED: $operationName $operationID $operationArgs" note
            if { $itk_option(-logStyle) == "all_during_operation" } {
                if { ! $m_ShowMessage } {
                    #puts "turn on show message"
                    set m_ShowMessage 1
                }
            }
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
                $itk_component(log) log_string \
                "COMPLETED: $operationName $operationID $operationArgs" note
            } else {
                $itk_component(log) log_string \
                "COMPLETED: $operationName $operationID $operationArgs" error
            }
            if {$operationID == $itk_option(-operationID) && $itk_option(-logStyle) == "all_during_operation" } {
                #puts "turn off show message"
                set m_ShowMessage 0
            }
        }
        stog_operation_update {
            if {[string match -nocase "*warn*" $operationArgs]} {
                set color warning
            } elseif {[string match -nocase "*error*" $operationArgs]} {
                set color error
            } else {
                set color note
            }
            $itk_component(log) log_string \
            "UPDATE: $operationName $operationID $operationArgs" $color
        }
        default {
            return -code error \
            "Should not have received this message: $_message"
        }
    }
    #puts "end of event handle in RobotCalibration"
}
body DCS::DeviceLog::handleStringEvent { name_ ready_ alias_ contents_ - } {
    #puts "string event $name_ $ready_ $alias_ $contents_"
    #puts "m_ShowMessage=$m_ShowMessage"
    if {!$m_ShowMessage} return
    if {!$ready_} return

    set name_ [$name_ cget -deviceName]

    $itk_component(log) log_string \
    "STRING: $name_ changed to {$contents_}" note
}
body DCS::DeviceLog::handleMotorEvent { name_ ready_ alias_ contents_ - } {
    #puts "MotorEvent: $name_ $ready_ $alias_ $contents_"
    if {$m_ShowMessage != 1} return
    if {!$ready_} return

    set name_ [$name_ cget -deviceName]

    $itk_component(log) log_string \
    "MOTOR: $name_ moved to $contents_" note
}
body DCS::DeviceLog::handleShutterEvent { name_ ready_ alias_ contents_ - } {
    #puts "ShutterEvent: $name_ $ready_ $alias_ $contents_"
    if {!$m_ShowMessage} return
    if {!$ready_} return

    set name_ [$name_ cget -deviceName]

    $itk_component(log) log_string \
    "SHUTTER: $name_ $contents_" note
}
body DCS::DeviceLog::handleControllerEvent { name_ ready_ alias_ contents_ - } {
    #puts "ControllerEvent: $name_ $ready_ $alias_ $contents_"
    #puts "m_ShowMessage=$m_ShowMessage"
    if { ! $m_ShowMessage } return
    if {!$ready_} return

    set name_ [$name_ cget -controller]

    if {$contents_ == "offline"} {
        $itk_component(log) log_string \
        "CONTROLLER: $name_ $contents_" error
    } else {
        $itk_component(log) log_string \
        "CONTROLLER: $name_ $contents_" note
    }
}

body DCS::DeviceLog::handleClientStateEvent { name_ ready_ alias_ contents_ - } {
    #puts "ClientStateEvent: $name_ $ready_ $alias_ $contents_"
    if { !$ready_ } return

    if { $contents_ == "offline" } {
        if { !$m_Offline } {
            $itk_component(log) log_string "$name_ offline" error
            set m_Offline 1
        }
        return
    } else {
        if { $m_Offline } {
            $itk_component(log) log_string "$name_ online" note
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
body DCS::DeviceLog::handleLogMessageEvent { message_ } {
    puts "handleLogMessageEvent $message_"
    foreach {command arg1 arg2 arg3} $message_ {break}
    switch -exact -- $arg1 {
        note -
        warning -
        error {
            $itk_component(log) log_string "$arg2 reports: [lrange $message_ 3 end]" $arg1
        }
        default {
            $itk_component(log) log_string "$arg2 reports: [lrange $message_ 3 end]" error
        }
    }
}

configbody DCS::DeviceLog::enableClear {
    if {$itk_option(-enableClear) } {
        $itk_component(clear_log) configure -state normal
    } else {
        $itk_component(clear_log) configure -state disabled
    }
}
configbody DCS::DeviceLog::logStyle {
    switch -exact -- $itk_option(-logStyle) {
        all {
            set m_ShowMessage 1
        }
        operation_id -
        all_during_operation {
            set m_ShowMessage 0
        }
    }
}
