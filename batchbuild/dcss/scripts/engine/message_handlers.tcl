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

package require mime
package require smtp

set gSiblingsMoving 0
set gClientId 0
set gShutterMap [list {} {} {} {} {} {} {} {}]

proc isFloat { string } {
    return [expr ![catch {format %f $string} dummy]]
}

proc getPrefixFrom_ { name times } {
    set markP end

    for {set i 0} {$i < $times} {incr i} {
        set markP [string last _ $name $markP]
        if {$markP < 1} {
            return ""
        }
        incr markP -1
    }

    set prefix [string range $name 0 $markP]
    return $prefix
}

########################
# "no_hw_host_" is used as prefix to flag it is hardware host offline,
# if you want to change it, search the whole file for it.
########################
proc stog_configure_hardware_host { hardwareHost hardwareComputer status args} {
    global gDevice
    global gOutstandingOperations${hardwareHost}

    global gHwHost

    set gDevice($hardwareHost,type) hardware_host
    set gHwHost($hardwareHost,status) $status
    
    # If an hardware host goes offline, clean up any outsanding operations that the hardware host was working on.
    if { $status  == "offline" } {
        if {[dcss2 cget -_connectionGood]} {
            dcss2 sendMessage "htos_log severe $hardwareHost $hardwareHost offline"
        }
        if { [info exists gOutstandingOperations${hardwareHost}] } {
            set outstandingOperations [get_set gOutstandingOperations${hardwareHost}]
            
            print "$hardwareHost offline cleaning up: $outstandingOperations"
            
            #send the completed message for all the active operations for the disconnected hardware server
            foreach operation $outstandingOperations {
                set operationName [lindex $operation 0]
                set operationHandle [lindex $operation 1]
                dcss2 sendMessage "htos_operation_completed $operationName $operationHandle no_hw_host_$hardwareHost"
            }
        } else {
            print "$hardwareHost host did not have outstanding operation."
        }

        #flag all devices to offline
        if {[info exists gDevice($hardwareHost,deviceList)] } {
            set outstandingDevices [get_set gDevice($hardwareHost,deviceList)]
            print "$hardwareHost offline cleaning up: $outstandingDevices"
            #send the completed message for all devices
            set outstandingIonChambers ""
            foreach device $outstandingDevices {
                switch -exact -- $gDevice($device,type) {
                    real_motor -
                    pseudo_motor {
                        dcss2 sendMessage "htos_motor_move_completed $device $gDevice($device,scaled) no_hw_host_$hardwareHost"
                    }
                    ion_chamber {
                        lappend outstandingIonChambers $device
                    }
                    encoder {
                        dcss2 sendMessage "htos_get_encoder_completed $device $gDevice($device,position) no_hw_host_$hardwareHost"
                    }
                    shutter {
                        dcss2 sendMessage "htos_report_shutter_state $device $gDevice($device,state) no_hw_host_$hardwareHost"
                    }
                    string {
                        dcss2 sendMessage "htos_set_string_completed $device no_hw_host_$hardwareHost $gDevice($device,contents)"
                    }
                }
            }
            if {[llength $outstandingIonChambers] > 0} {
                set outMsg "htos_report_ion_chambers 0"
                eval lappend outMsg $outstandingIonChambers
                lappend outMsg no_hw_host_$hardwareHost
                dcss2 sendMessage $outMsg
            }
        } else {
            print "$hardwareHost host did not have device."
        }
    }
    updateEventListeners $hardwareHost
}

proc stog_configure_operation {operationName hardwareHost args} {
    global gOperation
    global gDevice

    set gOperation($operationName,hardwareHost) $hardwareHost
    set gOperation($operationName,stopFlag) 0

    ###for monitoring operations
    if { ! [info exists gDevice($operationName,observers) ] } {
        set gDevice($operationName,observers) ""
    }
    set gDevice($operationName,result) "not_called_yet"
    set gDevice($operationName,timeStamp) 0
}

proc stog_admin { args } {}
proc stog_load_image { args } {}
proc stog_exposure_started { args } {}
proc stog_readout_started { args } {}
proc stog_collect_stopped {} {
    if {[isString detector_status]} {
        variable ::nScripts::detector_status

        set detector_status "Detector Idle"
    }
}
proc stog_collect_started {} {}
proc stog_configure_runs { totalRuns currentRun isActive doseMode } {
}
proc stog_update_run { args } {}
proc stog_simulating_device { args } {}
proc stog_no_master {} {}
proc stog_other_master {} {}
proc stog_request_to_become_master {} {}
proc stog_become_master {} {}
proc stog_become_slave {} {}
proc stog_failed_to_store_image { args } {}
proc stog_update_client_list { args } {}
proc stog_set_permission_level { args } {}
proc stoh_set_motor_dependency { args } {}
proc stoh_set_motor_children { args } {}
proc stog_set_motor_dependency { args } {}
proc stog_set_motor_children { args } {}

proc stog_quit { args } { }

proc stog_configure_pseudo_motor { motor hardwareHost hardwareName position \
    upperLimit lowerLimit lowerLimitOn upperLimitOn motorLockOn status } {

    global gDevice
    add_to_set gDevice($hardwareHost,deviceList) $motor

    #self's pseudo motor are createded by stoh_register_xxxxx
    if {$hardwareHost == "self"} return

    set gDevice($motor,hardwareHost) $hardwareHost
        # create the device if not yet defined
        if { ! [info exists gDevice($motor,type)] } {
            print "****create external pseudo motor $motor"
            create_pseudo_motor $motor component mm
        }
        setScaledValue $motor $position
        setUpperLimitFromScaledValue $motor $upperLimit
        setLowerLimitFromScaledValue $motor $lowerLimit
        setLowerLimitEnableValue $motor $lowerLimitOn
        setUpperLimitEnableValue $motor $upperLimitOn
        setLockEnableValue $motor $motorLockOn

    updateEventListeners $motor
    ####enable this after testing of event listeners first
    ####update_observers $motor

        # update all parent motors and update their targets
        print "update parents about $motor"
        if { $gDevice($motor,parents) != {} } {    
            update_parents $motor 1
        }
        print "done updating parents about $motor"
}
proc stog_configure_detector {args} {}
#parse log message and send out email if needed
proc stog_log {args} {
    variable ::nScripts::log_mail_map

    set level [lindex $args 0]
    set sender [lindex $args 1]
    set message [join [lrange $args 2 end]]

    if {[string range $level 0 4] == "chat_"} {
        user_chat_file [string range $level 5 end] $sender $message
        return
    }

    if {![info exists log_mail_map]} {
        return
    }
    if {[llength $log_mail_map] <= 0} {
        return
    }

    set timeStamp [clock format [clock seconds] -format "%d %b %Y %X"]
    set contents "$timeStamp $message"
    set subject "CONTROL: [::config getConfigRootName] $level from $sender"

    set token [::mime::initialize -canonical text/plain -string $contents]
    ::mime::setheader $token Subject $subject
    ::mime::setheader $token From "blctl"

    if {[catch {
        foreach mail_map $log_mail_map {
            foreach {senderPattern levelPattern mail_list} $mail_map break

            if {[regexp ^$senderPattern\$ $sender] &&
            [regexp ^$levelPattern\$ $level]} {
                puts "sending email to $mail_list"
                ::smtp::sendmessage $token -recipients $mail_list
                break
            }
        };#foreac mail_map
    } emsg]} {
        puts "log to email failed: $emsg"
    }
    ::mime::finalize $token
}

