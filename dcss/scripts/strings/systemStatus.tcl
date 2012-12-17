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

proc STRING_initialize {} {
    global gTHC_high
    global gTT_high
    global gTG_high
    global gDevice
    global gOperation
    variable STRING
    variable systemStatusHostList
    variable systemStatusSpecialDevice
    variable local_hutch_door_status
    variable temperatureHost


    set gTHC_high 0
    set gTT_high 0
    set gTG_high 0

    set local_hutch_door_status "unkown"
    set temperatureHost ""

    set STRING ""

    ####which devices (strings) to monitor
    set deviceList [list\
    temperature \
    system_idle \
    hutchDoorStatus \
    detector_status \
    gap_energy_sync \
    energy_config \
    screening_msg \
    collect_msg \
    raster_msg \
    scan_msg \
    robot_sample \
    auto_sample_msg \
    center_crystal_msg \
    fill_run_msg \
    ceilingTemperature \
    tableTemperature \
    gonioTemperature \
    energy_moving_msg \
    visex_msg \
    spectroWrap_status \
    microspec_phiScan_status \
    microspec_timeScan_status \
    microspec_doseScan_status \
    ]

    ###which hosts to monitor
    set systemStatusHostList self
    if {[info exists gDevice(temperature,hardwareHost)]} {
        puts "setting temperatureHost $gDevice(temperature,hardwareHost)"
        set temperatureHost $gDevice(temperature,hardwareHost)
        lappend systemStatusHostList $gDevice(temperature,hardwareHost)
    }
    if {[info exists gOperation(detector_collect_image,hardwareHost)]} {
        lappend systemStatusHostList $gOperation(detector_collect_image,hardwareHost)
    }
    if {[info exists gDevice(shutter,hardwareHost)]} {
        lappend systemStatusHostList $gDevice(shutter,hardwareHost)
    }
    if {[info exists gDevice(gonio_phi,hardwareHost)]} {
        lappend systemStatusHostList $gDevice(gonio_phi,hardwareHost)
    }

    foreach device $deviceList {
        registerEventListener $device \
        [list ::nScripts::STRING_trigger $device]
    }
    puts "systemStatusHostList: $systemStatusHostList"
    foreach host $systemStatusHostList {
        registerEventListener $host \
        [list ::nScripts::STRING_trigger $host]
    }

    ##special devices that take priority
    ###order is important here
    set systemStatusSpecialDevice [list \
    userAlignBeam \
    optimized_energy \
    energy \
    auto_sample_cal \
    centerCrystal \
    manualRastering \
    centerSlits \
    madScan \
    fillRun \
    scan3DSetup \
    ]
}


proc STRING_configure { args } {
	#simply return whatever is given us without any error checking
	return $args
}

