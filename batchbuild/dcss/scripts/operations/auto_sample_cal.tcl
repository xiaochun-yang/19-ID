# This is operation wrap for automatic calibration of goniometer x, y, z
# using laser displacement sensor.
#
# THEORY:
# rotate phi, get distance from the sensor to the goniometer header surface.
# do Fourier analysis:
# use order 0 (average of distance) to calibrate sample_z
# use order 1 (base frequency to calibrate sample_x and sample_y
#
# NOISE REDUCTION:
# 1. over sample: take several samples per position and use the middle value
# 2. replace odd value with average of neighbors.
#
# CONSTANTS: (all stored in global string)
# string: "auto_sample_const"
# "max_cycle: 10 num_point_cal: 64 num_point_check: 64 num_point_self: 360 sample_time: 0.2 num_sample: 1 threshold_std: 4 threshold_x: 0.2 threshold_y: 0.5 threshold_z: 0.3 0.2 max_x: 2 max_y: 2 max_z: 10 max_phi_offset: 10 system_on: 1"
#

global gASCTooNoisy
set gASCTooNoisy 0

proc ASC_get_constant { name } {
    variable ::nScripts::auto_sample_const
    switch -exact -- $name {
        max_cycle       { return [lindex $auto_sample_const 1] }
        num_point_cal   { return [lindex $auto_sample_const 3] }
        num_point_check { return [lindex $auto_sample_const 5] }
        num_point_self  { return [lindex $auto_sample_const 7] }
        sample_time     { return [lindex $auto_sample_const 9] }
        num_sample      { return [lindex $auto_sample_const 11] }
        threshold_std   { return [lindex $auto_sample_const 13] }
        threshold_x     { return [lindex $auto_sample_const 15] }
        threshold_y     { return [lindex $auto_sample_const 17] }
        threshold_z     { return [lindex $auto_sample_const 19] }
        max_x           { return [lindex $auto_sample_const 21] }
        max_y           { return [lindex $auto_sample_const 23] }
        max_z           { return [lindex $auto_sample_const 25] }
        max_phi_offset  { return [lindex $auto_sample_const 27] }
        system_on       { return [lindex $auto_sample_const 29] }
        save_raw_data   { return [lindex $auto_sample_const 31] }
        noisy_flag_only { return [lindex $auto_sample_const 33] }
        default         { return -code error "bad name $name" }
    }
}
# 
# CALIBRATION RESULTS: (all stored in global string with history in file)
# from self_calibration:
# string: "auto_sample_data:"
# "mm/dd/yy-hh:mm:ss desired_average: 2.2358  scale_x: 29.8 scale_y: 29.4 scale_z: 12.2 phi_offset: -0.04"
#
proc ASC_get_cal_data { name } {
    variable ::nScripts::auto_sample_data

    switch -exact -- $name {
        desired_average { return [lindex $auto_sample_data 2] }
        scale_x         { return [lindex $auto_sample_data 4] }
        scale_y         { return [lindex $auto_sample_data 6] }
        scale_z         { return [lindex $auto_sample_data 8] }
        phi_offset_x    { return [lindex $auto_sample_data 10] }
        phi_offset_y    { return [lindex $auto_sample_data 12] }
        default         { return -code error "bad name $name" }
    }
}

proc ASC_turn_on_laser { } {
    global gOldADCCardExists
    variable ASC_restore_lights
    variable ASC_on_value
    variable ASC_mask
    variable ASC_laser_controlBOARD

    set ASC_restore_lights 1
    if {[catch centerSaveAndSetLights errMsg]} {
        log_warning lights control failed $errMsg
        set ASC_restore_lights 0
    }
    if {$gOldADCCardExists} {
        set operationHandle [eval start_waitable_operation setDigitalOutput \
        $ASC_laser_controlBOARD $ASC_on_value $ASC_mask]
    } else {
        set operationHandle [eval start_waitable_operation setDigOut \
        $ASC_laser_controlBOARD $ASC_on_value $ASC_mask]
    }
    set result [wait_for_operation_to_finish $operationHandle]
}
proc ASC_turn_off_laser { } {
    global gOldADCCardExists
    variable ASC_restore_lights
    variable ASC_off_value
    variable ASC_mask
    variable ASC_laser_controlBOARD

    if {$gOldADCCardExists} {
        set operationHandle [eval start_waitable_operation setDigitalOutput \
        $ASC_laser_controlBOARD $ASC_off_value $ASC_mask]
    } else {
        set operationHandle [eval start_waitable_operation setDigOut \
        $ASC_laser_controlBOARD $ASC_off_value $ASC_mask]
    }
    set result [wait_for_operation_to_finish $operationHandle]
    if {$ASC_restore_lights} {
        centerRestoreLights
    }
}