proc stog_start_operation {args} {
    global gSystemOperationList
    global gOperation
    variable ::nScripts::lock_operation
        
    #get operation name
    set op_name [lindex $args 0]
    set op_handle [lindex $args 1]
    set gOperation($op_name,stopFlag) 0

    #add to gOutstandingOperations set if it is in the lock list
    if {[lsearch -exact $lock_operation $op_name] != -1 ||
    [lsearch -exact $lock_operation ALL] != -1} {
        set hardwareHost  $gOperation($op_name,hardwareHost) 
        global gOutstandingOperations${hardwareHost}
        if {[catch {
            add_to_set gOutstandingOperations${hardwareHost} \
            [list $op_name $op_handle]
        } errMsg]} {
            log_error Error add $op_name to outstanding operations: $errMsg
        }
    }

    #append it to the system status string
    if { [catch {namespace eval nScripts add_to_system_idle $op_name} error] } {
        log_error "Error add system_idle: $error"
    }
    if {[isOperation userNotify]} {
        if { [catch {namespace eval nScripts userNotify_onOperationStart $op_name $op_handle} error] } {
            log_error "Error on add to notify: $error"
        }
    }
}

proc stog_stop_operation { args } {
    global gOperation
    set op_name [lindex $args 0]
    set gOperation($op_name,stopFlag) 1

    #log_note "stop flag set for operation $op_name"
}
proc stoh_stop_operation { args } {
    global gOperation
    set op_name [lindex $args 0]

    incr gOperation($op_name,stopFlag)

    if {[info commands nScripts::${op_name}_stopCallback] != ""} {
        puts "doing ${op_name}_stopCallback"
        if {[catch {namespace eval nScripts ${op_name}_stopCallback} errMsg]} {
            puts " ${op_name}_stopCallback failed: $errMsg"
        }
    }
    log_note "stop flag set for self operation $op_name"
}

proc handle_stog_messages {textMessage binaryMessage} {
    if {[string first hutchDoorStatus $textMessage] == -1} {
        set logMsg [PRIVATEFilter $textMessage]
        set logMsg [SIDFilter $logMsg]
        print "selfGui in<- $logMsg"
    }

    if { [catch {eval $textMessage} errorResult] } {
        #Ouch, what can we do now?
        ## to prevent dead loop
        if {[string first "Unhandled error in scripting engine" $textMessage] < 0} {
            ::dcss2 sendMessage "htos_log software_severe server Unhandled error in scripting engine $errorResult while processing $textMessage"
        }
    }
}

proc handle_stoh_messages {textMessage binaryMessage} {
    set logMsg [PRIVATEFilter $textMessage]
    set logMsg [SIDFilter $logMsg]
    print "self_HW in<- $logMsg"
    if { [catch {eval $textMessage} errorResult]} {
        #Ouch, what can we do now?
        if {[string first "Unhandled error in scripting engine" $textMessage] < 0} {
            ::dcss2 sendMessage "htos_log software_severe server Unhandled error in scripting engine $errorResult while processing $textMessage"
        }
    }
}

proc stoh_abort_all { args } {

    # global variables
    global gDevice
    global gWait
    global gAbortCallbacks

    incr gDevice(abortCount)
    print "New abort count = $gDevice(abortCount)"

    ############# log ############
    if {$gDevice(moving_motor_list) != ""} {
        log_warning "Abort motor list: $gDevice(moving_motor_list)"
    }

    # abort wait timer if running
    if { $gWait(status) == "waiting" } {
        set gWait(status) aborting
    }

    # abort string waiting
    foreach strObj $gDevice(string_list) {
        if {$gDevice($strObj,status) != "inactive"} {
            #log_note set string $strObj to aborted
            set gDevice($strObj,status) inactive
            set gDevice($strObj,lastResult) aborted
        }
    }

    ###callbacks (for self motors)
    foreach command $gAbortCallbacks {
        if {[catch {
            namespace eval nScripts $command
        } error] } {
            log_error $error
        }
    }

}

# put set_children function in nScripts namespace
namespace eval nScripts {
    
    proc set_children { args } {
        
        # global variables
        global gDevice
        
        # store children of this device
        set gDevice($gDevice(current_device),children) $args        
        
        foreach child $args {
            # add current device to parents list of the child
            lappend gDevice($child,parents) $gDevice(current_device)
        }
    }

    proc set_siblings { args } {
        
        # global variables
        global gDevice
        
        # store children of this device
        set gDevice($gDevice(current_device),siblings) $args
    }

    proc set_triggers { args } {
        # global variables
        global gDevice
        
        # add the current device to the "observers" list of the trigger device 
        foreach triggerDevice $args {
            lappend gDevice($triggerDevice,observers) $gDevice(current_device)
        }
    }

    ##### system_idle supports motors and operations
    proc add_to_system_idle { op_name {unique 0}} {
        variable lock_operation 
        variable system_idle

        if {([lsearch -exact $lock_operation $op_name] != -1) || \
        ([lsearch -exact $lock_operation ALL] != -1)} {
            if {!$unique || [lsearch -exact $system_idle $op_name] == -1} {
                lappend system_idle $op_name
            }
        }
    }

    proc remove_from_system_idle { op_name {all_instance 0}} {
        variable system_idle
        set notrace_system_idle $system_idle

        if {$all_instance} {
            set anyChange 0
            while {1} {
                set index [lsearch -exact $notrace_system_idle $op_name]
                if {$index != -1} {
                    set notrace_system_idle \
                    [lreplace $notrace_system_idle $index $index]
                    set anyChange 1
                } else {
                    break
                }
            }
            if {$anyChange} {
                set system_idle $notrace_system_idle
            }
        } else {
            set index [lsearch -exact $notrace_system_idle $op_name]
            if {$index != -1} {
                set notrace_system_idle [lreplace $notrace_system_idle $index $index]
                set system_idle $notrace_system_idle
            }
        }
        check_system_idle
    }

    proc clear_system_idle {  } {
        variable system_idle
        set system_idle {}
    }
    proc check_system_idle { } {
        global gDevice
        variable system_idle
        ###we can only deal with motors now.
        ###it is motors give us trouble, so it should be enough
        set new_system_idle ""
        foreach device $system_idle {
            set should_be_removed 0
            if {[isMotor $device]} {
                if {$gDevice($device,status) != "moving"} {
                    set should_be_removed 1
                    puts "WARNING system_idle $device removed: not moving"
                }
            }
            if {!$should_be_removed} {
                lappend new_system_idle $device
            }
        }
        if {$new_system_idle != $system_idle} {
            set system_idle $new_system_idle
        }
    }
}

proc stoh_start_motor_move { motor position {fromSelf ""} } {

    # global variables
    global gDevice

    if { [catch {checkForMotorsBlockedByScriptedOperation $fromSelf} err] } {
        set gDevice($motor,lastResult) [lindex $err 0]
        puts "check block error"
        dcss2 sendMessage "htos_motor_move_completed $motor $gDevice($motor,scaled) [lindex $err 0] [lindex $err 1]"
        abort
        return
    }

    print "About to move $motor..."

    #Set the global abort count to allow us to know if we have been aborted later.
    set gDevice($motor,abortCount) $gDevice(abortCount)

    if { $fromSelf == "" } {
        # do move checks if message was from client
        print "not from self, check ...."
        if { [catch {checkMoveRequestFromClient $motor $position} err]} {
            set gDevice($motor,lastResult) $err
            puts "check move request error $err"
            dcss2 sendMessage "htos_motor_move_completed $motor $gDevice($motor,scaled) $err"
            abort
            return
        }

    }

    if { $gDevice($motor,scripted) } {
        print "scripted"
        # execute the move script if scripted device
        moveScriptedDevice $motor $position
        # indicate that the device is now moving
    } else {
        print "external"
        moveExternalMotor $motor $position
    }
}

