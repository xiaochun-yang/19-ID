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

#this package implement all commands that can be used in user-writen
#scripts.
#it is a replacement for old bluice commands.

package provide DCSScriptCommand 1.0  

package require DCSDevice
package require DCSDeviceFactory
package require DCSRunSequenceCalculator

namespace eval nScripts {
    
    variable deviceVariablesInited
    variable deviceFactory
    variable controlSystem
    variable runCalculator

    ### we delay call the initializer so it can get all the devices
    ### including the ones missing in local database dumpfile.
    set deviceVariablesInited 0
    set controlSystem ::dcss
    set runCalculator [::DCS::RunSequenceCalculator \#auto]

    proc trace_motor_shortcut_read { motor element op } {
        variable deviceFactory
        variable $motor
        set obj [$deviceFactory getObjectName $motor]
        set $motor [$obj cget -scaledPosition]
    }
    proc trace_motor_shortcut_write { motor element op } {
        variable deviceFactory
        variable $motor
        set obj [$deviceFactory getObjectName $motor]
        set newPosition [set $motor]
        $obj setScaledPosition $newPosition
    }

    proc trace_string_shortcut_read { stringName element op } {
        variable deviceFactory
        variable $stringName
        set obj [$deviceFactory getObjectName $stringName]
        set $stringName [$obj getContents]
    }
    proc trace_string_shortcut_write { stringName element op } {
        variable deviceFactory
        variable $stringName
        set obj [$deviceFactory getObjectName $stringName]
        $obj sendContentsToServer [set $stringName]
    }

    proc init_device_variables { } {
        variable deviceVariablesInited
        variable deviceFactory

        if {$deviceVariablesInited} {
            return
        }
        set deviceFactory [::DCS::DeviceFactory::getObject]

        set deviceVariablesInited 1

        #### motors
        set motorList [$deviceFactory getMotorList]
        foreach motorObj $motorList {
            set motorName [namespace tail $motorObj]
            variable $motorName
            set $motorName 0
            trace variable $motorName r trace_motor_shortcut_read
            trace variable $motorName w trace_motor_shortcut_write
        }

        #### strings
        set stringList [$deviceFactory getStringList]
        foreach stringObj $stringList {
            set stringName [namespace tail $stringObj]
            variable $stringName
            set $stringName ""
            trace variable $stringName r trace_string_shortcut_read
            trace variable $stringName w trace_string_shortcut_write
        }
    }
    proc exit { } {
        log_note script exit
    }
    namespace export \
        exit \
        move \
        getGoodLimits \
        open_shutter \
        close_shutter \
        read_ion_chamber \
        read_ion_chambers \
        get_ion_chamber_counts \
        get_encoder \
        set_encoder \
        wait_for_encoder \
        start_operation \
        start_waitable_operation \
        stop_operation \
        wait_for_devices \
        wait_for_string_contents \
        wait_for_operation \
        wait_for_operation_to_finish \
        wait_for_time \
        wait_for_file_exists \
        get_user_name \
        get_session_id \
        get_ticket \
        videoSnapshot \
        send_message \
        addEnergyRegion \
        listEnergyRegion \
        clearEnergyRegion \
        addPhiRegion \
        listPhiRegion \
        clearPhiRegion \
        startMadCollect \
        server_log \
        server_log_note \
        server_log_warning \
        server_log_error \
        server_log_severe \
        lock_active \
        raster_run_0 \
        microspec_load_result \
        microspec_load_result_by_mode \
}
##if device in log_operation list
##wait for sytem_idle to empty
proc nScripts::wait_for_system_idle { device } {
    if {$device == ""} return

    if {[catch {
        set lockList [::device::lock_operation getContents]
        if {[lsearch $lockList $device] >= 0} {
            set busyList [::device::system_idle getContents]
            if {$busyList != ""} {
                log_note waiting for system_idle
                wait_for_string_contents system_idle ""
            }
        }
    } errMsg]} {
        log_error while trying to decide whether wait for system_idle: $errMsg
    }
}
proc nScripts::move { name args } {
    variable deviceFactory
    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name does not exist"
    }

    if {![$obj isa ::DCS::Motor]} {
        return -code error "$name is not a motor"
    }

    wait_for_system_idle $name

