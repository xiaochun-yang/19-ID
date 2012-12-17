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


proc normalize_initialize {} {
    variable beamlineOpenStateTimestamp
    variable beamlineOpenStatePrevious
    variable beamlineOpenState

    variable injectionStateTimestamp
    variable injectionStatePrevious
    variable injectState

    variable spearStateTimestamp
    variable spearStatePrevious
    variable spearState

    variable beamNotGoodBecauseOfNotHappy
    set beamNotGoodBecauseOfNotHappy 0

    set beamlineOpenStateTimestamp 0
    set beamlineOpenStatePrevious $beamlineOpenState
    registerEventListener beamlineOpenState ::nScripts::beamlineOpenStateCallback

    set injectionStateTimestamp 0
    set injectionStatePrevious $injectState
    registerEventListener injectState ::nScripts::injectionStateCallback

    set spearStateTimestamp 0
    set spearStatePrevious $spearState
    registerEventListener spearState ::nScripts::spearStateCallback
}
proc beamlineOpenStateCallback { } {
    variable beamlineOpenState
    variable beamlineOpenStatePrevious
    variable beamlineOpenStateTimestamp

    if {$beamlineOpenState == "Open"} {
        if {$beamlineOpenStatePrevious != "Open"} {
            set beamlineOpenStateTimestamp [clock seconds]
            puts "set beamlineOpenStateTimestamp to now"
            #log_warning set timestamp for open
        }
    } else {
        set beamlineOpenStateTimestamp ""
    }
    if {$beamlineOpenState != $beamlineOpenStatePrevious} {
        if {[catch {
            ::dcss2 sendMessage \
            "htos_log chat_error server Spear State changed to $beamlineOpenState"
        } errMsg]} {
            puts "send log to chat failed: $errMsg"
        }
    }
    set beamlineOpenStatePrevious $beamlineOpenState
}

proc injectionStateCallback { } {
    variable injectState
    variable injectionStatePrevious
    variable injectionStateTimestamp

    if {$injectState != "Injection"} {
        if {$injectionStatePrevious == "Injection"} {
            set injectionStateTimestamp [clock seconds]
            puts "set injectionStateTimestamp to now"
            #log_warning set timestamp for injection end
        }
    } else {
        set injectionStateTimestamp ""
    }
    set injectionStatePrevious $injectState
}

proc spearStateCallback { } {
    variable spearState
    variable spearStatePrevious
    variable spearStateTimestamp

    if {$spearState == "Beams"} {
        if {$spearStatePrevious != "Beams"} {
            set spearStateTimestamp [clock seconds]
            puts "set spearStateTimestamp to now"
            #log_warning set timestamp for Beams
        }
    } else {
        set spearStateTimestamp ""
    }
    set spearStatePrevious $spearState
}

proc normalize_start {} {
    variable dose_data

    set counts [getStableIonCounts TRUE]

    if { $counts == 0} {
        return "Normalize Failed"
    }

    set situation [lindex $dose_data 2]
    set dose_data [lreplace $dose_data 0 1 $situation $counts]

    log_note "Beam Normalized with $counts counts."

    return "normalized"

}

proc getStableIonCounts { breakOnZero {fail_on_stop 0} } {
    variable dose_const
    variable dose_data

    
    set doseIonChamber i2
    set doseIntegrationPeriod 0.1
    set doseStabilityRatio 95
    set doseThreshold 100


    if {[llength $dose_const] < 5} {
        log_warning wrong dose_const $dose_const, regenerate default
        set dose_const [list \
        [clock seconds] \
        $doseIonChamber \
        $doseIntegrationPeriod \
        $doseThreshold \
        $doseStabilityRatio]
        log_warning new dose_const $dose_const
    } else {
        foreach {ts doseIonChamber doseIntegrationPeriod doseThreshold \
        doseStabilityRatio} $dose_const break
    }
    
    set counts 0
    set stable FALSE

    set lastCounts 1

    while { $stable == "FALSE" } {
        # count on the ion chamber
        read_ion_chambers $doseIntegrationPeriod $doseIonChamber

        if {$fail_on_stop && [get_operation_stop_flag]} {
            return -code error stopped
        }
    
        # wait for ion chamber read to complete
        wait_for_devices $doseIonChamber

        # get the counts
        
        set counts [get_ion_chamber_counts $doseIonChamber]
        
          if { $counts < $doseThreshold } {

            log_warning "No beam."

            set counts 0

            if { $breakOnZero == "TRUE"} {
               return 0
            }
            
          } elseif { abs( double($lastCounts) / double($counts) - 1 ) < $doseStabilityRatio / 100.0 } {

            set stable TRUE
              
        } else {
        
            #wait for $doseStabilityTime
            #log_note "unstable_beam $counts"
           }

        set lastCounts $counts
    }
    
    set tm [clock seconds]

    variable energy
    ### slit slize
    variable beam_size_x
    variable beam_size_y
    variable attenuation

    set situation [list $tm $energy $beam_size_x $beam_size_y $attenuation]
    if {[llength $dose_data] < 2} {
        set dose_data [list $situation $counts $situation $counts]
    } else {
        set dose_data [lreplace $dose_data 2 3 $situation $counts]
    }
    return $counts
}

