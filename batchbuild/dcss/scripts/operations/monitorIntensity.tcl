proc monitorIntensity_initialize {} {
}

proc monitorIntensity_start { } {
    global gMotorBeamWidth
    global gMotorBeamHeight

    variable energy
    variable table_vert
    variable optimizedEnergyParameters
    variable beamlineID
    variable $gMotorBeamHeight
    variable $gMotorBeamWidth
    variable attenuation
    variable spear_current
    variable beamstop_z
    global gDevice

    #############################################
    # check arguments
    #############################################

    set energyMotorName [getEnergyMotorName]
    ###set energyMotorName energy
    variable $energyMotorName

    set energy_min [lindex [getGoodLimits energy] 0] 
    set energy_max [lindex [getGoodLimits energy] 1]
    set energy_ref [expr 12658]
    
    set testEnergies [::config getStr monitorIntensity.energy]
    if {$testEnergies == ""} {
        set testEnergies [list $energy_min $energy_max $energy_ref]
    }
    set testIonChambers [list]
    set ionChamberCandidates [list i0 i1 i2]
    foreach candidate $ionChamberCandidates {
        if {[isIonChamber $candidate]} {
            lappend testIonChambers $candidate
        }
    }

    set beam_min_y [lindex [getGoodLimits $gMotorBeamHeight] 0]
    set beam_min_x [lindex [getGoodLimits $gMotorBeamWidth] 0]

    set beamstop_max [lindex [getGoodLimits beamstop_z] 1]

    #Get initial positions to move back 
    set energy_recover $energy
    set beamx_recover [set $gMotorBeamWidth]
    set beamy_recover [set $gMotorBeamHeight]
    set attenuation_recover $attenuation

    set intTime 1

    move attenuation to 0
    wait_for_devices attenuation
    move $gMotorBeamWidth to $beam_min_x 
    move $gMotorBeamHeight to $beam_min_y 
    move beamstop_z to [expr $beamstop_max - 0.5 ]

    wait_for_devices  beamstop_z $gMotorBeamWidth $gMotorBeamHeight
    
    set filename ${beamlineID}_ic.dat
    set fileDir /home/webserverroot/secure/staff_pages/UserSupport/BEAMLINES
    if {[catch {open $fileDir/$filename a} handle]} {
        log_error Error opening $filename: $handle
        return -code "open file failed"
    }

    puts $handle "[time_stamp]; beam size: [set $gMotorBeamWidth] mm x [set $gMotorBeamHeight] mm; beamstop: $beamstop_z mm; SPEAR [format "%3.1f" $spear_current] mA"

    #########################################################
    ##### catch everything in order to close the file handle
    #########################################################
    if {[catch {

	foreach x $testEnergies {

	    move $energyMotorName to $x
	    wait_for_devices $energyMotorName


	    close_shutter shutter
	    wait_for_shutters shutter 
	    puts -nonewline $handle "E = [format "%5.0f" $x] eV "

	    foreach y $testIonChambers {
		read_ion_chambers $intTime $y 
		wait_for_devices $y
		set reading [expr 200.0 *  [get_ion_chamber_counts $y] / $spear_current]

		puts -nonewline $handle "$y=[format "%.2e" ${reading}] ,"
	    }

	    open_shutter shutter 
	    wait_for_shutters shutter
	    read_ion_chambers $intTime i_beamstop
	    wait_for_devices i_beamstop
    
	    set reading_ibs [expr 200.0 * [get_ion_chamber_counts i_beamstop]]
	    puts -nonewline $handle "ibs=[format "%.2e" ${reading_ibs}] ;"

	    close_shutter shutter
	    wait_for_shutters shutter
	}
	puts $handle ""
    } errMsg]} {
	close $handle
	move $energyMotorName to $energy_recover
	move $gMotorBeamWidth to $beamx_recover
	move $gMotorBeamHeight to $beamy_recover
	move attenuation to $attenuation_recover
	wait_for_devices  $energyMotorName $gMotorBeamWidth $gMotorBeamHeight attenuation
	return -code error $errMsg
    }

    close $handle
    move $energyMotorName to $energy_recover
    move $gMotorBeamWidth to $beamx_recover
    move $gMotorBeamHeight to $beamy_recover
    move attenuation to $attenuation_recover
    wait_for_devices  $energyMotorName $gMotorBeamWidth $gMotorBeamHeight attenuation

    log_warning Results written to $fileDir/$filename

}

