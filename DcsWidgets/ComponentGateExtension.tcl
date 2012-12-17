package provide ComponentGateExtension 1.0
package require DCSComponent
class DCS::ComponentGateExtension {
    inherit ::itk::Widget ::DCS::ComponentGate
    itk_option define -controlSystem controlsytem ControlSystem ::dcss
    itk_option define -activeClientOnly activeClientOnly ActiveClientOnly 1
    itk_option define -systemIdleOnly systemIdleOnly SystemIdleOnly 1
    #public methods
    public method registerComponent { args }
    public method unregisterComponent {}
    public method updateBubble {}
    public method handleNewOutput {}


    #private variables
    private variable listOfComponents ""
    constructor { args } {
        eval itk_initialize $args
    }
}
body DCS::ComponentGateExtension::registerComponent { args } {
    foreach component $args {
        if {[lsearch $listOfComponents $component] < 0} {
            lappend listOfComponents $component
        }
    }
}
body DCS::ComponentGateExtension::unregisterComponent {} {
    set listOfComponents ""
}
#Update the help message
body ::DCS::ComponentGateExtension::updateBubble {} {
    #delete the help balloon
    catch {wm withdraw .help_shell}
    set message "this blu-ice has a bug"
    set outputMessage [getOutputMessage]
    foreach {output blocker status reason} $outputMessage {break}
    foreach {object attribute} [split $blocker ~] break
    if { ! $_onlineStatus } {
        set message $reason
    } elseif { $output } {
        #the widget is enabled
        set message ""
	} elseif {$reason == "PERMISSION" } {
        set message [$object getPermissionMessage]
	} elseif { $object == "::device::system_idle"} {
		set message "System not idle: $status"
    } else {
        #set deviceStatus $itk_option(-device).status
        #the widget is disabled
        if {$reason == "supporting device" } {
            #something is happening with the device we are interested in.
            switch $status {
                inactive {
                    set message "Device is ready to move."
                }
                moving {
                    set message "[namespace tail $object] is moving."
                }
                offline  {
                    set message "DHS '[$object cget -controller]' is offline (needed for [namespace tail $object])."
                }
				locked  {
					set message "[namespace tail $object] is locked."
				}
                not_connected {
					set message "not connected"
                }
                default {
                    set message "[namespace tail $object] is not ready: $status"
                }
            }
        } else {
            #unhandled reason, use default reason specified with addInput
            set message "$reason"
        }
    }
    foreach component $listOfComponents {
        DynamicHelp::register $component balloon $message
    }
}
body DCS::ComponentGateExtension::handleNewOutput {} {
    foreach component $listOfComponents {
        if { $_gateOutput == 1} {
            $component configure -state normal
        } else {
            $component configure -state disabled
        }
    }
    updateBubble
}
configbody ::DCS::ComponentGateExtension::activeClientOnly {
    if {$itk_option(-activeClientOnly) } {
        addInput "::$itk_option(-controlSystem) clientState active {This Blu-Ice is passive. Become active.}"
    } else {
        deleteInput "::$itk_option(-controlSystem) clientState"
    }
}

configbody ::DCS::ComponentGateExtension::systemIdleOnly {
    set deviceFactory [DCS::DeviceFactory::getObject]
    set systemIdle [$deviceFactory createString system_idle]
    if {$itk_option(-systemIdleOnly) } {
        addInput "$systemIdle contents {} {supporting device}"
    } else {
        deleteInput "$systemIdle contents"
    }
}
