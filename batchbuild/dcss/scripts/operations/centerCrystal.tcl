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

#######################################
#CONFIG is via string: center_crystal_const

##################################
# temperary data are saved in string center_crystal_data
#################################################3

set CCrystalConstantNameList [list \
    system_on \
    loop_width_extra \
    loop_height_extra \
    min_column \
    max_column \
    min_row \
    max_row \
    min_step_x \
    max_step_x \
    min_step_y \
    max_step_y \
    delta \
    init_expose_time \
    increment_expose_time \
    min_expose_time \
    max_expose_time \
    background_sub \
    min_num_spot \
    target_num_spot \
    min_loop \
    max_loop \
    finish_horizontal \
    finish_vertical \
    beam_width_extra \
    beam_height_extra \
    keep_orig_beam_size \
    collimator_scan \
    collimator_scale_factor \
    collimator_min_column \
    collimator_max_column \
    collimator_min_row \
    collimator_max_row \
    collimator_min_step_x \
    collimator_max_step_x \
    collimator_min_step_y \
    collimator_max_step_y \
]
####scan_purpose: CRYSTAL SLIT
####scan_mode: VERTICAL HORIZONTAL 2D
####scan_phase: EDGE, FACE, EDGEBACK this is for log purpose
set CCrystalDataNameList [list \
    log_file_name \
    angle_phi_axis \
    phi_offset \
    scan_purpose \
    scan_mode \
    scan_phase \
    sil_id \
    column_images \
    event_id \
    sil_row_offset \
    exposure_time \
    old_beam_x \
    old_beam_y \
    old_i2 \
    old_exposure_time \
    det_mode \
    image_ext \
    loop_width \
    face_height \
    edge_height \
    scale_Hx \
    scale_Hy \
    scale_Hz \
    scale_Vx \
    scale_Vy \
    scale_Vz \
    num_row \
    num_column \
    step_x \
    step_y \
    image_list \
    center_row \
    center_column \
    boundary_start_row \
    boundary_end_row \
    boundary_start_column \
    boundary_end_column \
    crystal_width_column \
    crystal_height_row \
    crystal_width_mm \
    crystal_height_mm \
    crystal_edge_height_mm \
    max_weight \
    horizontal_done \
    vertical_done \
    h_done_reason \
    v_done_reason \
    h_done_first \
    v_done_first \
    user \
    scan_only \
    raw_weight_list \
] 

set CCrystalSessionID ""
proc centerCrystal_initialize {} {
    variable center_crystal_constant_name_list
    variable center_crystal_data_name_list
    variable CCrystalConstantNameList
    variable CCrystalDataNameList

    variable CCrystalUniqueIDList

    set center_crystal_constant_name_list $CCrystalConstantNameList
    set center_crystal_data_name_list     $CCrystalDataNameList

    set CCrystalUniqueIDList [list]

    namespace eval ::centerCrystal {
        set center_crystal_data ""
    }

    variable ::centerCrystal::center_crystal_data

    set ll [llength $CCrystalDataNameList]
    for {set i 0} {$i < $ll} {incr i} {
        lappend center_crystal_data $i
    }
    puts "init center_crystal_data to length =$ll"
}

proc centerCrystal_start { user sessionID directory filePrefix args } {
    global gMotorBeamWidth
    global gMotorBeamHeight

    variable attenuation
    variable $gMotorBeamWidth
    variable $gMotorBeamHeight
    variable gonio_phi
    variable sample_x
    variable sample_y
    variable sample_z
    variable center_crystal_msg
    variable CCrystalSessionID
    variable scan3DSetup_info

    if {[catch correctPreCheckMotors errMsg]} {
        log_error failed to correct motors $errMsg
        return -code error $errMsg
    }

    if {[isString user_collimator_status]} {
        collimatorNormalIn
    }

    set timeStart [clock seconds]

    if {$sessionID == "SID"} {
        set sessionID PRIVATE[get_operation_SID]
        puts "centerCrystal use operation SID: [SIDFilter $sessionID]"
    }

    if {[catch {impCreateDirectory $user $sessionID $directory} errMsg]} {
        if {[string first already $errMsg] < 0} {
            set center_crystal_msg "error: directory"
            return -code error "create directory $directory failed: $errMsg"
        }
    }
    CCrystalMakeSureDataHasEnoughSpace

    ###clear old ion chamber reading so that it will not scale using
    ###data from previous run
    save_center_crystal_data old_i2 0

    set log_file_name [file join $directory ${filePrefix}.log]
    save_center_crystal_data log_file_name $log_file_name
    set contents "$user start center crystal\n"
    append contents "directory=$directory filePrefix=$filePrefix\n"
    append contents [format "beamsize: %5.3fX%5.3f phi: %8.3f\n" \
    [set $gMotorBeamWidth] [set $gMotorBeamHeight] $gonio_phi]
    #####call write file to overwrite if file exists.
    impWriteFile $user $sessionID $log_file_name $contents false

    #### we need these to write log file
    save_center_crystal_data user $user
    set CCrystalSessionID $sessionID

    ##### the purpose of this centering
    set toAlignSlits 0
    if {[lindex $args 0] == "1"} {
        set toAlignSlits 1
        CCrystalLog "CENTER SLITS"
    }
    if {$toAlignSlits} {
        save_center_crystal_data scan_purpose SLIT
    } else {
        save_center_crystal_data scan_purpose CRYSTAL
    }
    set angle_phi_axis [lindex $args 1]
    if {[string is double -strict $angle_phi_axis]} {
        save_center_crystal_data angle_phi_axis $angle_phi_axis
    } else {
        save_center_crystal_data angle_phi_axis 0.0
    }
    
    set phi_offset [lindex $args 2]
    if {[string is double -strict $phi_offset]} {
        save_center_crystal_data phi_offset $phi_offset
    } else {
        save_center_crystal_data phi_offset 0.0
    }

    ##### save to restore after operation
    set orig_beam_x [set $gMotorBeamWidth]
    set orig_beam_y [set $gMotorBeamHeight]
    set orig_gonio_phi $gonio_phi
    set orig_attenuation $attenuation

    ##### save to restore in case of failure and aborted
    set orig_sample_x $sample_x
    set orig_sample_y $sample_y
    set orig_sample_z $sample_z

    ################catch everything##############
    # in case of any failure, restore
    # beam size and phi.
    # in case of total failure, sample_x, y z
    # will be restored.
    ##############################################

    set manual_scan 0
    save_center_crystal_data scan_only 0
    set arg0 [lindex $args 0]
    if {$arg0 == "rastering"} {
        set manual_scan 1
    }

    if {[lindex $args 0] == "use_collimator_constant"} {
        set use_collimator_constant 1
    } else {
        set use_collimator_constant 0
    }

    set scan3DSetup_info [lreplace $scan3DSetup_info 11 11 3]

    set result "success"
    set skipBeamSize 0
    if {[catch {
        ###do not delete until check tight up in sil.
        ###CCrystalDeleteDefaultSil
        CCrystalCreateDefaultSil
        CCrystalSetupEnvironments $manual_scan $use_collimator_constant
        ###DEBUG
        CCrystalLogConstant

        #### save new values after loop centering
        # if failed later, they will be used instead of the old original ones
        set orig_gonio_phi $gonio_phi
        set orig_sample_x $sample_x
        set orig_sample_y $sample_y
        set orig_sample_z $sample_z

        if {!$manual_scan} {
            set log_contents \
            "loop size width=[get_center_crystal_data loop_width]"

            append log_contents \
            " face_height=[get_center_crystal_data face_height]"

            append log_contents \
            " edge_height=[get_center_crystal_data edge_height]"

            CCrystalLog $log_contents
        }

        if {$manual_scan} {
            if {![eval CCrystalDoManualScan \
            $user $sessionID $directory $filePrefix]} {
                log_error manual scan failed
                return -code error "manual crystal scan failed"
            }
            CCrystalLog "manual scan successed"
            return
        }

        CCrystalCalculateXYScale;###call for each phi

        ######## 2-D scan to find center of edge  #######
        set file_prefix ${filePrefix}_edge
        if {[CCrystalEdgeScan $user $sessionID $directory $file_prefix]} {
            set crystal_edge_height [get_center_crystal_data crystal_height_mm]
            save_center_crystal_data crystal_edge_height_mm $crystal_edge_height

            set h_done_first [get_center_crystal_data h_done_first]
            if {$toAlignSlits && !$h_done_first} {
                #### one more vertical scan with min step size
                set file_prefix ${filePrefix}_extra
                if {![CCrystalExtraEdgeScan $user $sessionID \
                $directory $file_prefix]} {
                    #### just warning, continue with previous center
                    CCrystalLog "Warning: extra Edge scan faied"
                }
            }
            ############## 1-D scan edge back ##########
            set save_dx1 [expr $sample_x - $orig_sample_x]
            set save_dy1 [expr $sample_y - $orig_sample_y]
            set save_dz1 [expr $sample_z - $orig_sample_z]
            move sample_x to $orig_sample_x
            move sample_y to $orig_sample_y
            if {$toAlignSlits} {
                ############## 1-D scan edge back ##########
                move gonio_phi by 180
                wait_for_devices sample_x sample_y gonio_phi
                CCrystalCalculateXYScale
                set file_prefix ${filePrefix}_edbk
                if {![CCrystalEdgeBackScan $user $sessionID $directory $file_prefix]} {
                    set result "failed at edget back side"
                } else {
                    set save_dx2 [expr $sample_x - $orig_sample_x]
                    set save_dy2 [expr $sample_y - $orig_sample_y]
                    set slitY [CCrystalSlitY $orig_gonio_phi \
                    $save_dx1 $save_dy1 \
                    $save_dx2 $save_dy2]

                    CCrystalLog [format "slit vert: %.3f" $slitY]
                    if {$slitY > 0} {
                        CCrystalLog \
                        [format "vertical slits are %.3f above the phi axis" \
                        $slitY]
                    } else {
                        set temp [expr abs($slitY)]
                        CCrystalLog \
                        [format "vertical slits are %.3f below the phi axis" \
                        $temp]
                    }
                }
                move gonio_phi by 180
                wait_for_devices sample_x sample_y gonio_phi
                CCrystalCalculateXYScale
            } else {
                ############## 1-D scan face ##########
                move gonio_phi by 90
                wait_for_devices sample_x sample_y gonio_phi
                set face_phi $gonio_phi
                CCrystalCalculateXYScale
                set file_prefix ${filePrefix}_face
                if {![CCrystalFaceScan $user $sessionID $directory $file_prefix]} {
                    log_warning "center crystal partially failed at face side"
                    CCrystalLog "center crystal partially failed at face side"
                    set center_crystal_msg "error: face side failed"
                }

                #rotate back to original face
                move gonio_phi by -90

                # move to edge center
                move sample_x by $save_dx1
                move sample_y by $save_dy1
                wait_for_devices sample_x sample_y gonio_phi
                CCrystalCalculateXYScale
                CCrystalLog \
                "final center position: $sample_x $sample_y $sample_z"
                set do_collimator [get_center_crystal_constant collimator_scan]
                if {$do_collimator} {
                    CCrystalLogData
                    set file_prefix ${filePrefix}_clmtr
                    if {![CCrystalCollimatorScan \
                    $user $sessionID $directory $file_prefix 0]} {
                        log_error collimator scan failed
                        ## but we want to keep the crystal scan results
                        ## so, do not change result
                    } else {
                        set skipBeamSize 1
                    }
                }
            }
        } else {
            set result "center crystal failed at edge"
            set center_crystal_msg "error: failed at edge"
            log_warning $result
            CCrystalLog $result
        }
    } errMsg]} {
        if {$errMsg != ""} {
            set result $errMsg
            log_warning "center crystal failed: $errMsg"
            CCrystalLog "center crystal failed: $result"
            set center_crystal_msg "error: $result"
        }
    }
    CCrystalDeleteDefaultSil

    if {$result != "success"} {
        #### restore sample x, y, z
        move sample_x to $orig_sample_x
        move sample_y to $orig_sample_y
        move sample_z to $orig_sample_z
        wait_for_devices sample_x sample_y sample_z
        log_warning "sample position restored"
    }

    start_recovery_operation detector_stop
    if {$result == "success" && !$toAlignSlits && !$manual_scan} {
        set crystal_edge_height_mm \
        [get_center_crystal_data crystal_edge_height_mm]

        set crystal_face_height_mm \
        [get_center_crystal_data crystal_height_mm]

        if {$crystal_edge_height_mm > $crystal_face_height_mm} {
            set final_height $crystal_edge_height_mm
        } else {
            set final_height $crystal_face_height_mm
        }
        set final_width [get_center_crystal_data crystal_width_mm]
        CCrystalLog [format "Final Crystal Size on Loop Face : %.3f X %.3f mm" \
        $final_width $crystal_face_height_mm]
        CCrystalLog [format "Final Crystal Size on Loop Edge : %.3f X %.3f mm" \
        $final_width $crystal_edge_height_mm]

        set beam_width_extra [get_center_crystal_constant beam_width_extra]
        set beam_height_extra [get_center_crystal_constant beam_height_extra]
        set xfactor [expr 1.0 + $beam_width_extra * 0.01]
        set yfactor [expr 1.0 + $beam_height_extra * 0.01]
        set final_beam_x [expr $final_width * $xfactor]
        set final_beam_y [expr $final_height * $yfactor]
        CCrystalLimitStepSizeX final_beam_x
        CCrystalLimitStepSizeY final_beam_y

        ####make sure the beamsize is within software limits of beamsize
        ###even they are not enabled
        CCrystalBeamSizeLimit final_beam_x final_beam_y

        CCrystalLog [format "Final Beam Size: %.3fX%.3f" \
        $final_beam_x $final_beam_y]

        if {[catch {
            get_center_crystal_constant keep_orig_beam_size
        } keep_orig]} {
            set keep_orig 0
        }

        if {!$skipBeamSize} {
            if {$keep_orig == "1"} {
                move $gMotorBeamWidth to $orig_beam_x
                move $gMotorBeamHeight to $orig_beam_y
            } else {
                move $gMotorBeamWidth to $final_beam_x
                move $gMotorBeamHeight to $final_beam_y
            }
        }
    } else {
        move $gMotorBeamWidth to $orig_beam_x
        move $gMotorBeamHeight to $orig_beam_y
    }
    wait_for_devices $gMotorBeamWidth $gMotorBeamHeight

    ####It is better to leave the crystal face to the beam
    ###move gonio_phi   to $orig_gonio_phi

    move attenuation to $orig_attenuation
    #wait_for_devices gonio_phi attenuation
    wait_for_devices attenuation
    CCrystalLog "end of center crystal"
    set center_crystal_msg ""

    set timeEnd [clock seconds]

    set timeUsed [expr $timeEnd - $timeStart]
    set timeUsedText [CCrystalGetRelativeTimeText $timeUsed]
    CCrystalLog "time used: $timeUsedText === $timeUsed seconds"

    CCrystalLogData


    cleanupAfterAll

    if {$result != "success"} {
        return -code error $result
    }
    if {$toAlignSlits} {
        return $slitY
    }
    return $result
}

