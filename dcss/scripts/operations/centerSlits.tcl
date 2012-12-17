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
#CONFIG is via string: center_slits_const

##################################
# temperary data are saved in string center_slits_data
#################################################3

set CSlitsSessionID ""

proc centerSlits_initialize {} {
    variable center_slits_constant_name_list
    variable center_slits_data_name_list

    #### max_loop_xxxx has no effects if move_xxxx is not enabled
    set center_slits_constant_name_list [list \
        kappa \
        max_loop_vertical \
        max_loop_horizontal \
        move_vertical \
        move_horizontal \
        threshold_vertical \
        threshold_horizontal \
        angle_between_phi_and_kappa \
    ]

    set center_slits_data_name_list [list \
    log_file_name \
    hv_scale \
    delta_omega \
    delta_phi \
    angle_phi_axis \
    v0_offset \
    user \
    ] 
}

proc centerSlits_start { user sessionID directory filePrefix } {
    variable center_slits_const
    variable cslits_constant_snapshot
    variable gonio_phi
    variable gonio_omega
    variable CSlitsSessionID

    set orig_gonio_omega $gonio_omega
    set orig_gonio_phi $gonio_phi

    if {$sessionID == "SID"} {
        set sessionID PRIVATE[get_operation_SID]
        puts "centerSlits use operation SID: [SIDFilter $sessionID]"
    }

    set cslits_constant_snapshot $center_slits_const

    if {[catch {impCreateDirectory $user $sessionID $directory} errMsg]} {
        if {[string first already $errMsg] < 0} {
            return -code error "create directory $directory failed: $errMsg"
        }
    }

    ###check kappa
    set kappa [get_center_slits_constant kappa]
    if {![string is double -strict $kappa]} {
        return -code error "wrong kappa:$kappa Must be a number"
    }
    set max_loop_horizontal [get_center_slits_constant max_loop_horizontal]

    set log_file_name [file join $directory ${filePrefix}.log]
    save_center_slits_data log_file_name $log_file_name
    set contents "$user start center slits\n"
    append contents "directory=$directory filePrefix=$filePrefix\n"
    #####call write file to overwrite if file exists.
    impWriteFile $user $sessionID $log_file_name $contents false

    #### we need these to write log file
    save_center_slits_data user $user
    set CSlitsSessionID $sessionID

    CSlitsHorzVertScale $kappa

    if {$kappa != 0 && $max_loop_horizontal > 0} {
        if {abs($orig_gonio_omega - 270.0) > 30.0} {
            return -code error "omega must be around 270 degrees"
        }
        set d_o [get_center_slits_data delta_omega]
        set delta_phi [get_center_slits_data delta_phi]
        set omega [expr 270.0 - $d_o]
        set phi [expr $orig_gonio_phi - $delta_phi]

        set check_by_moving 0
        if {$check_by_moving} {
            move gonio_kappa to 0
            wait_for_devices gonio_kappa
            move gonio_kappa to $kappa
            wait_for_devices gonio_kappa
            move gonio_kappa to 0
            wait_for_devices gonio_kappa

            move gonio_omega to $omega
            wait_for_devices gonio_omega
            move gonio_omega to $orig_gonio_omega
            wait_for_devices gonio_omega
        } else {
            global gDevice
            if {$gDevice(gonio_kappa,lockOn)} {
                return -code error "motor gonio_kappa is locked"
            }
            if {![limits_ok gonio_kappa $kappa]} {
                return -code error gonio_kappa_sw_limit
            }
            if {$gDevice(gonio_omega,lockOn)} {
                return -code error "motor gonio_omega is locked"
            }
            if {![limits_ok gonio_omega $omega]} {
                return -code error gonio_omega_sw_limit
            }
        }

    } else {
        set omega $orig_gonio_omega
        set phi $orig_gonio_phi
        log_warning kappa==0 no horizontal centering
    }

    ###DEBUG
    CSlitsLogConstant

    CSlitsVertical $user $sessionID $directory ${filePrefix}V

    if {$kappa == 0 || $max_loop_horizontal <= 0} {
        CSlitsLog "no horizontal centering"
        return "no horizontal centering"
    }

    move gonio_kappa to $kappa
    wait_for_devices gonio_kappa
    move gonio_omega to $omega
    wait_for_devices gonio_omega

    move gonio_phi to $phi
    wait_for_devices gonio_phi

    CSlitsLog [format "horz: phi: %.3f omega: %.3f" $phi $omega]
    
    CSlitsHorizontal $user $sessionID $directory ${filePrefix}H
    CSlitsLog [format "move omega kappa and phi back to: %.3f 0 %.3f" \
    $orig_gonio_omega $orig_gonio_phi]
    move gonio_omega to $orig_gonio_omega
    move gonio_kappa to 0
    move gonio_phi   to $orig_gonio_phi
    wait_for_devices gonio_omega gonio_kappa gonio_phi
    return success
}
proc CSlitsVertical { user sessionID directory filePrefix } {
    variable slit_1_vert
    variable slit_2_vert
    variable gonio_kappa

    ###### save slit position
    set orig_v_slit1 $slit_1_vert
    set orig_v_slit2 $slit_1_vert

    CSlitsLog [format "original slit_1_vert: %.3f slit_2_vert: %.3f" \
    $slit_1_vert $slit_2_vert]
        
    save_center_slits_data v0_offset 0
    set max_loop_vertical [get_center_slits_constant max_loop_vertical]
    if {$max_loop_vertical <= 0} {
        CSlitsLog "max_loop_vertical <= 0: only make sure loop centered"
        CCrystalCheckLoopCenter
        return
    }

    ###### kappa must at 0
    if {abs($gonio_kappa) >= 0.001} {
        return -code error "kappa=$gonio_kappa not at 0"
    }

    set move_vertical [get_center_slits_constant move_vertical]
    set threshold_vertical [get_center_slits_constant threshold_vertical]
    set threshold_vertical [expr abs($threshold_vertical)]

    set previous_v 0.99e99;##a big number
    for {set v_loop 0} {$v_loop <$max_loop_vertical} {incr v_loop} {
        set handle [start_waitable_operation centerCrystal \
        $user $sessionID $directory $filePrefix 1]
        set result [wait_for_operation_to_finish $handle]
        set slit_y [lindex $result 1]
        save_center_slits_data v0_offset $slit_y
        CSlitsLog [format "vertical offset=%.3f" $slit_y]
        if {!$move_vertical} {
            CSlitsLog "vertical move not enabled"
            break
        }
        
        ####to move before break:
        ####move this if below move
        if {abs($slit_y) <= abs($threshold_vertical)} {
            CSlitsLog "wthin vertical threshold"
            break
        }
        if {abs($slit_y) > abs($previous_v)} {
            CSlitsLog "exceed previous vertical offset"
            break
        }
        set previous_v $slit_y
        
        set dv [expr -1.0 * $slit_y]
        move slit_1_vert by $dv
        move slit_2_vert by $dv
        wait_for_devices slit_1_vert slit_2_vert
        CSlitsLog [format "slits moved by %.3f" $dv]
        save_center_slits_data v0_offset 0
        CSlitsOptimizeTable
    }
    set dv1 [expr $slit_1_vert - $orig_v_slit1]
    if {abs($dv1) > 0.001} {
        CSlitsLog [format "total vertical moved %.3f" $dv1]
        CSlitsLog [format "new slit_1_vert: %.3f slit_2_vert: %.3f" \
        $slit_1_vert $slit_2_vert]
    }
}

