proc calibrateDetector_initialize {} {
}

proc calibrateDetector_start { args } {
    variable beamlineID
    #variable energy
    variable detectorMode

    ####checking
    global gMotorHorz
    global gMotorVert
    variable $gMotorHorz
    variable $gMotorVert

    if {[set $gMotorHorz] != 0.0 || [set $gMotorVert] != 0.0} {
        log_error detector horz or vert not at zero
        send_operatoin_update "detector horz or vert not at zero"
        send_operatoin_update "moving detector horz and vert to zero"
        move $gMotorHorz to 0
        move $gMotorVert to 0
        wait_for_devices $gMotorHorz $gMotorVert

        ### For BL12-2, the real move is done by 
        ##  moving the distance motor later in the code
    }

    set delta 10
    set time 5
    set mode [::gDetector getDefaultModeIndex]
    set extension [::gDetector getImageFileExt $mode]
    send_operation_update "default detector mode: $mode"
    send_operation_update "imageFileExt: $extension"

    ### resolution motor need this
    set detectorMode $mode

    #### energy #####
    set calibrationEnergy 12658.0
    adjustPositionToLimit energy calibrationEnergy
    send_operation_update "moving energy to $calibrationEnergy"
    set energyMotor [getEnergyMotorName]
    move $energyMotor to $calibrationEnergy
    wait_for_devices $energyMotor

    #### attenuation
    set beamAttenuation [::config getInt calibrateDetector.attenuation 0]
    send_operation_update "moving attenuation to $beamAttenuation"
    move attenuation to $beamAttenuation
    wait_for_devices attenuation

    #### distance/resolution
    set distanceCfg [::config getStr calibrateDetector.distance]
    if {[string is double -strict $distanceCfg]} {
        log_warning distance using config: $distanceCfg
        send_operation_update "distance using config: $distanceCfg"
        set detectorMotor [getDetectorDistanceMotorName]
        move $detectorMotor to $distanceCfg
        wait_for_devices $detectorMotor
    } else {
        ###another way:
        ######calculateDistance resoliton energy detector_mode detector_horz detector_vert
        #set calibrationDistance [::gDetector calculateDistance 1.9 $calibrationEnergy $mode 0 0]
        #set detectorMotor [getDetectorDistanceMotorName]
        #move $detectorMotor to $calibrationDistance
        #wait_for_devices $detectorMotor

        send_operation_update "moving resolution to 1.9"
        move resolution to 1.9
        wait_for_devices resolution
    }

    set setEnergy 0
    if { $beamlineID == "BL1-5"} {
	    set time 10
    } elseif {$beamlineID =="BL9-1"} {
	    set time 10
    } elseif {$beamlineID =="BL14-1"} {
	    set time 10
    } elseif {$beamlineID =="BL12-2"} {
        set setEnergy [energyGetEnabled detector_vert_move]
	set testEnergies [::config getStr calibrateDetector.energyList]
	removeInlineCamera
    }

    set userName [get_operation_user]
    set SID [get_operation_SID]
    #debug:
    #    log_warning "SID set to [SIDFilter $SID]"

    set imagedir /data/${userName}

    centerDetector $beamlineID $imagedir $extension $delta $time $userName $SID $mode $setEnergy
    
    detectorZCal $beamlineID $imagedir $extension $delta $time $userName $SID $mode
    if {$setEnergy} {
        set i 1
	    foreach x $testEnergies {
	        if { $x < [expr $calibrationEnergy + 1.0 ] && $x  > [expr $calibrationEnergy - 1.0 ] } {
		        log_warning "Offset has already been calibrated at E= $x"
	        } else {
		        move $energyMotor to $x
		        wait_for_devices $energyMotor

		        move attenuation to $beamAttenuation
		        wait_for_devices attenuation

		        calibrateDetectorOffset $beamlineID $imagedir $extension $delta $time $userName $SID $mode $i

                #set i [expr $i + 1 ]
                incr i
	        }
	    }
        move $energyMotor to $calibrationEnergy
        wait_for_devices $energyMotor
    }
}
proc centerDetector {beamline imagedir extension delta time userName SID mode setEnergy} {
    global gMotorHorz
    global gMotorVert
    variable energy
    variable detector_horz
    variable detector_vert
    variable detector_z

    log_note "Mount Silicon sample before beginning"
#Make sure the detector is not offset

    move $gMotorHorz to 0
    move $gMotorVert to 0
    wait_for_devices $gMotorHorz $gMotorVert

    ### this can be changed to [isMotor detector_z_corr]
    if {$beamline == "BL12-2"} {
        ### maybe we want to do these, NOT the detector_z_corr????
        #move detector_vert to 0
        #move detector_horz to 0
        #wait_for_devices detector_vert detector_horz

        ### this will move to calculated center
        move detector_z_corr by 0
        wait_for_devices detector_z_corr
    }

    set controlFile ${imagedir}/${beamline}-control.out
    set outputFile ${imagedir}/${beamline}-center.out
    set imageroot si-$beamline
    set imageFile ${imagedir}/si-${beamline}.${extension}

    #set serverurl "http://smb.slac.stanford.edu/crystal-analysis/secureServlet/"
    set auth "?beamline=$beamline&userName=${userName}&SMBSessionID=${SID}"

    set handle [start_waitable_operation collectFrame 0 $imageroot $imagedir $userName gonio_phi shutter $delta $time $mode 1 0 $SID]

    wait_for_operation $handle

    log_warning "Running detector center. This takes a while"

    #set url "${serverurl}centerDetector"
    set url [::config getStr calibrateDetector.centerUrl] 
    append url "${auth}"
    append url "&imageFile=${imageFile}"
    append url "&outputFile=${outputFile}"
    append url "&controlFile=${controlFile}"

    #Debug
 #   log_warning $url
    wait_for_time [expr 5000]

    #Send request to run the center script to the crystal analysis server
    if {[catch {
	    set token [http::geturl $url -timeout 8000]
	    checkHttpStatus $token
	    set result [http::data $token]
	    http::cleanup $token
    } errMsg]} {
	    log_error "Failed to get center results: $errMsg"
	    return -code error $errMsg
    }

    #Monitor job. We do this because center takes some time to run

    #set url "${serverurl}checkJobStatus"
    set url [::config getStr calibrateDetector.checkJobStatusUrl] 
    append url "${auth}"
    append url "&controlFile=${controlFile}"
    #Debug
#    log_warning $url

    while {1} {
	    wait_for_time 10000
	    if {[catch {
	        set token [http::geturl $url -timeout 8000]
	        checkHttpStatus $token
	        set result [lindex [http::data $token] 0 ]
#	        log_warning $result
	        http::cleanup $token
	    } errMsg]} {

	        log_error "Failed to get center job status: $errMsg"
	        return -code error $errMsg
	    }
	    if { $result != "running:" } {
	        log_warning "center job finished"
	        break
	    }
    }

    if {[catch { set handle [open $outputFile r ] } errorMsg] } {	
	    log_error "could not open $outputFile : $errorMsg"
    } else {
	    set data [exec grep "Offset" $outputFile ]
	
	    if {$data == ""} {
	        log_error "center failed. See $outputFile" 
	    }

	    set xmove [expr [exec grep Offset $outputFile | cut -f 2 ]]
	    set ymove [expr [exec grep Offset $outputFile | cut -f 4 ]]

	    log_warning  "Moving detector_horz by $xmove mm"
	    log_warning  "Moving detector_vert by $ymove mm"
	    move detector_horz by $xmove
	    move detector_vert by $ymove
        wait_for_devices detector_horz detector_vert

	    if {$beamline == "BL12-2"} {
	        if {$setEnergy == "1"} {
		        log_warning  "resetting energy "
		        energy_set $energy
	        }
	        log_warning  "resetting detector_z "
	        detector_z_corr_set $detector_z
	    } else {
	        log_warning "detector_vert and detector_horz set to 0"
	        configure detector_horz position 0
	        configure detector_vert position 0
	    }
	    
    }
    #debug
    #log_warning  "$detector_horz"
    #log_warning "$detector_vert"

    close $handle

    log_note "detector center calibrated"

}

