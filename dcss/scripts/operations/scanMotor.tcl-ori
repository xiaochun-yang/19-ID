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
package require Itcl
namespace import ::itcl::*


package require DCSImperson
package require DCSUtil

proc scanMotor_initialize {} {
    global gAllFilterList
    ### to be the same as GUI
    set gAllFilterList ""
    set mapping [::config getStr bluice.filterLabelMap]

    foreach {filter tag} $mapping {
        lappend gAllFilterList $filter
    }

    puts "scannable filters: $gAllFilterList"

    ### save info for those peak scans
    namespace eval ::scanMotor {
        set saveUserName ""
        set saveSessionID ""
        set saveMotorDef ""
    }
}



proc scanMotor_start { user_ sessionId_ motorDef_ detectors_ filters_ timing_ prefix_ } {
    global gDevice
    global gOperation

    #string
    variable ::nScripts::scan_motor_status

    variable ::scanMotor::saveUserName
    variable ::scanMotor::saveSessionID
    variable ::scanMotor::saveMotorDef

    if {$sessionId_ == "SID"} {
        set sessionId_ "PRIVATE[get_operation_SID]"
        puts "use operation SID: [SIDFilter $sessionId_]"
    }

    set saveUserName $user_
    set saveSessionID $sessionId_
    set saveMotorDef  $motorDef_

    ##############################
    #parse input parameters
    ##############################

    #####motors#############
    parse_motors_definition $motorDef_ save_motor_positions totalNumPoints

    #######detectors##########
    parse_detectors $detectors_ save_need_open_shutter save_need_remove_inline_light

    ########filters##########
    eval check_device_controller_online $filters_
    set save_filter_states [get_filter_states]
    
    ########timing#######
    #units should be in ms.
    foreach { integrationTime \
                      motorSettlingTime \
                      numScans \
                      delayBetweenScans } $timing_ break

    #all in seconds
    set timingForFile [list \
    [expr $integrationTime / 1000.0] [expr $motorSettlingTime / 1000.0] \
    $numScans [expr $delayBetweenScans / 1000.0] s]

    ###########prefix##################
    parse_prefix $user_ $sessionId_ $numScans $prefix_ filenameList
    if {[llength $filenameList] != $numScans} {
        log_error "software internal error: numScans=$numScans but files=[set $filenameList]"
        return -code error "software internal error"
    }
    
    ############# prepare to scan ##########

    set_filter_states $filters_

    # open shutter if necessary
    if {$save_need_open_shutter} {
        open_shutter shutter
    }
    if {$save_need_remove_inline_light} {
        removeInlineCamera
    }
    #this list includes all filters and shutter
    wait_for_shutters $gDevice(shutter_list)

    if {[get_scanMotor_stopFlag]} {
        return -code error "stopped by user"
    }

    # do scan_count scans
    log_note "scanMotor started"
    for {set cnt 0} { $cnt < $numScans } {incr cnt} {
        #new scan started
        send_operation_update setup \
        $user_ SessionId $motorDef_ $detectors_ $filters_ $timing_ $prefix_

        #create the log file
        set fullPath [lindex $filenameList $cnt]
        set filename [file tail $fullPath]

        set contents ""
        append contents "# file       $filename $prefix_\n"
        append contents "# date       [time_stamp]\n"
        append contents "# motor1     [lindex $motorDef_ 0]\n"
        append contents "# motor2     [lindex $motorDef_ 1]\n"
        append contents "# detectors  $detectors_\n"
        append contents "# filters    $filters_\n"
        append contents "# timing     $timingForFile\n"
        append contents "\n"
        append contents "\n"
        append contents "\n"

        impAppendTextFile $user_ $sessionId_ $fullPath $contents

        #set string so client can load it
        set progress "[expr $cnt * $totalNumPoints] of [expr $numScans * $totalNumPoints]"
        set scan_motor_status [list $fullPath $progress]

        # wait for ion chambers to become inactive
        #eval wait_for_devices $detectors_
        
        # do the scans
        scanMotors $user_ $sessionId_ $motorDef_ $detectors_ \
        $integrationTime $motorSettlingTime $fullPath

        #update blu-ice that one scan is done
        send_operation_update done

        if {[get_scanMotor_stopFlag]} {
            log_warning "scanMotor stopped by user"
            break
        }

        #update the progress bar again at the end of each scan
        set progress "[expr ($cnt + 1) * $totalNumPoints] of [expr $numScans * $totalNumPoints]"
        set scan_motor_status [list $fullPath $progress]
        
        #delay between scans
        wait_for_time [expr int($delayBetweenScans)]
    }
    log_note "scanMotor done"

    # close shutter if necessary
    if { $save_need_open_shutter && $gDevice(shutter,state) == "open" } {
        close_shutter shutter
    }
    if {$save_need_remove_inline_light && ![inlineLightAlreadyIn]} {
        ## you should be able to use following
        ##insertInlineCamera 
        ## but it is safer to:
        inlineLightControl_start insert
    }
    # restore filter states
    set_filter_states $save_filter_states
    wait_for_shutters $gDevice(shutter_list)

    # move motors back to previous positions if scan successful
    if {[info exists save_motor_positions]} {
        set motorNames [array names save_motor_positions]
        if {[llength $motorNames]} {
            foreach motor_name $motorNames {
                log_note move $motor_name back to $save_motor_positions($motor_name)
                move $motor_name to $save_motor_positions($motor_name)
                wait_for_devices $motor_name
            }
        }
    }

    if {[get_scanMotor_stopFlag]} {
        return -code error "stopped by user"
    }
    return normal
}