proc CSlitsHorizontal { user sessionID directory filePrefix } {
    variable slit_1_horiz
    variable slit_2_horiz

    set orig_h_slit1 $slit_1_horiz
    set orig_h_slit2 $slit_2_horiz
    CSlitsLog [format "original slit_1_horiz: %.3f slit_2_horiz: %.3f" \
    $slit_1_horiz $slit_2_horiz]
        
    set max_loop_horizontal [get_center_slits_constant max_loop_horizontal]
    if {$max_loop_horizontal < 0} {
        return
    }

    set move_horizontal [get_center_slits_constant move_horizontal]
    set threshold_horizontal [get_center_slits_constant threshold_horizontal]
    set threshold_horizontal [expr abs($threshold_horizontal)]
    set hv_scale [get_center_slits_data hv_scale]
    set v0_offset [get_center_slits_data v0_offset]
    set kappa [get_center_slits_constant kappa]
    set delta_phi [get_center_slits_data delta_phi]
    set delta_omega [get_center_slits_data delta_omega]
    set angle_offset [expr $delta_phi + $delta_omega]
    set angle_phi_axis [get_center_slits_data angle_phi_axis]

    CSlitTrickCenterCrystal 0

    set previous_h 0.99e99;###a big number
    for {set h_loop 0} {$h_loop < $max_loop_horizontal} {incr h_loop} {
        set handle [start_waitable_operation centerCrystal \
        $user $sessionID $directory $filePrefix 1 $angle_phi_axis $angle_offset]
        set result [wait_for_operation_to_finish $handle]
        set slit_y [lindex $result 1]
        CSlitsLog [format "new vertical offset=%.3f" $slit_y]
        set slit_x [expr $hv_scale * ($slit_y - $v0_offset)]
        CSlitsLog [format "horizontal offset=%.3f" $slit_x]
        if {$slit_x >= 0.0} {
            CSlitsLog [format "slits are %.3f off spear side" $slit_x]
        } else {
            set temp [expr -1.0 * $slit_x]
            CSlitsLog [format "slits are %.3f off ssrl side" $temp]
        }

        if {!$move_horizontal} {
            CSlitsLog "horizontal move not enabled"
            break
        }
        
        ####to move before break:
        ####move this if below move
        if {abs($slit_x) <= abs($threshold_horizontal)} {
            CSlitsLog "within horizontal threshold"
            break
        }
        if {abs($slit_x) >= abs($previous_h)} {
            CSlitsLog "exceed previous horizontal offset"
            break
        }
        set previous_h $slit_x

        set dh $slit_x
        move slit_1_horiz by $dh
        move slit_2_horiz by $dh
        wait_for_devices slit_1_horiz slit_2_horiz
        CSlitsLog [format "slits horizontal moved by %.3f" $dh]
        CSlitsOptimizeTable
    }
    set dh1 [expr $slit_1_horiz - $orig_h_slit1]
    if {abs($dh1) > 0.001} {
        CSlitsLog [format "Total horizontal moved: %.3f" $dh1]
        CSlitsLog [format "new slit_1_horiz: %.3f slit_2_horiz: %.3f" \
        $slit_1_horiz $slit_2_horiz]
    }
}