proc auto_sample_cal_initialize { } {
    global gLaserControl
    global gLaserRead
    variable ASC_on_value
    variable ASC_off_value
    variable ASC_mask
    ###assume both channels in the same board
    variable ASC_laser_controlBOARD

    variable ASC_laser_readBOARD
    variable ASC_laser_readCHANNEL

    loadLaserChannelConfig
    decideADCCard

    ###off means both off
    set ASC_off_value 0

    set ASC_laser_controlBOARD $gLaserControl(goniometer,BOARD)
    if {$ASC_laser_controlBOARD != $gLaserControl(sample,BOARD)} {
        log_severe need software change to support laser control on \
        different boards
        return
    }
    ###on means gonometer on and sample off
    set ASC_on_value [expr 1 << $gLaserControl(goniometer,CHANNEL)]
    set ASC_mask  [expr $ASC_on_value | (1 << $gLaserControl(sample,CHANNEL))]

    set ASC_laser_readBOARD $gLaserRead(goniometer,BOARD)
    ###skip first "normal"
    set ASC_laser_readCHANNEL [expr $gLaserRead(goniometer,CHANNEL) + 1]
}

#sub_command: self_calibration
#             calibrate_xyz
#             calibrate_xyOnly
#             check_xyz
proc auto_sample_cal_start { sub_command args } {
    global gLaserControl
    global gLaserRead
    ###clear noisy flag
    global gASCTooNoisy
    set gASCTooNoisy 0

    ###check config
    if {$gLaserControl(goniometer,BOARD) < 0 || \
    $gLaserControl(goniometer,CHANNEL) < 0 || \
    $gLaserControl(sample,BOARD) < 0 || \
    $gLaserControl(sample,CHANNEL) < 0 || \
    $gLaserRead(goniometer,BOARD) < 0 || \
    $gLaserRead(goniometer,CHANNEL) < 0} {
        return -code error "laser channel config not found"
    }


    
    set result OK

    switch -exact -- $sub_command {
        full_calibrate {
            if {![ASC_get_constant system_on]} {
                log_error "auto_sample_cal is turned off"
                return "auto_sample_cal is turned off"
            }
            if {[catch {
                ASC_updateMsg "auto center goniometer"
                move sample_x to 0
                move sample_y to 0
                move sample_z to 0
                wait_for_motors [list sample_x sample_y sample_z]
                set result [ASC_calibrate_sample_xyz]
                ASC_reset_xyz
                ASC_turn_off_laser
                ASC_updateMsg ""
            } errMsg]} {
                ASC_turn_off_laser
                ASC_updateMsg ""
                return -code error $errMsg
            }
        }
            
        move_xyz {
            move sample_x to 0
            move sample_y to 0
            move sample_z to 0
            wait_for_motors [list sample_x sample_y sample_z]
        }
        self_calibration {
            if {[catch {
                ASC_updateMsg "setup auto center gonio "
                ASC_self_calibration
                ASC_turn_off_laser
                ASC_updateMsg ""
            } errMsg]} {
                ASC_updateMsg ""
                ASC_turn_off_laser
                return -code error $errMsg
            }
        }
        calibrate_xyz {
            if {[catch {
                ASC_updateMsg "auto center gonio (no reset)"
                set result [ASC_calibrate_sample_xyz]
                ASC_turn_off_laser
                ASC_updateMsg ""
            } errMsg]} {
                ASC_updateMsg ""
                ASC_turn_off_laser
                return -code error $errMsg
            }
        }
        calibrate_xyOnly {
            if {[catch {
                ASC_updateMsg "auto center gonio sample_xy(no reset)"
                set result [ASC_calibrate_sample_xyz 0]
                ASC_turn_off_laser
                ASC_updateMsg ""
            } errMsg]} {
                ASC_updateMsg ""
                ASC_turn_off_laser
                return -code error $errMsg
            }
        }
        check_xyz {
            if {[catch {
                ASC_updateMsg "check goniometer position"
                set result [ASC_check_sample_xyz]
                ASC_turn_off_laser
                ASC_updateMsg ""
            } errMsg]} {
                ASC_updateMsg ""
                ASC_turn_off_laser
                return -code error $errMsg
            }
        }
        reset_xyz {
            ASC_reset_xyz
            #flag robot that goniometer calibration is needed
            start_operation robot_config set_flags gonio

        }
        read_files {
            eval ASC_read_files $args
        }
        default {
            return -code error "unsuppored command"
        }
    }
    return $result
}

###configure all sample_x, sample_y, and sample_z to 0
proc ASC_reset_xyz { } {
    variable sample_x
    variable sample_y
    variable sample_z

    ##### notify hardware group
    ::dcss2 sendMessage "htos_log warning hardware sample_xyz position resetted from $sample_x $sample_y $sample_z"
    
    #save log
    if [catch {open auto_sample_reset.log a} fileHandle] {
        log_error "open history file for auto sample reset failed"
    } else {

        set timeStamp [clock format [clock seconds] -format "%D-%T"]
        puts $fileHandle "$timeStamp $sample_x $sample_y $sample_z"
        close $fileHandle
    }
    configure sample_x position 0
    configure sample_y position 0
    configure sample_z position 0

    return "sample_x sample_y sample_z set to 0"
}

