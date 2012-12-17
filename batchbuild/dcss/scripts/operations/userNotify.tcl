proc userNotify_initialize { } {
    ### get mapping from config
    variable user_notify_name_mapping
    variable userNotify_previousValue

    ::config getRange userNotify.operation_list list4User
    ::config getRange staffNotify.operation_list list4Staff

    set notifyList [concat $list4User $list4Staff]

    foreach line $notifyList {
        set name [lindex $line 0]
        set contents [lrange $line 1 end]

        foreach device $contents {
            set user_notify_name_mapping($device) $name
            puts "userNotify set name for $device to $name"
            if {[isDevice $device]} {
                set userNotify_previousValue($device) \
                [userNotify_getDeviceCurrentValue $device]
    
                registerEventListener $device \
                [list ::nScripts::userNotify_onDeviceChange $device]
            }
        }
    }
    userNotify_registerEvent
}
proc userNotify_start { cmd args } {

    switch -exact $cmd {
        "clear_user" {
            userNotify_clearList
        }
        "clear_setup" {
            userNotify_clearSetup
        }
        "clear_all" {
            userNotify_clearList
            userNotify_clearSetup
        }
        "list" {
            send_operation_update ==================SET UP================
            userNotify_listSetup
            send_operation_update ==================EMAIL=================
            userNotify_listList
            send_operation_update ========================================
        }
        "test" {
            log_warning sending out user notify test message
            userNotify_notify TEST: Your email has been added for notification.
        }
        "setup" {
            variable user_notify_setup
            variable user_notify_list

            set newList [lindex $args 0]
            set newList [string map {{ } ,} $newList]
            set user_notify_list $newList
            set user_notify_setup [lindex $args 1]
            userNotify_registerEvent
        }
        default {
            send_operation_update error unknown command
        }
    }
}

proc userNotify_registerEvent { } {
    variable user_notify_setup
    variable userNotify_previousValue

    puts "userNotify_registerEvent: {$user_notify_setup}"

    ### it is OK to just register and never unregister
    foreach device $user_notify_setup {
        if {[isDevice $device]} {
            set userNotify_previousValue($device) \
            [userNotify_getDeviceCurrentValue $device]
            registerEventListener $device [list ::nScripts::userNotify_onDeviceChange $device]
        }
    }
}

proc userNotify_getDeviceCurrentValue { device } {
    global gDevice

    switch -exact -- $gDevice($device,type) {
        string {
            set newValue $gDevice($device,contents)
        }
        real_motor -
        pseudo_motor {
            set newValue [getScaledValue $device]
        }
        encoder {
            set newValue $gDevice($device,position)
        }
        shutter {
            set newValue $gDevice($device,state)
        }
        ion_chamber {
            set newValue $gDevice($device,counts)
        }
        hardware_host {
            global gHwHost
            set newValue $gHwHost($device,status)
        }
        default {
            puts \
            "userNotify: unsupported type $gDevice($device,type) for $device"
            return "unknown"
        }
    }
}

proc userNotify_clearSetup { } {
    userNotify_listSetup

    variable user_notify_setup
    variable userNotify_previousValue

    set user_notify_setup ""
    array unset userNotify_previousValue

    log_warning userNotify setup cleared
}

proc userNotify_clearList { } {
    userNotify_listList

    ### may TODO:
    ### send last email saying you have been removed from notify list

    variable user_notify_list
    set user_notify_list ""

    log_warning usreNotify list cleared
}
proc userNotify_listSetup { } {
    variable user_notify_setup
    variable userNotify_previousValue

    set ll [llength $user_notify_setup]

    ### i MAY increase inside the loop too.
    set num 0
    for {set i 0} {$i < $ll} {incr i} {
        set tag [lindex $user_notify_setup $i]
        if {[string is double -strict $tag]} {
            continue
        }
        set runTimeThreshold 0
        set next_i [expr $i + 1]
        set next_tag [lindex $user_notify_setup $next_i]
        if {[string is double -strict $next_tag]} {
            set runTimeThreshold $next_tag

            ##skip this item, it is the time limit
            incr i
        }

        #send_operation_update setup: $tag runTimeThreshold: $runTimeThreshold
        send_operation_update setup: $tag
        incr num
    }
    send_operation_update total notify setup: $num

    if {[array exists userNotify_previousValue]} {
        send_operation_update ==============previous values=============

        set nameList [array names userNotify_previousValue]

        foreach name $nameList {
            send_operation_update previous_value: $name \
            $userNotify_previousValue($name)
        }
        send_operation_update total previous values [llength $nameList]
    }
}
proc userNotify_listList { } {
    variable user_notify_list

    set aList [split $user_notify_list ,]

    foreach adr $user_notify_list {
        send_operation_update notify email: $adr
    }
    send_operation_update total email addresses: [llength $aList]
}