########################################################################
########################### setup ######################################
########################################################################
proc CCrystalSetupEnvironments { manual_scan use_collimator_constant } {
    variable center_crystal_const
    variable collimator_center_crystal_const
    variable ccrystal_constant_snapshot

    ##### save environments to snapshot so that any chang during
    ### operation will not affect the current operation
    if {$use_collimator_constant} {
        set ccrystal_constant_snapshot $collimator_center_crystal_const
    } else {
        set ccrystal_constant_snapshot $center_crystal_const
    }

    ##### fill running parameters
    set exposureTime    [get_center_crystal_constant init_expose_time]
    set newTime [CCrystalSetExposureTime $exposureTime]
    if {$newTime != $exposureTime} {
        CCrystalLog "exposure time inited to $newTime"
    }
    
    save_center_crystal_data sil_row_offset 0

    if {$manual_scan} {
        return
    }

    #########get loop size
    CCrystalGetLoopSize width faceHeight edgeHeight

    ######### may need to increase loop size in case of tilted phi ######
    set degree_angle_phi_axis [get_center_crystal_data angle_phi_axis]
    if {$degree_angle_phi_axis != 0.0} {
        set angle_phi_axis [expr $degree_angle_phi_axis * 3.1415927 / 180.0]
        set sin_phi_axis [expr sin($angle_phi_axis)]

        set minEdge [expr $faceHeight * abs($sin_phi_axis)]
        set minFace [expr $edgeHeight * abs($sin_phi_axis)]
        if {$edgeHeight < $minEdge} {
            CCrystalLog [format "increase edge height by tilt to %.3f" $minEdge]
            set edgetHeight $minEdge
        }
        if {$faceHeight < $minFace} {
            CCrystalLog [format "increase face height by tilt to %.3f" $minFace]
            set faceHeight $minFace
        }
    }

    save_center_crystal_data loop_width $width
    save_center_crystal_data face_height $faceHeight
    save_center_crystal_data edge_height $edgeHeight
}
proc CCrystalCalculateXYScale { } {
    variable gonio_phi
    variable gonio_omega

    set degree_angle_phi_axis [get_center_crystal_data angle_phi_axis]
    set angle_phi_axis [expr $degree_angle_phi_axis * 3.1415927 / 180.0]
    set sin_phi_axis [expr sin($angle_phi_axis)]
    set cos_phi_axis [expr cos($angle_phi_axis)]

    #CCrystalLog "phi axis angle: $degree_angle_phi_axis -H: $sin_phi_axis V: $cos_phi_axis"

    set phi_offset [get_center_crystal_data phi_offset]

    set angleInDegree [expr $gonio_phi + $gonio_omega + $phi_offset]
    set angleInDegree [expr -90.0 - $angleInDegree]
    set angle [expr $angleInDegree * 3.14159 / 180.0]
    set scaleX [expr sin($angle)]
    set scaleY [expr cos($angle)]

    #CCrystalLog "angle: $angleInDegree scaleX: $scaleX scaley: $scaleY"

    set scaleVx [expr $cos_phi_axis * $scaleX]
    set scaleVy [expr $cos_phi_axis * $scaleY]
    set scaleVz [expr $sin_phi_axis * (-1.0)]

    set scaleHx [expr $sin_phi_axis * $scaleX]
    set scaleHy [expr $sin_phi_axis * $scaleY]
    set scaleHz [expr $cos_phi_axis * 1.0]

    save_center_crystal_data scale_Hx $scaleHx
    save_center_crystal_data scale_Hy $scaleHy
    save_center_crystal_data scale_Hz $scaleHz
    save_center_crystal_data scale_Vx $scaleVx
    save_center_crystal_data scale_Vy $scaleVy
    save_center_crystal_data scale_Vz $scaleVz
}
proc CCrystalSetInitEdgeScanNum { } {
    #########get loop size
    #set scan_purpose [get_center_crystal_data scan_purpose]
    #if {$scan_purpose == "SLIT"} {
    #    set max_col [get_center_crystal_constant max_column]
    #    set max_step_x [get_center_crystal_constant max_step_x]
    #    set max_row [get_center_crystal_constant max_row]
    #    set max_step_y [get_center_crystal_constant max_step_y]

    #    set width  [expr $max_step_x * $max_col]
    #    set height [expr $max_step_y * $max_row]
    #    CCrystalLog "Align Slits: max size $width $height"
    #} else {
        set width  [get_center_crystal_data loop_width]
        set height [get_center_crystal_data edge_height]
    #}

    #### clear done flag
    save_center_crystal_data horizontal_done 0
    save_center_crystal_data vertical_done 0
    CCrystalSetup2DScanParameter $width $height
}
################ 1D scan vertically with beam width equal to crystal size ##
proc CCrystalSetInitFaceScanNum { } {
    ############################## VERTICAL ##########################
    #########get loop size
    set faceHeight [get_center_crystal_data face_height]

    #### clear done flag
    save_center_crystal_data vertical_done 0
    
    CCrystalSetup1DScanParameter $faceHeight VERTICAL

    
    CCrystalAdjustExposureTimeByBeamSize 1
    #set old_expose_time [get_center_crystal_data exposure_time]
    #CCrystalLog "keep the old exposure time: $old_expose_time"
}
proc CCrystalSetInitEdgeBackScanNum { } {
    ### this for sure only be called for center SLIT
    ############################## VERTICAL ##########################
    #########get loop size
    set height [get_center_crystal_data edge_height]
    #set max_row [get_center_crystal_constant max_row]
    #set max_step_y [get_center_crystal_constant max_step_y]
    #set height [expr $max_step_y * $max_row]

    #### clear done flag
    save_center_crystal_data vertical_done 0
    
    CCrystalSetup1DScanParameter $height VERTICAL
    CCrystalAdjustExposureTimeByBeamSize
}
proc CCrystalSetInitExtraEdgeScanNum { } {
    ### this for sure only be called for center SLIT
    ############################## VERTICAL ##########################
    set height [get_center_crystal_data crystal_height_mm]

    #### clear done flag
    save_center_crystal_data vertical_done 0
    
    CCrystalSetup1DScanParameter $height VERTICAL
    CCrystalAdjustExposureTimeByBeamSize
}
##################################################################
# In scan, number of steps and step size are decided by:
#
# use minimum number of steps to calculate the step size.
#
# if the step size is too big, we use the max step size to
# calculate the number of steps.
#
# if the step size is too small, we use the min step size to 
# calculate the number of steps.
#
# This will make sure the whole area is covered
#
##################################################################
proc CCrystalSetup2DScanParameter { width height } {
    puts "centerCrystal 2d setup $width $height"

    CCrystalSetup1DScanParameter $width HORIZONTAL
    CCrystalSetup1DScanParameter $height VERTICAL
    save_center_crystal_data scan_mode 2D
}