### force optimize table
proc CSlitsOptimizeTable { } {
    variable optimized_energy
    variable optimizedEnergyParameters

    if {![info exists optimized_energy]} {
        CSlitsLog "skip optimizing table, no optimized_energy motor"
        return
    }

    if {![info exists optimizedEnergyParameters]} {
        CSlitsLog "no optimizedEnergyParameters, cannot force it"
    } else {
        #### clear the last timestamp to force it
        set optimizedEnergyParameters [lreplace $optimizedEnergyParameters \
        10 10 0]
    }
    
    CSlitsLog "Optimizing table after moving slits"

    move optimized_energy by 0
    wait_for_devices optimized_energy
}

proc CSlitTrickCenterCrystal { move_back_to_loop_center } {
    variable save_loop_size
    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi

    if {$move_back_to_loop_center} {
        foreach {status loopWidth faceHeight edgeHeight s_x s_y s_z g_phi } \
        $save_loop_size break

        move sample_x to $s_x
        move sample_y to $s_y
        move sample_z to $s_z
        move gonio_phi to $g_phi
        wait_for_devices sample_x sample_y sample_z gonio_phi
    } else {
        set save_loop_size [lreplace $save_loop_size 4 7 $sample_x \
        $sample_y $sample_z $gonio_phi]
    }
}

