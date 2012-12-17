proc photodiode_initialize {} {
}

proc photodiode_start { thick ionChamber gain num_interval args } {
    variable energy
    variable table_vert
    variable optimizedEnergyParameters
    variable beamlineID
    variable beam_size_y 
    variable beam_size_x
    variable beam_size_sample_x
    variable beam_size_sample_y
    variable spear_current
    global gDevice

    #############################################
    # check arguments
    #############################################
    if {![isIonChamber $ionChamber]} {
        log_error $ionChamber is not an ion chamber
        return -code error "wrong argument"
    }
    set ref_ionChamber [lindex $optimizedEnergyParameters 18]
    if { $ref_ionChamber == $ionChamber } {
        log_error "$ionChamber is used by optimized energy"
        log_error "Please connect photodiode to a different preamplifier"
        return -code error "wrong argument"
    } 

    if {$gain == 0} {
        log_error gain cannot be 0
        return -code error "wrong argument"
    }

    if {$num_interval <= 0} {
        log_error num_interval must be > 0
        return -code error "wrong argument"
    }

    set attList $args

    if {$attList == ""} {
        set attList [list 0 25 50 75 99]
    }

    set energyMotorName [getEnergyMotorName]
    variable $energyMotorName
    variable attenuation

    set old_attn  $attenuation
    set old_energy  $energy

    foreach {energy_min energy_max} [getGoodLimits energy] break

    set intTime 1

    log_warning "photodiode connected to $ionChamber preamplifier"
    log_warning "reference ion chamber: $ref_ionChamber "
    send_operation_update photodiode connected to $ionChamber preamplifier
    send_operation_update reference ion chamber: $ref_ionChamber

    move attenuation to 0
    wait_for_devices attenuation

    set interval [expr ( $energy_max - $energy_min )/$num_interval]
    log_warning Data will be collected \
    from $energy_min to $energy_max eV at $interval eV intervals

    set filename ${beamlineID}_intensity.dat
    set fileDir /home/webserverroot/secure/staff_pages/UserSupport/BEAMLINES
    set fullPath "$fileDir/$filename"
    if {[catch {open $fullPath w} handle]} {
        log_error Error opening $filename: $handle
        return -code "open file failed"
    }

    #########################################################
    ##### catch everything in order to close the file handle
    #########################################################
    if {[catch {
        set gotMicroSize 0
        set extraMsg ""
        if {[isString collimator_status]} {
            variable collimator_status
            foreach {isMicro index w h} $collimator_status break
            if {$isMicro} {
                set extraMsg "collimator_size: $w $h"
                set gotMicroSize 1
            }
        }
        if {!$gotMicroSize} {
            puts $handle "# [time_stamp] Photodiode thickness: $thick micron; gain: $gain; Slit gap size: $beam_size_x , $beam_size_y mm; Spear current: $spear_current Integration time: $intTime"
        } else {
            puts $handle "# [time_stamp] Photodiode thickness: $thick micron; gain: $gain; Slit gap size: $beam_size_x , $beam_size_y mm; Spear current: $spear_current Integration time: $intTime $extraMsg"
        }
        puts $handle "# Energy(keV) Flux(ph/s) Current(mA) $ref_ionChamber shutter closed(V) $ref_ionChamber shutter open(V)"

        close_shutter shutter
        wait_for_shutters shutter 
        set points [expr $num_interval + 1]
        for {set index 0} {$index < $points} {incr index} {
            move $energyMotorName to [expr $energy_min + $index * $interval]
            wait_for_devices $energyMotorName

            set line_contents [format {%3.3f} [expr $energy/1000.0]]

            foreach att $attList {
                move attenuation to $att
                wait_for_devices attenuation
                #### delay to settle down
                wait_for_time 2000

                read_ion_chambers $intTime $ionChamber $ref_ionChamber
                wait_for_devices $ionChamber $ref_ionChamber
                set dark [get_ion_chamber_counts $ionChamber]
                set ref_closed [get_ion_chamber_counts $ref_ionChamber]

                open_shutter shutter 
                wait_for_shutters shutter
                read_ion_chambers $intTime $ionChamber $ref_ionChamber
                wait_for_devices $ionChamber $ref_ionChamber
                close_shutter shutter
                wait_for_shutters shutter

                set current \
                [expr ( [get_ion_chamber_counts $ionChamber]  - $dark )*$gain]
                set ref_open [get_ion_chamber_counts $ref_ionChamber]

                set photons [ current2photons $current $energy $thick ]
                append line_contents " [format {%1.3e} $photons] $current  [format {%6.2f} $ref_closed]   [format {%6.2f} $ref_open]"

                send_operation_update point [expr $index + 1] of $points: \
                energy = [set $energyMotorName] \
                attenuation = $attenuation \
                dark = $dark ref_closed = $ref_closed \
                current=$current ref_open=$ref_open
            }

            puts $handle $line_contents
            flush $handle

        }

        #for web-ice
        puts $handle " "
        puts $handle \
        "#The flux was measured for this beam size (hor, ver in mm)"
        puts $handle "flux_size $beam_size_sample_x $beam_size_sample_y"


    } errMsg]} {
        close $handle
        move attenuation to $old_attn
        wait_for_devices attenuation
        move $energyMotorName to $old_energy
        wait_for_devices $energyMotorName

        return -code error $errMsg
    }
    close $handle

    log_warning Results written to $fileDir/$filename

    ### save a copy for dcss to calculate flux
    global DCS_DIR
    set destDir [file join $DCS_DIR dcsconfig tables $beamlineID]
    if {[catch {
        file mkdir $destDir
        file copy -force -- $fullPath [file join $destDir flux.dat]
    } errMsg]} {
        log_error failed to save a copy for DCSS to calculate flux: $errMsg
    }

    set fileToExec \
    /home/www/templates/beamline-properties/generate_properties.csh

    if {[file executable $fileToExec]} {
        if {[catch {
            exec $fileToExec $beamlineID 
            log_warning " Generated Web-Ice properties file."
        } errMsg]} {
            log_error execute $fileToExec failed: $errMsg
        }
    } else {
        log_warning file not executable: $fileToExec
    }

    move attenuation to $old_attn
    wait_for_devices attenuation 
    move $energyMotorName to $old_energy
    wait_for_devices $energyMotorName

}

