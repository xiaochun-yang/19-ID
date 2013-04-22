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

#package require Itcl
#namespace import ::itcl::*

set gDebugComments 1
set gOperationCounter 0
set gCommonIonChamberList ""

set gFluxIonChamberTimeScaled 0
array set gUserLogSystemStatus [list]

set MAR345IMGFILEEXT [list mar2300 mar2000 mar1600 mar1200 mar3450 mar3000 mar2400 mar1800]

proc trimPRIVATE { sessionID } {
    if {[string first PRIVATE $sessionID] == 0} {
        return [string range $sessionID 7 end]
    } else {
        return $sessionID
    }
}

proc checkCollectDirectoryAllowed { dir } {
    set prefixList [::config getList collect.allowedDirectory]
    if {$prefixList == ""} {
        set prefixList "/data"
    }
    foreach allowed $prefixList {
        set ll [string length $allowed]
        if {[string equal -length $ll $dir $allowed]} {
            return
        }
    }
    return -code error "not allowed to collect data in directory $dir"
}

### it will automatically get detector type
proc getDetectorFileExt { mode } {
    return [::gDetector getImageFileExt $mode]
}

proc time_stamp {} {
	clock format [clock seconds] -format "%d %b %Y %X"
}

proc operationTimeoutCallback { handle timeout } {
    global gOperation
    puts "timeout callback for $handle"

    set name "unknown operation"
    set hardwareHost ""
    if {[catch {
        set name [set gOperation($handle,name)]
		::dcss2 sendMessage "htos_operation_completed $name $handle timeout"
        set hardwareHost [set gOperation($name,hardwareHost)]
    } errMsg]} {
        log_warning failed to get operation name from $handle: $errMsg
    }
    append name ($handle)
    if {$hardwareHost != ""} {
        log_severe operation $name timeout on $hardwareHost
    } else {
        log_severe operation $name timeout
    }
}

proc wait_for_operation { operationHandle {timeout 0} } {
	# global variables
	global gOperation

	#check to see if there are any updates stored in the update fifo
	if { $gOperation($operationHandle,updateInIndex) > $gOperation($operationHandle,updateOutIndex) } {
		set result $gOperation($operationHandle,update,$gOperation($operationHandle,updateOutIndex))
		#clear out the update to avoid a memory leak
		unset gOperation($operationHandle,update,$gOperation($operationHandle,updateOutIndex))
		incr gOperation($operationHandle,updateOutIndex)
		return "update $result"
	}

	# if the operation is still active, wait for device to become inactive, aborting or get an update
	if { $gOperation($operationHandle,status) == "active" } {

        if {$timeout > 0} {
            set timeout [expr int($timeout)]

            set afterID \
            [after $timeout operationTimeoutCallback $operationHandle $timeout]
            puts "setup timeout for $operationHandle"
        } else {
            set afterID ""
        }
		vwait gOperation($operationHandle,status)
        after cancel $afterID

		#updates could have come in while we were waiting...
		#check to see if there are any updates stored in the update fifo
		if { $gOperation($operationHandle,updateInIndex) > $gOperation($operationHandle,updateOutIndex) } {
			set result $gOperation($operationHandle,update,$gOperation($operationHandle,updateOutIndex))
			#clear out the update to avoid a memory leak
			unset gOperation($operationHandle,update,$gOperation($operationHandle,updateOutIndex))
			incr gOperation($operationHandle,updateOutIndex)
			return "update $result"
		}
	}
	
	puts "****************************operation $operationHandle finished"
	puts "++++++++++++++++ $gOperation($operationHandle,status)"
	if  { $gOperation($operationHandle,updateInIndex) !=  $gOperation($operationHandle,updateOutIndex) } {
		puts "WARNING: ***************  operation update fifo not depleted ! ************** "
	}

	set result $gOperation($operationHandle,result) 	
	set status $gOperation($operationHandle,status)
	
	#unset gOperation($operationHandle,result)
	#unset gOperation($operationHandle,status)
	#unset gOperation($operationHandle,name)
	#unset gOperation($operationHandle,updateInIndex)
	#unset gOperation($operationHandle,updateOutIndex)
    catch { array unset gOperation $operationHandle,* }

	# return an error if any operation completed abnormally
	if { $status == "normal" } { 
		return "$status $result"
	} else {
		return -code error "$status $result"
	}
}

proc wait_for_operation_to_finish { operationHandle {timeout 0} } {
    set status "update"

    while { $status == "update" } {
        set result [wait_for_operation $operationHandle $timeout]
        set status [lindex $result 0]
    }

    return "$result"
}

#use this one if the device list has mixed type of devices.
proc wait_for_devices { args } {
    log_note wait_for_device $args
    ###last one maybe a timeout
    set timeout [lindex $args end]
    if {[string is integer -strict $timeout] && ![isDevice $timeout]} {
        set args [lreplace $args end end]
    } else {
        set timeout ""
    }

	# first check that all specified devices exist
	foreach device $args {
	
		# return an error if device doesn't exist
		if { ![isDevice $device]  } {
			log_error "Device $device does not exist!"
			return -code error ${device}_doesNotExist
		}
	}

    eval wait_for_components $args $timeout
}

proc wait_for_time { time } {
	global gWait
    global gVWaitStack

    set time [expr int($time)]

	#This function can only be called once at a time.
	if { $gWait(status) != "inactive" } {
        puts "wait_for_time flag gWait(status): $gWait(status) != inactive"
        puts "#############vwait stack: bottom to top##############"
        foreach wwww $gVWaitStack {
            puts $wwww
        }
        puts "#####################################################"

        if {$gWait(status) == "waiting"} {
		    ::dcss2 sendMessage "htos_note Warning Function 'wait_for_time' was called twice simultaneously."
		    return -code error "wait_active"
        }
        puts "ERROR BUG in wait_for_time: gWait(status) is not inactive nor waiting"
	}
	
	if { $time > 1000 } {
		log_warning "Waiting for $time ms."
	}
	
	set gWait(status) waiting

	# set timer to change status after specified amount of timer
	set afterID [after $time { set gWait(status) complete }]
	
	vwait gWait(status)

	# cancel 'after' command and return an error if wait was aborted
	if { $gWait(status) == "aborting" } {
		puts "******************** wait_for_time was aborted *********************"
		catch [after cancel $afterID]
		set gWait(status) inactive
		return -code error "aborted"
	}
	
	# otherwise set status to inactive and return
	set gWait(status) inactive
	return
}

proc wait_for_file {filename timeout} {
    #log_info "waiting for for file: $filename"
    set timeWaited 0
    while {$timeWaited < $timeout} {
        if [file exists $filename] return
        wait_for_time 1000
        incr timeWaited 1000
    }
    log_warning "wait for $filename timed-out after $timeout ms"
}


proc isDevice { device } {

	# global variables
	global gDevice

	# return true if the device has an entry in the gDevice array
	return [ info exists gDevice($device,type) ]
}

### operation is not a device (somehow strange)
proc isOperation { name } {
    global gOperation

    return [info exists gOperation($name,hardwareHost)]
}


proc isMotor { device } {

	# global variables
	global gDevice

	# return true if device is either a real or pseudo motor
	return [expr {[isDeviceType real_motor $device] || 
		[isDeviceType pseudo_motor $device] }]
}

