###################################################################
# This is a wrapper for webice to do following in a single
# atomic operation:
# 1. Create a new run definition
# 2. Start that single run with options to:
#    a. Mount selected crystal
#    b. Center crystal
#    c. Autoindex to refine run definition
#    d. Collect that run.
#
###################################################################
# to allow user monitor this process and to keep consistent with
# other runs, the option settings will change collect_config
# which is displayed on Collect Tab and used in all runs.
#
###################################################################
# If any disabled option is selected, this operation will be aborted
# with error messages.
#
# collect_config decides which options are disabled or enabled,
# and which options are selected.
#
###################################################################
proc collectWeb_initialize {} {
    global gCollectWebStatusFile
    global gCollectWebUser
    global gCollectWebSID

    set gCollectWebStatusFile ""
    set gCollectWebUser ""
    set gCollectWebSID ""

    registerEventListener collect_msg ::nScripts::writeCollectMsgToFile
}

proc collectWeb_start { user SID runDefinition_ runExtra_ runOptions_ \
statusFile_ } {
    global gCollectWebStatusFile
    global gCollectWebUser
    global gCollectWebSID
    variable collect_config
    variable collect_msg
    variable runs
    variable beamlineID

    if {$SID == "SID"} {
        set SID "PRIVATE[get_operation_SID]"
        puts "use operation SID: [SIDFilter $SID]"
    }

    set gCollectWebStatusFile $statusFile_
    set gCollectWebUser $user
    set gCollectWebSID $SID

    set runName [lindex $runExtra_ 2]
    set collect_msg [lreplace $collect_msg 0 6 \
    1 Starting 0 $beamlineID $user $runName {}]

    
    ###### check if disabled options are selected ####
    # change to foreach after parameter list is stable

    set selectedMadScan 0
    ### change to > 8 later
    if {[llength $runOptions_] > 7} {
        foreach {show enabledMount enabledCenter enabledAutoindex \
        selectedMount selectedCenter selectedAutoindex selectedStop \
        selectedMadScan} $runOptions_ break
    } else {
        set errorMsg "wrong length runOptions"
        eval log_error $errorMsg
        set collect_msg [lreplace $collect_msg 0 1 0 $errorMsg]
        return -code error [join $errorMsg]
    }

    set errorMsg ""
    if {$selectedMount && (!$show || !$enabledMount)} {
        append errorMsg "mount option is disabled"
    }
    if {$selectedCenter && (!$show || !$enabledCenter)} {
        append errorMsg "center option is disabled"
    }
    if {$selectedAutoindex && (!$show || !$enabledAutoindex)} {
        append errorMsg "autoindex option is disabled"
    }
    if {[llength $errorMsg] != 0} {
        eval log_error $errorMsg
        set collect_msg [lreplace $collect_msg 0 1 0 $errorMsg]
        return -code error [join $errorMsg]
    }

    set newRunNumber [runsConfig_start $user addNewRun \
    $runDefinition_ $runExtra_]

    if {![string is integer -strict $newRunNumber]} {
        set errorMsg "Error: create new run failed"
        log_error $erroMsg
        set collect_msg [lreplace $collect_msg 0 1 0 $errorMsg]
        return -code error [join $errorMsg]
    }

    set collect_msg [lreplace $collect_msg 6 6 $newRunNumber]

    ### set collect_config
    puts "setting collect_config"
    set collect_config [lreplace $collect_config 0 6 \
    $show \
    $enabledMount \
    $enabledCenter \
    $enabledAutoindex \
    $selectedMount \
    $selectedCenter \
    $selectedAutoindex]

    puts "start collect operation"
    if {[catch {
        set result [collectRun_start $newRunNumber $user 0 $SID $runName \
        $selectedStop $selectedMadScan]
    } errorMsg]} {
        #### clear all special flags
        set collect_config [lreplace $collect_config 0 6 0 0 0 0 0 0 0]
        set collect_msg [lreplace $collect_msg 0 2 0 "Error: $errorMsg" 0]
        return -code error $errorMsg
    }
    #### clear all special flags
    set collect_config [lreplace $collect_config 0 6 0 0 0 0 0 0 0]
    return $result
}
proc writeCollectMsgToFile { } {
    global gCollectWebStatusFile
    global gCollectWebUser
    global gCollectWebSID
    variable collect_msg

    if {$gCollectWebStatusFile == "" || \
    $gCollectWebUser == "" || \
    $gCollectWebSID == "" } {
        return
    }

    global gOperation
	 
    if {$gOperation(collectWeb,status) != "active"} {
        return
    }
	 
    if {[catch {
        impWriteFile $gCollectWebUser $gCollectWebSID \
        $gCollectWebStatusFile $collect_msg false
    } errMsg]} {
        log_warning failed to update status file $gCollectWebStatusFile $errMsg
    }
}