#check setup to run
#
proc ASC_check_condition { } {
    global gDevice

    #turn on laser
    ASC_turn_on_laser

    #check kappa
    if {abs($gDevice(gonio_kappa,scaled)) > 0.001 } {
        log_error kappa must be zero to run auto_sample_data
        return 0
    }
    return 1
}


proc ASC_scan_magnet { num_point } {
    variable gonio_omega
    variable gonio_phi
    variable sample_x
    variable sample_y
    variable sample_z

    ##retrieve saved info
    set average_time [ASC_get_constant sample_time]
    if {$average_time == ""} {
        set average_time 0
    }

    #caller will make sure num_point is in good range
    if {$num_point <= 0} {
        return ""
    }
    set phi_stepsize [expr 360.0 / $num_point]

    #get init phi: we require at init phi: sample_x and sample_y is in
    #normal position: sample_y vertical upward.
    set phi0 [expr -$gonio_omega]

    #DEBUG
    puts "scan magnet at: phi0=$phi0 x=$sample_x y=$sample_y z=$sample_z"

    set resultList {}
    for {set i 0} {$i < $num_point} {incr i} {
        set phi [expr $phi0 + $i * $phi_stepsize]
        lappend resultList [ASC_get_displacement $phi $average_time] 
    }
    
    #DEBUG
    if {[ASC_get_constant save_raw_data] == "1"} {
        set filename auto_sample_xyz[clock format [clock seconds] -format "%d%b%y%H%M%S"].scan
        if ![catch {open $filename w} fileHandle] {
            for {set i 0} {$i < $num_point} {incr i} {
                puts $fileHandle [lindex $resultList $i]
            }
            close $fileHandle
        }
    }

    return $resultList
}
proc ASC_get_displacement {phi average_time} {
    global gOldADCCardExists
    variable ASC_laser_readBOARD
    variable ASC_laser_readCHANNEL

    set num_sample [ASC_get_constant num_sample]
    if {$num_sample == "" || $num_sample < 1} {
        set num_sample 1
    }

    move gonio_phi to $phi
    wait_for_devices gonio_phi

    #sample raw data
    set rawDataList {}
    set timeInMs [expr 1000.0 * $average_time]
    for {set s 0} {$s < $num_sample} {incr s} {
        if {$gOldADCCardExists} {
            set h [start_waitable_operation readAnalog $timeInMs]
        } else {
            set h [start_waitable_operation readDaq $ASC_laser_readBOARD $timeInMs median]
        }
        set result [wait_for_operation_to_finish $h]
        if {[string first abort $result] >= 0} {
            return -code error "aborted"
        }
        lappend rawDataList [lindex $result $ASC_laser_readCHANNEL]
    }
    #take the middle value and return (without average and other .....)
    #this idea is from PSI
    return [lindex $rawDataList [expr $num_sample / 2]]
}
#it will replace the outlier with neighbor average.
#because we will do Fourier analysis, we cannot simply remove the data
#
#Our data is a ring-buffer.  The first and the last points are neighbors.
# So, we can calculate average for the first and last points too.
proc ASC_low_pass_filter { rawDataList } {
    set num_std [ASC_get_constant threshold_std]
    if {$num_std == "" || $num_std < 1} {
        set num_std 4
    }

    set num_point [llength $rawDataList]
    #less data, cannot use average to replace the raw data
    if {$num_point < 12} {
        puts "warning number of points < 12 no low pass filter"
        return $rawDataList
    }

    #############calculate the standard deviation#############
    set rawAverage 0.0
    for {set i 0} {$i < $num_point} {incr i} {
        set rawAverage [expr $rawAverage + [lindex $rawDataList $i]]
    }
    set rawAverage [expr $rawAverage / $num_point]
    #we want to save noise for later use
    set noise2List {}
    set std2 0.0
    for {set i 0} {$i < $num_point} {incr i} {
        set noise [expr [lindex $rawDataList $i] - $rawAverage]
        set noise2 [expr $noise * $noise]
        lappend noise2List $noise2
        set std2 [expr $std2 + $noise2]
        #puts "data $i: noise=$noise, noise2=$noise2"
    }
    set std2 [expr $std2 / $num_point]
    set std2Threshold [expr $std2 * $num_std * $num_std]

    #############check each2 point against std threshold##########
    set resultList {}
    set badIndexList {}
    for {set i 0} {$i < $num_point} {incr i} {
        set noise2 [lindex $noise2List $i]
        set rawValue [lindex $rawDataList $i]
        if {$noise2 > $std2Threshold} {
            #use average of 2 neighbors
            set index1 [expr $i - 1]
            set index2 [expr $i + 1]
            #we need to take special care of first and last points.
            if {$index1 < 0} {
                set index1 [expr $num_point - 1]
            }
            if {$index2 >= $num_point} {
                set index2 0
            }

            #calculate the average
            set value1 [lindex $rawDataList $index1]
            set value2 [lindex $rawDataList $index2]
            set cookedValue [expr ($value1 + $value2) / 2.0]
            lappend resultList $cookedValue

            puts "warning raw($i) noise too big: $noise2 > $std2Threshold"
            puts "warning raw($i) $rawValue=>$cookedValue"
            #this method cannot deal with bad values in a row
            if {[llength $badIndexList] >0 && \
            [lindex $badIndexList end] + 1 == $i} {
                return -code error "data too noise, try again"
            }

            lappend badIndexList $i
        } else {
            lappend resultList $rawValue
        }
    }
    if {[llength $badIndexList] > 0} {
        puts "bad index list: $badIndexList"
    }
    return $resultList
}