proc scanTwoMotors { motor1Def_ motor2Def_ detectors_ integrationTime_ motorSettlingTime_ filename_ } {
    variable ::nScripts::scan_motor_status

    upvar user_ username
    upvar sessionId_ SID
    
    set counts ""

    foreach {name1 points1 start1 end1 stepSize1 units1} $motor1Def_ break
    foreach {name2 points2 start2 end2 stepSize2 units2} $motor2Def_ break

    set step_size_1 [expr ($end1 - $start1) / double($points1 - 1)]
    set step_size_2 [expr ($end2 - $start2) / double($points2 - 1)]
    
    for {set p1 0} {$p1 < $points1} {incr p1} {
        set position1 [expr $start1 + $step_size_1 * $p1]
        #move $name1 to $position1 $units1
        if { $name1 != "time" } {
            move $name1 to $position1
        } else {
            wait_for_time [expr int(1000.0 * $step_size_1)]
        }
        for {set p2 0} {$p2 < $points2} {incr p2} {
    
            set position2 [expr $start2 + $step_size_2 * $p2]
            #move $name2 to $position2 $units1
            move $name2 to $position2
                
            #wait for all of the motors
            if { $name1 != "time" } {
                wait_for_devices $name1 $name2
            } else {
                wait_for_devices $name2
            }
    
            # wait for the motors to settle
            wait_for_time [expr int($motorSettlingTime_) ]
    
            set counts [doScanCounting $integrationTime_ $detectors_]
    
            set fullPoint [list $position1 $position2]
            send_operation_update $fullPoint $counts
            #append the result to the log file
            set contents [format_for_scan_log $fullPoint $counts]
            append contents "\n"
            impAppendTextFile $username $SID $filename_ $contents
    
            #update progress bar
            #set scan_motor_status [lreplace $scan_motor_status 1 1 "+1"]
            #if client connected during a scan +n will not work
            set old_prog [lindex $scan_motor_status 1]
            set old_step [lindex $old_prog 0]
            set new_step [expr $old_step + 1]
            set new_prog [lreplace $old_prog 0 0 $new_step]
            set scan_motor_status [lreplace $scan_motor_status 1 1 $new_prog]
        }
    }
}