proc userNotify_notify { args } {
    variable user_notify_list

    ###log_severe USER_NOTIFY $args

    if {![isString user_notify_list]} {
        return
    }
    if {$user_notify_list == ""} {
        return
    }

    set message [join $args]
    set timeStamp [clock format [clock seconds] -format "%d %b %Y %X"]
    set contents "$timeStamp $message"
    set subject "[::config getConfigRootName] Notify"

    set token [::mime::initialize -canonical text/plain -string $contents]
    ::mime::setheader $token Subject $subject
    ::mime::setheader $token From "SSRL"

    if {[catch {
        puts "sending NOTIFY email to $user_notify_list"
        ::smtp::sendmessage $token -recipients $user_notify_list
    } err]} {
        puts "failed to notify user: $err"
        log_severe failed to notify user: $err
    }
}

proc userNotify_onOperationStart { name handle } {
    ## we changed to ignore the time now.
    ## so, no need to keep the time stamp anymore
    ## the framework is kept in case of future change.
}
proc userNotify_onOperationComplete { operationName operationHandle status args } {
    set displayName [userNotify_getDisplayName $operationName]
    if {$displayName == ""} {
        return
    }

    if {$status == "normal"} {
        userNotify_notify $displayName finished
    } else {
        userNotify_notify $displayName failed $args
    }
}
proc userNotify_getDisplayName { deviceName } {
    variable user_notify_setup
    variable user_notify_name_mapping

    if {![isString user_notify_setup]} {
        #log_warning DEBUG user_notify_setup not string
        return ""
    }

    if {[lsearch -exact $user_notify_setup $deviceName] < 0 && \
    [lsearch -exact $user_notify_setup ANY] < 0} {
        return ""
    }

    ### mapping to Display name if possible
    if {[info exists user_notify_name_mapping($deviceName)]} {
        return $user_notify_name_mapping($deviceName)
    } else {
        return $deviceName
    }
}
proc userNotify_onDeviceChange { deviceName } {
    global gDevice

    variable userNotify_previousValue

    set displayName [userNotify_getDisplayName $deviceName]
    if {$displayName == ""} {
        return
    }

    if {$gDevice($deviceName,type) != "hardware_host" && \
    $gDevice($deviceName,lastResult) != "normal"} {
        userNotify_notify $displayName ERROR $gDevice($deviceName,lastResult)
        return
    }

    set newValue [userNotify_getDeviceCurrentValue $deviceName]

    if {[info exists userNotify_previousValue($deviceName)] && \
    $userNotify_previousValue($deviceName) == $newValue} {
        ## no change
        return
    }

    ### now new value, notify user
    set userNotify_previousValue($deviceName) $newValue

    switch -exact -- $gDevice($deviceName,type) {
        string {
            userNotify_notify \
            $displayName changed to $newValue
        }
        real_motor -
        pseudo_motor {
            userNotify_notify \
            $displayName moved to $newValue $gDevice($deviceName,scaledUnits)
        }
        encoder {
            userNotify_notify $displayName changed to $newValue
        }
        shutter {
            userNotify_notify $displayName changed to $newValue
        }
        ion_chamber {
            userNotify_notify ion chamber $displayName  reading $newValue
        }
        hardware_host {
            global gHwHost
            userNotify_notify hardware_host $displayName $newValue
        }
    }
}
