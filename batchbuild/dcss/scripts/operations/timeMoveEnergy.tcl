proc timeMoveEnergy_initialize {} {

}

proc timeMoveEnergy_start { movementstart movementend } {

    #global variables
    variable d_spacing
    variable asymmetric_cut

    global gDevice

    #get list of motors which move during an energy move

    set motorlist [energy_motorlist ]

    log_note $motorlist

    set ll [llength $motorlist]

    #calculate starting position for mono_theta

    if {[info procs energy_calculate_mono_theta] == ""} {
        if  {[info procs energy_calculate_mono_theta_corr] != ""} {
        set old_mono_theta [energy_calculate_mono_theta_corr $movementstart $d_spacing]
        #calculate destination for mono_theta
        set new_mono_theta [energy_calculate_mono_theta_corr $movementend $d_spacing]

        # time mono_theta (mono_theta moves) 
        set time($ll) [timeOfMovement_start mono_theta $old_mono_theta $new_mono_theta]

        } else {
         log_error "energy script changed, please rewrite......"
                return -code error "need rewrite, mono_theta not found"
        }
    } else {
        set old_mono_theta [energy_calculate_mono_theta $movementstart $d_spacing]
        set new_mono_theta [energy_calculate_mono_theta $movementend $d_spacing]

        # time mono_theta (mono_angle moves)  asymmetric_cut could be a dummy variable instead
        if {[info exists gDevice(mono_angle,speed)]} {
            set time($ll) [timeOfMovement_start mono_angle [expr $old_mono_theta + $asymmetric_cut] [expr $new_mono_theta + $asymmetric_cut] ]
        } elseif {[info exists gDevice(mono_theta,speed)]} {
            set time($ll) [timeOfMovement_start mono_theta [expr $old_mono_theta + $asymmetric_cut] [expr $new_mono_theta + $asymmetric_cut] ]
        } else {
            log_error "energy script changed, please rewrite......"
            return -code error "need rewrite"
        }
    }

    #now deal with table motors

    for {set i 0} {$i < $ll} {incr i} {

        set motorname [lindex $motorlist $i]

        set proc_name energy_calculate_${motorname}_corr
        if {[info procs $proc_name] == ""} {
            set proc_name energy_calculate_${motorname}
            if {[info procs $proc_name] == ""} {
                log_error "energy script changed, please rewrite......"
                return -code error "need rewrite"
            }
        }

        set old_position [expr [$proc_name $old_mono_theta]]

        set new_position [expr [$proc_name $new_mono_theta]]

        set time($i) [timeOfMovement_start $motorname $old_position $new_position ]
    }
 

set totaltime 0
set i 0
    while { $i < ($ll + 1) } {
	if { $time($i) > $totaltime } {
	    set totaltime $time($i)
	}
	set i [expr $i +1]
    }
return $totaltime

}
