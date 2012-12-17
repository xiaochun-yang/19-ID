#string serial_shutter_const will hold following fields
#/dev/ttyM0 /dev/ttyM1 9600,n,8,1 3 2000
# field 0: first serial port for filters
# field 1: second serial port for filters
# field 2: serial port mode
# field 3: timeout in milliseconds
# field 4: retry times before report error
# field 5: delay between retries

proc serial_shutter_get_constant { name } {
    variable ::nScripts::serial_shutter_const
    switch -exact -- $name {
        device0 {
            #file name to open. normally /dev/ttyM0
            return [lindex $serial_shutter_const 0]
        }
        device1 {
            #file name to open. normally /dev/ttyM1
            return [lindex $serial_shutter_const 1]
        }
        mode {
            #RS232 config: 9600,n,8,1
            return [lindex $serial_shutter_const 2]
        }
        time_out {
            #timeout in milliseconds for each reply
            return [lindex $serial_shutter_const 3]
        }
        retry {
            return [lindex $serial_shutter_const 4]
        }
		delay {
            return [lindex $serial_shutter_const 5]
		}
        default {
            return -code error "bad name $name for cryojet constant"
        }
    }
}

proc serialShutter_initialize {} {
	variable serailShutterPrivateMAX_BOARD
	variable serailShutterPrivateCHANNEL_PER_BOARD
	variable serailShutterPrivateMODULE PFCU00

	set serailShutterPrivateMAX_BOARD 2
	set serailShutterPrivateCHANNEL_PER_BOARD 4

	##uncomment after DEBUG
	#after 1000 "namespace eval nScripts serialShutterPoll"
}

#all operation will end  up calling serialShutter_get_status
proc serialShutter_start { sub_command args } {
    switch -exact -- $sub_command {
        insert {
            if {[llength $args] != 1} {
                return -code error "wrong # arguments"
            }
			#return [serialShutterWrite 1 $args]
			return [serialShutterInsert $args]
        }
        remove {
            if {[llength $args] != 1} {
                return -code error "wrong # arguments"
            }
			#return [serialShutterWrite 0 $args]
			return [serialShutterRemove $args]
        }
        get_status {
            return [serialShutterGetStatus]
        }
        default {
            return -code error "$sub_command not supported"
        }
    }
}
proc serialShutterWrite { insert index } {
	variable serailShutterPrivateMAX_BOARD
	variable serailShutterPrivateCHANNEL_PER_BOARD
	variable serailShutterPrivateMODULE PFCU00

	#log_note serialShutterWrite $insert $index

	if {![info exists serailShutterPrivateCHANNEL_PER_BOARD] || \
	![string is integer -strict $serailShutterPrivateCHANNEL_PER_BOARD] || \
	$serailShutterPrivateCHANNEL_PER_BOARD <= 0} {
		set serailShutterPrivateCHANNEL_PER_BOARD 4
	}

	set device_index  [expr $index / $serailShutterPrivateCHANNEL_PER_BOARD]
	set channel_index [expr $index % $serailShutterPrivateCHANNEL_PER_BOARD]

	if {$device_index < 0 || $device_index >= $serailShutterPrivateMAX_BOARD} {
		return -code error "index wrong: device_index=$device_index"
	}

	###generate the command
	set value 0
	if {$insert} {
		set value 1
	}
	set cmd "!$serailShutterPrivateMODULE W"
	set mask [string repeat = $serailShutterPrivateCHANNEL_PER_BOARD]
	set mask [string replace $mask $channel_index $channel_index $value]
	append cmd $mask
	append cmd "\r"

	return [serialShutter_send_command $device_index $cmd]
}