proc isEncoder { device } {
    return [isDeviceType encoder $device]
}

proc isShutter { device } {
    return [isDeviceType shutter $device]
}

proc isString { device } {
    return [isDeviceType string $device]
}

proc isIonChamber { device } {
    return [isDeviceType ion_chamber $device]
}

proc isDeviceType { type device } {
	
	# global variables
	global gDevice

	# return true if device exists and is specified type
	return [expr { [isDevice $device] && $gDevice($device,type) == $type }]
	}


proc isPrep { prep } {

	if { $prep == "by" || $prep == "to" } {
		return 1
	} else {
		return 0
	}
}

proc isUnits { units } {

	# global variables
	global gDevice

	if { [lsearch {scaled unscaled mm um deg mrad eV keV A % s ms min K L/m} $units] != -1 } {
		return 1
	} else {
		return 0
	}
}

proc isExpr { value } {

	if { ![catch { expr ($value) }] } {
		return 1
	} else {
		return 0
	}
}


class EventHook {

	# data members
	private variable commandList
	
	# public member functions
	
	# add -- adds a command to the list of handlers
	public method add { command } {
		lappend commandList $command 
	}
	
	# execute -- executes all commands currently in list
	public method execute {} {
		foreach command $commandList {
			eval $command
		}
	}
}


proc gaussian { x {y 0} } {

	set center 0
	set sigma 0.5

	set dist [distance 0 0 $x $y]
	if { $dist > 10 } {
		return 0 
	} else {
		return [expr 0.3989/$sigma * exp(-0.5 * pow(($dist-$center)/$sigma,2)) ]
	}
}


proc pad_string { message requestedlength } {

	set blank_string "                                     "
	set length [string length $message]

	if { $length < $requestedlength } {
		append message [string range $blank_string 0 [expr $requestedlength - $length -1] ]
	}

	return $message
}


proc log_string { string type } {

	set time [time_stamp]	
	print "$time  $string"
}

proc log { args } { log_string "[join $args]" output }
proc log_command { args } { log_string "[join $args]" input }

proc log_severe { args } {
	log_string "SELF SEVERE: [join $args]" error
	::dcss2 sendMessage "htos_log severe server [join $args]"
}
proc log_error { args } {
	log_string "SELF ERROR: [join $args]" error
	::dcss2 sendMessage "htos_log error server [join $args]"
}
proc log_warning { args } {
	log_string "SELF WARNING: [join $args]" warning
	::dcss2 sendMessage "htos_log warning server [join $args]"
}
proc log_note { args } {
	log_string "SELF NOTE: [join $args]" note
	::dcss2 sendMessage "htos_log note server [join $args]"
}

proc user_chat_file { level sender contents } {
    global gUserChatFileHandle
    if {[catch {
        variable ::nScripts::current_user_chat

        if {$current_user_chat == ""} {
            return
        }

        set chat_contents [string map {\r " " \n " "} $contents]

        set userchatts [clock format [clock seconds] -format "%d %b %Y %X"]
        ########## save to file ######
        set filename [lindex $current_user_chat 0]
        if {[info exists gUserChatFileHandle] && $gUserChatFileHandle != ""} {
            close $gUserChatFileHandle
            set gUserChatFileHandle ""
        }
        set gUserChatFileHandle [open $filename a]
        ######## this special format is for the convenience to use excel 
        # to open this file after download
        puts $gUserChatFileHandle \
        "\"$userchatts\" \"$level\" \"$sender\" \"$chat_contents\""
        close $gUserChatFileHandle
        set gUserChatFileHandle ""
    } errMsg]} {
        puts "user chat failed: $errMsg"
    }
}

################################ user log #######################
proc user_log { level catlog args } {
    if {[catch {
        variable ::nScripts::current_user_log
        ########## send out message first
        set log_contents [join $args]
        set log_contents [string map {\r " " \n " " \$ {}} $log_contents]
        ::dcss2 sendMessage [list htos_log user_$level $catlog $log_contents]

        set userlogts [clock format [clock seconds] -format "%d %b %Y %X"]
        ########## save to file ######
        set filename [lindex $current_user_log 0]
        set handle [open $filename a]
        ######## this special format is for the convenience to use excel 
        # to open this file after download
        puts $handle "\"$userlogts\" \"$level\" \"$catlog\" \"$log_contents\""
        close $handle
    } errMsg]} {
        log_error "user log failed: $errMsg"
    }
}
proc user_log_note { catlog args } {
    eval user_log note $catlog $args
}
proc user_log_warning { catlog args } {
    eval user_log warning $catlog $args
}
proc user_log_error { catlog args } {
    eval user_log error $catlog $args
}

proc user_log_get_motor_position { motor } {
    global gDevice
    global gMotorBeamWidth
    global gMotorBeamHeight

    if {$motor != "beam_size"} {
        #set result "$gDevice($motor,scaled) [lindex $gDevice($motor,scaledUnits) 0]"
        set result $gDevice($motor,scaled)
        set result [format "%.3f" $result]
        return $result
    } else {
        # beam_size: fake
        set x $gDevice($gMotorBeamWidth,scaled)
        set y $gDevice($gMotorBeamHeight,scaled)
        set x [format "%.3f" $x]
        set y [format "%.3f" $y]
        return "$x X $y"
    }

}
proc user_log_get_current_crystal { } {
    variable ::nScripts::robot_status

    set mounted [lindex $robot_status 15]

    if {[llength $mounted] < 3} {
        return manual
    }
    foreach { cas row col } $mounted break
    return $cas$col$row
}

proc user_log_any_change { catlog motor unit } {
    global gUserLogSystemStatus

    set current_value [user_log_get_motor_position $motor]
    if {![info exists gUserLogSystemStatus($motor)] || \
    $gUserLogSystemStatus($motor) != $current_value} {
        set gUserLogSystemStatus($motor) $current_value
        set log_contents [format "%-20s %s %s" $motor $current_value $unit]
        user_log_note $catlog $log_contents
        return 1
    }
    return 0
}

proc user_log_system_status { catlog } {
    global gUserLogSystemStatus

    variable ::nScripts::dose_data
    variable ::nScripts::runs

    set anyChange 0

    ##### beam_size is fake for beam_size_x X beam_size_y
    set motorList [list detector_z beam_size energy attenuation beamstop_z]
    set unitList  [list mm         mm        ev     %           mm]

    foreach motor $motorList unit $unitList {
        if {[user_log_any_change $catlog $motor $unit]} {
            set anyChange 1
        }
    }

    set doseMode [lindex $runs 2]

    if {$doseMode} {
        set storedCounts [lindex $dose_data 1]
        set lastCounts [lindex $dose_data 3]
        if {[string is double -strict $storedCounts] && \
        [string is double -strict $lastCounts]} {
            set doseFactor [format "%.2f" [expr double($storedCounts) / \
            double($lastCounts)]]
            set current_value "on factor $doseFactor"
        } else {
            set current_value "factor invalid"
        }
    } else {
        set current_value "off"
    }
    if {![info exists gUserLogSystemStatus(dose_mode)] || \
    $gUserLogSystemStatus(dose_mode) != $current_value} {
        set gUserLogSystemStatus(dose_mode) $current_value
        set log_contents [format "%-20s %s" "dose mode" $current_value]
        user_log_note $catlog $log_contents
    }
    return $anyChange
}