proc detectorZCal {beamline imagedir extension delta time userName SID mode} {

    variable sample_flow
    set detectorMotor [getDetectorDistanceMotorName]

    #set imageFile "/data/ana/si_0_006.mccd"

    set controlFile ${imagedir}/${beamline}-control.out
    set outputFile ${imagedir}/${beamline}-center.out
    set imageroot siRoom-$beamline
    set imageFile ${imagedir}/${imageroot}.${extension}

    #set serverurl "http://smb.slac.stanford.edu/crystal-analysis/secureServlet/"
    set auth "?beamline=$beamline&userName=${userName}&SMBSessionID=${SID}"

    set restorecryo $sample_flow

    log_note "RESTORE CRYO = $restorecryo"

    move sample_flow to 0
    wait_for_devices sample_flow
    wait_for_time [expr 600*10]
    if {[catch {
	set handle [start_waitable_operation collectFrame 0 siRoom-$beamline $imagedir $userName gonio_phi shutter $delta $time $mode 1 0 $SID ] 
	wait_for_operation_to_finish $handle
    } errorM]} {
	move sample_flow to $restorecryo
	wait_for_devices sample_flow 
        log_note "Restoring cryo"
	return -code error $errorM
    }

    move sample_flow to $restorecryo
    wait_for_devices sample_flow 

    log_warning "Running detector distance calibration"

    #set url "${serverurl}calibrate"
    set url [::config getStr calibrateDetector.calibrateUrl] 
    append url "${auth}"
    append url "&imageFile=${imageFile}"

    #Debug
 #   log_warning $url

    #don't know why, but calibration cannot find the image without some delay
    wait_for_time [expr 5000]

    #Send request to run the center script to the crystal analysis server
    if {[catch {
	set token [http::geturl $url -timeout 160000]
	checkHttpStatus $token
	set result [http::data $token]
	http::cleanup $token
    } errMsg]} {

	log_error "Failed to get detector distance calibration results: $errMsg"
	return -code error $errMsg
    }

    log_warning "True distance: $result"
    
    set truez $result
    configure $detectorMotor position $truez

    log_note "detector distance calibrated"
}