proc STRING_trigger { starter } {
    #puts "STRING_trigger $starter"
    global gDevice
    global gTHC_high
    global gTT_high
    global gTG_high
        
    variable STRING
    variable hutchDoorStatus
    variable local_hutch_door_status
    variable system_idle
    variable temperatureHost
    variable temperature

    if {[motor_exists temperature] && \
    ( \
        $gDevice(temperature,lowerLimitOn) || \
        $gDevice(temperature,upperLimitOn) \
    ) \
    } {
        if {$temperatureHost == ""} {
            set temperatureHost $gDevice(temperature,hardwareHost)
            registerEventListener $temperatureHost \
            [list ::nScripts::STRING_trigger $temperatureHost]
            puts "in trigger setting temperatureHost to $temperatureHost"
        }
        global gHwHost
        if {$gHwHost($temperatureHost,status) == "offline"} {
            set new_value [list "cryoJet offline" black red]
            if {$STRING != $new_value} {
                set STRING $new_value
            }
            return
        }
        if {![limits_ok_quiet temperature $temperature]} {
            set display [expr int($temperature)]
            set new_value [list "cryoJet temperature $display K" black red]
            if {$STRING != $new_value} {
                set STRING $new_value
            }
            return
        }
    }

    if {$starter == "gonioTemperature"} {
        variable gonioTemperature
        if {![limits_ok_quiet gonioTemperature $gonioTemperature]} {
            ###msg out
            if {!$gTG_high} {
                set gTG_high 1
                log_severe goniometer tempurature $gonioTemperature C
            }

            set new_value [list "goniometer temperature $gonioTemperature C" black red]
            if {$STRING != $new_value} {
                set STRING $new_value
            }
            return
        } else {
            set gTG_high 0
        }
    }

    if {$starter == "tableTemperature"} {
        variable tableTemperature
        if {![limits_ok_quiet tableTemperature $tableTemperature]} {
            ###msg out
            if {!$gTT_high} {
                set gTT_high 1
                log_severe table tempurature $tableTemperature C
            }

            set new_value [list "table top temperature $tableTemperature C" black red]
            if {$STRING != $new_value} {
                set STRING $new_value
            }
            return
        } else {
            set gTT_high 0
        }
    }

    if {$starter == "ceilingTemperature"} {
        variable ceilingTemperature
        if {![limits_ok_quiet ceilingTemperature $ceilingTemperature]} {
            ###msg out
            if {!$gTHC_high} {
                set gTHC_high 1
                log_severe hutch ceiling tempurature $ceilingTemperature C
            }

            set new_value [list "hutch ceiling temperature $ceilingTemperature C" black red]
            if {$STRING != $new_value} {
                set STRING $new_value
            }
            return
        } else {
            set gTHC_high 0
        }
    }

    if {$starter == "hutchDoorStatus"} {
        set door [lindex $hutchDoorStatus 0]
        if {$door == $local_hutch_door_status} {
            return
        }
        set local_hutch_door_status $door
    }

    ###emergency button###
    if {[lsearch -exact $system_idle motorStopButton] >= 0} {
        set display "MOTOR STOP BUTTON LATCHED"
        set new_value [list $display black red]
        if {$STRING != $new_value} {
            set STRING $new_value
        }
        return
    }

    set hutch_door_status [lindex $hutchDoorStatus 0]
    set msgSecondary [STRING_getSecondaryMsg]
    if {[llength $system_idle] > 0} {
        set msgPrimary [STRING_getPrimparyMsg]
        set display "$msgPrimary - $msgSecondary"
        set foreground black
        set background #d0d000
    } elseif {$hutch_door_status != "closed"} {
        set display "Hutch Door $hutch_door_status - $msgSecondary"
        set foreground black
        set background #d0d000
    } else {
        set display $msgSecondary
        set foreground black
        set background #00a040
        if {[string match -nocase *offline* $display]} {
            set background red
            set foreground black
        }
    }
    ####change color in case of error warning
    if {[string match -nocase *error* $display] || \
    [string match -nocase *fail* $display] || \
    [string match -nocase *abort* $display] || \
    [string match -nocase *warn* $display]} {
        set foreground red
        set background #d0d000
    } elseif {[string first Exposing $display] >= 0} {
        set foreground #c04080
        set background #d0d000
    }
    set new_value [list $display $foreground $background]
    if {$STRING != $new_value} {
        set STRING $new_value
    }
}
####default is the first device in system_idle
#### it may be mapped to more meaningful common English
proc STRING_getPrimparyMsg { } {
    variable system_idle

    set device [lindex $system_idle 0]
    set result $device

    ####mapping
    switch -exact -- $device {
        centerSlits {
            set result "Align Slits"
        }
        centerCrystal {
            set result "Center Crystal"
        }
        centerLoop {
            set result "Auto Centering"
        }
        collectWeb {
            set result "WebIce"
        }
        madCollect {
            set result "MadCollecting"
        }
        collectRuns -
        collectRun -
        collectShutterless -
        collectFrame {
            set result "Collecting"
        }
        madScan {
            set result "MAD Scan"
        }
        moveSample {
            set result "Sample Moving"
        }
        normalize {
            set result "Normalizing Dose"
        }
        optimalExcitation {
            set result "Excitation Scan"
        }
        sequence {
            set result "Screening"
        }
        sequenceManual {
            set result "Robot Moving Sample"
        }
        ISampleMountingDevice {
            set result "Robot Busy"
        }
        scanMotor {
            set result "Scanning Motor"
        }
        auto_sample_cal {
            set result "Auto Gonio CAL"
        }
        energy {
            set result "Changing Energy"
        }
        userAlignBeam -
        optimized_energy {
            set result "Optimizing Beam"
        }
        camera_zoom {
            set result "Zooming Camera"
        }
        gonio_omega -
        gonio_kappa -
        gonio_phi {
            set result "Rotating Sample"
        }
        cryojet_anneal {
            set result "Annealing Sample"
        }
        detector_horz -
        detector_vert -
        detector_z {
            set result "Detector Moving"
        }
        fillRun {
            set result "Autoindex"
        }
        burnPaper {
            set result "Burn Paper"
        }
        cryoBlock {
            set result "Sample Annealing"
        }
        collectRasters -
        collectRaster {
            set result "Crystal Rastering"
        }
        rasterRunsConfig {
            if {[lsearch -exact $system_idle collectRaster] < 0} {
                set result "Raster Setup"
            } else {
                set result "Crystal Rastering"
            }
        }
        videoVisexSnapshot {
            set result "Collecting Emission"
        }
        visexMoveSample {
            set result "Emission Sample Moving"
        }
        visexRotatePhi {
            set result "Emission Sample Rotating"
        }
        spectrometerWrap {
            set result "Spectrometer"
        }
        microspec_snapshot -
        microspec_phiScan -
        microspec_timeScan -
        microspec_doseScan {
            set result "microspec"
        }
        microspec_horz -
        microspec_vert -
        microspec_z {
            set result "microspec moving"
        }
    }
    return $result
}

