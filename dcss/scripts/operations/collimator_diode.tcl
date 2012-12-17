proc collimator_diode_initialize { } {
}
proc collimator_diode_start { thick ionChamber gain num_interval args } {
    global DCS_DIR
    variable beamlineID

    set userCollimatorList [collimatorMove_getUserCollimatorList]

    set dcsFileDir [file join $DCS_DIR dcsconfig tables $beamlineID]
    set webFileDir /home/webserverroot/secure/staff_pages/UserSupport/BEAMLINES

    set srcWebPath [file join $webFileDir ${beamlineID}_intensity.dat]
    set srcDcsPath [file join $dcsFileDir flux.dat]

    foreach userCollimator $userCollimatorList {
        foreach {index micro width height curFtName} $userCollimator break
        set ftName $curFtName
        if {$micro} {
            set sizeName \
            [expr int($width * 1000.0)]x[expr int($height * 1000.0)]
        } else {
            set sizeName gshield
        }
        if {$ftName == ""} {
            set ftName flux_$sizeName
        }

        set h [start_waitable_operation collimatorMove $index]
        set r [wait_for_operation_to_finish $h]

        set h [eval start_waitable_operation photodiode \
        $thick $ionChamber $gain $num_interval $args]
        set r [wait_for_operation_to_finish $h]

        #### now we copy the file
        set dstDcsPath [file join $dcsFileDir $ftName]
        set dstWebPath [file join $webFileDir \
        ${beamlineID}_intensity_${sizeName}.dat]

        file copy -force -- $srcDcsPath $dstDcsPath
        file copy -force -- $srcWebPath $dstWebPath

        log_warning saved to $dstDcsPath
        log_warning saved to $dstWebPath

        if {$ftName != $curFtName} {
            ## save the flux_table field to the preset
            collimatorMove_setFluxLUTByIndex $index $ftName
        }
    }
    ### make sure at the end BEAMLINE_intensity.dat is the guardshield.
    set gsWebPath [file join $webFileDir \
    ${beamlineID}_intensity_gshield.dat]
    file copy -force -- $gsWebPath $srcWebPath
}