#do order 0 (average) and order 1 (sin/cos) analysis only
proc ASC_Fourier_analysis { dataList check_tone {debug 0} } {
    set PI 3.14159265359
    set num_point [llength $dataList]
    if {$num_point <= 0} {
        return -code error "no data passed in for ASC_Fourier_analysis"
    }

    if {0} {
    ####calculate the average
    set average 0.0
    for {set i 0} {$i < $num_point} {incr i} {
        set average [expr $average + [lindex $dataList $i]]
    }

    #DEBUG
    puts "ASC average=$average"

    #accumulate
    set sine_delta 0.0
    set cosine_delta 0.0
    set stepSize [expr $PI * 2 / $num_point]
    for {set i 0} {$i < $num_point} {incr i} {
        set value [lindex $dataList $i]
        set angle [expr -$stepSize * $i]
        set sd [expr $value * sin($angle)]
        set cd [expr $value * cos($angle)]
        set sine_delta [expr $sine_delta + $sd]
        set cosine_delta [expr $cosine_delta + $cd]
        #puts "angle$i=$angle value=$value sd=$sd cd=$cd"
    }
    } else {
        set result [generic_DFT $dataList]
        if {$debug} {
            send_operation_update "DFT result:"
            set i 0
            foreach component $result {
                send_operation_update "component $i: $component"
                incr i
            }
        }
        
        set average [lindex [lindex $result 0] 0]
        set first [lindex $result 1]
        set cosine_delta [lindex $first 0]
        set sine_delta [lindex $first 1]

        #error check:
        #compare amplitude of each components.
        #if tone (cosX, sinX) is not greater than
        # 5 times the other ones, flag failed.
        puts "check tone"
        set firstA2 [expr $cosine_delta * $cosine_delta + $sine_delta * $sine_delta]
        if {$check_tone} {
            #tone amplitude must be 5 times greater than noise
            set maxA2 [expr $firstA2 / 25.0]
            puts "set maxA2 to: $maxA2"
        } else {
            #check_tone is setup when sample_x or sample_y move 1 mm
            #so let's try to get a maxA2 from constants and data
            set scale_x [ASC_get_cal_data scale_x]
            if {$scale_x == "" || $scale_x == 0 || abs($scale_x) > 100.0} {
                set scale_x 30.0
            }
            set fake_a [expr 1.0 / $scale_x]
            set fake_firstA2 [expr $fake_a * $fake_a * $num_point * $num_point]
            if {$firstA2 > $fake_firstA2} {
                set maxA2 [expr $firstA2 / 25.0]
                puts "set maxA2 to: $maxA2"
            } else {
                set maxA2 [expr $fake_firstA2 / 25.0]
                puts "set fake maxA2 to: $maxA2"
            }
        }
        set maxPoint [expr $num_point / 2 + 1]
        set a2List {}
        lappend a2List $firstA2
        set too_noisy 0
        for {set i 2} {$i < $maxPoint} {incr i} {
            set pair [lindex $result $i]
            set c [lindex $pair 0]
            set s [lindex $pair 1]
            set a2 [expr $c * $c + $s * $s]
            lappend a2List $a2
            if {$i > 2 && $a2 > $maxA2} {
                puts "too noisy at $i amp2=$a2 > maxA2=$maxA2"
                set too_noisy 1
            }
        }
        if {$debug} {
            send_operation_update "a2List"
            set i 0
            foreach a2 $a2List {
                send_operation_update "a2 $i: $a2"
                incr i
            }
        }
        if {$too_noisy} {
            set flag_only [ASC_get_constant noisy_flag_only]
            if {$flag_only != "1"} {
                log_error "too noisy, maybe ice or hardware failure"
                puts "too noisy a2List: $a2List"
                return -code error "too noisy, maybe ice or hardware failure"
            } else {
                puts "warning flagged too noisy, maybe ice or hardware failure"
                puts "warning a2List: $a2List"
                global gASCTooNoisy
                set gASCTooNoisy 1
            }
        }
    }
    set average [expr $average / $num_point]
    set sine_delta [expr $sine_delta / $num_point]
    set cosine_delta [expr $cosine_delta / $num_point]

    #DEBUG
    puts "sine_delta=$sine_delta cosine_delta=$cosine_delta"
    
    return [list $average $sine_delta $cosine_delta]
}

