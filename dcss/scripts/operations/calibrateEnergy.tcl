proc calibrateEnergy_initialize {} {
}

proc calibrateEnergy_start { args } {

    variable energy
    variable beamlineID
    variable optimizedEnergyParameters
    variable attenuation

    global gDevice

    set dir /home/blctl/$beamlineID
    set scanfile ${dir}/energyScan.log
    set choochout ${dir}/chooch.out
    set energyMotorName [getEnergyMotorName]

    set step 1
    set start 12620
    set end 12700
    set reverse 0
    set detector i1
    set attn 0
    set oldattn $attenuation
    
    if { $beamlineID == "BL1-5"} {
        set reverse 1
    } elseif { $beamlineID == "BL9-1"  } {
        set reverse 1
    } elseif { $beamlineID == "BL11-1" } {
        set reverse 1
        set step 2
    } elseif { $beamlineID == "BL12-2" } {
        set detector i2
    } 
    
    log_warning "Starting energy calibration on $beamlineID"
    set time 0.5
    set positions {}
    set counts {}

    if {$start >= [lindex [getGoodLimits energy] 0] && $end <= [lindex [getGoodLimits energy] 1] } {

        set energyold $energy

        if {$reverse == 1} {
            set newend $start
            set start $end
            set end $newend
        }
        move $energyMotorName to $start
        log_warning "Moving energy to $start"
        wait_for_devices $energyMotorName
        move attenuation to $attn
        log_warning "Removing attenuation filters"
        wait_for_devices attenuation

        if {$gDevice(Se,state) == "open" } {
            log_warning "Closing Se filter"
            close_shutter Se
            wait_for_shutters Se
        }

	if {($end - $start) < 0} {
	    set points [expr ($end - $start)/$step * -1 ]
	} else {
	    set points [expr ($end - $start)/$step ]
	}


        if { [catch {set handle [open $scanfile w] } errorResult ] } {

            log_error "Error opening $scanfile"
            move energy $energyold
            wait_for_devices energy 
            move attenuation $oldattn 
            wait_for_devices attenuation
            open_shutter Se
            wait_for_shutters Se
        } else {


            puts $handle "Test Data from Se Foil"
            puts $handle "$points"
            for { set point 0 } { $point < $points } { incr point } {

	    
		if {($end - $start) < 0} {
		    set position [expr $start - ($point * $step)]
		} else {
		    set position [expr $start + ($point * $step)]
		}
		move energy to $position
		wait_for_devices energy 
		
		read_ion_chambers $time $detector
		wait_for_devices $detector

		lappend positions $position
		lappend counts [get_ion_chamber_counts $detector ]
	    }

	    if {($end - $start) < 0} {
		for {set i [expr int($points-1)]} { $i >= 0} {incr i -1} {
		    puts $handle "[lindex $positions $i] [lindex $counts $i]"
		    }
	    } else {
		for {set i 0} { $i < $points} {incr i} {
		    puts $handle "[lindex $positions $i] [lindex $counts $i]"
		}
	    }
	    close $handle

	}


	if { [catch {exec /home/sw/rhel4/utils/chooch -e Se -a K $scanfile | grep infl > $choochout} msg]} { 

	    set energynew [exec cut -c10-17 $choochout]

            if {$energynew == ""} {
		log_error "Chooch failed. See $choochout"
		move energy to $energyold
		wait_for_devices energy 
		move attenuation to $oldattn
		wait_for_devices attenuation
	    } else {

		move energy to $energynew
		wait_for_devices energy
		set energy 12658
		log_warning "Energy reset from $energynew to $energy"
		log_note "Energy Calibrated for Beamline $beamlineID"
	    }
	}

	open_shutter Se
	wait_for_shutters Se
	move attenuation to $oldattn
	wait_for_devices attenuation

    } else {
	log_error "The required energy scan is beyond the energy limits at this beamline"
    }

}