### change algorithm to:
### try max points if the step size >= min step size
proc CCrystalSetup1DScanParameter { distance direction {collimator 0} {beam_size 0}} {
    puts "centerCrystal setup 1d: $distance $direction collimator $collimator beam size=$beam_size"

    if {$collimator} {
        set tag collimator_
    } else {
        set tag ""
    }

    switch -exact -- $direction {
        VERTICAL {
            set vertical_done [get_center_crystal_data vertical_done]
            if {$vertical_done} {
                log_warning vertical already done no change
                return
            }
            set min_num  [get_center_crystal_constant ${tag}min_row]
            set max_num  [get_center_crystal_constant ${tag}max_row]
            set max_step [get_center_crystal_constant ${tag}max_step_y]
            set min_step [get_center_crystal_constant ${tag}min_step_y]
        }
        HORIZONTAL {
            set horizontal_done [get_center_crystal_data horizontal_done]
            if {$horizontal_done} {
                log_warning horizontal already done no change
                return
            }
            set min_num  [get_center_crystal_constant ${tag}min_column]
            set max_num  [get_center_crystal_constant ${tag}max_column]
            set max_step [get_center_crystal_constant ${tag}max_step_x]
            set min_step [get_center_crystal_constant ${tag}min_step_x]
        }
        default {
            return -code error "wrong direction"
        }
    }
    set num_step $max_num
    set step_size [expr $distance / double($num_step)]
    if {$beam_size > 0 && $step_size > $beam_size && $num_step > 1} {
        set step_size [expr ($distance - $beam_size) / double($num_step - 1)]
        log_warning step_size adjusted to $step_size because beam width is smaller
    }

    if {$step_size < $min_step} {
        set step_size $min_step
        set num_step [expr int(ceil($distance / double($step_size)))]
        if {$num_step < $min_num} {
            set num_step $min_num
            log_warning "increasde to min number of steps: $min_num"
        }
    } elseif {$step_size > $max_step} {
        set step_size $max_step
    }

    switch -exact -- $direction {
        VERTICAL {
            save_center_crystal_data step_y $step_size
            save_center_crystal_data num_row $num_step
        }
        HORIZONTAL {
            save_center_crystal_data step_x $step_size
            save_center_crystal_data num_column $num_step
        }
    }
    save_center_crystal_data scan_mode $direction
}
proc CCrystalIncreaseExposeTime { } {
    set current_time [get_center_crystal_data exposure_time]
    set max_time [get_center_crystal_constant max_expose_time]
    if {$current_time >= $max_time} {
        CCrystalLog "reached max exposure factor, quit"
        return 0
    }

    set new_time [CCrystalAdjustExposureTimeByNumSpot $current_time]
    #flag to skip ion chamber scaling
    save_center_crystal_data old_i2 0

    CCrystalLog "exposure factor increased to $new_time"
    return 1
}
proc CCrystalEdgeScan { user sessionID directory file_prefix } {
    CCrystalLog "Edge 2-D Scan"
    save_center_crystal_data scan_phase EDGE

    CCrystalSetInitEdgeScanNum

    return [CCrystalLoopScan $user $sessionID $directory $file_prefix]
}
proc CCrystalFaceScan { user sessionID directory file_prefix } {
    CCrystalLog "Face 1-D vertical scan"
    save_center_crystal_data scan_phase FACE

    CCrystalSetInitFaceScanNum

    return [CCrystalLoopScan $user $sessionID $directory $file_prefix]
}
proc CCrystalExtraEdgeScan { user sessionID directory file_prefix } {
    CCrystalLog "extra Edge 1-D vertical scan"
    save_center_crystal_data scan_phase EDGEEXTRA

    CCrystalSetInitExtraEdgeScanNum

    return [CCrystalLoopScan $user $sessionID $directory $file_prefix]
}
proc CCrystalEdgeBackScan { user sessionID directory file_prefix } {
    CCrystalLog "Edgeback 1-D vertical scan"
    save_center_crystal_data scan_phase EDGEBACK

    CCrystalSetInitEdgeBackScanNum

    return [CCrystalLoopScan $user $sessionID $directory $file_prefix]
}

########################################################################
########################### matrix scan ################################
########################################################################
proc CCrystalLoopScan { user sessionID directory file_prefix } {
    variable center_crystal_msg

    save_center_crystal_data h_done_first 0
    save_center_crystal_data v_done_first 0

    set max_loop [get_center_crystal_constant max_loop]

    for {set loop 0} {$loop < $max_loop} {incr loop} {
        set local_file_prefix ${file_prefix}_[expr $loop + 1]
        while {![CCrystal2DScan $user $sessionID $directory $local_file_prefix]} {
            CCrystalAdjustSilRowOffset
            if {![CCrystalIncreaseExposeTime]} {
                log_error "auto-crystal alignment failed - no diffraction"
                set center_crystal_msg "error: no diffraction"
                return 0
            }
        }
        
        #called before checking of finish.
        #it need current number of row and column
        CCrystalAdjustSilRowOffset

        ####### it also prepare next scan parameters
        if {[CCrystalSearchShouldFinish $loop]} {
            ###### print out crystal size
            set width      [get_center_crystal_data crystal_width_mm]
            set height     [get_center_crystal_data crystal_height_mm]
            set scan_phase [get_center_crystal_data scan_phase]
            set contents [format "Crystal %s Size: %5.3fX%5.3f" \
            $scan_phase $width $height]
            CCrystalLog $contents
            set center_crystal_msg $contents
            return 1
        }
    }
    log_warning "reached max loop in center crystal"
    CCrystalLog "reached max loop in center crystal"
    set center_crystal_msg "error: failed after max try"
    return 0
}
####no safety check, internal method
proc CCrystal2DScan { user sessionID directory file_prefix {skip_beamSize 0} } {
    global gMotorBeamWidth
    global gMotorBeamHeight

    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega
    variable $gMotorBeamWidth
    variable $gMotorBeamHeight
    variable center_crystal_msg

    ###########no motor should be moving
    error_if_moving \
    sample_x \
    sample_y \
    sample_z \
    gonio_phi \
    gonio_omega

    set num_row    [get_center_crystal_data num_row]
    set num_column [get_center_crystal_data num_column]
    if {$num_column * $num_row <= 1} {
        return 0
    }

    ###### save original position and move back after done before move
    ###### to new center.  Normally that is the previous center
    set orig_x   $sample_x
    set orig_y   $sample_y
    set orig_z   $sample_z
    set orig_phi $gonio_phi

    ####### get transform
    set scaleHX [get_center_crystal_data scale_Hx]
    set scaleHY [get_center_crystal_data scale_Hy]
    set scaleHZ [get_center_crystal_data scale_Hz]
    set scaleVX [get_center_crystal_data scale_Vx]
    set scaleVY [get_center_crystal_data scale_Vy]
    set scaleVZ [get_center_crystal_data scale_Vz]

    set step_x [get_center_crystal_data step_x]
    set step_y [get_center_crystal_data step_y]

    ###DEBUG
    #CCrystalLogData

    #####adjust beam size
    if {!$skip_beamSize} {
        move $gMotorBeamWidth to $step_x
        move $gMotorBeamHeight to $step_y
        save_center_crystal_data old_beam_x $step_x
        save_center_crystal_data old_beam_y $step_y
        wait_for_devices $gMotorBeamWidth $gMotorBeamHeight
    }

    move attenuation to 0
    wait_for_devices attenuation

    #scale exposure time according to ion chamber reading configed by
    #dose control
    if {[catch {
        set current_i2 [getStableIonCounts 0]
        CCrystalLog "stable ion chamber reading: $current_i2"
    } errorMsg]} {
        if {[string first aborted $errorMsg] >= 0} {
            return -code error aborted
        }
        set current_i2 0
        CCrystalLog "ion chamber reading error: $errorMsg"
    }
    set old_i2 [get_center_crystal_data old_i2]
    if {![string is double -strict $old_i2]} {
        set old_i2 0
    }
    ### exposure_time already changed by beamsize scale
    if {$current_i2 != 0 && $old_i2 != 0} {
        set old_exposure_time [get_center_crystal_data old_exposure_time]
        set new_exposure_time \
        [expr $old_exposure_time * abs( double($old_i2) / double($current_i2))]
        #CCrystalLog "by ion chamber: old time $old_exposure_time"
        #CCrystalLog "by ion chamber: old i2: $old_i2"
        #CCrystalLog "by ion chamber: new i2: $current_i2"
        #CCrystalLog "by ion chamber: new time: $new_exposure_time"


        set timeFromBeamSize [get_center_crystal_data exposure_time]
        set newTime [CCrystalAdjustExposureTimeByNumSpot $new_exposure_time]
        
        CCrystalLog "exposure factor adjusted by ion chamber to $newTime"
        CCrystalLog "DEBUG INFO: exposure factor from beamsize: $timeFromBeamSize"
    }
    

    #####move to start position

    ### first column now is defined as the max sample_z.
    ### so that the position is on the left of the sample video image
    #set horz [expr ($num_column - 1) / 2.0 * $step_x]
    set horz [expr (1 - $num_column) / 2.0 * $step_x]

    set vert [expr ($num_row - 1) / 2.0 * $step_y]

    move sample_x by [expr (-1) * ($scaleVX * $vert + $scaleHX * $horz)]
    move sample_y by [expr (-1) * ($scaleVY * $vert + $scaleHY * $horz)]
    move sample_z by [expr (-1) * ($scaleVZ * $vert + $scaleHZ * $horz)]
    wait_for_devices sample_x sample_y sample_z

    ####save
    set x0 $sample_x
    set y0 $sample_y
    set z0 $sample_z

    ###retrieve collect image parameters
    set exposeTime [get_center_crystal_data exposure_time]
    set delta      [get_center_crystal_constant delta]
    set modeIndex  [get_center_crystal_data det_mode]

    save_center_crystal_data old_i2 $current_i2
    save_center_crystal_data old_exposure_time $exposeTime

    #####use attenuation if exposure time is less than 1 second
    CCrystalLog "Exposure factor: $exposeTime of [CCrystalGetStandardDoseText]"

    foreach {att exposeTime} \
    [CCrystalGetExposureFromFactor $exposeTime] break
    CCrystalLog "Exposure: time=$exposeTime at attenuation=$att"
    move attenuation to $att
    wait_for_devices attenuation

    set scan_phase [get_center_crystal_data scan_phase]
    set contents [format \
    "%s %dX%d %.3fX%.3fmm exposure: time $exposeTime attenuation=$att" \
    $scan_phase $num_column $num_row $step_x $step_y]
    
    CCrystalLog            $contents
    set center_crystal_msg "$scan_phase ${num_column}X${num_row}"

    if {[isOperation rasteringUpdate]} {
        set angle [expr $gonio_omega + $orig_phi]
        set path [file join $directory ${file_prefix}.scan]
        rasteringUpdate_start setup $scan_phase \
        $orig_x $orig_y $orig_z $angle \
        $step_y $step_x $num_row $num_column \
        $path
    }

    set log "filename                  phi    omega        x        y        z  bm_x  bm_y sil_row" 
    CCrystalLog $log

    set image_file_list {}
    for {set row_index 0} {$row_index < $num_row} {incr row_index} {
        set vert [expr $step_y * $row_index]
        for {set col_index 0} {$col_index < $num_column} {incr col_index} {
            set sil_row [CCrystalNodeToSILRow \
            $num_row $num_column $row_index $col_index]

            #######move to position
            #### column 1 defined as the left on the image
            #set horz [expr $step_x * $col_index]
            set horz [expr -1 * $step_x * $col_index]

            set x [expr $x0 + $scaleVX * $vert + $scaleHX * $horz]
            set y [expr $y0 + $scaleVY * $vert + $scaleHY * $horz]
            set z [expr $z0 + $scaleVZ * $vert + $scaleHZ * $horz]
            move sample_x to $x
            move sample_y to $y
            move sample_z to $z
            wait_for_devices sample_x sample_y sample_z

            if {[isOperation rasteringUpdate]} {
                set cellIndex [expr $col_index + $row_index * $num_column]
                rasteringUpdate_start update_cell $cellIndex exposing
            }

            ###prepare filename for collect image
            set fileroot \
            ${file_prefix}_[expr $row_index + 1]_[expr $col_index +1]

            set reuseDark 0 
            set operationHandle [start_waitable_operation collectFrame \
                                         0 \
                                             $fileroot \
                                             $directory \
                                             $user \
                                             gonio_phi \
                                             shutter \
                                             $delta \
                                             $exposeTime \
                                             $modeIndex \
                                             0 \
                                             $reuseDark \
                                             $sessionID]

            wait_for_operation $operationHandle
            set log_contents \
            [format "%-20s %8.3f %8.3f %8.3f %8.3f %8.3f %5.3f %5.3f %d" \
            $fileroot \
            $orig_phi $gonio_omega \
            $sample_x $sample_y $sample_z \
            [set $gMotorBeamWidth] [set $gMotorBeamHeight] $sil_row]
            CCrystalLog $log_contents
            
            #the data collection moves by delta. Move back.
            move gonio_phi to $orig_phi
            wait_for_devices gonio_phi
            CCrystalCalculateXYScale

            ### add and analyze image
            CCrystalAddAndAnalyzeImage $user $sessionID $sil_row \
            $directory $fileroot

            lappend image_file_list $fileroot
            save_center_crystal_data image_list $image_file_list

            if {[isOperation rasteringUpdate]} {
                set cellIndex [expr $col_index + $row_index * $num_column]
                rasteringUpdate_start update_cell $cellIndex done 
            }
            CCrystalCheckImage $user $sessionID
        };#for col_index
    };#for row_index
    ### need this to flush out last image
    start_operation detector_stop


    ####restore position
    move sample_x to $orig_x
    move sample_y to $orig_y
    move sample_z to $orig_z
    wait_for_devices sample_x sample_y sample_z

    ###DEBUG
    #CCrystalLogData

    set center_crystal_msg "$scan_phase wait for results"
    CCrystalWaitForAllImage $user $sessionID $directory
    if {![CCrystalFind2DCenter $user $sessionID $directory centerHorz centerVert]} {
        return 0
    }

    set scan_only [get_center_crystal_data scan_only]
    if {!$scan_only} {
        ######################## convert to sample x y z
        ### new column definition
        #set centerHorzMM [expr $centerHorz * $step_x]
        set centerHorzMM [expr -1 * $centerHorz * $step_x]

        set centerVertMM [expr $centerVert * $step_y]
        set center_x [expr $x0 + $scaleVX * $centerVertMM + $scaleHX * $centerHorzMM]
        set center_y [expr $y0 + $scaleVY * $centerVertMM + $scaleHY * $centerHorzMM]
        set center_z [expr $z0 + $scaleVZ * $centerVertMM + $scaleHZ * $centerHorzMM]

        ###### move center to beam center ###
        move sample_x to $center_x
        move sample_y to $center_y
        move sample_z to $center_z
        wait_for_devices sample_x sample_y sample_z

        CCrystalLog [format "center moved to %.3f %.3f %.3f" \
        $sample_x $sample_y $sample_z]
    }
    return 1
}