proc checkForMotorsBlockedByScriptedOperation { operationID } {
    global gDevice

    #check to see if an operation has blocked all motor moves.
    if { $gDevice(all_motors_blocked) != "unblocked" } {
        
        if {$operationID != $gDevice(all_motors_blocked) } {
            print "All motors blocked."
            return -code error "blocked [list $operationID $gDevice(all_motors_blocked)]"
        }
    }
}

proc moveExternalMotor { motor position } {
    # for real motors just send the move command back to dcss
    dcss sendMessage "gtos_start_motor_move $motor $position"
}

proc moveScriptedDevice {motor position} {
    global gSiblingsMoving
    global gDevice

    dcss2 sendMessage "htos_motor_move_started $motor $position"

    handle_move_start $motor

    set siblingMoveResult "normal"
        
    if { ! $gSiblingsMoving } {
        
        set gSiblingsMoving 1
        
        foreach sibling $gDevice($motor,siblings) {

            print "Checking sibling $sibling..."
            
            if { [expr abs($gDevice($sibling,target) - $gDevice($sibling,scaled)) > $gDevice($sibling,maxTargetError)] } {
                
                print "Moving sibling device $sibling back to target value of $gDevice($sibling,target)"
                
                if { [catch { move $sibling to $gDevice($sibling,target) } ] } {
                    print "************** caught error moving sibling $sibling ************************"
                    set siblingMoveResult "error"
                    break
                } 
                
                if { [catch {wait_for_devices $sibling} ] } {
                    print "************** caught error waiting for sibling ************************"
                    set siblingMoveResult "error"
                    break
                } 
                
            } else {
                print "Sibling at target."
            }
        }
        set gSiblingsMoving 0
    }
    
    if { $siblingMoveResult == "normal" } {
        
        # set move result to normal
        set moveResult "normal"
        
        set gDevice(current_device) $motor
        
        if { [catch "namespace eval nScripts ${motor}_move $position" error] } {
            log_error "Error executing $motor script: $error"
            
            # store the result of the move
            #set moveResult "aborted"
            set moveResult $error
        }
    } else {
        set moveResult "aborted"
    }
    
    set gDevice($motor,lastResult) $moveResult
    
    # get final position of device
    setScaledValue $motor [nScripts::${motor}_update]

    # set the target value of the device and its parents if move was successful
    if { ($moveResult == "normal") && (! $gSiblingsMoving) } {
        print "*********************** Setting target of $motor **********************"
        set gDevice($motor,target) $gDevice($motor,scaled)
    }
    
    if {$moveResult == "normal" && [parents_not_moving $motor] && ! $gSiblingsMoving } {
        update_parents $motor 1
    } else {
        update_parents $motor 0
    }
    
    # indicate that the motor is now inactive
    handle_move_complete $motor
    
    # report the result of the move
    dcss2 sendMessage "htos_motor_move_completed $motor $gDevice($motor,scaled) $moveResult"
}

proc checkMoveRequestFromClient {motor position} {
    global gDevice

    puts "check move request: $motor $position"

    # make sure device is inactive
    if { $gDevice($motor,status) != "inactive" } {
        return -code error $gDevice($motor,status)
    }
    puts "check move request: lock"
    
    # make sure motor is not locked
    if { $gDevice($motor,lockOn) } {
        return -code error locked
    }

    puts "check move request: parent lock"
    # make sure parents are not locked
    if { ![parents_unlocked $motor] } {
        return -code error locked
    }            

    # make sure not in config
    puts "check move request: config"
    if {$gDevice($motor,configInProgress)} {
        return -code error configInProgress
    }

    puts "check move request: parent config"
    # make sure parents are not locked
    if { [parents_inConfig $motor] } {
        return -code error parent_configInProgress
    }            

    # make sure children are inactive
    puts "check move request: child inactive"
    foreach child $gDevice($motor,children) {
        if { $gDevice($child,status) != "inactive" } {
            log_error "Child $child of $motor is already moving!"
            return -code error movingChildren
        }
        if {$gDevice($child,configInProgress)} {
            return -code error child_configInProgress
        }
    }
    
    # make sure old and new positions are within limits
    puts "check limits_ok $motor $position"
    if { ![limits_ok $motor $position] } {
        return -code error ${motor}_sw_limit
    }

    # make sure move would not violate limits of parents
    puts "check parents_limits_ok $motor $position"
    if { ! [parent_limits_ok $motor $position] } {
        return -code error ${motor}_parents_sw_limit
    }

    puts "check children_limits_ok $motor $position"
    if {![children_limits_ok $motor $position]} {
        return -code error ${motor}_children_sw_limit
    }
        
    return 1
}

proc stoh_register_operation { operation scriptName } {

    # global variables
    global gOperation
    global OPERATION_DIR

    # read the operation script
    puts $OPERATION_DIR/${scriptName}.tcl

    if {$scriptName == "GENERIC_ABS_ENCODER_OP"} {
        set scriptTemplateFile [open $OPERATION_DIR/$scriptName.tcl]
        set templateScript [read $scriptTemplateFile]
        close $scriptTemplateFile

        switch -exact -- $scriptName {
            "GENERIC_ABS_ENCODER_OP" {
                set prefix [getPrefixFrom_ $operation 2]
            }
            default {
                set prefix [getPrefixFrom_ $operation 1]
            }
        }
        if {$prefix == ""} {
            log_error bad name $operation for $scriptName
            return
        }

        regsub -all PREFIX $templateScript $prefix processedScript
        #puts "*************"
        #puts $processedScript
        #puts "*************"
        
        if { [catch "namespace eval nScripts {$processedScript}" error] } {
            log_error $error
            return
        }
    } else {
        if { [catch "namespace eval nScripts source $OPERATION_DIR/${scriptName}.tcl" error] } {
            log_error $error
            return
        }
    }

    # set the operation to non-parallel by default
    set gOperation($operation,parallel) 0

    # execute the initialization script
    if { [catch "namespace eval nScripts ${operation}_initialize" error] } {
        log_error $error
        return
    }

    # set the operation state to inactive
    set gOperation($operation,registered) 1 

    # set the operation state to inactive
    set gOperation($operation,status) inactive
    set gOperation($operation,count) 0

    # set the last operation result to success
    set gOperation($operation,lastResult) normal

    # set return value for operation to NULL
    set gOperation($operation,returnValue) ""

    print "************************ Registered $operation ******************************"
}