# to make sure "beamGood" and "wait_for_good_beam" use the same
# conditions to check, we merge them into 1 function.
# beamGood will just be a no-wait call
proc beamGood {} {
    return [check_beam_good 0]
}
proc wait_for_good_beam { } {
    return [check_beam_good 1]
}

proc updateWaitForGoodBeamMsg { contents_ } {
    global ::gWaitForGoodBeamMsg

    if {![info exists gWaitForGoodBeamMsg]} {
        return
    }
    if {[llength $gWaitForGoodBeamMsg] < 1} {
        return
    }

    set msgName [lindex $gWaitForGoodBeamMsg 0]
    set msgIndex [lindex $gWaitForGoodBeamMsg 1]
    if {$msgName == ""} {
        return
    }
    if {$msgIndex == ""} {
        set msgIndex -1
    }

    variable $msgName

    if {[string range $msgIndex 0 3] == "key="} {
        set key [string range $msgIndex 4 end]
        set oldValue [set $msgName]
        dict set $msgName $key $contents_
        return
    }

    if {![string is integer -strict $msgIndex]} {
        return
    }


    if {$msgIndex < 0} {
        set $msgName $contents_
    } elseif {[llength [set $msgName]] > $msgIndex} {
        set oldValue [set $msgName]
        set $msgName [lreplace $oldValue $msgIndex $msgIndex $contents_]
    }
}

proc beamGoodCheckBeamlineOpenState { wait_for_it } {
    variable optimizedEnergyParameters
    variable beamlineOpenState
    variable beamlineOpenStateTimestamp

    set beamlineOpenCheck [lindex $optimizedEnergyParameters 4]
    set beamlineOpenStateDelay [lindex $optimizedEnergyParameters 26]

    if {$beamlineOpenCheck } {    
        set num_cycle 0
        while (1) { 
            #wait for the beamline state to be open
            if {[catch {
                set op [start_waitable_operation forceReadString \
                beamlineOpenState]
                wait_for_operation_to_finish $op 3000
            } errorResult]} {
                set result Open
            } else {
                set result $beamlineOpenState
            }
            if {$result != "Open"} {
                if {!$wait_for_it} {
                    log_warning beamline not Open
                    return 0
                } else {
                    if {$num_cycle > 0} {
                        log_warning Beam Closed while waiting for \
                        optics temp to stabilize
                        log_warning Waiting again for the beamline to open.
                        set num_cycle 0
                    } else {
                        log_warning Waiting for the beamline to open.
                    }
                    updateWaitForGoodBeamMsg "Waiting For Beamline To Open"
                    if {[catch {
                        wait_for_string_contents beamlineOpenState Open
                    } errMsg]} {
                        if {[string first abort $errMsg] >= 0} {
                            log_warning aborted
                            return -code error aborted
                        } else {
                            log_warning $errMsg
                            log_warning failed talk to spear, assume beamline Open
                            set beamlineOpenStateTimestamp [clock seconds]
                        }
                    }
                }
            }

            ###check to see if need to wait for delay
            if {![string is double -strict $beamlineOpenStateDelay] || \
            $beamlineOpenStateDelay <= 0} {
                #log_warning no delay defined for beamlineOpenState
                break
            }
            if {![string is double -strict $beamlineOpenStateTimestamp]} {
                log_severe beamlineOpenState==Open but no timestamp
                log_severe ts: $beamlineOpenStateTimestamp
                break
            }

            puts "DEBUG beamlineOpen delay: $beamlineOpenStateDelay"
            puts "DEBUG beamlineOpen ts: [clock format $beamlineOpenStateTimestamp] -format {%Y %T}]"

            set timeNow [clock seconds]
            set timeNeedToWait [expr $beamlineOpenStateTimestamp + \
            $beamlineOpenStateDelay - \
            $timeNow]

            if {$timeNeedToWait <= 0} {
                #log_warning delay expired already
                break
            }

            set timeNeedToWait [expr int($timeNeedToWait)]

            ####need to wait delay
            ### display in minutes
            if {!$wait_for_it} {
                log_warning need delay for optics temp to stabilize
                return 0
            } else {
                if {$num_cycle > 0} {
                    log_warning Beam Closed and Re-Opened while \
                    waiting for optics temp to stabilize

                    log_warning waiting again $timeNeedToWait seconds for \
                    optics temp to stabilize
                } else {
                    log_warning waiting $timeNeedToWait seconds for optics \
                    temp to stabilize
                }
                while {$timeNeedToWait > 0} {
                    set n_min [expr ($timeNeedToWait + 59) / 60]
                    set n_wait \
                    [expr ($timeNeedToWait > 60)?60:$timeNeedToWait]

                    updateWaitForGoodBeamMsg \
                    "waiting $n_min min for optics temp to stabilize"

                    wait_for_time [expr 1000 * $n_wait]
                
                    set timeNeedToWait [expr $timeNeedToWait - 60]
                }
            }
            #log_warning go back wait for open again
            incr num_cycle
        }
    }
    return 1
}