    eval $obj move $args
}
proc nScripts::getGoodLimits { name } {
    variable deviceFactory
    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name dose not exist"
    }

    if {![$obj isa ::DCS::Motor]} {
        return -code error "$name is not a motor"
    }
    set lL [$obj cget -lowerLimit]
    set uL [$obj cget -upperLimit]
    if {[$obj isa ::DCS::RealMotor] && [$obj cget -backlashOn]} {
        ### one more extra step from the backlash to be safe for rounding 
        ### error
        if {[$obj cget -backlash] < 0} {
            set uL [expr $uL + ([$obj cget -backlash] - 1.0) / [$obj cget -scaleFactor]]
        } else {
            set lL [expr $lL + ([$obj cget -backlash] + 1.0) / [$obj cget -scaleFactor]]
        }
    }
    return [list $lL $uL]
}
proc nScripts::open_shutter { name } {
    variable deviceFactory
    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name does not exist"
    }

    if {![$obj isa ::DCS::Shutter]} {
        return -code error "$name is not a shutter"
    }

    $obj open
}
proc nScripts::close_shutter { name } {
    variable deviceFactory
    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name does not exist"
    }

    if {![$obj isa ::DCS::Shutter]} {
        return -code error "$name is not a shutter"
    }

    $obj close
}
proc nScripts::read_ion_chamber { time args } {
    log_error Please change your read_ion_chamber to read_ion_chambers
    return [eval read_ion_chambers $time $args]
}
proc nScripts::read_ion_chambers { time args } {
    variable deviceFactory
    variable controlSystem
    #check
    if {$time <= 0} {
        return -code error "time must > 0 to read ion chambers"
    }
    foreach name $args {
        set obj [$deviceFactory getObjectName $name]
        if {![$deviceFactory deviceExists $obj]} {
            return -code error "$name does not exist"
        }

        if {![$obj isa ::DCS::IonChamber]} {
            return -code error "$name is not an ion chamber"
        }
    }

    #send the command directly.  We cannot use individual ion chamber here.
    $controlSystem sendMessage "gtos_read_ion_chambers $time 0 $args"

    #update ion chamber status
    foreach name $args {
        set obj [$deviceFactory getObjectName $name]
        $obj started
    }
}

proc nScripts::get_ion_chamber_counts { args } {
    variable deviceFactory

    set result ""
    foreach name $args {
        set obj [$deviceFactory getObjectName $name]
        if {![$deviceFactory deviceExists $obj]} {
            return -code error "$name does not exist"
        }

        if {![$obj isa ::DCS::IonChamber]} {
            return -code error "$name is not an ion chamber"
        }
        lappend result [$obj getCounts]
    }
    return $result
}

proc nScripts::get_encoder { name } {
    variable deviceFactory
    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name does not exist"
    }

    if {![$obj isa ::DCS::Encoder]} {
        return -code error "$name is not an encoder"
    }

    $obj get_position
}
proc nScripts::set_encoder { name position } {
    variable deviceFactory
    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name does not exist"
    }

    if {![$obj isa ::DCS::Encoder]} {
        return -code error "$name is not an encoder"
    }

    $obj set_position $position
}
proc nScripts::wait_for_encoder { name } {
    variable deviceFactory
    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name does not exist"
    }

    if {![$obj isa ::DCS::Encoder]} {
        return -code error "$name is not an encoder"
    }

    $obj waitForDevice

    return [$obj cget -position]
}
proc nScripts::start_operation { name args } {
    variable deviceFactory

    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name does not exist"
    }

    if {![$obj isa ::DCS::Operation]} {
        return -code error "$name is not an operation"
    }

    wait_for_system_idle $name

    return [eval $obj startOperation $args]
}
proc nScripts::stop_operation { name args } {
    variable deviceFactory

    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name does not exist"
    }

    if {![$obj isa ::DCS::Operation]} {
        return -code error "$name is not an operation"
    }

    return [eval $obj stopOperation $args]
}
proc nScripts::start_waitable_operation { name args } {
    variable deviceFactory

    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name does not exist"
    }

    if {![$obj isa ::DCS::Operation]} {
        return -code error "$name is not an operation"
    }

    wait_for_system_idle $name

    return [eval $obj startWaitableOperation $args]
}
proc nScripts::wait_for_devices { args } {
    variable deviceFactory
    foreach name $args {
        set obj [$deviceFactory getObjectName $name]
        if {![$deviceFactory deviceExists $obj]} {
            return -code error "$name does not exist"
        }
    }
    foreach name $args {
        set obj [$deviceFactory getObjectName $name]
        $obj waitForDevice
    }
}
proc nScripts::wait_for_string_contents { name expected {index -1} } {
    variable deviceFactory
    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name does not exist"
    }

    if {![$obj isa ::DCS::String]} {
        return -code error "$name is not a string"
    }

    $obj waitForContents $expected $index
}
proc nScripts::wait_for_operation { handle } {
    return [::DCS::Operation::waitForOperation $handle]
}
proc nScripts::wait_for_operation_to_finish { handle } {
    set status "update"

    while {$status == "update"} {
        set result [wait_for_operation $handle]
        set status [lindex $result 0]
    }

    return $result
}
proc nScripts::wait_for_time { ms } {
    global gWaitForTime

    if {![info exist gWaitForTime]} {
        set gWaitForTime inactive
    }

    if {$gWaitForTime != "inactive"} {
        return -code error "only one wait for time is suppported"
    }
    set gWaitForTime waiting

    set id [after $ms { set gWaitForTime time_out }]
    addToWaitingList gWaitForTime
    vwait gWaitForTime
    removeFromWaitingList gWaitForTime
    if {$gWaitForTime != "time_out"} {
        catch {after cancel $id}
    }
    set result $gWaitForTime
    set gWaitForTime inactive
    if {$result == "aborting"} {
        return -code error "wait for time aborted"
    }
}
proc nScripts::get_device { name } {
    variable deviceFactory
    set obj [$deviceFactory getObjectName $name]
    if {![$deviceFactory deviceExists $obj]} {
        return -code error "$name does not exist"
    }
    return $obj
}