proc stoh_start_operation { operation operationHandle args } {

    # global variables
    global gOperation
    global gDevice

    puts "entered stoh_start_operation $operation $operationHandle"
    incr gOperation($operation,count)

    # stop if operation is active and not parallel
    if { $gOperation($operation,status) != "inactive" && ! $gOperation($operation,parallel) } {
        
        print "*********** Operation $operation already in progress! ***************"
        dcss2 sendMessage "htos_operation_completed $operation $operationHandle active"
        return
    }
    
    #set the abort count for this operation to see later if we have been aborted
    set gOperation($operationHandle,abortCount) $gDevice(abortCount)

    # set the operation state to active
    set gOperation($operation,status) active

    # set the operation result to success
    set gOperation($operation,lastResult) normal
    
    # run the operation start script
    if {[catch {
        set gOperation($operation,returnValue) \
        [namespace eval nScripts ${operation}_start $args]
    } errorResult] } {
         
        #log_error "Error executing $operation script: $errorResult"

        # store the result of the move
        set gOperation($operation,lastResult) "error"
        set gOperation($operation,returnValue) $errorResult
        #if { [info exists gOperation($operationHandle,status)] } {
        #    set gOperation($operationHandle,status) "error"
        #}
    } else {
        set gOperation($operation,lastResult) normal
    }
    if {[info commands nScripts::${operation}_cleanup] != ""} {
        puts "doing ${operation}_cleanup"
        if {[catch {namespace eval nScripts ${operation}_cleanup} errMsg]} {
            puts " ${operation}_cleanup failed: $errMsg"
        }
    }

    #check to see if this operation had blocked motors...
    if { $gDevice(all_motors_blocked) == $operationHandle } {
        puts "automatically unblocking all motors"
        set gDevice(all_motors_blocked) "unblocked"
    }

    # send the server an operation complete message
    dcss2 sendMessage "htos_operation_completed $operation $operationHandle $gOperation($operation,lastResult) $gOperation($operation,returnValue)"
}

proc stog_operation_completed { operationName operationHandle status args } {
    global gOperation


    if {$operationName == "detector_stop" && [isString detector_status]} {
        variable ::nScripts::detector_status
        if {$status == "normal"} {
            set display Ready
        } else {
            set display Error
        }

        set detector_status "Detector $display"
    }


    ### remove from system_idle if the operation is in the list
    if { [catch "namespace eval nScripts remove_from_system_idle $operationName" error] } {
        log_error "Error remove from system_idle: $error"
    }
    if {[isOperation userNotify]} {
        if { [catch {
            namespace eval nScripts userNotify_onOperationComplete \
            $operationName $operationHandle $status $args
        } error] } {
            log_error "Error on userNotify: $error"
        }
    }

    #get the hardware host for this operation
    set hardwareHost  $gOperation($operationName,hardwareHost) 
    #put the set of operations controlled by the hardware host in the global name space
    global gOutstandingOperations${hardwareHost}

    #If the results of the instance of this operation are being waited for, store the result
    if { [info exists gOperation($operationHandle,status) ] } {
        set gOperation($operationHandle,result) $args
        set gOperation($operationHandle,status) $status
    }

    #if this script is controlled by the scripting engine.
    if { [info exists gOperation($operationName,status)] } {
        #Set the operation to inactive. This is useful for scripts that cannot be run in parallel.
        incr gOperation($operationName,count) -1
        set count [set gOperation($operationName,count)]
        if {$count <= 0} {
            set gOperation($operationName,status) inactive
            set gOperation($operationName,count) 0
        }
        #we no longer need to know if this instance of the operation has been aborted.
        if {[info exists gOperation($operationHandle,abortCount)] } {
            unset gOperation($operationHandle,abortCount)
        }
    }
    
    #remove the operation from the set of operations controlled by the hardware host
    if { [info exists gOutstandingOperations${hardwareHost} ] } {
        set element [list $operationName $operationHandle]
        if {[is_in_set gOutstandingOperations${hardwareHost} $element]} {
            print "******** Removing outstanding operation [list $operationName $operationHandle]"
        }
        remove_from_set gOutstandingOperations${hardwareHost} $element
    } else {
        print "gOutstandingOperations${hardwareHost} is empty"
    }

    global gDevice
    set gDevice($operationName,result) "$status $args"
    set gDevice($operationName,timeStamp) [clock seconds]
    updateEventListeners $operationName
    update_observers $operationName
}

proc stog_operation_update { operation operationHandle args } {
    global gOperation

    #print "got operation update $operation $operationHandle"

    #if the operationHandle is in the global operation table, store the result
    if { [info exists gOperation($operationHandle,status) ] } {
        #store the update in the fifo
        set gOperation($operationHandle,update,$gOperation($operationHandle,updateInIndex)) [list $args]
        incr gOperation($operationHandle,updateInIndex)
        #trigger the vwait in wait_for_operation
        set gOperation($operationHandle,status) "active"  
    }

    if {$operation == "detector_collect_image" && [isString detector_status]} {
        variable ::nScripts::detector_status

        set request [lindex $args 0]
        if { $request == "scanning_plate" } {
            set detector_status "Scanning Plate [lindex $args 1]%..."
        }
        if { $request == "erasing_plate" } {
            set detector_status "Erasing Plate [lindex $args 1]%..."
        }
    }
}

proc stoh_register_pseudo_motor { motor scriptName args } {
    
    # global variables
    global gDevice
    global DEVICE_DIR

    # create the device if not yet defined
    if { ! [info exists gDevice($motor,type)] } {
        create_pseudo_motor $motor component mm
    }
    
    set gDevice($motor,scripted) 1
    
    # generate the motor script
    if { $scriptName == "standardVirtualMotor" || \
    $scriptName == "stringMotor" || \
    $scriptName == "clsMotor" || \
    $scriptName == "standardEncoderMotor" || \
    $scriptName == "standardLaserMotor"} {
        #generate the standard virtual motor from the template.
        set scriptTemplateFile [open $DEVICE_DIR/$scriptName.tcl]
        set templateScript [read $scriptTemplateFile]
        close $scriptTemplateFile

        #puts "*************"
        #puts $templateScript
        #puts "*************"
        regsub -all VIRTUAL $templateScript $motor processedScript
        #puts "*************"
        #puts $processedScript
        #puts "*************"
        
        if { [catch "namespace eval nScripts {$processedScript}" error] } {
            log_error $error
            return
        }
    } elseif { \
    $scriptName == "SCAN2D_VERT" || \
    $scriptName == "SCAN2D_HORZ" || \
    $scriptName == "DEG_VERT" || \
    $scriptName == "DEG_PITCH" || \
    $scriptName == "DEG_HORZ" || \
    $scriptName == "DEG_YAW" || \
    $scriptName == "MRAD_VERT" || \
    $scriptName == "MRAD_PITCH"|| \
    $scriptName == "STDSLIT_VERT"|| \
    $scriptName == "STDSLIT_VERT_GAP" ||\
    $scriptName == "STDSLIT_HORIZ" || \
    $scriptName == "STD_MOVE_TOGETHER" || \
    $scriptName == "GENERIC_CORR_ABS" || \
    $scriptName == "ENCODER_MOTOR" || \
    $scriptName == "STRING_DISPLAY_MOTOR" || \
    $scriptName == "STDSLIT_HORIZ_GAP" \
    } {
        #generate the standard virtual motor from the template.
        set scriptTemplateFile [open $DEVICE_DIR/$scriptName.tcl]
        set templateScript [read $scriptTemplateFile]
        close $scriptTemplateFile

        #### get PREFIX from motor name
        switch -exact -- $scriptName {
            "STDSLIT_HORIZ_GAP" -
            "STDSLIT_VERT_GAP" {
                set prefix [getPrefixFrom_ $motor 2]
            }
            "STD_MOVE_TOGETHER" {
                set prefix $motor
            }
            "ENCODER_MOTOR" {
                set prefix [string range $motor 0 end-14]
                puts "ENCODER_MOTOR prefix=$prefix"
            }
            "STRING_DISPLAY_MOTOR" {
                set prefix [string range $motor 0 end-5]
                puts "STRING_DIPLAY_MOTOR prefix=$prefix"
            }
            default {
                set prefix [getPrefixFrom_ $motor 1]
            }
        }
        if {$prefix == ""} {
            log_error bad motor name $motor for $scriptName
            return
        }

        #puts "*************"
        #puts $templateScript
        #puts "*************"
        regsub -all PREFIX $templateScript $prefix processedScript
        #puts "*************"
        #puts $processedScript
        #puts "*************"
        
        if { [catch "namespace eval nScripts {$processedScript}" error] } {
            log_error $error
            return
        }
    } else {
        #load the script from the scripted device directory
        if { [catch "namespace eval nScripts source $DEVICE_DIR/${scriptName}.tcl" error] } {
            log_error $error
            return
        }
    }
    # execute the initialization script
    set gDevice(current_device) $motor
    if { [catch "namespace eval nScripts ${motor}_initialize" error] } {
        log_error $error
        return
    }
    
    # store name of registered motor
    add_to_set gDevice(registered_scripted_devices) $motor
    
    # request current configuration
    dcss2 sendMessage "htos_send_configuration $motor"
}