proc beamGoodCheckSpearState { wait_for_it } {
    variable optimizedEnergyParameters
    variable spearState
    variable spearStateTimestamp

    set spearStateCheck [lindex $optimizedEnergyParameters 27]
    set spearStateDelay [lindex $optimizedEnergyParameters 28]

    if {$spearStateCheck == "1"} {    
        set num_cycle 0
        while (1) { 
            #wait for spearState to Beams
            if {[catch {
                set op [start_waitable_operation forceReadString \
                spearState]
                wait_for_operation_to_finish $op 3000
            } errorResult]} {
                set result Beams
            } else {
                set result $spearState
            }
            if {$result != "Beams"} {
                if {!$wait_for_it} {
                    log_warning spearState not Beams
                    return 0
                } else {
                    if {$num_cycle > 0} {
                        log_warning Spear changed to non Beams while waiting for \
                        optics temp to stabilize
                        log_warning Waiting again for spearState Beams.
                        set num_cycle 0
                    } else {
                        log_warning Waiting for spear Beams.
                    }
                    updateWaitForGoodBeamMsg "Waiting For Spear Beams"
                    if {[catch {
                        wait_for_string_contents spearState Beams
                    } errMsg]} {
                        if {[string first abort $errMsg] >= 0} {
                            log_warning aborted
                            return -code error aborted
                        } else {
                            log_warning $errMsg
                            log_warning failed talk to spear, assume Beams
                            set spearStateTimestamp [clock seconds]
                        }
                    }
                }
            }

            ###check to see if need to wait for delay
            if {![string is double -strict $spearStateDelay] || \
            $spearStateDelay <= 0} {
                #log_warning no delay defined for spearState
                break
            }
            if {![string is double -strict $spearStateTimestamp]} {
                log_severe spearState==Beams but no timestamp
                log_severe ts: $spearStateTimestamp
                break
            }

            puts "DEBUG spearState delay: $spearStateDelay"
            puts "DEBUG spearState ts: [clock format $spearStateTimestamp] -format {%Y %T}]"

            set timeNow [clock seconds]
            set timeNeedToWait [expr $spearStateTimestamp + \
            $spearStateDelay - \
            $timeNow]

            if {$timeNeedToWait <= 0} {
                #log_warning delay expired already
                break
            }

            set timeNeedToWait [expr int($timeNeedToWait)]

            ####need to wait delay
            ### display in minutes
            if {!$wait_for_it} {
                log_warning need delay for optics temp to stabilize
                return 0
            } else {
                if {$num_cycle > 0} {
                    log_warning spearState changed to non-Beams while \
                    waiting for optics temp to stabilize

                    log_warning waiting again $timeNeedToWait seconds for \
                    optics temp to stabilize
                } else {
                    log_warning waiting $timeNeedToWait seconds for optics \
                    temp to stabilize
                }
                while {$timeNeedToWait > 0} {
                    set n_min [expr ($timeNeedToWait + 59) / 60]
                    set n_wait \
                    [expr ($timeNeedToWait > 60)?60:$timeNeedToWait]

                    updateWaitForGoodBeamMsg \
                    "waiting $n_min min for optics temp to stabilize"

                    wait_for_time [expr 1000 * $n_wait]
                
                    set timeNeedToWait [expr $timeNeedToWait - 60]
                }
            }
            #log_warning go back wait for open again
            incr num_cycle
        }
    }
    return 1
}

