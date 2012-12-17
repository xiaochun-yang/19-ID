proc megaScreening_initialize { } {
}

proc megaScreening_start { user sessionID args } {
    variable megaCassetteList

    if {$sessionID == "SID"} {
        set sessionID PRIVATE[get_operation_SID]
        puts "megaScreening use operation SID: $sessionID"
    }

    set megaCassetteList $args
        
    set ll [llength $megaCassetteList]
    if {$ll < 2 || [expr $ll % 2]} {
        log_error wrong argument number
        return -code error "wrong argument number"
    }

    ##check
    foreach { cassette dir } $megaCassetteList {
        if {[string first $cassette "lmr"] < 0} {
            log_error wrong cassette $cassette
            return -code error "wrong cassette $cassette"
        }
        if {[string index $dir 0] != "/"} {
            log_error wrong dir $dir for cassette $cassette
            return -code error "wrong dir $dir for cassette $cassette"
        }
        impDirectoryWritable $user $sessionID $dir
    }

    ## process each cassette
    while (1) {
        if {[llength $megaCassetteList] < 2} {
            log_note megaScreening all done
            break
        }
        foreach { cassette dir } $megaCassetteList break
        megaScreening_loadOneCassette $sessionID $cassette $dir
        megaScreening_checkAction $sessionID

        ####screening one cassette
        sequence_start start $sessionID

        ###only continue to next cassette when current cassette
        ###is all done:
        ###all samples are unselected
        ###no sample mounted

        if {![megaScreening_noSampleMounted]} {
            break
        }
        if {![megaScreening_noSampleSelected]} {
            break
        }

        ###continue to next cassette by removing current cassette from
        ### the list
        set wait_contents [lindex $megaCassetteList 2]
        set megaCassetteList [lreplace $megaCassetteList 0 1]
        #wait_for_string_contents megaCassetteList $wait_contents 0
    }
}

##internal procedure, no safety check
proc megaScreening_noSampleMounted { } {
    variable crystalStatus

    if {[lindex $crystalStatus 3] != "0"} {
        log_note "sample on goniomter, will not continue to next cassette"
        return 0
    } else {
        return 1
    }
}
proc megaScreening_loadOneCassette { sessionID cassette dir } {
    variable sequenceDeviceState

    #### switch cassette
    switch -exact -- $cassette {
        l {
            set index 1
        }
        m {
            set index 2
        }
        r {
            set index 3
        }
    }
    set cur_index [lindex $sequenceDeviceState 1]
    if {$index != $cur_index} {
        if {![megaScreening_noSampleMounted]} {
            log_error cannot switch cassette, sample still mounted
            return -code error "sample still mounted"
        }
        ##prepare new contents
        set newState [lreplace $sequenceDeviceState 1 1 $index]
        ##send it 
        #log_note setting new cassette index
        sequenceSetConfig_start setConfig cassetteInfo $newState $sessionID
        #log_note waiting for update
        wait_for_string_contents sequenceDeviceState $index 1
    }
    ####set the root directory
    #log_note setting directory to $dir
    sequenceSetConfig_start setConfig directory $dir $sessionID
    #log_note waiting directory to change
    wait_for_string_contents screeningParameters $dir 2
}

proc megaScreening_checkAction { sessionID } {
    variable crystalStatus
    variable screeningActionList

    ###if no sample mounted, move next action to mount
    if {[lindex $crystalStatus 3] != "1" && \
    [lindex $screeningActionList 2] != "0"} {
        sequenceSetConfig_start setConfig nextAction 0 $sessionID
        wait_for_string_contents screeningActionList 0 2
        log_warning no sample mounted start with mountNext
    }
}
proc megaScreening_noSampleSelected { } {
    variable crystalSelectionList

    foreach {currentCrystal nextCrystal crystalListStates} \
    $crystalSelectionList break;

    if {$currentCrystal != -1} {
        ###this should not happen,
        ###we already checked no sample before this call
        log_note "current cassette still has sample mounted"
        return 0
    }
    foreach crystalSelected $crystalListStates {
        if {$crystalSelected != "0"} {
            log_note "current cassette not finish yet"
            return 0
        }
    }
    return 1
}