proc CCrystalFind2DCenter { user sessionID directory horzRef vertRef } {
    upvar $horzRef center_column
    upvar $vertRef center_row

    set num_row [get_center_crystal_data num_row]
    set num_column [get_center_crystal_data num_column]

    set sil_start_row [get_center_crystal_data sil_row_offset]
    set sil_num_row [expr $num_row * $num_column]
    set raw_weight_list [get_center_crystal_data raw_weight_list]

    CCrystalLog "raw weight list"
    CCrystalLogWeight $num_row $num_column $raw_weight_list "%8d"

    ####only cutoff for now
    CCrystalWeightFilter $num_row $num_column $raw_weight_list \
    weight_list max_weight

    save_center_crystal_data max_weight $max_weight
    CCrystalLog "cooked weight list max: $max_weight"
    CCrystalLogWeight $num_row $num_column $weight_list "%8.2f"

    ##################check to see if max weight is still too small#####
    set min_weight_to_proceed [get_center_crystal_constant min_num_spot]
    if {$max_weight < $min_weight_to_proceed} {
        CCrystalLog "find center failed: num of spot too small"
        return 0
    }

    foreach {center_row center_column \
    crystal_height_row crystal_width_column \
    start_row end_row start_col end_col} \
    [CCrystalFindStrongestCrystal $num_row $num_column weight_list] break

    save_center_crystal_data center_row $center_row
    save_center_crystal_data center_column $center_column

    save_center_crystal_data boundary_start_row $start_row
    save_center_crystal_data boundary_end_row $end_row
    save_center_crystal_data boundary_start_column $start_col
    save_center_crystal_data boundary_end_column $end_col

    save_center_crystal_data crystal_width_column $crystal_width_column
    save_center_crystal_data crystal_height_row $crystal_height_row

    #CCrystalLog "center column:  [format %10.3f $center_column]"
    #CCrystalLog "center row:     [format %10.3f $center_row]"
    #CCrystalLog "crystal width:  [format %10.3f $crystal_width_column] column"
    #CCrystalLog "crystal height: [format %10.3f $crystal_height_row] row"
    #CCrystalLog "boundary box row: $start_row $end_row column: $start_col $end_col"

    set do_collimator [get_center_crystal_constant collimator_scan]
    if {$do_collimator} {
        CCrystalCheckMicroCrystalSize
    }
    return 1
}

proc CCrystalSearchShouldFinish { loop_index } {
    set min_loop [get_center_crystal_constant min_loop]
    incr min_loop -1

    set scan_phase [get_center_crystal_data scan_phase]
    if {$loop_index >= $min_loop || $scan_phase == "EDGEEXTRA"} {
        CCrystalCheckHorizontalDone
        CCrystalCheckVerticalDone
    } else {
        CCrystalLog "min_loop not reached yet: skip check and continue zoom in"
    }

    set horizontal_done [get_center_crystal_data horizontal_done]
    set vertical_done   [get_center_crystal_data vertical_done]

    set scan_mode [get_center_crystal_data scan_mode]
    switch -exact -- $scan_mode {
        VERTICAL {
            if {$vertical_done} {
                set v_done_reason [get_center_crystal_data v_done_reason]
                log_note finish $v_done_reason
                CCrystalLog "finish $v_done_reason"
                return 1
            }
        }
        HORIZONTAL {
            if {$horizontal_done} {
                set h_done_reason [get_center_crystal_data h_done_reason]
                log_note finish $h_done_reason
                CCrystalLog "finish $h_done_reason"
                return 1
            }
        }
        2D -
        default {
            if {$horizontal_done && $vertical_done} {
                set h_done_reason [get_center_crystal_data h_done_reason]
                set v_done_reason [get_center_crystal_data v_done_reason]
                log_note finish $h_done_reason $v_done_reason
                CCrystalLog "finish $h_done_reason $v_done_reason"
                return 1
            }
            if {$horizontal_done} {
                save_center_crystal_data h_done_first 1
            }
            if {$vertical_done} {
                save_center_crystal_data v_done_first 1
            }
        }
    }


    ##################### setup next run #######################
    CCrystalLog "continue search, setup new parameters"
    switch -exact -- $scan_mode {
        VERTICAL {
            set step_y [get_center_crystal_data step_y]
            set crystal_height_row [get_center_crystal_data crystal_height_row]
            set height [expr $crystal_height_row * $step_y]
            CCrystalSetup1DScanParameter $height $scan_mode
        }
        HORIZONTAL {
            set step_x [get_center_crystal_data step_x]
            set crystal_width_column [get_center_crystal_data \
            crystal_width_column]

            set width [expr $crystal_width_column * $step_x]
            CCrystalSetup1DScanParameter $width $scan_mode
        }
        2D {
            set step_x [get_center_crystal_data step_x]
            set step_y [get_center_crystal_data step_y]
            set crystal_width_column [get_center_crystal_data \
            crystal_width_column]
            set crystal_height_row [get_center_crystal_data crystal_height_row]

            set width [expr $crystal_width_column * $step_x]
            set height [expr $crystal_height_row * $step_y]
            CCrystalSetup2DScanParameter $width $height
        }
    }

    CCrystalAdjustExposureTimeByBeamSize
    return 0
}
################################################################
######################## web stuff #############################
################################################################
proc CCrystalClearResults { } {
    variable CCrystalSessionID

    set user [get_center_crystal_data user]
    set sessionID $CCrystalSessionID
    set silid [get_center_crystal_data sil_id]
    resetSpreadsheet $user $sessionID $sil_id
}
proc CCrystalDeleteDefaultSil { } {
    variable CCrystalSessionID

    set user [get_center_crystal_data user]
    set sessionID $CCrystalSessionID
    ###try to delete the previous SIL, may belong to another user
    set sil_id [get_center_crystal_data sil_id]
    if {[string is integer -strict $sil_id] && $sil_id > 0} {
        if {[catch {
            deleteSil $user $sessionID $sil_id
            save_center_crystal_data sil_id 0
        } errMsg]} {
            puts "failed to delete SIL $sil_id: $errMsg"
        }
    }
}
proc CCrystalCreateDefaultSil { } {
    variable CCrystalSessionID
    variable CCrystalUniqueIDList

    ####create new sil and save the id to the string
    set user [get_center_crystal_data user]
    set sessionID $CCrystalSessionID
    set sil_id [createDefaultSil $user $sessionID]
    puts "new sil_id: $sil_id"

    if {![string is integer -strict $sil_id] || $sil_id < 0} {
        return -code error "create default sil failed: sil_id: $sil_id not > 0"
    }

    ### get uniqueID for each row
    if {[catch {
        set CCrystalUniqueIDList [getSpreadsheetProperty \
        $user $sessionID $sil_id UniqueID]
    } errMsg]} {
        set CCrystalUniqueIDList [list]
        log_error failed to get uniqueIDList: $errMsg
    }

    set event_id 0

    save_center_crystal_data sil_id $sil_id
    save_center_crystal_data event_id 0

    ##can find it by parsing header
    save_center_crystal_data column_images 23

    CCrystalLog "new silid=$sil_id images assume at column 23"
}
proc CCrystalAddAndAnalyzeImage { user sessionID row directory fileroot } {
    variable beamlineID
    variable CCrystalUniqueIDList

    set fullPath [file join $directory \
    ${fileroot}.[get_center_crystal_data image_ext]]

    set silid [get_center_crystal_data sil_id]

    set uniqueID [lindex $CCrystalUniqueIDList $row]

    addCrystalImage $user $sessionID $silid $row 1 $fullPath NULL $uniqueID

    analyzeCenterImage \
    $user $sessionID $silid $row $uniqueID 1 $fullPath ${beamlineID} $directory
}

proc CCrystalColumnImagesGroup1 { row_contents_ } {
    set pattern1 {<Images>(.*)</Images>}
    set pattern2 {<Group name="1">(.*)</Group>}
    set pattern3 {<Image (.*) />}
    
    set images ""
    set group1 ""
    set imageInfo ""

    regexp $pattern1 $row_contents_ dummy images
    regexp $pattern2 $images dummy group1
    regexp $pattern3 $group1 dummy imageInfo

    #DEBUG
    puts "images=$images"
    puts "group1=$group1"
    puts "imageInfo=$imageInfo"

    return $imageInfo
}

proc CCrystalCheckImage { user sessionID } {
    set sil_id [get_center_crystal_data sil_id]
    set numList [getNumSpotsData $user $sessionID $sil_id]
    puts "numList: $numList"

    set image_list [get_center_crystal_data image_list]
    set start [get_center_crystal_data sil_row_offset]
    set ll [llength $image_list]
    set end [expr $start + $ll - 1]

    puts "start=$start ll=$ll end=$end"

    set result ""
    foreach num [lrange $numList $start $end] {
        if {$num == "" || $num < 0} {
            break
        }
        lappend result $num
    }

    puts "textList=$result"
    if {[isOperation rasteringUpdate]} {
        eval rasteringUpdate_start update_text $result
    }
    save_center_crystal_data raw_weight_list $result
    return $result
}

proc CCrystalWaitForAllImage { user sessionID directory } {
    CCrystalLog "wait for all image"
    set image_list [get_center_crystal_data image_list]
    set ll [llength $image_list]

    
    set llResult [llength [CCrystalCheckImage $user $sessionID]]
    if {$llResult > 0} {
        log_warning got $llResult of $ll
    }

    set previous_ll $llResult
    while {$llResult < $ll} {
        if {[get_operation_stop_flag]} {
            log_error stopped by user
            return
        }
        wait_for_time 1000
        if {[catch {
            set llResult [llength [CCrystalCheckImage $user $sessionID]]
        } err]} {
            log_warning failed to wait for all data: $err
            break
        }
        if {$llResult > $previous_ll} {
            log_warning got $llResult of $ll
            set previous_ll $llResult
        }
    }
    CCrystalLog "got all image"
}
proc CCrystalNodeToSILRow { num_row num_column row_index col_index} {
    ##### retrieve current offset
    set sil_row_offset [get_center_crystal_data sil_row_offset]
    if {![string is integer -strict $sil_row_offset] || $sil_row_offset < 0} {
        set sil_row_offset 0
        save_center_crystal_data sil_row_offset 0
    }

    ######## check if we need to start over ######
    set last [expr $sil_row_offset + $num_row * $num_column]
    ###### 96 is hardcoded here.
    if {$last >= 96} {
        set sil_row_offset 0
        save_center_crystal_data sil_row_offset 0
    }
    return [expr $num_column * $row_index + $col_index + $sil_row_offset]
}
proc CCrystalAdjustSilRowOffset { } {
    set current_offset [get_center_crystal_data sil_row_offset]
    set num_row [get_center_crystal_data num_row]
    set num_col [get_center_crystal_data num_column]

    set next_offset [expr $current_offset + $num_row * $num_col]

    if {$next_offset >= 96} {
        set next_offset 0
        log_warning run out of spreadsheet row, reuse
        CCrystalClearResults
    }

    save_center_crystal_data sil_row_offset $next_offset
}
################################################################
######################## utilities #############################
################################################################
proc get_center_crystal_constant { name } {
    variable ccrystal_constant_snapshot

    set index [CCrystalConstantNameToIndex $name]
    return [lindex $ccrystal_constant_snapshot $index]
}
proc get_center_crystal_data { name } {
    #variable center_crystal_data
    variable ::centerCrystal::center_crystal_data

    set index [CCrystalDataNameToIndex $name]
    return [lindex $center_crystal_data $index]
}

