proc alignTable_reportError { msg } {
    log_warning $msg
    send_operation_update $msg
}
proc alignTable_initialize {} {

}


proc alignTable_start {} {

    variable beamlineID
    variable energy
    variable optimizedEnergyParameters
    
    set result1 [alignTablevert]
    send_operation_update $result1
    if {$beamlineID == "BL9-1" || $beamlineID == "BL11-1" || $beamlineID == "BL7-1" } {
	set result2 [alignTableslide]
    } else {
	set result2 [alignTablehorz]
    }
    send_operation_update $result2
    log_warning $result1
    log_warning $result2

    #Reset energy if "reset energy after optimize" option is on
    if {[lindex $optimizedEnergyParameters 5] == 1} {
	energy_set $energy
	log_warning "energy set to $energy" 
    }
}

proc alignTablevert {} {

    send_operation_update "alignTableVert"

    variable optimizedEnergyParameters
    variable table_vert 
    variable beam_size_x 
    variable beam_size_y 

    #prepare for vertical scan

    set ionChamber  [lindex $optimizedEnergyParameters 18]
    set scanStep [lindex $optimizedEnergyParameters 23]
    set scanPoints [lindex $optimizedEnergyParameters 22]
    set scanTime [lindex $optimizedEnergyParameters 24]
    set flux  [lindex $optimizedEnergyParameters 14]
    set wmin  [lindex $optimizedEnergyParameters 15]
    set wmax 1.0
    set glc  [lindex $optimizedEnergyParameters 16]
    set grc  [lindex $optimizedEnergyParameters 17]

    # save old positions
    set  old_table_vert $table_vert
    set  old_beam_size_x $beam_size_x
    set  old_beam_size_y $beam_size_y

    #make the beam as big as software limit in the direction we are not scanning:
    move beam_size_x to [lindex [getGoodLimits beam_size_x] 1]
    move beam_size_y to [lindex $optimizedEnergyParameters 20]
    wait_for_devices  beam_size_x beam_size_y
    
    if { [catch {
	set opt_table_vert [optimizeMotor_start table_vert $old_table_vert $ionChamber $scanPoints $scanStep $scanTime $flux $wmin $wmax $glc $grc] 
	set opt_table_vert [lindex $opt_table_vert 0]
    } errorResult] } {
        log_warning "Table_vert optimization did not work"
	alignTable_reportError $errorResult
	#Recover if scan did not work 
	move table_vert to $old_table_vert
	move beam_size_x to $old_beam_size_x
	move beam_size_y to $old_beam_size_y
	wait_for_devices table_vert beam_size_x beam_size_y
        return -code error \
	    "Table_vert optimization did not work. See error message in log"
    } else {
	move table_vert to $opt_table_vert
	move beam_size_x to $old_beam_size_x
	move beam_size_y to $old_beam_size_y
	wait_for_devices beam_size_x beam_size_y table_vert

    alignFrontEndLog table_vert [expr $opt_table_vert - $old_table_vert] \
    from $old_table_vert to $opt_table_vert
	
        log_note "Table_vert optimized at $opt_table_vert. Old position was $old_table_vert"
	
	return "Table_vert optimized at $opt_table_vert. Old position was $old_table_vert"
    }
}