################################################################
######################## utilities #############################
################################################################
proc get_center_slits_constant { name } {
    variable cslits_constant_snapshot

    set index [CSlitsConstantNameToIndex $name]
    return [lindex $cslits_constant_snapshot $index]
}
proc get_center_slits_data { name } {
    variable center_slits_data

    set index [CSlitsDataNameToIndex $name]
    return [lindex $center_slits_data $index]
}
proc save_center_slits_data { name value } {
    variable center_slits_data

    set index [CSlitsDataNameToIndex $name]
    set center_slits_data [lreplace $center_slits_data $index $index $value]
}

proc CSlitsDataNameToIndex { name } {
    variable center_slits_data_name_list
    variable center_slits_data

    if {![info exists center_slits_data]} {
        return -code error "string not exists: center_slits_data"
    }

    set index [lsearch -exact $center_slits_data_name_list $name]
    if {$index < 0} {
        puts "DataNameToIndex failed name=$name list=$center_slits_data_name_list"
        return -code error "data bad name: $name"
    }

    if {[llength $center_slits_data] <= $index} {
        return -code error "bad contents of string center_slits_data"
    }
    return $index
}
proc CSlitsConstantNameToIndex { name } {
    variable cslits_constant_snapshot
    variable center_slits_constant_name_list

    if {![info exists cslits_constant_snapshot]} {
        return -code error "string not exists: cslits_constant_snapshot"
    }

    set index [lsearch -exact $center_slits_constant_name_list $name]
    if {$index < 0} {
        return -code error "bad name: $name"
    }

    if {[llength $cslits_constant_snapshot] <= $index} {
        return -code error "bad contents of string center_slits_const"
    }
    return $index
}
proc CSlitsLog { contents {update_operation 1}} {
    variable CSlitsSessionID

    set user      [get_center_slits_data user]
    set sessionID $CSlitsSessionID
    set logPath [get_center_slits_data log_file_name]

    set ts [clock format [clock seconds] -format "%d %b %Y %X"]

    impAppendTextFile $user $sessionID $logPath "$ts $contents\n"

    if {$update_operation} {
        send_operation_update $contents
    }
}
proc CSlitsLogConstant { } {
    variable center_slits_const
    variable center_slits_constant_name_list

    set ll [llength $center_slits_constant_name_list]

    set log_contents "CENTER SLITS PARAMETERS\n"
    for {set i 0} {$i < $ll} {incr i} {
        append log_contents [lindex $center_slits_constant_name_list $i]
        append log_contents =
        append log_contents [lindex $center_slits_const $i]
        append log_contents "\n"
    }
    ##### only write to log file, not send operation update
    CSlitsLog $log_contents 0
}
proc CSlitsLogData { } {
    variable center_slits_data_name_list
    variable center_slits_data
    variable CSlitsSessionID

    set user      [get_center_slits_data user]
    set sessionID $CSlitsSessionID

    set ll [llength $center_slits_data_name_list]
    set log_contents "CENTER CRYSTAL DATA\n"
    for {set i 0} {$i < $ll} {incr i} {
        append log_contents [lindex $center_slits_data_name_list $i]
        append log_contents =
        append log_contents [lindex $center_slits_data $i]
        append log_contents "\n"
    }
    ##### only write to log file, not send operation update
    CSlitsLog $log_contents 0
}