proc save_center_crystal_data { name value } {
    #variable center_crystal_data
    variable ::centerCrystal::center_crystal_data

    set index [CCrystalDataNameToIndex $name]
    set center_crystal_data [lreplace $center_crystal_data $index $index $value]
}

proc CCrystalDataNameToIndex { name } {
    variable center_crystal_data_name_list
    #variable center_crystal_data
    variable ::centerCrystal::center_crystal_data

    if {![info exists center_crystal_data]} {
        return -code error "string not exists: center_crystal_data"
    }

    set index [lsearch -exact $center_crystal_data_name_list $name]
    if {$index < 0} {
        puts "DataNameToIndex failed name=$name list=$center_crystal_data_name_list"
        return -code error "data bad name: $name"
    }

    if {[llength $center_crystal_data] <= $index} {
        return -code error "bad contents of string center_crystal_data"
    }
    return $index
}
proc CCrystalConstantNameToIndex { name } {
    variable ccrystal_constant_snapshot
    variable center_crystal_constant_name_list

    if {![info exists ccrystal_constant_snapshot]} {
        return -code error "string not exists: ccrystal_constant_snapshot"
    }

    set index [lsearch -exact $center_crystal_constant_name_list $name]
    if {$index < 0} {
        return -code error "bad name: $name"
    }

    if {[llength $ccrystal_constant_snapshot] <= $index} {
        return -code error "bad contents of string center_crystal_constant"
    }
    return $index
}
proc CCrystalLog { contents {update_operation 1}} {
    variable CCrystalSessionID

    set user      [get_center_crystal_data user]
    set sessionID $CCrystalSessionID
    set logPath [get_center_crystal_data log_file_name]

    set ts [clock format [clock seconds] -format "%d %b %Y %X"]

    impAppendTextFile $user $sessionID $logPath "$ts $contents\n"

    if {$update_operation} {
        send_operation_update $contents
    }
}
proc CCrystalLogConstant { } {
    variable ccrystal_constant_snapshot
    variable center_crystal_constant_name_list

    set ll [llength $center_crystal_constant_name_list]

    set log_contents "CENTER CRYSTAL PARAMETERS\n"
    for {set i 0} {$i < $ll} {incr i} {
        append log_contents [lindex $center_crystal_constant_name_list $i]
        append log_contents =
        append log_contents [lindex $ccrystal_constant_snapshot $i]
        append log_contents "\n"
    }
    ##### only write to log file, not send operation update
    CCrystalLog $log_contents 0
}
proc CCrystalLogData { } {
    variable center_crystal_data_name_list
    #variable center_crystal_data
    variable ::centerCrystal::center_crystal_data
    variable CCrystalSessionID

    set user      [get_center_crystal_data user]
    set sessionID $CCrystalSessionID

    set ll [llength $center_crystal_data_name_list]
    set log_contents "CENTER CRYSTAL DATA\n"
    for {set i 0} {$i < $ll} {incr i} {
        append log_contents [lindex $center_crystal_data_name_list $i]
        append log_contents =
        append log_contents [lindex $center_crystal_data $i]
        append log_contents "\n"
    }
    ##### only write to log file, not send operation update
    CCrystalLog $log_contents 0
}
proc CCrystalLogWeight { num_row num_column weightList fmt } {
    if {$num_row > 1 && $num_column > 1} {
        set output_sum 1
    } else {
        set output_sum 0
    }
        
    array set col_weight [list]
    for {set col 0} {$col < $num_column} {incr col} {
        set col_weight($col) 0
    }
    for {set row 0} {$row < $num_row} {incr row} {
        set row_weight 0

        set start [expr $row * $num_column]
        set end [expr $start + $num_column - 1]
        set oneRow [lrange $weightList $start $end]
        set line ""
        set col 0
        foreach weight $oneRow {
            set row_weight [expr $weight + $row_weight]
            set col_weight($col) [expr $weight +$col_weight($col)]
            append line [format $fmt $weight]
            incr col
        }
        if {$output_sum} {
            ### add total for row
            append line "     Row SUM: "
            append line [format $fmt $row_weight]

        }
        CCrystalLog $line
    }
    if {$output_sum} {
       CCrystalLog "Column SUM:"
        set line ""
        for {set col 0} {$col < $num_column} {incr col} {
            append line [format $fmt $col_weight($col)]
        }
        CCrystalLog $line
    }
}
####return face width, face height, and edge height
#### edge width is the same as face width
proc CCrystalGetLoopSize { faceWRef faceHRef edgeHRef {no_log 0}} {
    variable save_loop_size
    variable center_crystal_msg

    upvar $faceWRef faceWmm
    upvar $faceHRef faceHmm
    upvar $edgeHRef edgeHmm

    CCrystalCheckLoopCenter
    foreach {status loopWidth faceHeight edgeHeight} $save_loop_size break
    #set faceWmm [expr $loopWidth * 0.8]
    #set faceHmm $faceHeight
    #set edgeHmm $edgeHeight
    ######### to be safe, increase loop size 20%
    set loop_width_extra [get_center_crystal_constant loop_width_extra]
    if {![string is double -strict $loop_width_extra] ||
    $loop_width_extra <= -100} {
        set loop_width_extra 0.0
    }
    set widthScale [expr 1.0 + $loop_width_extra * 0.01]
    set loop_height_extra [get_center_crystal_constant loop_height_extra]
    if {![string is double -strict $loop_height_extra] ||
    $loop_height_extra <= -100} {
        set loop_height_extra 0.0
    }
    set heightScale [expr 1.0 + $loop_height_extra * 0.01]

    set faceWmm [expr $widthScale * $loopWidth]
    set faceHmm [expr $heightScale * $faceHeight]
    set edgeHmm [expr $heightScale * $edgeHeight]
    
    if {!$no_log} {
        if {$widthScale != 1.0 || $heightScale != 1.0} {
            CCrystalLog [format "loop size adjusted to: %5.3f %5.3f %5.3f" \
            $faceWmm $faceHmm $edgeHmm]
        } else {
            CCrystalLog [format "loop size: %5.3f %5.3f %5.3f" \
            $faceWmm $faceHmm $edgeHmm]
        }
    }

    ###### move to the real loop center ######
    set dz [expr $loopWidth * 0.1]
    move sample_z by $dz
    wait_for_devices sample_z
    
    if {$faceWmm < 0.001 || $faceHmm < 0.001 || $edgeHmm < 0.001} {
        set center_crystal_msg "error: center loop failed to return size"
        return -code error "loop center failed to return loop size"
    }
}
proc CCrystalCheckLoopCenter { } {
    variable save_loop_size
    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable center_crystal_msg

    #######################################################
    # anything wrong from the loopcentering, we will call
    # loop centeringg here again
    #######################################################
    set loopCenterOK 1
    if {[llength $save_loop_size] < 8} {
        #send_operation_update "loopCenter result length not right, force loopcentering"
        set loopCenterOK 0
    }
    foreach {status loopWidth faceHeight edgeHeight s_x s_y s_z g_phi } \
    $save_loop_size break
    if {$status != "normal"} {
        #send_operation_update "loopCenter result failed: $save_loop_size, force loopcentering"
        set loopCenterOK 0
    }
    if {abs($sample_x - $s_x) > 0.01 || \
    abs($sample_y - $s_y) > 0.01 || \
    abs($sample_z - $s_z) > 0.01 || \
    abs($gonio_phi - $g_phi) > 0.01} {
        #send_operation_update "sample moved after loopcentering, force loopcentering"
        #send_operation_update "old:     $s_x $s_y $s_z $g_phi"
        #send_operation_update "current: $sample_x $sample_y $sample_z $gonio_phi"
        set loopCenterOK 0
    }

    if {!$loopCenterOK} {
        set center_crystal_msg "center loop"
        set handle [start_waitable_operation centerLoop]
        wait_for_operation_to_finish $handle
        
        ###### check results: #####
        if {[llength $save_loop_size] < 8} {
            set center_crystal_msg "error: $save_loop_size"
            return -code error \
            "failed in get loop size: $save_loop_size"
        }
        #### we do not check position here, we called loop centering ourselves.
        set status [lindex $save_loop_size 0]
        if {$status != "normal"} {
            set center_crystal_msg "error: $save_loop_size"
            return -code error \
            "failed in get loop size: $save_loop_size"
        }
    }
}
proc CCrystalWeightFilter {num_row num_column raw_weight_list weightListRef maxRef} {
    upvar $weightListRef result
    upvar $maxRef max_weight

    ##### filter: cut off number then cut off percent
    set background_sub  [get_center_crystal_constant background_sub]
    set result [list]
    foreach weight $raw_weight_list {
        if {[string is double -strict $weight] && $weight >= $background_sub} {
            lappend result [expr $weight - $background_sub]
        } else {
            lappend result 0
        }
    }
    ##### find max #####
    set max_weight 0.0;### weight are not negative
    foreach weight $result {
        if {[string is double -strict $weight] && $weight > $max_weight} {
            set max_weight $weight
        }
    }
}

proc CCrystalGetDetectorMode { exposureTime } {
    variable detectorType

    set type [lindex $detectorType 0]

    if {$exposureTime < 5.0} {
        switch -exact -- $type {
            MAR325 -
            MAR165 {
                return 0
            }
            MAR345 {
                return 0
            }
            Q315CCD {
                return 2
            }
            Q4CCD {
                return 3
            }
            default {
                return 0
            }
        }
    } else {
        switch -exact -- $type {
            MAR325 -
            MAR165 {
                return 1
            }
            MAR345 {
                return 0
            }
            Q315CCD {
                return 6
            }
            Q4CCD {
                return 7
            }
            default {
                return 0
            }
        }
    }
}

########################## HELP function ############
proc CCrystalBeamSizeLimit { widthREF heightREF } {
    upvar $widthREF x
    upvar $heightREF y
    global gMotorBeamWidth
    global gMotorBeamHeight

    if {[catch {
        global gDevice
        set xu $gDevice($gMotorBeamWidth,scaledUpperLimit)
        set xl $gDevice($gMotorBeamWidth,scaledLowerLimit)
        set yu $gDevice($gMotorBeamHeight,scaledUpperLimit)
        set yl $gDevice($gMotorBeamHeight,scaledLowerLimit)

        if {$xu > $xl} {
            if {$x < $xl} {
                CCrystalLog "adjust final beam width to lower limit $xl"
                set x $xl
            } elseif {$x > $xu} {
                CCrystalLog "adjust final beam width to upper limit $xu"
                set x $xu
            }
        }
        if {$yu > $yl} {
            if {$y < $yl} {
                CCrystalLog "adjust final beam height to lower limit $yl"
                set y $yl
            } elseif {$y > $yu} {
                CCrystalLog "adjust final beam height to upper limit $yu"
                set y $yu
            }
        }
    } errMsg]} {
        log_error check beamsize failed: $errMsg
    }
}
proc CCrystalLimitStepSizeX { stepSizeRef } {
    upvar $stepSizeRef step_x

    set max_step [get_center_crystal_constant max_step_x]
    set min_step [get_center_crystal_constant min_step_x]

    if {$step_x < $min_step} {
        set step_x $min_step
    }
    if {$step_x > $max_step} {
        set step_x $max_step
    }
}
proc CCrystalLimitStepSizeY { stepSizeRef } {
    upvar $stepSizeRef step_y

    set max_step [get_center_crystal_constant max_step_y]
    set min_step [get_center_crystal_constant min_step_y]

    if {$step_y > $max_step} {
        set step_y $max_step
    }
    if {$step_y < $min_step} {
        set step_y $min_step
    }
}
proc CCrystalSetHorizontalDone { reason } {
    save_center_crystal_data horizontal_done 1
    save_center_crystal_data h_done_reason $reason

    ####### set num step to 1 and beam size to crystal width
    set width_in_col [get_center_crystal_data crystal_width_column]
    set step_x [get_center_crystal_data step_x]
    set width [expr $width_in_col * $step_x]
    save_center_crystal_data crystal_width_mm $width
    CCrystalLimitStepSizeX width
    save_center_crystal_data step_x $width
    save_center_crystal_data num_column 1
}