proc ASC_collect_data { num_point {check_tone 0} } {
    set raw_data [ASC_scan_magnet $num_point]
    set cooked_data [ASC_low_pass_filter $raw_data]
    return [ASC_Fourier_analysis $cooked_data $check_tone]
}

#as long as the init spot is in the middle of the surface and
# sample_x, y, z are close to 0, this method should work.
#
#BEST PRACTICE:
#do this
#do calibration
#do this again
#
# This function will get Fourier results for current setup
# then move sample_x 1 mm do it again,
# then move back and move sample_y 1 mm and do it again.
# then move back and move sample_z 1 mm and do it again.
proc ASC_self_calibration { {test_from_files 0} } {
    variable ::nScripts::auto_sample_data
    variable gonio_phi

    global ASC_files

    set PI 3.14159265359

    set DELTA_SAMPLE_X 1.0
    set DELTA_SAMPLE_Y 1.0
    set DELTA_SAMPLE_Z 1.0

    ASC_check_condition

    set old_phi $gonio_phi

    set max_phi_offset [ASC_get_constant max_phi_offset]
    if {$max_phi_offset == "" || $max_phi_offset <= 2} {
        log_warning bad max_phi_offset in auto_sample_const
        set max_phi_offset 10
    }

    set timeStamp [clock format [clock seconds] -format "%D-%T"]
    
    set num_point [ASC_get_constant num_point_self]
    if {$num_point == "" || $num_point < 16} {
        log_warning bad num_point_self in string auto_sample_const
        set num_point 360
    }

    for {set loop 0} {$loop < 4} {incr loop} {
        switch -exact -- $loop {
            0 {
                if {$test_from_files} {
                    set result [ASC_test_file [lindex $ASC_files 0]]
                } else {
                    set result [ASC_collect_data $num_point]
                }
                puts "loop $loop: result=$result"
                foreach {average0 sine_delta0 cosine_delta0} $result break
            }
            1 {

                if {$test_from_files} {
                    set result [ASC_test_file [lindex $ASC_files 1] 1]
                } else {
                    move sample_y by $DELTA_SAMPLE_Y mm
                    wait_for_motors sample_y
                    set result [ASC_collect_data $num_point 1]
                }
                puts "loop $loop: result=$result"
                foreach {average1 sine_delta1 cosine_delta1} $result break
                set sine_delta1 [expr $sine_delta1 - $sine_delta0]
                set cosine_delta1 [expr $cosine_delta1 - $cosine_delta0]
                set phi_offset_from_y [expr -atan2(-$cosine_delta1, $sine_delta1)]
                set phi_offset_from_y_degree [expr $phi_offset_from_y * 180.0 / $PI]
                puts "offset from y: $phi_offset_from_y_degree"
                foreach {delta_y should_be_zero} [ASC_phi_correction $sine_delta1 $cosine_delta1 $phi_offset_from_y] break
                if {abs($delta_y) < 100.0 * abs($should_be_zero)} {
                    log_warning bad phi_offset from y: $delta_y $should_be_zero
                }
            }
            2 {
                if {$test_from_files} {
                    set result [ASC_test_file [lindex $ASC_files 2] 1]
                } else {
                    move sample_y by -$DELTA_SAMPLE_Y mm
                    move sample_x by $DELTA_SAMPLE_X mm
                    wait_for_motors [list sample_x sample_y]
                    set result [ASC_collect_data $num_point 1]
                }
                puts "loop $loop: result=$result"
                foreach {average2 sine_delta2 cosine_delta2} $result break
                set sine_delta2 [expr $sine_delta2 - $sine_delta0]
                set cosine_delta2 [expr $cosine_delta2 - $cosine_delta0]
                set phi_offset_from_x [expr atan2($sine_delta2, -$cosine_delta2)]
                set phi_offset_from_x_degree [expr $phi_offset_from_x * 180.0 / $PI]
                puts "raw offset: y: $phi_offset_from_y_degree x: $phi_offset_from_x_degree"
                foreach {should_be_zero delta_x} [ASC_phi_correction $sine_delta2 $cosine_delta2 $phi_offset_from_x] break
                if {abs($delta_x) < 100.0 * abs($should_be_zero)} {
                    log_warning bad phi_offset from x: $delta_x $should_be_zero
                }
            }
            3 {
                if {$test_from_files} {
                    set result [ASC_test_file [lindex $ASC_files 3]]
                } else {
                    move sample_x by -$DELTA_SAMPLE_X mm
                    move sample_z by $DELTA_SAMPLE_Z mm
                    wait_for_motors [list sample_z sample_x]
                    set result [ASC_collect_data $num_point]
                }
                puts "loop $loop: result=$result"
                foreach {average3 sine_delta3 cosine_delta3} $result break
            }
        }
    }
    #move back to origianl position
    if {!$test_from_files} {
        move sample_z by -$DELTA_SAMPLE_Z mm
        move gonio_phi to $old_phi
        wait_for_motors [list gonio_phi sample_z]
    }

    ######### analysis result ############
    ############ take out background #########

    ######### check polarization of the ADC card #######
    #we do not require that when sensor distance increases, the
    #input from ADC should increase.
    #we can use scale_z to find it out.
    #we moved sample_z from 0 to +1 mm 
    #with correct setup, $average3 should be less than $average0
    #we define:
    #scale_x as delta_of_sample_x over delta_of_cosine
    #scale_y as delta_of_sample_y over delta_of_sine
    #scale_z as delta_of_sample_z over delta_of_average
    #so in correct setup, all of them should be negative

    set delta_z [expr $average3 - $average0]
    if {$delta_z > 0} {
        log_warning laser sensor to ADC card wire polarization error
        set phi_offset_from_x_degree [expr 180.0 + $phi_offset_from_x_degree]
        set phi_offset_from_y_degree [expr 180.0 + $phi_offset_from_y_degree]
    }

    puts "phi_offset: x: $phi_offset_from_x_degree y: $phi_offset_from_y_degree"
    if {abs($phi_offset_from_y_degree - $phi_offset_from_x_degree) > 2* $max_phi_offset} {
        log_error "data too noisy phi offset not match between x and y"
        #return -code error "data too noisy: abort"
    }


    send_operation_update "delta: $delta_x $delta_y $delta_z"


    if {abs($phi_offset_from_x_degree) > $max_phi_offset ||
    abs($phi_offset_from_y_degree) > $max_phi_offset} {
        log_warning detected phi+omega offset exceed $max_phi_offset degree.
        #return -code error "failed phi+omega offset too big"
    }
    

    if {$delta_x == 0} {
        return -code error "delta_x == 0: problem moving sample_x"
    }
    if {$delta_y == 0} {
        return -code error "delta_y == 0: problem moving sample_y"
    }
    if {$delta_z == 0} {
        return -code error "delta_z == 0: problem moving sample_z"
    }

    set desired_z $average0
    set const_x [expr $DELTA_SAMPLE_X / $delta_x]
    set const_y [expr $DELTA_SAMPLE_Y / $delta_y]
    set const_z [expr $DELTA_SAMPLE_Z / $delta_z]

    #check sanity
    if {abs($const_x) > 100.0} {
        log_error "scale_x $const_x exceed reasonable range"
        return -code error "scale_x $const_x exceed reasonable range"
    }
    if {abs($const_y) > 100.0} {
        log_error "scale_y $const_y exceed reasonable range"
        return -code error "scale_y $const_y exceed reasonable range"
    }
    if {abs($const_z) > 100.0} {
        log_error "scale_z $const_z exceed reasonable range"
        return -code error "scale_z $const_z exceed reasonable range"
    }

    #save to string
    if {$test_from_files} {
        set result [list $timeStamp desired_average: $desired_z scale_x: $const_x scale_y: $const_y scale_z: $const_z phi_offset_x: $phi_offset_from_x phi_offset_y: $phi_offset_from_y]
        send_operation_update $result
        return $result
    }

    set auto_sample_data [list $timeStamp desired_average: $desired_z scale_x: $const_x scale_y: $const_y scale_z: $const_z phi_offset_x: $phi_offset_from_x phi_offset_y: $phi_offset_from_y]

    #DEBUG
    send_operation_update $auto_sample_data

    #save to history file
    #impAppendTextFile $userName $SID $filename $contents
    if [catch {open auto_sample_cal.log a} fileHandle] {
        log_error "open history file for auto sample cal failed"
    } else {
        puts $fileHandle $auto_sample_data
        global gASCTooNoisy
        if {$gASCTooNoisy} {
           puts $fileHandle "too noisy flagged"
        }
        close $fileHandle
    }
}