###only support 1 line of command
proc serialShutter_send_command { device_index command } {
	variable serailShutterPrivateMODULE PFCU00

	#log_note serialShutter_send_command $device_index $command

    #generate correct reply pattern
    set reply_pattern "%$serailShutterPrivateMODULE OK (\[0-3\]{4}) DONE"
    set reply_pattern2 "(\[0-3\]{4}) DONE"

    #### get config
    set filename [serial_shutter_get_constant device$device_index]
    set mode [serial_shutter_get_constant mode]
    if {[catch {serial_shutter_get_constant time_out} time_out]} {
        log_warning no time_out defined in string serial_shutter_const
        set time_out 2000
    }
    if {[catch {serial_shutter_get_constant retry} retry]} {
        log_warning no retry defined in string serial_shutter_const $retry
        set retry 0
    }
    incr retry
    if {[catch {serial_shutter_get_constant delay} delay]} {
        log_warning no delay defined in string serial_shutter_const $retry
        set delay 2000
    }
	set success 0
    for {set i 0} {$i < $retry} {incr i} {
        if {$i > 0} {
            log_warning "communication to serial Shutter failed, retrying"
        }
		#log_note file: $filename mode:$mode cmd:$command timeout:$time_out
		if {[catch {
        	set result \
			[DCSSerial::command_response $filename $mode $command 1 $time_out]
			set result [lindex $result 0]
			#log_note com result:$result
        	####check result with pattern
			if {[regexp $reply_pattern $result dummy status]} {
				#log_note got it: $status
				set success 1
			} elseif {[regexp $reply_pattern2 $result dummy status]} {
				log_note got it in simple pattern: $status
				set success 1
			} else {
				log_warning reply: $result not match pattern
			}
		} errorMsg]} {
			log_warning serial shutter communication error: $errorMsg
		}
		if {$success} {
			return $status
		}
		log_note not success, delay $delay
		wait_for_time $delay
    }
	return -code error "serial communication failed for shutters"
}
proc serialShutterGetStatus { } {
	variable serailShutterPrivateMAX_BOARD
	variable serailShutterPrivateMODULE PFCU00
	
	#log_note serialshutterGetStatus

	set cmd "!$serailShutterPrivateMODULE F\r"

	set result ""
	for {set i 0} {$i < $serailShutterPrivateMAX_BOARD} {incr i} {
		append result [serialShutter_send_command $i $cmd]
	}

	#log_note result $result
	return $result
}
proc serialShutterInsert { index } {
	variable serailShutterPrivateMAX_BOARD
	variable serailShutterPrivateCHANNEL_PER_BOARD
	variable serailShutterPrivateMODULE PFCU00

	#log_note serialShutterInsert $index

	if {![info exists serailShutterPrivateCHANNEL_PER_BOARD] || \
	![string is integer -strict $serailShutterPrivateCHANNEL_PER_BOARD] || \
	$serailShutterPrivateCHANNEL_PER_BOARD <= 0} {
		set serailShutterPrivateCHANNEL_PER_BOARD 4
	}

	set device_index  [expr $index / $serailShutterPrivateCHANNEL_PER_BOARD]
	set channel_index [expr $index % $serailShutterPrivateCHANNEL_PER_BOARD]

	if {$device_index < 0 || $device_index >= $serailShutterPrivateMAX_BOARD} {
		return -code error "index wrong: device_index=$device_index"
	}

	###generate the command
	set cmd "!$serailShutterPrivateMODULE I[expr $channel_index + 1]\r"

	set result [serialShutter_send_command $device_index $cmd]
	set readback [string index $result $channel_index]
	switch -exact -- $readback {
		1 {
			return OK
		}
		0 {
			return -code error "insert failed: not in"
		}
		2 {
			return -code error "insert failed: open circuit"
		}
		3 {
			return -code error "insert failed: short circuit"
		}
	}
}
proc serialShutterRemove { index } {
	variable serailShutterPrivateMAX_BOARD
	variable serailShutterPrivateCHANNEL_PER_BOARD
	variable serailShutterPrivateMODULE PFCU00

	#log_note serialShutterRemove $index

	if {![info exists serailShutterPrivateCHANNEL_PER_BOARD] || \
	![string is integer -strict $serailShutterPrivateCHANNEL_PER_BOARD] || \
	$serailShutterPrivateCHANNEL_PER_BOARD <= 0} {
		set serailShutterPrivateCHANNEL_PER_BOARD 4
	}

	set device_index  [expr $index / $serailShutterPrivateCHANNEL_PER_BOARD]
	set channel_index [expr $index % $serailShutterPrivateCHANNEL_PER_BOARD]

	if {$device_index < 0 || $device_index >= $serailShutterPrivateMAX_BOARD} {
		return -code error "index wrong: device_index=$device_index"
	}

	###generate the command
	set cmd "!$serailShutterPrivateMODULE R[expr $channel_index + 1]\r"

	set result [serialShutter_send_command $device_index $cmd]
	set readback [string index $result $channel_index]
	#log_note readback: $readback
	switch -exact -- $readback {
		0 {
			return OK
		}
		1 {
			return -code error "remove failed: still in, maybe manual or TTL"
		}
		2 {
			return -code error "remove failed: open circuit"
		}
		3 {
			return -code error "remove failed: short circuit"
		}
	}
}
proc serialShutterUpdate { } {
	global gDevice
	global gShutterMap
	set result [serialShutterGetStatus]

	set ll [llength $gShutterMap]

	for {set i 0} {$i < $ll} {incr i} {
		set name [lindex $gShutterMap $i]
		set value [string index $result $i]
		switch -exact -- $value {
			0 {
				if {$gDevice($name,state) != "open"} {
					::dcss2 sendMessage "htos_report_shutter_state $name open"
				}
			}
			1 {
				if {$gDevice($name,state) != "closed"} {
					::dcss2 sendMessage "htos_report_shutter_state $name closed"
				}
			}
			2 {
				log_error $name open circuit
			}
			3 {
				log_error $name short circuit
			}
		}
	}
}

proc serialShutterPoll { } {
	#log_note polling serial Shutter
	if {[catch serialShutterUpdate errorMsg]} {
		puts "serialShutter poll failed: $errorMsg"
	}
	after 1000 "namespace eval nScripts serialShutterPoll"
}
