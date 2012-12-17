proc userCollimator_initialize { } {
}

### toggle collimator setting
proc userCollimator_start { {index {}} } {
    variable user_collimator_status

    set microBeamSelected [lindex $user_collimator_status 0]
    ### toggle
    if {$index == "" || $index == "micro" || $index == "normal"} {
        if {$index == ""} {
            set newMicroBeam [expr !$microBeamSelected]
        } elseif {$index == "micro"} {
            set newMicroBeam 1
        } else {
            ## $index == "normal"
            set newMicroBeam 0
        }
        if {$microBeamSelected == $newMicroBeam} {
            puts "already there, do nothing, just return"
            return
        }

        if {!$newMicroBeam} {
            set user_collimator_status [list 0 -1 2.0 2.0]
            collimatorMoveOut
        } else {
            foreach {index width height} [collimatorGetFirstMicron] break
            if {$index < 0} {
                log_error no microBeam collimator found in the presets
                return -code error FAILED
            }
            set user_collimator_status [list 1 $index $width $height]
        }
        return
    }
    if {![string is integer -strict $index]} {
        log_error bad collimator preset index: $index
        return
    }
    set currentIndex      [lindex $user_collimator_status 1]
    set currentWidth      [lindex $user_collimator_status 2]
    set currentHeight     [lindex $user_collimator_status 3]

    foreach {index hide micro width height} \
    [collimatorMove_getIndexFromIndex $index] break

    if {$index == $currentIndex \
    && $micro == $microBeamSelected \
    && $width == $currentWidth \
    && $height == $currentHeight} {
        puts "already there, do nothing, just return"
        return
    }


    if {!$micro && $microBeamSelected} {
        collimatorMoveOut
    }

    set user_collimator_status [list $micro $index $width $height]
}