proc stog_configure_real_motor { motor hardwareHost hardwareName \
     position upperLimit lowerLimit scaleFactor speed acceleration backlash \
     lowerLimitOn upperLimitOn motorLockOn backlashOn reverseOn status } {

    # global variables
    global gDevice
    add_to_set gDevice($hardwareHost,deviceList) $motor

    #store the hardware host for each device. This allows clean up when hardware host goes offline.
    set gDevice($motor,hardwareHost) $hardwareHost

    # create the device if not yet defined
    if { ! [info exists gDevice($motor,type)] } {
        print "*********************************************create $motor"
        create_real_motor $motor component mm
    }

    setScaleFactorValue $motor $scaleFactor
    setScaledValue $motor $position
    setUpperLimitFromScaledValue $motor $upperLimit
    setLowerLimitFromScaledValue $motor $lowerLimit
    setSpeedValue $motor $speed
    setAccelerationValue $motor $acceleration
    setBacklashFromUnscaledValue $motor $backlash
    setLowerLimitEnableValue $motor $lowerLimitOn
    setUpperLimitEnableValue $motor $upperLimitOn
    setLockEnableValue $motor $motorLockOn
    setBacklashEnableValue $motor $backlashOn
    setReverseEnableValue $motor $reverseOn

    updateEventListeners $motor
    ####enable this after testing of event listeners first
    ####update_observers $motor

    # update all parent motors and update their targets
    print "update parents about $motor"
    if { $gDevice($motor,parents) != {} } {    
        update_parents $motor 1
    }
    print "done updating parents about $motor"
}


proc stoh_configure_pseudo_motor { motor hardwareHost hardwareName position \
    upperLimit lowerLimit lowerLimitOn upperLimitOn motorLockOn status } {

    # global variables
    global gDevice

    #store the hardware host for each device. This allows clean up when hardware host goes offline.
    set gDevice($motor,hardwareHost) $hardwareHost

    # only do configuration change if scripted device
    if { $gDevice($motor,scripted) } { 
        if {$gDevice($motor,configInProgress)} {
            log_severe $motor previous config not finish yet
            return
        }

        set gDevice($motor,configInProgress) 1
        
        # set the pseudomotor parameters
        setUpperLimitFromScaledValue $motor $upperLimit
        setLowerLimitFromScaledValue $motor $lowerLimit
        setLowerLimitEnableValue $motor $lowerLimitOn
        setUpperLimitEnableValue $motor $upperLimitOn
        setLockEnableValue $motor $motorLockOn

        # run the motor set script if not first configuration
        if { $gDevice($motor,configured) } {

            if { [catch "namespace eval nScripts ${motor}_set $position" error] } {
                log_error "Error executing 'set' script for $motor: $error"
                set gDevice($motor,configInProgress) 0
                return
            } else {
                set gDevice($motor,configInProgress) 0
                set gDevice($motor,target) $position
            }
        } else {
            set gDevice($motor,configured) 1
            set gDevice($motor,configInProgress) 0
            setScaledValue $motor $position
            set gDevice($motor,target) $position
        }

        # update position of device
        setScaledValue $motor [nScripts::${motor}_update]

        dcss2 sendMessage "htos_configure_device $motor $gDevice($motor,scaled) \
      $upperLimit $lowerLimit $lowerLimitOn $upperLimitOn $motorLockOn"
        
        # update all parent motors and update their targets
        if { $gDevice($motor,parents) != {} } {    
            update_parents $motor 1
        }
        #inform all interested devices that the motor has been set
        updateEventListeners $motor
        update_observers $motor
    }
}

proc stoh_correct_motor_position { motor adjust } {
    # global variables
    global gDevice

    if {![isMotor $motor]} {
        log_error in correct_motor_position $motor is not a motor
        return
    }

    if {!$gDevice($motor,scripted)} {
        puts "should not be here stoh for a not scripted motor: $motor"
        return
    }

    variable ::nScripts::$motor
    set motor [expr [set $motor] + $adjust]
}


proc stog_configure_ion_chamber { 
    ion_chamber host counter channel timer timer_type } {

    # global variables
    global gDevice
    add_to_set gDevice($host,deviceList) $ion_chamber
    add_to_set gDevice(ionChamberList) $ion_chamber
    
    # set ion chamber parameters
    set gDevice($ion_chamber,hardwareHost)    $host
    set gDevice($ion_chamber,counter)        $counter
    set gDevice($ion_chamber,timer)            $timer
    set gDevice($ion_chamber,channel)        $channel
    set gDevice($ion_chamber,status)         inactive
    set gDevice($ion_chamber,counts)         0
    set gDevice($ion_chamber,cps)             0
    set gDevice($ion_chamber,type)            ion_chamber
    set gDevice($ion_chamber,timer_type)    $timer_type
    set gDevice($ion_chamber,lastResult)     normal

    if { ! [info exists gDevice($ion_chamber,observers) ] } {
        set gDevice($ion_chamber,observers) ""
    }
    # add ion chamber to list of detectors associated with timer
    add_to_set gDevice(ion_chamber_list) $ion_chamber
}



proc stog_configure_shutter { shutter host state } {
    
    # global variables
    global gDevice
    add_to_set gDevice($host,deviceList) $shutter
    
    create_shutter $shutter
    set gDevice($shutter,state)     $state
    set gDevice($shutter,hardwareHost) $host
    add_to_set gDevice(shutter_list) $shutter
}



proc stog_update_motor_position { motor position status } {

    # global variables
    global gDevice

    # skip if motor is scripted device
    if { $gDevice($motor,scripted) } {
        return
    }

    # reset timeout
    set gDevice($motor,timedOut) 0

    # update the motor position
    setScaledValue $motor $position

    # update position of all parent motors
    if { $gDevice($motor,parents) != {} }  {
        start_polling $gDevice($motor,parents)
    }

    updateEventListeners $motor

    # check if motor hit clockwise hardware limit
    if { $status == "cw_hw_limit" } {
        log_error "Motor $motor hit clockwise hardware limit."
        return
    }
    
    # check if motor hit counter-clockwise hardware limit
    if { $status == "ccw_hw_limit" } {
        log_error "Motor $motor hit counterclockwise hardware limit."
        return
    }
}