proc ASC_convert_delta { delta_x delta_y average } {
    ###############get and check constants##################
    set desired_z [ASC_get_cal_data desired_average]
    set const_x   [ASC_get_cal_data scale_x]
    set const_y   [ASC_get_cal_data scale_y]
    set const_z   [ASC_get_cal_data scale_z]
    set phi_offset_x [ASC_get_cal_data phi_offset_x]
    set phi_offset_y [ASC_get_cal_data phi_offset_y]
    if {$const_x == 0 || $const_y == 0 || $const_z == 0 ||
    abs($const_x) > 100.0 || abs($const_y) > 100.0 || abs($const_z) > 100.0 } {
        return -code error "bad constants: $const_x, $const_y, $const_z"
    }

    set delta_z [expr $average - $desired_z]
    puts "raw delta: $delta_x $delta_y $delta_z"

    #correction for phi offset
    foreach {dummy_y corrected_delta_x} [ASC_phi_correction $delta_y $delta_x $phi_offset_x] break
    foreach {corrected_delta_y dummy_x} [ASC_phi_correction $delta_y $delta_x $phi_offset_y] break
    #DEBUG
    puts "after phi correction delta: $corrected_delta_x $corrected_delta_y"

    #convert to mm
    set delta_x [expr $corrected_delta_x * $const_x]
    set delta_y [expr $corrected_delta_y * $const_y]
    set delta_z [expr $delta_z * $const_z]

    #DEBUG
    puts "mm delta: $delta_x $delta_y $delta_z"

    return [list $delta_x $delta_y $delta_z]
}
proc ASC_collect_delta { num_point } {
    #do the data collection
    set result [ASC_collect_data $num_point]
    foreach {average delta_y delta_x} $result break
    return [ASC_convert_delta $delta_x $delta_y $average]
}