proc beamGoodCheckInjectionState { wait_for_it } {
    variable optimizedEnergyParameters
    variable injectionStateTimestamp
    variable injectState

    set injectionStateCheck [lindex $optimizedEnergyParameters 27]
    set injectionStateDelay [lindex $optimizedEnergyParameters 28]

    #### here == "1" is for backward compatible
    if {$injectionStateCheck == "1"} {    
        puts "DEBUG checking injection state"
        set num_cycle 0
        while (1) { 
            #wait for the injection to end
            if {[catch {
                set op [start_waitable_operation forceReadString \
                injectState]
                wait_for_operation_to_finish $op 3000
            } errorResult]} {
                set result "No Injection"
            } else {
                set result $injectState
            }
            if {$result == "Injection"} {
                if {!$wait_for_it} {
                    log_warning injection in process
                    return 0
                } else {
                    if {$num_cycle > 0} {
                        log_warning Injection while waiting for \
                        optics temp to stabilize
                        log_warning Waiting again for the injection to end.
                        set num_cycle 0
                    } else {
                        log_warning Waiting for injection to end.
                    }
                    updateWaitForGoodBeamMsg "Waiting For Injection To Finish"
                    if {[catch {
                        ## ! in front of string name means NOT:
                        ## wait for the contents != Injection
                        wait_for_string_contents !injectState Injection
                    } errMsg]} {
                        if {[string first abort $errMsg] >= 0} {
                            log_warning aborted
                            return -code error aborted
                        } else {
                            log_warning $errMsg
                            log_warning failed talk to spear, assume No Injection
                            set injectionStateTimestamp [clock seconds]
                        }
                    }
                }
            }

            ###check to see if need to wait for delay
            if {![string is double -strict $injectionStateDelay] || \
            $injectionStateDelay <= 0} {
                #log_warning no delay defined for injectState
                break
            }
            if {![string is double -strict $injectionStateTimestamp]} {
                log_severe injectState!=Injection but no timestamp
                log_severe ts: $injectionStateTimestamp
                break
            }
            set timeNow [clock seconds]
            set timeNeedToWait [expr $injectionStateTimestamp + \
            $injectionStateDelay - \
            $timeNow]

            if {$timeNeedToWait <= 0} {
                #log_warning delay expired already
                break
            }

            set timeNeedToWait [expr int($timeNeedToWait)]

            ####need to wait delay
            ### display in minutes
            if {!$wait_for_it} {
                log_warning need delay for optics temp to stabilize
                return 0
            } else {
                if {$num_cycle > 0} {
                    log_warning injected while \
                    waiting for optics temp to stabilize

                    log_warning waiting again $timeNeedToWait seconds for \
                    optics temp to stabilize
                } else {
                    log_warning waiting $timeNeedToWait seconds for optics \
                    temp to stabilize
                }
                while {$timeNeedToWait > 0} {
                    set n_min [expr ($timeNeedToWait + 59) / 60]
                    set n_wait \
                    [expr ($timeNeedToWait > 60)?60:$timeNeedToWait]

                    updateWaitForGoodBeamMsg \
                    "waiting $n_min min for optics temp to stabilize"

                    wait_for_time [expr 1000 * $n_wait]
                
                    set timeNeedToWait [expr $timeNeedToWait - 60]
                }
            }
            #log_warning go back wait for injection to end again
            incr num_cycle
        }
    }
    return 1
}
proc beamGoodCheckSpearCurrent { wait_for_it } {
    variable optimizedEnergyParameters
    variable spear_current

    ### wrap all so that we can change the parameter and let go of
    ### collecting
    while { 1 } {
        set checkSpearCurrent [lindex $optimizedEnergyParameters 32]
        set minCurrent [lindex $optimizedEnergyParameters 33]

        if {$checkSpearCurrent != "1" \
        || ![string is double -strict $minCurrent]} {
            return 1
        }

        log_warning Checking Spear Current

        if {[string is double -strict $spear_current] \
        && $spear_current >= $minCurrent} {
            break
        }
        if {!$wait_for_it} {
            log_warning Spear Current Low
            return 0
        } else {
            updateWaitForGoodBeamMsg "Wait For Good Beam (Spear Current)"
            wait_for_time 1000
        }
    }
    return 1
}
proc beamGoodCheckIonChamberReading { wait_for_it } {
    variable optimizedEnergyParameters

    set minCounts [lindex $optimizedEnergyParameters 21]
    set ionChamberCheck [lindex $optimizedEnergyParameters 25]

    #### this is to be backward compatiable with ionChamberCheck == ""
    #### in case it is not defined.
    if {$ionChamberCheck == "0"} {
        return 1
    }

    set signalName [::config getBeamGoodSignal]
    if {$signalName == ""} {
        puts "use i0 as beamGood signal"
        set signalName i0
    }
    log_warning Checking ion chamber $signalName reading

    #check ion chamber to see if stoppers are closed 
    while { 1 } {
        read_ion_chambers 0.1 $signalName
        wait_for_devices $signalName
        set counts [get_ion_chamber_counts $signalName]
	puts "yangx i0 counts=$counts minCpunts=$minCounts"
        if {$counts >= $minCounts} {
            break
        }
        if {!$wait_for_it} {
            log_warning Is there beam in the hutch? \
            Please check stoppers. .
            return 0
        } else {
            updateWaitForGoodBeamMsg "Wait For Good Beam"
        }
    }
    return 1
}