proc print { outputString } {
        global gDebugComments
        if  { $gDebugComments } {
                catch [puts $outputString ] 
        }
}

proc create_operation_handle { } {
	global gClientId
	global gOperationCounter
	
	incr gOperationCounter
	
	return "$gClientId.$gOperationCounter"
}

proc get_operation_info { } {
	
	set currentLevel [info level]
	set operationHandle ""
	
	while { $currentLevel >= 0 } {
		set command [info level $currentLevel]
		if { [lindex $command 0] == "stoh_start_operation" } {
			set operationName [lindex $command 1]
			set operationHandle [lindex $command 2]
			break
		}
		incr currentLevel -1
	}
	
	if { $operationHandle == "" } {
		print "get_operation_handle failed"
		return error
	}
	
	return "$operationName $operationHandle"
}

proc get_top_operation_info { } {
	
	set currentLevel [info level]
	set operationHandle ""

    for {set i 0} {$i <= $currentLevel} {incr i} {
		set command [info level $i]
		if { [lindex $command 0] == "stoh_start_operation" } {
			set operationName [lindex $command 1]
			set operationHandle [lindex $command 2]
			break
		}
    }
	
	if { $operationHandle == "" } {
		print "get_operation_handle failed"
		return error
	}
	
	return "$operationName $operationHandle"
}
###this can only get name
proc get_local_operation_name { } {
	set currentLevel [info level]
	set operationName ""
	while { $currentLevel >= 0 } {
		set command [info level $currentLevel]
        set first [lindex $command 0]
		if {$first == "stoh_start_operation"} {
			set operationName [lindex $command 1]
			break
		}
        set tail [string range $first end-5 end]
		if {$tail == "_start"} {
			set operationName [string range $first 0 end-6]
			break
		}
		incr currentLevel -1
	}
	
	return $operationName
}
proc send_operation_update { args } {
	set operationInfo [get_operation_info]
    if {[llength $operationInfo] == 2} {
	    dcss2 sendMessage "htos_operation_update $operationInfo $args"
    } else {
        puts "should not call send_operation_update while not in operation"
    }
}

proc get_operation_SID { } {
    set info [get_top_operation_info]
    set handle [lindex $info 1]
    if {$handle == ""} {
        return "OP_HANDLE_NOT_FOUND"
    }
    if {[scan $handle "%d" clientId] != 1} {
        return "BAD_OP_HANDLE"
    }
    return [get_user_session_id $clientId]
}

proc get_operation_user { } {
    global gClient
    set info [get_top_operation_info]
    set handle [lindex $info 1]
    if {$handle == ""} {
        return "OP_HANDLE_NOT_FOUND"
    }
    if {[scan $handle "%d" clientId] != 1} {
        return "BAD_OP_HANDLE"
    }
    if {![info exists gClient($clientId)]} {
        return "NOT_FOUND"
    }

    return $gClient($clientId)
}

proc get_operation_isStaff { } {
    global gClientInfo

    set info [get_top_operation_info]
    set handle [lindex $info 1]
    if {$handle == ""} {
        return 0
    }
    if {[scan $handle "%d" clientId] != 1} {
        return 0
    }
    if {![info exists gClientInfo($clientId,staff)]} {
        return 0
    }
    return $gClientInfo($clientId,staff)
}

## operation is started by BluIce, not by scripting engineer itself
proc client_started_operation { name } {
    global gClient

    set info [get_operation_info]
    if {[llength $info] < 2} {
        return 0
    }

    #### check name ###
    #### if name not match, means it is called by other operations using
    #### $name_start without create new operation
    set op_name [lindex $info 0]
    if {$op_name != $name} {
        return 0
    }

    #### check whether the operation is created by scripting engine
    set op_handle [lindex $info 1]
    set clientID [expr int($op_handle)]
    set clientName $gClient($clientID)
    if {$clientName == "self"} {
        return 0
    }
    return 1
}

proc save_operation_log { key value } {
    global gOperationLog

    set info [get_top_operation_info]
    set opName [lindex $info 0]

    set ts [clock seconds]

    #puts "save_operation_log $opName $key $value"
    set gOperationLog($key,$opName) [list $ts $value]
}
proc clear_operation_log { {opName ""} } {
    if {$opName == ""} {
        set info [get_top_operation_info]
        set opName [lindex $info 0]
    }
    namespace eval $opName {
        global gOperationLog

        if {[info exists logKey]} {
            foreach key $logKey {
                array unset gOperationLog($key,*)
            }
        }
        set logStartTime [clock seconds]
    }
}
proc write_operation_log { {opName ""} } {
    global gOperationLog

    if {$opName == ""} {
        set info [get_top_operation_info]
        set opName [lindex $info 0]
    }
    #puts "write_operation_log $opName"

    if {![info exists ::${opName}::logKey] || \
    ![info exists ::${opName}::logStartTime] || \
    ![info exists ::${opName}::logOperation]} {
        puts "writeOperationLog: $opName skipped, no key or op or start time"
        puts "key: [info exists ::${opName}::logKey]"
        puts "start time: [info exists ::${opName}::logStartTime]"
        puts "op: [info exists ::${opName}::logOperation]"
        return ""
    }

    variable ::${opName}::logStartTime
    variable ::${opName}::logKey
    variable ::${opName}::logOperation

    set fileName opLog_$opName.csv

    ### create one line contents
    set tNow [clock seconds]
    set tNowText [clock format $tNow -format "%D %T"]

    set contents "$tNowText"
    set found 0
    foreach key $logKey {
        ### default value is empty
        set value ""
        foreach op $logOperation {
            if {[info exists gOperationLog($key,$op)]} {
                foreach {ts v} $gOperationLog($key,$op) break
                if {$ts >= $logStartTime} {
                    set value $v
                    if {[string is double -strict $value]} {
                        set value [format "%.4f" $value]
                    }
                    set found 1
                    break
                }
            }
        }
        append contents ",$value"
    }

    if {!$found} {
        log_error not found any operation log key
        return ""
    }

    set header "TimeStamp,[join $logKey ,]"

    set needWriteHeader 1

    if {[file readable $fileName]} {
        if {![catch {open $fileName r} h]} {
            set firstLine [gets $h]
            close $h
            if {$firstLine == $header} {
                set needWriteHeader 0
            }
        }
    }

    if {![catch {open $fileName a} h]} {
        if {$needWriteHeader} {
            puts $h $header
        }
        puts $h $contents
        close $h
        return $fileName
    } else {
        log_error save operation log failed: $h
    }
    #puts "write_operation_log $opName $contents"
    return ""
}

#######################################################
# operation message: 3 
# 1. system global message
# 2. top caller's messge
# 3. local message
proc get_system_message_name { } {
    return system_status
}
proc set_operation_message_name { opName msgName } {
    global gDevice
    set gDevice($opName,msg) $msgName
}
proc get_top_operation_message_name { } {
    global gDevice
    set info [get_top_operation_info]
    if {[llength $info] < 2} {
        return top_operation_msg
    } else {
        set name [lindex $info 0]
        if {[info exists gDevice($name,msg)]} {
            return $gDevice($name,msg)
        } else {
            return ${name}_msg
        }
    }
}
proc get_local_operation_message_name { } {
    set name [get_local_operation_name]
    if {$name == ""} {
        return local_operation_msg
    }
    if {[info exists gDevice($name,msg)]} {
        return $gDevice($name,msg)
    }
    return ${name}_msg
}