proc getCalibrationDistance { energy  radius} {

    #We want to get two Si powder rings in the image (resol ~1.9 A)
    set conversion  12398.
    set lambda [expr $conversion/$energy]
    set theta [expr asin($lambda/3.8)]
    set distance [expr $radius/(tan(2*$theta))]
#debug
    #log_warning "The calibration distance at $energy eV is $distance mm"
    return $distance
}
 

proc calibrateDetectorOffset {beamline imagedir extension delta time userName SID mode i} {

#    log_note "Mount Silicon sample before beginning"
    variable energy
    variable detector_horz
    variable detector_vert

    set controlFile ${imagedir}/${beamline}-control.out
    set outputFile ${imagedir}/${beamline}-center.out
    set imageroot si-$beamline-E$i
    set imageFile ${imagedir}/${imageroot}.${extension}

    #set serverurl "http://smb.slac.stanford.edu/crystal-analysis/secureServlet/"
    set auth "?beamline=$beamline&userName=${userName}&SMBSessionID=${SID}"


    variable handle
    set handle [start_waitable_operation collectFrame 0 $imageroot $imagedir $userName gonio_phi shutter $delta $time $mode 1 0 $SID]

    wait_for_operation $handle

    log_warning "Running detector center. This takes a while"

    #set url "${serverurl}centerDetector"
    set url [::config getStr calibrateDetector.centerUrl]
    append url "${auth}"
    append url "&imageFile=${imageFile}"
    append url "&outputFile=${outputFile}"
    append url "&controlFile=${controlFile}"

    #Debug
 #   log_warning $url
    wait_for_time [expr 5000]

    #Send request to run the center script to the crystal analysis server
    if {[catch {
	set token [http::geturl $url -timeout 8000]
	checkHttpStatus $token
	set result [http::data $token]
	http::cleanup $token
    } errMsg]} {

	log_error "Failed to get center results: $errMsg"
	return -code error $errMsg
    }

    #Monitor job. We do this because center takes some time to run

    #set url "${serverurl}checkJobStatus"
    set url [::config getStr calibrateDetector.checkJobStatusUrl]
    append url "${auth}"
    append url "&controlFile=${controlFile}"
    #Debug
#    log_warning $url

    while {1} {
	wait_for_time 10000
	if {[catch {
	    set token [http::geturl $url -timeout 8000]
	    checkHttpStatus $token
	    set result [lindex [http::data $token] 0 ]
#	    log_warning $result
	    http::cleanup $token
	} errMsg]} {

	    log_error "Failed to get center job status: $errMsg"
	    return -code error $errMsg
	    break
	}
	if { $result != "running:" } {
	    log_warning "center job finished"
	    break
	}
    }

    if {[catch { set handle [open $outputFile r ] } errorMsg] } {	
	log_error "could not open $outputFile : $errorMsg"
    } else {
	set data [exec grep "Offset" $outputFile ]

	if {$data == ""} {
	    log_error "center failed. See $outputFile" 
	}

#	set ymove [expr [exec grep Offset $outputFile | cut -f 2 ]]
	set ymove [expr [exec grep Offset $outputFile | cut -f 4 ]]

	log_warning "detector_vert position $detector_vert is moved by $ymove mm at energy $energy eV"
	move detector_vert by $ymove
        wait_for_devices detector_vert
        energy_set $energy

#debug
	#log_warning  "$detector_horz"
	#log_warning "Detector_vert is  $detector_vert mm at energy $x eV"
    }
    close $handle


    log_note "detector center calibrated"

}