proc CSlitsHorzVertScale { degree_kappa } {
    if {$degree_kappa == 0.0} {
        save_center_slits_data hv_scale 0.0
        save_center_slits_data delta_omega 0.0
        save_center_slits_data delta_phi 0.0
        save_center_slits_data angle_phi_axis 0.0
        CSlitsLog "kappa: 0.0 ==>delta_omega: 0.0 delta_phi: 0.0 hv_scale: 0.0"
        return
    }

    set PI 3.1415926

    set DEGREE_PHI_KAPPA_AXIS 60.0;#####degree
    set ANGLE_PHI_KAPPA_AXIS [expr $DEGREE_PHI_KAPPA_AXIS * $PI / 180.0]
    set cos_x [expr cos($ANGLE_PHI_KAPPA_AXIS)]
    set sin_x [expr sin($ANGLE_PHI_KAPPA_AXIS)]

    set kappa [expr $degree_kappa * $PI / 180.0]
    set cos_kappa [expr cos($kappa)]
    set sin_half_kappa [expr sin([expr $kappa / 2.0])]

    ################ ALPHA ####################
    ### alpha is angle between phi and omega axis caused by kappa
    ###
    ### sin(alpha/2)=sin(kappa/2)*sin(ANGLE_PHI_KAPPA_AXIS)
    set sin_half_alpha [expr $sin_x * $sin_half_kappa]
    set alpha [expr asin($sin_half_alpha) * 2.0]

    ##### prepare temp variables
    set sin_alpha [expr sin($alpha)]
    set tan_alpha [expr tan($alpha)]
    if {$sin_alpha == 0.0} {
        return -code error "bad kappa leads to hv_scale too big"
    }

    ############### BETA ######################
    ### beta is delta_phi caused by kappa
    ### cos(beta)=cos(kappa)/sqrt(cos2(X)+sin2(X)cos2(kappa))
    set cos_beta [expr $cos_kappa / \
    sqrt($cos_x * $cos_x + $sin_x * $sin_x * $cos_kappa * $cos_kappa)]
    set beta [expr acos($cos_beta)]

    ############## OMEGA ##########
    ### this is delta ometa to bring phi axis back to perpendicular plane to
    ### the beam
    ###
    ### sin(delta_omega)=sin(x)cos(x)(1-cos(kappa)/sin(alpha)
    set sin_d_o [expr $sin_x * $cos_x * (1 - $cos_kappa ) / $sin_alpha]
    set d_o [expr asin($sin_d_o)]
    set cos_d_o [expr cos($d_o)]

    ############# GAMMA #######################
    ### gamma is delta_phi caused by omega correction
    ### cos(gamma)=cos(omega)/sqrt(1+tan2(alpha)sin2(omega))
    set cos_gamma [expr $cos_d_o / \
    sqrt(1.0 + $tan_alpha * $tan_alpha * $sin_d_o * $sin_d_o)]
    set gamma [expr acos($cos_gamma)]

    ############## results ##########
    set hv_scale [expr 1.0 / $sin_alpha]
    set degree_delta_omega [expr $d_o * 180.0 / $PI]
    set degree_delta_phi [expr ($beta - $gamma) * 180.0 / $PI]
    set degree_angle_phi_axis [expr $alpha * 180.0 / $PI]
    ##### we found delta_phi is the same as delta_omega in all cases.
    ##### but this is without math proof yet.
    if {abs($degree_delta_phi - $degree_delta_omega) > 1.0} {
        puts "diff delta_phi and delta_omega"
        puts "delta_phi: $degree_delta_phi"
        puts "delta_omega: $degree_delta_omega"
    }
    
    save_center_slits_data hv_scale $hv_scale
    save_center_slits_data delta_omega $degree_delta_omega
    save_center_slits_data delta_phi $degree_delta_phi
    save_center_slits_data angle_phi_axis $degree_angle_phi_axis

    CSlitsLog [format "kappa: %.3f ==>delta_omega: %.3f hv_scale: %.3f" \
    $degree_kappa $degree_delta_omega $hv_scale]
}