proc set_operation_message { contents {local 1} {top 0} {sys 0} } {
}


proc wait_for_encoder { encoder {timeout ""} } {
    global gDevice

	if { ![isEncoder $encoder]  } {
		log_error "encoder $encoder does not exist!"
		return -code error ${encoder}_doesNotExist
	}
    eval wait_for_components $encoder $timeout

    return $gDevice($encoder,position)
}

proc wait_for_shutters { shutterList {timeout ""} } {
    foreach device $shutterList {
		if { ![isShutter $device]  } {
			log_error "shutter $device does not exist!"
			return -code error ${device}_doesNotExist
		}
    }
    eval wait_for_components $shutterList $timeout
}

proc wait_for_ion_chambers { ion_chamberList {timeout ""} } {
    foreach device $ion_chamberList {
		if { ![isIonChamber $device]  } {
			log_error "ion_chamber $device does not exist!"
			return -code error ${device}_doesNotExist
		}
    }
    eval wait_for_components $ion_chamberList $timeout
    return [eval get_ion_chamber_counts ion_chamberList]
}

proc wait_for_motors { motorList {timeout ""} } {
    foreach device $motorList {
		if { ![isMotor $device]  } {
			log_error "motor $device does not exist!"
			return -code error ${device}_doesNotExist
		}
    }
    eval wait_for_components $motorList $timeout
}

proc error_if_moving { args } {
    foreach device $args {
	    if {![isMotor $device]} {
		    log_error "motor $device does not exist!"
		    return -code error ${device}_doesNotExist
	    }
        global gDevice
        if {$gDevice($device,status) != "inactive"} {
		    log_error "motor $device moving!"
		    return -code error ${device}_moving
        }
    }
}

proc wait_for_motor_if_moving { device {timeout ""} } {
	if { ![isMotor $device]  } {
		log_error "motor $device does not exist!"
		return -code error ${device}_doesNotExist
	}
    global gDevice
    if {$gDevice($device,status) != "inactive"} {
        eval wait_for_components $device $timeout
    }
}

#wait_for_strings is not the same as other waits.
#it will set status to waiting
#means it will wait for changes from now.
#Other waitings will return immediately if status is inactive
proc wait_for_strings { args } {
    global gDevice

    ###last one maybe a timeout
    set timeout [lindex $args end]
    if {[string is integer -strict $timeout] && ![isDevice $timeout]} {
        set args [lreplace $args end end]
    } else {
        set timeout ""
    }

    foreach device $args {
		if { ![isString $device]  } {
			log_error "string $device does not exist!"
			return -code error ${device}_doesNotExist
		}
    }
    eval check_device_controller_online $args

    foreach device $args {
        set gDevice($device,status) waiting_for_change
    }
	eval wait_for_components $args $timeout
}

#field: < 0: whole contents,
#field: >=0: check using [lindex $contents $field]
proc wait_for_string_contents { stringName value { field -1 } {timeout ""} } {
    global gDevice

    set flagNot 0

    if {[string index $stringName 0] == "!"} {
        set flagNot 1
        set stringName [string range $stringName 1 end]

        puts "wait for string $stringName != $value"
    }

    if {![isString $stringName]} {
        log_error wait_for_string_contents: $stringName is not a string
        return -code error "${stringName}_is_not_a_string"
    }
    if {$gDevice($stringName,lastResult) == "disconnected"} {
        log_error wait_for_string_contents: $stringName disconnected
        return -code error "${stringName}_not_ready"
    }

    set current_value $gDevice($stringName,contents)
    log_note "current_value: $current_value"
    if {$field >= 0} {
        set current_value [lindex $current_value $field]
    }

    while {1} {
        if {$flagNot} {
            if {$current_value != $value} {
                break
            }
        } else {
            if {$current_value == $value} {
                break
            }
        }

        log_note wait_for_string_content: wait for string to change
        eval wait_for_strings $stringName $timeout
        log_note "wait_for_string_content: out of wait_for_stings"
        set current_value $gDevice($stringName,contents)
        if {$field >= 0} {
            set current_value [lindex $current_value $field]
        }
    }
    return normal
}

proc dumpBinary { binaryString {rowWidth 16} {valueFormat "%02X "} } {

	set characters [string length $binaryString]

	binary scan $binaryString "c$characters" asciiValues
	#puts $asciiValues
	
	set row ""
	set textViewer ""
	for { set cnt 0} { $cnt < $characters} { incr cnt } {
		set asciiValue [lindex $asciiValues $cnt]
		if { $asciiValue < 0 } {
			set asciiValue [expr ( $asciiValue + 0x100 ) % 0x100 ]
		}
		append row [format $valueFormat $asciiValue]
		set character [format "%c" $asciiValue]
		
		if {[string is wordchar $character]} {
			append textViewer $character
		} else {
			append textViewer "."
		}
		
		if { ($cnt+1)%$rowWidth == 0 } {
			puts "$row : $textViewer"
			set row ""
			set textViewer ""
		}
	}
	
	puts "$row : $textViewer"
}

#This function looks up the call stack, and tries to determine 4 things:
# 1) Is this function called by an operation or a scripted device?
# 2) What is the name of the operation or scripted device
# 3) Has this operation or scripted device been aborted?
# 4) If this is an operation, what is the operation handle?
proc get_script_info {args } {
	global gOperation
	global gDevice

	set currentLevel [info level]
	set operationHandle ""
	set scriptType ""
	
	while { $currentLevel >= 0 } {
		set command [info level $currentLevel]
		#puts " ********* $command ***********"
		if { [lindex $command 0] == "stoh_start_operation" } {
			set scriptType "operation"
			set scriptName [lindex $command 1]
			set operationHandle [lindex $command 2]
			#if the abort count has changed since the script operation started,
			if { $gOperation($operationHandle,abortCount) != $gDevice(abortCount) } {
				set abortStatus "aborted"
			} else {
				set abortStatus "not_aborted"
			}
			break
		}
		
		if { [lindex $command 0] == "stoh_start_motor_move" } {
			set scriptType "device"
			set scriptName [lindex $command 1]
			set operationHandle "0"
            if {[llength $command] >= 4} {
                #### to pass down the operation handle
                #### started by self
			    set operationHandle [lindex $command 3]
            }
			
			#if the abort count has changed since the device was started,
			if { $gDevice($scriptName,abortCount) != $gDevice(abortCount) } {
				set abortStatus "aborted"
			} else {
				set abortStatus "not_aborted"
			}
			break
		}

		if { [lindex $command 0] == "stoh_read_ion_chambers" } {
			set scriptType "device"
			set scriptName "message_handlers"
			set operationHandle "0"
			
            set firstIonChamber [lindex $command 3]
			#if the abort count has changed since the device was started,
			if { $gDevice($firstIonChamber,abortCount) != $gDevice(abortCount) } {
				set abortStatus "aborted"
			} else {
				set abortStatus "not_aborted"
			}
			break
		}

		if { [lindex $command 0] == "stoh_set_shutter_state" } {
			set scriptType "device"
			set scriptName "serialShutter"
			set operationHandle "0"
			
            set deviceName [lindex $command 1]
			#if the abort count has changed since the device was started,
			if { $gDevice($deviceName,abortCount) != $gDevice(abortCount) } {
				set abortStatus "aborted"
			} else {
				set abortStatus "not_aborted"
			}
			break
		}

		if { [lindex $command 0] == "stoh_get_encoder" } {
			set scriptType "device"
			set scriptName [lindex $command 1]
			set operationHandle "0"
			
			#if the abort count has changed since the device was started,
			if { $gDevice($scriptName,abortCount) != $gDevice(abortCount) } {
				set abortStatus "aborted"
			} else {
				set abortStatus "not_aborted"
			}
			break
		}
		incr currentLevel -1
	}
	
	if { $scriptType == "" } {
		#print "get_script_info failed"
		return error
	}

	puts "$scriptType $scriptName $abortStatus $operationHandle"
	return "$scriptType $scriptName $abortStatus $operationHandle"
}