proc scanOneMotor { motor1Def_ detectors_ integrationTime_ motorSettlingTime_ filename_ } {
    variable ::nScripts::scan_motor_status

    upvar user_ username
    upvar sessionId_ SID
    
    
    set counts ""

    foreach {name1 points1 start1 end1 stepSize1 units1} $motor1Def_ break

    set step_size_1 [expr ($end1 - $start1) / double($points1 - 1)]
    
    for {set p1 0} {$p1 < $points1} {incr p1} {
        set position1 [expr $start1 + $step_size_1 * $p1]

        #move $name1 to $position1 $units1
        #units already been taken care in blu-ice
        if { $name1 != "time" } {
            move $name1 to $position1

            # wait for the motors to settle
            wait_for_devices $name1
            wait_for_time [expr int($motorSettlingTime_) ]
        } else {
            wait_for_time [expr int(1000.0 * $step_size_1)]
        }

        set counts [doScanCounting $integrationTime_ $detectors_]

        set fullPoint $position1
        send_operation_update $fullPoint $counts
        #append the result to the log file
        set contents [format_for_scan_log $fullPoint $counts]
        append contents "\n"
        impAppendTextFile $username $SID $filename_ $contents

        #update progress bar
        #set scan_motor_status [lreplace $scan_motor_status 1 1 "+1"]
        #if client connected during a scan +n will not work
        set old_prog [lindex $scan_motor_status 1]
        set old_step [lindex $old_prog 0]
        set new_step [expr $old_step + 1]
        set new_prog [lreplace $old_prog 0 0 $new_step]
        set scan_motor_status [lreplace $scan_motor_status 1 1 $new_prog]
    }
}

#recursive for more than one motors
#it will move one motor a time and wait it to finish moving then next motor
proc scanMotors { username SID motorDef_ detectors_ integrationTime_ motorSettlingTime_ filename_ { motorNames_ {} } { fullPosition_ {} } } {
    variable ::nScripts::scan_motor_status

    #log_note scanMotors $motorDef_ $detectors_ $integrationTime_ $motorSettlingTime_ $filename_ $motorNames_ $fullPosition_

    #double check
    if {[llength $motorDef_] == 0} {
        log_error "software error: empty motor definition {$motorDef_}"
        return
    }

    if {[get_scanMotor_stopFlag]} {
        return
    }

    set motor1Def_ [lindex $motorDef_ 0]
    set motor2Def_ [lindex $motorDef_ 1]

    if {[llength $motor1Def_] < 6} {
        log_error "software error: bad motor definition {$motor1Def_}"
    }
    
    foreach {name1 points1 start1 end1 stepSize1 units1} $motor1Def_ break

    set step_size_1 [expr ($end1 - $start1) / double($points1 - 1)]

    set leftMotors [lrange $motorDef_ 1 end]
    #log_note "left motors: {$leftMotors}"

    set local_motorNames $motorNames_
    if { $name1 != "time" } {
        lappend local_motorNames $name1
        #log_note "motor names: $local_motorNames"
    }
    
    for {set p1 0} {$p1 < $points1} {incr p1} {
        if {[get_scanMotor_stopFlag]} {
            return
        }

        set position1 [expr $start1 + $step_size_1 * $p1]
        set local_fullPosition $fullPosition_
        lappend local_fullPosition $position1
        #log_note "full position: $local_fullPosition"

        #move $name1 to $position1 $units1
        if { $name1 != "time" } {
            move $name1 to $position1
            wait_for_devices $name1
        } else {
            wait_for_time [expr int(1000.0 * $step_size_1)]
        }

        if {[llength $motor2Def_] < 6} {
            #wait motor to settle down
            if {[llength $local_motorNames] > 0} {
                wait_for_time [expr int($motorSettlingTime_) ]
            }

            #read results
            set counts [doScanCounting $integrationTime_ $detectors_]
            #update blu-ice
            send_operation_update $local_fullPosition $counts
            #append the result to the log file
            set contents [format_for_scan_log $local_fullPosition $counts]
            append contents "\n"

            if { $name1 == "time" } {
                set ts [clock format [clock seconds] -format "%D %T"]
                set contents "$ts $contents"
            }
            impAppendTextFile $username $SID $filename_ $contents

            #update progress bar
            set old_prog [lindex $scan_motor_status 1]
            set old_step [lindex $old_prog 0]
            set new_step [expr $old_step + 1]
            set new_prog [lreplace $old_prog 0 0 $new_step]
            set scan_motor_status [lreplace $scan_motor_status 1 1 $new_prog]
        } else {
            #recursive call
            scanMotors $username $SID $leftMotors $detectors_ $integrationTime_ $motorSettlingTime_ $filename_ $local_motorNames $local_fullPosition
        }
    }
}