proc CCrystalSetVerticalDone { reason } {
    save_center_crystal_data vertical_done 1
    save_center_crystal_data v_done_reason $reason

    ####### set num step to 1 and beam size to crystal height
    set height_in_row [get_center_crystal_data crystal_height_row]
    set step_y [get_center_crystal_data step_y]
    set height [expr $height_in_row * $step_y]
    save_center_crystal_data crystal_height_mm $height
    CCrystalLimitStepSizeY height
    save_center_crystal_data step_y $height
    save_center_crystal_data num_row 1
}

proc CCrystalCheckHorizontalDone { } {
    if {[get_center_crystal_data horizontal_done]} {
        return 1
    }

    ########## case of no diffraction at all ################
    set crystal_width_column [get_center_crystal_data crystal_width_column]
    if {$crystal_width_column <= 0} {
        ################ should not be here
        log_error "no diffraction"
        CCrystalSetHorizontalDone "no diffration"
        CCrystalSetVerticalDone "no diffration"
        return 1
    }
    #########check minimum step size###############
    set step_x     [get_center_crystal_data step_x]
    set min_step_x [get_center_crystal_constant min_step_x]
    if {$step_x <= $min_step_x} {
        CCrystalSetHorizontalDone "reached min step size"
        return 1
    }
    ##########check crystal size################
    set num_col [get_center_crystal_data num_column]
    if {$num_col > 2} {
        set required_width [expr $num_col * \
        [get_center_crystal_constant finish_horizontal] * 0.01]
    } else {
        set required_width 1
    }
    if {$crystal_width_column >= $required_width} {
        CCrystalSetHorizontalDone "enough data"
        return 1
    }
    return 0
}
proc CCrystalCheckVerticalDone { } {
    if {[get_center_crystal_data vertical_done]} {
        return 1
    }

    ########## case of no diffraction at all ################
    set crystal_height_row [get_center_crystal_data crystal_height_row]
    if {$crystal_height_row <= 0} {
        ################ should not be here
        log_note "no diffraction"
        CCrystalSetHorizontalDone "no diffration"
        CCrystalSetVerticalDone "no diffration"
        return 1
    }
    #########check minimum step size###############
    set step_y     [get_center_crystal_data step_y]
    set min_step_y [get_center_crystal_constant min_step_y]
    if {$step_y <= $min_step_y} {
        CCrystalSetVerticalDone "reached min step size"
        return 1
    }
    ##########check crystal size################
    set num_row [get_center_crystal_data num_row]
    if {$num_row > 2} {
        set required_height [expr $num_row * [get_center_crystal_constant finish_vertical] * 0.01]
    } else {
        set required_height 1
    }
    if {$crystal_height_row >= $required_height} {
        CCrystalSetVerticalDone "enough data"
        return 1
    }

    return 0
}
proc CCrystalAdjustExposureTimeByBeamSize { {width_only 0} } {
    set old_beam_x [get_center_crystal_data old_beam_x]
    set old_beam_y [get_center_crystal_data old_beam_y]
    set old_area [expr $old_beam_x * $old_beam_y]

    ##### get new area size
    set step_x [get_center_crystal_data step_x]
    set step_y [get_center_crystal_data step_y]
    set new_area [expr $step_x * $step_y]

    set old_expose_time [get_center_crystal_data exposure_time]

    
    #CCrystalLog "time adjust by beamsize"
    #CCrystalLog "old size: $old_beam_x $old_beam_y"
    #CCrystalLog "old time: $old_expose_time"
    #CCrystalLog "new size: $step_x $step_y"


    if {$new_area <= 0} {
        set factor [get_center_crystal_constant increment_expose_time]
    } else {
        if {$width_only} {
            set factor [expr double($old_beam_x) / $step_x]
        } else {
            set factor [expr double($old_area) / $new_area]
        }
    }

    set new_exposure_time [expr $old_expose_time * $factor]

    set new_time [CCrystalAdjustExposureTimeByNumSpot $new_exposure_time]
    #CCrystalLog "exposure time adjusted to $new_time"
}
proc CCrystalAdjustExposureTimeByNumSpot { old_time } {
    set current_max_num_spot [get_center_crystal_data max_weight]
    set min_num_spot [get_center_crystal_constant min_num_spot]
    set target_num_spot [get_center_crystal_constant target_num_spot]

    ### Mike wants to use raw peak
    set background_sub  [get_center_crystal_constant background_sub]
    set current_max_num_spot [expr $current_max_num_spot + $background_sub]

    #CCrystalLog "adjusting time by numspots: curren: $current_max_num_spot"
    #CCrystalLog "adjusting time by numspots: target: $target_num_spot"
    #CCrystalLog "adjusting time by numspots: min   : $min_num_spot"
    #CCrystalLog "adjusting time by numspots: old time: $old_time"
    

    if {$min_num_spot > $target_num_spot} {
        set tmpHold $min_num_spot
        set min_num_spot $target_num_spot
        set target_num_spot $tmpHold
    }

    if {$current_max_num_spot > 0} {
        set factor [expr double($target_num_spot) / double($current_max_num_spot)]
    } else {
        set factor [get_center_crystal_constant increment_expose_time]
    }
    set exposure_time [expr $old_time * $factor]
    puts "centerCrystal: exposure time to $exposure_time by num spots"
    set new_time [CCrystalSetExposureTime $exposure_time]
    return $new_time
}

##### this will  check range, and set mode and file extension
proc CCrystalSetExposureTime { time } {
    set max_time [get_center_crystal_constant max_expose_time]
    set min_time [get_center_crystal_constant min_expose_time]

    if {$max_time < $min_time} {
        ###swap them
        set temp $max_time
        set max_time $min_time
        set min_time $temp
    }

    if {$time < $min_time} {
        set time $min_time
        puts "centerCrystal: exposure time to $time (min)"
    }
    if {$time > $max_time} {
        set time $max_time
        puts "centerCrystal: exposure time to $time (max)"
    }
    set modeIndex [CCrystalGetDetectorMode $time]
    set new_ext [getDetectorFileExt $modeIndex]

    save_center_crystal_data exposure_time $time
    save_center_crystal_data det_mode $modeIndex
    save_center_crystal_data image_ext $new_ext

    return $time
}

proc CCrystalSlitY { phi dx1 dy1 dx2 dy2 } {
    variable gonio_omega

    #set phi_offset 90;#diff from video
    set phi_offset [get_center_crystal_data phi_offset]
    set phi_offset [expr $phi_offset + 90.0]

    set angleInDegree [expr $phi + $gonio_omega + $phi_offset]
    set angle [expr -3.14159 * $angleInDegree / 180.0]

    set dx [expr $dx1 - $dx2]
    set dy [expr $dy1 - $dy2]

    set slit_y [expr \
    sin($angle) * $dx * 0.5 + \
    cos($angle) * $dy * 0.5]

    set ll [expr 0.5 * sqrt($dx * $dx + $dy * $dy)]

    set dl [expr $ll - abs($slit_y)]
    if {abs($dl) > 0.001} {
        CCrystalLog "not really moved vertically: ll: $ll slit_y: $slit_y"
    }

    return $slit_y
}
proc CCrystalMakeSureDataHasEnoughSpace { } {
    #variable center_crystal_data
    variable ::centerCrystal::center_crystal_data
    variable center_crystal_data_name_list
    variable center_crystal_constant_name_list
    variable CCrystalConstantNameList
    variable CCrystalDataNameList

    #### refresh name list if not match
    if {$center_crystal_constant_name_list != $CCrystalConstantNameList} {
        set center_crystal_constant_name_list $CCrystalConstantNameList
        CCrystalLog "warning constant name list refreshed"
    }
    if {$center_crystal_data_name_list != $CCrystalDataNameList} {
        set center_crystal_data_name_list $CCrystalDataNameList
        CCrystalLog "warning data name list refreshed"
    }

    set llname [llength $center_crystal_data_name_list]
    set lldata [llength $center_crystal_data]

    if {$llname > $lldata} {
        set ll [expr $llname - $lldata]
        for {set i 0} {$i < $ll} {incr i} {
            lappend center_crystal_data ""
        }
    }
}

proc CCrystalGetStandardDoseText { } {
    variable collect_default

    set defT [lindex $collect_default 1]
    set defA [lindex $collect_default 2]

    return "standard dose: time $defT at attenuation=${defA}%"
}
proc CCrystalGetExposureFromFactor { f } {
    variable collect_default

    foreach {defD defT defA minT maxT minA maxA} $collect_default break

    #### here should be $minT
    set tPrefer $defT

    #### exposure time at attenuation = 0
    set time0 [expr $defT * (1.0 - $defA / 100.0) * $f]

    ### try prefered time first
    ### a can be negative
    set a [expr 100.0 * (1.0 - $time0 / $tPrefer)]
    if {$a < $minA} {
        ### use minA and increase time
        set a $minA
        set t [expr $time0 / (1.0 - $a / 100.0)]
        if {$t > $maxT} {
            log_warning exposure time limited to $maxT from $t
            CCrystalLog "exposure time limited to $maxT from $t"
            set t $maxT
        }
        ## assumed tPrefer >= minT
    } elseif {$a > $maxA} {
        ###scale down time from tPrefer
        set a $maxA
        set t [expr $time0 / (1.0 - $a / 100.0)]
        if {$t < $minT} {
            log_warning exposure time limited to $minT from $t
            CCrystalLog "exposure time limited to $minT from $t"
            set t $minI
        }
    } else {
        ##$a >= $minA && $a <= $maxA
        set t $tPrefer
    }
    return [list $a $t]
}
proc CCrystalGetRelativeTimeText { s } {
    set m [expr $s / 60]
    set h [expr $m / 60]
    set d [expr $h / 24]

    set S [expr $s % 60]
    set M [expr $m % 60]
    set H [expr $h % 24]

    set result ""
    if {$d > 0} {
        return [format "%d %02d:%02d:%02d" $d $H $M $S]
    }
    if {$h > 0} {
        return [format "%02d:%02d:%02d" $h $M $S]
    }
    return [format "%02d:%02d" $m $S]
}

