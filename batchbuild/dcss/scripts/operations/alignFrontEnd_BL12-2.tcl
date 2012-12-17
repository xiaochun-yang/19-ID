proc alignFrontEndConstantNameToIndex { name } {
    variable cfgAlignFrontEndConstantNameList
    variable alignFrontEnd_constant

    if {![info exists alignFrontEnd_constant]} {
        return -code error "string not exists: alignFronEnd_constant_snapshot"
    }

    set index [lsearch -exact $cfgAlignFrontEndConstantNameList $name]
    if {$index < 0} {
        return -code error "bad name: $name"
    }

    if {[llength $alignFrontEnd_constant] <= $index} {
        return -code error "bad contents of string alignFrontEnd_constant"
    }
    return $index
}
proc get_alignFrontEnd_constant { name } {
    variable alignFrontEnd_constant

    set index [alignFrontEndConstantNameToIndex $name]
    return [lindex $alignFrontEnd_constant $index]
}

proc alignFrontEndMakeSureEnoughConstant { } {
    variable cfgAlignFrontEndConstantNameList
    variable alignFrontEnd_constant

    set ln [llength $cfgAlignFrontEndConstantNameList]
    set lc [llength $alignFrontEnd_constant]

    if {$ln > $lc} {
        set nAdd [expr $ln - $lc]
        log_error alignFrontEnd_constant does not have enough data. $nAdd space appended
        log_error Please check with config tab

        for {set i 0} {$i < $nAdd} {incr i} {
            lappend alignFrontEnd_constant ""
        }
        return -code error "constant_not_enought_data"
    }
}

proc alignFrontEnd_initialize {} {
    variable cfgAlignFrontEndConstantNameList

    set cfgAlignFrontEndConstantNameList [::config getStr alignFrontEndConstantsNameList]
}

proc alignFrontEndLog { args } {
    catch {
        set logFileName alignFrontEnd.log
        set timeStamp [clock format [clock seconds] -format "%D-%T"]
        if {[catch {open $logFileName a} fh]} {
            puts "failed to open log file: $logFileName"
        } else {
            puts $fh "$timeStamp $args"
            close $fh
        }
    }
}