#### if called from a motor moving, we will not wait if
#### hutch door is open or i0 is low.
proc beamGoodCheckBeamHappy { wait_for_it {time_to_wait 0.1} {in_moving 0}} {
    ### if 0.1 is change, need to change this too
    set DEFAULT_TIMEOUT 0.1

    global gDoorOpened

    set gDoorOpened 0

    ### check availability
    variable beam_happy_cfg
    if {![array exists beam_happy_cfg]} {
        puts "skip beamHappy check: beam_happy_cfg not found"
        return 1
    }
    if {$beam_happy_cfg(BOARD) < 0 || $beam_happy_cfg(CHANNEL) < 0} {
        puts "skip beamHappy check: BOARD CHANNEL not defined"
        return 1
    }

    ## check enabled
    variable optimizedEnergyParameters
    set enabled [lindex $optimizedEnergyParameters  29]
    if {$enabled != "1"} {
        puts "skip beamHappy check: not enabled"
        return 1
    }

    log_warning checking beam on mirror feedback detector

    ### a quick check first
    set h [start_waitable_operation waitDigInBit \
    $beam_happy_cfg(BOARD) \
    $beam_happy_cfg(CHANNEL) \
    $beam_happy_cfg(VALUE) \
    0.2]

    if {![catch {
        wait_for_operation_to_finish $h
    } errMsg]} {
        return 1
    }

    if {!$wait_for_it} {
        log_warning Beam on mirror feedback detector not stable
        return 0
    }

    ### now it needs to wait
    updateWaitForGoodBeamMsg \
    "Wait For Stable Beam on Mirror Feedback Detector"

    set messageSent 0
    while {1} {
        if {$in_moving} {
            if {[shoudNotCheckBeamHappy]} {
                return 1
            }
        }

        set h [start_waitable_operation waitDigInBit \
        $beam_happy_cfg(BOARD) \
        $beam_happy_cfg(CHANNEL) \
        $beam_happy_cfg(VALUE) \
        $time_to_wait]

        if {![catch {
            wait_for_operation_to_finish $h
        } errMsg]} {
            return 1
        }
        if {[string first abort $errMsg] >=0} {
            return -code error $errMsg
        }

        if {!$messageSent \
        && !$gDoorOpened \
        && $time_to_wait != $DEFAULT_TIMEOUT} {
            log_severe Beam on mirror feedback detector not stable
            set messageSent 1
        }
    }
    return 1
}
proc check_beam_good { wait_for_it } {
    variable beamNotGoodBecauseOfNotHappy
    set beamNotGoodBecauseOfNotHappy 0

    if {![beamGoodCheckBeamlineOpenState $wait_for_it]} {
        return 0
    }
    if {![beamGoodCheckSpearState $wait_for_it]} {
        return 0
    }
    if {![beamGoodCheckSpearCurrent $wait_for_it]} {
        return 0
    }
    if {![beamGoodCheckIonChamberReading $wait_for_it]} {
        return 0
    }
    if {![beamGoodCheckBeamHappy $wait_for_it]} {
        set beamNotGoodBecauseOfNotHappy 1
        return 0
    }

    if {$wait_for_it} {
        updateWaitForGoodBeamMsg "Done Waiting For Good Beam"
    }
    return 1
}