### used in cases like "Stop" only skip part of operation
proc clear_operation_stop_flag { } {
	global gOperation

    #log_note "get_operation_stop_flag"

    set info [get_script_info]
    foreach {type name status handle} $info break

    if {$type != "operation"} {
        return
    }
    #log_note "return $gOperation($name,stopFlag)"
    set gOperation($name,stopFlag) 0
}
proc get_operation_stop_flag { } {
	global gOperation

    #log_note "get_operation_stop_flag"

    set info [get_script_info]
    foreach {type name status handle} $info break

    if {$type != "operation"} {
        return 0
    }
    #log_note "return $gOperation($name,stopFlag)"
    return $gOperation($name,stopFlag)
}

proc get_client_id { } {
    set handle [lindex [get_script_info] 3]
    set dot_index [string first . $handle]
    if {$dot_index == 0} {
        set handle 0
    } elseif {$dot_index > 0} {
        incr dot_index -1
        set handle [string range $handle 0 $dot_index]
    }
    return $handle
}

proc check_device_controller_online { args } {
    global gDevice
    global gHwHost

    foreach device $args {
        if {![info exists gDevice($device,hardwareHost)]} {
            return -code error "unknown device $device"
        }
        set host $gDevice($device,hardwareHost)

        if {![info exists gHwHost($host,status)]} {
            return -code error "unknown host $host for $device"
        }
    
        if {$gHwHost($host,status) != "online" } {
            return -code error \
            "hardware host {$host} for $device $gHwHost($host,status)"
        }
    }
}

proc componentTimeoutCallback { args } {
	global gDevice

    log_error timeout for $args

	foreach device $args {
		if { $gDevice($device,status) != "inactive" } {
            switch -exact -- $gDevice($device,type) {
                real_motor -
                pseudo_motor {
                    dcss2 sendMessage "htos_motor_move_completed $device $gDevice($device,scaled) timeout"
                }
                ion_chamber {
                    dcss2 sendMessage "htos_report_ion_chambers 0 $device timeout"
                }
                encoder {
				    dcss2 sendMessage "htos_get_encoder_completed $device $gDevice($device,position) timeout"
                }
                shutter {
                    dcss2 sendMessage "htos_report_shutter_state $device $gDevice($device,state) timeout"
                }
                string {
                    dcss2 sendMessage "htos_set_string_completed $device timeout $gDevice($device,contents)"
                }
            }
            set hardwareHost $gDevice($device,hardwareHost)
            if {$hardwareHost != ""} {
                log_severe $device timeout on $hardwareHost
            } else {
                log_severe $device timeout
            }
		}
    }
}
#this is generic wait
#it check gDevice(XXXX,status) and gDevice(XXXX,lastResult)
proc wait_for_components { args } {
	global gDevice

    ###last one maybe a timeout
    set timeout [lindex $args end]
    if {[string is integer -strict $timeout] && ![isDevice $timeout]} {
        set args [lreplace $args end end]
        log_note new args $args timeout $timeout
    } else {
        set timeout 0
    }

	set errorMsg normal

	foreach obj $args {
		if { ![info exists gDevice($obj,status)] } {
			log_error "$obj does not exist"
			return -code error unknown_component_$obj
		}
	}

    if {$timeout > 0} {
        set afterID [after $timeout componentTimeoutCallback $args]
    } else {
        set afterID ""
    }

	foreach obj $args {
		# wait for obj to become inactive or aborting
		while { $gDevice($obj,status) != "inactive" } {
			vwait gDevice($obj,status)
		}
		
		# set error flag if obj is motor that stopped abnormally
		if { $gDevice($obj,lastResult) != "normal" } {
            set errorMsg ${obj}_$gDevice($obj,lastResult)
            #log_note bad result for $obj
        }
	}
    after cancel $afterID

	# return an error if any motor stopped abnormally
	if { $errorMsg != "normal" } {
		return -code error $errorMsg
	}
}

proc generic_DFT {in_data} {
    # First convert to internal format
    set dataL [list]
    set n 0
    foreach datum $in_data {
        if {[llength $datum] == 1} then {
            lappend dataL $datum 0.0
        } else {
            lappend dataL [lindex $datum 0] [lindex $datum 1]
        }
        incr n
    }

    # Then compute a list of n'th roots of unity (explanation below)
    set rootL [DFT_make_roots $n -1]

    # Check if the input length is a power of two.
    set p 1
    while {$p < $n} {set p [expr {$p << 1}]}
    # By construction, $p is a power of two. If $n==$p then $n is too.

    # Finally compute the transform using fast_DFT or slow_DFT,
    # and convert back to the input format.
    set res [list]
    foreach {Re Im} [
        if {$p == $n} then {
            fast_DFT $dataL $rootL
        } else {
            slow_DFT $dataL $rootL
        }
    ] {
        lappend res [list $Re $Im]
    }
    return $res
}

proc generic_inverse_DFT {in_data} {
    # First convert to internal format
    set dataL [list]
    set n 0
    foreach datum $in_data {
        if {[llength $datum] == 1} then {
            lappend dataL $datum 0.0
        } else {
            lappend dataL [lindex $datum 0] [lindex $datum 1]
        }
        incr n
    }

    # Then compute a list of n'th roots of unity (explanation below)
    set rootL [DFT_make_roots $n 1]

    # Check if the input length is a power of two.
    set p 1
    while {$p < $n} {set p [expr {$p << 1}]}
    # By construction, $p is a power of two. If $n==$p then $n is too.

    # Finally compute the transform using fast_DFT or slow_DFT,
    # divide by input data length to correct the amplitudes,
    # and convert back to the input format.
    set res [list]
    foreach {Re Im} [
        # $p is power of two. If $n==$p then $n is too.
        if {$p == $n} then {
            fast_DFT $dataL $rootL
        } else {
            slow_DFT $dataL $rootL
        }
    ] {
        lappend res [list [expr {$Re/$n}] [expr {$Im/$n}]]
    }
    return $res
}