proc alignSlits { } {

    variable slit_1_horiz
    variable slit_1_vert
    variable beam_size_y
    variable beam_size_x
    variable optimizedEnergyParameters

    set flux  [lindex $optimizedEnergyParameters 14]
    set ic  [lindex $optimizedEnergyParameters 18] 
    set time [lindex $optimizedEnergyParameters 24]

    #Configurable
    set maxscanx [get_alignFrontEnd_constant optimize_vert_slit_gap_horz]
    set minscany [get_alignFrontEnd_constant optimize_vert_slit_gap_vert]

    set minscanx [get_alignFrontEnd_constant optimize_horz_slit_gap_horz]
    set maxscany [get_alignFrontEnd_constant optimize_horz_slit_gap_vert]

    set wminV [get_alignFrontEnd_constant optimize_slit_wmin_vert]
    set wminH [get_alignFrontEnd_constant optimize_slit_wmin_horz]
    set wmaxV [get_alignFrontEnd_constant optimize_slit_wmax_vert]
    set wmaxH [get_alignFrontEnd_constant optimize_slit_wmax_horz]
    set glcV  [get_alignFrontEnd_constant optimize_slit_glc_vert]
    set glcH  [get_alignFrontEnd_constant optimize_slit_glc_horz]
    set grcV  [get_alignFrontEnd_constant optimize_slit_grc_vert]
    set grcH  [get_alignFrontEnd_constant optimize_slit_grc_horz]
    set stepV    [get_alignFrontEnd_constant optimize_slit_step_size_vert]
    set stepH    [get_alignFrontEnd_constant optimize_slit_step_size_horz]
    set pointsV  [get_alignFrontEnd_constant optimize_slit_num_step_vert]
    set pointsH  [get_alignFrontEnd_constant optimize_slit_num_step_horz]

    set old_slit_1_vert $slit_1_vert
    set old_slit_1_horiz $slit_1_horiz
    set new_slit_1_vert $slit_1_vert
    set new_slit_1_horiz $slit_1_horiz
    set old_beam_size_y  $beam_size_y
    set old_beam_size_x  $beam_size_x
 
    move beam_size_y to $minscany
    move beam_size_x to $maxscanx
    wait_for_devices beam_size_y beam_size_x
    if { [catch {
	set new_slit_1_vert [optimizeMotor_start slit_1_vert $old_slit_1_vert $ic $pointsV $stepV $time  $flux $wminV $wmaxV $glcV $grcV] 
	set new_slit_1_vert [lindex $new_slit_1_vert 0]
    } errorResult] } {
 
	alignTable_reportError $errorResult


	#Recover if scan did not work 
	move slit_1_vert to $old_slit_1_vert
	wait_for_devices slit_1_vert 
	move beam_size_y to $old_beam_size_y
	move beam_size_x to $old_beam_size_x
	wait_for_devices beam_size_y beam_size_x
        return -code error "Vertical slit scan failed"
    } else {
	
	move slit_1_vert to $new_slit_1_vert
	wait_for_devices slit_1_vert
	move beam_size_y to $old_beam_size_y
	move beam_size_x to $old_beam_size_x
	wait_for_devices beam_size_y beam_size_x
	log_warning "New vertical slit position $new_slit_1_vert; old was $old_slit_1_vert "

    alignFrontEndLog slit_1_vert [expr $new_slit_1_vert - $old_slit_1_vert] \
    from $old_slit_1_vert to $new_slit_1_vert
    }
    move beam_size_x to $minscanx
    move beam_size_y to $maxscany
    wait_for_devices beam_size_x beam_size_y
    if { [catch {
	set new_slit_1_horiz [optimizeMotor_start slit_1_horiz $old_slit_1_horiz $ic $pointsH $stepH $time  $flux $wminH $wmaxH $glcH $grcH] 
	set new_slit_1_horiz [lindex $new_slit_1_horiz 0]
    } errorResult] } {
 
	alignTable_reportError $errorResult


	#Recover if scan did not work 
	move slit_1_horiz to $old_slit_1_horiz
	wait_for_devices slit_1_horiz 
	move beam_size_x to $old_beam_size_x
	move beam_size_y to $old_beam_size_y
	wait_for_devices beam_size_x beam_size_y
        return -code error "Horizontal slit scan failed"
    } else {
	
	move slit_1_horiz to $new_slit_1_horiz
	wait_for_devices slit_1_horiz 
	move beam_size_x to $old_beam_size_x
	move beam_size_y to $old_beam_size_y
	wait_for_devices beam_size_x beam_size_y
 	log_warning "New horizontal slit position $new_slit_1_horiz ; old was $old_slit_1_horiz "

    alignFrontEndLog slit_1_horz [expr $new_slit_1_horiz - $old_slit_1_horiz] \
    from $old_slit_1_horiz to $new_slit_1_horiz
    }

}