proc stog_motor_move_completed { motor position status } {
    ### remove from system_idle if the operation is in the list
    puts "remove $motor from system idle"
    if { [catch "namespace eval nScripts remove_from_system_idle $motor 1" error] } {
        log_error "Error remove from system_idle: $error"
    }

    
    # global variables
    global gDevice
    global gSiblingsMoving

    #get the hardware host for this operation
    set hardwareHost $gDevice($motor,hardwareHost)
    #put the set of devices controlled by the hardware host in the global name space

    set gDevice($motor,lastResult) $status

    # handle move complete message for real devices only
    if { ! $gDevice($motor,scripted) } {
    
        # update the motor position
        setScaledValue $motor $position
        
        # store the result of the move
        if { $status == "normal" && [parents_not_moving $motor]  && (! $gSiblingsMoving) } {
            update_parents $motor 1
        } else {
            update_parents $motor 0
        }

        # update status of motor
        handle_move_complete $motor

        # if not normal or aborted status, abort everything!
        if { $status != "normal" && $status != "aborted" } {
            #dcss2 sendMessage "htos_motor_move_completed $motor $position $status"
            abort
        }
    }

    triggerTimerService $motor
}

proc stog_motor_move_started { motor position } {
    #append it to the system status string
    puts "add $motor to system idle"
    if { [catch "namespace eval nScripts add_to_system_idle $motor 1" error] } {
        log_error "Error add system_idle: $error"
    }
    # global variables
    global gDevice
    
    # skip if motor is scripted device
    if { $gDevice($motor,scripted) } {
        set gDevice($motor,lastResult) normal
        return
    }
    
    # update gui
    handle_move_start $motor
}

proc stog_limit_hit { motor direction } {

    # global variables
    global gDevice

    # report the error
    log_error "Motor $motor has hit $direction hardware limit."

    # abort any other moving motors or scans
    do abort soft
}


proc stog_device_active { device operation } {

    # global variables
    global gDevice

    # report the error
    log_error "Device $device is active.  $operation operation failed."
}


proc stog_no_hardware_host { device } {

    # report the error
    log_error "Hardware host for device $device not connected."
}


proc update_motor_config_to_server { motor } {

    # global variables
    global gDevice
    
    if { $gDevice($motor,type) == "real_motor" } {
        set backlash [expr round($gDevice($motor,scaledBacklash) * \
            $gDevice($motor,scaleFactor) ) ]
    
        dcss sendMessage "gtos_configure_device $motor \
            $gDevice($motor,scaled)\
            $gDevice($motor,scaledUpperLimit)\
            $gDevice($motor,scaledLowerLimit)\
            $gDevice($motor,scaleFactor)\
            $gDevice($motor,speed)\
            $gDevice($motor,acceleration)\
            $backlash\
            $gDevice($motor,lowerLimitOn)\
            $gDevice($motor,upperLimitOn)\
            $gDevice($motor,lockOn)\
            $gDevice($motor,backlashOn)\
            $gDevice($motor,reverseOn) "
    } else {
        dcss sendMessage "gtos_configure_device $motor \
            $gDevice($motor,scaled)\
            $gDevice($motor,scaledUpperLimit)\
            $gDevice($motor,scaledLowerLimit)\
            $gDevice($motor,lowerLimitOn)\
            $gDevice($motor,upperLimitOn)\
            $gDevice($motor,lockOn)    "
    }
}


proc stog_unrecognized_command {} {
    #log_error "Command unrecognized by server."
}


proc stog_report_ion_chambers { time args } {

    # global variables
    global gDevice

    # deal with error message
    # error message will have extra "reason" at the end of args.
    if {$time <= 0} {
        set result [lindex $args end]
        log_warning "ion chamber reading error: $result"

        foreach ion_chamber [lrange $args 0 end-1] {
            set gDevice($ion_chamber,counts) 0
            set gDevice($ion_chamber,cps)    0
            set gDevice($ion_chamber,status) inactive
            set gDevice($ion_chamber,lastResult) $result
        }
        return
    }
    
    # get number of arguments
    set argc [llength $args]
    # initialize argument index
    set index 0
    
    while { $index < $argc } {

        set ion_chamber [lindex $args $index]
        incr index
        set counts [lindex $args $index]
        incr index
        
        set gDevice($ion_chamber,counts) $counts
        catch {set gDevice($ion_chamber,cps)    [expr int($counts / $time) ]}
        set gDevice($ion_chamber,status) inactive
        set gDevice($ion_chamber,lastResult) normal
        updateEventListeners $ion_chamber
        update_observers $ion_chamber
    }
}    


proc stog_report_shutter_state { shutter state {result normal} } {
    
    # global variables
    global gDevice
    
    # set the state of the shutter
    if {$result == "normal"} {
        set gDevice($shutter,state) $state
    }
    
    set gDevice($shutter,lastResult) $result
    # set status to inactive
    set gDevice($shutter,status) "inactive"

    #set the update_observers
    updateEventListeners $shutter
    update_observers $shutter
}



proc stog_test_socket_connection { junk } {
    
        log_note "got Test Message."
  
    }


proc stoc_send_client_type {} {
    dcss2 sendMessage "htos_client_is_hardware self"
}



#this message is sent by DCSS after client is completely initialized
proc stog_login_complete { clientId args } {
    global gClientId
    #
    set gClientId $clientId
}


proc stog_note { args } {

    ####start from 1 to match old code on BluIce
    foreach {arg1 arg2 arg3 arg4} $args break

    switch -exact -- $arg1 {
        image_ready {
            log_note Loading ${arg2}...

            ####old, maybe not used anymore
            global collectedImages
            set collectedImages $arg2
            updateXFormStatusFile $arg2
        }
        encoder_offline {
            log_error Mono encoder is offline
        }
        mono_corrected {
            log_warning Mono_theta corrected
        }
        changing_detector_mode {
            log_note Changing detector mode...
            if {[isString detector_status]} {
                variable ::nScripts::detector_status
                set detector_status "Changing Detector Mode..."
            }
        }
        movedExistingFile {
            log_warning $arg2 moved to $arg3
        }
        failedToBackupExistingFile {
            log_error $arg2 already exists and cound not be backed up
        }
        failedToWriteFile {
            log_error $arg2 could not be written to disk
            abort
        }
        ion_chamber {
            log_note ion_chamber $arg3 $arg4
        }
        no_beam {
            log_warning No Beam
            if {[isString detector_status]} {
                variable ::nScripts::detector_status
                set detector_status "error: No Beam"
            }
        }
        Warning {
            log_warning [lrange $args 1 end]
        }
        Error {
            log_error [lrange $args 1 end]
        }
        LID_OPENED {
            log_warning Lid Opened
            ::dcss2 sendMessage "htos_set_string_completed cassette_owner normal blctl blctl blctl blctl"
        }

        detector_z -
        default {
            log_warning $args
        }
    }
}


proc stog_configure_run { name runStatus nextFrame runLabel \
                                        fileroot directory startFrameLabel axisMotor \
                                        startAngle endAngle delta wedgeSize exposureTime distance beamStop\
                                        numEnergy energy1 energy2 energy3 energy4 energy5 \
                                        modeIndex inverseOn } {
    puts "entered stog_configure_run"
}

#This function is called during initialization of the scripting engine.
#The encoders are initialized here.  The controller position is what the actual motion controller
#thinks the position is.  The databasePosition is what was stored in the file on the computer 
#controlling the motion controller.
proc stog_configure_encoder { encoder hardwarehost databasePosition controllerPosition } {
    global gDevice
    add_to_set gDevice($hardwarehost,deviceList) $encoder
    add_to_set gDevice(encoderList) $encoder

    set gDevice($encoder,hardwareHost) $hardwarehost
    set gDevice($encoder,type) encoder
    set gDevice($encoder,status) inactive
    set gDevice($encoder,position) $controllerPosition
    set gDevice($encoder,controllerPosition) $controllerPosition
    set gDevice($encoder,databasePosition) $databasePosition
    set gDevice($encoder,lastResult) normal
    set gDevice($encoder,abortCount) $gDevice(abortCount)

    if { ! [info exists gDevice($encoder,observers) ] } {
        set gDevice($encoder,observers) ""
    }

    updateEventListeners $encoder
    update_observers $encoder
}