#If using NFS, and this is called early (prior to file existence), 
#make sure negative cache is off or else this could wait for a long time.
proc nScripts::wait_for_file_exists {filename} {
    while { ![file exists $filename] } {
        puts "waiting for $filename"
        #on nfs, following line helps speed up local knowledge of file written by different host
        catch {exec ls -alrt [file dirname $filename]}
        wait_for_time 500
    }
}


proc nScripts::lock_active { args } {
    variable controlSystem

    log_note $args

    if { [llength $args] == 1 } {
        $controlSystem waitForActiveLock [lindex $args 0]
    } else {
        $controlSystem waitForActiveLock new
    }
    return [$controlSystem getActiveKey]
}

proc nScripts::raster_run_0 {distance beamstop delta exposure bgCutOff } {

    package require Raster4BluIce
    global gRaster
    if { ![info exists ::gRaster]} {
        ::DCS::Raster4BluIce ::gRaster
    }

    if { [::gRaster getNotRaster0] } {
        ::gRaster switchRasterNumber 0
    }

    if  { [::gRaster getRunState] == "complete" } {
        set centerRaster [start_waitable_operation centerRaster move 0 $bgCutOff]
        wait_for_operation $centerRaster
        return       
    }

    if  { ! [::gRaster getRunnable] && ![::gRaster getNeedsReset] } {
        #just mounted a new sample?
        set op [start_waitable_operation rasterRunsConfig auto_set 0 0]
      	wait_for_operation $op
    }

    if  { [::gRaster getNeedsReset ] } {
        set reset_op [start_waitable_operation rasterRunsConfig resetRaster 0 0]
        wait_for_operation $reset_op
    }

    set r [start_waitable_operation rasterRunsConfig setUserSetup 0 distance $distance]
    wait_for_operation $r
    set r [start_waitable_operation rasterRunsConfig setUserSetup 0 beamstop $beamstop]
    wait_for_operation $r
    set r [start_waitable_operation rasterRunsConfig setUserSetup 0 delta $delta]
    wait_for_operation $r
    set r [start_waitable_operation rasterRunsConfig setUserSetup 0 time $exposure]
    wait_for_operation $r

    set _collectRaster [start_waitable_operation collectRaster 0 [get_user_name] [get_session_id]]
    wait_for_operation_to_finish $_collectRaster
      	
    set centerRaster [start_waitable_operation centerRaster move 0 $bgCutOff]
    wait_for_operation $centerRaster  
} 
proc nScripts::microspec_load_result { path {index ""}} {
    $::BluIce::objMicroSpecTab loadResultByName $path $index
}
proc nScripts::microspec_load_result_by_mode { mode path {index ""}} {
    $::BluIce::objMicroSpecTab loadResult $mode $path $index
}