proc DFT_make_roots {n sign} {
    set res [list]
    for {set k 0} {2*$k < $n} {incr k} {
        set alpha [expr {2*3.1415926535897931*$sign*$k/$n}]
        lappend res [expr {cos($alpha)}] [expr {sin($alpha)}]
    }
    return $res
}
proc fast_DFT {dataL rootL} {
    if {[llength $dataL] == 8} then {
        foreach {Re_z0 Im_z0 Re_z1 Im_z1 Re_z2 Im_z2 Re_z3 Im_z3} $dataL {break}
        if {[lindex $rootL 3] > 0} then {
            return [list\
              [expr {$Re_z0 + $Re_z1 + $Re_z2 + $Re_z3}] [expr {$Im_z0 + $Im_z1 + $Im_z2 + $Im_z3}]\
              [expr {$Re_z0 - $Im_z1 - $Re_z2 + $Im_z3}] [expr {$Im_z0 + $Re_z1 - $Im_z2 - $Re_z3}]\
              [expr {$Re_z0 - $Re_z1 + $Re_z2 - $Re_z3}] [expr {$Im_z0 - $Im_z1 + $Im_z2 - $Im_z3}]\
              [expr {$Re_z0 + $Im_z1 - $Re_z2 - $Im_z3}] [expr {$Im_z0 - $Re_z1 - $Im_z2 + $Re_z3}]]
        } else {
            return [list\
              [expr {$Re_z0 + $Re_z1 + $Re_z2 + $Re_z3}] [expr {$Im_z0 + $Im_z1 + $Im_z2 + $Im_z3}]\
              [expr {$Re_z0 + $Im_z1 - $Re_z2 - $Im_z3}] [expr {$Im_z0 - $Re_z1 - $Im_z2 + $Re_z3}]\
              [expr {$Re_z0 - $Re_z1 + $Re_z2 - $Re_z3}] [expr {$Im_z0 - $Im_z1 + $Im_z2 - $Im_z3}]\
              [expr {$Re_z0 - $Im_z1 - $Re_z2 + $Im_z3}] [expr {$Im_z0 + $Re_z1 - $Im_z2 - $Re_z3}]]
        }
    } elseif {[llength $dataL] > 8} then {
        set evenL [list]
        set oddL [list]
        foreach {Re_z0 Im_z0 Re_z1 Im_z1} $dataL {
            lappend evenL $Re_z0 $Im_z0
            lappend oddL $Re_z1 $Im_z1
        }
        set squarerootL [list]
        foreach {Re_omega0 Im_omega0 Re_omega1 Im_omega1} $rootL {
            lappend squarerootL $Re_omega0 $Im_omega0
        }
        set lowL [list]
        set highL [list]
        foreach\
          {Re_y0 Im_y0}       [fast_DFT $evenL $squarerootL]\
          {Re_y1 Im_y1}       [fast_DFT $oddL $squarerootL]\
          {Re_omega Im_omega} $rootL {
            set Re_y1t [expr {$Re_y1 * $Re_omega - $Im_y1 * $Im_omega}]
            set Im_y1t [expr {$Im_y1 * $Re_omega + $Re_y1 * $Im_omega}]
            lappend lowL  [expr {$Re_y0 + $Re_y1t}] [expr {$Im_y0 + $Im_y1t}]
            lappend highL [expr {$Re_y0 - $Re_y1t}] [expr {$Im_y0 - $Im_y1t}]
        }
        return [concat $lowL $highL]
    } elseif {[llength $dataL] == 4} then {
        foreach {Re_z0 Im_z0 Re_z1 Im_z1} $dataL {break}
        return [list\
          [expr {$Re_z0 + $Re_z1}] [expr {$Im_z0 + $Im_z1}]\
          [expr {$Re_z0 - $Re_z1}] [expr {$Im_z0 - $Im_z1}]]
    } else {
        return $dataL
    }
}
proc slow_DFT {dataL rootL} {
    set n [expr {[llength $dataL] / 2}]

    # The missing roots are computed by complex conjugating the given
    # roots. If $n is even then -1 is also needed; it is inserted explicitly.
    set k [llength $rootL]
    if {$n % 2 == 0} then {
        lappend rootL -1.0 0.0
    }
    for {incr k -2} {$k > 0} {incr k -2} {
        lappend rootL [lindex $rootL $k]\
          [expr {-[lindex $rootL [expr {$k+1}]]}]
    }

    # This is strictly following the naive formula.
    # The product jk is kept as a separate counter variable.
    set res [list]
    for {set k 0} {$k < $n} {incr k} {
        set Re_sum 0.0
        set Im_sum 0.0
        set jk 0
        foreach {Re_z Im_z} $dataL {
            set Re_omega [lindex $rootL [expr {2*$jk}]]
            set Im_omega [lindex $rootL [expr {2*$jk+1}]]
            set Re_sum [expr {$Re_sum +
              $Re_z * $Re_omega - $Im_z * $Im_omega}]
            set Im_sum [expr {$Im_sum +
              $Im_z * $Re_omega + $Re_z * $Im_omega}]
            incr jk $k
            if {$jk >= $n} then {set jk [expr {$jk - $n}]}
        }
        lappend res $Re_sum $Im_sum
    }
    return $res
}

proc test_DFT {points {real 0} {iterations 20}} {
    set in_dataL [list]
    for {set k 0} {$k < $points} {incr k} {
        if {$real} then {
            lappend in_dataL [expr {2*rand()-1}]
        } else {
            lappend in_dataL [list [expr {2*rand()-1}] [expr {2*rand()-1}]]
        }
    }
    set time1 [time {
        set conv_dataL [generic_DFT $in_dataL]
    } $iterations]
    set time2 [time {
        set out_dataL [generic_inverse_DFT $conv_dataL]
    } $iterations]
    set err 0.0
    foreach iz $in_dataL oz $out_dataL {
        if {$real} then {
            foreach {o1 o2} $oz {break}
            set err [expr {$err + ($i-$o1)*($i-$o1) + $o2*$o2}]
        } else {
            foreach i $iz o $oz {
                set err [expr {$err + ($i-$o)*($i-$o)}]
            }
        }
    }
    return [format "Forward: %s\nInverse: %s\nAverage error: %g"\
      $time1 $time2 [expr {sqrt($err/$points)}]]
}

namespace eval DCSSerial {
    variable wait_reply
    variable reply
    variable after

    namespace export command_response
}