proc doScanCounting { integrationTime_ detectors_ } {
    global gDevice

    #split
    set ionChamberList ""
    set encoderList ""
    foreach device $detectors_ {
        set type $gDevice($device,type)
        switch -exact -- $type {
            "encoder" { lappend encoderList $device }
            "ion_chamber" { lappend ionChamberList $device }
            default {
                log_error $device type=$type \
                only support encoder and ion chamber.
                return -code error not_supported
            }
        }
    }    

    # do the counting
    eval read_ion_chambers [expr $integrationTime_ / 1000.0] $ionChamberList
    foreach encoder $encoderList {
        get_encoder $encoder
    }

    eval wait_for_devices $detectors_

    ### merge
    set scanData ""
    foreach device $detectors_ {
        set type $gDevice($device,type)
        switch -exact -- $type {
            "encoder"     { set value $gDevice($device,position) }
            "ion_chamber" { set value $gDevice($device,counts) }
        }
        lappend scanData [expr double($value)]
    }

    # calculate transmission and absorbance if reference requested
    if { [llength $detectors_] > 1 } {

        set signal [lindex $scanData 0] 
        set reference [lindex $scanData 1]
        
        set transmission [calculateTransmissionFromSignals $signal $reference] 
        set absorption [calculateAbsorption $transmission]

        lappend scanData $transmission
        lappend scanData $absorption
    }

    return $scanData
}


proc calculateTransmissionFromSignals { signal_ reference_ } {

    # calculate transmission and absorbance if reference requested
    if { $reference_ == 0 } {
        set transmission [expr $signal_ ]
    } else {
        set transmission [expr $signal_ / $reference_ ]
    }
    
    return $transmission
}

proc calculateAbsorption { transmission_ } {
    
    if { $transmission_ <= 0 } {
        set absorption 100
    } else {
        set absorption [expr -log($transmission_) ]
    }

    return $absorption
}

#copied from old blu-ice/scripts/filter.tcl
proc set_filter_states { new_state } {

    # global variables
    global gDevice
    global gAllFilterList
    
    # initialize previous state
    set prev_state ""
    
    foreach filter $gAllFilterList {
        #log_note "deal with $filter"
        if {[isShutter $filter]} {
            if { $gDevice($filter,state) == "closed" } {
                lappend prev_state $filter
                if { [lsearch $new_state $filter] == -1 } {
                    #log_note "Removing $filter..."
                    open_shutter $filter
                }
            } else {
                if { [lsearch $new_state $filter] != -1 } {
                    #log_note "Inserting $filter..."
                    close_shutter $filter
                }
            }         
        } else {
            log_warning $filter is not a shutter on this beamline
        }
    }
    
    # return the previous state
    return $prev_state
}

proc get_filter_states { } {

    # global variables
    global gDevice
    global gAllFilterList
    
    # initialize previous state
    set prev_state ""
    
    foreach filter $gAllFilterList {
        if {[isShutter $filter] && \
        $gDevice($filter,state) == "closed" } {
            lappend prev_state $filter
        }         
    }
    
    # return the previous state
    return $prev_state
}

proc extend_directory_name { dir user } {

    set dir [string trim $dir]

    #log_note "extend_dir dir:{$dir} user:{$user}"
    #most common cases
    #relative path
    if {$dir == {} || $dir == {~} || $dir == {~/} } {
        #log_note "extend dir return relative path ~$user"
        return "~$user"
    }

    #absolute path
    set firstLetter [string index $dir 0]
    set secondLetter [string index $dir 1]

    #log_note "first: {$firstLetter} second: {$secondLetter}"
    if {$firstLetter == {~} && $secondLetter == {/}} {
        #log_note "extend dir return absolute path ~$user+old"
        return [string replace $dir 0 0 "~$user"]
    }
    if {$firstLetter == {/} || $firstLetter == {~} } {
        #log_note "extend dir no change: $dir"
        return $dir
    }

    #log_note "extend dir default: ~$user/$dir"
    return "~$user/$dir"
}

proc check_motor_scan_def { motorDef_ clientID_ } {
    global gDevice

    if {[llength $motorDef_] < 6} {
        return -code error "bad motor scan definition {$motorDef_}"
    }
    foreach {name points start end step_size units} $motorDef_ break

    if {$name == "time" } return
    
    #check name
    if {![motor_exists $name]} {
        return -code error "bad motor name {$name}"
    }

    #check permit
    set permitCheck [check_device_permit $clientID_ $name]
    if {$permitCheck != "GRANTED"} {
        return -code error "permit check failed: $permitCheck"
    }

    #check points
    if {$points < 2} {
        return -code error "bad total points {$points}"
    }

    #check motor soft limits
    assertMotorLimit $name $start
    assertMotorLimit $name $end
}