proc stog_get_encoder_completed { encoder position status } {
    global gDevice

    set gDevice($encoder,lastResult) $status
    #Setting the status to allow wait_for_encoder to break out of its vwait.
    set gDevice($encoder,status) inactive

    if { $status != "normal" } {
        log_error "Error reading $encoder: $status"
        return
    }

    set gDevice($encoder,position) $position
    updateEventListeners $encoder
    update_observers $encoder
}


proc stog_set_encoder_completed { encoder position status } {
    global gDevice

    set gDevice($encoder,lastResult) $status
    #Setting the status to allow wait_for_encoder to break out of its vwait.
    set gDevice($encoder,status) inactive

    if { $status != "normal" } {
        log_error "Error reading $encoder: $status"
        return
    }
    
    set gDevice($encoder,position) $position
    updateEventListeners $encoder
    update_observers $encoder
}

#The scripted engine will get this message when 
# the scripting engine's gui side connects to the DCSS core.
# It will get this message for each string defined in the local database.
proc stog_configure_string { stringName hardwareHost args } {
    global gDevice
    add_to_set gDevice($hardwareHost,deviceList) $stringName
    set gDevice($stringName,hardwareHost) $hardwareHost

    #Create the device if not yet defined. The only way it could be defined is if the
    # the registration message already came in, in which case we don't want to overwrite
    # the 'scripted' parameter.
    if { ! [info exists gDevice($stringName,type)] } {
        create_string $stringName
        #Initialize the scripted status to 0.  
        #The registration message will set this to 1 if controlled by the scripting engine.
        set gDevice($stringName,scripted) 0
    }
    # Store the contents
    set gDevice($stringName,contents) $args
    set gDevice($stringName,status) inactive
    set gDevice($stringName,lastResult) normal

    updateEventListeners $stringName
    update_observers $stringName
}

#The scripting engine will get this message when the scripting engine's hardware side
#connects to the DCSS core.  It will get this message only for strings that are
#controlled by the scripting engine.
proc stoh_register_string {stringName scriptName } {
    # global variables
    global gDevice
    global STRING_DIR

    set gDevice(current_device) $stringName

    #Create the device if not yet defined.  It will probably already be defined
    # because the gui client side has a head start in connecting to the DCSS core and
    # probably got the stog_configure_string message already.
    if { ! [info exists gDevice($stringName,type)] } {
        create_string $stringName
    }
    
    #Remember that this string is owned by the scripting engine.
    set gDevice($stringName,scripted) 1
    
    #generate the standard virtual motor from the template.
    set scriptTemplateFile [open [file join $STRING_DIR ${scriptName}.tcl]]
    set templateScript [read $scriptTemplateFile]
    close $scriptTemplateFile
    
    regsub -all STRING $templateScript $stringName processedScript
    
    if { [catch {
        namespace eval nScripts $processedScript
    } errorResult] } {
        log_error $errorResult
        return
    }

    # execute the initialization script
    if { [catch "namespace eval nScripts ${stringName}_initialize" errorResult] } {
        log_error $errorResult
        return
    }
    
    # request current configuration
    #dcss2 sendMessage "htos_send_configuration $stringName"
}


proc stoh_set_string { stringName args } {
    global gDevice

    if {$gDevice($stringName,configInProgress)} {
        log_severe $stringName set failed: configInProgress
        return
    }

    set gDevice($stringName,configInProgress) 1
    
    # Run the string's personal configure script.
    if { [catch {set result [namespace eval nScripts ${stringName}_configure $args]} errorResult] } {
        ::dcss2 sendMessage "htos_set_string_completed $stringName $errorResult $gDevice($stringName,contents)"
    } else {
        #the function returned the new string successfully
        set gDevice($stringName,contents) $result
        ::dcss2 sendMessage "htos_set_string_completed $stringName normal $gDevice($stringName,contents)"
    }
    set gDevice($stringName,configInProgress) 0
}

#The contents of the string are passed back by dcss when requested
# by the htos_send_configuration command (see standardString.tcl)
proc stoh_configure_string { stringName hardwareHost args } {
    global gDevice

    if {$gDevice($stringName,configInProgress)} {
        log_severe $stringName config failed: configInProgress
        return
    }
    
    set gDevice($stringName,configInProgress) 1
    
    # Run the string's personal configure script.
    if { [catch {set result [namespace eval nScripts ${stringName}_configure $args]} errorResult] } {
        #It is really bad to be here because the current configuration of the string is not valid within the local database
        #force the definition and plow on.
        set gDevice($stringName,contents) $result
        #inform the guis that there is something wrong
        ::dcss2 sendMessage "htos_set_string_completed $stringName $errorResult $gDevice($stringName,contents)"
    } else {
        #Set the contents
        set gDevice($stringName,contents) $result
    }

    set gDevice($stringName,configInProgress) 0
}

proc stog_set_string_completed {stringName status args } {
    global gDevice

    if { !$gDevice($stringName,scripted) && $status == "normal" } {
        set gDevice($stringName,contents) $args
    }
    
    set gDevice($stringName,lastResult) $status
    set gDevice($stringName,status) inactive

    updateEventListeners $stringName

    ###observers only can be motors
    update_observers $stringName

    triggerTimerService $stringName
}


#remember all of the clients that have been logged in.
proc stog_update_client { clientId unixName args} {
    global gClient
    global gClientInfo
    
    #print "$unixName logged in with id $clientId"
    set gClient($clientId) $unixName

    set gClientInfo($clientId,staff) [lindex $args 3]

    set isMaster [lindex $args 7]
    if {$isMaster} {
        global gMasterListener
        foreach command $gMasterListener {
            if {[catch {
                namespace eval nScripts $command $unixName $clientId
            } error] } {
                log_error $error
            }
        }
    }
}

################################################################
# for scripted ion chamber
################################################################
proc stoh_register_ion_chamber { name counter counterChannel timer timerType } {
    global gDevice
    global DEVICE_DIR

    if {$timerType == "standardVirtualIonChamber"} {
        log_note "standard virtual ion chamber $name"
    } else {
        log_error "$name: $timeType not supported yet only support standardVirtualIonChamber for now"
    }
}