proc ASC_correct_motors { delta_x delta_y delta_z correct_z } {
    ###############get and check constants##################
    set max_x [ASC_get_constant max_x]
    set max_y [ASC_get_constant max_y]
    set max_z [ASC_get_constant max_z]

    if {$max_x == "" || $max_x <= 0 || $max_x > 2.0} {
        log_warning bad max_x in string auto_sample_const
        set max_x 2.0
    }
    if {$max_y == "" || $max_y <= 0 || $max_y > 2.0} {
        log_warning bad max_y in string auto_sample_const
        set max_y 2.0
    }
    if {$max_z == "" || $max_z <= 0 || $max_z > 10.0} {
        log_warning bad max_z in string auto_sample_const
        set max_z 10.0
    }

    #DEBUG
    puts "max: $max_x $max_y $max_z"

    ####### check range ########
    if {$correct_z && abs($delta_z) > $max_z} {
        log_warning delta_z exceed max_z, will only correct z
        set delta_z [expr $delta_z > 0 ? $max_z : -$max_z]
        move sample_z by [expr -$delta_z]
        wait_for_motors sample_z
        return
    }
    if {abs($delta_x) > $max_x} {
        log_warning delta_x exceeds max_x, reduced
        set delta_x [expr $delta_x > 0 ? $max_x : -$max_x]
    }
    if {abs($delta_y) > $max_y} {
        log_warning delta_y exceeds max_y, reduced
        set delta_y [expr $delta_y > 0 ? $max_y : -$max_y]
    }
    if {$correct_z} {
        log_warning correct motor $delta_x $delta_y $delta_z
        move sample_x by [expr -$delta_x]
        move sample_y by [expr -$delta_y]
        move sample_z by [expr -$delta_z]
        wait_for_motors [list sample_x sample_y sample_z]
    } else {
        log_warning correct motor $delta_x $delta_y
        move sample_x by [expr -$delta_x]
        move sample_y by [expr -$delta_y]
        wait_for_motors [list sample_x sample_y]
    }
}

#check whether deltas exceed thresholds.
#if failed, it will try again with double points
proc ASC_check_sample_xyz { } {
    variable gonio_phi

    ASC_check_condition

    set timeStamp [clock format [clock seconds] -format "%D-%T"]

    #save old phi and move back at the end
    set old_phi $gonio_phi

    ###############get and check constants##################
    ASC_get_threshold threshold_x threshold_y threshold_z
    set num_point [ASC_get_constant num_point_check]
    if {$num_point == "" || $num_point < 16} {
        set num_point 64
        puts "warning bad num_point_check in string auto_sample_const"
    }

    #DEBUG
    puts "threshold:  $threshold_x, $threshold_y, $threshold_z"

    for {set loop 0} {$loop < 2} {incr loop} {
        #do the data collection
        foreach {delta_x delta_y delta_z} [ASC_collect_delta $num_point] break

        #check thresholds
        if {abs($delta_x) < $threshold_x && \
        abs($delta_y) < $threshold_y && \
        abs($delta_z) < $threshold_z} {
            move gonio_phi to $old_phi

            #save log
            if [catch {open auto_sample_chk.log a} fileHandle] {
                log_error "open history file for auto sample check failed"
            } else {
                global gASCTooNoisy
                if {$gASCTooNoisy} {
                    puts $fileHandle "$timeStamp $delta_x $delta_y $delta_z PASSED (too noisy flagged)"
                } else {
                    puts $fileHandle "$timeStamp $delta_x $delta_y $delta_z PASSED"
                }
                close $fileHandle
            }
            wait_for_motors gonio_phi
            return "$delta_x $delta_y $delta_z"
        }
        set num_point [expr $num_point * 2]
    }

    #####failed#######
    move gonio_phi to $old_phi
    #log
    if [catch {open auto_sample_chk.log a} fileHandle] {
        log_error "open history file for auto sample check failed"
    } else {
        global gASCTooNoisy
        if {$gASCTooNoisy} {
            puts $fileHandle "$timeStamp $delta_x $delta_y $delta_z FAILED (too noisy flagged)"
        } else {
            puts $fileHandle "$timeStamp $delta_x $delta_y $delta_z FAILED"
        }
        close $fileHandle
    }
    wait_for_motors gonio_phi
    ##### key word "check_xyz_failed" is used in SampleMountingDevice
    return -code error "check_xyz_failed $delta_x $delta_y $delta_z"
}