proc nScripts::get_user_name { } {
    variable controlSystem
    return [$controlSystem getUser]
}
proc nScripts::get_session_id { } {
    variable controlSystem
    return "PRIVATE[$controlSystem getSessionId]"
}
proc nScripts::get_ticket { } {
    variable controlSystem
    set client [AuthClient::getObject]
    return [$client getTicket]
}
proc nScripts::videoSnapshot { source filePath } {
    if {$source < 1 || $source > 4} {
        log_error "source 1-4"
        return
    }

    if { [file exists $filePath] == 1 } {
        log_warning "Overwriting $filePath"
    }
    if { [catch {open $filePath w 0600} fileId] } {
        log_warning "videoSnapshot cannot open $fileId"
        return
    }

    set url [::config getImageUrl $source]
    append url "&resolution=high&size=large"
    if { [catch {
        set token [http::geturl $url -channel $fileId -timeout 12000]
        upvar #0 $token state
        set status $state(status)
        puts "status: $status"
        http::cleanup $token
    } err] } {
        set status "ERROR $err $url"
    }
    close $fileId

    if { $status != "ok" } {
        log_warning "doVideoSnapshot failed to get image: status=$status"
        return
    }
    log_note video snapshot saved to $filePath
}
proc nScripts::send_message { args } {
    variable controlSystem
    $controlSystem sendMessage "$args"
}
proc nScripts::addEnergyRegion { start end step } {
    variable madCollectEnergyRegionList

    lappend madCollectEnergyRegionList [list $start $end $step]

    listEnergyRegion
}
proc nScripts::addPhiRegion { start end step } {
    variable madCollectPhiRegionList

    lappend madCollectPhiRegionList [list $start $end $step]

    listPhiRegion
}
proc nScripts::listEnergyRegion { } {
    variable madCollectEnergyRegionList
    foreach e $madCollectEnergyRegionList {
        log_warning energyRegion $e
    }
}
proc nScripts::listPhiRegion { } {
    variable madCollectPhiRegionList
    foreach e $madCollectPhiRegionList {
        log_warning phiRegion $e
    }
}
proc nScripts::clearEnergyRegion { } {
    variable madCollectEnergyRegionList
    set madCollectEnergyRegionList ""
}
proc nScripts::clearPhiRegion { } {
    variable madCollectPhiRegionList
    set madCollectPhiRegionList ""
}
proc nScripts::startMadCollect { dir_ prefix_ exposureTime_ } {
    variable madCollectEnergyRegionList
    variable madCollectPhiRegionList

    ::device::madCollect startOperation $dir_ $prefix_ $exposureTime_ $madCollectEnergyRegionList $madCollectPhiRegionList
}
proc nScripts::server_log { level sender args } {
    variable controlSystem

    set msg "gtos_log $level $sender $args"
    $controlSystem sendMessage $msg
}
proc nScripts::server_log_note { sender args } {
    eval server_log note $sender $args
}
proc nScripts::server_log_warning { sender args } {
    eval server_log warning $sender $args
}
proc nScripts::server_log_error { sender args } {
    eval server_log error $sender $args
}
proc nScripts::server_log_severe { sender args } {
    eval server_log severe $sender $args
}
#history is like a limited stack

class DCS::CommandHistory {
    private variable MAX_ENTRY 100
    protected variable m_array
    #head is the oldest and tail is the newest
    protected variable m_head 0
    protected variable m_tail 0
    protected variable m_current 0

    #add will also reset current to newest
    public method add { command }
    public method getPrev { }
    public method getNext { }

    constructor { } { }
    destructor { }
}
body DCS::CommandHistory::add { command } {
    #save command
    set m_array($m_tail) $command

    #adjust pointers
    set m_tail [expr ($m_tail + 1) % $MAX_ENTRY]
    if {$m_head == $m_tail} {
        set m_head [expr ($m_head + 1) % $MAX_ENTRY]
    }

    #mark no current
    set m_current -1
}
body DCS::CommandHistory::getPrev { } {
    #empty?
    if {$m_head == $m_tail} return ""

    if {$m_current < 0} {
        set m_current [expr ($m_tail - 1) % $MAX_ENTRY]
    } elseif {$m_current != $m_head} {
        set m_current [expr ($m_current - 1) % $MAX_ENTRY]
    }

    if {![info exists m_array($m_current)]} {
        puts "intenal error of command history in getPrev"
        puts "head: $m_head tail: $m_tail current: $m_current"
        puts "list: [array get m_array]"

        return ""
    }

    return $m_array($m_current)
}
body DCS::CommandHistory::getNext { } {
    if {$m_current >= 0} {
        set m_current [expr ($m_current + 1) % $MAX_ENTRY]
    }
    if {$m_current == $m_tail} {
        set m_current -1
    }
    #pass beyong newest
    if {$m_current < 0} {
        return ""
    }
    if {![info exists m_array($m_current)]} {
        puts "intenal error of command history in getNext"
        puts "head: $m_head tail: $m_tail current: $m_current"
        puts "list: [array get m_array]"

        return ""
    }
    return $m_array($m_current)
}