proc CCrystalCollimatorScan {user sessionID directory file_prefix manual_scan} {
    ##### collimator size
    foreach {bw bh} [collimatorMoveFirstMicron] break

    #### crystal size
    foreach {delta_phi cw ceh cfh} \
    [CCrystalGetCollimatorScanSize $manual_scan] break

    ######### adjust exposure time
    set scale_factor [get_center_crystal_constant collimator_scale_factor]
    if {$scale_factor < 1} {
        log_warning collimator scale factor should not be < 1
        set scale_factor 1
    }
    set current_time [get_center_crystal_data exposure_time]
    set new_time [expr $current_time * $scale_factor]
    CCrystalLog \
    "collimator scaled expose factor from $current_time to $new_time"
    ####BYPASS limits check
    save_center_crystal_data exposure_time $new_time

    ############
    #### crystal edge
    #move gonio_phi by $delta_phi
    #wait_for_devices gonio_phi
    #CCrystalCalculateXYScale

    
    set edgeOK [CCrystalCollimatorEdgeScan $bw $bh $cw $ceh \
    $user $sessionID $directory ${file_prefix}_edge]
    if {!$edgeOK} {
        #move gonio_phi by [expr -1 * $delta_phi]
        #wait_for_devices gonio_phi
        #CCrystalCalculateXYScale
        log_error collimator scan crystal edge failed.
        return 0
    }

    move gonio_phi by 90
    wait_for_devices gonio_phi
    CCrystalCalculateXYScale

    ####after edge collimator scan, we have better crystal width now
    set cw [get_center_crystal_data crystal_width_mm]

    set faceOK [CCrystalCollimatorFaceScan $bw $bh $cw $cfh \
    $user $sessionID $directory ${file_prefix}_face]

    ### leave the face to the beam
    #move gonio_phi by [expr -90]
    #wait_for_devices gonio_phi
    #CCrystalCalculateXYScale
    if {!$faceOK} {
        log_error collimator scan crystal face failed.
        return 0
    }
    log_note collimator crystal center successed
    return 1
}   
proc CCrystalCollimatorEdgeScan { bw bh cw ceh \
user sessionID directory file_prefix } {
    save_center_crystal_data h_done_first 0
    save_center_crystal_data v_done_first 0
    save_center_crystal_data horizontal_done 0
    save_center_crystal_data vertical_done 0
    save_center_crystal_data scan_phase EDGE_COLLIMATOR
    CCrystalSetup1DScanParameter $cw  HORIZONTAL 1 $bw
    CCrystalSetup1DScanParameter $ceh VERTICAL   1 $bh
    save_center_crystal_data scan_mode 2D

    ### disable i2 scaling
    save_center_crystal_data old_i2 0
    while {![CCrystal2DScan $user $sessionID $directory $file_prefix 1]} {
        CCrystalAdjustSilRowOffset
        if {![CCrystalIncreaseExposeTime]} {
            log_error "auto-crystal alignment failed - no diffraction"
            set center_crystal_msg "error: no diffraction"
            return 0
        }
        ### disable i2 scaling
        save_center_crystal_data old_i2 0
    }
        
    #called before checking of finish.
    #it need current number of row and column
    CCrystalAdjustSilRowOffset

    CCrystalSetVerticalDone   "collimator scan once"
    CCrystalSetHorizontalDone "collimator scan once"

    set width      [get_center_crystal_data crystal_width_mm]
    set height     [get_center_crystal_data crystal_height_mm]
    save_center_crystal_data crystal_edge_height_mm $height


    set scan_phase [get_center_crystal_data scan_phase]
    set contents [format "Crystal %s Size: %5.3fX%5.3f" \
    $scan_phase $width $height]
    CCrystalLog $contents
    set center_crystal_msg $contents

    return 1
}
proc CCrystalCollimatorFaceScan { bw bh cw cfh \
user sessionID directory file_prefix } {

    save_center_crystal_data h_done_first 0
    save_center_crystal_data v_done_first 0
    save_center_crystal_data horizontal_done 0
    save_center_crystal_data vertical_done 0
    save_center_crystal_data scan_phase FACE_COLLIMATOR
    CCrystalSetup1DScanParameter $cfh VERTICAL 1
    CCrystalSetupCollimatorFaceHorzScanParameter $cw $bw
    save_center_crystal_data scan_mode 2D

    set old_exposure_time [get_center_crystal_data old_exposure_time]
    set newTime [CCrystalAdjustExposureTimeByNumSpot $old_exposure_time]
    ### disable i2 scaling
    save_center_crystal_data old_i2 0
    while {![CCrystal2DScan $user $sessionID $directory $file_prefix 1]} {
        CCrystalAdjustSilRowOffset
        if {![CCrystalIncreaseExposeTime]} {
            log_error "auto-crystal alignment failed - no diffraction"
            set center_crystal_msg "error: no diffraction"
            return 0
        }
        ### disable i2 scaling
        save_center_crystal_data old_i2 0
    }
        
    #called before checking of finish.
    #it need current number of row and column
    CCrystalAdjustSilRowOffset
    CCrystalSetVerticalDone   "collimator scan once"

    set width      [get_center_crystal_data crystal_width_mm]
    set height     [get_center_crystal_data crystal_height_mm]
    set scan_phase [get_center_crystal_data scan_phase]
    set contents [format "Crystal %s Size: %5.3fX%5.3f" \
    $scan_phase $width $height]
    CCrystalLog $contents
    set center_crystal_msg $contents

    return 1
}
proc CCrystalGetCollimatorScanSize { manual_scan } {
    set crystal_edge_height [get_center_crystal_data crystal_edge_height_mm]
    set crystal_face_height [get_center_crystal_data crystal_height_mm]
    set crystal_width       [get_center_crystal_data crystal_width_mm]


    if {$manual_scan} {
        set xfactor 1.0
        set yfactor 1.0
    } else {
        set beam_width_extra [get_center_crystal_constant beam_width_extra]
        set beam_height_extra [get_center_crystal_constant beam_height_extra]
        set xfactor [expr 1.0 + $beam_width_extra * 0.01]
        set yfactor [expr 1.0 + $beam_height_extra * 0.01]
    }

    set width   [expr $crystal_width * $xfactor]
    set eHeight [expr $crystal_edge_height * $yfactor]
    set fHeight [expr $crystal_face_height * $yfactor]

    ## here face is loop face
    #if {$eHeight > $fHeight} {
    #    return [list 90 $width $fHeight $eHeight]
    #} else {
    #    return [list 0  $width $eHeight $fHeight]
    #}
    return [list 0  $width $eHeight $fHeight]
}
proc CCrystalSetupCollimatorFaceHorzScanParameter { distance step_size } {
    puts "centerCrystal setup collimator face horz: $distance $step_size"

    set horizontal_done [get_center_crystal_data horizontal_done]
    if {$horizontal_done} {
        log_warning horizontal already done no change
        return
    }

    set num_step 1
    if {$step_size > 0} {
        set num_step [expr int(ceil($distance / double($step_size)))]
    }
    set max_num [get_center_crystal_constant collimator_max_column]
    if {$num_step > $max_num} {
        set num_step $max_num
        set step_size [expr $distance / double($num_step)]
    }

    save_center_crystal_data step_x $step_size
    save_center_crystal_data num_column $num_step
    save_center_crystal_data scan_mode HORIZONTAL
}

##############################################################################
# Once multiple crystals are detected, we will only pick the strongest.
# We have to redo all the calculations.  The column_weight and row_weight
# cannot be reused.
# Jinhu cannot find a neat and efficient way to do it.
# So, he selected easy to read way, not the most efficient way.
##############################################################################

proc CCrystalMatrixCalculation { num_row num_column weight_list \
start_row end_row start_col end_col \
resultRef rowWeightRef columnWeightRef } {
    upvar $resultRef result
    upvar $rowWeightRef row_weight
    upvar $columnWeightRef column_weight

    array unset resultArray

    puts "row $start_row $end_row col: $start_col $end_col"

    set sum 0.0
    set center_row 0.0
    set center_column 0.0
    for {set row 0} {$row < $num_row} {incr row} {
        set row_weight($row) 0
    }
    for {set col 0} {$col < $num_column} {incr col} {
        set column_weight($col) 0
    }

    set max_weight 0
    set row_of_peak $start_row
    set column_of_peak $start_col
    for {set row $start_row} {$row <= $end_row} {incr row} {
        for {set col $start_col} {$col <= $end_col} {incr col} {
            set offset [expr $row * $num_column + $col]
            set weight [lindex $weight_list $offset]

            set center_row [expr $center_row + $row * $weight]
            set center_column [expr $center_column + $col * $weight]
            set sum [expr $sum + $weight]

            set row_weight($row) [expr $row_weight($row) + $weight]
            set column_weight($col) [expr $column_weight($col) + $weight]

            if {$weight > $max_weight} {
                set max_weight $weight
                set row_of_peak $row
                set column_of_peak $col
            }
        }
    }
    if {$sum > 0} {
        set center_row [expr $center_row / $sum]
        set center_column [expr $center_column / $sum]
    } else {
        ####should not be here
        set center_row [expr $num_row / 2.0]
        set center_column [expr $num_column / 2.0]
        log_error "all image quality is 0"
    }

    ### save result
    set result(total) $sum
    set result(peak) $max_weight
    set result(peak_row) $row_of_peak
    set result(peak_column) $column_of_peak
    set result(center_row) $center_row
    set result(center_column) $center_column

    puts "DEBUG: peak:   $result(peak_row) $result(peak_column)"
    puts "DEBUG: center: $result(center_row) $result(center_column)"

}

proc CCrystalFindStrongestCrystal {num_row num_column weightListREF} {
    upvar $weightListREF weight_list

    array set column_weight [list]
    array set row_weight [list]
    array set summary [list]

    set start_row 0
    set end_row [expr $num_row - 1]
    set start_col 0
    set end_col [expr $num_column - 1]

    while {1} {
        CCrystalMatrixCalculation $num_row $num_column $weight_list \
        $start_row $end_row $start_col $end_col \
        summary row_weight column_weight

        ###################################################
        ### check multiple crystal
        set isZero 1
        set numCrystalVert 0
        for {set row $start_row} {$row <= $end_row} {incr row} {
            if {$row_weight($row) > 0} {
                if {$isZero} {
                    incr numCrystalVert
                    set isZero 0
                }
            } else {
                set isZero 1
            }
        }

        set isZero 1
        set numCrystalHorz 0
        for {set col $start_col} {$col <= $end_col} {incr col} {
            if {$column_weight($col) > 0} {
                if {$isZero} {
                    incr numCrystalHorz
                    set isZero 0
                }
            } else {
                set isZero 1
            }
        }

        #### find boundary starting from max until 0
        for {set row $summary(peak_row)} {$row >= $start_row} {incr row -1} {
            if {$row_weight($row) == 0} {
                break
            }
        }
        set start_row [expr $row + 1]
        for {set row $summary(peak_row)} {$row <= $end_row} {incr row} {
            if {$row_weight($row) == 0} {
                break
            }
        }
        set end_row [expr $row - 1]
        puts "new row: $start_row $end_row"

        #### find boundary starting from max until 0
        for {set col $summary(peak_column)} {$col >= $start_col} {incr col -1} {
            if {$column_weight($col) == 0} {
                break
            }
        }
        set start_col [expr $col + 1]
        for {set col $summary(peak_column)} {$col <= $end_col} {incr col} {
            if {$column_weight($col) == 0} {
                break
            }
        }
        set end_col [expr $col - 1]
        puts "new col: $start_col $end_col"

        if {$numCrystalVert <= 1 && $numCrystalHorz <= 1} {
            break
        }
        puts "numCrystal: vert=$numCrystalVert horz=$numCrystalHorz"
        log_warning maybe multiple crystals
        CCrystalLog "WARNING: maybe multiple crystals"
        ### loopback to check again
    }

    set max_row_weight 0
    for {set row $start_row} {$row <= $end_row} {incr row} {
        if {$row_weight($row) > $max_row_weight} {
            set max_row_weight $row_weight($row)
        }
    }

    set crystal_height_row 0.0
    for {set row $start_row} {$row <= $end_row} {incr row} {
        set crystal_height_row \
        [expr $crystal_height_row + 1.0 * $row_weight($row) / $max_row_weight]
    }

    set max_column_weight 0
    for {set col $start_col} {$col <= $end_col} {incr col} {
        if {$column_weight($col) > $max_column_weight} {
            set max_column_weight $column_weight($col)
        }
    }
    set crystal_width_column 0.0
    for {set col $start_col} {$col <= $end_col} {incr col} {
        set crystal_width_column [expr $crystal_width_column \
        + $column_weight($col) / double($max_column_weight)]
    }

    if {abs($summary(peak_row) - $summary(center_row)) > 1} {
        log_warning Weighted center is off from peak in row
    }
    if {abs($summary(peak_column) - $summary(center_column)) > 1} {
        log_warning Weighted center is off from peak in column
    }

    return [list \
    $summary(center_row) $summary(center_column) \
    $crystal_height_row $crystal_width_column \
    $start_row $end_row $start_col $end_col \
    ]
}