#currently, we only support standardVirturalIonChamber in self,
#so, any stoh_read_ion_chambers is for this type only.
#in short, this is the code for standardVirtualIonChamber
proc stoh_read_ion_chambers { time poll args } {
    global gDevice

    #### reroute to dcss server if any ion chamber not hosted in self
    set allInSelf 1
    foreach ionChamber $args {
        if {$gDevice($ionChamber,hardwareHost) != "self"} {
            log_note $ionChamber not on self
            set allInSelf 0
            break
        }
    }
    log_note allInSelf $allInSelf
    if {!$allInSelf} {
        #this will regroup the ion chambers for each hardwareHost.
        puts forward
        eval read_ion_chambers_nocheck $time $args
        return
    }


    puts "entered stoh_read_ion_chambers $time $poll $args"

    set startOK 1
    set failReason ""

    if {[isOperation genericFScan]} {
        ::nScripts::genericFScan_clearAsk
    }

    #generate operation list from ion chambers
    array set opHandleArray [list]
    array set opResultArray [list]

    array set encoderResultArray [list]

    foreach ionChamber $args {
        puts "before set abortCount"
        set gDevice($ionChamber,abortCount) $gDevice(abortCount)
        set device $gDevice($ionChamber,counter)
        if {[isOperation $device]} {       
            set opHandleArray($device) dummy
            set opResultArray($device) dummy
            if {$device == "genericFScan"} {
                ::nScripts::genericFScan_addAsk $ionChamber
            }
        } elseif {[isEncoder $device]} {
            set encoderResultArray($device) dummy
        } else {
            set startOK 0
            set failReason "ion chamber $ionChamber has unspported sub type"
            log_error $failReason
        }
    }

    if {$startOK} {
        set encoderNameList [array names encoderResultArray]
        foreach encoder $encoderNameList {
            if {[catch {get_encoder $encoder} errMsg]} {
                set startOK 0
                set failReason "get_enoder $encoder failed: $errMsg"
                log_error $failReason
                break
            }
        }
    }

    #start all operations
    if {$startOK} {
        set opNameList [array names opHandleArray]
        foreach opName $opNameList {
            set time_for_operation $time
            if {$opName == "readAnalog"} {
                set time_for_operation [expr $time * 1000.0]
            }
            if {[catch {start_waitable_operation $opName $time_for_operation} \
            opHandleArray($opName)] } {
                set startOK 0
                set failReason "start operation $opName failed: $opHandleArray($opName)"
                log_error $failReason
                break
            }
        }
    }
    #wait operations to finish
    if {$startOK} {
        foreach opName $opNameList {
            if {[catch {wait_for_operation_to_finish $opHandleArray($opName)} \
                        opResultArray($opName)]} {
                set startOK 0
                set failReason "operation $opName failed: $opResultArray($opName)"
                break
            }
            #log_note "$opName result: $opResultArray($opName)"
        }
    }
    if {$startOK} {
        foreach encoder $encoderNameList {
            if {[catch {wait_for_encoder $encoder} \
            encoderResultArray($encoder)]} {
                set startOK 0
                set failReason \
                "$encoder failed: $encoderResultArray($encoder)"
                break
            }
        }
    }

    #generate reading results
    if {$startOK} {
        set readingResults {}
        foreach ionChamber $args {
            set device $gDevice($ionChamber,counter)
            if {[isOperation $device]} {       
                #skip "normal" from operatin result
                if {$device == "genericFScan"} {
                    set index \
                    [lsearch -exact $opResultArray($device) $ionChamber]

                    set index [expr $index + 1]
                } else {
                    set index [expr $gDevice($ionChamber,channel) + 1]
                }
                set result [lindex $opResultArray($device) $index]
                #log_note "put $ionChamber: $result"
                if {$result == "" || ![isFloat $result]} {
                    set failReason \
                    "Error $ionChamber result is not a float: $result"
                    log_error $failReason
                    set startOK 0
                    break
                }
            } else {
                # for now , all others are encoders
                set result $encoderResultArray($device)
                if {$result == "" || ![isFloat $result]} {
                    set failReason \
                    "Error $ionChamber result is not a float: $result"
                    log_error $failReason
                    set startOK 0
                    break
                }
            }
            set timer $gDevice($ionChamber,timer)
            if {[string is double -strict $timer]} {
                puts "convert units for $ionChamber"
                set result \
                [namespace eval nScripts unitsForIonChamber $timer $result $time]
            }
            lappend readingResults $ionChamber $result
        }
    }

    if {!$startOK} {
        set msg "htos_report_ion_chambers 0"
        eval lappend msg $args
        lappend msg $failReason
        dcss2 sendMessage $msg
        return
    }

    #create report message
    set reportMsg "htos_report_ion_chambers $time"
    eval lappend reportMsg $readingResults
    dcss2 sendMessage $reportMsg
}

proc stoh_register_shutter { name state args } {
    global gShutterMap

    set index [::config getInt "shutter.$name" 0]
    incr index -1
    if {$index >= 0} {
        set ll [llength $gShutterMap]
        set needed [expr $index - $ll + 1]
        for {set i 0} {$i < $needed} {incr i} {
            lappend gShutterMap ""
        }
        set gShutterMap [lreplace $gShutterMap $index $index $name]
    }
}
proc stoh_set_shutter_state { name state } {
    set gDevice($name,abortCount) $gDevice(abortCount)
    #log_note got set shutter $name $state
    ##get index
    set index [::config getInt "shutter.$name" 0]
    incr index -1
    #log_note mapping $name to $index

    if {[catch {
        if {$state == "open"} {
            #set result [::nScripts::serialShutter_start remove $index]
            set result \
            [namespace eval nScripts serialShutter_start remove $index]
        } else {
            set result \
            [namespace eval nScripts serialShutter_start insert $index]
        }
        log_note result $result
        #::dcss2 sendMessage "htos_report_shutter_state $name $state"
        namespace eval nScripts serialShutterUpdate
    } errorMsg]} {
        log_error set shutter $name failed: $errorMsg
    }
}
proc stog_dcss_end_update_all_device { args } {
}
proc stog_device_permission_bit { args } {
}
proc stog_set_motor_base_units { motor units } {
    global gDevice
    set gDevice($motor,scaledUnits) $units
}

proc stoh_register_encoder {encoder scriptName } {
    global gDevice
    global DEVICE_DIR

    #Create the device if not yet defined.  It will probably already be defined
    # because the gui client side has a head start in connecting to the DCSS core and
    # probably got the stog_configure_encoder message already.
    if { ! [info exists gDevice($encoder,type)] } {
        set gDevice($encoder,type) encoder
        set gDevice($encoder,status) inactive
        set gDevice($encoder,lastResult) normal
    }
    
    #Remember that this string is owned by the scripting engine.
    set gDevice($encoder,scripted) 1
    
    if { $scriptName == "standardLaserEncoder"} {
        set scriptTemplateFile [open $DEVICE_DIR/$scriptName.tcl]
        set templateScript [read $scriptTemplateFile]
        close $scriptTemplateFile

        #puts "*************"
        #puts $templateScript
        #puts "*************"
        regsub -all VIRTUAL $templateScript $encoder processedScript
        #puts "*************"
        #puts $processedScript
        #puts "*************"
        
        if { [catch "namespace eval nScripts {$processedScript}" error] } {
            log_error $error
            return
        }
    } else {
        #load the script from the scripted device directory
        if { [catch "namespace eval nScripts source $DEVICE_DIR/${scriptName}.tcl" error] } {
            log_error $error
            return
        }
    }
    set gDevice(current_device) $encoder
    if { [catch "namespace eval nScripts ${encoder}_initialize" error] } {
        log_error $error
        return
    }
    
    # request current configuration
    #dcss2 sendMessage "htos_send_configuration $stringName"
}
proc stoh_set_encoder { encoder position } {
    global gDevice

    set gDevice($encoder,abortCount) $gDevice(abortCount)

    if {[catch {namespace eval nScripts ${encoder}_set $position} result]} {
        ::dcss2 sendMessage \
        "htos_set_encoder_completed $encoder $gDevice($encoder,position) {$result}"
    } else {
        ::dcss2 sendMessage \
        "htos_set_encoder_completed $encoder $position normal"
    }
}
proc stoh_get_encoder { encoder } {
    global gDevice

    set gDevice($encoder,abortCount) $gDevice(abortCount)

    if {[catch {namespace eval nScripts ${encoder}_get} result]} {
        ::dcss2 sendMessage \
        "htos_get_encoder_completed $encoder $gDevice($encoder,position) {$result}"
    } else {
        ::dcss2 sendMessage \
        "htos_get_encoder_completed $encoder $result normal"
    }
}