proc alignFrontEnd_vert {ic step points time minscany maxscanx flux wmin wmax glc grc} {
    global gMotorBeamWidth
    global gMotorBeamHeight

    set motorSlit1Vert slit_1_vert
    if {[isMotor focusing_mirror_2_mfd_vert]} {
        set motorSlit1Vert focusing_mirror_2_mfd_vert
    }

    variable table_vert 
    variable sample_x 
    variable $gMotorBeamHeight 
    variable $gMotorBeamWidth 
    variable gonio_phi 
    variable gonio_omega
    variable $motorSlit1Vert
    variable slit_2_vert

    set x_offset1 0
    set x_offset2 0
    set new_sample_x1 $sample_x
    set new_sample_x2 $sample_x

    #Store beam size  for recovering
    set old_beam_size_x [set $gMotorBeamWidth]
    set old_beam_size_y [set $gMotorBeamHeight]
    #Store sample position for recovery 
    set old_sample_x $sample_x
    
    #Preparing for scans
    
    #Move gonio_z so that sample_x scan runs in the vertical direction (up-down)
    move gonio_phi to [expr 360 - $gonio_omega]
    # Move beam size 
    move $gMotorBeamWidth to $maxscanx
    move $gMotorBeamHeight to $minscany

    wait_for_devices gonio_phi $gMotorBeamWidth $gMotorBeamHeight 

    if { [catch {
	set new_sample_x1 [optimizeMotor_start sample_x $old_sample_x $ic $points $step $time  $flux $wmin $wmax $glc $grc] 
	set new_sample_x1 [lindex $new_sample_x1 0]
    } errorResult] } {
 
	alignTable_reportError $errorResult


	#Recover if scan did not work 
	move sample_x to $old_sample_x
	move $gMotorBeamWidth to $old_beam_size_x
	move $gMotorBeamHeight to $old_beam_size_y

	wait_for_devices sample_x $gMotorBeamWidth $gMotorBeamHeight
        return -code error " First sample_x scan failed"
    } else {

	#Prepare for second scan 180 degrees away - sample_x moves from down up
	move sample_x to $old_sample_x
	move gonio_phi by 180
	wait_for_devices gonio_phi sample_x
	# This scan is done in the negative direction so the offset sign is chnaged
	set x_offset1 [expr - $new_sample_x1 + $old_sample_x]
	
	if { [catch {
	    set new_sample_x2 [optimizeMotor_start sample_x $old_sample_x $ic $points $step $time $flux $wmin $wmax $glc $grc] 
	    set new_sample_x2 [lindex $new_sample_x2 0]
	} errorResult] } {

	    alignTable_reportError $errorResult

	    #Recover if scan did not work
	    move sample_x to $old_sample_x
	    move $gMotorBeamWidth to $old_beam_size_x
	    move $gMotorBeamHeight to $old_beam_size_y

	    wait_for_devices sample_x $gMotorBeamWidth $gMotorBeamHeight
	    return -code error "Second sample_x scan failed"
	} else {

	    # This scan was done in the positive direction
	    set x_offset2 [expr $new_sample_x2 - $old_sample_x]

	    set center_rotation [expr ($x_offset2 - $x_offset1)/2 + $old_sample_x]
	    log_warning "center of rotation is $center_rotation; old was $old_sample_x "

	    set phi_offset [expr $new_sample_x2 - $center_rotation ]

        ##################################
        if {0} {
        if {[isMotor gonio_vert]} {
            variable gonio_vert
            set old_gonio_vert $gonio_vert
            set new_gonio_vert [expr $gonio_vert + $phi_offset]
            move gonio_vert to $new_gonio_vert
            wait_for_devices gonio_vert
            log_warning gonio_vert position was corrected by $phi_offset
            alignFrontEndLog phy_offset_vert $phi_offset \
            gonio_vert from $old_gonio_vert to $new_gonio_vert
            return
        }
        }
        ##################################

	    set new_table_vert [expr $phi_offset + $table_vert]
	    set new_slit_1_vert [expr - $phi_offset + [set $motorSlit1Vert]]
	    set new_slit_2_vert [expr - $phi_offset + $slit_2_vert]

        if {1} {
	    move table_vert to $new_table_vert
	    move $motorSlit1Vert to $new_slit_1_vert
	    move slit_2_vert to $new_slit_2_vert
	    wait_for_devices table_vert $motorSlit1Vert slit_2_vert
        alignFrontEndLog phy_offset_vert $phi_offset
        }
	    move sample_x to $center_rotation
	    wait_for_devices sample_x
	    log_warning "table_vert position was corrected by $phi_offset"
	    move $gMotorBeamWidth to $old_beam_size_x
	    move $gMotorBeamHeight to $old_beam_size_y
	    wait_for_devices $gMotorBeamWidth $gMotorBeamHeight

	}
    }
}