proc ASC_calibrate_sample_xyz { {correct_z 1} } {
    variable gonio_phi

    ASC_check_condition

    #save phi
    set old_phi $gonio_phi

    ###############get and check constants##################
    ASC_get_threshold threshold_x threshold_y threshold_z
    set max_cycle [ASC_get_constant max_cycle]
    set num_point [ASC_get_constant num_point_cal]
    if {$max_cycle == "" || $max_cycle < 1} {
        log_warning bad max_cycle in string auto_sample_const
        set max_cycle 1
    }
    if {$num_point == "" || $num_point < 16} {
        set num_point 64
        log_warning bad num_point_cal in string auto_sample_const
    }

    #DEBUG
    puts "num_point=$num_point max_cycle=$max_cycle"
    puts "threshold:  $threshold_x, $threshold_y, $threshold_z"

    set offsetXList {}
    set offsetYList {}
    set offsetZList {}
    for {set cycle 0} {$cycle < $max_cycle} {incr cycle} {
        foreach {delta_x delta_y delta_z} [ASC_collect_delta $num_point] break
        lappend offsetXList $delta_x
        lappend offsetYList $delta_y
        lappend offsetZList $delta_z
        #move the motors
        puts "correct motor: $delta_x $delta_y $delta_z $correct_z"
        ASC_correct_motors $delta_x $delta_y $delta_z $correct_z

        #########check threshold############
        if {abs($delta_x) < $threshold_x && \
        abs($delta_y) < $threshold_y && \
        abs($delta_z) < $threshold_z} {
            move gonio_phi to $old_phi
            wait_for_motors gonio_phi
            puts "OK in cycle $cycle: $delta_x $delta_y $delta_z"
            return "$delta_x $delta_y $delta_z"
        }
    }

    ######## we failed ##########
    log_warning sample xyz calibration failed
    log_warning Xoffset: $offsetXList
    log_warning Yoffset: $offsetYList
    log_warning Zoffset: $offsetZList
    move gonio_phi to $old_phi
    wait_for_motors gonio_phi
    return -code error "failed"
}
proc ASC_phi_correction { sine_delta cosine_delta phi_offset } {
    set orignalAngle [expr atan2($sine_delta,$cosine_delta)]
    set amp [expr sqrt($sine_delta * $sine_delta + $cosine_delta * $cosine_delta)]

    set newAngle [expr $orignalAngle + $phi_offset]
    set newSineDelta [expr $amp * sin($newAngle)]
    set newCosineDelta [expr $amp * cos($newAngle)]

    #DEBUG
    puts "deltas:$sine_delta $cosine_delta changed to $newSineDelta $newCosineDelta"

    return [list $newSineDelta $newCosineDelta]
}
proc ASC_get_threshold { x_name y_name z_name } {
    upvar $x_name threshold_x
    upvar $y_name threshold_y
    upvar $z_name threshold_z

    set threshold_x [ASC_get_constant threshold_x]
    set threshold_y [ASC_get_constant threshold_y]
    set threshold_z [ASC_get_constant threshold_z]

    if {$threshold_x == "" || $threshold_x <= 0 || $threshold_x >= 1.0 } {
        set threshold_x 0.3
        log_warning bad threshold_x in string auto_sample_const
    }
    if {$threshold_y == "" || $threshold_y <= 0 || $threshold_y >= 1.0 } {
        set threshold_y 0.7
        log_warning bad threshold_y in string auto_sample_const
    }
    if {$threshold_z == "" || $threshold_z <= 0 || $threshold_z >= 1.0 } {
        set threshold_z 0.3
        log_warning bad threshold_z in string auto_sample_const
    }
}
proc ASC_read_files { args } {
    set num_file [llength $args]
    switch -exact -- $num_file {
        0 {
            return -code error "no file name found"
        }
        1 {
            set result [ASC_test_file [lindex $args 0]]
            foreach {average delta_y delta_x} $result break
            return [ASC_convert_delta $delta_x $delta_y $average]
        }
        4 {
            global ASC_files
            set ASC_files $args
            ASC_self_calibration 1
        }
        default {
            return -code error "only support 1 file or 4 files"
        }
    }
}
proc ASC_test_file { filename {check_tone 0}} {
    if [catch {open $filename r} fileHandle] {
        return -code error "failed to open file $filename to read"
    }
    set rawDataList {}
    while {[gets $fileHandle buffer] >= 0} {
        if {[llength $buffer] > 1} {
            set value [lindex $buffer 1]
        } else {
            set value $buffer
        }
        if {$value != ""} {
            lappend rawDataList $value
        }
    }

    set cookedDataList [ASC_low_pass_filter $rawDataList]
    return [ASC_Fourier_analysis $cookedDataList $check_tone 1]
}
proc ASC_updateMsg { contents_ } {
    variable auto_sample_msg

    set auto_sample_msg $contents_
}