proc safexp {x} {
 return [expr ($x>700 ? 1e300 : ($x<-700 ? 0 : exp($x)))
] }

# element: Si
proc Si_elastic_1551_49999_poly {x} {
set Si_elastic_1551_49999_shift 9.93021
set Si_elastic_1551_49999_poly0 -1.49150971119711
set Si_elastic_1551_49999_poly1 -1.53007194611835
set Si_elastic_1551_49999_poly2 -0.0750975673075001
set Si_elastic_1551_49999_poly3 0.105841127450652
set Si_elastic_1551_49999_poly4 -0.0748076354022508
set Si_elastic_1551_49999_poly5 -0.0637459125629581
set Si_elastic_1551_49999_poly6 -0.0111535396573683
return [expr \
  $Si_elastic_1551_49999_poly0 \
 +$Si_elastic_1551_49999_poly1*($x-$Si_elastic_1551_49999_shift)\
 +$Si_elastic_1551_49999_poly2*pow($x-$Si_elastic_1551_49999_shift,2)\
 +$Si_elastic_1551_49999_poly3*pow($x-$Si_elastic_1551_49999_shift,3)\
 +$Si_elastic_1551_49999_poly4*pow($x-$Si_elastic_1551_49999_shift,4)\
 +$Si_elastic_1551_49999_poly5*pow($x-$Si_elastic_1551_49999_shift,5)\
 +$Si_elastic_1551_49999_poly6*pow($x-$Si_elastic_1551_49999_shift,6)
] }
proc Si_elastic_poly {x} {
 return [expr ( $x>log(1550) && $x<=log(50000) ? [Si_elastic_1551_49999_poly $x] : 1/0)
] }
proc Si_elastic {x} {
 return [expr ([safexp [expr [Si_elastic_poly log($x)]]])
] }
proc Si_inelastic_1551_49999_poly {x} {
set Si_inelastic_1551_49999_shift 9.93021
set Si_inelastic_1551_49999_poly0 -1.95796972354655
set Si_inelastic_1551_49999_poly1 0.232830702715137
set Si_inelastic_1551_49999_poly2 -0.194591455563139
set Si_inelastic_1551_49999_poly3 0.029188183777832
set Si_inelastic_1551_49999_poly4 0.0301915535353304
set Si_inelastic_1551_49999_poly5 -0.0048540082552366
set Si_inelastic_1551_49999_poly6 -0.00422220153702006
return [expr \
  $Si_inelastic_1551_49999_poly0 \
 +$Si_inelastic_1551_49999_poly1*($x-$Si_inelastic_1551_49999_shift)\
 +$Si_inelastic_1551_49999_poly2*pow($x-$Si_inelastic_1551_49999_shift,2)\
 +$Si_inelastic_1551_49999_poly3*pow($x-$Si_inelastic_1551_49999_shift,3)\
 +$Si_inelastic_1551_49999_poly4*pow($x-$Si_inelastic_1551_49999_shift,4)\
 +$Si_inelastic_1551_49999_poly5*pow($x-$Si_inelastic_1551_49999_shift,5)\
 +$Si_inelastic_1551_49999_poly6*pow($x-$Si_inelastic_1551_49999_shift,6)
] }
proc Si_inelastic_poly {x} {
 return [expr ( $x>log(1550) && $x<=log(50000) ? [Si_inelastic_1551_49999_poly $x] : 1/0)
] }
proc Si_inelastic {x} {
 return [expr ([safexp [expr [Si_inelastic_poly log($x)]]])
] }
proc Si_photoelectric_1551_1838_poly {x} {
set Si_photoelectric_1551_1838_shift 7.45076
set Si_photoelectric_1551_1838_poly0 5.90636989728173
set Si_photoelectric_1551_1838_poly1 -2.70907767695258
set Si_photoelectric_1551_1838_poly2 -0.00152684513852439
set Si_photoelectric_1551_1838_poly3 0.000100013659941552
set Si_photoelectric_1551_1838_poly4 9.99996205732192e-05
set Si_photoelectric_1551_1838_poly5 0.0001
set Si_photoelectric_1551_1838_poly6 0.0001
return [expr \
  $Si_photoelectric_1551_1838_poly0 \
 +$Si_photoelectric_1551_1838_poly1*($x-$Si_photoelectric_1551_1838_shift)\
 +$Si_photoelectric_1551_1838_poly2*pow($x-$Si_photoelectric_1551_1838_shift,2)\
 +$Si_photoelectric_1551_1838_poly3*pow($x-$Si_photoelectric_1551_1838_shift,3)\
 +$Si_photoelectric_1551_1838_poly4*pow($x-$Si_photoelectric_1551_1838_shift,4)\
 +$Si_photoelectric_1551_1838_poly5*pow($x-$Si_photoelectric_1551_1838_shift,5)\
 +$Si_photoelectric_1551_1838_poly6*pow($x-$Si_photoelectric_1551_1838_shift,6)
] }
proc Si_photoelectric_1840_49999_poly {x} {
set Si_photoelectric_1840_49999_shift 9.94564
set Si_photoelectric_1840_49999_poly0 1.2779844980404
set Si_photoelectric_1840_49999_poly1 -3.09003975051177
set Si_photoelectric_1840_49999_poly2 -0.0652704261516074
set Si_photoelectric_1840_49999_poly3 0.034780542074268
set Si_photoelectric_1840_49999_poly4 -0.00961979951786491
set Si_photoelectric_1840_49999_poly5 -0.0216341341426575
set Si_photoelectric_1840_49999_poly6 -0.00618903273595827
return [expr \
  $Si_photoelectric_1840_49999_poly0 \
 +$Si_photoelectric_1840_49999_poly1*($x-$Si_photoelectric_1840_49999_shift)\
 +$Si_photoelectric_1840_49999_poly2*pow($x-$Si_photoelectric_1840_49999_shift,2)\
 +$Si_photoelectric_1840_49999_poly3*pow($x-$Si_photoelectric_1840_49999_shift,3)\
 +$Si_photoelectric_1840_49999_poly4*pow($x-$Si_photoelectric_1840_49999_shift,4)\
 +$Si_photoelectric_1840_49999_poly5*pow($x-$Si_photoelectric_1840_49999_shift,5)\
 +$Si_photoelectric_1840_49999_poly6*pow($x-$Si_photoelectric_1840_49999_shift,6)
] }
proc Si_photoelectric_poly {x} {
 return [expr ( $x>log(1839) && $x<=log(50000) ? [Si_photoelectric_1840_49999_poly $x] : ( $x>log(1550) && $x<=log(1839) ? [Si_photoelectric_1551_1838_poly $x] : 1/0))
] }
proc Si_photoelectric {x} {
 return [expr ([safexp [expr [Si_photoelectric_poly log($x)]]])
] }
proc Si_total {x} {
 return [expr [Si_elastic $x] + [Si_inelastic $x] + [Si_photoelectric $x]
] }
proc Si_nonelastic {x} {
 return [expr [Si_inelastic $x] + [Si_photoelectric $x]
] }
# transmittance of a $thick um foil
proc trans_Si { energy thick } {
    # density
    set rho_Si 2.33
    return [safexp -[expr [Si_total $energy]*$thick*1e-4*$rho_Si]]
}
proc absorb_Si { energy thick } {
    return [ expr 1.0 - [trans_Si $energy $thick]] 
        } 
proc current2photons {current energy thick} {
    return [ expr $current*0.001*3.62/($energy*1.602e-19*[absorb_Si $energy $thick])]
}