proc alignFrontEnd_horz {ic step points time minscanx maxscany minscany maxscanx flux wmin wmax glc grc method} {
    global gMotorBeamWidth
    global gMotorBeamHeight

    set motorSlit1Horiz slit_1_horiz
    if {[isMotor focusing_mirror_2_mfd_vert]} {
        set motorSlit1Horiz mirror_feedback_detector_horz
    }

    global gDevice
    variable beamlineID
    variable table_horz
    variable table_slide
    variable sample_z
    variable sample_x
    variable $gMotorBeamHeight 
    variable $gMotorBeamWidth 
    variable gonio_kappa
    variable $motorSlit1Horiz
    variable slit_2_horiz
    
    set x_offset 0
    set z_offset 0
    set kappa_offset 0
    set new_sample_z $sample_z
    set new_sample_x $sample_x

    #Store beam size  for recovering
    set old_beam_size_x [set $gMotorBeamWidth]
    set old_beam_size_y [set $gMotorBeamHeight]
    #Store sample position for recovery 
    set old_sample_z $sample_z
    set old_sample_x $sample_x

    set horiz_motor table_horz
    #On side beamlines we want to move table_slide as a rule (unless it has been disabled)
    if {$beamlineID == "BL9-1" || $beamlineID == "BL11-1" || $beamlineID == "BL7-1" } {set horiz_motor table_slide}



    ### prepare: this is horitontal, no matter which method, 
    ### $gMotorBeamWidth should be minimum.

    if {$method == "3"} {

    if {$beamlineID == "BL12-2"} {
        log_error cannot do this on BL12-2
        return -code error "not available"
    }

	move $gMotorBeamHeight to $minscany
	move $gMotorBeamWidth to $maxscanx
	wait_for_devices  $gMotorBeamWidth $gMotorBeamHeight

	#is kappa locked?
	if {$gDevice(gonio_kappa,lockOn)} {
	    return -code error "motor gonio_kappa is locked"
	} 

        #Procedure 3: Use kappa to correct center of rotation

	# Move to the kappa upper limit. 
	move gonio_kappa to [lindex [getGoodLimits gonio_kappa ] 1]
	wait_for_devices gonio_kappa

	if { [catch {
	    set new_sample_x [optimizeMotor_start sample_x $old_sample_x $ic $points $step $time $flux $wmin $wmax $glc $grc]
	    set new_sample_x [lindex $new_sample_x 0]
	} errorResult] } {

	    alignTable_reportError $errorResult

	    #Recover if scan did not work
	    move sample_x to $old_sample_x
	    move $gMotorBeamWidth to $old_beam_size_x
	    move $gMotorBeamHeight to $old_beam_size_y
	    move gonio_kappa to 0
	    wait_for_devices gonio_kappa sample_x $gMotorBeamWidth $gMotorBeamHeight
	    return -code error "sample_x scan to determine kappa c.o.r failed"
	} else {

	    # when we rotate the vertical axis about kappa, the new y axis is 
	    # y' = y * (cos gonio_kappa (sin 30)**2  + (cos 30)**2) 
	    # (the angle of the Huber kappa axis to z is 60, the angle to the y axis is 30)
	    # The angle between the new and old y axis is alpha = arccos (y'/y)
	    
	    set scale [expr 0.75 + 0.25 * cos(3.14*$gonio_kappa/180.0)]
	    set alpha [expr acos($scale)] 

	    set x_offset [expr (-$old_sample_x + $new_sample_x) * $scale ]
	    set kappa_offset [expr $x_offset * cos ($alpha)/ tan($alpha) ]
	    
	    set center_rotation_kappa [expr $old_sample_z + $kappa_offset ]

	    log_warning "kappa center of rotation is $center_rotation_kappa; old was $old_sample_z "
	    log_warning "beam offset is $kappa_offset"

        alignFrontEndLog phy_offset_horz_kappa $kappa_offset

	    move gonio_kappa to 0
	    wait_for_devices gonio_kappa
		
	    set new_horiz_motor [expr $kappa_offset + [set $horiz_motor]]
	    set new_slit_1_horiz [expr - $kappa_offset + [set $motorSlit1Horiz]]
	    set new_slit_2_horiz [expr  - $kappa_offset + $slit_2_horiz]

	    #table slide increases toward SPEAR
	    if {$horiz_motor == "table_slide"} {
		set new_horiz_motor [expr - $kappa_offset + [set $horiz_motor]]
	    }
	    move sample_z to $center_rotation_kappa
	    move sample_x to $old_sample_x
	    move $horiz_motor to $new_horiz_motor
	    move $motorSlit1Horiz to $new_slit_1_horiz	    
	    move slit_2_horiz to $new_slit_2_horiz
	    wait_for_devices $horiz_motor $motorSlit1Horiz slit_2_horiz sample_z sample_x
	    log_warning "$horiz_motor position was corrected by $kappa_offset"
 
	}
    } else {

	#if method is 1 or 2, Prepare for horizontal scan

	move $gMotorBeamHeight to $maxscany
	move $gMotorBeamWidth to $minscanx
	wait_for_devices  $gMotorBeamWidth $gMotorBeamHeight


	if { [catch {
	    set new_sample_z [optimizeMotor_start sample_z $old_sample_z $ic $points $step $time $flux $wmin $wmax $glc $grc]
	    set new_sample_z [lindex $new_sample_z 0]
	} errorResult] } {
	    
	    alignTable_reportError $errorResult
	    
	    #Recover if scan did not work
	    move sample_z to $old_sample_z
	    move $gMotorBeamWidth to $old_beam_size_x
	    move $gMotorBeamHeight to $old_beam_size_y
	
	    wait_for_devices fluorescence_z sample_z $gMotorBeamWidth $gMotorBeamHeight
	    return -code error "sample_z scan failed"
	} else {

	    #sample_z scans in negative direction (positive towards SPEAR)
	    set z_offset [expr $old_sample_z - $new_sample_z]

	    #Procedure 1: move the sample to the center of the beam
	    if {$method == "1"} {
		    
		move sample_z to $new_sample_z
		wait_for_devices sample_z
		log_warning "Moved sample_z by -$z_offset mm to $new_sample_z"
	    }

	    #Procedure 2: Trust that the sample is centered on the camera, adjust table and slits

	    if {$method == "2"} {

        alignFrontEndLog phy_offset_horz_sample_z $z_offset

		set new_horiz_motor [expr $z_offset + [set $horiz_motor]]
		set new_slit_1_horiz [expr - $z_offset + [set $motorSlit1Horiz]]
		set new_slit_2_horiz [expr - $z_offset + $slit_2_horiz]
		#table slide increases toward SPEAR
		if {$horiz_motor == "table_slide"} {
		    set new_horiz_motor [expr - $z_offset + [set $horiz_motor]]
		}
        if {1} {
		move sample_z to $old_sample_z
		move $horiz_motor to $new_horiz_motor
		move $motorSlit1Horiz to $new_slit_1_horiz
		move slit_2_horiz to $new_slit_2_horiz
		wait_for_devices $horiz_motor $motorSlit1Horiz slit_2_horiz sample_z
        }

		log_warning "$horiz_motor position was corrected by $z_offset"
		
	    }
	}
    }

    
    move $gMotorBeamWidth to $old_beam_size_x
    move $gMotorBeamHeight to $old_beam_size_y
    wait_for_devices $gMotorBeamWidth $gMotorBeamHeight 

}
    