proc DCSSerial::command_response { file_name mode command num_line time_out } {
    variable wait_reply
    variable reply
    variable after

    set display_command [string map {\r " "} $command]

    #log_note "DCSSerial command_response $file_name {$display_command} $num_line $time_out"

    if {[catch {open $file_name r+} handle]} {
        return -code error "failed to open $file_name: $handle"
    }
    if {[catch {fconfigure $handle \
    -blocking off \
    -translation {auto binary} \
    -mode $mode} e]} {
        log_error "error fconfigure $e DCSSerial"
    }
    #log_note "DCSSerial: send out command"
    puts -nonewline $handle $command
    flush $handle
    set reply($handle) ""
    set after($handle) [after $time_out [list DCSSerial::timeout $handle]]
    set wait_reply($handle) waiting
    fileevent $handle readable [list DCSSerial::read $handle $num_line]

    #wait result
    #log_note "DCSSerial: wait for reply"
    ######log who is waiting for what
    vwait [namespace current]::wait_reply($handle)
    #log_note "DCSSerial: out of wait"

    #save info
    set status $wait_reply($handle)
    set result $reply($handle)

    #close up
    fileevent $handle readable {}
    close $handle
    catch {after cancel $after($handle)}
    unset wait_reply($handle)
    unset reply($handle)

    if {$status == "ready"} {
        return $result
    } else {
        return -code error "$status $result"
    }
}
proc DCSSerial::timeout { handle } {
    variable wait_reply
    if {[info exists wait_reply($handle)]} {
        log_warning timeout in DCSSerial
        set wait_reply($handle) timeout
    }
}
proc DCSSerial::read { handle num_line } {
    variable wait_reply
    variable reply
    if {[catch {gets $handle one_line} n]} {
        log_error "read failed $n in DCSSerial"
        set wait_reply($handle) $n
    } elseif {[string length $one_line] == 0} {
        #puts "got empty line"
    } else {
        #log_note "got 1 line length=[string length $one_line]: $one_line"
        lappend reply($handle) $one_line
        if {[llength $reply($handle)] >= $num_line} {
            #puts "mark read done"
            set wait_reply($handle) ready
        }
    }
}

global gEventListener
array set gEventListener [list]
proc registerEventListener { device command } {
    global gEventListener

    if {![info exists gEventListener($device)] || \
    [lsearch $gEventListener($device) $command] < 0} {
        lappend gEventListener($device) $command
    }
}

proc updateEventListeners { device } {
    global gEventListener
    if {[info exists gEventListener($device)]} {
        set listenerList [set gEventListener($device)]
        foreach listener $listenerList {
            if {[catch {eval $listener} errMsg]} {
                puts "DEBUG ERROR: updateEventListeners for $device: $listener: $errMsg"
            }
        }
    }
}

global gAbortCallbacks
set gAbortCallbacks [list]
proc registerAbortCallback { command } {
    global gAbortCallbacks

    if {[lsearch $gAbortCallbacks $command] < 0} {
        lappend gAbortCallbacks $command
    }
    puts "registerAbort: $command"
    puts "new list: $gAbortCallbacks"
}

#####call back when master changes
global gMasterListener
set gMasterListener [list]
proc registerMasterCallback { command } {
    global gMasterListener
    lappend gMasterListener $command
}

#we only support motors for now.
#you can add support to other device too
# an "after" script will be setup in following stype
# if {[eval $condition]} {
# after $timeAfter $command
#}
# the command is executed in root namespace ::
proc registerTimerService { tsName timeAfter args } {
    global gTimerService

    puts "registerTimerService $tsName $timeAfter $args"

    ###check definition
    if {[info commands ${tsName}_condition] == ""} {
        puts "timer ERROR ${tsName}_condition not defined"
        return
    }
    if {[info commands ${tsName}_command] == ""} {
        puts "timer ERROR ${tsName}_command not defined"
        return
    }

    if {[llength $args] <= 0} {
        puts "timer ERROR no triggerDevice in input"
        return
    }

    foreach triggerDevice $args {
        if {![info exists gTimerService($triggerDevice),name]} {
            set gTimerService($triggerDevice,name) [list]
            set gTimerService($triggerDevice,command) [list]
            set gTimerService($triggerDevice,condition) [list]
            set gTimerService($triggerDevice,timeAfter) [list]
        } else {
            set allOK 1
            set ll [llength $gTimeService($triggerDevice,command)]
            if {$ll != [llength $gTimeService($triggerDevice,condition)]} {
                puts "ERROR timerService condition list wrong legnth"
                set allOK 0
            }
            if {$ll != [llength $gTimeService($triggerDevice,timeAfter)]} {
                puts "ERROR timerService timeAfter list wrong legnth"
                set allOK 0
            }
            if {$ll != [llength $gTimeService($triggerDevice,name)]} {
                puts "ERROR timerService name list wrong legnth"
                set allOK 0
            }
            if {!$allOK} {
                set gTimerService($triggerDevice,command) [list]
                set gTimerService($triggerDevice,condition) [list]
                set gTimerService($triggerDevice,timeAfter) [list]
                set gTimerService($triggerDevice,name) [list]
            }
        }

        if {[lsearch $tsName $gTimerService($triggerDevice,name)] >= 0} {
            puts "ERROR $tsName already registered with $triggerDevice"
            continue
        }
        append gTimerService($triggerDevice,command) ${tsName}_command
        append gTimerService($triggerDevice,condition) ${tsName}_condition
        append gTimerService($triggerDevice,timeAfter) $timeAfter
        append gTimerService($triggerDevice,name) $tsName
    }
        ###may registered with other device already
    if {![info exists gTimerService(afterIDs,$tsName)]} {
        set gTimerService(afterIDs,$tsName) ""
    }
}
proc triggerTimerService { triggerDevice } {
    if {[catch {
        global gTimerService
        if {[info exists gTimerService($triggerDevice,command)]} {
            foreach command $gTimerService($triggerDevice,command) \
            condition $gTimerService($triggerDevice,condition) \
            timeAfter $gTimerService($triggerDevice,timeAfter) \
            tsName $gTimerService($triggerDevice,name) {
                set ID $gTimerService(afterIDs,$tsName)
                if {$ID != ""} {
                    after cancel $ID
                    set gTimerService(afterIDs,$tsName) ""
                }
                if {[eval $condition]} {
                    set gTimerService(afterIDs,$tsName) \
                    [after $timeAfter $command]
                    #log_note "timer setup: after $timeAfter do $command"
                } else {
                    #log_note "skip timer setup: after $timeAfter do $command"
                }
            }
        }
    } errMsg]} {
        log_error "error in timer process: $errMsg"
    }
}
proc loadLaserChannelConfig { } {
    global gLaserControl
    global gLaserRead

    foreach name [list goniometer sample \
    table_vert_1 table_vert_2 table_horz_1 table_horz_2] {
        if {![info exists gLaserControl($name,BOARD)] || \
        ![info exists gLaserControl($name,CHANNEL)]} {
            set gLaserControl($name,BOARD) -1
            set gLaserControl($name,CHANNEL) -1
            set cfg [::config getStr laser.$name.control]
            puts "control for $name: $cfg"
            if {[llength $cfg] >= 2} {
                set gLaserControl($name,BOARD) [lindex $cfg 0]
                set gLaserControl($name,CHANNEL) [lindex $cfg 1]
                puts "$name $gLaserControl($name,BOARD) $gLaserControl($name,CHANNEL)"
            }
        }
        if {![info exists gLaserRead($name,BOARD)] || \
        ![info exists gLaserRead($name,CHANNEL)]} {
            set gLaserRead($name,BOARD) -1
            set gLaserRead($name,CHANNEL) -1
            set cfg [::config getStr laser.$name.read]
            puts "read for $name: $cfg"
            if {[llength $cfg] >= 2} {
                set gLaserRead($name,BOARD) [lindex $cfg 0]
                set gLaserRead($name,CHANNEL) [lindex $cfg 1]
                puts "$name $gLaserControl($name,BOARD) $gLaserControl($name,CHANNEL)"
            }
        }
    }
}
proc decideADCCard { } {
    global gOldADCCardExists
    global gHwHost

    if {[info exists gOldADCCardExists]} {
        return
    }
    if {[info exists gHwHost(ADAC5500,status)]} {
        puts "OLD ADAC CARD EXISTS"
        set gOldADCCardExists 1
    } else {
        set gOldADCCardExists 0
        puts "NO OLD ADAC CARD"
    }
}
proc updateXFormStatusFile { new_image_name } {
    #### for adxv with -autoload option
    set fn [::config getStr adxv.xformstatusfile]
    if {$fn != ""} {
        log_info writing xformstatusfile: $fn
        if {[catch {
            global xform_count
            ###### copied from ALS ####
            if {![info exists xform_count] || \
            ![string is integer -strict $xform_count] || \
            $xform_count < 1} {
                set xform_count 1
                catch {
                    set h [open $fn r]
                    set contents [read $h]
                    close $h
                    scan $contents "%d" xform_count
                }
            }
            set xform_count [expr ($xform_count % 10 ) + 1]
            set h [open $fn w]
            puts $h "$xform_count $new_image_name"
            close $h
            log_info new xformstatusfile contents: $xform_count $arg2
        } errMsg]} {
            log_error write adxv XFORMSTATUSFILE failed: $errMsg
        }
    }
}