## try to get XXXX_msg for devices in system_idle
## detector_status will be returned if system_idle is empty
## or detector is busy
proc STRING_getSecondaryMsg { } {
    global gHwHost
    variable systemStatusHostList
    variable systemStatusSpecialDevice
    variable system_idle
    variable hutchDoorStatus
    variable auto_sample_msg
    variable center_crystal_msg
    variable fill_run_msg
    variable detector_status
    variable screening_msg
    variable collect_msg
    variable raster_msg
    variable scan_msg
    variable robot_sample
    variable center_crystal_msg
    variable energy_config
    variable gap_energy_sync

    variable energy_moving_msg

    variable visex_msg
    variable spectroWrap_status
    variable microspec_phiScan_status
    variable microspec_timeScan_status
    variable microspec_doseScan_status
    variable microspec_snapshot_status

    ###check any offline first
    foreach host $systemStatusHostList {
        if {$gHwHost($host,status) == "offline"} {
            return "$host offline"
        }
    }

    switch -exact -- $detector_status {
        "Detector Ready" -
        "Detector Idle" -
        "Scanning Plate 100%..." -
        "" { }
        default {
            return $detector_status
        }
    }
    ###default is the first
    set index 0
    set picked_one [lindex $system_idle 0]
    ###then search for special device
    foreach device $systemStatusSpecialDevice {
        set index [lsearch -exact $system_idle $device]
        if {$index >= 0} {
            set picked_one [lindex $system_idle $index]
            break
        }
    }
    set result ""
    switch -exact -- $picked_one {
        userAlignBeam -
        optimized_energy {
            ####it will be primary message if it is first
            ####so no need for secondary
            if {$index != 0} {
                set result "optimizing beam"
            }
        }
        energy {
            ####it will be primary message if it is first
            ####so no need for secondary
            if {[isString energy_moving_msg] && $energy_moving_msg != ""} {
                set result $energy_moving_msg
            } else {
                if {$index != 0} {
                    set result "changing energy"
                }
            }
        }
        auto_sample_cal {
            set result $auto_sample_msg
        }
        scan3DSetup -
        manualRastering -
        centerCrystal -
        centerSlits {
            set result $center_crystal_msg
        }
        fillRun {
            set result $fill_run_msg
        }
        collectRuns -
        collectShutterless -
        collectRun {
            foreach {status msg} $collect_msg break
            if {$status == "1"} {
                set result $msg
            }
        }
        rasterRunsConfig -
        collectRasters -
        collectRaster {
            foreach {status msg} $raster_msg break
            if {$status == "1"} {
                set result $msg
            }
        }
        madCollect -
        madScan -
        optimalExcitation {
            set result $scan_msg
        }
        fillRun {
            set result $fill_run_msg
        }
        sequence {
            set result $auto_sample_msg
            if {$result == ""} {
                set result $screening_msg
            }
        }
        sequenceManual -
        ISampleMountingDevice {
            set result $auto_sample_msg
            if {$result == ""} {
                set result $robot_sample
            }
        }
        videoVisexSnapshot -
        visexMoveSample -
        visexRotatePhi {
            set iPhi [lsearch -exact $system_idle gonio_phi]
            if {$iPhi >= 0} {
                set result "Rotating Phi"
            } elseif {[isString visex_msg] && $visex_msg != ""} {
                set result $visex_msg
            }
        }
        spectrometerWrap {
            if {[catch {
                set result [dict get $spectroWrap_status message]
            } errMsg]} {
                puts "dict get from spectrometerWrap failed: $errMsg"
            }
        }
        microspec_snapshot -
        microspec_phiScan -
        microspec_timeScan -
        microspec_doseScan {
            if {[catch {
                set contents [set ${picked_one}_status]
                set result [dict get $contents message]
            } errMsg]} {
                puts "dict get from ${picked_one}_status failed: $errMsg"
            }
        }
    }

    if {$result != ""} {
        return $result
    }

    #### check gap energy sync
    if {[isString gap_energy_sync] && \
    [lindex $gap_energy_sync 0] == "0"} {
        return "warning: undulator gap not sync with energy"
    }

    ## result == ""
    ##set result ""

    if {![isString energy_config]} {
        return $detector_status
    }

    set cfgList [::config getStr energy.config]
    if {[llength $cfgList] >= [llength $energy_config]} {
        foreach enabled $energy_config name $cfgList {
            if {$enabled == "0" \
            && $name != "adjust_detector_vert" \
            && $name != "move_table_horz" \
            && $name != "move_mfd_vert" \
            && $name != "move_mfd_horz" \
            } {
                lappend result $name
            }
        }
        if {$result != ""} {
            set result "warning: energy disabled: $result"
            return $result
        }
    } else {
        foreach enabled $energy_config {
            if {$enabled == "0"} {
                return "some energy conponents disabled"
            }
        }
    }
    return $detector_status
}