proc alignFrontEnd_start {aligntable alignslits horalign} {
    global gMotorBeamWidth
    global gMotorBeamHeight

    alignFrontEndMakeSureEnoughConstant

    # align front end using fluorescence:
    # Move detector_z to the standard position for alignmnet
    # Optimize the table
    # MOve fluorescence scan close to the sample
    # calculate center of rotation and phi axis offset, correct vertical slit and table position 
    # move sample_x to center of rotation
    # scan sample_z,  calculate z_offset
    # For horizontal alignmnet, there are three alternatives:
    #1, not do anything (just move sample to where the beam is most intense)
    #2 assume the sample is in the center of rotation correct horizontal slit and table position
    #3 do a second scan at a different value of kappa, calculate center of rotation, offset and correct the table and slit position
    # Reset energy
    # If a scan fails, move back the fluorescence scan and exit

    # In future should prepare for scan by setting attenuation

    if {[isMotor detector_z_corr]} {
        set distanceMotor detector_z_corr
    } else {
        set distanceMotor detector_z
    }

    variable fluorescence_z
    variable $distanceMotor
    variable attenuation
    variable optimizedEnergyParameters
    variable energy
    variable gonio_kappa

    set flux  [lindex $optimizedEnergyParameters 14]
    #Configurable per beamline
    set ionChamber [get_alignFrontEnd_constant align_front_ion_chamber]
    set distance   [get_alignFrontEnd_constant align_front_detector_distance]
    set attn       [get_alignFrontEnd_constant align_front_attenuation]
    set enrg       [get_alignFrontEnd_constant align_front_energy]

    set scanStepV   [get_alignFrontEnd_constant align_front_step_size_vert]
    set scanStepH   [get_alignFrontEnd_constant align_front_step_size_horz]
    set scanPointsV [get_alignFrontEnd_constant align_front_num_step_vert]
    set scanPointsH [get_alignFrontEnd_constant align_front_num_step_horz]
    set scanTimeV   [get_alignFrontEnd_constant align_front_scan_time_vert]
    set scanTimeH   [get_alignFrontEnd_constant align_front_scan_time_horz]
    set wminV       [get_alignFrontEnd_constant align_front_wmin_vert]
    set wminH       [get_alignFrontEnd_constant align_front_wmin_horz]
    set wmaxV       [get_alignFrontEnd_constant align_front_wmax_vert]
    set wmaxH       [get_alignFrontEnd_constant align_front_wmax_horz]
    set glcV        [get_alignFrontEnd_constant align_front_glc_vert]
    set glcH        [get_alignFrontEnd_constant align_front_glc_horz]
    set grcV        [get_alignFrontEnd_constant align_front_grc_vert]
    set grcH        [get_alignFrontEnd_constant align_front_grc_horz]

    set max_scan_beam_x [get_alignFrontEnd_constant align_front_vert_gap_horz]
    set min_scan_beam_y [get_alignFrontEnd_constant align_front_vert_gap_vert]

    set min_scan_beam_x [get_alignFrontEnd_constant align_front_horz_gap_horz]
    set max_scan_beam_y [get_alignFrontEnd_constant align_front_horz_gap_vert]

    set old_attn $attenuation
    set old_distance [set $distanceMotor]

#Method 3 will align kappa c.o.r.
    set horiz_method $horalign

    if { $gonio_kappa != 0.0} {
	    log_error "Kappa is not 0! Exiting procedure"
        return -code error "kappa must at 0 to start"
    }

	move energy to $enrg
	move $distanceMotor to $distance
	wait_for_devices $distanceMotor energy

    ########## DISABLED for now ###############
    if {0} {
	#Align the table if requested
	if { $aligntable == 1 } { alignTable_start }

	#Align slits if requested

	if { $alignslits == 1 } { alignSlits }
    }
    ###########################################

	move attenuation to $attn
	move fluorescence_z to [expr 0.1 + [lindex [getGoodLimits fluorescence_z] 0]]
	wait_for_devices fluorescence_z attenuation

	if { [catch {alignFrontEnd_vert $ionChamber $scanStepV $scanPointsV $scanTimeV $min_scan_beam_y $max_scan_beam_x $flux $wminV $wmaxV $glcV $grcV} error] } {
	    log_error "$error. Correct this or use green paper "
	    move attenuation to $old_attn
	    move $distanceMotor to $old_distance
	    move fluorescence_z to [expr -1.0 + [lindex [getGoodLimits fluorescence_z] 1]]
	    wait_for_devices $distanceMotor fluorescence_z attenuation
	} else {
        ####################################
        if {$horiz_method > 1} {
        ####################################
	    
	    if { [catch {alignFrontEnd_horz $ionChamber $scanStepH $scanPointsH $scanTimeH $min_scan_beam_x $max_scan_beam_y $min_scan_beam_y $max_scan_beam_x  $flux $wminH $wmaxH $glcH $grcH $horiz_method } error] } {
		
		log_error "$error . Correct this or use green paper"
		move attenuation to $old_attn
		move $distanceMotor to $old_distance
		move fluorescence_z to [expr -1.0 + [lindex [getGoodLimits fluorescence_z] 1]]
		wait_for_devices $distanceMotor fluorescence_z attenuation
		
	    }  else {
		#Reset energy if "reset energy after optimize" option is on
		if {[lindex $optimizedEnergyParameters 5] == 1} {
		    energy_set $energy
		    log_warning "energy set to $energy" 
		}
	    
	    }
        ####################################
        }
        ####################################
	}
	move attenuation to $old_attn
	move $distanceMotor to $old_distance
	move fluorescence_z to [expr -1.0 + [lindex [getGoodLimits fluorescence_z] 1]]
	wait_for_devices $distanceMotor fluorescence_z attenuation
}
