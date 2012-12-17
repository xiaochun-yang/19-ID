###################################################################
# string cryo_block_constant
# field 0:        max_time
# field 1:        delay for check blocking    minus means no check
# field 2:        delay for check unblocking  minus means no check
# filed 3:        min delay between last unblocking and new block

proc cryoBlock_initialize {} {
    global gLastUnblockingTime
    global gCryoBlockAvailable
    variable cryoBlockOUT_BOARD
    variable cryoBlockOUT_CHANNEL
    variable cryoBlockIN_BOARD
    variable cryoBlockIN_OPEN_CHANNEL
    variable cryoBlockIN_CLOSE_CHANNEL

    set gLastUnblockingTime 0
    set gCryoBlockAvailable 1

    set cryoBlockOUT_BOARD          -1
    set cryoBlockOUT_CHANNEL        -1
    set cryoBlockIN_BOARD           -1
    set cryoBlockIN_OPEN_CHANNEL    -1
    set cryoBlockIN_CLOSE_CHANNEL   -1

    set cfgCtl [::config getStr cryoBlock.control]
    if {[llength $cfgCtl] == 2} {
        foreach {cryoBlockOUT_BOARD cryoBlockOUT_CHANNEL} $cfgCtl break
    } else {
        puts "bad cryoBlock.control in config: $cfgCtl"
    }
    puts "cfgCtl: $cfgCtl"
    set cfgOpen [::config getStr cryoBlock.open_read]
    if {[llength $cfgOpen] == 2} {
        foreach {cryoBlockIN_BOARD cryoBlockIN_OPEN_CHANNEL} $cfgOpen break
    } else {
        puts "bad cryoBlock.open_read in config: $cfgOpen"
    }
    puts "cfgOpen: $cfgOpen"
    set cfgClose [::config getStr cryoBlock.close_read]
    puts "cfgClose $cfgClose"
    if {[llength $cfgClose] == 2} {
        foreach {closeBoard cryoBlockIN_CLOSE_CHANNEL} $cfgClose break

        if {$closeBoard != $cryoBlockIN_BOARD} {
            puts "WARNING: board not match for open and close read"
            set cryoBlockIN_BOARD           -1
            set cryoBlockIN_OPEN_CHANNEL    -1
            set cryoBlockIN_CLOSE_CHANNEL   -1
        }
    } else {
        puts "bad cryoBlock.close_read in config: $cfgClose"
    }

    if {$cryoBlockOUT_BOARD    < 0 || \
    $cryoBlockOUT_CHANNEL      < 0 || \
    $cryoBlockIN_BOARD         < 0 || \
    $cryoBlockIN_OPEN_CHANNEL  < 0 || \
    $cryoBlockIN_CLOSE_CHANNEL < 0} {
        set gCryoBlockAvailable 0
        puts "cryoBlock NOT available on this beamline"
    } else {
        puts "cryoBlock available on this beamline"
        puts "OUT: $cryoBlockOUT_BOARD $cryoBlockOUT_CHANNEL"
        puts "IN: $cryoBlockIN_BOARD $cryoBlockIN_OPEN_CHANNEL $cryoBlockIN_CLOSE_CHANNEL"
    }
}

proc cryoBlock_start { time } {
    global gLastUnblockingTime
    global gCryoBlockAvailable
    variable cryo_block_constant
    variable cryoBlockOUT_BOARD
    variable cryoBlockOUT_CHANNEL

    if {!$gCryoBlockAvailable} {
        log_error cryoBlock not available on this beamline
        return -code error "cryoBlock not available"
    }

    set max_time [lindex $cryo_block_constant 0]
    set min_delay_time [lindex $cryo_block_constant 3]
    if {$max_time == ""} {
        set max_time 10
    }
    if {$min_delay_time == ""} {
        set min_delay_time 8
    }
    if {$time < 0 || $time > $max_time} {
        log_error time must be between 0 and $max_time
        return -code error "time out of range 0-$max_time"
    }

    ##### if user abort, go unblock
    if {[catch {
        log_note block cryo stream
        set op_handle [start_waitable_operation \
        pulseDigOutBit $cryoBlockOUT_BOARD $cryoBlockOUT_CHANNEL 1 $time]

        wait_for_operation_to_finish $op_handle
    } e]} {
        log_warning $e
    }

    #####unblock
    log_note "unblock cryo stream"
    set done 0
    set counter 0
    set mask [expr 1 << $cryoBlockOUT_CHANNEL]
    while {!$done} {
        incr counter
        if {[catch cryoBlock_checkUnblock msg]} {
            log_error $msg
            log_warning retrying unblock cryo stream
            if {$counter > 10} {
                log_error "failed to unblock cryo stream"
                return -code error "failed to unblock"
            }
            set op_handle [start_waitable_recovery_operation \
            setDigOut $cryoBlockOUT_BOARD 0 $mask]

            wait_for_operation_to_finish $op_handle
        } else {
            set done 1
        }
    }
    set gLastUnblockingTime [clock seconds]
}

proc cryoBlock_checkBlock { max_wait } {
    variable cryo_block_constant

    log_note max_wait $max_wait ms

    set wait_time [lindex $cryo_block_constant 1]
    if {$wait_time == ""} {
        set wait_time 0
    }

    if {$wait_time > $max_wait} {
        set wait_time $max_wait
    }

    #skip test if time < 0
    if {$wait_time < 0} {
        return
    }
    if {$wait_time > 0 && $wait_time < 1000} {
        log_note wait $wait_time before check block
        wait_for_time $wait_time
    }
    if {[cryoBlock_getState] != "closed"} {
        return -code error "block stream failed"
    }
}
proc cryoBlock_checkUnblock { } {
    variable cryo_block_constant

    set wait_time [lindex $cryo_block_constant 2]
    if {$wait_time == ""} {
        set wait_time 0
    }

    #skip test if time < 0
    if {$wait_time < 0} {
        return
    }
    if {$wait_time > 0 && $wait_time < 1000} {
        log_note wait $wait_time before check unblock
        wait_for_time $wait_time
    }
    if {[cryoBlock_getState] != "open"} {
        return -code error "unblock stream failed"
    }
}
proc cryoBlock_getState { } {
    variable cryoBlockIN_BOARD
    variable cryoBlockIN_OPEN_CHANNEL
    variable cryoBlockIN_CLOSE_CHANNEL

    set op_handle [start_waitable_recovery_operation getDig $cryoBlockIN_BOARD]
    set result [wait_for_operation_to_finish $op_handle]
    set dataOnly [lrange $result 1 end]

    set isOpen  [lindex $dataOnly $cryoBlockIN_OPEN_CHANNEL]
    set isClose [lindex $dataOnly $cryoBlockIN_CLOSE_CHANNEL]

    if {$isOpen == 1 && $isClose == 0} {
        log_note "not blocked"
        return open
    } elseif {$isOpen == 0 && $isClose == 1} {
        log_note "blocked"
        return closed
    } else {
        log_error "bad state isOpen=$isOpen isClose=$isClose"
        return -code error "bad state isOpen=$isOpen isClose=$isClose"
    }
}
