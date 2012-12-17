### timer service turnOffSampleLight
#######sample light turn off after 30 minutes of system_idle

global gDoorOpened
set gDoorOpened 0

proc turnOffSampleLight_condition { } {
    global gDevice
    global gSampleLightName
    variable ::nScripts::system_idle

    if {[catch {
        set pos [set gDevice($gSampleLightName,scaled)]
    } error]} {
        return 0
    }
    
    if {abs($pos) < 0.001} {
        return 0
    }

    if {$system_idle != ""} {
        return 0
    }
    return 1
}
proc turnOffSampleLight_command { } {
    global gSampleLightBOARD
    global gSampleLightCHANNEL
    if {[catch {
        namespace eval ::nScripts {
            start_recovery_operation setAnalogOut \
            $gSampleLightBOARD $gSampleLightCHANNEL 0.0
        }
    } errMsg]} {
    }
}
set cfgSideLight [::config getStr light.side]
global gSampleLightName
set gSampleLightName ""
if {[llength $cfgSideLight] == 2} {
    global gSampleLightBOARD
    global gSampleLightCHANNEL
    foreach {gSampleLightBOARD gSampleLightCHANNEL} $cfgSideLight break
    set gSampleLightName aoDaq[join $cfgSideLight {}]
    registerTimerService \
    turnOffSampleLight 7200000 $gSampleLightName system_idle
}
#### for energency button to add "motorStopButton" to systemIdle
proc onYellowButtonChange { } {
    #puts "calling onYellowButtonChange"
    if {[catch {
        namespace eval ::nScripts {
            global gDoorOpened

            variable hutchDoorStatus
            variable system_idle

            set doorState [lindex $hutchDoorStatus 0]
            if {$doorState != "closed"} {
                set gDoorOpened 1
            }

            set yellowButtonOn [lindex $hutchDoorStatus 2]

            if {$yellowButtonOn == "1"} {
                #puts "add to systemidle"
                add_to_system_idle motorStopButton 1
            } else {
                #puts "remove from systemidle"
                remove_from_system_idle motorStopButton 1
            }
        }
    } errMsg]} {
        puts "onYellowButtonChange error: $errMsg"
    }
}
#registerEventListener hutchDoorStatus onYellowButtonChange

########################################################################
# monitor robot cassette to reset barcode for cassette
proc onRobotCassetteChange { } {
    if {[catch {
        namespace eval ::nScripts {
            variable robot_cassette
            variable cassette_barcode

            set newV $cassette_barcode

            set now [clock seconds]

            if {[lindex $robot_cassette 0] == "u"} {
                set newV [lreplace $newV 1 1 unknown]
            }
            if {[lindex $robot_cassette 97] == "u"} {
                set newV [lreplace $newV 2 2 unknown]
            }
            if {[lindex $robot_cassette 194] == "u"} {
                set newV [lreplace $newV 3 3 unknown]
            }

            if {$cassette_barcode != $newV} {
                set cassette_barcode $newV
            }
        }
    } errMsg]} {
        puts "onRobotCassetteChange error: $errMsg"
    }
}
registerEventListener robot_cassette onRobotCassetteChange

proc onDoseModeChange { } {
    if {[catch {
        namespace eval ::nScripts {
            variable runs

            foreach {count current_run dose_on} $runs break

            for {set i 0 } {$i <= $count} {incr i} {
                variable run$i

                runDefinitionUpdateTimer run$i [set run$i]
            }
        }
    } errMsg]} {
        puts "onDoseModeChange error: $errMsg"
    }
}
registerEventListener runs onDoseModeChange