##########################################################################
########### special units conversion for standardVirtualIonChamber
##########################################################################
proc unitsForIonChamber {index value time} {
    set result $value
    if {[catch {
        switch -exact -- $index {
            1 {
                #### for house air pressure
                #### 0.5v===0.0 psi
                #### 5.5v===200 psi
                set result [expr ($value - 0.5) * 40.0]
            }
            2 {
                #### for i2 to flux
                global gFluxIonChamberTimeScaled
                variable ::fluxLUT::last_reading
                variable ::fluxLUT::condition

                if {$gFluxIonChamberTimeScaled} {
                    set last_reading [expr $value / $time * \
                    $condition(integration_time)]

                } else {
                    set last_reading $value
                }
                puts "i_flux: last_reading=$last_reading"
	            set result [namespace eval nScripts flux_calculate]
            }
        }
    } errMsg]} {
        puts "convertion for ionchamber {$index $value $time} failed: $errMsg"
        set result $value
    }
    return $result
}

proc saveSystemSnapshot { userName_ SID_ path_ } {
    if {[catch {
#yangx?        updateAllEncoders
#yangx?        updateCommonIonChambers
        set contents [brief_dump_database]
        impWriteFile $userName_ $SID_ $path_ $contents
    } errMsg]} {
        puts "failed to saveSystemSnapshot: $errMsg"
    }
}
proc updateAllEncoders { } {
    global gDevice

    set encoderList [get_set gDevice(encoderList)]
    foreach encoder $encoderList {
        get_encoder $encoder
    }
    eval wait_for_devices $encoderList
}
proc updateCommonIonChambers { } {
    global gDevice
    global gCommonIonChamberList

    if {$gCommonIonChamberList == ""} {
        set ionChamberList [get_set gDevice(ionChamberList)]
        set commonList [::config getList ionChamber.common]
        set commonList [eval concat $commonList]
        foreach ic $ionChamberList {
            set common 0
            foreach p $commonList {
                if {[string match $p $ic]} {
                    set common 1
                    break
                }
            }
            if {$common} {
                lappend gCommonIonChamberList $ic
            }
        }
        puts "common ion_chamber list: $gCommonIonChamberList"
    }
    if {$gCommonIonChamberList != ""} {
        eval read_ion_chambers 0.1 $gCommonIonChamberList
        eval wait_for_devices $gCommonIonChamberList
    }
}

proc getEnergyMotorName { } {
    global gMotorEnergy

    return $gMotorEnergy
}
proc timeStampForFileName { } {
    return [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
}
proc swapIfBacklash { motor startRef endRef } {
    upvar $startRef start
    upvar $endRef   end
    
    if {![isDeviceType real_motor $motor]} {
        return 0
    }
    set back [getBacklashScaledValue $motor]
    if {![getBacklashEnableValue $motor] || \
    [getBacklashScaledValue $motor] == 0} {
        return 0
    }
    
    set needSwap 0
    if {$back < 0} {
        if {$end > $start} {
            set needSwap 1
        }
    } else {
        if {$end < $start} {
            set needSwap 1
        }
    }
    if {$needSwap} {
        set temp  $start
        set start $end
        set end   $temp
    }

    return $needSwap
}

proc getScrabbleForFilename { } {
    set i [clock clicks]

    set t [format "%X" $i]
    set t [string map {0 X 1 Y 2 Z 3 U 4 V 5 W 6 R 7 S 8 T 9 Q} $t]
    return $t
}

proc cleanupOldFiles { dir pattern {time_span {}} } {
    set fList [glob -directory $dir -types f -nocomplain $pattern]

    if {$time_span == ""} {
        foreach f $fList {
            if {[catch {
                file delete -force $f
                log_note deleted old file $f
                ### this can be aborted
                wait_for_time 0
            } errMsg]} {
                if {[string first aborted $errMsg] >= 0} {
                    return -code error aborted
                }
                log_warning failed to delete old file $f: $errMsg
                continue
            }
        }
        return
    }

    set span [timespanToSecond $time_span]
    set tNow [clock seconds]
    set tThreshold [expr $tNow - $span]

    foreach f $fList {
        if {[catch {
            set ft [file mtime $f]
            if {$ft < $tThreshold} {
                file delete -force $f
                log_note deleted old file $f
                wait_for_time 0
            }
        } errMsg] == 1} {
            if {[string first aborted $errMsg] >= 0} {
                return -code error aborted
            }
            log_warning failed to delete old file $f: $errMsg
            continue
        }
    }
}

# 01/11/12: Mike Soltis asked to change:
# use time0 as long as it is greater than default_min
proc getExposureSetupFromTime { time0 } {
    variable ::nScripts::collect_default

    foreach {defD defT defA minT maxT minA maxA} $collect_default break

    #### here should be $minT
    #set tPrefer $defT
    set tPrefer $minT

    ### try prefered time first
    ### this can be negative
    set a [expr 100.0 * (1.0 - $time0 / $tPrefer)]
    if {$a < $minA} {
        ### use minA and increase time
        set a $minA
        set t [expr $time0 / (1.0 - $a / 100.0)]
        if {$t > $maxT} {
            log_warning exposure time limited to $maxT from $t
            set t $maxT
        }
        ## assumed tPrefer >= minT
    } elseif {$a > $maxA} {
        ###scale down time from tPrefer
        set a $maxA
        set t [expr $time0 / (1.0 - $a / 100.0)]
        if {$t < $minT} {
            log_warning exposure time limited to $minT from $t
            set t $minI
        }
    } else {
        ##$a >= $minA && $a <= $maxA
        set t $tPrefer
    }
    return [list $a $t]
}
proc getCurrentBeamSize { } {
    if {[isString collimator_status]} {
        variable ::nScripts::collimator_status

        foreach {microBeam index width height} $collimator_status break
        if {$microBeam} {
            return [list $width $height]
        }
    }
    global gDevice
    global gMotorBeamWidth
    global gMotorBeamHeight

    set w $gDevice($gMotorBeamWidth,scaled)
    set h $gDevice($gMotorBeamHeight,scaled)

    return [list $w $h]
}