proc format_for_scan_log { fullPoint_ counts_ } {
    set output {}

    foreach x $fullPoint_ {
        append output [format " %14.6f" $x]
    }
    foreach c $counts_ {
        append output [format "    %18.6f" $c]
    }

    return $output
}

proc parse_motors_definition { definition_ oldPositions_ totalPoints_ } {
    global gDevice

    upvar 1 $oldPositions_ old_pos
    upvar 1 $totalPoints_ total_points_num

    #get client ID so we can check permit 
    set client_id [get_client_id]

    set total_points_num 1
    foreach motorDef $definition_ {
        if {[llength $motorDef] < 6} return

        check_motor_scan_def $motorDef $client_id
        set name [lindex $motorDef 0]
        if {$name != "time"} {
            check_device_controller_online $name
            set old_pos($name) $gDevice($name,scaled)
        }
        set total_points_num [expr $total_points_num * [lindex $motorDef 1]]
    }
}

proc parse_detectors { detectors_  needOpenShutter_ needRemoveInlineLight_ } {
    global gDevice

    upvar 1 $needOpenShutter_ need_open
    upvar 1 $needRemoveInlineLight_ need_remove

    if {[llength $detectors_] < 1} {
        return -code error "no signal selected"
    }

    eval check_device_controller_online $detectors_

    set need_open 0
    set need_remove 0

    if {[isOperation inlineLightContro] && [inlineLightAlreadyIn]} {
        foreach signal $detectors_ {
            if {$signal == "i_beamstop"} {
                set need_remove 1
                break
            }
        }
    }
     
    #check if we need to open shutter
    if {$gDevice(shutter,state) == "closed" } {
        foreach signal $detectors_ {
            if {$signal == "i_beamstop" || \
            [string range $signal 0 2] == "fd_"} {
                set need_open 1
                return
            }
        }
    }
}

proc parse_prefix { user_ sessionId_ numScans_ prefix_ filenameList_ } {
    upvar 1 $filenameList_ file_name_list

    set fnDir [lindex $prefix_ 0]
    set fnPrefix [lindex $prefix_ 1]
    set fnCounterInit [lindex $prefix_ 2]

    #check file names
    set fullDir [extend_directory_name $fnDir $user_]

    ####make sure none of the files exists
    impScanFilesNotExist $user_ $sessionId_ $fullDir ${fnPrefix}_ scan \
    $fnCounterInit $numScans_

    set file_name_list {}
    for {set cnt 0} {$cnt < $numScans_} {incr cnt} {
        set counter [format "%03d" [expr $fnCounterInit + $cnt]]
        set filename ${fnPrefix}_$counter.scan
        set fullPath [file join $fullDir $filename]
        set fullPath [file nativename $fullPath]
        lappend file_name_list $fullPath
    }
}

proc get_scanMotor_stopFlag { } {
    global gOperation
    return $gOperation(scanMotor,stopFlag)
}
proc get_scanMotor_subLogFileName { } {
    variable scan_motor_status
    variable ::scanMotor::saveMotorDef

    set fullPath [lindex $scan_motor_status 0]

    set rootName [file root $fullPath]
    set sub_dir ${rootName}_subScan

    set file [file tail $fullPath]
    set file [file root $file]

    ### create addOn from the motors
    set addOn ""
    foreach motorDef $saveMotorDef {
        if {[llength $motorDef] < 6} {
            break
        }
        foreach {name points start end step_size units} $motorDef break

        set step_size [expr abs($step_size)]
        if {$name == "time"} {
            set value [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
        } else {
            variable $name

            set factor 1.0
            while {$factor * $step_size < 1.0} {
                set factor [expr $factor * 1000.0]
            }
            set currentPosition [set $name]
            set value [expr round($currentPosition * $factor)]
            if {$value < 0} {
                set value M[expr abs($value)]
            }
        }
        append addOn _$value
    }

    set fileName ${file}${addOn}.scan

    return [file join $sub_dir $fileName]
}