proc shoudNotCheckBeamHappy { } {
    variable hutchDoorStatus
    set doorState [lindex $hutchDoorStatus 0]
    if {$doorState != "closed"} {
        log_error Skip Beam Happy Check - Hutch Door Not Closed
        return 1
    }

    ### following are part of check_beam_good
    if {![beamGoodCheckBeamlineOpenState 0]} {
        log_error Skip Beam Happy Check - Beamline Not Open
        return 1
    }
    if {![beamGoodCheckSpearState 0]} {
        log_error Skip Beam Happy Check - Spear State
        return 1
    }
    if {![beamGoodCheckIonChamberReading 0]} {
        log_error Skip Beam Happy Check - Ion Chamber Reading
        return 1
    }
    return 0
}

proc getMotorListNeedCheck { } {
    global gMotorBeamWidth
    global gMotorBeamHeight
    global gMotorEnergy
    global gMotorDistance
    global gMotorBeamStop

    set rawList [::config getPreCheckMotorList]

    set resultList ""

    ## mapping
    foreach tag $rawList {
        if {[string compare -length 4 $tag "map_"]} {
            lappend resultList $tag
        } else {
            switch -exact -- $tag {
                map_beam_size {
                    lappend resultList $gMotorBeamWidth $gMotorBeamHeight
                }
                map_beam_width {
                    lappend resultList $gMotorBeamWidth
                }
                map_beam_height {
                    lappend resultList $gMotorBeamHeight
                }
                map_energy {
                    lappend resultList $gMotorEnergy
                }
                map_distance {
                    lappend resultList $gMotorDistance
                }
                map_beamstop -
                map_beam_stop {
                    lappend resultList $gMotorBeamStop
                }
                default {
                    # you can just return an error
                    set cfgName [string range $tag 4 end]
                    set candidate [::config getStr "run.$cfgName"]
                    if {$candidate != ""} {
                        lappend resultList $candidate
                    } else {
                        log_error bad dcss.preCheckMotorList in config file: $tag
                        return -code error "erron in config file"
                    }
                }
            }
        }
    }
    return $resultList
}

### this is called in the beginning of all major operatoins
### It is a way to deal with consiquences of abort.
proc correctPreCheckMotors { {collimator_out 0} } {
    set mList [getMotorListNeedCheck]
    set client_id [get_client_id]

    ### move them by 0, one by one
    foreach motor $mList {
        move $motor by 0
        wait_for_devices $motor
    }

    if {[isString user_collimator_status]} {
        if {$collimator_out} {
            collimatorNormalIn
            return
        }
        variable user_collimator_status
        set collimatorSelected [lindex $user_collimator_status 0]
        set index [lindex $user_collimator_status 1]

        if {$collimatorSelected && $index >= 0} {
            # multiple choices
            collimatorMove_start $index

            ### single choice
            #collimatorMoveFirstMicron
        } else {
            collimatorNormalIn
        }
    }
}
### this is called after all major operatoins
proc cleanupAfterAll { } {
    puts "DEBUG cleanupAfterAll"
    if {[catch {
        if {[isString user_collimator_status]} {
            collimatorMoveOut
        }
    
        if {[isMotor beamstop_z_auto]} {
            inlineLightControl_start insert
        }
    } errMsg]} {
        log_error DEBUG cleanupAfterAll failed: $errMsg
    }
}