### return failed if the crystal occupys more than 2 rows and 2 columns
### with step size > 30u.
proc CCrystalCheckMicroCrystalSize { } {
    set start_row [get_center_crystal_data boundary_start_row]
    set end_row   [get_center_crystal_data boundary_end_row]
    set step_y    [get_center_crystal_data step_y]

    set start_col [get_center_crystal_data boundary_start_column]
    set end_col   [get_center_crystal_data boundary_end_column]
    set step_x    [get_center_crystal_data step_x]

    if {abs($end_row - $start_row) > 1 && $step_y >= 0.03 && \
    abs($end_col - $start_col) > 1 && $step_x >= 0.03} {
        CCrystalLog "check microCrystal size failed"
        return -code error NO_WAY_THIS_BIG
    }
}
proc CCrystalDoManualScan { user sessionID directory filePrefix } {
    variable scan2DEdgeSetup
    variable scan2DFaceSetup
    variable scan3DSetup_info

    set usingCollimator [lindex $scan3DSetup_info 4]

    #### tell program do not move to the center after scan.
    save_center_crystal_data scan_only 1
    save_center_crystal_data old_i2 0

    set bw 0
    set bh 0
    set extra_tag ""
    if {$usingCollimator} {
        foreach {bw bh} [collimatorMoveFirstMicron] break
        set extra_tag _COLLIMATOR
    }
    set tag EDGE_MANUAL${extra_tag}
    set file_prefix ${filePrefix}_$tag
    if {[get_operation_stop_flag]} {
        log_error stopped by user
        return 0
    }
    while {![CCrystalManual2DScan $tag $bw $bh $scan2DEdgeSetup \
    $user $sessionID $directory $file_prefix] \
    } {
        if {[get_operation_stop_flag]} {
            log_error stopped by user
            return 0
        }
        CCrystalAdjustSilRowOffset
        if {![CCrystalIncreaseExposeTime]} {
            log_error "manual collimator scan failed - no diffraction"
            set center_crystal_msg "error: no diffraction"
            return 0
        }
        ### disable i2 scaling
        save_center_crystal_data old_i2 0
    }

    if {[get_operation_stop_flag]} {
        log_error stopped by user
        return 0
    }
    set tag FACE_MANUAL${extra_tag}
    set file_prefix ${filePrefix}_$tag
    while {![CCrystalManual2DScan $tag $bw $bh $scan2DFaceSetup \
    $user $sessionID $directory $file_prefix] \
    } {
        if {[get_operation_stop_flag]} {
            log_error stopped by user
            return 0
        }
        CCrystalAdjustSilRowOffset
        if {![CCrystalIncreaseExposeTime]} {
            log_error "manual collimator scan failed - no diffraction"
            set center_crystal_msg "error: no diffraction"
            return 0
        }
        ### disable i2 scaling
        save_center_crystal_data old_i2 0
    }
    return 1
}
proc CCrystalManual2DScan { tag bw bh raster_setup \
user sessionID directory file_prefix } {
    CCrystalLog "M2DScan beam=$bw $bh setup=$raster_setup"

    global gMotorBeamWidth
    global gMotorBeamHeight

    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega
    variable $gMotorBeamWidth
    variable $gMotorBeamHeight
    variable center_crystal_msg

    ###########no motor should be moving
    error_if_moving \
    sample_x \
    sample_y \
    sample_z \
    gonio_phi \
    gonio_omega

    puts "ENTER MANUAL 2D SCAN setup=$raster_setup"


    save_center_crystal_data h_done_first 0
    save_center_crystal_data v_done_first 0
    save_center_crystal_data horizontal_done 0
    save_center_crystal_data vertical_done 0
    save_center_crystal_data scan_phase $tag

    ### move to orig
    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $raster_setup break

    if {$numRow * $numColumn <= 1} {
        return 0
    }

    save_center_crystal_data step_y [expr abs($cellHeight)]
    save_center_crystal_data num_row $numRow
    save_center_crystal_data step_x [expr abs($cellWidth)]
    save_center_crystal_data num_column $numColumn
    save_center_crystal_data scan_mode 2D

    set A4Beam $orig_a
    set orig_phi [expr $A4Beam - $gonio_omega]
    
    variable cfgSampleMoveSerial
    if {$cfgSampleMoveSerial == "1"} {
        move sample_x to $orig_x
        wait_for_devices sample_x
        move sample_y to $orig_y
        wait_for_devices sample_y
        move sample_z to $orig_z
        move gonio_phi to $orig_phi
        wait_for_devices sample_z gonio_phi
    } else {
        move sample_x to $orig_x
        move sample_y to $orig_y
        move sample_z to $orig_z
        move gonio_phi to $orig_phi
        wait_for_devices sample_x sample_y sample_z gonio_phi
    }

    ###DEBUG
    #CCrystalLogData

    #####adjust beam size
    if {$bw == 0 && $bh == 0} {
        set beamWidth  [expr abs($cellWidth)]
        set beamHeight [expr abs($cellHeight)]
        move $gMotorBeamWidth  to $beamWidth
        move $gMotorBeamHeight to $beamWidth
        wait_for_devices $gMotorBeamWidth $gMotorBeamHeight
    } else {
        set beamWidth  $bw
        set beamHeight $bh
    }
    save_center_crystal_data old_beam_x $beamWidth
    save_center_crystal_data old_beam_y $beamHeight

    move attenuation to 0
    wait_for_devices attenuation

    #scale exposure time according to ion chamber reading configed by
    #dose control
    if {[catch {
        set current_i2 [getStableIonCounts 0]
        CCrystalLog "stable ion chamber reading: $current_i2"
    } errorMsg]} {
        if {[string first aborted $errorMsg] >= 0} {
            return -code error aborted
        }
        set current_i2 0
        CCrystalLog "ion chamber reading error: $errorMsg"
    }
    set old_i2 [get_center_crystal_data old_i2]
    if {![string is double -strict $old_i2]} {
        set old_i2 0
    }
    ### exposure_time already changed by beamsize scale
    if {$current_i2 != 0 && $old_i2 != 0} {
        set old_exposure_time [get_center_crystal_data old_exposure_time]
        set new_exposure_time \
        [expr $old_exposure_time * abs( double($old_i2) / double($current_i2))]
        #CCrystalLog "by ion chamber: old time $old_exposure_time"
        #CCrystalLog "by ion chamber: old i2: $old_i2"
        #CCrystalLog "by ion chamber: new i2: $current_i2"
        #CCrystalLog "by ion chamber: new time: $new_exposure_time"


        set timeFromBeamSize [get_center_crystal_data exposure_time]
        set newTime [CCrystalAdjustExposureTimeByNumSpot $new_exposure_time]
        
        CCrystalLog "exposure factor adjusted by ion chamber to $newTime"
        CCrystalLog "DEBUG INFO: exposure factor from beamsize: $timeFromBeamSize"
    }
    
    ###retrieve collect image parameters
    set exposeTime [get_center_crystal_data exposure_time]
    set delta      [get_center_crystal_constant delta]
    set modeIndex  [get_center_crystal_data det_mode]

    save_center_crystal_data old_i2 $current_i2
    save_center_crystal_data old_exposure_time $exposeTime

    #####use attenuation if exposure time is less than 1 second
    CCrystalLog "Exposure factor: $exposeTime of [CCrystalGetStandardDoseText]"

    foreach {att exposeTime} \
    [CCrystalGetExposureFromFactor $exposeTime] break
    CCrystalLog "Exposure: time=$exposeTime at attenuation=$att"
    move attenuation to $att
    wait_for_devices attenuation

    set scan_phase [get_center_crystal_data scan_phase]
    set contents [format \
    "%s %dX%d %.3fX%.3fmm exposure: time $exposeTime attenuation=$att" \
    $scan_phase $numColumn $numRow $cellWidth $cellHeight]
    
    CCrystalLog            $contents
    set center_crystal_msg "$scan_phase ${numColumn}X${numRow}"

    if {[isOperation rasteringUpdate]} {
        set ext [get_center_crystal_data image_ext]
        set path [file join $directory ${file_prefix}.scan]
        rasteringUpdate_start simple_setup $scan_phase $path $ext $user $sessionID
    }

    set log "filename                  phi    omega        x        y        z  bm_x  bm_y sil_row" 
    CCrystalLog $log

    set image_file_list {}
    for {set row_index 0} {$row_index < $numRow} {incr row_index} {
        set proj_v [expr $row_index - ($numRow - 1) / 2.0]
        for {set col_index 0} {$col_index < $numColumn} {incr col_index} {
            set proj_h [expr $col_index - ($numColumn - 1) / 2.0]

            set sil_row [CCrystalNodeToSILRow \
            $numRow $numColumn $row_index $col_index]

            foreach {dx dy dz} \
            [calculateSamplePositionDeltaFromProjection \
            $raster_setup \
            $sample_x $sample_y $sample_z \
            $proj_v $proj_h] break

            #######move to position
            move sample_x by $dx
            move sample_y by $dy
            move sample_z by $dz
            wait_for_devices sample_x sample_y sample_z

            if {[isOperation rasteringUpdate]} {
                set cellIndex [expr $col_index + $row_index * $numColumn]
                rasteringUpdate_start update_cell $cellIndex exposing
            }

            ###prepare filename for collect image
            set fileroot \
            ${file_prefix}_[expr $row_index + 1]_[expr $col_index +1]

            set reuseDark 0 
            set operationHandle [start_waitable_operation collectFrame \
                                         0 \
                                             $fileroot \
                                             $directory \
                                             $user \
                                             gonio_phi \
                                             shutter \
                                             $delta \
                                             $exposeTime \
                                             $modeIndex \
                                             0 \
                                             $reuseDark \
                                             $sessionID]

            wait_for_operation $operationHandle
            set log_contents \
            [format "%-20s %8.3f %8.3f %8.3f %8.3f %8.3f %5.3f %5.3f %d" \
            $fileroot \
            $orig_phi $gonio_omega \
            $sample_x $sample_y $sample_z \
            [set $gMotorBeamWidth] [set $gMotorBeamHeight] $sil_row]
            CCrystalLog $log_contents
            
            #the data collection moves by delta. Move back.
            move gonio_phi to $orig_phi
            wait_for_devices gonio_phi

            ### add and analyze image
            CCrystalAddAndAnalyzeImage $user $sessionID $sil_row \
            $directory $fileroot

            lappend image_file_list $fileroot
            save_center_crystal_data image_list $image_file_list

            if {[isOperation rasteringUpdate]} {
                set cellIndex [expr $col_index + $row_index * $numColumn]
                rasteringUpdate_start update_cell $cellIndex done 
            }
            CCrystalCheckImage $user $sessionID
            if {[get_operation_stop_flag]} {
                break
            }
        };#for col_index
        if {[get_operation_stop_flag]} {
            log_error stopped by user
            break
        }
    };#for row_index
    ### need this to flush out last image
    start_operation detector_stop


    ####restore position
    move sample_x to $orig_x
    move sample_y to $orig_y
    move sample_z to $orig_z
    wait_for_devices sample_x sample_y sample_z

    ###DEBUG
    #CCrystalLogData
    if {[get_operation_stop_flag]} {
        log_error stopped by user
        return 0
    }

    set center_crystal_msg "$scan_phase wait for results"
    CCrystalWaitForAllImage $user $sessionID $directory
    if {[get_operation_stop_flag]} {
        log_error stopped by user
        return 0
    }
    if {![CCrystalFind2DCenter $user $sessionID $directory centerHorz centerVert]} {
        return 0
    }

    return 1
}