proc alignTablehorz {} {
    send_operation_update "alignTableHorz"

    variable optimizedEnergyParameters
    variable table_horz 
    variable beam_size_x 
    variable beam_size_y 

    #optimize table horizontally

    #Store table position for recovery 
    set old_table_horz $table_horz
    # save old beam size positions
    set  old_beam_size_x $beam_size_x
    set  old_beam_size_y $beam_size_y
    
    #Prepare for horizontal scan

    set ionChamber  [lindex $optimizedEnergyParameters 18]
    set scanStep [lindex $optimizedEnergyParameters 23]
    set scanPoints [expr 2* [lindex $optimizedEnergyParameters 22]] 
    #Scan table horz in negative direction to avoid backlash
    set scanStep -$scanStep

    set scanTime [lindex $optimizedEnergyParameters 24]
    set flux  [lindex $optimizedEnergyParameters 14]
    set wmin  [lindex $optimizedEnergyParameters 15]
    set wmax 1.5
    set glc  [lindex $optimizedEnergyParameters 16]
    set grc  [lindex $optimizedEnergyParameters 17]

    move beam_size_x to [lindex $optimizedEnergyParameters 19]
    move beam_size_y to [lindex [getGoodLimits beam_size_y] 1]
    wait_for_devices  beam_size_x beam_size_y

     if { [catch {
	    set opt_table_horz [optimizeMotor_start table_horz $old_table_horz $ionChamber $scanPoints $scanStep $scanTime $flux $wmin $wmax $glc $grc]
	    set opt_table_horz [lindex $opt_table_horz 0]
	 
     } errorResult] } {
	 log_warning "Table_horz optimization did not work."
	 alignTable_reportError $errorResult
	 
	 #Recover if scan did not work
	 move table_horz to $old_table_horz
	 move beam_size_x to $old_beam_size_x
	 move beam_size_y to $old_beam_size_y
	 wait_for_devices table_horz beam_size_x beam_size_y
	 return -code error "Table_horz optimization did not work. See error message in log"
	 
     } else {
	 move table_horz to $opt_table_horz
	 move beam_size_x to $old_beam_size_x
	 move beam_size_y to $old_beam_size_y
	 wait_for_devices beam_size_x beam_size_y  table_horz

    alignFrontEndLog table_horz [expr $opt_table_horz - $old_table_horz] \
    from $old_table_horz to $opt_table_horz

	 log_note "Table_horz optimized at $opt_table_horz. Old position was $old_table_horz"
	 return "Table_horz optimized at $opt_table_horz. Old position was $old_table_horz"
     }
}

proc alignTableslide {} {
    send_operation_update "alignTableSlide"

    variable optimizedEnergyParameters
    variable table_slide
    variable beam_size_x 
    variable beam_size_y 
    variable beamlineID

    #optimize table slide

    #Store table position for recovery 
    set old_table_slide $table_slide
    # save old beam size positions
    set  old_beam_size_x $beam_size_x
    set  old_beam_size_y $beam_size_y
    
    #Prepare for horizontal scan

    set ionChamber  [lindex $optimizedEnergyParameters 18]
    set scanStep [expr 4* [lindex $optimizedEnergyParameters 23]]
    # Beam on BL11-1 is narrower
    if {$beamlineID == "BL11-1"} {set scanStep [expr 2* [lindex $optimizedEnergyParameters 23]]}
    #Beamline 7-1 applies backlash in the +ve direction, so scan from positive to negative
    if {$beamlineID =="BL7-1"} {
	set scanStep -$scanStep
    }	
    #Make scan wider for table_slide
    set scanPoints [expr 2 * [lindex $optimizedEnergyParameters 22] ]

    set scanTime [lindex $optimizedEnergyParameters 24]
    set flux  [lindex $optimizedEnergyParameters 14]
    set wmin  [lindex $optimizedEnergyParameters 15]
    set wmax 2.5
    set glc  [lindex $optimizedEnergyParameters 16]
    set grc  [lindex $optimizedEnergyParameters 17]

    move beam_size_x to [lindex $optimizedEnergyParameters 19]
    move beam_size_y to [lindex [getGoodLimits beam_size_y] 1]
    wait_for_devices  beam_size_x beam_size_y

    if { [catch {
	set opt_table_slide [optimizeMotor_start table_slide $old_table_slide $ionChamber $scanPoints $scanStep $scanTime $flux $wmin $wmax $glc $grc]
	set opt_table_slide [lindex $opt_table_slide 0]
    } errorResult] } {
	log_warning "Table_slide optimization did not work"
	alignTable_reportError $errorResult

	#Recover if scan did not work
	move table_slide to $old_table_slide
	move beam_size_x to $old_beam_size_x
	move beam_size_y to $old_beam_size_y
	wait_for_devices table_slide beam_size_x beam_size_y
	return -code error "Table_slide optimization did not work. See error message in log"
    } else {
	move table_slide to $opt_table_slide
	move beam_size_x to $old_beam_size_x
	move beam_size_y to $old_beam_size_y
	wait_for_devices beam_size_x beam_size_y table_slide

    alignFrontEndLog table_slide [expr $opt_table_slide - $old_table_slide] \
    from $old_table_slide to $opt_table_slide

	log_note "Table_slide optimized at $opt_table_slide. Old position was $old_table_slide"
	return "Table_slide optimized at $opt_table_slide. Old position was $old_table_slide"
    }
}
